import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

// MARK: - AssistantTagebuchStore (S10_WIRBELSAEULE.md §9, Parallel-Track, 2026-07-07)

@MainActor
struct AssistantTagebuchStoreTests {

    @Test func appendUndLoadRundtrip() async throws {
        let store = AssistantTagebuchStore(db: try GRDBDatabase.inMemory())
        try store.append(AssistantTagebuchEintrag(projectID: "2026-001", art: .kannNichtLesen, text: "PDF im Mail-Anhang nicht lesbar"))
        try store.append(AssistantTagebuchEintrag(art: .fehlendeInfo, text: "Keine Projektnummer im Betreff"))
        #expect(store.eintraege.count == 2)
    }

    @Test func loadFiltertNachProjekt() async throws {
        let store = AssistantTagebuchStore(db: try GRDBDatabase.inMemory())
        try store.append(AssistantTagebuchEintrag(projectID: "2026-001", art: .widerspruch, text: "A"))
        try store.append(AssistantTagebuchEintrag(projectID: "2026-002", art: .widerspruch, text: "B"))
        try store.load(projectID: "2026-001")
        #expect(store.eintraege.count == 1)
        #expect(store.eintraege.first?.text == "A")
    }

    // Merge-Gate: Cold-Start. Schreiben → neue Instanz auf derselben Datei → identisch.
    @Test func tagebuchEintragUeberlebtNeustart() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("tagebuch-coldstart-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("db.sqlite")

        let geschrieben: AssistantTagebuchEintrag
        do {
            let store = AssistantTagebuchStore(db: try GRDBDatabase(url: url))
            geschrieben = try store.append(
                AssistantTagebuchEintrag(projectID: "2026-014", art: .sonstiges, text: "Überlebt Neustart")
            )
        }

        let store2 = AssistantTagebuchStore(db: try GRDBDatabase(url: url))
        try store2.load()
        #expect(store2.eintraege.count == 1)
        let eintrag = try #require(store2.eintraege.first)
        #expect(eintrag.id == geschrieben.id)
        #expect(eintrag.projectID == "2026-014")
        #expect(eintrag.art == .sonstiges)
        #expect(eintrag.text == "Überlebt Neustart")
    }
}

// MARK: - LogFrictionTool

@MainActor
struct LogFrictionToolTests {

    @Test func loggtEintragMitGueltigerArt() async throws {
        let store = AssistantTagebuchStore(db: try GRDBDatabase.inMemory())
        let reg = AssistantToolRegistry.standard(tagebuchStore: store)
        let result = await reg.run(
            name: "log_friction_point",
            inputJSON: Data(#"{"art":"kann_nicht_lesen","text":"PDF im Anhang nicht lesbar"}"#.utf8)
        )
        #expect(result.isError == false)
        #expect(store.eintraege.count == 1)
        #expect(store.eintraege.first?.art == .kannNichtLesen)
    }

    @Test func unbekannteArtFaelltAufSonstiges() async throws {
        let store = AssistantTagebuchStore(db: try GRDBDatabase.inMemory())
        let reg = AssistantToolRegistry.standard(tagebuchStore: store)
        _ = await reg.run(
            name: "log_friction_point",
            inputJSON: Data(#"{"art":"unbekannt","text":"x"}"#.utf8)
        )
        #expect(store.eintraege.first?.art == .sonstiges)
    }

    @Test func leererTextIstFehler() async throws {
        let store = AssistantTagebuchStore(db: try GRDBDatabase.inMemory())
        let reg = AssistantToolRegistry.standard(tagebuchStore: store)
        let result = await reg.run(name: "log_friction_point", inputJSON: Data(#"{"art":"sonstiges","text":""}"#.utf8))
        #expect(result.isError == true)
        #expect(store.eintraege.isEmpty)
    }

    @Test func toolFehltOhneTagebuchStore() {
        let reg = AssistantToolRegistry.standard()
        #expect(reg.toolNames.contains("log_friction_point") == false)
    }
}
