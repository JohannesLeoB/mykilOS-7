import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - TimerSidebarPill
// mykilOS 8, Block B (S1): die minimale Aktiv-Timer-Pille in der Sidebar. Sichtbar
// NUR wenn ein Timer läuft/pausiert (sonst rendert sie nichts). Play/Pause-Knopf,
// Projekt + Kostenstelle + tickende Zeit. Klick auf die Pille öffnet den Check-in.
// Im Kompakt-Modus nur ein farbiger Punkt mit Tooltip.
struct TimerSidebarPill: View {
    let compact: Bool
    @Binding var checkInRequested: Bool
    @Environment(AppState.self) private var appState

    private var store: TimerStore { appState.timer }

    var body: some View {
        if let active = store.active {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                let pulsing = store.shouldPulse()
                content(active: active, pulsing: pulsing)
            }
        }
    }

    @ViewBuilder
    private func content(active: ActiveTimer, pulsing: Bool) -> some View {
        if compact {
            Button { checkInRequested = true } label: {
                Circle()
                    .fill(pulsing ? MykColor.critical.color : MykColor.people.color)
                    .frame(width: 10, height: 10)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MykSpace.s3)
            }
            .buttonStyle(.plain)
            .help("\(active.projektTitel) · \(TimerFormat.clock(store.currentRunSeconds()))")
        } else {
            Button { checkInRequested = true } label: {
                HStack(spacing: 9) {
                    playPauseGlyph(active: active)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(active.projektTitel)
                            .font(.mykCaption).foregroundStyle(MykColor.ink.color)
                            .lineLimit(1).truncationMode(.tail)
                        Text(active.kostenstelle)
                            .font(.mykMono(9)).foregroundStyle(MykColor.muted.color).lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    Text(TimerFormat.clock(store.currentRunSeconds()))
                        .font(.mykMono(10)).monospacedDigit()
                        .foregroundStyle(pulsing ? MykColor.critical.color : MykColor.people.color)
                }
                .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s4)
                .background((pulsing ? MykColor.critical.color : MykColor.people.color).opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: MykRadius.md)
                    .stroke((pulsing ? MykColor.critical.color : MykColor.people.color).opacity(0.5), lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
            }
            .buttonStyle(.plain)
            .help("Check-in: läuft der Timer noch?")
        }
    }

    private func playPauseGlyph(active: ActiveTimer) -> some View {
        ZStack {
            Circle().fill(MykColor.people.color).frame(width: 24, height: 24)
            Image(systemName: active.isPaused ? "play.fill" : "pause.fill")
                .font(.mykMono(9)).foregroundStyle(.white)
        }
    }
}

// MARK: - Puls-Hintergrund (ganze Sidebar)
// Sanfter, sparsamer Puls (1 Hz) — färbt die ganze Sidebar dezent kritisch ein, wenn
// die Erinnerungs-Marke erreicht ist (siehe TimerStore.shouldPulse). Klar/aus sonst.
struct SidebarPulseBackground: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        // Der 1-Hz-Tick läuft NUR, solange überhaupt ein Timer aktiv ist — kein
        // Dauer-Render im Leerlauf. (Nicht an shouldPulse() koppeln: solange die
        // Marke noch nicht erreicht ist, wäre shouldPulse() false und es gäbe nichts,
        // das den Marken-Zeitpunkt überhaupt pollt → der Puls würde nie starten.)
        // `active` ist @Observable: startet/stoppt der Timer, baut sich diese View neu auf.
        if appState.timer.active != nil {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let on = appState.timer.shouldPulse()
                let bright = Int(context.date.timeIntervalSinceReferenceDate) % 2 == 0
                MykColor.critical.color
                    .opacity(on ? (bright ? 0.16 : 0.05) : 0)
                    .animation(.easeInOut(duration: 0.9), value: bright)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
    }
}
