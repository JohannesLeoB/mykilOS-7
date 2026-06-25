import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - CashWidget
// Geld & Angebote. Empfänger der Drive-Signale. Tiefblau.
// DAS Widget, das die Signal-Kommunikation zeigt: Drive flüstert, Cash fragt.
public struct CashWidget: View {
    public let projectID: String
    public init(projectID: String) { self.projectID = projectID }

    @Environment(StudioContext.self) private var context
    @State private var reviewAccepted = false

    private var hasReviewSignal: Bool {
        context.signals(for: projectID).contains(where: {
            if case .reviewSuggested = $0 { return true }; return false
        })
    }

    public var body: some View {
        WidgetContainer(
            kind: .cash,
            sourceLabel: "SEVDESK + DRIVE  ·  \(hasReviewSignal && !reviewAccepted ? "WARTET AUF FREIGABE" : "AKTUELL")",
            renderState: .content,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                HStack { SourceChip(kind: .cash); Text("Angebote / Cash").mykWidgetTitle(); Spacer() }
                if hasReviewSignal && !reviewAccepted {
                    signalPrompt
                } else {
                    defaultContent
                }
            }
        }
    }

    // Das Signal-Prompt: Drive hat ein Angebot erkannt
    private var signalPrompt: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            // "Flüster"-Linie von Drive
            HStack(spacing: 8) {
                Rectangle().fill(MykColor.cash.color).frame(width: 16, height: 1.5)
                Text("DRIVE MELDET · NEUES EINGANGSANGEBOT")
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.cash.color)
            }
            Text("Lieferanten-PDF erkannt — **Arbeitsplatte Naturstein, 3 Positionen**. Liegt 8 % über dem aktuellen Bieterspiegel.")
                .font(.mykSmall)
                .foregroundStyle(MykColor.ink.color)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { reviewAccepted = true }
                // Audit-Eintrag würde hier ausgelöst — Akt 2+
            } label: {
                Text("In Review übernehmen →")
                    .font(.mykSmall).fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s3)
                    .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.cash.color))
            }
            .buttonStyle(.plain)
        }
        .padding(MykSpace.s5)
        .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.cash.color.opacity(0.08)))
    }

    private var defaultContent: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            if reviewAccepted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(MykColor.positive.color)
                    Text("Angebot in Review übernommen").font(.mykSmall).foregroundStyle(MykColor.ink.color)
                }
            }
            HStack {
                Text("Budget").font(.mykSmall).foregroundStyle(MykColor.muted.color)
                Spacer()
                Text("72 %").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(MykColor.bone.color).frame(height: 4)
                    Capsule().fill(MykColor.tasks.color).frame(width: geo.size.width * 0.72, height: 4)
                }
            }.frame(height: 4)
        }
    }
}
