import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - FocusWidget
// "Heute zählt." — kuratiert, klar, kein Lärm.
// Liest Signale aus StudioContext und destilliert sie zu max. 2 konkreten Dingen.
// Nicht "14 offene Aufgaben" — sondern die zwei, die heute Gewicht haben.
struct FocusWidget: View {
    @Environment(StudioContext.self) private var context

    var body: some View {
        WidgetContainer(
            kind: .focus,
            sourceLabel: "HEUTE  ·  KALENDER + CLICKUP + CLOCKODO",
            renderState: .content,
            projectID: "home"
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s6) {
                header
                Divider().overlay(MykColor.line.color)
                focusItems
                if context.signals.isEmpty {
                    noSignalHint
                }
            }
        }
    }

    private var header: some View {
        HStack {
            SourceChip(kind: .focus)
            Text("Heute zählt").mykWidgetTitle()
            Spacer()
            Text(Date.now.formatted(.dateTime.hour().minute()))
                .font(.mykMono(11))
                .foregroundStyle(MykColor.faint.color)
        }
    }

    private var focusItems: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            ForEach(synthesized.prefix(2).indices, id: \.self) { i in
                FocusItem(text: synthesized[i], rank: i)
            }
            if synthesized.count > 2 {
                Text("+ \(synthesized.count - 2) weitere")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.muted.color)
                    .padding(.top, MykSpace.s2)
            }
        }
    }

    private var noSignalHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up.left")
                .font(.mykCaption)
                .foregroundStyle(MykColor.faint.color)
            Text("Signal-Demo oben drücken um Signale zu simulieren")
                .font(.mykCaption)
                .foregroundStyle(MykColor.faint.color)
        }
    }

    // MARK: Synthese aus aktiven Signalen
    private var synthesized: [String] {
        var items: [String] = []
        let active = context.signals

        if active.contains(where: { if case .reviewSuggested = $0 { return true }; return false }) {
            items.append("Angebot Küche Meyer prüfen → Cash-Widget")
        }
        if active.contains(where: { if case .deadlineNear(let pid, let days) = $0, days <= 2 { return true }; return false }) {
            items.append("Abnahme Meyer in 2 Tagen — Bartresen freigeben")
        }
        if active.contains(where: { if case .budgetThresholdCrossed(_, let r) = $0, r > 0.7 { return true }; return false }) {
            items.append("Budget Meyer bei 72 % — im Blick behalten")
        }
        // Default wenn keine Signale
        if items.isEmpty {
            items = ["Küche Meyer — Bartresen-Detail freigeben", "Loft — Zeichnungen für Freitag"]
        }
        return items
    }
}

// MARK: - FocusItem
private struct FocusItem: View {
    let text: String
    let rank: Int

    var body: some View {
        HStack(alignment: .top, spacing: MykSpace.s4) {
            // Rang-Indikator: 0 = Terrakotta (kritisch), 1 = Ocker
            Circle()
                .fill(rank == 0 ? MykColor.drive.color : MykColor.tasks.color)
                .frame(width: 7, height: 7)
                .padding(.top, 5)
            Text(text)
                .font(rank == 0 ? .mykHeadline : .mykBody)
                .foregroundStyle(rank == 0 ? MykColor.ink.color : MykColor.inkSoft.color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// SourceChip und WidgetContainer-Extension für home-spezifische Kinds
extension WidgetKind {
    var iconName: String {
        switch rawValue {
        case "focus":          return "scope"
        case "projectFaves":   return "star"
        case "clockodo":       return "clock"
        case "recentActivity": return "bolt"
        default:               return "square"
        }
    }
}
