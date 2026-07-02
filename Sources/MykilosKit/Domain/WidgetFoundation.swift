import Foundation

// MARK: - WidgetKind
// Stabile interne Keys — NIEMALS ändern, da sie in der Persistenz landen.
// Neue Arten immer hinzufügen, nie umbenennen.
public enum WidgetKind: String, Codable, CaseIterable, Sendable {
    case drive        // Dateien · Terrakotta
    case tasks        // Aufgaben · Ocker
    case contacts     // Menschen · Salbei
    case cash         // Geld · Tiefblau
    case calendar     // Termine · Salbei
    case notes        // Notiz · Pflaume
    case assistant    // Dolmetscher · Tinte
    // Home-spezifisch (Akt 2)
    case focus          // Fokus-Liste · Tinte
    case projectFaves   // Projekt-Favoriten · Ocker
    case clockodo       // Zeiterfassung · Ocker
    case recentActivity // Letzte Aktivität · Terrakotta
    case mail           // E-Mails · Pflaume
    case kalkulation    // Schätz-Brain · Ocker
    case warenkorb      // Projekt-Warenkorb · Tiefblau
    // Akt 3+: sevdesk…
}

// MARK: - WidgetSize
public enum WidgetSize: String, Codable, Sendable {
    case small   // 1 Spalte, kompakt
    case medium  // 1 Spalte, normal
    case wide    // 2 Spalten
    case full    // 3 Spalten

    public var columnSpan: Int {
        switch self { case .small, .medium: 1; case .wide: 2; case .full: 3 }
    }
}

// MARK: - WidgetInstance
public struct WidgetInstance: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var kind: WidgetKind
    public var size: WidgetSize
    public var position: Int
    public var isVisible: Bool
    public var isPinned: Bool

    public init(id: UUID = UUID(), kind: WidgetKind, size: WidgetSize = .medium,
                position: Int, isVisible: Bool = true, isPinned: Bool = false) {
        self.id = id; self.kind = kind; self.size = size
        self.position = position; self.isVisible = isVisible; self.isPinned = isPinned
    }
}

// MARK: - Default-Layouts (Option A: einheitlicher vollständiger Widget-Satz)
// Alle Projekttypen erhalten denselben Widget-Satz. Project.kind beeinflusst
// nur die Hero-Gradient-Farbe, nie den Funktionsumfang.
// WidgetBoardStore.reconcileCanonicalWidgets() ergänzt diese Widgets
// nicht-destruktiv in bereits gespeicherten Boards (Migration ohne Datenverlust).
public enum WidgetBoardDefault {
    // Computed property — erzeugt jedes Mal frische UUIDs (kein UUID-Sharing
    // zwischen Boards, die beide erstmals laden und in dieselbe DB schreiben).
    public static var canonicalLayout: [WidgetInstance] {
        [
            WidgetInstance(kind: .drive,     size: .wide,   position: 0),
            WidgetInstance(kind: .contacts,  size: .medium, position: 1),
            WidgetInstance(kind: .tasks,     size: .medium, position: 2),
            WidgetInstance(kind: .cash,      size: .wide,   position: 3),
            WidgetInstance(kind: .calendar,  size: .medium, position: 4),
            WidgetInstance(kind: .notes,     size: .medium, position: 5),
            WidgetInstance(kind: .warenkorb, size: .wide,   position: 6),
            WidgetInstance(kind: .assistant, size: .full,   position: 7),
        ]
    }

    public static func layout(for kind: ProjectKind) -> [WidgetInstance] {
        canonicalLayout
    }
}
