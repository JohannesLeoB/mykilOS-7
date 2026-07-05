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

    // MARK: NoteStore: erneutes load() darf ungespeicherte Eingaben nicht killen
    // Regression: onAppear/.task feuerten load() wiederholt und überschrieben den
    // gerade getippten Text mit dem alten DB-Stand (stiller Datenverlust).
    @Test func loadClobbertKeineUngespeichertenEingaben() throws {
        let db = try GRDBDatabase.inMemory()

        // Vorbestand in der DB: "alt"
        let seed = NoteStore(boardID: "proj_ME-24", db: db)
        try seed.load()
        seed.update("alter Stand")
        try seed.save()

        // Frische Instanz wie beim Öffnen: lädt "alt", User tippt "neu",
        // dann feuert load() erneut (Board-Re-Render / onAppear).
        let store = NoteStore(boardID: "proj_ME-24", db: db)
        try store.load()
        #expect(store.body == "alter Stand")
        #expect(store.hasUnsavedChanges == false)
        store.update("frisch getippt, noch nicht gespeichert")
        #expect(store.hasUnsavedChanges == true)
        try store.load()   // darf NICHT zurück auf "alter Stand" springen
        #expect(store.body == "frisch getippt, noch nicht gespeichert")
    }

    // MARK: AuditStore Cold-Start
    @Test func auditEntryUeberlebtNeustart() throws {
        let db = try GRDBDatabase.inMemory()
        let entry = AuditEntry(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            timestamp: Date(timeIntervalSince1970: 1_806_086_400),
            actorUserID: "local-user",
            projectID: "ME-24",
            action: .offerImported,
            summary: "Arbeitsplatte als Angebot markiert"
        )

        let storeA = AuditStore(db: db)
        try storeA.load()
        try storeA.append(entry)

        let storeB = AuditStore(db: db)
        try storeB.load()

        #expect(storeB.entries.count == 1)
        #expect(storeB.entries.first?.id == entry.id)
        #expect(storeB.entries.first?.timestamp == entry.timestamp)
        #expect(storeB.entries.first?.actorUserID == entry.actorUserID)
        #expect(storeB.entries.first?.projectID == entry.projectID)
        #expect(storeB.entries.first?.action == entry.action)
        #expect(storeB.entries.first?.summary == entry.summary)
    }

    // MARK: Mehrere Projekt-Boards unabhängig (Option A: alle starten mit 7 Widgets)
    @Test func projektBoardsUnabhaengig() throws {
        let db = try GRDBDatabase.inMemory()
        let meyerStore = WidgetBoardStore(boardID: "proj_ME-24", db: db) { WidgetBoardDefault.layout(for: .kitchen) }
        let lightStore  = WidgetBoardStore(boardID: "proj_SO-24", db: db) { WidgetBoardDefault.layout(for: .lighting) }
        try meyerStore.load()
        try lightStore.load()
        // Beide starten mit dem kanonischen Vollsatz
        #expect(meyerStore.instances.count == WidgetBoardDefault.canonicalLayout.count)
        #expect(lightStore.instances.count  == WidgetBoardDefault.canonicalLayout.count)
        // Boards sind unabhängig — Änderung in Meyer betrifft Licht nicht
        try meyerStore.add(kind: .mail)
        #expect(meyerStore.instances.count > lightStore.instances.count)
        #expect(meyerStore.boardID != lightStore.boardID)
    }

    // MARK: Nachtrag-Boards vererben nichts von Eltern (boardID-Isolation)
    @Test func nachtragBoardUnabhaengigVomEltern() throws {
        let db = try GRDBDatabase.inMemory()
        let parentStore   = WidgetBoardStore(boardID: "proj_ME-24",    db: db) { WidgetBoardDefault.layout(for: .kitchen) }
        let addendumStore = WidgetBoardStore(boardID: "proj_ME-24-N1", db: db) { WidgetBoardDefault.layout(for: .addendum) }
        try parentStore.load()
        try addendumStore.load()
        // Option A: beide starten mit demselben kanonischen Widget-Satz
        #expect(parentStore.instances.count   == WidgetBoardDefault.canonicalLayout.count)
        #expect(addendumStore.instances.count == WidgetBoardDefault.canonicalLayout.count)
        // Verschiedene Board-IDs = vollständig unabhängig
        #expect(parentStore.boardID != addendumStore.boardID)
    }

    // MARK: Nicht-destruktive Migration: alte Boards bekommen fehlende Widgets
    @Test func reconcileErganztFehlende() throws {
        let db = try GRDBDatabase.inMemory()
        // Board mit altem, schlankem Layout (nur 4 Widgets) anlegen
        let altLayout: [WidgetInstance] = [
            WidgetInstance(kind: .drive,     size: .wide,   position: 0),
            WidgetInstance(kind: .notes,     size: .medium, position: 1),
            WidgetInstance(kind: .tasks,     size: .wide,   position: 2),
            WidgetInstance(kind: .assistant, size: .full,   position: 3),
        ]
        let seedStore = WidgetBoardStore(boardID: "proj_ALT", db: db) { altLayout }
        try seedStore.load()
        #expect(seedStore.instances.count == 4)

        // Neustart mit canonicalLayout — reconcile ergänzt fehlende 3 Widgets
        let freshStore = WidgetBoardStore(boardID: "proj_ALT", db: db) {
            WidgetBoardDefault.canonicalLayout
        }
        try freshStore.load()
        #expect(freshStore.instances.count == WidgetBoardDefault.canonicalLayout.count)
        let kinds = freshStore.instances.map(\.kind)
        // Ursprüngliche 4 erhalten
        #expect(kinds.contains(.drive))
        #expect(kinds.contains(.notes))
        #expect(kinds.contains(.tasks))
        #expect(kinds.contains(.assistant))
        // Neue 3 ergänzt
        #expect(kinds.contains(.contacts))
        #expect(kinds.contains(.cash))
        #expect(kinds.contains(.calendar))
        // Erste 4 Positionen unverändert
        #expect(freshStore.instances[0].kind == .drive)
        #expect(freshStore.instances[1].kind == .notes)
        #expect(freshStore.instances[2].kind == .tasks)
        #expect(freshStore.instances[3].kind == .assistant)
    }

    // MARK: Reconcile ist idempotent — mehrfaches Laden dupliziert nichts
    @Test func reconcileIstIdempotent() throws {
        let db = try GRDBDatabase.inMemory()
        let store = WidgetBoardStore(boardID: "proj_X", db: db) { WidgetBoardDefault.canonicalLayout }
        try store.load()
        let countAfterFirst = store.instances.count
        try store.load()
        #expect(store.instances.count == countAfterFirst)
    }

    // MARK: Barcode-Widget landet per Nachzügler-Migration aufs Home-Board + überlebt Neustart
    // Beweist die 2026-07-05-Migration: ein bestehendes Home-Board (Vor-Barcode-Stand)
    // bekommt das neue Barcode-Widget ergänzt und behält es über Neustarts.
    @Test func barcodeLandetAufHomeBoardUndUeberlebtNeustart() throws {
        let db = try GRDBDatabase.inMemory()
        // Session A: altes Home-Board OHNE Barcode
        let altHome: [WidgetInstance] = [
            WidgetInstance(kind: .focus,          size: .wide,   position: 0),
            WidgetInstance(kind: .notes,          size: .medium, position: 1),
            WidgetInstance(kind: .projectFaves,   size: .full,   position: 2),
            WidgetInstance(kind: .recentActivity, size: .wide,   position: 3),
            WidgetInstance(kind: .clockodo,       size: .medium, position: 4),
        ]
        let storeA = WidgetBoardStore(boardID: "home", db: db) { altHome }
        try storeA.load()
        #expect(storeA.instances.contains(where: { $0.kind == .barcode }) == false)

        // Session B: App aktualisiert — homeLayout enthält jetzt .barcode → Migration ergänzt
        let storeB = WidgetBoardStore(boardID: "home", db: db) { WidgetBoardDefault.homeLayout }
        try storeB.load()
        #expect(storeB.instances.contains(where: { $0.kind == .barcode }))
        #expect(storeB.instances.contains(where: { $0.kind == .rechner }))

        // Session C: Neustart — beide bleiben persistent
        let storeC = WidgetBoardStore(boardID: "home", db: db) { WidgetBoardDefault.homeLayout }
        try storeC.load()
        #expect(storeC.instances.contains(where: { $0.kind == .barcode }))
        #expect(storeC.instances.contains(where: { $0.kind == .rechner }))
    }
}
