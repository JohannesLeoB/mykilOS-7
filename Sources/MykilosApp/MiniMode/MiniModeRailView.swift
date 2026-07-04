import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - MiniModeRailView
//
// Der Inhalt des schwebenden Mini-Mode-Panels: die eingeklappte Icon-Sidebar als
// eigenständiges, schmales Rail. Kein Modulinhalt, nur Icons.
//
//   • Oben das orange mykilOS-Logo → Klick bringt die letzte große Ansicht zurück
//     (Mini-Mode verlassen).
//   • Darunter je ein Icon pro App-Modul → Klick öffnet das Modul (und beendet Mini-Mode).
//   • Ein Icon pulst LANGSAM ORANGE (MykColor.brand), wenn seine Quelle Aufmerksamkeit
//     will (offene Aufgaben → Assistent-Icon; offene Signale → Heute-Icon). Ein Signal
//     sagt „hey" UND „welches Modul" — kein Ganz-Fenster-Puls. Abschaltbar pro Quelle
//     (Settings → Datenschutz).
//   • Unten eine ruhige Timer-Kachel, solange ein Timer läuft (Zustand, kein Rückstand →
//     kein Puls).
//   • Hover über das Rail → kleine Alert-Summary-Karte (macOS-Benachrichtigungs-Stil),
//     verschwindet beim Rausfahren. Hover-getriggert, NICHT auto-poppend.
struct MiniModeRailView: View {
    let store: MiniModeStore
    let controller: MiniModeController

    @State private var hovering = false

    private var snapshot: MiniModeSnapshot { store.snapshot }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Hover-Summary-Karte links neben dem Rail (nur bei Hover).
            if hovering && snapshot.hasAnything {
                MiniModePopoverView(store: store, onOpenApp: { controller.returnToMainWindow() })
                    .fixedSize()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            rail
        }
        .animation(.easeInOut(duration: 0.18), value: hovering)
        .onHover { hovering = $0 }
        .task { await store.refresh() }
    }

    // MARK: Das Rail

    private var rail: some View {
        VStack(spacing: MykSpace.s3) {
            logoButton
            Divider().overlay(MykColor.line.color).frame(width: 28)

            ForEach(MiniModeRailModule.allCases) { module in
                RailIcon(
                    module: module,
                    pulsing: shouldPulse(module),
                    action: { controller.openModule(module.appModule) }
                )
            }

            Spacer(minLength: 0)

            if let label = snapshot.activeTimerLabel {
                timerTile(label: label)
            }
        }
        .padding(.vertical, MykSpace.s4)
        .padding(.horizontal, MykSpace.s3)
        .frame(width: 64)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.lg)
                .fill(MykColor.paper.color)
                .overlay(
                    RoundedRectangle(cornerRadius: MykRadius.lg)
                        .stroke(MykColor.line.color, lineWidth: 1)
                )
        )
    }

    // MARK: Logo → zurück zur letzten großen Ansicht

    private var logoButton: some View {
        Button(action: { controller.returnToMainWindow() }) {
            RoundedRectangle(cornerRadius: 9)
                .fill(MykColor.brand.color)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.mykCaption)
                        .foregroundStyle(MykColor.paper.color)
                        .opacity(0.9)
                )
        }
        .buttonStyle(.plain)
        .help("mykilOS öffnen")
        .accessibilityLabel("mykilOS öffnen")
    }

    // MARK: Timer-Kachel (ruhig, kein Puls)

    private func timerTile(label: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: snapshot.timerIsPaused ? "pause.circle" : "timer")
                .font(.mykBody)
                .foregroundStyle(MykColor.people.color)
            Text(MiniModePopoverView.hms(snapshot.activeTimerSeconds ?? 0))
                .font(.mykMono(8))
                .foregroundStyle(MykColor.inkSoft.color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(width: 44)
        .padding(.vertical, MykSpace.s2)
        .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.paper2.color))
        .help(label)
    }

    // MARK: Puls-Entscheidung (respektiert Quellen-Toggles über den Store-Snapshot)

    /// Ein Modul-Icon pulst, wenn eine seiner Aufmerksamkeits-Quellen Rückstand meldet.
    /// Der Store hat ausgeschaltete Quellen gar nicht erst gelesen → sie tauchen nicht in
    /// `attentionSources` auf. Zusätzlich muss der Master-Puls (Datenschutz) an sein.
    private func shouldPulse(_ module: MiniModeRailModule) -> Bool {
        guard MiniModeDefaults.masterEnabled else { return false }
        let attention = snapshot.attentionSources
        return !module.sources.isDisjoint(with: attention)
    }
}

// MARK: - MiniModeRailModule
// Die im Rail gezeigten Module + die Aufmerksamkeits-Quellen, die ihr Icon pulsen lassen.
// Bewusst reduziert (Heute/Projekte/Assistent/Kataloge) — Einstellungen gehören nicht ins
// Mini-Rail. Mapt 1:1 auf AppModule für den Klick.
enum MiniModeRailModule: String, CaseIterable, Identifiable {
    case today, projects, assistant, kataloge
    var id: String { rawValue }

    var appModule: AppModule {
        switch self {
        case .today:     .today
        case .projects:  .projects
        case .assistant: .assistant
        case .kataloge:  .kataloge
        }
    }

    var icon: String { appModule.icon }
    var title: String { appModule.rawValue }

    /// Welche Mini-Mode-Quellen dieses Modul-Icon pulsen lassen. Signale sind heute im
    /// Heute-Board zuhause, Assistent-Aufgaben im Assistenten. Mail wird ergänzt, sobald
    /// ein lokaler Mail-Cache existiert (Folgeschritt).
    var sources: Set<MiniModeSource> {
        switch self {
        case .today:     [.signals]
        case .assistant: [.tasks]
        case .projects:  []
        case .kataloge:  []
        }
    }
}

// MARK: - RailIcon
// Ein einzelnes Modul-Icon im Rail. Langsamer Orange-Puls (opacity-Oszillation über
// TimelineView), wenn `pulsing`. Dasselbe ruhige Puls-Muster wie SidebarPulseBackground.
private struct RailIcon: View {
    let module: MiniModeRailModule
    let pulsing: Bool
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if pulsing {
                    TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
                        let now = timeline.date.timeIntervalSinceReferenceDate
                        // Langsame Welle (~2.4 s Periode), sanfte Amplitude.
                        let wave = 0.5 + 0.5 * sin(now * (2 * .pi / 2.4))
                        RoundedRectangle(cornerRadius: MykRadius.sm)
                            .fill(MykColor.brand.color)
                            .opacity(0.14 + 0.24 * wave)
                    }
                }
                Image(systemName: module.icon)
                    .font(.mykBody)
                    .foregroundStyle(pulsing ? MykColor.brand.color : (hovered ? MykColor.ink.color : MykColor.inkSoft.color))
            }
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: MykRadius.sm)
                    .fill(hovered && !pulsing ? MykColor.paper2.color : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .help(pulsing ? "\(module.title) · braucht Aufmerksamkeit" : module.title)
        .accessibilityLabel(module.title)
    }
}
