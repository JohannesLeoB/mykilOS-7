import Foundation

// MARK: - TeamRoster (ClickUp-Vollintegration, 2026-07-07)
// Rein lesende Anzeige-Referenz: Ghost-Kürzel ↔ echte ClickUp-Member-ID, für Farb-/Kürzel-
// Anzeige an bereits vorhandenen (echten) ClickUp-Assignee-Daten. KEIN Schreibpfad — mykilOS
// weist nie zu ([[aufgaben-nur-mensch-zu-mensch-regel]]); das hier macht nur sichtbar, wer laut
// ClickUp bereits zugewiesen ist. Quelle: Airtable Ghost-Personas (`tbl56f2arYm0ynrYx`,
// Feld "ClickUp-User-ID (Referenz)") — Johannes 2026-07-07 bestätigt.
public struct TeamMember: Identifiable, Equatable, Sendable {
    public let kuerzel: String
    public let clickUpMemberID: String
    public var id: String { kuerzel }

    public init(kuerzel: String, clickUpMemberID: String) {
        self.kuerzel = kuerzel
        self.clickUpMemberID = clickUpMemberID
    }
}

public enum TeamRoster {
    public static let alle: [TeamMember] = [
        TeamMember(kuerzel: "Jo", clickUpMemberID: "99729772"),
        TeamMember(kuerzel: "Da", clickUpMemberID: "296479146"),
        TeamMember(kuerzel: "Fra", clickUpMemberID: "296476295"),
        TeamMember(kuerzel: "Sen", clickUpMemberID: "99729773"),
        TeamMember(kuerzel: "Jil", clickUpMemberID: "248493812")
    ]

    /// Ghost-Kürzel für eine reale ClickUp-Member-ID, oder `nil` (unbekannt/kein Assignee).
    public static func kuerzel(fuerClickUpMemberID memberID: String?) -> String? {
        guard let memberID else { return nil }
        return alle.first { $0.clickUpMemberID == memberID }?.kuerzel
    }
}
