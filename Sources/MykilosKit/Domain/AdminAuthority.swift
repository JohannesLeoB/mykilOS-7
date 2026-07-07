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
// EHRLICHE GRENZE (adversariale Härtung 2026-07-07): Auf einem local-first
// macOS-Client, dessen Prozess unter dem Angreifer-User läuft, ist KEINE rein
// lokale Admin-Grenze fälschungssicher — wer den eigenen Keychain + GRDB schreibt,
// kann jeden lokalen Anker fälschen. Der Client-Guard ist Komfort + Nachweis +
// Verzögerung; die ABSOLUTE Grenze sitzt serverseitig bei den Airtable-/Google-
// Key-Scopes. Deshalb koppelt `istAdmin` an ein echtes Google-Token (s. u.) und
// externe Admin-Aktionen reverifizieren zusätzlich live — der Trust verschiebt sich
// vom fälschbaren String auf ein nicht-triviales Google-Secret.
//
// Diese Datei ist nur das reine Fundament (Foundation-only, testbar). Die
// Enforcement-Gates an den Admin-Only-Aufrufpfaden folgen als eigene, je
// live-abgenommene Stufen. (Eine Airtable-Rollen-Override wird in V1 bewusst NICHT
// gebaut: der Team-PAT steckt in jeder .mykinvite und kann ein Rollen-Feld selbst
// schreiben → Selbst-Beförderung. Einziger Anker = diese eingebackene Allowlist.)
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
        "johannes@mykilos.com",
        "dk@mykilos.com"          // Daniel (von Johannes 2026-07-07 bestätigt)
    ])
}

// MARK: - AdminAuthorizing
public protocol AdminAuthorizing: Sendable {
    func istAdmin(_ identity: ResidentIdentity?, tokenPresent: Bool) -> Bool
}

// MARK: - AllowlistAdminAuthority
// Prüft die verifizierte Identität gegen die Allowlist. Rein, deterministisch, testbar.
public struct AllowlistAdminAuthority: AdminAuthorizing {
    private let allowlist: AdminAllowlist

    public init(allowlist: AdminAllowlist = .gebacken) {
        self.allowlist = allowlist
    }

    /// Admin NUR, wenn (1) eine gültige verifizierte Google-Mail vorliegt, (2) ein echtes
    /// Google-Token im selben per-User-Namespace anwesend ist (`tokenPresent`), UND (3) die
    /// Mail in der Allowlist steht. Kein Ausweis / leerer Schlüssel / kein Token → kein Admin.
    ///
    /// `tokenPresent` (Token-Kopplung): die googleEmail wird beim App-Start ohne Netz aus dem
    /// lokal beschreibbaren Keychain hydriert — der String allein ist fälschbar. Ein echtes
    /// Google-Refresh-Token für die Admin-Mail kann ein lokaler Angreifer NICHT erzeugen. Der
    /// Aufrufer (AppState) berechnet `tokenPresent` aus dem per-User-Keychain-Namespace.
    public func istAdmin(_ identity: ResidentIdentity?, tokenPresent: Bool) -> Bool {
        guard let identity, identity.hasValidKey else { return false }
        guard tokenPresent else { return false }
        return allowlist.enthaelt(identity.googleEmail)
    }

    /// Store-/Service-Gate: wirft `nurAdmin`, wenn die Identität kein Admin ist.
    /// Sichtbar (throws) statt still — jeder Admin-Only-Aufrufpfad ruft das zuerst.
    public func assertAdmin(_ identity: ResidentIdentity?, tokenPresent: Bool, funktion: String) throws {
        guard istAdmin(identity, tokenPresent: tokenPresent) else {
            throw BerechtigungError.nurAdmin(funktion: funktion)
        }
    }
}
