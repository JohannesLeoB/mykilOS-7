import Foundation

// MARK: - OnboardingStep
// Lineare Schrittfolge des First-Run-Wizards. welcome → profile → claude →
// google → optional → done. Claude + Google sind die zwei essenziellen
// Verbindungen für den Assistenten.
enum OnboardingStep: Int, CaseIterable {
    case welcome
    case profile
    case claude
    case google
    case optional
    case done

    var indicatorIndex: Int { rawValue + 1 }
    static var indicatorTotal: Int { allCases.count }
}
