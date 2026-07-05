import Foundation
import Security

// MARK: - Schlüssel-Inventar (read-only)
// Zeigt für jede der 6 Integrationen an, OB ein Keychain-Eintrag existiert,
// ob er der aktiven Identität gehört (oder verwaist zu einer alten/anderen
// userID) und ob der Schlüssel persönlich oder geteilt ist.
//
// ⛔ EISERNE REGEL: NIE einen Secret-Wert lesen, anzeigen oder loggen. Diese
// gesamte Datei arbeitet ausschließlich mit Existenz + Service-Namen
// (Metadaten). Es gibt bewusst KEIN Feld, das einen Wert transportieren
// könnte. `SecItemCopyMatching` läuft mit `kSecReturnData: false`.

// MARK: - KeyIntegration
/// Die 6 Integrationen mit Keychain-Anteil. `keychainBase` ist exakt der
/// Base-String, den die jeweiligen KeychainXCredentialsStore verwenden
/// (`com.mykilos6.<base>.<userID>`, siehe PerUserKeychainService).
public enum KeyIntegration: String, CaseIterable, Sendable {
    case google
    case clockodo
    case clickup
    case sevdesk
    case airtable
    case claude

    /// Base-Segment im Keychain-Service-Namen `com.mykilos6.<base>.<userID>`.
    public var keychainBase: String {
        switch self {
        case .google:   "google"
        case .clockodo: "clockodo"
        case .clickup:  "clickup"
        case .sevdesk:  "sevdesk"
        case .airtable: "airtable"
        case .claude:   "claude"
        }
    }

    /// Sprechender Name für die Anzeige.
    public var displayName: String {
        switch self {
        case .google:   "Google Workspace"
        case .clockodo: "Clockodo"
        case .clickup:  "ClickUp"
        case .sevdesk:  "Sevdesk"
        case .airtable: "Airtable"
        case .claude:   "Claude"
        }
    }

    /// Fest verdrahtete Klassifizierung (bestätigt von Johannes):
    /// persönlich = google, clockodo, clickup, claude; geteilt = airtable, sevdesk.
    public var scope: KeyScope {
        switch self {
        case .google, .clockodo, .clickup, .claude: .persoenlich
        case .airtable, .sevdesk:                    .geteilt
        }
    }
}

// MARK: - KeyScope
/// Ob ein Schlüssel persönlich (nutzereigen) oder teamweit geteilt ist.
public enum KeyScope: Sendable {
    case persoenlich
    case geteilt

    public var label: String {
        switch self {
        case .persoenlich: "persönlich"
        case .geteilt:     "geteilt"
        }
    }
}

// MARK: - KeyInventoryItem
/// Ein Inventar-Eintrag pro Integration. Trägt bewusst KEIN Secret-Feld —
/// nur Status/Metadaten. `connected` spiegelt den AuthService-Status;
/// `isOrphaned` markiert einen Keychain-Eintrag, der zu einer anderen/alten
/// Identität gehört, während für die aktive userID keiner existiert.
public struct KeyInventoryItem: Equatable, Sendable {
    public let integration: KeyIntegration
    public let scope: KeyScope
    public let connected: Bool
    public let isOrphaned: Bool
    public let orphanHint: String?

    public init(
        integration: KeyIntegration,
        scope: KeyScope,
        connected: Bool,
        isOrphaned: Bool,
        orphanHint: String?
    ) {
        self.integration = integration
        self.scope = scope
        self.connected = connected
        self.isOrphaned = isOrphaned
        self.orphanHint = orphanHint
    }
}

// MARK: - StoredKeyLister
/// Liefert die im Keychain vorhandenen `com.mykilos6.*`-Service-Namen — NUR
/// die Namen, NIE die Werte. So bleibt die Kernlogik ohne echtes Keychain
/// testbar (Tests injizieren einen Fake).
public protocol StoredKeyLister: Sendable {
    func storedServiceNames() -> [String]
}

// MARK: - KeychainInventory (pure Kernlogik)
public enum KeychainInventory {
    /// Baut das Inventar deterministisch und seiteneffektfrei aus:
    /// - `activeUserID`: die aktuell aktive lokale userID (CurrentUserContext.current).
    /// - `storedServiceNames`: alle `com.mykilos6.*`-Service-Namen im Keychain (nur Namen).
    /// - `connected`: echter Verbindungsstatus je Integration (aus den AuthServices).
    public static func build(
        activeUserID: String,
        storedServiceNames: [String],
        connected: [KeyIntegration: Bool]
    ) -> [KeyInventoryItem] {
        KeyIntegration.allCases.map { integration in
            let (orphaned, hint) = orphanState(
                for: integration,
                activeUserID: activeUserID,
                storedServiceNames: storedServiceNames
            )
            return KeyInventoryItem(
                integration: integration,
                scope: integration.scope,
                connected: connected[integration] ?? false,
                isOrphaned: orphaned,
                orphanHint: hint
            )
        }
    }

    /// Verwaist-Erkennung für eine Integration.
    ///
    /// Regeln (robust gegen Base-Namen ohne Punkte):
    /// - Existiert ein Eintrag unter der AKTIVEN userID → nicht verwaist.
    /// - Existiert kein aktiver Eintrag, aber mindestens einer unter einer
    ///   ANDEREN userID (oder `.local`/Legacy ohne Suffix) → verwaist mit Hinweis.
    /// - Gar kein Eintrag → nicht verwaist (nur schlicht nicht vorhanden).
    static func orphanState(
        for integration: KeyIntegration,
        activeUserID: String,
        storedServiceNames: [String]
    ) -> (isOrphaned: Bool, hint: String?) {
        let base = integration.keychainBase
        let prefix = "com.mykilos6.\(base)"
        let trimmedActive = activeUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        // Leere userID fällt (wie PerUserKeychainService.perUser) auf "local" zurück.
        let effectiveActive = trimmedActive.isEmpty ? "local" : trimmedActive

        // Alle Suffixe (die userID-Segmente) für genau diese Base einsammeln.
        // Ein Service-Name sieht aus wie "com.mykilos6.<base>.<userID>" oder
        // (Legacy) "com.mykilos6.<base>" ganz ohne Suffix.
        var suffixes: [String] = []
        for name in storedServiceNames {
            guard let suffix = userIDSuffix(of: name, base: base, prefix: prefix) else { continue }
            suffixes.append(suffix)
        }

        guard suffixes.isEmpty == false else {
            // Kein Eintrag für diese Base → schlicht nicht vorhanden, nicht verwaist.
            return (false, nil)
        }

        if suffixes.contains(effectiveActive) {
            // Es gibt einen Eintrag unter der aktiven Identität → alles gut.
            return (false, nil)
        }

        // Nur Fremd-/Legacy-Einträge vorhanden → verwaist.
        let hint: String
        if suffixes.contains(where: { $0 == legacySuffixMarker }) {
            hint = "Schlüssel liegt unter der alten teamweiten Ablage (ohne Identität) — gehört zu einem älteren Stand."
        } else if suffixes.contains("local") {
            hint = "Schlüssel gehört zu einer abweichenden Identität (\u{201E}local\u{201C}), nicht zur aktiven."
        } else {
            hint = "Schlüssel gehört zu einer anderen/alten Identität, nicht zur aktiven."
        }
        return (true, hint)
    }

    /// Marker für einen Legacy-Eintrag (`com.mykilos6.<base>` ganz ohne userID-Suffix).
    private static let legacySuffixMarker = "\u{0000}legacy"

    /// Extrahiert das userID-Suffix eines Service-Namens für die gegebene Base.
    /// - Exakt `com.mykilos6.<base>` (Legacy, kein Suffix) → `legacySuffixMarker`.
    /// - `com.mykilos6.<base>.<rest>` → `<rest>` (letztes Segment; robust, falls
    ///   die userID selbst Punkte enthielte, wird konservativ das Restsegment
    ///   nach dem Base-Präfix genommen).
    /// - Passt die Base nicht (anderer Dienst) → nil.
    private static func userIDSuffix(of serviceName: String, base: String, prefix: String) -> String? {
        if serviceName == prefix {
            return legacySuffixMarker
        }
        let dotted = prefix + "."
        guard serviceName.hasPrefix(dotted) else { return nil }
        let rest = String(serviceName.dropFirst(dotted.count))
        // Base-Namen sind selbst punkt-frei; das Suffix ist alles nach
        // "com.mykilos6.<base>." — als letztes Segment interpretiert, falls
        // die userID doch einen Punkt enthielte (defensiv).
        let lastSegment = rest.split(separator: ".").last.map(String.init) ?? rest
        return lastSegment.isEmpty ? nil : lastSegment
    }
}

// MARK: - KeychainMetadataLister (echte Keychain-Metadaten-Abfrage)
/// Liest über das Security-Framework NUR die Metadaten (Service-Namen) aller
/// generischen Passwort-Einträge und filtert auf das `com.mykilos6.`-Präfix.
///
/// ⛔ Liest NIE Secret-Werte: `kSecReturnData: false` (nur Attribute), und es
/// wird ausschließlich das `kSecAttrService`-Feld ausgewertet. Kein Wert
/// verlässt jemals das Keychain. Fehler → leere Liste (kein Absturz, kein Log).
public struct KeychainMetadataLister: StoredKeyLister {
    public init() {}

    public func storedServiceNames() -> [String] {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecReturnAttributes: true,
            // Explizit KEINE Werte laden — nur Metadaten.
            kSecReturnData: false,
            kSecUseAuthenticationUI: kSecUseAuthenticationUISkip,
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let items = result as? [[CFString: Any]] else {
            // errSecItemNotFound oder jeder andere Fehler → leere Liste.
            return []
        }
        let services = items.compactMap { attributes -> String? in
            attributes[kSecAttrService] as? String
        }
        return services.filter { $0.hasPrefix("com.mykilos6.") }
    }
}
