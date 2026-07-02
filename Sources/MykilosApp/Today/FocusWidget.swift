import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosWidgets

// MARK: - FocusWidget
// "Heute zählt." — kuratiert, klar, kein Lärm.
// Liest Signale aus StudioContext und destilliert sie zu max. 2 konkreten Dingen.
// Nicht "14 offene Aufgaben" — sondern die zwei, die heute Gewicht haben.
struct FocusWidget: View {
    @Environment(StudioContext.self) private var context
    @Environment(AppState.self) private var appState

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
            Image(systemName: "checkmark.circle")
                .font(.mykCaption)
                .foregroundStyle(MykColor.positive.color)
            Text("Alles ruhig — keine offenen Signale.")
                .font(.mykCaption)
                .foregroundStyle(MykColor.muted.color)
        }
    }

    // MARK: Synthese aus aktiven Signalen
    // Jede Zeile nutzt die echte projectID des Signals (nicht den Signal-Typ
    // an sich) und löst den echten Projekttitel über die Registry auf — vorher
    // war hier unabhängig vom tatsächlichen Signal-Inhalt immer "Küche Meyer"/
    // "Loft" hartkodiert.
    private func title(for projectID: String) -> String {
        appState.registry.projects.first { $0.projectNumber == projectID }?.title ?? projectID
    }

    private var synthesized: [String] {
        var items: [String] = []
        let active = context.signals

        for signal in active {
            switch signal {
            case .reviewSuggested(let projectID, let label):
                items.append("\(label) (\(title(for: projectID))) prüfen → Cash-Widget")
            case .deadlineNear(let projectID, let days) where days <= 2:
                items.append("\(title(for: projectID)): Deadline in \(days) Tagen")
            case .budgetThresholdCrossed(let projectID, let ratio) where ratio > 0.7:
                items.append("\(title(for: projectID)): Budget bei \(Int(ratio * 100)) % — im Blick behalten")
            default:
                break
            }
        }
        // Kein Fake-Fallback mehr — ohne passende Signale bleibt die Liste leer
        // und noSignalHint greift (context.signals.isEmpty) bzw. die Sektion
        // zeigt schlicht nichts, statt erfundene Projekte zu nennen.
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
