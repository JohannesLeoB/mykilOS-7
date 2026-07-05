import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// MARK: - OrphanRebindTests (Stufe 1a — Teil A + B)
// Beweist den Rebind-Zweig des Personalausweises:
//  T1 — mit bekannter Google-Mail rebindet ensureUserID an die ALTE stabile
//       userID (DB-Anker), statt bei DB-Reset eine frische UUID zu vergeben.
//       Kontrollen: ohne Mail / leere / whitespace-Mail → KEIN Rebind.
//  T2 — der Keychain-Anker überlebt eine db.sqlite-Löschung: frische DB OHNE
//       Personalausweis-Record → Rebind fällt vom DB-Anker auf den Keychain-
//       Anker zurück. Volle Mail; Domain-only liefert nichts.
//
// Echte Datei-DB (NICHT inMemory) — Ganzsekunden-Timestamps, volle Mail. Kein
// echtes Keychain: T2 injiziert einen In-Memory-Fake-Anker.
@MainActor
struct OrphanRebindTests {

    // MARK: - T1 — Rebind statt Verwaisung (DB-Anker)

    @Test func rebindetAnAlteUserIDStattFrischerUUID() throws {
        let tmp = makeOrphanTempDir()
        defer { try? FileManager.default.removeItem(at: tmp) }
        let db = try GRDBDatabase(url: tmp.appendingPathComponent("db.sqlite"))

        // Personalausweis mit alter, stabiler UUID schreiben; userProfile bleibt frisch/leer.
        let store = ResidentIdentityStore(db: db)
        try store.save(ResidentIdentity(
            googleEmail: "johannes@mykilos.com",
            userID: "ALT-UUID-001",
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000)))

        // Mit bekannter Mail → an die alte UUID rebinden.
        let rebound = ProfileStore.ensureUserID(
            db: db,
            googleEmail: "johannes@mykilos.com",
            anchorStore: FakeIdentityAnchorStore())   // Keychain leer → nur DB-Anker greift
        #expect(rebound == "ALT-UUID-001")

        // Der Rebind hat die Single-Row id="local" auf die alte UUID gesetzt
        // (Upsert, keine neue Zeile): ein anschließender Aufruf OHNE Mail bleibt stabil.
        let stable = ProfileStore.ensureUserID(db: db)
        #expect(stable == "ALT-UUID-001")
    }

    @Test func ohneMailFrischeUUIDKeinRebind() throws {
        let tmp = makeOrphanTempDir()
        defer { try? FileManager.default.removeItem(at: tmp) }
        let db = try GRDBDatabase(url: tmp.appendingPathComponent("db.sqlite"))

        // Personalausweis existiert, aber ohne Mail wird NICHT rebindet.
        let store = ResidentIdentityStore(db: db)
        try store.save(ResidentIdentity(
            googleEmail: "johannes@mykilos.com",
            userID: "ALT-UUID-001",
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000)))

        let fresh = ProfileStore.ensureUserID(db: db)   // googleEmail = nil (Default)
        #expect(fresh != "ALT-UUID-001")
        #expect(fresh.isEmpty == false)
    }

    @Test func leereUndWhitespaceMailFuehrenNieZuRebind() throws {
        let tmp = makeOrphanTempDir()
        defer { try? FileManager.default.removeItem(at: tmp) }
        let db = try GRDBDatabase(url: tmp.appendingPathComponent("db.sqlite"))

        let store = ResidentIdentityStore(db: db)
        try store.save(ResidentIdentity(
            googleEmail: "johannes@mykilos.com",
            userID: "ALT-UUID-001",
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000)))

        // Nicht-Leer-Invariante: "" und "   " dürfen NIE auf den Anker rebinden.
        let leer = ProfileStore.ensureUserID(db: db, googleEmail: "")
        #expect(leer != "ALT-UUID-001")

        // Frische DB, damit die vorige (frische) UUID nicht als Bestandsprofil zurückkommt.
        let tmp2 = makeOrphanTempDir()
        defer { try? FileManager.default.removeItem(at: tmp2) }
        let db2 = try GRDBDatabase(url: tmp2.appendingPathComponent("db.sqlite"))
        let store2 = ResidentIdentityStore(db: db2)
        try store2.save(ResidentIdentity(
            googleEmail: "johannes@mykilos.com",
            userID: "ALT-UUID-001",
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000)))
        let whitespace = ProfileStore.ensureUserID(db: db2, googleEmail: "   ")
        #expect(whitespace != "ALT-UUID-001")
    }

    // MARK: - T2 — Keychain-Anker überlebt db.sqlite-Löschung

    @Test func keychainAnkerRebindetOhneDBRecord() throws {
        let tmp = makeOrphanTempDir()
        defer { try? FileManager.default.removeItem(at: tmp) }
        // FRISCHE DB OHNE Personalausweis-Record (Neuinstallation/DB-Reset).
        let db = try GRDBDatabase(url: tmp.appendingPathComponent("db.sqlite"))

        // Der Keychain-Anker kennt die alte UUID noch — er hat den DB-Verlust überlebt.
        let anchor = FakeIdentityAnchorStore()
        try anchor.save(userID: "ALT-UUID-001", forEmail: "johannes@mykilos.com")

        let rebound = ProfileStore.ensureUserID(
            db: db,
            googleEmail: "johannes@mykilos.com",
            anchorStore: anchor)
        #expect(rebound == "ALT-UUID-001")   // DB-Anker fehlt → Fallback auf Keychain-Anker
    }

    @Test func keychainAnkerVerlangtVolleMailNichtNurDomain() throws {
        let tmp = makeOrphanTempDir()
        defer { try? FileManager.default.removeItem(at: tmp) }
        let db = try GRDBDatabase(url: tmp.appendingPathComponent("db.sqlite"))

        let anchor = FakeIdentityAnchorStore()
        try anchor.save(userID: "ALT-UUID-001", forEmail: "johannes@mykilos.com")

        // Nur die Domain als Mail → der Anker (auf volle Mail geschlüsselt) liefert nichts.
        let byDomain = ProfileStore.ensureUserID(
            db: db,
            googleEmail: "mykilos.com",
            anchorStore: anchor)
        #expect(byDomain != "ALT-UUID-001")
    }

    // MARK: - KeychainIdentityAnchorStore Direkt-Invarianten (Fake-Keychain)

    @Test func ankerStoreSchreibtLeereMailNieUndLiestSieNichtAls() throws {
        let fake = FakeKeychain()
        let store = KeychainIdentityAnchorStore(keychain: fake)

        // Leere/whitespace-Mail wird NIE als Account geschrieben.
        try store.save(userID: "UUID-X", forEmail: "")
        try store.save(userID: "UUID-X", forEmail: "   ")
        #expect(fake.storage.isEmpty)

        // Leere/whitespace-Mail liefert beim Lesen IMMER nil.
        #expect(try store.userID(forEmail: "") == nil)
        #expect(try store.userID(forEmail: "   ") == nil)
    }

    @Test func ankerStoreNormalisiertMailUndRoundtrippt() throws {
        let fake = FakeKeychain()
        let store = KeychainIdentityAnchorStore(keychain: fake)
        try store.save(userID: "ALT-UUID-001", forEmail: "  Johannes@Mykilos.COM ")
        // Case/Whitespace-insensitiv über die normalisierte volle Mail.
        #expect(try store.userID(forEmail: "johannes@mykilos.com") == "ALT-UUID-001")
        #expect(try store.userID(forEmail: "JOHANNES@MYKILOS.COM") == "ALT-UUID-001")
    }

    // MARK: - Teil D — "letzte Mail"-Slot (Mail-Wiederbeschaffung nach db-Reset)

    @Test func letzteMailSlotRoundtripptNormalisiert() throws {
        let fake = FakeKeychain()
        let store = KeychainIdentityAnchorStore(keychain: fake)
        #expect(try store.loadLastEmail() == nil)                      // leer am Anfang
        try store.saveLastEmail("  Johannes@Mykilos.COM ")
        // Normalisiert (lowercased/trimmed) und OHNE die Mail zu kennen lesbar.
        #expect(try store.loadLastEmail() == "johannes@mykilos.com")
    }

    @Test func letzteMailSlotSchreibtLeereMailNie() throws {
        let fake = FakeKeychain()
        let store = KeychainIdentityAnchorStore(keychain: fake)
        try store.saveLastEmail("")
        try store.saveLastEmail("   ")
        #expect(fake.storage.isEmpty)
        #expect(try store.loadLastEmail() == nil)
    }

    @Test func letzteMailSlotKollidiertNichtMitMailAnker() throws {
        // Reservierter lastEmail-Account und der Mail→userID-Anker stören sich nicht.
        let fake = FakeKeychain()
        let store = KeychainIdentityAnchorStore(keychain: fake)
        try store.save(userID: "ALT-UUID-001", forEmail: "johannes@mykilos.com")
        #expect(try store.loadLastEmail() == nil)   // Mail-Anker gesetzt, lastEmail aber nicht
        #expect(try store.userID(forEmail: "johannes@mykilos.com") == "ALT-UUID-001")
    }

    @Test func resetFallLetzteMailPlusAnkerLiefertAlteUUID() throws {
        // Der reale Reset-Fall, den Teil D schließt: db.sqlite weg, aber im Keychain
        // liegen lastEmail-Slot + Mail-Anker. Die wiederbeschaffte Mail füttert den Anker.
        let fake = FakeKeychain()
        let store = KeychainIdentityAnchorStore(keychain: fake)
        try store.saveLastEmail("johannes@mykilos.com")
        try store.save(userID: "ALT-UUID-001", forEmail: "johannes@mykilos.com")

        // Simuliert AppState.init nach Reset: Mail aus dem Slot holen …
        let recovered = try store.loadLastEmail()
        #expect(recovered == "johannes@mykilos.com")

        // … und über den Anker (ohne DB-Record) die alte UUID auflösen.
        let tmp = makeOrphanTempDir()
        defer { try? FileManager.default.removeItem(at: tmp) }
        let db = try GRDBDatabase(url: tmp.appendingPathComponent("db.sqlite"))
        let rebound = ProfileStore.ensureUserID(db: db, googleEmail: recovered, anchorStore: store)
        #expect(rebound == "ALT-UUID-001")
    }
}

// MARK: - FakeIdentityAnchorStore
// In-Memory-Anker-Fake für die ProfileStore-Rebind-Tests — kein echtes Keychain.
// Schlüssel = normalisierte volle Mail (lowercased+trimmed), spiegelt die
// Normalisierung von KeychainIdentityAnchorStore.
private final class FakeIdentityAnchorStore: IdentityAnchorStoring, @unchecked Sendable {
    private var storage: [String: String] = [:]

    private func key(_ email: String) -> String? {
        let k = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return k.isEmpty ? nil : k
    }

    func save(userID: String, forEmail email: String) throws {
        guard let account = key(email) else { return }
        let value = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.isEmpty == false else { return }
        storage[account] = value
    }

    func userID(forEmail email: String) throws -> String? {
        guard let account = key(email) else { return nil }
        return storage[account]
    }
}

// MARK: - Temp-Verzeichnis-Helfer (echte Datei-DB)
private func makeOrphanTempDir() -> URL {
    let base = FileManager.default.temporaryDirectory
        .appendingPathComponent("mykilos_orphan_rebind_\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    return base
}
