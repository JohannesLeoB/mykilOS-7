import Foundation
import MykilosKit

// MARK: - AssistantEngine
// Liest Signale und erzeugt daraus priorisierte Insights. Rein synchron,
// testbar, kein Netzwerk — die Daten kommen von außen rein.
public struct AssistantEngine {

    public init() {}

    public func generateInsights(
        projectID: String,
        signals: [WidgetSignal]
    ) -> [AssistantInsight] {
        var insights: [AssistantInsight] = []

        for signal in signals {
            if let insight = mapSignal(signal, projectID: projectID) {
                insights.append(insight)
            }
        }

        if insights.isEmpty {
            insights.append(AssistantInsight(
                projectID: projectID,
                summary: "Alles ruhig bei \(projectID). Wenn etwas aufläuft, melde ich mich.",
                source: .signals,
                priority: .info
            ))
        }

        return insights.sorted { $0.priority > $1.priority }
    }

    private func mapSignal(_ signal: WidgetSignal, projectID: String) -> AssistantInsight? {
        switch signal {
        case .reviewSuggested(let pid, let label) where pid == projectID:
            return AssistantInsight(
                projectID: pid,
                summary: "Neues Angebot erkannt: \(label)",
                detail: "Drive hat ein Eingangsangebot gefunden. Soll ich es für den Bieterspiegel vorbereiten?",
                source: .drive,
                priority: .attention,
                suggestedAction: SuggestedAction(
                    label: "Für Bieterspiegel vorbereiten",
                    auditAction: .offerImported,
                    auditSummary: "Angebot \(label) für Bieterspiegel vorbereitet"
                )
            )
        case .budgetThresholdCrossed(let pid, let ratio) where pid == projectID:
            let percent = Int(ratio * 100)
            return AssistantInsight(
                projectID: pid,
                summary: "Budget bei \(percent) %",
                detail: "Das Projektbudget hat die \(percent)%-Schwelle überschritten.",
                source: .budget,
                priority: ratio >= 0.9 ? .urgent : .attention
            )
        case .deadlineNear(let pid, let days) where pid == projectID:
            return AssistantInsight(
                projectID: pid,
                summary: days == 1 ? "Abnahme morgen" : "Abnahme in \(days) Tagen",
                detail: "Die Projekt-Deadline rückt näher.",
                source: .calendar,
                priority: days <= 1 ? .urgent : .attention
            )
        case .driveFileAdded(let pid, let fileName) where pid == projectID:
            return AssistantInsight(
                projectID: pid,
                summary: "Neue Datei: \(fileName)",
                source: .drive,
                priority: .info
            )
        case .offerDetected(let pid, let label) where pid == projectID:
            return AssistantInsight(
                projectID: pid,
                summary: "Angebot erkannt: \(label)",
                source: .drive,
                priority: .attention
            )
        default:
            return nil
        }
    }
}
