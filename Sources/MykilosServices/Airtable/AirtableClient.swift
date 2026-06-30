import Foundation
import MykilosKit

// MARK: - AirtableError
public enum AirtableError: Error, Sendable, Equatable {
    case notConnected
    case invalidResponse
    case httpError(Int)
    case decodingFailed
    case invalidBaseID(String)
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
public struct AirtableClient: AirtableFetching, AirtableRecordCreating, AirtableRecordUpdating {
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
            "Kontakte",
        ],
        // Artikel & Einkauf (Webshop-Phase 1, gated, von Johannes freigegeben 2026-06-30)
        // NIEMALS: Artikel-Stamm, Lieferanten, Preise oder andere Tabellen dieser Base.
        "appdxTeT6bhSBmwx5": [
            "Lagerliste",      // tblh8j1Rykv12T2Dx
            "Projektartikel",  // tblirHIicPP3qdcDp
            "Warenkörbe",      // tblhZujm3Ig6hlafX
        ],
    ]

    /// Prüft, ob Base + Tabelle auf der Schreib-Whitelist stehen.
    /// Wird von createRecord und updateRecord verwendet.
    static func isWritable(baseID: String, table: String) -> Bool {
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
