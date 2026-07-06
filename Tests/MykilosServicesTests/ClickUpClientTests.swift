import Testing
import Foundation
import MykilosKit
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
              "assignees": [ { "id": 42, "username": "J. Berger" } ]
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
        #expect(tasks[0].priority == .urgent)
        #expect(tasks[0].assignee == "J. Berger")
        #expect(tasks[0].assigneeID == "42")
        #expect(tasks[0].dueDate == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(tasks[1].isUrgent == false)
        #expect(tasks[1].priority == nil)
        #expect(tasks[1].assignee == nil)
        #expect(tasks[1].assigneeID == nil)
        #expect(tasks[1].dueDate == nil)
    }

    // Aufgaben-Spalte 2 (2026-07-07): volle Prio-Granularität, nicht nur isUrgent.
    @Test func parseTasksDekodiertAllePrioStufen() throws {
        let stufen: [(String, ClickUpPriority)] = [
            ("urgent", .urgent), ("high", .high), ("normal", .normal), ("low", .low),
        ]
        for (raw, erwartet) in stufen {
            let json = """
            { "tasks": [ { "id": "x", "name": "n", "status": { "status": "open" },
                           "due_date": null, "priority": { "priority": "\(raw)" }, "assignees": [] } ] }
            """
            let tasks = try ClickUpClient.parseTasks(from: Data(json.utf8))
            #expect(tasks.first?.priority == erwartet)
        }
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

    // MARK: - ClickUpTaskWriting (2026-07-04)

    @Test func buildUpdateTaskURLEnthaeltTaskID() {
        let url = ClickUpClient.buildUpdateTaskURL(baseURL: baseURL, taskID: "abc123")
        #expect(url?.absoluteString == "https://api.clickup.com/api/v2/task/abc123")
    }

    @Test func createTaskWirftNotConnectedOhneCredentials() async {
        let store = InMemoryClickUpCredentialsStore()
        let client = ClickUpClient(credentialsStore: store)

        do {
            _ = try await client.createTask(listID: "9012345", name: "Testaufgabe", content: "Zugewiesen (simuliert): Jo")
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? ClickUpError == .notConnected)
        }
    }

    @Test func setStatusWirftNotConnectedOhneCredentials() async {
        let store = InMemoryClickUpCredentialsStore()
        let client = ClickUpClient(credentialsStore: store)

        do {
            try await client.setStatus(taskID: "abc123", status: "complete")
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? ClickUpError == .notConnected)
        }
    }

    // MARK: - project_phase Custom Field (2026-07-04)

    @Test func parseTasksDekodiertProjectPhaseAusCustomFields() throws {
        let json = """
        {
          "tasks": [
            {
              "id": "t1",
              "name": "Aufmaß terminieren",
              "status": { "status": "to do" },
              "custom_fields": [
                { "id": "936d3989-9236-4673-821e-755411b9d042", "name": "project_phase", "value": 4 },
                { "id": "5764d5ed-c9c6-4ea8-9446-033faad12ff0", "name": "review_required", "value": true }
              ]
            },
            {
              "id": "t2",
              "name": "Ohne Phase",
              "status": { "status": "to do" },
              "custom_fields": [
                { "id": "3fe9a608-b25c-469d-adf2-01b82cbe7641", "name": "drive_folder_url", "value": null }
              ]
            }
          ]
        }
        """
        let tasks = try ClickUpClient.parseTasks(from: Data(json.utf8))
        #expect(tasks[0].projectPhase == .ausfuehrung)
        #expect(tasks[1].projectPhase == nil)
    }

    @Test func parseTasksToleriertFehlendeCustomFields() throws {
        let json = """
        { "tasks": [ { "id": "t1", "name": "Ohne Custom Fields", "status": { "status": "to do" } } ] }
        """
        let tasks = try ClickUpClient.parseTasks(from: Data(json.utf8))
        #expect(tasks[0].projectPhase == nil)
    }

    @Test func projectPhaseNimmtDieWeitestFortgeschritteneStufe() {
        let tasks = [
            ClickUpTask(id: "a", name: "A", status: "", projectPhase: .briefing),
            ClickUpTask(id: "b", name: "B", status: "", projectPhase: .ausfuehrung),
            ClickUpTask(id: "c", name: "C", status: "", projectPhase: nil),
        ]
        #expect(ClickUpClient.projectPhase(from: tasks) == .ausfuehrung)
    }

    @Test func projectPhaseNilOhneGesetztesFeld() {
        let tasks = [ClickUpTask(id: "a", name: "A", status: "")]
        #expect(ClickUpClient.projectPhase(from: tasks) == nil)
    }

    @Test func mykilosStageMappingFuerAlle7Phasen() {
        #expect(ClickUpProjectPhase.briefing.mykilosStage == .akquise)
        #expect(ClickUpProjectPhase.planung.mykilosStage == .planung)
        #expect(ClickUpProjectPhase.angebot.mykilosStage == .angebot)
        #expect(ClickUpProjectPhase.bestellung.mykilosStage == .ausfuehrung)
        #expect(ClickUpProjectPhase.ausfuehrung.mykilosStage == .ausfuehrung)
        #expect(ClickUpProjectPhase.abschluss.mykilosStage == .abschluss)
        #expect(ClickUpProjectPhase.service.mykilosStage == .abschluss)
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
