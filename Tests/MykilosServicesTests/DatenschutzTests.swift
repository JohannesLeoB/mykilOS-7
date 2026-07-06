import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// Vision-Doku "Nutzerprofil & Datenschutz", Stufe 3: Cold-Start-Test für die Präferenzen +
// End-to-End-Test für den Export (reale Stores, InMemory-DB, kein Netzwerk/Keychain).
@MainActor
struct DatenschutzTests {

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("myk6-datenschutz-\(UUID().uuidString)", isDirectory: true)
    }

    @Test func praeferenzenUeberlebenNeustartMitEchterDateiDB() throws {
        let dir = tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("db.sqlite")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let dbA = try GRDBDatabase(url: url)
        let storeA = DatenschutzPraeferenzenStore(db: dbA)
        try storeA.load()
        #expect(storeA.praeferenzen == .standard)   // leere DB → Standard, alles freigegeben

        var geaendert = DatenschutzPraeferenzen.standard
        geaendert.teileMailMitAssistent = false
        geaendert.kiKomplettAus = true
        try storeA.speichere(geaendert)

        let dbB = try GRDBDatabase(url: url)
        let storeB = DatenschutzPraeferenzenStore(db: dbB)
        try storeB.load()
        #expect(storeB.praeferenzen.teileMailMitAssistent == false)
        #expect(storeB.praeferenzen.kiKomplettAus == true)
        #expect(storeB.praeferenzen.teileNotizenMitAssistent == true)   // unberührte Felder bleiben Standard
    }

    @Test func standardPraeferenzenGebenAllesFreiUndKiIstAn() {
        let standard = DatenschutzPraeferenzen.standard
        #expect(standard.teileMailMitAssistent == true)
        #expect(standard.teileNotizenMitAssistent == true)
        #expect(standard.teileChatMitAssistent == true)
        #expect(standard.teileClockodoMitAssistent == true)
        #expect(standard.kiKomplettAus == false)
    }

    @Test func exportEnthaeltProfilNotizenAufgabenUndChatZaehlungen() async throws {
        let db = try GRDBDatabase.inMemory()
        let profileStore = ProfileStore(db: db)
        try profileStore.save(UserProfile(displayName: "Frauke", role: "Innenarchitektin"))

        let notesStore = AssistantNotesStore(db: db)
        _ = try await notesStore.create("Miele Brüheinheit bestellen")
        _ = try await notesStore.create("Kunde ruft zurück")

        let tasksStore = AssistantTasksStore(db: db)
        _ = try await tasksStore.create("Aufmaß Küche Meyer")

        let chatStore = ChatStore(db: db)
        try chatStore.append(ChatMessage.text("Hallo", role: .user), to: .home)
        try chatStore.append(ChatMessage.text("Hi!", role: .assistant), to: .home)
        try chatStore.append(ChatMessage.text("Projektfrage", role: .user), to: .project("2026-015"))

        let export = await DatenschutzExportService.erstelle(
            profile: profileStore, notes: notesStore, tasks: tasksStore, chat: chatStore,
            projektNummern: ["2026-015"]
        )

        #expect(export.profil?.displayName == "Frauke")
        #expect(export.notizen.count == 2)
        #expect(export.aufgaben == ["Aufmaß Küche Meyer"])
        #expect(export.chatNachrichtenJeBereich["home"] == 2)
        #expect(export.chatNachrichtenJeBereich["project:2026-015"] == 1)
    }

    @Test func exportOhneJeglicheDatenIstLeerAberStuerztNicht() async throws {
        let db = try GRDBDatabase.inMemory()
        let export = await DatenschutzExportService.erstelle(
            profile: ProfileStore(db: db),
            notes: AssistantNotesStore(db: db),
            tasks: AssistantTasksStore(db: db),
            chat: ChatStore(db: db),
            projektNummern: []
        )
        #expect(export.profil == nil)
        #expect(export.notizen.isEmpty)
        #expect(export.aufgaben.isEmpty)
        #expect(export.chatNachrichtenJeBereich["home"] == 0)
    }
}
