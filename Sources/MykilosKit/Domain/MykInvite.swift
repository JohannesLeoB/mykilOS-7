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

    public init(werte: [String: String], erstelltAm: Date = Date(), ablaufAm: Date? = nil) {
        self.werte = werte
        self.erstelltAm = erstelltAm
        self.ablaufAm = ablaufAm
    }

    public var istAbgelaufen: Bool {
        guard let ablaufAm else { return false }
        return Date() > ablaufAm
    }

    /// Stabile Schlüssel-Konstanten (Schaltschrank-Prinzip: keine verstreuten Stringliterale).
    public enum Schluessel {
        public static let airtablePAT = "airtable.pat"
        public static let airtableBaseID = "airtable.baseID"
    }
}
