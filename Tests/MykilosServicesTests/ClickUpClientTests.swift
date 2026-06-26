import Testing
import Foundation
@testable import MykilosServices

struct ClickUpClientTests {

    private let baseURL = "https://api.clickup.com/api/v2"

    @Test func buildTasksURLEnthaeltListenIDUndOffenFilter() {
        let url = ClickUpClient.buildTasksURL(baseURL: baseURL, listID: "9012345")
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(components?.path == "/api/v2/list/9012345/task")
        #expect(items["archived"] == "false")
        #expect(items["include_closed"] == "false")
        #expect(items["subtasks"] == "false")
    }

    @Test func parseTasksDekodiertNameStatusFaelligkeitUndAssignee() throws {
        let json = """
        {
          "tasks": [
            {
              "id": "abc1",
              "name": "Bartresen-Detail freigeben",
              "status": { "status": "in progress" },
              "due_date": "1700000000000",
              "priority": { "priority": "urgent" },
              "assignees": [ { "username": "J. Berger" } ]
            },
            {
              "id": "abc2",
              "name": "Korpusmaße an Tischlerei",
              "status": { "status": "to do" },
              "due_date": null,
              "priority": null,
              "assignees": []
            }
          ]
        }
        """
        let tasks = try ClickUpClient.parseTasks(from: Data(json.utf8))

        #expect(tasks.count == 2)
        #expect(tasks[0].id == "abc1")
        #expect(tasks[0].name == "Bartresen-Detail freigeben")
        #expect(tasks[0].status == "in progress")
        #expect(tasks[0].isUrgent == true)
        #expect(tasks[0].assignee == "J. Berger")
        #expect(tasks[0].dueDate == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(tasks[1].isUrgent == false)
        #expect(tasks[1].assignee == nil)
        #expect(tasks[1].dueDate == nil)
    }

    @Test func parseTasksLeereListe() throws {
        let json = """
        { "tasks": [] }
        """
        let tasks = try ClickUpClient.parseTasks(from: Data(json.utf8))
        #expect(tasks.isEmpty)
    }

    @Test func parseTasksWirftBeiKaputtemJSON() {
        #expect(throws: ClickUpError.decodingFailed) {
            _ = try ClickUpClient.parseTasks(from: Data("kein json".utf8))
        }
    }

    @Test func dateFromEpochMillisKonvertiertUndFaelltAufNilZurueck() {
        #expect(ClickUpClient.date(fromEpochMillis: "1700000000000") == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(ClickUpClient.date(fromEpochMillis: nil) == nil)
        #expect(ClickUpClient.date(fromEpochMillis: "keine zahl") == nil)
    }

    @Test func tasksWirftNotConnectedOhneCredentials() async {
        let store = InMemoryClickUpCredentialsStore()
        let client = ClickUpClient(credentialsStore: store)

        do {
            _ = try await client.tasks(listID: "9012345")
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? ClickUpError == .notConnected)
        }
    }
}

// MARK: - InMemoryClickUpCredentialsStore

final class InMemoryClickUpCredentialsStore: ClickUpCredentialsStoring, @unchecked Sendable {
    private var stored: ClickUpCredentials?

    init(credentials: ClickUpCredentials? = nil) {
        self.stored = credentials
    }

    func store(_ credentials: ClickUpCredentials) throws {
        self.stored = credentials
    }

    func load() throws -> ClickUpCredentials? {
        stored
    }

    func clear() throws {
        stored = nil
    }
}
