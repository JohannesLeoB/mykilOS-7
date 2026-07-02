import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - SourceChip
// Das farbige Quellen-Icon oben links in jedem Widget.
// Farbe = Quelle — man erkennt die Herkunft, bevor man liest.
public struct SourceChip: View {
    public let kind: WidgetKind
    public init(kind: WidgetKind) { self.kind = kind }

    public var body: some View {
        Image(systemName: kind.iconName)
            .font(.mykCaption)
            .foregroundStyle(kind.source.accentColor)
            .frame(width: 24, height: 24)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(kind.source.accentColor.opacity(0.12))
            )
    }
}

extension WidgetKind {
    var iconName: String {
        switch self {
        case .drive:     "folder"
        case .tasks:     "checklist"
        case .contacts:  "person.2"
        case .cash:      "eurosign"
        case .calendar:  "calendar"
        case .notes:     "note.text"
        case .assistant: "sparkles"
        case .focus:          "scope"
        case .projectFaves:   "star"
        case .mail:           "envelope"
        case .clockodo:       "clock"
        case .recentActivity: "bolt"
        case .kalkulation:    "eurosign.square"
        case .warenkorb:      "cart"
        }
    }
}
