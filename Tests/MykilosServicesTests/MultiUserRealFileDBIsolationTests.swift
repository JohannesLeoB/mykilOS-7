import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// MARK: - MultiUserRealFileDBIsolationTests (Bauplan §7.3, das haerteste Gate)
//
// Schliesst die letzte offene Verifikationsluecke aus dem Multi-User-Bauplan:
// die bestehenden Isolationstests (MultiUserStoreIsolationTests) beweisen
// Trennung nur mit In-Memory-DB und expliziten userIDs — nicht mit einer
// ECHTEN Datei-DB ueber einen ECHTEN "Neustart" (frische GRDBDatabase-Instanz
// auf derselben Datei), wie der Bauplan verlangt. Diese Suite tut genau das,
// fuer den vollen Zyklus: Bewohner A -> Abmelden -> Bewohner B (Neustart) ->
// B sieht A's Daten NIE -> B meldet sich ab -> A kehrt zurueck (Neustart) ->
// A bekommt seine ALTE stabile userID + seine Daten zurueck, nicht B's Gast-ID.
//
// Bewusst OHNE echtes Keychain (folgt der Konvention aus OrphanRebindTests):
// nutzt den DB-Anker (ResidentIdentityStore) statt des Keychain-Ankers —
// deckt den Kern-Mechanismus vollstaendig ab, ohne OS-Keychain-Prompts im
// automatisierten Testlauf. Kein AppState (der braucht echtes Keychain fuer
// die Google-Auth-Services) — Store-Ebene reicht, um Isolation + Rebind zu
// beweisen; das ist exakt das, was §7.3 als "hartes Gate" verlangt.
@MainActor
struct MultiUserRealFileDBIsolationTests {

    @Test func residentWechselUndRueckkehrUeberEchteNeustarts() async throws {
        let tmp = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tmp) }
        let dbURL = tmp.appendingPathComponent("db.sqlite")

        // ---- "Boot 1": Bewohner A verbindet sich, legt private Daten an. ----
        var db = try GRDBDatabase(url: dbURL)
        let residentA = ProfileStore.ensureUserID(db: db)
        try ResidentIdentityStore(db: db).save(ResidentIdentity(
            googleEmail: "a@mykilos.com", userID: residentA,
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000)))
        let notesA = AssistantNotesStore(db: db, userID: residentA)
        _ = try await notesA.create("A's private Notiz")

        // ---- Abmelden: frischer Gast-Namespace (wie signOutEverywhere). ----
        let gastNachA = ProfileStore.resetToFreshGuest(db: db)
        #expect(gastNachA != residentA)

        // ---- "Boot 2" — ECHTER Neustart: frische GRDBDatabase-Instanz, ----
        // ---- dieselbe Datei. Ohne Login (kein Email) bleibt's beim Gast. ----
        db = try GRDBDatabase(url: dbURL)
        let residentB = ProfileStore.ensureUserID(db: db)
        #expect(residentB == gastNachA)

        // B sieht A's Notiz NIE — ueber eine ECHTE Datei-DB + ECHTEN Neustart.
        let notesB = AssistantNotesStore(db: db, userID: residentB)
        #expect(try await notesB.all().isEmpty)

        // B verbindet sich mit eigener Mail, legt eigene Notiz an.
        try ResidentIdentityStore(db: db).save(ResidentIdentity(
            googleEmail: "b@mykilos.com", userID: residentB,
            updatedAt: Date(timeIntervalSince1970: 1_800_000_100)))
        _ = try await notesB.create("B's private Notiz")

        // ---- B meldet sich ab. ----
        _ = ProfileStore.resetToFreshGuest(db: db)

        // ---- "Boot 3" — A kehrt zurueck (kennt seine Mail). Echter Neustart. ----
        db = try GRDBDatabase(url: dbURL)
        let residentARueckkehr = ProfileStore.ensureUserID(db: db, googleEmail: "a@mykilos.com")
        // Rebind auf die ALTE stabile ID — nicht neu, nicht B's Gast-ID.
        #expect(residentARueckkehr == residentA)

        let notesARueckkehr = AssistantNotesStore(db: db, userID: residentARueckkehr)
        let alleA = try await notesARueckkehr.all()
        #expect(alleA.count == 1)
        #expect(alleA.first?.body == "A's private Notiz")

        // A sieht B's Notiz NIE (auch nicht nach eigener Rueckkehr).
        #expect(alleA.contains { $0.body == "B's private Notiz" } == false)
    }

    @Test func chatGedaechtnisUeberlebtEchtenNeustartUndBleibtProBewohnerGetrennt() throws {
        let tmp = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tmp) }
        let dbURL = tmp.appendingPathComponent("db.sqlite")
        let scope = ChatScope.project("2026-042")

        var db = try GRDBDatabase(url: dbURL)
        let memoryA = ChatMemoryStore(db: db, userID: "resident-a")
        try memoryA.save(ChatMemorySummary(
            scopeKey: scope.rawKey, summaryText: "A's Zusammenfassung",
            coveredThroughMessageID: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000)))

        // ECHTER Neustart — frische GRDBDatabase-Instanz, dieselbe Datei.
        db = try GRDBDatabase(url: dbURL)
        let memoryB = ChatMemoryStore(db: db, userID: "resident-b")
        #expect(try memoryB.summary(for: scope) == nil)   // B sieht A's Gedaechtnis nicht

        // A findet nach dem Neustart weiterhin die eigene Zusammenfassung.
        let memoryA2 = ChatMemoryStore(db: db, userID: "resident-a")
        #expect(try memoryA2.summary(for: scope)?.summaryText == "A's Zusammenfassung")
    }
}

private func makeTempDir() -> URL {
    let base = FileManager.default.temporaryDirectory
        .appendingPathComponent("mykilos_multiuser_realdb_\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    return base
}
