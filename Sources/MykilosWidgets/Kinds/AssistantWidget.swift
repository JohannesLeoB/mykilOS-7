import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - AssistantWidget
// Der Dolmetscher. Liest alle Signale des Projekts, formt Insights, schlägt vor.
// Dunkel, dominant, 3 Spalten breit. Schreibt NIE ohne Freigabe.
public struct AssistantWidget: View {
    public let projectID: String
    public init(projectID: String) { self.projectID = projectID }

    @Environment(StudioContext.self) private var context
    @State private var confirmedIDs: Set<UUID> = []

    private var insights: [AssistantInsight] {
        AssistantEngine().generateInsights(
            projectID: projectID,
            signals: context.signals(for: projectID)
        )
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
            sourceLineAssistant
        }
        .background(
            LinearGradient(
                colors: [Color(hex: 0x1F1C17), Color(hex: 0x2C2620)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 4)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            HStack {
                SourceChip(kind: .assistant)
                Text("Assistent").mykWidgetTitle().foregroundStyle(.white.opacity(0.55))
                Spacer()
                priorityBadge
            }
            insightsList
        }
        .padding(MykSpace.s6)
    }

    @ViewBuilder
    private var priorityBadge: some View {
        let highest = insights.map(\.priority).max() ?? .info
        switch highest {
        case .urgent:
            PriorityChip(label: "DRINGEND", color: MykColor.critical.color)
        case .attention:
            PriorityChip(label: "HINWEIS", color: MykColor.tasks.color)
        case .info:
            EmptyView()
        }
    }

    private var insightsList: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            ForEach(insights) { insight in
                InsightRow(
                    insight: insight,
                    isConfirmed: confirmedIDs.contains(insight.id),
                    onConfirm: { confirmedIDs.insert(insight.id) }
                )
            }
        }
    }

    private var sourceLineAssistant: some View {
        HStack(spacing: 8) {
            Circle().fill(MykColor.positive.color).frame(width: 5, height: 5)
            Text("LIEST: DRIVE · CASH · KALENDER · CLOCKODO · MAIL  ·  SCHREIBT NICHTS OHNE FREIGABE")
                .font(.mykMono(9.5))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
        }
        .padding(.horizontal, MykSpace.s6).padding(.vertical, MykSpace.s4)
        .overlay(alignment: .top) {
            Divider().overlay(.white.opacity(0.1))
        }
    }
}

// MARK: - InsightRow

private struct InsightRow: View {
    let insight: AssistantInsight
    let isConfirmed: Bool
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            HStack(spacing: 6) {
                priorityDot
                Text(insight.summary)
                    .font(.mykBody)
                    .foregroundStyle(.white.opacity(0.96))
            }
            if let detail = insight.detail {
                Text(detail)
                    .font(.mykCaption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            if let action = insight.suggestedAction {
                actionButtons(action: action)
            }
        }
        .padding(.vertical, MykSpace.s3)
    }

    private var priorityDot: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 6, height: 6)
    }

    private var dotColor: Color {
        switch insight.priority {
        case .urgent:    MykColor.critical.color
        case .attention: MykColor.tasks.color
        case .info:      MykColor.faint.color
        }
    }

    @ViewBuilder
    private func actionButtons(action: SuggestedAction) -> some View {
        if isConfirmed {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(MykColor.positive.color)
                Text("Bestätigt — wird im Audit protokolliert")
                    .font(.mykMono(9.5))
                    .foregroundStyle(.white.opacity(0.5))
            }
        } else {
            HStack(spacing: MykSpace.s4) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { onConfirm() }
                } label: {
                    Text(action.label)
                        .font(.mykSmall).fontWeight(.semibold)
                        .foregroundStyle(MykColor.ink.color)
                        .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s3)
                        .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(.white))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - PriorityChip

private struct PriorityChip: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.mykMono(9))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(color.opacity(0.15))
            )
    }
}
