import Foundation
import MykilosKit

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
    /// Numerische ClickUp-Member-ID des ersten Zugewiesenen (falls die API sie liefert) —
    /// zum Abgleich mit `ResidentIdentity.clickUpMemberID` für "meine Aufgaben"-Filter.
    /// `assignee` (Username) reicht dafür NICHT, da beide Felder unterschiedliche Formate sind.
    public var assigneeID: String?
    public var isUrgent: Bool
    /// Volle Prio-Stufe (Aufgaben-Spalte 2, 2026-07-07) — additiv neben `isUrgent`,
    /// das weiterhin für bestehende Aufrufer (TasksWidget, AssistantTool) unverändert bleibt.
    public var priority: ClickUpPriority?
    /// Custom Field `project_phase` (Testspace, per Task) — falls auf dieser Aufgabe gesetzt.
    public var projectPhase: ClickUpProjectPhase?

    public init(id: String, name: String, status: String,
                dueDate: Date? = nil, assignee: String? = nil, assigneeID: String? = nil,
                isUrgent: Bool = false, priority: ClickUpPriority? = nil,
                projectPhase: ClickUpProjectPhase? = nil) {
        self.id = id
        self.name = name
        self.status = status
        self.dueDate = dueDate
        self.assignee = assignee
        self.assigneeID = assigneeID
        self.isUrgent = isUrgent
        self.priority = priority
        self.projectPhase = projectPhase
    }
}

// MARK: - ClickUpPriority (Aufgaben-Spalte 2, 2026-07-07)
// ClickUps 4 native Prio-Stufen, roh aus dem `priority.priority`-String der API.
public enum ClickUpPriority: String, CaseIterable, Sendable, Equatable {
    case urgent, high, normal, low

    public var label: String {
        switch self {
        case .urgent: "Dringend"
        case .high: "Hoch"
        case .normal: "Normal"
        case .low: "Niedrig"
        }
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
    /// Liest die 13 Projekt-Custom-Fields der Liste als typisiertes `ClickUpProjektMeta`
    /// (CLICKUP_DATENINTEGRATION_PLAN Schritt 2 — rein lesend). Default-Extension liefert
    /// `.empty`, damit bestehende Test-Doubles/Fakes nicht angefasst werden müssen; der echte
    /// `ClickUpClient` überschreibt mit dem Live-Fetch + Schaltschrank-Mapper.
    func projektMeta(listID: String) async throws -> ClickUpProjektMeta
}

public extension ClickUpFetching {
    func projektMeta(listID: String) async throws -> ClickUpProjektMeta { .empty }
}

// MARK: - ClickUpTaskWriting (2026-07-04)
// Interaktive Write-Basics FÜR DEN NUTZER (nicht das automatische Provisioning oben):
// Aufgabe anlegen, Status ändern/erledigt markieren. EISERNE REGELN (nicht verhandelbar):
//   - KI weist NIE zu ([[aufgaben-nur-mensch-zu-mensch-regel]]) — es gibt hier bewusst KEINE
//     assignee-Methode. Eine simulierte Zuweisung ist nur ein Text-Marker (Ghost-Kürzel im
//     `content`/Beschreibungsfeld), NIE das native ClickUp-`assignees`-Feld.
//   - Entwicklung/Test NUR im Testspace `90128024109` ([[clickup-ghost-persona-rule]]) — dieser
//     Client selbst kennt keinen Space und erzwingt das nicht technisch; die aufrufende Stelle
//     ist dafür verantwortlich, in dieser Phase nur Testspace-Listen-IDs zu übergeben.
public protocol ClickUpTaskWriting: Sendable {
    /// Legt eine Aufgabe an. `content` ist die Beschreibung (ClickUp-Feld `content`) — Träger für
    /// einen optionalen Ghost-Kürzel-Marker ("Zugewiesen (simuliert): Jo"), NIE ein echtes Feld.
    func createTask(listID: String, name: String, content: String?) async throws -> String
    /// Setzt den Status einer Aufgabe (Statuswerte sind pro Liste konfiguriert — der Aufrufer
    /// kennt sie aus den bereits geladenen `ClickUpTask.status`-Werten der Liste).
    func setStatus(taskID: String, status: String) async throws
}

// MARK: - ClickUpProjectProvisioning
// mykilOS 8, Studio-OS-Rollout (2026-07-02): der Schreibpfad für die Projekt-Geburt
// (ProjektProvisioningService, Schritt `.clickUpStruktur`). Getrennt vom reinen
// Lese-Widget-Pfad (`ClickUpFetching`) — Views/Widgets rufen das NIE direkt auf,
// nur der Provisioning-Service (Karte→Bestätigung→Audit, wie Drive/Airtable).
public protocol ClickUpProjectProvisioning: Sendable {
    /// Findet eine Liste mit exaktem Namen im Ordner, oder legt sie neu an (idempotent).
    /// `content` (Beschreibung: Kunde/Drive-Link/Projektnummer) wird NUR beim Neu-Anlegen
    /// gesetzt — eine bereits gefundene Liste wird nicht überschrieben.
    func findOrCreateList(folderID: String, name: String, content: String?) async throws -> String
    /// Legt einen Task in der Liste an. Kein Duplikat-Check hier — der Aufrufer prüft
    /// vorher über `tasks(listID:)`, ob der Name schon existiert.
    func createTask(listID: String, name: String) async throws -> String
}

// MARK: - ClickUpClient
// Liest die offenen Aufgaben einer ClickUp-Liste des verbundenen Accounts.
// Auth: Personal-API-Token direkt im Authorization-Header (kein "Bearer").
public struct ClickUpClient: ClickUpFetching, ClickUpProjectProvisioning, ClickUpTaskWriting {
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

    /// Liest die Projekt-Custom-Fields der Liste (dieselbe `tasks`-Antwort, anderer Decodable-Pfad).
    /// Rein lesend: `ClickUpProjektMetaMapper` hebt die generischen `custom_fields` über den
    /// umsteckbaren Schaltschrank in ein typisiertes `ClickUpProjektMeta`. Kein Schreiben.
    public func projektMeta(listID: String) async throws -> ClickUpProjektMeta {
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

        return try ClickUpProjektMetaMapper.parse(from: data)
    }

    // MARK: - Schreiben (Provisioning, Schritt `.clickUpStruktur`)

    public func findOrCreateList(folderID: String, name: String, content: String? = nil) async throws -> String {
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

        // Kein Treffer → neu anlegen. `content` (Kunde/Drive-Link/Projektnummer) nur hier gesetzt.
        guard let createURL = Self.buildCreateListURL(baseURL: baseURL, folderID: folderID) else {
            throw ClickUpError.invalidResponse
        }
        var createRequest = URLRequest(url: createURL)
        createRequest.httpMethod = "POST"
        createRequest.setValue(credentials.apiToken, forHTTPHeaderField: "Authorization")
        createRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: String] = ["name": name]
        if let content, content.isEmpty == false { body["content"] = content }
        createRequest.httpBody = try JSONEncoder().encode(body)
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

    // MARK: - Interaktive Write-Basics (ClickUpTaskWriting, 2026-07-04)

    public func createTask(listID: String, name: String, content: String? = nil) async throws -> String {
        guard let credentials = try? credentialsStore.load() else { throw ClickUpError.notConnected }
        guard let url = Self.buildCreateTaskURL(baseURL: baseURL, listID: listID) else {
            throw ClickUpError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(credentials.apiToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: String] = ["name": name]
        if let content, content.isEmpty == false { body["content"] = content }
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClickUpError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw ClickUpError.httpError(http.statusCode) }
        guard let newID = try Self.parseCreatedID(from: data) else { throw ClickUpError.decodingFailed }
        return newID
    }

    public func setStatus(taskID: String, status: String) async throws {
        guard let credentials = try? credentialsStore.load() else { throw ClickUpError.notConnected }
        guard let url = Self.buildUpdateTaskURL(baseURL: baseURL, taskID: taskID) else {
            throw ClickUpError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(credentials.apiToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["status": status])
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClickUpError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw ClickUpError.httpError(http.statusCode) }
    }

    static func buildUpdateTaskURL(baseURL: String, taskID: String) -> URL? {
        let encoded = taskID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? taskID
        return URL(string: "\(baseURL)/task/\(encoded)")
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
                let phaseIndex = entity.customFields?.first(where: { $0.name == "project_phase" })?.value
                return ClickUpTask(
                    id: entity.id,
                    name: entity.name,
                    status: entity.status?.status ?? "",
                    dueDate: Self.date(fromEpochMillis: entity.dueDate),
                    assignee: entity.assignees?.first?.username,
                    assigneeID: entity.assignees?.first?.id.map(String.init),
                    isUrgent: entity.priority?.priority?.lowercased() == "urgent",
                    priority: ClickUpPriority(rawValue: entity.priority?.priority?.lowercased() ?? ""),
                    projectPhase: phaseIndex.flatMap(ClickUpProjectPhase.init(rawValue:))
                )
            }
        } catch {
            throw ClickUpError.decodingFailed
        }
    }

    /// Die am weitesten fortgeschrittene `project_phase` unter den geladenen Aufgaben — der
    /// pragmatische „Stand des Projekts laut ClickUp"-Signal, solange keine einzelne Task als
    /// Projekt-Meister-Datensatz existiert. `nil`, wenn keine Aufgabe das Feld gesetzt hat.
    public static func projectPhase(from tasks: [ClickUpTask]) -> ClickUpProjectPhase? {
        tasks.compactMap(\.projectPhase).max(by: { $0.rawValue < $1.rawValue })
    }

    // ClickUp liefert due_date als Epoch-Millisekunden-String (oder null).
    static func date(fromEpochMillis millis: String?) -> Date? {
        guard let millis, let value = Double(millis) else { return nil }
        return Date(timeIntervalSince1970: value / 1000.0)
    }

    // Der Projekt-Meta-Übertrag (`custom_fields` → `ClickUpProjektMeta` über die Route-Tabelle)
    // liegt bewusst NEBENAN in ClickUpProjektMetaMapper.swift (`ClickUpProjektMetaMapper.parse`) —
    // eigener Decodable-Pfad, hält diesen Client schlank und den Meta-Schaltschrank an einem Ort.

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
    var customFields: [CustomFieldEntity]?

    enum CodingKeys: String, CodingKey {
        case id, name, status, priority, assignees
        case dueDate = "due_date"
        case customFields = "custom_fields"
    }

    struct StatusEntity: Decodable { var status: String? }
    struct PriorityEntity: Decodable { var priority: String? }
    struct AssigneeEntity: Decodable { var id: Int?; var username: String? }

    // Custom Fields sind je nach Feldtyp heterogen (Bool/String/Int/null) — uns interessiert
    // hier nur `project_phase` (drop_down → `value` ist der Orderindex der Option als Int).
    // Andere Feldtypen tolerant überspringen (nil), statt das ganze Parsing zu brechen.
    // Der typisierte Projekt-Meta-Übertrag (13 Felder) läuft separat über
    // ClickUpProjektMetaMapper.swift mit eigenem Decodable-Pfad.
    struct CustomFieldEntity: Decodable {
        var name: String
        var value: Int?

        private enum CodingKeys: String, CodingKey { case name, value }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            value = try? container.decode(Int.self, forKey: .value)
        }
    }
}
