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

// MARK: - ClickUpClient
// Liest die offenen Aufgaben einer ClickUp-Liste des verbundenen Accounts.
// Auth: Personal-API-Token direkt im Authorization-Header (kein "Bearer").
public struct ClickUpClient: ClickUpFetching {
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
}

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
