import Foundation

// MARK: - AdminAuthority (Berechtigungs-Fundament)
//
// Trennt die Admin-Ebene (Daniel + Johannes) von normalen Usern. Entscheidung
// Johannes 2026-07-07 (CLICKUP_IO_ARCHITEKTUR_PLAN.md E2b, Gedächtnis
// `admin-hat-erweiterte-funktionen`):
//   · NORMALE User DÜRFEN: Projekte anlegen (Intake→Nummer→Provisioning in die
//     bestehende Struktur), arbeiten, eigener Scope.
//   · ADMIN-ONLY: Ordner-Schema/Template editieren, Einladungen (.mykinvite),
//     Go-Live-Unlock (.prod), Key-/Config-Verteilung, Ghost→echt-Migration.
//
// EISERNE SICHERHEITSREGEL: Admin-Status kommt AUSSCHLIESSLICH aus der extern
// VERIFIZIERTEN Google-Mail (`ResidentIdentity.googleEmail`), NIE aus einem lokal
// setzbaren Feld (`UserProfile.role` ist Freitext/Anzeige, taugt NICHT als Signal).
// Damit kann sich kein normaler User selbst hochstufen. Default-deny: alles
// Unbekannte/Leere/Nicht-Verifizierte ist KEIN Admin.
//
// Diese Datei ist nur das reine Fundament (Foundation-only, testbar). Die
// Enforcement-Gates an den Admin-Only-Aufrufpfaden und die optionale read-only
// Airtable-Override der Allowlist folgen als eigene, je live-abgenommene Stufen.
public enum BerechtigungError: Error, Sendable, Equatable, LocalizedError {
    /// Eine Admin-Only-Funktion wurde von einer Nicht-Admin-Identität aufgerufen.
    case nurAdmin(funktion: String)

    public var errorDescription: String? {
        switch self {
        case .nurAdmin(let funktion):
            return "Nur Admins dürfen: \(funktion)."
        }
    }
}

// MARK: - AdminAllowlist
// Die Menge verifizierter Admin-Google-Mails. Normalisiert (getrimmt, kleingeschrieben),
// damit Groß-/Kleinschreibung und Rand-Whitespace nie zu einem Fehlurteil führen.
public struct AdminAllowlist: Sendable, Equatable {
    public let emails: Set<String>

    public init(_ emails: [String]) {
        self.emails = Set(emails.map(Self.normalisiere).filter { $0.isEmpty == false })
    }

    static func normalisiere(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Ist diese Mail in der Allowlist? nil/leer → false (default-deny).
    public func enthaelt(_ email: String?) -> Bool {
        guard let email else { return false }
        let normalisiert = Self.normalisiere(email)
        guard normalisiert.isEmpty == false else { return false }
        return emails.contains(normalisiert)
    }

    /// Eingebackener Default — offline-fest, nicht lokal umlegbar. Die Quelle der
    /// Admin-Wahrheit ist die verifizierte Google-Mail; dieser Satz ist der Anker
    /// (eine optionale read-only Airtable-Team-Rollen-Tabelle darf ihn später NUR
    /// additiv erweitern, nie einen normalen User zum Admin machen ohne Beleg).
    ///
    /// ⚠️ Daniels echte verifizierte Google-Mail ist hier bewusst NICHT geraten —
    /// Johannes trägt sie ein (ein falscher Eintrag wäre ein Sicherheitsfehler:
    /// entweder sperrt er Daniel aus oder gibt Fremden Admin).
    public static let gebacken = AdminAllowlist([
        // Daniels verifizierte Google-Mail hier ergänzen (Johannes trägt sie ein).
        "johannes@mykilos.com"
    ])
}

// MARK: - AdminAuthorizing
public protocol AdminAuthorizing: Sendable {
    func istAdmin(_ identity: ResidentIdentity?) -> Bool
}

// MARK: - AllowlistAdminAuthority
// Prüft die verifizierte Identität gegen die Allowlist. Rein, deterministisch, testbar.
public struct AllowlistAdminAuthority: AdminAuthorizing {
    private let allowlist: AdminAllowlist

    public init(allowlist: AdminAllowlist = .gebacken) {
        self.allowlist = allowlist
    }

    /// Admin NUR, wenn eine gültige (nicht-leere) verifizierte Google-Mail vorliegt UND
    /// sie in der Allowlist steht. Kein Ausweis / leerer Schlüssel → kein Admin.
    public func istAdmin(_ identity: ResidentIdentity?) -> Bool {
        guard let identity, identity.hasValidKey else { return false }
        return allowlist.enthaelt(identity.googleEmail)
    }

    /// Store-/Service-Gate: wirft `nurAdmin`, wenn die Identität kein Admin ist.
    /// Sichtbar (throws) statt still — jeder Admin-Only-Aufrufpfad ruft das zuerst.
    public func assertAdmin(_ identity: ResidentIdentity?, funktion: String) throws {
        guard istAdmin(identity) else {
            throw BerechtigungError.nurAdmin(funktion: funktion)
        }
    }
}
