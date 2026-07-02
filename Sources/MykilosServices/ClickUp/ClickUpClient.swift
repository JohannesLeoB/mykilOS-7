import Foundation

// MARK: - ClickUpTask
// Eine offene Aufgabe aus der im Projekt verlinkten ClickUp-Liste
// (Project.links.clickUpListID). Reiner Lesefetch — kein Schreiben hier;
// Statusänderungen liefen, falls je gewünscht, über Action-Card → Audit.
public struct ClickUpTask: Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var status: String
    public var dueDate: Date?
    public var assignee: String?
    public var isUrgent: Bool

    public init(id: String, name: String, status: String,
                dueDate: Date? = nil, assignee: String? = nil, isUrgent: Bool = false) {
        self.id = id
        self.name = name
        self.status = status
        self.dueDate = dueDate
        self.assignee = assignee
        self.isUrgent = isUrgent
    }
}

// MARK: - ClickUpError
public enum ClickUpError: Error, Sendable, Equatable {
    case notConnected
    case invalidResponse
    case httpError(Int)
    case decodingFailed
}

// MARK: - ClickUpFetching
public protocol ClickUpFetching: Sendable {
    func tasks(listID: String) async throws -> [ClickUpTask]
}

// MARK: - ClickUpProjectProvisioning
// mykilOS 8, Studio-OS-Rollout (2026-07-02): der Schreibpfad für die Projekt-Geburt
// (ProjektProvisioningService, Schritt `.clickUpStruktur`). Getrennt vom reinen
// Lese-Widget-Pfad (`ClickUpFetching`) — Views/Widgets rufen das NIE direkt auf,
// nur der Provisioning-Service (Karte→Bestätigung→Audit, wie Drive/Airtable).
public protocol ClickUpProjectProvisioning: Sendable {
    /// Findet eine Liste mit exaktem Namen im Ordner, oder legt sie neu an (idempotent).
    func findOrCreateList(folderID: String, name: String) async throws -> String
    /// Legt einen Task in der Liste an. Kein Duplikat-Check hier — der Aufrufer prüft
    /// vorher über `tasks(listID:)`, ob der Name schon existiert.
    func createTask(listID: String, name: String) async throws -> String
}

// MARK: - ClickUpClient
// Liest die offenen Aufgaben einer ClickUp-Liste des verbundenen Accounts.
// Auth: Personal-API-Token direkt im Authorization-Header (kein "Bearer").
public struct ClickUpClient: ClickUpFetching, ClickUpProjectProvisioning {
    private let credentialsStore: ClickUpCredentialsStoring
    private let session: URLSession
    private let baseURL = "https://api.clickup.com/api/v2"

    public init(
        credentialsStore: ClickUpCredentialsStoring = KeychainClickUpCredentialsStore(),
        session: URLSession = .shared
    ) {
        self.credentialsStore = credentialsStore
        self.session = session
    }

    public func tasks(listID: String) async throws -> [ClickUpTask] {
        guard let credentials = try? credentialsStore.load() else {
            throw ClickUpError.notConnected
        }
        guard let url = Self.buildTasksURL(baseURL: baseURL, listID: listID) else {
            throw ClickUpError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue(credentials.apiToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClickUpError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw ClickUpError.httpError(http.statusCode) }

        return try Self.parseTasks(from: data)
    }

    // MARK: - Schreiben (Provisioning, Schritt `.clickUpStruktur`)

    public func findOrCreateList(folderID: String, name: String) async throws -> String {
        guard let credentials = try? credentialsStore.load() else { throw ClickUpError.notConnected }
        // Erst lesen (idempotent, kein Duplikat): existierende Listen im Ordner nach Namen prüfen.
        guard let listsURL = Self.buildFolderListsURL(baseURL: baseURL, folderID: folderID) else {
            throw ClickUpError.invalidResponse
        }
        var listRequest = URLRequest(url: listsURL)
        listRequest.setValue(credentials.apiToken, forHTTPHeaderField: "Authorization")
        let (listData, listResponse) = try await session.data(for: listRequest)
        guard let listHTTP = listResponse as? HTTPURLResponse else { throw ClickUpError.invalidResponse }
        guard (200...299).contains(listHTTP.statusCode) else { throw ClickUpError.httpError(listHTTP.statusCode) }
        if let existingID = try Self.parseListID(from: listData, matchingName: name) {
            return existingID
        }

        // Kein Treffer → neu anlegen.
        guard let createURL = Self.buildCreateListURL(baseURL: baseURL, folderID: folderID) else {
            throw ClickUpError.invalidResponse
        }
        var createRequest = URLRequest(url: createURL)
        createRequest.httpMethod = "POST"
        createRequest.setValue(credentials.apiToken, forHTTPHeaderField: "Authorization")
        createRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        createRequest.httpBody = try JSONEncoder().encode(["name": name])
        let (createData, createResponse) = try await session.data(for: createRequest)
        guard let createHTTP = createResponse as? HTTPURLResponse else { throw ClickUpError.invalidResponse }
        guard (200...299).contains(createHTTP.statusCode) else { throw ClickUpError.httpError(createHTTP.statusCode) }
        guard let newID = try Self.parseCreatedID(from: createData) else { throw ClickUpError.decodingFailed }
        return newID
    }

    public func createTask(listID: String, name: String) async throws -> String {
        guard let credentials = try? credentialsStore.load() else { throw ClickUpError.notConnected }
        guard let url = Self.buildCreateTaskURL(baseURL: baseURL, listID: listID) else {
            throw ClickUpError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(credentials.apiToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["name": name])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClickUpError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw ClickUpError.httpError(http.statusCode) }
        guard let newID = try Self.parseCreatedID(from: data) else { throw ClickUpError.decodingFailed }
        return newID
    }

    // MARK: - Reine, testbare Bausteine (kein Netzwerk/Keychain)

    static func buildTasksURL(baseURL: String, listID: String) -> URL? {
        let encodedList = listID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? listID
        var components = URLComponents(string: "\(baseURL)/list/\(encodedList)/task")
        components?.queryItems = [
            URLQueryItem(name: "archived", value: "false"),
            URLQueryItem(name: "include_closed", value: "false"),
            URLQueryItem(name: "subtasks", value: "false"),
        ]
        return components?.url
    }

    static func parseTasks(from data: Data) throws -> [ClickUpTask] {
        do {
            let decoded = try JSONDecoder().decode(ClickUpTasksResponse.self, from: data)
            return decoded.tasks.map { entity in
                ClickUpTask(
                    id: entity.id,
                    name: entity.name,
                    status: entity.status?.status ?? "",
                    dueDate: Self.date(fromEpochMillis: entity.dueDate),
                    assignee: entity.assignees?.first?.username,
                    isUrgent: entity.priority?.priority?.lowercased() == "urgent"
                )
            }
        } catch {
            throw ClickUpError.decodingFailed
        }
    }

    // ClickUp liefert due_date als Epoch-Millisekunden-String (oder null).
    static func date(fromEpochMillis millis: String?) -> Date? {
        guard let millis, let value = Double(millis) else { return nil }
        return Date(timeIntervalSince1970: value / 1000.0)
    }

    // MARK: Schreib-Bausteine (rein, testbar)

    static func buildFolderListsURL(baseURL: String, folderID: String) -> URL? {
        let encoded = folderID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? folderID
        return URL(string: "\(baseURL)/folder/\(encoded)/list")
    }

    static func buildCreateListURL(baseURL: String, folderID: String) -> URL? {
        let encoded = folderID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? folderID
        return URL(string: "\(baseURL)/folder/\(encoded)/list")
    }

    static func buildCreateTaskURL(baseURL: String, listID: String) -> URL? {
        let encoded = listID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? listID
        return URL(string: "\(baseURL)/list/\(encoded)/task")
    }

    /// Sucht in der Liste der Ordner-Listen exakt `matchingName`; nil = kein Treffer.
    static func parseListID(from data: Data, matchingName: String) throws -> String? {
        do {
            let decoded = try JSONDecoder().decode(ClickUpListsResponse.self, from: data)
            return decoded.lists.first { $0.name == matchingName }?.id
        } catch {
            throw ClickUpError.decodingFailed
        }
    }

    /// Liest die `id` aus einer Create-Antwort (Liste oder Task — beide liefern `{ "id": "..." }`).
    static func parseCreatedID(from data: Data) throws -> String? {
        do {
            return try JSONDecoder().decode(ClickUpCreatedEntity.self, from: data).id
        } catch {
            throw ClickUpError.decodingFailed
        }
    }
}

private struct ClickUpListsResponse: Decodable {
    var lists: [ClickUpListEntity]
    struct ClickUpListEntity: Decodable { var id: String; var name: String }
}

private struct ClickUpCreatedEntity: Decodable { var id: String }

// MARK: - Decodable-Spiegel der ClickUp-Antwort
private struct ClickUpTasksResponse: Decodable {
    var tasks: [ClickUpTaskEntity]
}

private struct ClickUpTaskEntity: Decodable {
    var id: String
    var name: String
    var status: StatusEntity?
    var dueDate: String?
    var priority: PriorityEntity?
    var assignees: [AssigneeEntity]?

    enum CodingKeys: String, CodingKey {
        case id, name, status, priority, assignees
        case dueDate = "due_date"
    }

    struct StatusEntity: Decodable { var status: String? }
    struct PriorityEntity: Decodable { var priority: String? }
    struct AssigneeEntity: Decodable { var username: String? }
}
