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
    public init(text: String, isError: Bool = false, actionURL: String? = nil) {
        self.text = text; self.isError = isError; self.actionURL = actionURL
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

// MARK: - AssistantToolRegistry (Whitelist, default-deny)
public struct AssistantToolRegistry: Sendable {
    private let tools: [any AssistantTool]

    public init(tools: [any AssistantTool]) { self.tools = tools }

    /// Standard-Read-only-Whitelist. SEVDESK ist hier bewusst NICHT enthalten und
    /// wird auch nie ergänzt (NO-GO: Sevdesk nie lesen/schreiben).
    public static func standard(
        gmail: GoogleGmailFetching = GoogleGmailClient(),
        calendar: GoogleCalendarFetching = GoogleCalendarClient()
    ) -> AssistantToolRegistry {
        AssistantToolRegistry(tools: [
            SearchGmailTool(client: gmail),
            ListCalendarTool(client: calendar),
            SuggestCalendarEventTool(),
        ])
    }

    public var toolNames: [String] { tools.map(\.name) }

    public func definitions() -> [ClaudeToolDefinition] {
        tools.map { $0.wireDefinition() }
    }

    /// Führt ein Tool aus. Unbekannter/nicht erlaubter Name → Deny-Ergebnis, ohne etwas auszuführen.
    public func run(name: String, inputJSON: Data) async -> ToolRunResult {
        guard let tool = tools.first(where: { $0.name == name }) else {
            return ToolRunResult(text: "Tool nicht erlaubt oder unbekannt: \(name)", isError: true)
        }
        let input = Self.stringDict(from: inputJSON)
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
