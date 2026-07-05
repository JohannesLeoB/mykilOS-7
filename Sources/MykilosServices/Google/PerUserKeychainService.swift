import Foundation

// MARK: - CurrentUserContext
// Prozess-weite, thread-sichere Ablage der stabilen lokalen userID (siehe
// UserProfile.userID). AppState.init() setzt sie EINMAL beim App-Start
// (Self.ensureUserID(db:), synchron, vor jeder Keychain-Store-Konstruktion).
// Existenzgrund: Dutzende Call-Sites im Kit instanziieren Google-Clients über
// Default-Parameter (z. B. `GoogleDriveClient()` in AssistantTool.swift,
// TimelineTabView.swift, …) — die alle bis zu KeychainGoogleTokenStore()
// durchreichen. Diese Stellen einzeln auf ein explizites userID-Argument
// umzustellen wäre ein App-weiter Umbau weit über den Keychain-Härtungs-
// Auftrag hinaus. Der Kontext lässt den bestehenden Default-Parameter
// `userID: String? = nil` stattdessen "die aktuell aktive lokale userID"
// bedeuten, ohne eine einzige Call-Site anzufassen. Tests setzen/resetten
// ihn explizit — kein echtes Keychain, kein Netzwerk nötig.
public enum CurrentUserContext {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var _userID: String?

    /// Von AppState.init() einmalig gesetzt, sobald die stabile lokale
    /// userID ermittelt/erzeugt ist (siehe ensureUserID).
    public static func set(_ userID: String?) {
        lock.lock(); defer { lock.unlock() }
        _userID = userID
    }

    /// Von allen KeychainXCredentialsStore-Default-Inits gelesen, wenn der
    /// Aufrufer keine explizite userID übergibt.
    public static var current: String? {
        lock.lock(); defer { lock.unlock() }
        return _userID
    }

    /// Nur für Tests: definierten Ausgangszustand herstellen.
    public static func resetForTesting() {
        lock.lock(); defer { lock.unlock() }
        _userID = nil
    }
}

// MARK: - PerUserKeychainService
// V10 Folge-Block A: alle teamweiten Keychain-Services (google/clockodo/
// airtable/clickup/sevdesk/claude) laufen künftig unter
// `com.mykilos6.<service>.<userID>` statt teamweit geteilt `com.mykilos6.<service>`.
// Reine Foundation-Logik (kein Keychain-Zugriff) — die Namensableitung UND die
// Migrations-Entscheidung sind so ohne echtes Keychain testbar. Der siebte
// String "com.mykilos6.google.oauth.loopback" ist nur ein DispatchQueue-Label,
// kein Secret — bewusst NICHT hierüber geführt.
public enum PerUserKeychainService {
    /// Team-weiter Basis-Service-Name, wie er vor V10 überall genutzt wurde.
    /// Bleibt als Migrationsquelle bestehen — wird nie gelöscht.
    public static func legacy(_ base: String) -> String {
        "com.mykilos6.\(base)"
    }

    /// Der neue per-User-Service-Name. `userID` ist die stabile lokale
    /// Profil-UUID (UserProfile.userID, siehe AppState.ensureUserID()) — NICHT
    /// E-Mail/displayName (änderbar, kann Sonderzeichen enthalten).
    /// Leere/whitespace-only userID fällt auf "local" zurück statt einen
    /// kaputten Service-String wie "com.mykilos6.google." zu erzeugen.
    public static func perUser(_ base: String, userID: String?) -> String {
        let trimmed = userID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let safeUserID = trimmed.isEmpty ? "local" : trimmed
        return "com.mykilos6.\(base).\(safeUserID)"
    }
}

// MARK: - KeychainAccessing
// Minimales Protokoll über die drei `KeychainStore`-Operationen, die die
// sanfte Migration braucht. `KeychainStore` (struct, echtes Security-Framework)
// erfüllt es bereits strukturell; Tests injizieren stattdessen einen
// In-Memory-Fake — nie echtes Keychain im Testlauf.
public protocol KeychainAccessing: Sendable {
    func load(service: String, account: String) throws -> String?
    @discardableResult
    func store(_ value: String, service: String, account: String) throws -> Bool
}

extension KeychainStore: KeychainAccessing {}

// MARK: - PerUserKeychainMigrator
// Sanfte Migration: beim ersten Zugriff unter dem neuen per-User-Service
// nachsehen; nichts da, aber unter einer Migrationsquelle ein Wert → lesen,
// unter neuem Service schreiben, ALTEN Eintrag nicht löschen
// (Rückwärtskompatibilität — bestehende Verbindungen dürfen nicht
// stillschweigend verschwinden, z. B. bei Downgrade oder Parallel-Zugriff).
//
// Zwei Migrationsquellen (in dieser Reihenfolge):
//   1. Legacy `com.mykilos6.<base>` — der teamweite Vor-V10-Service.
//   2. `.local`-Fallback `com.mykilos6.<base>.local` — entsteht, wenn ein Store
//      zur Schreibzeit KEINE aktive userID sah (CurrentUserContext.current == nil)
//      und deshalb unter dem "local"-Fallback schrieb (der Claude-`.local`-Bug,
//      2026-07-05). Wird nur gezogen, wenn die aktive userID selbst KEIN "local"
//      ist (sonst wäre newService == localService → Selbst-Migration/Loop).
public enum PerUserKeychainMigrator {
    /// Liefert den Wert unter `account`, bevorzugt aus dem per-User-Service.
    /// Migriert bei Bedarf einmalig von einer Migrationsquelle in den per-User-Service.
    public static func loadWithMigration(
        keychain: some KeychainAccessing,
        base: String,
        userID: String?,
        account: String
    ) throws -> String? {
        let newService = PerUserKeychainService.perUser(base, userID: userID)
        if let value = try keychain.load(service: newService, account: account) {
            return value
        }
        // Migrationsquelle 1: der alte teamweite Legacy-Service.
        let oldService = PerUserKeychainService.legacy(base)
        if let legacyValue = try keychain.load(service: oldService, account: account) {
            // Nachziehen unter neuem Service; alter Eintrag bleibt bestehen.
            try keychain.store(legacyValue, service: newService, account: account)
            return legacyValue
        }
        // Migrationsquelle 2: der ".local"-Fallback-Service (Claude-`.local`-Bug).
        // Nur ziehen, wenn die aktive userID KEIN "local" ist — sonst ist
        // localService == newService und wir hätten oben schon getroffen.
        let localService = PerUserKeychainService.perUser(base, userID: nil)
        if localService != newService,
           let localValue = try keychain.load(service: localService, account: account) {
            // Nachziehen unter neuem Service; ".local"-Eintrag bleibt bestehen (append-only).
            try keychain.store(localValue, service: newService, account: account)
            return localValue
        }
        return nil
    }
}
