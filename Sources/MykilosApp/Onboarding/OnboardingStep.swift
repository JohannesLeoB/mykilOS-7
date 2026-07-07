import Foundation

// MARK: - OnboardingStep
// Lineare Schrittfolge des First-Run-Wizards. welcome → profile → claude →
// google → meldeadresse → optional → done. Claude + Google sind die zwei
// essenziellen Verbindungen für den Assistenten; meldeadresse bestätigt die
// erkannte Identität (read-only, nur lokaler Write).
enum OnboardingStep: Int, CaseIterable {
    case welcome
    // Schlüsselbund-Import (2026-07-07): hat der neue Kollege eine .mykinvite-Einladung, lädt
    // er sie gleich hier + Passwort → alle geteilten Team-Keys (Airtable/Google-Client/Claude)
    // sind vorbereitet, die folgenden Schritte zeigen sie verbunden. Überspringbar.
    case einladung
    case profile
    case claude
    case google
    // E4 (2026-07-05): „Erkannt als … stimmt das?" — Google-Identität bestätigen,
    // clockodoUserID lokal ergänzen. Kein externer Write.
    case meldeadresse
    case optional
    case done

    var indicatorIndex: Int { rawValue + 1 }
    static var indicatorTotal: Int { allCases.count }
}
