import Testing
import Foundation
import MykilosKit
import MykilosServices
@testable import MykilosApp

// MARK: - ClickUpAufgabenLoader (Aufgaben-Spalte 2, 2026-07-07)
// Reine Aggregations-/Sortier-/Fehlerlogik, getrennt von der View getestet (gleiches
// Muster wie HeuteAnstehendView.ScheduleLoader).

@MainActor
struct ClickUpAufgabenLoaderTests {

    @Test func aggregiertUndTaggtMitProjekt() async {
        let client = FakeClickUp(byList: [
            "L1": [ClickUpTask(id: "1", name: "Aufmaß", status: "open")],
            "L2": [ClickUpTask(id: "2", name: "Angebot", status: "in progress")],
        ])
        let loader = ClickUpAufgabenLoader(clickUp: client)
        await loader.load(refs: [
            ProjectClickUpRef(projectNumber: "2026-001", title: "Cirnavuk", listID: "L1"),
            ProjectClickUpRef(projectNumber: "2026-002", title: "Hustadt", listID: "L2"),
        ])
        #expect(loader.items.count == 2)
        #expect(loader.items.contains { $0.task.name == "Aufmaß" && $0.projectNumber == "2026-001" })
        #expect(loader.items.contains { $0.task.name == "Angebot" && $0.projectTitle == "Hustadt" })
        #expect(loader.loaded == true)
        #expect(loader.fehlerText == nil)
    }

    @Test func sortiertFrueheFaelligkeitZuerstOhneFaelligkeitZuletzt() async {
        let spaet = Date(timeIntervalSince1970: 2_000_000)
        let frueh = Date(timeIntervalSince1970: 1_000_000)
        let client = FakeClickUp(byList: [
            "L1": [
                ClickUpTask(id: "1", name: "spät", status: "open", dueDate: spaet),
                ClickUpTask(id: "2", name: "früh", status: "open", dueDate: frueh),
                ClickUpTask(id: "3", name: "ohne", status: "open"),
            ],
        ])
        let loader = ClickUpAufgabenLoader(clickUp: client)
        await loader.load(refs: [ProjectClickUpRef(projectNumber: "2026-001", title: "Cirnavuk", listID: "L1")])
        #expect(loader.items.map(\.task.name) == ["früh", "spät", "ohne"])
    }

    @Test func fehlerhafteListeWirdUebersprungenAndereBleiben() async {
        let client = FakeClickUp(byList: ["L1": [ClickUpTask(id: "1", name: "Aufmaß", status: "open")]],
                                 failing: ["L2"])
        let loader = ClickUpAufgabenLoader(clickUp: client)
        await loader.load(refs: [
            ProjectClickUpRef(projectNumber: "2026-001", title: "Cirnavuk", listID: "L1"),
            ProjectClickUpRef(projectNumber: "2026-002", title: "Hustadt", listID: "L2"),
        ])
        #expect(loader.items.count == 1)
        #expect(loader.items.first?.projectNumber == "2026-001")
        #expect(loader.fehlerText != nil)   // sichtbarer Hinweis, kein stiller Datenverlust
    }

    @Test func keineProjekteMitListeErgibtLeerOhneFehler() async {
        let loader = ClickUpAufgabenLoader(clickUp: FakeClickUp(byList: [:]))
        await loader.load(refs: [])
        #expect(loader.items.isEmpty)
        #expect(loader.loaded == true)
        #expect(loader.fehlerText == nil)
    }

    @Test func notConnectedIstLeerNichtFehler() async {
        let client = FakeClickUp(byList: [:], notConnected: ["L1"])
        let loader = ClickUpAufgabenLoader(clickUp: client)
        await loader.load(refs: [ProjectClickUpRef(projectNumber: "2026-001", title: "Cirnavuk", listID: "L1")])
        #expect(loader.items.isEmpty)
        #expect(loader.fehlerText == nil)   // notConnected ist bewusst kein Fehlerbanner
    }
}

private struct FakeClickUp: ClickUpFetching {
    let byList: [String: [ClickUpTask]]
    var failing: Set<String> = []
    var notConnected: Set<String> = []
    func tasks(listID: String) async throws -> [ClickUpTask] {
        if notConnected.contains(listID) { throw ClickUpError.notConnected }
        if failing.contains(listID) { throw ClickUpError.httpError(500) }
        return byList[listID] ?? []
    }
}
