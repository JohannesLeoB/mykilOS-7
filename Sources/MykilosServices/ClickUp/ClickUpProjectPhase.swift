import Foundation
import MykilosKit

// MARK: - ClickUpProjectPhase (2026-07-04)
// Das Custom Field `project_phase` (Testspace `90128024109`, verifiziert per
// `clickup_get_custom_fields`) — 7 Stufen, feiner als mykilOS' 5-stufiger
// Lebenszyklus-Stepper (`ProjectLifecycleStage`). Read-only Abgleich, siehe
// docs/CLICKUP_PROJEKT_MAPPING.md §2: „Abgleich mit Lebenszyklus-Stepper … kein
// Auto-Write in beide Richtungen" — ClickUp sagt nur, mykilOS schreibt nie zurück,
// und der Nutzer setzt seine Stufe weiterhin selbst im Stepper.
public enum ClickUpProjectPhase: Int, CaseIterable, Sendable, Equatable {
    case briefing = 0
    case planung = 1
    case angebot = 2
    case bestellung = 3
    case ausfuehrung = 4
    case abschluss = 5
    case service = 6

    public var label: String {
        switch self {
        case .briefing:   "Briefing"
        case .planung:    "Planung"
        case .angebot:    "Angebot"
        case .bestellung: "Bestellung"
        case .ausfuehrung: "Ausführung"
        case .abschluss:  "Abschluss"
        case .service:    "Service"
        }
    }

    /// Grobe Abbildung auf die 5-stufige mykilOS-Sicht: Bestellung fällt unter Ausführung
    /// (Beschaffung läuft parallel zur Umsetzung), Service unter Abschluss (Nachbetreuung
    /// eines bereits abgeschlossenen Projekts).
    public var mykilosStage: ProjectLifecycleStage {
        switch self {
        case .briefing:    .akquise
        case .planung:     .planung
        case .angebot:     .angebot
        case .bestellung, .ausfuehrung: .ausfuehrung
        case .abschluss, .service:      .abschluss
        }
    }
}
