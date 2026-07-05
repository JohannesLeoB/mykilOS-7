import Foundation

// MARK: - IdentityAnchorStoring
// Minimales Protokoll über den Identitäts-Anker: Spiegel von
// (volle Google-Mail) → (stabile lokale userID). ProfileStore.ensureUserID
// nutzt es als optionalen Fallback hinter dem DB-Anker, wenn db.sqlite
// gelöscht/neu ist. Tests injizieren einen Fake — kein echtes Keychain nötig.
public protocol IdentityAnchorStoring: Sendable {
    /// Anker schreiben. Leere/whitespace-only Mail wird NIE geschrieben.
    func save(userID: String, forEmail email: String) throws
    /// userID zur Mail lesen. Leere/whitespace-only Mail liefert IMMER nil.
    func userID(forEmail email: String) throws -> String?
}

// MARK: - KeychainIdentityAnchorStore
// Teil B des Orphan-Rebind: der Identitäts-Anker (googleEmail → userID) wird
// ZUSÄTZLICH zum GRDB-Personalausweis im Keychain gespiegelt, damit er eine
// Löschung von db.sqlite (Neuinstallation, DB-Reset) überlebt. Nach einem
// solchen Reset bekäme ein bekannter Nutzer sonst eine frische UUID und seine
// per-User-Keychain-Einträge (Google/Clockodo/…) verwaisten. Über diesen Anker
// findet ensureUserID die ALTE UUID wieder und rebindet darauf.
//
// ⛔ TRÄGT NIE EIN SECRET: Wert ist ausschließlich die stabile lokale userID
// (UserProfile.userID, eine UUID), Account ist die normalisierte volle Mail.
// Kein Token, kein API-Key. Deshalb bewusst NICHT im `KeyIntegration`-Enum des
// Schlüssel-Inventars — die „genau 6 Secrets"-Invariante bliebe sonst.
//
// EISERNE NICHT-LEER-INVARIANTE: eine leere/nur-Whitespace Mail wird NIE als
// Account geschrieben oder gelesen (ein leerer Anker wäre ein geteilter
// Rebind-Magnet — Namespace-Kollaps wie der "local"-Fallback). Volle Mail als
// Anker, NIE nur die Domain.
public struct KeychainIdentityAnchorStore: IdentityAnchorStoring {
    /// Eigener Service-Namespace, getrennt von den 6 Secret-tragenden
    /// Integrationen (`com.mykilos6.<base>.<userID>`). Kein per-User-Suffix:
    /// der Anker MUSS ohne bekannte userID auffindbar sein — genau der Fall
    /// nach einer db.sqlite-Löschung, wenn die userID neu vergeben würde.
    public static let service = "com.mykilos6.identity"

    private let keychain: any KeychainAccessing

    public init(keychain: any KeychainAccessing = KeychainStore()) {
        self.keychain = keychain
    }

    /// Normalisierte volle Mail als Account: getrimmt + lowercased. Leere Mail
    /// → nil (Nicht-Leer-Invariante). Nie die Domain isoliert.
    private static func normalizedEmail(_ email: String) -> String? {
        let key = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return key.isEmpty ? nil : key
    }

    public func save(userID: String, forEmail email: String) throws {
        guard let account = Self.normalizedEmail(email) else { return }
        let value = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        // Kein leerer/whitespace userID-Wert als Anker (spiegelbildliche Invariante).
        guard value.isEmpty == false else { return }
        try keychain.store(value, service: Self.service, account: account)
    }

    public func userID(forEmail email: String) throws -> String? {
        guard let account = Self.normalizedEmail(email) else { return nil }
        guard let value = try keychain.load(service: Self.service, account: account) else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - "Letzte Mail"-Slot (Teil D / Option A)

    /// Reservierter Account für die zuletzt verwendete Mail. Bewusst kein gültiges
    /// Mail-Format (führende/abschließende `__`) → kollidiert NIE mit einem echten
    /// `normalizedEmail`-Account (Mail→userID). So bleibt „welche Mail zuletzt?"
    /// lesbar, OHNE die Mail schon zu kennen.
    private static let lastEmailAccount = "__last_email__"

    /// Teil D (Option A): die zuletzt verwendete Google-Mail SUFFIX-LOS mitschreiben.
    /// Nach einem db.sqlite-Reset ist `loadUserInfo(userID: frisch)` leer (die
    /// Userinfo liegt unter dem ALTEN userID-Suffix, und loadWithMigration scannt
    /// keine alten UUID-Suffixe). Über diesen Slot ist die Mail dennoch wieder-
    /// beschaffbar → der Mail→userID-Anker oben kann greifen (Henne-Ei gelöst).
    /// Kein Secret (Mail ist keins). Leere/whitespace-Mail wird NIE geschrieben.
    public func saveLastEmail(_ email: String) throws {
        guard let normalized = Self.normalizedEmail(email) else { return }
        try keychain.store(normalized, service: Self.service, account: Self.lastEmailAccount)
    }

    /// Die zuletzt verwendete (normalisierte) Mail, unabhängig von der aktiven userID.
    public func loadLastEmail() throws -> String? {
        guard let value = try keychain.load(service: Self.service, account: Self.lastEmailAccount) else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
