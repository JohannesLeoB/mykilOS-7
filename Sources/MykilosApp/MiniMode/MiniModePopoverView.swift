import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - MiniModePopoverView
// Kompakte Aggregat-Karte (macOS-Benachrichtigungs-Stil), die beim Hover über das
// schwebende Mini-Rail als Alert-Summary erscheint. Rein lesend — keine Schreibvorgänge,
// keine Buttons, die Daten ändern. Ein Klick auf „mykilOS öffnen" bringt nur das
// Hauptfenster nach vorn. Design: monochrom + Quellfarben als Akzent, alle Werte aus
// MiniModeStore.snapshot. (Der Name bleibt aus Kompatibilitätsgründen — `hms` ist
// getestet; die Rolle wandelte sich von „Menüleisten-Popover" zu „Hover-Karte".)
struct MiniModePopoverView: View {
    let store: MiniModeStore
    /// Bringt das Hauptfenster nach vorn (vom AppDelegate injiziert).
    let onOpenApp: () -> Void

    private var snapshot: MiniModeSnapshot { store.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            header

            Divider().overlay(MykColor.line.color)

            if snapshot.hasAnything {
                VStack(alignment: .leading, spacing: MykSpace.s3) {
                    timerRow
                    nextEventRow
                    countRow(.tasks, count: snapshot.openTaskCount)
                    countRow(.signals, count: snapshot.openSignalCount)
                }
            } else {
                emptyState
            }

            Divider().overlay(MykColor.line.color)

            Button(action: onOpenApp) {
                HStack(spacing: MykSpace.s2) {
                    Image(systemName: "arrow.up.forward.app")
                    Text("mykilOS öffnen").font(.mykSmall)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(MykColor.brand.color)
        }
        .padding(MykSpace.s5)
        .frame(width: 280)
        .background(MykColor.paper.color)
        .task { await store.refresh() }
    }

    // MARK: Kopf

    private var header: some View {
        HStack(spacing: MykSpace.s3) {
            Text("mykilOS")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            Spacer()
            if snapshot.badgeCount > 0 {
                Text("\(snapshot.badgeCount)")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.paper.color)
                    .padding(.horizontal, MykSpace.s2)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(MykColor.brand.color))
            }
        }
    }

    // MARK: Zeilen

    @ViewBuilder
    private var timerRow: some View {
        if let label = snapshot.activeTimerLabel {
            HStack(spacing: MykSpace.s3) {
                Image(systemName: snapshot.timerIsPaused ? "pause.circle" : "timer")
                    .foregroundStyle(MykColor.people.color)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.ink.color)
                        .lineLimit(1)
                    Text(snapshot.timerIsPaused ? "Pausiert" : "Läuft")
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.muted.color)
                }
                Spacer()
                Text(Self.hms(snapshot.activeTimerSeconds ?? 0))
                    .font(.mykMono(11))
                    .foregroundStyle(MykColor.inkSoft.color)
                    .monospacedDigit()
            }
        }
    }

    @ViewBuilder
    private var nextEventRow: some View {
        if let title = snapshot.nextEventTitle {
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "calendar")
                    .foregroundStyle(MykColor.people.color)
                    .frame(width: 18)
                Text(title)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.ink.color)
                    .lineLimit(1)
                Spacer()
                if let date = snapshot.nextEventDate {
                    Text(date, style: .time)
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.muted.color)
                }
            }
        }
    }

    @ViewBuilder
    private func countRow(_ source: MiniModeSource, count: Int) -> some View {
        if count > 0 {
            HStack(spacing: MykSpace.s3) {
                Image(systemName: source.icon)
                    .foregroundStyle(color(for: source))
                    .frame(width: 18)
                Text(source.title)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.ink.color)
                Spacer()
                Text("\(count)")
                    .font(.mykMono(11))
                    .foregroundStyle(MykColor.inkSoft.color)
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(MykColor.positive.color)
            Text("Nichts Offenes.")
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
            Spacer()
        }
        .padding(.vertical, MykSpace.s2)
    }

    /// Nur `.tasks`/`.signals` laufen über `countRow` (Timer/Termin haben eigene
    /// dedizierte Zeilen, Mail zeigt in V1 bewusst keine Zeile — siehe MiniModeStore).
    private func color(for source: MiniModeSource) -> Color {
        switch source {
        case .tasks:   MykColor.tasks.color
        case .signals: MykColor.brand.color
        default:       MykColor.muted.color
        }
    }

    /// H:MM:SS bzw. MM:SS Formatierung der Timer-Sekunden.
    static func hms(_ seconds: Double) -> String {
        let total = Int(max(0, seconds))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }
}
