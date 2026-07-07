import Foundation

// MARK: - WidgetSource
// Jede Quelle hat eine Identität — und im Designsystem eine eigene Farbe.
public enum WidgetSource: String, Codable, Sendable, CaseIterable {
    case drive       // Dateien        — Terrakotta
    case people      // Kontakte       — Salbei
    case calendar    // Termine        — Salbei
    case tasks       // Aufgaben       — Ocker
    case cash        // Geld/Angebote  — Tiefblau
    case notes       // Persönliches   — Pflaume
    case mail        // E-Mails       — Pflaume
    case assistant   // Dolmetscher
}

// MARK: - WidgetSignal
// Kleine, typisierte Ereignisse. Widgets SENDEN sie an den StudioContext und
// LESEN die für sie relevanten. Widgets reden nie direkt miteinander.
public enum WidgetSignal: Sendable, Equatable {
    case projectFocused(projectID: String)
    case driveFileAdded(projectID: String, fileName: String)
    case offerDetected(projectID: String, label: String)
    case drawingDetected(projectID: String, label: String)   // neue Werkzeichnung im Drive-Ordner
    case reviewSuggested(projectID: String, label: String)   // VORSCHLAG, kein Write
    case budgetThresholdCrossed(projectID: String, ratio: Double)
    case deadlineNear(projectID: String, days: Int)
    /// Personalisiert (ClickUp-Alerts, 2026-07-07): NUR ausgelöst, wenn `assigneeID` der
    /// geladenen Aufgabe der eigenen `clickUpMemberID` entspricht — anders als `deadlineNear`
    /// (projektweit, jede Fälligkeit) ist das hier "meine eigene Aufgabe wird bald fällig".
    case myClickUpTaskDueSoon(projectID: String, taskName: String, days: Int)
}
