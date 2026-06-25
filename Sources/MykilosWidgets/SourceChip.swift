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
        }
    }
}

// MARK: - Home-Widget-Kind Extensions (Akt 2)
// Erweiterung für die in WidgetBoard.swift definierten Static-Let-Instanzen.
// Da die neuen WidgetKinds keine neuen enum-Cases sind, brauchen wir guard-basiertes Matching.
public extension WidgetKind {
    var homeIconName: String {
        switch rawValue {
        case "focus":          return "scope"
        case "projectFaves":   return "star"
        case "clockodo":       return "clock"
        case "recentActivity": return "bolt"
        default:               return iconName
        }
    }

    var homeSource: WidgetSource {
        switch rawValue {
        case "focus":          return .assistant
        case "projectFaves":   return .tasks
        case "clockodo":       return .tasks
        case "recentActivity": return .drive
        default:               return source
        }
    }
}
