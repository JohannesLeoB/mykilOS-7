import Foundation
import MykilosKit

// MARK: - Tool-Bausteine (Phase 2 — Tool-Use)
// Read-only-Tools, die der Assistent aufrufen darf. WHITELIST/default-deny:
// nur explizit registrierte Tools laufen. SEVDESK wird NIE registriert (NO-GO).
// Tool-Ergebnisse sind Daten, keine Instruktionen (Prompt-Injection-Schutz im Engine).

public struct ToolParameter: Sendable, Equatable {
    public let name: String
    public let type: String
    public let description: String
    public let required: Bool
    public init(name: String, type: String = "string", description: String, required: Bool = true) {
        self.name = name; self.type = type; self.description = description; self.required = required
    }
}

public struct ToolRunResult: Sendable, Equatable {
    public let text: String
    public let isError: Bool
    /// Optionaler Aktions-URL, den die Engine als `.calendarAction`-Block in der
    /// Nachricht speichert (nur Anzeige, nie an die API gesendet).
    public let actionURL: String?
    /// Optionale Kostenschätzung — die Engine speichert sie als `.kalkulationsSchaetzung`-
    /// Block (nur Anzeige, nie an die API gesendet).
    public let schaetzung: KostenSchaetzung?
    public init(text: String, isError: Bool = false, actionURL: String? = nil, schaetzung: KostenSchaetzung? = nil) {
        self.text = text; self.isError = isError; self.actionURL = actionURL; self.schaetzung = schaetzung
    }
}

public protocol AssistantTool: Sendable {
    var name: String { get }
    var description: String { get }
    var parameters: [ToolParameter] { get }
    func run(input: [String: String]) async -> ToolRunResult
}

// MARK: - Wire-Definition für Anthropic tools[]
public struct ClaudeToolDefinition: Encodable, Equatable {
    public let name: String
    public let description: String
    public let inputSchema: InputSchema

    enum CodingKeys: String, CodingKey { case name, description, inputSchema = "input_schema" }

    public struct InputSchema: Encodable, Equatable {
        public let type = "object"
        public var properties: [String: Property]
        public var required: [String]
        enum CodingKeys: String, CodingKey { case type, properties, required }
    }
    public struct Property: Encodable, Equatable {
        public let type: String
        public let description: String
    }
}

extension AssistantTool {
    func wireDefinition() -> ClaudeToolDefinition {
        var properties: [String: ClaudeToolDefinition.Property] = [:]
        var required: [String] = []
        for p in parameters {
            properties[p.name] = .init(type: p.type, description: p.description)
            if p.required { required.append(p.name) }
        }
        return ClaudeToolDefinition(
            name: name, description: description,
            inputSchema: .init(properties: properties, required: required)
        )
    }
}

// MARK: - Gemeinsamer Datumsformatter (deterministisch, de_DE / Europe/Berlin)
private let toolDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "de_DE")
    f.timeZone = TimeZone(identifier: "Europe/Berlin")
    f.dateFormat = "EEE d. MMM yyyy, HH:mm"
    return f
}()

// MARK: - SearchGmailTool (read-only) — beantwortet „Wo ist die Mail an …?"
public struct SearchGmailTool: AssistantTool {
    private let client: GoogleGmailFetching
    public init(client: GoogleGmailFetching = GoogleGmailClient()) { self.client = client }

    public let name = "search_gmail"
    public let description =
        "Durchsucht die E-Mails des Nutzers (nur lesen). Verwende Gmail-Suchsyntax im query, "
        + "z. B. 'from:gesa', 'to:gesa subject:Angebot', 'newer_than:30d'. Gibt Treffer mit Betreff, "
        + "Absender und Datum zurück."
    public var parameters: [ToolParameter] {
        [ToolParameter(name: "query", description: "Gmail-Suchabfrage (Gmail-Operatoren erlaubt)")]
    }

    public func run(input: [String: String]) async -> ToolRunResult {
        let query = (input["query"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return ToolRunResult(text: "Leere Suchabfrage.", isError: true) }
        do {
            let messages = try await client.searchMessages(query: query, maxResults: 10)
            guard messages.isEmpty == false else {
                return ToolRunResult(text: "Keine Mails für „\(query)“ gefunden.")
            }
            let lines = messages.map { m -> String in
                let date = m.receivedAt.map { toolDateFormatter.string(from: $0) } ?? "ohne Datum"
                let place = Self.placement(from: m.labels)
                return "• \(m.subject) — von \(m.from) (\(date))\(place.isEmpty ? "" : " · Ablage: \(place)")\n  \(m.snippet)"
            }
            return ToolRunResult(text: lines.joined(separator: "\n"))
        } catch GoogleGmailError.notConnected {
            return ToolRunResult(text: "Gmail ist nicht verbunden. Bitte Google in den Einstellungen verbinden.", isError: true)
        } catch {
            return ToolRunResult(text: "Gmail-Suche fehlgeschlagen: \(error)", isError: true)
        }
    }

    // Label-IDs → lesbarer Ablageort (beantwortet „wo abgelegt?"). Status-Labels
    // (gelesen/markiert) werden ausgeblendet; Kategorien & eigene Labels bleiben.
    static func placement(from labels: [String]) -> String {
        let hidden: Set<String> = ["UNREAD", "STARRED", "IMPORTANT"]
        let names = labels.filter { hidden.contains($0) == false }.map(humanLabel(_:))
        return names.joined(separator: ", ")
    }

    static func humanLabel(_ id: String) -> String {
        switch id {
        case "INBOX":  "Posteingang"
        case "SENT":   "Gesendet"
        case "DRAFT":  "Entwürfe"
        case "SPAM":   "Spam"
        case "TRASH":  "Papierkorb"
        case let c where c.hasPrefix("CATEGORY_"): "Kategorie " + c.dropFirst("CATEGORY_".count).capitalized
        default: id   // eigene Label-ID
        }
    }
}

// MARK: - ListCalendarTool (read-only) — beantwortet „Was steht an?"
public struct ListCalendarTool: AssistantTool {
    private let client: GoogleCalendarFetching
    public init(client: GoogleCalendarFetching = GoogleCalendarClient()) { self.client = client }

    public let name = "list_calendar_events"
    public let description =
        "Listet anstehende Kalendertermine des Nutzers (nur lesen). Optionaler 'query'-Filter "
        + "(Freitext über Titel/Ort), 'within_days' begrenzt den Zeitraum (Standard 14)."
    public var parameters: [ToolParameter] {
        [
            ToolParameter(name: "query", description: "Optionaler Freitext-Filter", required: false),
            ToolParameter(name: "within_days", type: "integer", description: "Zeitraum in Tagen (Standard 14)", required: false),
        ]
    }

    public func run(input: [String: String]) async -> ToolRunResult {
        let query = input["query"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let days = input["within_days"].flatMap { Int($0) } ?? 14
        do {
            let events = try await client.listUpcomingEvents(query: (query?.isEmpty == false) ? query : nil, withinDays: days)
            guard events.isEmpty == false else {
                return ToolRunResult(text: "Keine anstehenden Termine in den nächsten \(days) Tagen gefunden.")
            }
            let lines = events.map { e -> String in
                let when = e.startsAt.map { e.isAllDay ? "ganztägig" : toolDateFormatter.string(from: $0) } ?? "ohne Datum"
                let place = e.location.map { " @ \($0)" } ?? ""
                return "• \(e.title) — \(when)\(place)"
            }
            return ToolRunResult(text: lines.joined(separator: "\n"))
        } catch GoogleCalendarError.notConnected {
            return ToolRunResult(text: "Kalender ist nicht verbunden. Bitte Google in den Einstellungen verbinden.", isError: true)
        } catch {
            return ToolRunResult(text: "Kalender-Abruf fehlgeschlagen: \(error)", isError: true)
        }
    }
}

// MARK: - SuggestCalendarEventTool (output-only, Phase 3)
// Generiert einen Google-Kalender-Link zum Anlegen eines Termins im Browser.
// Liest KEINE Daten — kein API-Call, keine Google-Verbindung nötig.
// Das erzeugte .calendarAction-Block öffnet nur eine URL; es wird NIE in den
// Google Calendar geschrieben.
public struct SuggestCalendarEventTool: AssistantTool {
    public init() {}

    public let name = "suggest_calendar_event"
    public let description =
        "Erstellt einen Google-Kalender-Link, den der Nutzer öffnen kann, um einen Termin "
        + "direkt im Browser anzulegen. Keine API-Verbindung nötig — reine Link-Generierung. "
        + "Verwende dieses Tool, wenn der Nutzer explizit einen Termin anlegen möchte oder du "
        + "eine klare Terminempfehlung hast."
    public var parameters: [ToolParameter] {
        [
            ToolParameter(name: "title", description: "Titel des Termins (Pflicht)"),
            ToolParameter(name: "date",
                          description: "Datum im Format YYYYMMDD oder YYYYMMDDTHHmmss (optional)",
                          required: false),
            ToolParameter(name: "notes",
                          description: "Optionale Beschreibung oder Notizen",
                          required: false),
        ]
    }

    public func run(input: [String: String]) async -> ToolRunResult {
        let title = (input["title"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard title.isEmpty == false else {
            return ToolRunResult(text: "Kein Titel angegeben.", isError: true)
        }
        var items: [URLQueryItem] = [URLQueryItem(name: "text", value: title)]
        if let raw = input["date"], raw.isEmpty == false {
            let normalized = raw
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: ":", with: "")
                .replacingOccurrences(of: " ", with: "T")
            items.append(URLQueryItem(name: "dates", value: "\(normalized)/\(normalized)"))
        }
        if let notes = input["notes"], notes.isEmpty == false {
            items.append(URLQueryItem(name: "details", value: notes))
        }
        var comps = URLComponents(string: "https://calendar.google.com/calendar/r/eventedit")!
        comps.queryItems = items
        let url = comps.url?.absoluteString ?? "https://calendar.google.com/calendar/r/eventedit"
        return ToolRunResult(
            text: "Kalender-Link erstellt: \(title)",
            actionURL: url
        )
    }
}

// MARK: - KostenSchaetzungTool (read-only, lokale Engine) — S18
// Ruft die lokale KalkulationsEngine auf. Kein Netzwerkzugriff — arbeitet auf
// BaselineAnchors + LearningStore (beide lokal). Das Ergebnis erscheint als
// `.kalkulationsSchaetzung`-Block in der Nachricht (nur Anzeige, nie an die API).
public struct KostenSchaetzungTool: AssistantTool {
    private let engine: any KalkulationsEngineProviding
    public init(engine: any KalkulationsEngineProviding) { self.engine = engine }

    public let name = "schaetze_projekt"
    public let description =
        "Erstellt eine Kostenschätzung für ein Innenausbau-Projekt (Küche/Beleuchtung/Ausbau) "
        + "auf Basis einer Freitext-Beschreibung. Gibt Min/Mitte/Max-Netto und Konfidenz zurück. "
        + "Nur aufrufbar, wenn ein Projekt im Fokus steht."
    public var parameters: [ToolParameter] {
        [ToolParameter(name: "beschreibung", description: "Freitext-Beschreibung (Raum, Materialien, Größe, Besonderheiten)")]
    }

    public func run(input: [String: String]) async -> ToolRunResult {
        let beschreibung = (input["beschreibung"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let projektID    = (input["_projektID"]   ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard beschreibung.isEmpty == false else {
            return ToolRunResult(text: "Keine Beschreibung angegeben.", isError: true)
        }
        guard projektID.isEmpty == false else {
            return ToolRunResult(text: "Kein Projekt im Fokus — Schätzung nur im Projekt-Chat möglich.", isError: true)
        }
        do {
            let s = try await engine.schaetze(projektID: projektID, freitext: beschreibung)
            return ToolRunResult(text: Self.formatSummary(s), schaetzung: s)
        } catch {
            return ToolRunResult(text: "Schätzung fehlgeschlagen: \(error.localizedDescription)", isError: true)
        }
    }

    private static func formatSummary(_ s: KostenSchaetzung) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.locale = Locale(identifier: "de_DE")
        fmt.maximumFractionDigits = 0
        let min   = fmt.string(from: NSNumber(value: s.minNetto))   ?? "\(Int(s.minNetto))"
        let mitte = fmt.string(from: NSNumber(value: s.mitteNetto)) ?? "\(Int(s.mitteNetto))"
        let max   = fmt.string(from: NSNumber(value: s.maxNetto))   ?? "\(Int(s.maxNetto))"
        return "Kostenschätzung: \(min)–\(mitte)–\(max) € netto (\(Int(s.confidence * 100)) % Konfidenz, \(s.evidenceCount) Belege)"
    }
}

// MARK: - ListDriveFolderTool
// Listet Dateien und Unterordner im verlinkten Google-Drive-Projektordner.
// Liest ausschließlich Metadaten (Name, Typ, Datum) — nie Dateiinhalte.
// _driveFolderID wird von der Registry injiziert (kein echter Tool-Parameter).
struct ListDriveFolderTool: AssistantTool {
    private let client: GoogleDriveFetching
    init(client: GoogleDriveFetching = GoogleDriveClient()) { self.client = client }

    var name: String { "list_drive_folder" }
    var description: String {
        "Listet Dateien und Unterordner im verlinkten Google-Drive-Projektordner. "
        + "Gibt Name, Typ und Änderungsdatum zurück — liest KEINE Dateiinhalte. "
        + "Mit 'unterordner' (z. B. '01 ANGEBOTE', '02 CAD') gezielt in einen Unterordner schauen."
    }
    var parameters: [ToolParameter] {
        [ToolParameter(name: "unterordner",
                       description: "Optionaler Unterordner-Name (z. B. '01 ANGEBOTE'). Leer = Projektordner-Wurzel.")]
    }

    func run(input: [String: String]) async -> ToolRunResult {
        let folderID = (input["_driveFolderID"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let filter   = (input["unterordner"]    ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !folderID.isEmpty else {
            return ToolRunResult(text: "Kein Drive-Ordner für dieses Projekt verknüpft.", isError: true)
        }
        do {
            var files = try await client.listFolder(folderID: folderID)
            var prefix = "Projektordner"
            if !filter.isEmpty {
                if let sub = files.first(where: { $0.isFolder && $0.name.lowercased().contains(filter) }) {
                    files = try await client.listFolder(folderID: sub.id)
                    prefix = sub.name
                } else {
                    let folders = files.filter { $0.isFolder }.map { $0.name }.joined(separator: ", ")
                    return ToolRunResult(text: "Unterordner '\(filter)' nicht gefunden. Vorhandene Ordner: \(folders)")
                }
            }
            return format(files, prefix: prefix)
        } catch GoogleDriveError.notConnected {
            return ToolRunResult(text: "Google Drive nicht verbunden. In Einstellungen verbinden.", isError: true)
        } catch {
            return ToolRunResult(text: "Drive-Abruf fehlgeschlagen: \(error.localizedDescription)", isError: true)
        }
    }

    private func format(_ files: [GoogleDriveFile], prefix: String) -> ToolRunResult {
        guard !files.isEmpty else { return ToolRunResult(text: "\(prefix): leer.") }
        let fmt = DateFormatter(); fmt.dateFormat = "dd.MM.yy"
        let lines = files.prefix(30).map { f in
            "• \(f.name) [\(f.typeLabel)]\(f.modifiedAt.map { " — \(fmt.string(from: $0))" } ?? "")"
        }
        let more = files.count > 30 ? "\n… und \(files.count - 30) weitere." : ""
        return ToolRunResult(text: "\(prefix) (\(files.count) Einträge):\n" + lines.joined(separator: "\n") + more)
    }
}

// MARK: - SearchContactsTool (read-only) — beantwortet „Wer ist …? Kontaktdaten?"
struct SearchContactsTool: AssistantTool {
    private let client: GoogleContactsFetching
    init(client: GoogleContactsFetching = GoogleContactsClient()) { self.client = client }

    var name: String { "search_contacts" }
    var description: String {
        "Durchsucht die Google-Kontakte des verbundenen Accounts (nur lesen). "
        + "Gibt Name, E-Mail, Telefon und Organisation passender Kontakte zurück."
    }
    var parameters: [ToolParameter] {
        [ToolParameter(name: "query", description: "Suchbegriff (Name, Firma, E-Mail-Fragment)")]
    }

    func run(input: [String: String]) async -> ToolRunResult {
        let query = (input["query"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return ToolRunResult(text: "Leere Suchabfrage.", isError: true) }
        do {
            let contacts = try await client.searchContacts(query: query)
            guard contacts.isEmpty == false else {
                return ToolRunResult(text: "Keine Kontakte für „\(query)“ gefunden.")
            }
            let lines = contacts.prefix(15).map { c -> String in
                var parts = ["• \(c.displayName)"]
                if let org = c.organization, org.isEmpty == false { parts.append("(\(org))") }
                if let mail = c.email, mail.isEmpty == false { parts.append("· \(mail)") }
                if let tel = c.phone, tel.isEmpty == false { parts.append("· \(tel)") }
                return parts.joined(separator: " ")
            }
            return ToolRunResult(text: lines.joined(separator: "\n"))
        } catch GoogleContactsError.notConnected {
            return ToolRunResult(text: "Google ist nicht verbunden. Bitte in den Einstellungen verbinden.", isError: true)
        } catch {
            return ToolRunResult(text: "Kontaktsuche fehlgeschlagen: \(error)", isError: true)
        }
    }
}

// MARK: - ListClickUpTasksTool (read-only) — beantwortet „Was ist offen?"
// _clickUpListID wird von der Registry injiziert (kein echter Tool-Parameter).
struct ListClickUpTasksTool: AssistantTool {
    private let client: ClickUpFetching
    init(client: ClickUpFetching = ClickUpClient()) { self.client = client }

    var name: String { "list_clickup_tasks" }
    var description: String {
        "Listet die offenen ClickUp-Aufgaben des aktuellen Projekts (nur lesen) "
        + "mit Status, Fälligkeit und Zuständigkeit. Nur im Projekt-Chat verfügbar."
    }
    var parameters: [ToolParameter] { [] }

    func run(input: [String: String]) async -> ToolRunResult {
        let listID = (input["_clickUpListID"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard listID.isEmpty == false else {
            return ToolRunResult(text: "Keine ClickUp-Liste für dieses Projekt verknüpft.", isError: true)
        }
        do {
            let tasks = try await client.tasks(listID: listID)
            guard tasks.isEmpty == false else { return ToolRunResult(text: "Keine offenen Aufgaben in dieser Liste.") }
            let lines = tasks.prefix(25).map { t -> String in
                var parts = ["• \(t.name) [\(t.status)]"]
                if t.isUrgent { parts.append("· DRINGEND") }
                if let due = t.dueDate { parts.append("· fällig \(toolDateFormatter.string(from: due))") }
                if let who = t.assignee, who.isEmpty == false { parts.append("· \(who)") }
                return parts.joined(separator: " ")
            }
            return ToolRunResult(text: lines.joined(separator: "\n"))
        } catch ClickUpError.notConnected {
            return ToolRunResult(text: "ClickUp ist nicht verbunden. Bitte in den Einstellungen verbinden.", isError: true)
        } catch {
            return ToolRunResult(text: "ClickUp-Abruf fehlgeschlagen: \(error)", isError: true)
        }
    }
}

// MARK: - QueryStudioKnowledgeTool (read-only, lokal) — die „allwissende" Wissensbasis
struct QueryStudioKnowledgeTool: AssistantTool {
    private let brain: StudioBrain
    init(brain: StudioBrain) { self.brain = brain }

    var name: String { "query_studio_knowledge" }
    var description: String {
        "Durchsucht die lokale Studio-Wissensbasis aus der Projekthistorie "
        + "(Projekte mit Phase/Problem-Signalen/Beträgen, Lieferanten, Team). "
        + "Nutze sie für Fragen zu früheren oder laufenden Projekten, Kunden und Lieferanten. "
        + "Leere/allgemeine Anfrage gibt eine Gesamtübersicht (Kennzahlen, Top-Köpfe/Lieferanten)."
    }
    var parameters: [ToolParameter] {
        [ToolParameter(name: "query", description: "Kunde, Projekt, Ort oder Lieferant (leer = Übersicht)", required: false)]
    }

    func run(input: [String: String]) async -> ToolRunResult {
        let query = (input["query"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty || ["übersicht", "overview", "statistik", "gesamt", "stats"].contains(query.lowercased()) {
            return ToolRunResult(text: brain.overview)
        }
        let hits = brain.lookup(query)
        guard hits.isEmpty == false else {
            return ToolRunResult(text: "Keine Treffer in der Studio-Wissensbasis für „\(query)“. Tipp: Kundenname, Ort oder Lieferant.")
        }
        return ToolRunResult(text: hits.map(brain.describe).joined(separator: "\n"))
    }
}

// MARK: - AssistantToolRegistry (Whitelist, default-deny)
public struct AssistantToolRegistry: Sendable {
    private let tools: [any AssistantTool]

    public init(tools: [any AssistantTool]) { self.tools = tools }

    /// Standard-Read-only-Whitelist. SEVDESK ist hier bewusst NICHT enthalten und
    /// wird auch nie ergänzt (NO-GO: Sevdesk nie lesen/schreiben).
    /// `kalkulationsEngine` ergänzt `schaetze_projekt`, `drive` ergänzt `list_drive_folder`.
    public static func standard(
        gmail: GoogleGmailFetching = GoogleGmailClient(),
        calendar: GoogleCalendarFetching = GoogleCalendarClient(),
        drive: GoogleDriveFetching = GoogleDriveClient(),
        contacts: GoogleContactsFetching = GoogleContactsClient(),
        clickUp: ClickUpFetching = ClickUpClient(),
        studioBrain: StudioBrain? = StudioBrain.shared,
        kalkulationsEngine: (any KalkulationsEngineProviding)? = nil
    ) -> AssistantToolRegistry {
        var tools: [any AssistantTool] = [
            SearchGmailTool(client: gmail),
            ListCalendarTool(client: calendar),
            SuggestCalendarEventTool(),
            ListDriveFolderTool(client: drive),
            SearchContactsTool(client: contacts),
            ListClickUpTasksTool(client: clickUp),
        ]
        if let studioBrain {
            tools.append(QueryStudioKnowledgeTool(brain: studioBrain))
        }
        if let engine = kalkulationsEngine {
            tools.append(KostenSchaetzungTool(engine: engine))
        }
        return AssistantToolRegistry(tools: tools)
    }

    public var toolNames: [String] { tools.map(\.name) }

    public func definitions() -> [ClaudeToolDefinition] {
        tools.map { $0.wireDefinition() }
    }

    /// Nur `schaetze_projekt` — für den Schätzchat-Modus (kein Mail/Kalender/Drive-Leak).
    public func schaetzDefinitions() -> [ClaudeToolDefinition] {
        tools.filter { $0.name == "schaetze_projekt" }.map { $0.wireDefinition() }
    }

    /// Führt ein Tool aus. Unbekannter/nicht erlaubter Name → Deny-Ergebnis.
    /// `projektID` → `_projektID`, `driveFolderID` → `_driveFolderID` (injiziert,
    /// kein Protokollbruch: `_`-Präfix-Keys sendet Claude nicht selbst).
    public func run(name: String, inputJSON: Data, projektID: String? = nil, driveFolderID: String? = nil, clickUpListID: String? = nil) async -> ToolRunResult {
        guard let tool = tools.first(where: { $0.name == name }) else {
            return ToolRunResult(text: "Tool nicht erlaubt oder unbekannt: \(name)", isError: true)
        }
        var input = Self.stringDict(from: inputJSON)
        if let id  = projektID     { input["_projektID"]      = id }
        if let fid = driveFolderID { input["_driveFolderID"]  = fid }
        if let lid = clickUpListID { input["_clickUpListID"]  = lid }
        return await tool.run(input: input)
    }

    // Claude kann integer-Parameter (z. B. within_days) als JSON-Number senden.
    // JSONSerialization + compactMapValues fängt String und Number gleichermaßen ab.
    static func stringDict(from data: Data) -> [String: String] {
        guard let raw = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return [:] }
        return raw.compactMapValues { v in
            if let s = v as? String { return s }
            if let n = v as? NSNumber { return n.stringValue }
            return nil
        }
    }
}
