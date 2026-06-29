import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

// MARK: - AssistantNotesStore (S4) — Cold-Start + CRUD

struct AssistantNotesStoreTests {

    @Test func notizUeberlebtNeustart() async throws {
        let db = try GRDBDatabase.inMemory()
        let storeA = AssistantNotesStore(db: db)
        let note = try await storeA.create("Miele Brüheinheit — Frau Jacob 0403005018048")

        // Neue Instanz auf derselben DB → laden → identisch.
        let storeB = AssistantNotesStore(db: db)
        let loaded = try await storeB.all()
        #expect(loaded.count == 1)
        #expect(loaded.first?.id == note.id)
        #expect(loaded.first?.body == "Miele Brüheinheit — Frau Jacob 0403005018048")
    }

    @Test func loeschenPerRefUndTextfund() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = AssistantNotesStore(db: db)
        let a = try await store.create("Angebot Hustadt nachfassen")
        _ = try await store.create("Material bei Blum bestellen")

        // per ID-Präfix (ref) löschen
        let deleted = try await store.delete(matching: a.ref)
        #expect(deleted?.id == a.id)

        // per Text-Teilstring finden
        let found = try await store.find(matching: "blum")
        #expect(found?.body.contains("Blum") == true)

        #expect(try await store.all().count == 1)
    }

    @Test func bearbeitenAendertTextUndPersistiert() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = AssistantNotesStore(db: db)
        let n = try await store.create("alt")
        let updated = try await store.update(matching: n.ref, newBody: "neu")
        #expect(updated?.body == "neu")

        let fresh = AssistantNotesStore(db: db)
        #expect(try await fresh.all().first?.body == "neu")
    }

    @Test func leereDatenbankLiefertKeineNotizen() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = AssistantNotesStore(db: db)
        #expect(try await store.all().isEmpty)
        #expect(try await store.delete(matching: "irgendwas") == nil)
    }

    // S10: Projekt-Scope. scoped(to:) liefert Projekt-Notizen + globale; nil = alle.
    @Test func scopedFiltertProjektPlusGlobal() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = AssistantNotesStore(db: db)
        try await store.create("global notiz")                        // projectID nil
        try await store.create("hustadt sache", projectID: "2026-024")
        try await store.create("andere sache", projectID: "2026-001")

        let hustadt = try await store.scoped(to: "2026-024")
        #expect(hustadt.count == 2)                                   // projekt + global
        #expect(hustadt.contains { $0.body == "hustadt sache" })
        #expect(hustadt.contains { $0.body == "global notiz" })
        #expect(hustadt.contains { $0.body == "andere sache" } == false)

        #expect(try await store.scoped(to: nil).count == 3)          // nil → alle
        #expect(try await store.all().count == 3)
    }

    // S10 Cold-Start: projectID überlebt den Neustart.
    @Test func projektIDUeberlebtNeustart() async throws {
        let db = try GRDBDatabase.inMemory()
        try await AssistantNotesStore(db: db).create("für projekt", projectID: "2026-024")
        let fresh = AssistantNotesStore(db: db)
        #expect(try await fresh.all().first?.projectID == "2026-024")
    }
}

// MARK: - Notiz-Tools über die Registry

struct NoteToolsTests {
    private func registry(_ db: GRDBDatabase) -> AssistantToolRegistry {
        AssistantToolRegistry.standard(notesStore: AssistantNotesStore(db: db))
    }

    @Test func createUndListUeberRegistry() async throws {
        let db = try GRDBDatabase.inMemory()
        let reg = registry(db)
        let created = await reg.run(name: "create_note", inputJSON: Data(#"{"text":"Brüheinheit prüfen"}"#.utf8))
        #expect(created.isError == false)
        #expect(created.text.contains("Brüheinheit prüfen"))

        let listed = await reg.run(name: "list_notes", inputJSON: Data("{}".utf8))
        #expect(listed.text.contains("Brüheinheit prüfen"))
    }

    @Test func deleteOhneTrefferIstFehler() async throws {
        let db = try GRDBDatabase.inMemory()
        let reg = registry(db)
        let r = await reg.run(name: "delete_note", inputJSON: Data(#"{"note":"gibtsnicht"}"#.utf8))
        #expect(r.isError == true)
    }

    // S10: Notiz im Projekt-Chat wird automatisch dem Projekt zugeordnet (_projektID),
    // list_notes scoped standardmäßig darauf; ein fremdes Projekt sieht sie nicht.
    @Test func projektChatTaggtUndScoped() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = AssistantNotesStore(db: db)
        let reg = AssistantToolRegistry.standard(notesStore: store)

        let made = await reg.run(name: "create_note", inputJSON: Data(#"{"text":"Hustadt Termin"}"#.utf8), projektID: "2026-024")
        #expect(made.text.contains("2026-024"))
        #expect(try await store.all().first?.projectID == "2026-024")

        // Im selben Projekt sichtbar
        let here = await reg.run(name: "list_notes", inputJSON: Data("{}".utf8), projektID: "2026-024")
        #expect(here.text.contains("Hustadt Termin"))
        // In fremdem Projekt NICHT (nur dessen + globale)
        let elsewhere = await reg.run(name: "list_notes", inputJSON: Data("{}".utf8), projektID: "2026-001")
        #expect(elsewhere.text.contains("Hustadt Termin") == false)
        // Mit alle=true überall sichtbar
        let all = await reg.run(name: "list_notes", inputJSON: Data(#"{"alle":"true"}"#.utf8), projektID: "2026-001")
        #expect(all.text.contains("Hustadt Termin"))
    }

    @Test func notizToolsFehlenOhneStore() {
        let reg = AssistantToolRegistry.standard()
        #expect(reg.toolNames.contains("create_note") == false)
    }
}
