import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

struct AssistantEngineTests {
    let engine = AssistantEngine()

    @Test func ohneSignaleGibtRuhigenInsight() {
        let insights = engine.generateInsights(projectID: "ME-24", signals: [])
        #expect(insights.count == 1)
        #expect(insights[0].priority == .info)
        #expect(insights[0].summary.contains("ruhig"))
    }

    @Test func reviewSuggestedErzeugtAttentionInsight() {
        let signals: [WidgetSignal] = [
            .reviewSuggested(projectID: "ME-24", label: "Angebot Tischlerei")
        ]
        let insights = engine.generateInsights(projectID: "ME-24", signals: signals)
        #expect(insights.count == 1)
        #expect(insights[0].priority == .attention)
        #expect(insights[0].summary.contains("Angebot"))
        #expect(insights[0].suggestedAction != nil)
        #expect(insights[0].suggestedAction?.auditAction == .offerImported)
    }

    @Test func budgetThresholdErzeugtInsightMitRichtigerPrioritaet() {
        let low = engine.generateInsights(
            projectID: "ME-24",
            signals: [.budgetThresholdCrossed(projectID: "ME-24", ratio: 0.72)]
        )
        #expect(low[0].priority == .attention)
        #expect(low[0].summary.contains("72"))

        let high = engine.generateInsights(
            projectID: "ME-24",
            signals: [.budgetThresholdCrossed(projectID: "ME-24", ratio: 0.95)]
        )
        #expect(high[0].priority == .urgent)
    }

    @Test func deadlineNearErzeugtUrgentBeiEinemTag() {
        let insights = engine.generateInsights(
            projectID: "ME-24",
            signals: [.deadlineNear(projectID: "ME-24", days: 1)]
        )
        #expect(insights[0].priority == .urgent)
        #expect(insights[0].summary.contains("morgen"))
    }

    @Test func deadlineNearZweiTageIstAttention() {
        let insights = engine.generateInsights(
            projectID: "ME-24",
            signals: [.deadlineNear(projectID: "ME-24", days: 3)]
        )
        #expect(insights[0].priority == .attention)
        #expect(insights[0].summary.contains("3 Tagen"))
    }

    @Test func filteredNachProjektID() {
        let signals: [WidgetSignal] = [
            .driveFileAdded(projectID: "LO-23", fileName: "plan.pdf"),
            .deadlineNear(projectID: "ME-24", days: 2),
        ]
        let insights = engine.generateInsights(projectID: "ME-24", signals: signals)
        #expect(insights.count == 1)
        #expect(insights[0].summary.contains("2 Tagen"))
    }

    @Test func mehrereSignaleSortiertNachPrioritaet() {
        let signals: [WidgetSignal] = [
            .driveFileAdded(projectID: "ME-24", fileName: "zeichnung.pdf"),
            .budgetThresholdCrossed(projectID: "ME-24", ratio: 0.95),
            .reviewSuggested(projectID: "ME-24", label: "Angebot X"),
        ]
        let insights = engine.generateInsights(projectID: "ME-24", signals: signals)
        #expect(insights.count == 3)
        #expect(insights[0].priority == .urgent)
        #expect(insights.last?.priority == .info)
    }
}
