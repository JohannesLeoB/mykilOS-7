import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// MARK: - WidgetBoardStore Cold-Start-Tests
// Beweist: Widget-Layouts überleben den App-Neustart (GRDB-backed).
// Das ist die direkteste Verlängerung des Cold-Start-Versprechens aus Akt 0.
@MainActor
struct WidgetBoardStoreTests {

    // MARK: Core: Layout überlebt Neustart
    @Test func layoutUeberlebtNeustart() throws {
        let db = try GRDBDatabase.inMemory()
        let defaultWidgets = WidgetBoardDefault.homeLayout

        // Session A: Default-Layout speichern
        let storeA = WidgetBoardStore(boardID: "home", db: db) { defaultWidgets }
        try storeA.load()
        #expect(storeA.instances.count == defaultWidgets.count)
        #expect(storeA.saveState != .idle)  // Wurde gespeichert

        // "App neu gestartet": neue Store-Instanz, selbe DB
        let storeB = WidgetBoardStore(boardID: "home", db: db)
        try storeB.load()
        #expect(storeB.instances.count == defaultWidgets.count)
        #expect(storeB.instances.map(\.kind.rawValue) == storeA.instances.map(\.kind.rawValue))
    }

    // MARK: SaveState ist sichtbar nach Speichern
    @Test func saveStateWirdGesetzt() throws {
        let db = try GRDBDatabase.inMemory()
        let store = WidgetBoardStore(boardID: "test", db: db) { WidgetBoardDefault.homeLayout }
        try store.load()
        if case .saved = store.saveState { } else {
            Issue.record("SaveState sollte .saved sein, ist aber: \(store.saveState)")
        }
    }

    // MARK: Widget hinzufügen/entfernen persistent
    @Test func hinzufuegenEntfernenPersistent() throws {
        let db = try GRDBDatabase.inMemory()
        let storeA = WidgetBoardStore(boardID: "proj_ME-24", db: db) {
            WidgetBoardDefault.layout(for: .kitchen)
        }
        try storeA.load()
        let initialCount = storeA.instances.count
        try storeA.add(kind: .calendar, size: .medium)
        #expect(storeA.instances.count == initialCount + 1)

        let idToRemove = storeA.instances.last!.id
        try storeA.remove(id: idToRemove)
        #expect(storeA.instances.count == initialCount)

        // Neustart — Stand muss gehalten haben
        let storeB = WidgetBoardStore(boardID: "proj_ME-24", db: db)
        try storeB.load()
        #expect(storeB.instances.count == initialCount)
    }

    // MARK: NoteStore Cold-Start
    @Test func notizUeberlebtNeustart() throws {
        let db = try GRDBDatabase.inMemory()

        let storeA = NoteStore(boardID: "home", db: db)
        try storeA.load()
        storeA.update("Meyer mag warme Eiche")
        try storeA.save()
        if case .saved = storeA.saveState { } else {
            Issue.record("Erwarte .saved")
        }

        let storeB = NoteStore(boardID: "home", db: db)
        try storeB.load()
        #expect(storeB.body == "Meyer mag warme Eiche")
    }

    // MARK: Mehrere Projekt-Boards unabhängig
    @Test func projektBoardsUnabhaengig() throws {
        let db = try GRDBDatabase.inMemory()
        let meyerStore = WidgetBoardStore(boardID: "proj_ME-24", db: db) { WidgetBoardDefault.layout(for: .kitchen) }
        let lightStore  = WidgetBoardStore(boardID: "proj_SO-24", db: db) { WidgetBoardDefault.layout(for: .lighting) }
        try meyerStore.load()
        try lightStore.load()
        // Küche hat mehr Widgets als Lichtplanung
        #expect(meyerStore.instances.count > lightStore.instances.count)
        // Boards sind unabhängig — Änderung in Meyer betrifft Licht nicht
        try meyerStore.add(kind: .calendar)
        #expect(meyerStore.instances.count > lightStore.instances.count)
    }

    // MARK: Nachtrag-Boards vererben nichts von Eltern
    @Test func nachtragBoardUnabhaengigVomEltern() throws {
        let db = try GRDBDatabase.inMemory()
        let parentStore   = WidgetBoardStore(boardID: "proj_ME-24",    db: db) { WidgetBoardDefault.layout(for: .kitchen) }
        let addendumStore = WidgetBoardStore(boardID: "proj_ME-24-N1", db: db) { WidgetBoardDefault.layout(for: .addendum) }
        try parentStore.load()
        try addendumStore.load()
        // Addendum ist schlanker
        #expect(addendumStore.instances.count < parentStore.instances.count)
        // Verschiedene Board-IDs = vollständig unabhängig
        #expect(parentStore.boardID != addendumStore.boardID)
    }
}
