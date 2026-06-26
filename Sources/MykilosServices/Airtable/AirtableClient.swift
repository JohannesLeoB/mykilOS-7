import Foundation
import MykilosKit

// MARK: - AirtableError
public enum AirtableError: Error, Sendable, Equatable {
    case notConnected
    case invalidResponse
    case httpError(Int)
    case decodingFailed
}

// MARK: - AirtableFetching
public protocol AirtableFetching: Sendable {
    func fetchRecords(baseID: String, table: String) async throws -> [[String: AirtableFieldValue]]
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
}

// MARK: - AirtableClient
public struct AirtableClient: AirtableFetching {
    private let credentialsStore: AirtableCredentialsStoring
    private let session: URLSession
    private let apiBase = "https://api.airtable.com/v0"

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
