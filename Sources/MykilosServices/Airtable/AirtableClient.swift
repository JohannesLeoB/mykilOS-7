import Foundation
import MykilosKit

// MARK: - AirtableError
// Fix (2026-07-01, Live-Untersuchung Warenkorb-Versand): ohne LocalizedError-
// Konformität bridged Swift jeden AirtableError generisch zu NSError mit
// domain=Typname + code=0 — die UI zeigte deshalb "AirtableError error 0" statt
// der echten Ursache (z. B. HTTP 422). Jetzt zeigt jeder Call-Site dieselbe
// aussagekräftige Meldung wie der bereits korrekte Fragebogen-Pfad (IntakeSchreibFehler).
public enum AirtableError: Error, LocalizedError, Sendable, Equatable {
    case notConnected
    case invalidResponse
    case httpError(Int)
    case decodingFailed
    case invalidBaseID(String)

    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Airtable nicht verbunden — Personal Access Token in den Einstellungen eintragen."
        case .invalidResponse:
            return "Airtable-Antwort ungültig (keine HTTP-Antwort erhalten)."
        case .httpError(let code):
            return "Airtable-Fehler HTTP \(code)"
        case .decodingFailed:
            return "Airtable-Antwort konnte nicht gelesen werden (Decoding fehlgeschlagen)."
        case .invalidBaseID(let msg):
            return "Schreibschutz verletzt: \(msg)"
        }
    }
}

// MARK: - AirtableFetching
public protocol AirtableFetching: Sendable {
    func fetchRecords(baseID: String, table: String) async throws -> [[String: AirtableFieldValue]]
}

// MARK: - AirtableRecordCreating
// Eng begrenzter, append-only Schreibpfad. Bewusst getrennt vom Lese-Protokoll,
// damit Schreib-Aufrufer explizit sein müssen.
public protocol AirtableRecordCreating: Sendable {
    func createRecord(baseID: String, table: String, fields: [String: AirtableFieldValue]) async throws -> String
}

// MARK: - AirtableRecordUpdating
// HTTP PATCH auf einen bestehenden Record — nur Felder, die geändert werden sollen.
// KEIN DELETE. Wirft `invalidBaseID`, wenn Base/Tabelle nicht auf der Whitelist.
public protocol AirtableRecordUpdating: Sendable {
    func updateRecord(baseID: String, table: String, recordID: String, fields: [String: AirtableFieldValue]) async throws
}

// MARK: - AirtableRecordDeleting
// mykilOS 8, Block A: NUR für TEST-Sandbox-Cleanup (HANDOFF_TEST_SANDBOX.md §2/§5).
// Bewusst ein EIGENES, von `AirtableRecordCreating`/`-Updating` getrenntes Protokoll
// — kein Aufrufer „stolpert versehentlich" über eine Delete-Fähigkeit. Geprüft gegen
// `AirtableClient.testDeletableMap`, eine eigene, von `writableMap` UNABHÄNGIGE und
// absichtlich winzige Whitelist (Stand 2026-06-30: LEER — es gibt noch keine echte
// TEST-Tabelle; Block D befüllt sie, wenn S4-Provisioning TEST-Artefakte erzeugt).
public protocol AirtableRecordDeleting: Sendable {
    func deleteRecord(baseID: String, table: String, recordID: String) async throws
}

// MARK: - AirtableFieldValue
public enum AirtableFieldValue: Sendable, Equatable, Decodable {
    case string(String)
    case array([String])
    case number(Double)
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) { self = .string(s); return }
        if let a = try? container.decode([String].self) { self = .array(a); return }
        if let n = try? container.decode(Double.self) { self = .number(n); return }
        if container.decodeNil() { self = .null; return }
        self = .null
    }

    public var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    /// Gibt einen String zurück — auch für .number-Werte (Zahlen → "12345" oder "3.14").
    /// Nutzen wenn das Quelltfeld in Airtable als Zahl formatiert sein kann (z. B. Artikelnummer).
    public var anyStringValue: String? {
        switch self {
        case .string(let s): return s
        case .number(let n):
            // Ganzzahlen ohne Dezimalstelle (12345.0 → "12345")
            if n.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int(n))
            }
            return String(n)
        default: return nil
        }
    }

    public var firstArrayValue: String? {
        if case .array(let a) = self { return a.first }
        return nil
    }

    public var numberValue: Double? {
        if case .number(let n) = self { return n }
        return nil
    }

    /// JSON-serialisierbarer Wert für den Schreibpfad (POST-Body).
    var jsonValue: Any {
        switch self {
        case .string(let s): return s
        case .array(let a):  return a
        case .number(let n): return n
        case .null:          return NSNull()
        }
    }
}

// MARK: - AirtableClient
public struct AirtableClient: AirtableFetching, AirtableRecordCreating, AirtableRecordUpdating, AirtableRecordDeleting {
    private let credentialsStore: AirtableCredentialsStoring
    private let session: URLSession
    private let apiBase = "https://api.airtable.com/v0"

    // MARK: NO-GO-Schreibgrenzen (unverhandelbar)
    // Geschrieben wird AUSSCHLIESSLICH in explizit freigegebene Bases und Tabellen.
    // Nie die geteilte Base (appkPzoEiI5eSMkNK), nie fremde Bases, kein DELETE.
    //
    // Freigegebene Bases + Tabellen (Stand 2026-06-30):
    //   appuVMh3KDfKw4OoQ  — Mastermind (eigene Schaltzentrale)
    //   appdxTeT6bhSBmwx5  — Artikel & Einkauf (Webshop-Phase 1, gated, von Johannes freigegeben)
    //
    // NIEMALS andere Tabellen dieser Bases, NIEMALS andere Bases, KEIN DELETE.
    public static let writableBaseID = "appuVMh3KDfKw4OoQ"   // Rückwärtskompatibilität
    public static let writableTables: Set<String> = [          // Rückwärtskompatibilität (Mastermind)
        "Datenstrom-Handbuch", "Datenstrom-Log",
        "Kontakte",   // S19: Kontakt anlegen/aktualisieren via Bestätigungskarte
    ]

    /// Vollständige Schreib-Whitelist: Base-ID → erlaubte Tabellen.
    /// createRecord und updateRecord prüfen gegen diese Map.
    public static let writableMap: [String: Set<String>] = [
        // Mastermind-Base (eigene Schaltzentrale)
        "appuVMh3KDfKw4OoQ": [
            "Datenstrom-Handbuch", "Datenstrom-Log",
            "Kontakte",            // S19: Kontakt anlegen/aktualisieren
        ],
        // Artikel & Einkauf (Webshop-Phase 1, gated, von Johannes freigegeben 2026-06-30)
        // Intake-Fragebogen legt neue Kunden- + Projekt-Records an (append-only, gated, Record-Link gültig).
        // NIEMALS: Artikel-Stamm, Lieferanten, Preise oder andere Tabellen dieser Base.
        "appdxTeT6bhSBmwx5": [
            "Lagerliste",      // tblh8j1Rykv12T2Dx
            "Projektartikel",  // tblirHIicPP3qdcDp
            "Warenkörbe",      // tblhZujm3Ig6hlafX
            "Projekte",        // Intake: neues Projekt anlegen (tblOXF9Cv8Jze6595, gated)
            "Kunden",          // Intake: neuen Kunden anlegen (tblImZ3fKYBXBT7Wb, gated)
        ],
        // mykilOS-Backup (Write-Shadow-Spiegel, von Johannes 2026-06-30 live angelegt).
        // AUSSCHLIESSLICH append-only über WriteShadowRecorder — niemals PATCH (kein
        // updateRecord-Aufrufer nutzt diese Base), niemals DELETE (kein Pfad existiert).
        "app56DTbSoqPvZhom": [
            "Write-Shadow-Log",   // tblYQVdeHP2Zvgt8m — Tabellenname unverifiziert, MCP sieht die Base nicht
        ],
    ]

    /// Prüft, ob Base + Tabelle auf der Schreib-Whitelist stehen.
    /// Wird von createRecord und updateRecord verwendet.
    public static func isWritable(baseID: String, table: String) -> Bool {
        writableMap[baseID]?.contains(table) == true
    }

    public init(
        credentialsStore: AirtableCredentialsStoring = KeychainAirtableCredentialsStore(),
        session: URLSession = .shared
    ) {
        self.credentialsStore = credentialsStore
        self.session = session
    }

    public func fetchRecords(baseID: String, table: String) async throws -> [[String: AirtableFieldValue]] {
        guard let credentials = try? credentialsStore.load() else {
            throw AirtableError.notConnected
        }

        var allRecords: [[String: AirtableFieldValue]] = []
        var offset: String? = nil

        repeat {
            guard let url = Self.buildListURL(apiBase: apiBase, baseID: baseID, table: table, offset: offset) else {
                throw AirtableError.invalidResponse
            }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(credentials.pat)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AirtableError.invalidResponse }
            guard (200...299).contains(http.statusCode) else { throw AirtableError.httpError(http.statusCode) }

            let page = try Self.parsePage(from: data)
            allRecords.append(contentsOf: page.records)
            offset = page.offset
        } while offset != nil

        return allRecords
    }

    // MARK: - Schreibpfad (append-only, hart begrenzt)

    /// Legt EINEN neuen Record an. Wirft `invalidBaseID`, wenn Base oder Tabelle
    /// nicht auf der Whitelist stehen — das ist die harte NO-GO-Durchsetzung:
    /// kein Schreiben in Projekt-/Kunden-/Kalkulationsdaten, kein Schreiben in
    /// fremde Basen. Gibt die neue Record-ID zurück.
    public func createRecord(baseID: String, table: String, fields: [String: AirtableFieldValue]) async throws -> String {
        guard Self.isWritable(baseID: baseID, table: table) else {
            throw AirtableError.invalidBaseID("Schreiben in \(table)@\(baseID) nicht erlaubt — Whitelist: \(Self.writableMap)")
        }
        guard let credentials = try? credentialsStore.load() else {
            throw AirtableError.notConnected
        }
        let encoded = table.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? table
        guard let url = URL(string: "\(apiBase)/\(baseID)/\(encoded)") else {
            throw AirtableError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(credentials.pat)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = ["records": [["fields": fields.mapValues(\.jsonValue)]]]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AirtableError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw AirtableError.httpError(http.statusCode) }
        let decoded = try? JSONDecoder().decode(CreateRecordResponse.self, from: data)
        return decoded?.records.first?.id ?? ""
    }

    // MARK: - Update (PATCH, bestätigungspflichtig, hart begrenzt)

    /// Aktualisiert EINEN bestehenden Record via HTTP PATCH. Wirft `invalidBaseID`,
    /// wenn Base oder Tabelle nicht auf der Whitelist — kein Schreiben in fremde Bases.
    /// Gibt nur geänderte Felder mit — Felder, die nicht im Dict stehen, bleiben unverändert.
    public func updateRecord(baseID: String, table: String, recordID: String, fields: [String: AirtableFieldValue]) async throws {
        guard Self.isWritable(baseID: baseID, table: table) else {
            throw AirtableError.invalidBaseID("Schreiben in \(table)@\(baseID) nicht erlaubt — Whitelist: \(Self.writableMap)")
        }
        guard let credentials = try? credentialsStore.load() else {
            throw AirtableError.notConnected
        }
        let encoded = table.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? table
        guard let url = URL(string: "\(apiBase)/\(baseID)/\(encoded)/\(recordID)") else {
            throw AirtableError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(credentials.pat)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = ["fields": fields.mapValues(\.jsonValue)]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AirtableError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw AirtableError.httpError(http.statusCode) }
    }

    // MARK: - Löschpfad (NUR TEST-Sandbox-Cleanup, Block A)
    // Eigene, winzige Whitelist — VÖLLIG unabhängig von `writableMap`. Stand
    // 2026-06-30 bewusst LEER: es gibt noch keine echte TEST-Tabelle (S4-Provisioning
    // kommt erst in Block D). Erst wenn eine konkrete TEST-Tabelle hier eingetragen
    // wird, kann überhaupt irgendetwas gelöscht werden — auch über `TestSandboxCleaner`.
    public static let testDeletableMap: [String: Set<String>] = [:]

    static func isTestDeletable(baseID: String, table: String) -> Bool {
        testDeletableMap[baseID]?.contains(table) == true
    }

    /// Löscht EINEN Record. Wirft `invalidBaseID`, wenn Base/Tabelle nicht auf der
    /// TEST-Delete-Whitelist stehen — das ist die einzige Stelle im gesamten Code,
    /// die überhaupt einen Airtable-DELETE-Request absetzen kann.
    public func deleteRecord(baseID: String, table: String, recordID: String) async throws {
        guard Self.isTestDeletable(baseID: baseID, table: table) else {
            throw AirtableError.invalidBaseID("Löschen in \(table)@\(baseID) nicht erlaubt — TEST-Delete-Whitelist: \(Self.testDeletableMap)")
        }
        guard let credentials = try? credentialsStore.load() else {
            throw AirtableError.notConnected
        }
        let encoded = table.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? table
        guard let url = URL(string: "\(apiBase)/\(baseID)/\(encoded)/\(recordID)") else {
            throw AirtableError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(credentials.pat)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AirtableError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw AirtableError.httpError(http.statusCode) }
    }

    // MARK: - Testbare Bausteine für updateRecord

    /// Baut die PATCH-URL: api.airtable.com/v0/{baseID}/{table}/{recordID}.
    static func buildPatchURL(apiBase: String, baseID: String, table: String, recordID: String) -> URL? {
        let encoded = table.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? table
        return URL(string: "\(apiBase)/\(baseID)/\(encoded)/\(recordID)")
    }

    /// Serialisiert den PATCH-Payload. Rein und testbar.
    static func encodePatchPayload(fields: [String: AirtableFieldValue]) throws -> Data {
        let payload: [String: Any] = ["fields": fields.mapValues(\.jsonValue)]
        return try JSONSerialization.data(withJSONObject: payload)
    }

    // MARK: - Reine, testbare Bausteine

    static func buildListURL(apiBase: String, baseID: String, table: String, offset: String?) -> URL? {
        let encoded = table.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? table
        var components = URLComponents(string: "\(apiBase)/\(baseID)/\(encoded)")
        var items = [URLQueryItem(name: "pageSize", value: "100")]
        if let offset { items.append(URLQueryItem(name: "offset", value: offset)) }
        components?.queryItems = items
        return components?.url
    }

    static func parsePage(from data: Data) throws -> AirtablePage {
        do {
            return try JSONDecoder().decode(AirtablePage.self, from: data)
        } catch {
            throw AirtableError.decodingFailed
        }
    }

    static func mapCustomers(from records: [[String: AirtableFieldValue]]) -> [Customer] {
        records.compactMap { fields in
            guard let number = fields["Kundennummer"]?.stringValue,
                  let name = fields["Name"]?.stringValue else { return nil }
            let recordID = fields["_airtableRecordID"]?.stringValue
            return Customer(customerNumber: number, name: name, airtableRecordID: recordID)
        }
    }

    // S13: Mappt die Airtable-Tabelle „Kontakte" → StudioContact (read-only). Erfordert
    // einen Namen; alle anderen Felder optional. Pure/testbar.
    public static func mapContacts(from records: [[String: AirtableFieldValue]]) -> [StudioContact] {
        records.compactMap { fields in
            let name = (fields["Name"]?.stringValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard name.isEmpty == false else { return nil }
            let recordID = fields["_airtableRecordID"]?.stringValue ?? name
            func nonEmpty(_ key: String) -> String? {
                let v = fields[key]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
                return (v?.isEmpty == false) ? v : nil
            }
            return StudioContact(
                id: recordID, name: name,
                organisation: nonEmpty("Organisation"),
                email: nonEmpty("E-Mail"),
                telefon: nonEmpty("Telefon"),
                adresse: nonEmpty("Adresse"),
                projekt: nonEmpty("Projekt") ?? fields["Projekt"]?.firstArrayValue,
                kategorie: nonEmpty("Kategorie"))
        }
    }

    static func mapProjects(from records: [[String: AirtableFieldValue]]) -> [Project] {
        records.compactMap { fields in
            guard let number = fields["Projektnummer"]?.stringValue,
                  let title = fields["Titel"]?.stringValue else { return nil }

            let kindRaw = fields["Art"]?.stringValue ?? "kitchen"
            let kind = ProjectKind(rawValue: kindRaw) ?? .kitchen
            let customerNumber = fields["Kundennummer"]?.stringValue
                ?? fields["Kunde"]?.firstArrayValue
                ?? ""

            let links = ProjectLinks(
                driveFolderID: fields["Drive-Ordner-ID"]?.stringValue,
                driveFolderPath: fields["Drive-Pfad"]?.stringValue,
                clickUpListID: fields["ClickUp-Liste"]?.stringValue,
                calendarQuery: fields["Kalender-Suche"]?.stringValue,
                contactsQuery: fields["Kontakte-Suche"]?.stringValue,
                mailQuery: fields["Mail-Suche"]?.stringValue,
                sevdeskRef: fields["sevdesk-Ref"]?.stringValue,
                budget: fields["Budget"]?.numberValue
            )

            let recordID = fields["_airtableRecordID"]?.stringValue

            return Project(
                projectNumber: number,
                title: title,
                kind: kind,
                customerNumber: customerNumber,
                parentProjectNumber: fields["Eltern-Projekt"]?.stringValue
                    ?? fields["Eltern-Projekt"]?.firstArrayValue,
                links: links,
                phase: fields["Phase"]?.stringValue,
                airtableRecordID: recordID
            )
        }
    }

    // MARK: - Geschäfts-Mapping (Artikel-Base appdxTeT6bhSBmwx5, Block A)
    // Feldnamen sind code-verifiziert aus `IntakeResultBuilder.mapKundeFelder`/
    // `mapProjektFelder` — der einzige real schreibende Pfad in diese Tabellen
    // (Stand 2026-06-30). Bewusst tolerant: ein fehlendes Feld verwirft NIE den
    // ganzen Record (Fallstrick „Records verschwinden still", siehe ROLLING_PLAN §3b).
    public static func mapBusinessCustomers(from records: [[String: AirtableFieldValue]]) -> [BusinessCustomer] {
        records.compactMap { fields in
            guard let recordID = fields["_airtableRecordID"]?.stringValue, !recordID.isEmpty else { return nil }
            let nachname = fields["Nachname"]?.stringValue
            let vorname  = fields["Vorname"]?.stringValue
            let firma    = fields["Firma"]?.stringValue
            // Mindestens ein Namens-/Firmenfeld muss da sein, sonst ist der Record kein
            // brauchbarer Kunde (z. B. eine leere Vorlagenzeile).
            guard (nachname?.isEmpty == false) || (firma?.isEmpty == false) else { return nil }
            return BusinessCustomer(
                airtableRecordID: recordID,
                nachname: nachname,
                vorname: vorname,
                firma: firma,
                email: fields["Kontakt 1 Email"]?.stringValue,
                telefon: fields["Kontakt 1 Telefon"]?.stringValue
            )
        }
    }

    public static func mapBusinessProjects(from records: [[String: AirtableFieldValue]]) -> [BusinessProject] {
        records.compactMap { fields in
            guard let recordID = fields["_airtableRecordID"]?.stringValue, !recordID.isEmpty,
                  let name = fields["Projektname"]?.stringValue, !name.isEmpty else { return nil }
            let kundeIDs: [String]
            if case .array(let arr)? = fields["Kunde"] { kundeIDs = arr }
            else if let single = fields["Kunde"]?.stringValue { kundeIDs = [single] }
            else { kundeIDs = [] }
            // Existiert heute nicht im Artikel-Schema (Stand 2026-06-30) — bleibt nil,
            // bis das Feld ergänzt wird. Lookup per Feld-NAME, nicht erraten.
            let projectNumber = fields["Projektnummer"]?.stringValue
            return BusinessProject(
                airtableRecordID: recordID,
                projektname: name,
                projektstatus: fields["Projektstatus"]?.stringValue,
                budget: fields["Budget"]?.numberValue ?? fields["Budget"]?.anyStringValue.flatMap(Double.init),
                kundeRecordIDs: kundeIDs,
                projectNumber: (projectNumber?.isEmpty == false) ? projectNumber : nil
            )
        }
    }
}

// MARK: - AirtablePage

public struct AirtablePage: Decodable, Sendable {
    public let records: [[String: AirtableFieldValue]]
    public let offset: String?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        offset = try container.decodeIfPresent(String.self, forKey: .offset)

        var rawRecords: [[String: AirtableFieldValue]] = []
        var recordsContainer = try container.nestedUnkeyedContainer(forKey: .records)
        while !recordsContainer.isAtEnd {
            let record = try recordsContainer.decode(AirtableRecord.self)
            var fields = record.fields
            fields["_airtableRecordID"] = .string(record.id)
            rawRecords.append(fields)
        }
        records = rawRecords
    }

    enum CodingKeys: String, CodingKey { case records, offset }
}

private struct AirtableRecord: Decodable {
    let id: String
    let fields: [String: AirtableFieldValue]
}

// MARK: - CreateRecordResponse
private struct CreateRecordResponse: Decodable {
    struct Created: Decodable { let id: String }
    let records: [Created]
}
