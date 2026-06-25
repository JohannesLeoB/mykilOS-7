import Foundation

// MARK: - WidgetBoardID
// Eindeutige Identität eines Widget-Boards. "home" ist das Heute-Board,
// alle anderen sind Projekt-Boards (Projektnummer als Key).
public enum WidgetBoardID: Hashable, Sendable, CustomStringConvertible {
    case home
    case project(String)   // Projektnummer z. B. "ME-24"

    public var rawValue: String {
        switch self { case .home: "home"; case let .project(p): "project_\(p)" }
    }
    public var description: String { rawValue }
}

// MARK: - Home-Widget-Arten (Akt 2)
// Ergänzung zu den Projekt-Widgets aus Akt 1.
extension WidgetKind {
    // Home-spezifisch
    public static let focus          = WidgetKind(rawValue: "focus")!
    public static let projectFaves   = WidgetKind(rawValue: "projectFaves")!
    public static let clockodo       = WidgetKind(rawValue: "clockodo")!
    public static let recentActivity = WidgetKind(rawValue: "recentActivity")!
}

// Da wir new Cases via statics definieren können wir CaseIterable nicht nutzen —
// daher kein breaking change an WidgetKind.

// MARK: - Home-Default-Layout
extension WidgetBoardDefault {
    public static var homeLayout: [WidgetInstance] {[
        WidgetInstance(kind: .focus,          size: .wide,   position: 0),
        WidgetInstance(kind: .notes,          size: .medium, position: 1),
        WidgetInstance(kind: .projectFaves,   size: .full,   position: 2),
        WidgetInstance(kind: .recentActivity, size: .wide,   position: 3),
        WidgetInstance(kind: .clockodo,       size: .medium, position: 4),
    ]}
}
