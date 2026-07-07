import Foundation

// MARK: - MykInvitePayload (Onboarding-Plan Ebene 2, docs/handoffs/ONBOARDING_ADMIN_EINLADUNG_PLAN.md)
// Der ENTSCHLÜSSELTE Inhalt einer .mykinvite-Datei: geteilte Zugangsdaten als Key-Value-Paare.
// V1 (Claude-Entscheidung, 2026-07-06/07): nur Airtable-PAT + Base-ID — der Plan selbst empfiehlt
// "erst Team-Airtable, dann weitere". Weitere Schlüssel (Claude-Team-Key o. ä.) sind eine reine
// Registry-Erweiterung (neue `Schluessel`-Konstante), kein Formatwechsel.
// Foundation-only (MykilosKit-Regel: kein SwiftUI, kein GRDB).
public struct MykInvitePayload: Codable, Equatable, Sendable {
    public var werte: [String: String]
    public var erstelltAm: Date
    public var ablaufAm: Date?
    /// Für WEN ist diese Einladung? Reine Metadaten (kein Secret) — liegen bewusst INNERHALB
    /// der Verschlüsselung, damit die E-Mail nicht im Klartext auf der Datei steht. Der
    /// Onboarding-Wizard begrüßt damit namentlich UND kann prüfen, dass der spätere Google-
    /// Login zur eingeladenen Adresse passt. Beide optional — alte Dateien ohne diese Felder
    /// dekodieren weiter (additiv).
    public var eingeladeneEmail: String?
    public var eingeladenerName: String?

    public init(
        werte: [String: String],
        erstelltAm: Date = Date(),
        ablaufAm: Date? = nil,
        eingeladeneEmail: String? = nil,
        eingeladenerName: String? = nil
    ) {
        self.werte = werte
        self.erstelltAm = erstelltAm
        self.ablaufAm = ablaufAm
        self.eingeladeneEmail = eingeladeneEmail
        self.eingeladenerName = eingeladenerName
    }

    public var istAbgelaufen: Bool {
        guard let ablaufAm else { return false }
        return Date() > ablaufAm
    }

    /// Stabile Schlüssel-Konstanten (Schaltschrank-Prinzip: keine verstreuten Stringliterale).
    /// Team-geteilte Zugangsdaten — NIE persönliche Secrets (eigener Google-Login/Clockodo).
    public enum Schluessel {
        public static let airtablePAT = "airtable.pat"
        public static let airtableBaseID = "airtable.baseID"
        // Google-OAuth-CLIENT-Config (App-Ebene, kein User-Token) — Johannes 2026-07-07.
        public static let googleClientID = "google.clientID"
        public static let googleClientSecret = "google.clientSecret"
        // Team-Claude-Key (nur wenn EIN geteilter Anthropic-Key genutzt wird) — Johannes 2026-07-07.
        public static let claudeAPIKey = "claude.apiKey"
        public static let claudeModel = "claude.model"
    }
}

// MARK: - MykInviteInhalt — welche Team-Key-Gruppen der Admin in die Datei legt
// OptionSet, damit die Admin-UI je Gruppe an-/abwählen kann. ClickUp bewusst NICHT dabei
// (geht bald per-User live — ein geteilter Token wäre dann falsch). Persönliches (eigener
// Google-Login, Clockodo) ist grundsätzlich nie eine Option.
public struct MykInviteInhalt: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// Airtable-PAT + Base-ID (die geteilten Projekt-/Kontaktdaten, read-only).
    public static let airtable = MykInviteInhalt(rawValue: 1 << 0)
    /// Google-OAuth-Client-Config (Client-ID + -Secret, App-Ebene — kein User-Token).
    public static let googleClient = MykInviteInhalt(rawValue: 1 << 1)
    /// Team-Claude-Key + Modell (nur bei EINEM geteilten Anthropic-Key sinnvoll).
    public static let claude = MykInviteInhalt(rawValue: 1 << 2)
}
