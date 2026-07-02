import Foundation

// MARK: - ProjectLifecycleStage
// Die kompakte 5-Stufen-Sicht auf ein Kundenprojekt — die Verdichtung der 10 Phasen,
// die aus den echten Slack-Projektverläufen abgeleitet wurden (Studio-OS, 2026-07-02).
// Bewusst grob für den Hero-Stepper: eine Stufe, kein Micro-Management.
public enum ProjectLifecycleStage: Int, CaseIterable, Codable, Sendable, Identifiable {
    case akquise = 0
    case planung
    case angebot
    case ausfuehrung
    case abschluss

    public var id: Int { rawValue }

    public var label: String {
        switch self {
        case .akquise:     "Akquise"
        case .planung:     "Planung"
        case .angebot:     "Angebot"
        case .ausfuehrung: "Ausführung"
        case .abschluss:   "Abschluss"
        }
    }
}

// MARK: - Ehrliche Ableitung
// Kein Raten: die abgeleitete Startstufe behauptet NIE mehr, als die Signale belegen.
// Sie ist nur ein Vorschlag — der Nutzer setzt die wahre Stufe im Hero-Stepper (lokal
// gespeichert). `isArchived` gewinnt immer (Abschluss); sonst hebt gebuchte Zeit die
// Stufe auf mindestens „Planung" (es wird nachweislich am Projekt gearbeitet). Ohne
// jedes Signal bleibt es „Akquise" — der ehrliche Default für ein frisches Projekt.
public enum ProjectLifecycleDeriver {
    public static func derive(timeBookedHours: Double, isArchived: Bool) -> ProjectLifecycleStage {
        if isArchived { return .abschluss }
        if timeBookedHours > 0 { return .planung }
        return .akquise
    }
}
