import Foundation

// MARK: - Mediator
// Die kleine, zentrale, TESTBARE Regelmenge. Hier — und nur hier — lebt das
// "Drive flüstert dem Cash-Widget zu". Die Regeln sind azyklisch: ein
// abgeleitetes Signal löst keine weitere Ableitung aus.
//
// WICHTIG: Abgeleitete Signale sind VORSCHLÄGE (laut für Einsicht). Sie rendern
// einen Hinweis/Prompt — sie führen NIE eine Aktion aus. Schreiben passiert nur
// über Vorschau → Bestätigung → Audit (leise für Wirkung).
public enum Mediator {
    public static func derive(from signal: WidgetSignal) -> WidgetSignal? {
        switch signal {
        case let .offerDetected(projectID, label):
            // Drive hat ein Angebot erkannt → Cash-Widget soll Review vorschlagen.
            return .reviewSuggested(projectID: projectID, label: label)
        default:
            return nil
        }
    }
}
