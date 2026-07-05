import Testing
import Foundation
@testable import MykilosServices

// MARK: - FakeKeychain
// In-Memory-Fake für KeychainAccessing — kein echtes Keychain, kein Netzwerk
// im Testlauf (harte Test-Regel dieses Repos). Schlüssel = service+account.
final class FakeKeychain: KeychainAccessing, @unchecked Sendable {
    private(set) var storage: [String: String] = [:]
    private(set) var storeCallCount = 0

    private func key(_ service: String, _ account: String) -> String { "\(service)::\(account)" }

    func load(service: String, account: String) throws -> String? {
        storage[key(service, account)]
    }

    @discardableResult
    func store(_ value: String, service: String, account: String) throws -> Bool {
        storeCallCount += 1
        let isNew = storage[key(service, account)] == nil
        storage[key(service, account)] = value
        return isNew
    }
}

struct PerUserKeychainServiceTests {

    // MARK: - Namens-Ableitung

    @Test func perUserErzeugtVerschiedeneServicesFuerVerschiedeneUser() {
        let serviceA = PerUserKeychainService.perUser("google", userID: "user-a-uuid")
        let serviceB = PerUserKeychainService.perUser("google", userID: "user-b-uuid")
        #expect(serviceA != serviceB)
        #expect(serviceA == "com.mykilos6.google.user-a-uuid")
        #expect(serviceB == "com.mykilos6.google.user-b-uuid")
    }

    @Test func perUserMitNilFaelltAufLocalZurueck() {
        #expect(PerUserKeychainService.perUser("clockodo", userID: nil) == "com.mykilos6.clockodo.local")
    }

    @Test func perUserMitLeeremOderWhitespaceUserIDFaelltAufLocalZurueck() {
        #expect(PerUserKeychainService.perUser("clockodo", userID: "") == "com.mykilos6.clockodo.local")
        #expect(PerUserKeychainService.perUser("clockodo", userID: "   ") == "com.mykilos6.clockodo.local")
    }

    @Test func legacyLiefertTeamweitenServiceOhneUserID() {
        #expect(PerUserKeychainService.legacy("airtable") == "com.mykilos6.airtable")
    }

    @Test func alleSechsBasesErzeugenEindeutigeServices() {
        let bases = ["google", "clockodo", "claude", "clickup", "sevdesk", "airtable"]
        let services = Set(bases.map { PerUserKeychainService.perUser($0, userID: "shared-uuid") })
        #expect(services.count == bases.count)
    }

    // MARK: - Sanfte Migration

    @Test func migrationLiestAltenWertWennNeuerServiceLeerIst() throws {
        let keychain = FakeKeychain()
        // Alter, teamweiter Eintrag existiert bereits (Vor-V10-Zustand).
        try keychain.store("legacy-token", service: PerUserKeychainService.legacy("clockodo"), account: "apiKey")

        let migrated = try PerUserKeychainMigrator.loadWithMigration(
            keychain: keychain, base: "clockodo", userID: "user-1", account: "apiKey")

        #expect(migrated == "legacy-token")
        // Nachgezogen: liegt jetzt AUCH unter dem neuen per-User-Service.
        let newValue = try keychain.load(service: "com.mykilos6.clockodo.user-1", account: "apiKey")
        #expect(newValue == "legacy-token")
        // Alter Eintrag bleibt bestehen (Rückwärtskompatibilität — nicht gelöscht).
        let oldValue = try keychain.load(service: PerUserKeychainService.legacy("clockodo"), account: "apiKey")
        #expect(oldValue == "legacy-token")
    }

    @Test func migrationBevorzugtNeuenServiceWennBeideExistieren() throws {
        let keychain = FakeKeychain()
        try keychain.store("legacy-token", service: PerUserKeychainService.legacy("clockodo"), account: "apiKey")
        try keychain.store("fresh-token", service: "com.mykilos6.clockodo.user-1", account: "apiKey")
        let storeCallsBeforeMigration = keychain.storeCallCount

        let value = try PerUserKeychainMigrator.loadWithMigration(
            keychain: keychain, base: "clockodo", userID: "user-1", account: "apiKey")

        #expect(value == "fresh-token")
        // Kein unnötiger Nachzieh-Write, wenn der neue Service schon einen Wert hat.
        #expect(keychain.storeCallCount == storeCallsBeforeMigration)
    }

    @Test func migrationLiefertNilWennBeideServicesLeerSind() throws {
        let keychain = FakeKeychain()
        let value = try PerUserKeychainMigrator.loadWithMigration(
            keychain: keychain, base: "airtable", userID: "user-1", account: "pat")
        #expect(value == nil)
        #expect(keychain.storeCallCount == 0)
    }

    @Test func userBLiestNichtsVonUserA() throws {
        let keychain = FakeKeychain()
        try keychain.store("user-a-secret", service: "com.mykilos6.airtable.user-a", account: "pat")

        let userBValue = try PerUserKeychainMigrator.loadWithMigration(
            keychain: keychain, base: "airtable", userID: "user-b", account: "pat")

        #expect(userBValue == nil)
    }

    @Test func migrationIstIsoliertJeAccount() throws {
        // E-Mail migriert, apiKey (noch) nicht gesetzt — beide Accounts unabhängig.
        let keychain = FakeKeychain()
        try keychain.store("a@b.de", service: PerUserKeychainService.legacy("clockodo"), account: "email")

        let email = try PerUserKeychainMigrator.loadWithMigration(
            keychain: keychain, base: "clockodo", userID: "user-1", account: "email")
        let apiKey = try PerUserKeychainMigrator.loadWithMigration(
            keychain: keychain, base: "clockodo", userID: "user-1", account: "apiKey")

        #expect(email == "a@b.de")
        #expect(apiKey == nil)
    }

    // MARK: - Migration aus dem ".local"-Fallback (Claude-Bug 2026-07-05)

    @Test func migrationZiehtWertAusLocalFallbackNach() throws {
        // Bug-Zustand: Credentials liegen unter com.mykilos6.claude.local, weil der
        // Store zur Schreibzeit keine aktive userID sah.
        let keychain = FakeKeychain()
        try keychain.store("claude-key", service: "com.mykilos6.claude.local", account: "apiKey")

        // Jetzt mit aktiver userID lesen → wird über die .local-Quelle gefunden.
        let value = try PerUserKeychainMigrator.loadWithMigration(
            keychain: keychain, base: "claude", userID: "aktive-uuid", account: "apiKey")

        #expect(value == "claude-key")
        // Nachgezogen unter den per-User-Service.
        let neu = try keychain.load(service: "com.mykilos6.claude.aktive-uuid", account: "apiKey")
        #expect(neu == "claude-key")
        // Append-only: der .local-Eintrag bleibt bestehen.
        let local = try keychain.load(service: "com.mykilos6.claude.local", account: "apiKey")
        #expect(local == "claude-key")
    }

    @Test func aktiveLocalIdentitaetMigriertNichtAufSichSelbst() throws {
        // Aktive userID ist selbst "local" (bzw. nil) → newService == localService.
        // Der Wert wird direkt (Schritt 1) gefunden, KEINE Selbst-Migration, kein Extra-Write.
        let keychain = FakeKeychain()
        try keychain.store("claude-key", service: "com.mykilos6.claude.local", account: "apiKey")
        let writesVorher = keychain.storeCallCount

        let value = try PerUserKeychainMigrator.loadWithMigration(
            keychain: keychain, base: "claude", userID: nil, account: "apiKey")

        #expect(value == "claude-key")
        #expect(keychain.storeCallCount == writesVorher) // kein Nachzieh-Write auf sich selbst
    }

    @Test func legacyHatVorrangVorLocalFallback() throws {
        // Existieren BEIDE Migrationsquellen, gewinnt Legacy (Reihenfolge im Migrator).
        let keychain = FakeKeychain()
        try keychain.store("legacy-key", service: "com.mykilos6.claude", account: "apiKey")
        try keychain.store("local-key", service: "com.mykilos6.claude.local", account: "apiKey")

        let value = try PerUserKeychainMigrator.loadWithMigration(
            keychain: keychain, base: "claude", userID: "aktive-uuid", account: "apiKey")

        #expect(value == "legacy-key")
    }

    // MARK: - Multi-User-Riegel: Zweit-Bewohner erbt keine persönlichen Alt-Secrets
    // (Bauplan §7.4 Falle 1 — das 🔴 größte Datenleck des User-Wechsels)

    @Test func zweitBewohnerErbtNichtLegacyPersoenlichenDienst() throws {
        let keychain = FakeKeychain()
        // Erst-Bewohner A ist geräteweiter Primary; A's altes team-weites Google-Token liegt in Legacy.
        try keychain.store("user-a", service: KeychainIdentityAnchorStore.service,
                           account: KeychainIdentityAnchorStore.devicePrimaryAccount)
        try keychain.store("a-google-token", service: PerUserKeychainService.legacy("google"), account: "tokens")

        // Zweit-Bewohner B liest → bekommt NICHTS (kein Cross-User-Leak).
        let bValue = try PerUserKeychainMigrator.loadWithMigration(
            keychain: keychain, base: "google", userID: "user-b", account: "tokens")
        #expect(bValue == nil)
    }

    @Test func zweitBewohnerErbtNichtLocalFallbackPersoenlichenDienst() throws {
        let keychain = FakeKeychain()
        try keychain.store("user-a", service: KeychainIdentityAnchorStore.service,
                           account: KeychainIdentityAnchorStore.devicePrimaryAccount)
        // A's Claude-Key im „.local"-Fallback (der 2026-07-05-Bug-Zustand).
        try keychain.store("a-claude-key", service: "com.mykilos6.claude.local", account: "apiKey")

        let bValue = try PerUserKeychainMigrator.loadWithMigration(
            keychain: keychain, base: "claude", userID: "user-b", account: "apiKey")
        #expect(bValue == nil)
    }

    @Test func erstBewohnerAdoptiertSeineLegacySecretsWeiterhin() throws {
        let keychain = FakeKeychain()
        // A ist Primary UND liest selbst → der Riegel darf ihn NICHT blockieren.
        try keychain.store("user-a", service: KeychainIdentityAnchorStore.service,
                           account: KeychainIdentityAnchorStore.devicePrimaryAccount)
        try keychain.store("a-google-token", service: PerUserKeychainService.legacy("google"), account: "tokens")

        let aValue = try PerUserKeychainMigrator.loadWithMigration(
            keychain: keychain, base: "google", userID: "user-a", account: "tokens")
        #expect(aValue == "a-google-token")
        // Nachgezogen unter A's eigenen per-User-Service.
        #expect(try keychain.load(service: "com.mykilos6.google.user-a", account: "tokens") == "a-google-token")
    }

    @Test func geteilterDienstBleibtVomRiegelUnberuehrt() throws {
        let keychain = FakeKeychain()
        // Primary = A. Geteilter Dienst (airtable) → Team-Zugang DARF an B weitergereicht werden (§1a).
        try keychain.store("user-a", service: KeychainIdentityAnchorStore.service,
                           account: KeychainIdentityAnchorStore.devicePrimaryAccount)
        try keychain.store("team-pat", service: PerUserKeychainService.legacy("airtable"), account: "pat")

        let bValue = try PerUserKeychainMigrator.loadWithMigration(
            keychain: keychain, base: "airtable", userID: "user-b", account: "pat")
        #expect(bValue == "team-pat")  // geteilt: kein Riegel
    }

    @Test func ohnePrimaryLaeuftMigrationWieBisher() throws {
        // Kein Primary verankert (Erstkonfiguration / Bestandsgerät) → Riegel inaktiv, Legacy wird gezogen.
        let keychain = FakeKeychain()
        try keychain.store("a-google-token", service: PerUserKeychainService.legacy("google"), account: "tokens")

        let value = try PerUserKeychainMigrator.loadWithMigration(
            keychain: keychain, base: "google", userID: "irgendwer", account: "tokens")
        #expect(value == "a-google-token")
    }

    // MARK: - ensureDevicePrimary (first-writer-wins)

    @Test func ensureDevicePrimaryVerankertNurEinmal() throws {
        let keychain = FakeKeychain()
        let store = KeychainIdentityAnchorStore(keychain: keychain)
        try store.ensureDevicePrimary("user-a")
        #expect(try store.loadDevicePrimary() == "user-a")
        // Zweiter Aufruf mit anderem Bewohner ändert den Primary NICHT.
        try store.ensureDevicePrimary("user-b")
        #expect(try store.loadDevicePrimary() == "user-a")
    }

    @Test func ensureDevicePrimarySchreibtKeineLeereUserID() throws {
        let keychain = FakeKeychain()
        let store = KeychainIdentityAnchorStore(keychain: keychain)
        try store.ensureDevicePrimary("   ")
        #expect(try store.loadDevicePrimary() == nil)
    }
}
