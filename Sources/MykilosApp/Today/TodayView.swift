import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - TodayView
// Das Heute-Board. Persistent, @MainActor, live.
// Beim ersten Start: Default-Layout wird gesät und sofort in GRDB geschrieben.
// Ab dann: was du hinlegst, bleibt liegen — Neustart vergisst nichts.
struct TodayView: View {
    @Environment(AppState.self) private var appState
    @Environment(StudioContext.self) private var context

    var body: some View {
        ZStack(alignment: .bottom) {
            MykColor.paper.color.ignoresSafeArea()
            VStack(spacing: 0) {
                commandBar
                Divider().overlay(MykColor.line.color)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: MykSpace.s8) {
                        greeting
                        if context.signals.isEmpty == false {
                            signalStrip
                        }
                        HomeBoardView(
                            boardStore: appState.homeBoard,
                            noteStore:  appState.homeNotes
                        )
                    }
                    .padding(.horizontal, MykSpace.s9)
                    .padding(.vertical, MykSpace.s8)
                    .padding(.bottom, 48)   // Platz für SaveStateBar
                }
            }
            SaveStateBar(state: appState.homeBoard.saveState)
        }
    }

    // MARK: Command-Bar
    private var commandBar: some View {
        HStack(spacing: MykSpace.s5) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Heute")
                    .font(.mykDisplay)
                    .foregroundStyle(MykColor.ink.color)
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.mykMono(11))
                    .foregroundStyle(MykColor.muted.color)
                    .tracking(0.5)
            }
            Spacer()
            // Signal-Demo-Knopf — zeigt die Engine in Aktion
            HomeDemoSignalButton()
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s5)
    }

    // MARK: Greeting
    private var greeting: some View {
        Text(greetingText)
            .font(.mykTitle)
            .foregroundStyle(MykColor.inkSoft.color)
    }

    // MARK: Signal-Strip
    private var signalStrip: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            Text("Signale dieser Sitzung")
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
                .tracking(0.5)
            ForEach(Array(context.signals.suffix(5).reversed().enumerated()), id: \.offset) { _, signal in
                SignalPill(signal: signal)
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let base: String
        switch hour {
        case 5..<12: base = "Guten Morgen"
        case 12..<17: base = "Guten Nachmittag"
        case 17..<22: base = "Guten Abend"
        default: base = "Noch wach"
        }
        if let name = appState.profile.profile?.displayName, name.isEmpty == false {
            return "\(base), \(name)."
        }
        return "\(base)."
    }
}

// MARK: - SignalPill
private struct SignalPill: View {
    let signal: WidgetSignal

    var body: some View {
        HStack(spacing: MykSpace.s3) {
            Circle().fill(signalColor).frame(width: 5, height: 5)
            Text(signalText)
                .font(.mykMono(10))
                .foregroundStyle(MykColor.inkSoft.color)
                .lineLimit(1)
        }
        .padding(.horizontal, MykSpace.s4)
        .padding(.vertical, 5)
        .background(Capsule().fill(MykColor.card.color))
    }

    private var signalColor: Color {
        switch signal {
        case .offerDetected, .reviewSuggested:    MykColor.cash.color
        case .deadlineNear, .budgetThresholdCrossed: MykColor.critical.color
        case .driveFileAdded:                     MykColor.drive.color
        case .projectFocused:                     MykColor.faint.color
        }
    }

    private var signalText: String {
        switch signal {
        case .projectFocused(let p):                "Projekt fokussiert: \(p)"
        case .driveFileAdded(let p, let name):      "Datei in \(p): \(name)"
        case .offerDetected(let p, let label):      "Angebot in \(p): \(label)"
        case .reviewSuggested(let p, let label):    "Review: \(p) · \(label)"
        case .budgetThresholdCrossed(let p, let r): "Budget \(p): \(Int(r * 100)) %"
        case .deadlineNear(let p, let days):        "Deadline \(p): \(days) Tage"
        }
    }
}

// MARK: - HomeDemoSignalButton
// Demo: feuert Signale für "Küche Meyer" damit FocusWidget reagiert
private struct HomeDemoSignalButton: View {
    @Environment(StudioContext.self) private var context
    @State private var fired = false

    var body: some View {
        Button {
            withAnimation {
                context.emit(.offerDetected(projectID: "ME-24", label: "Arbeitsplatte"))
                context.emit(.budgetThresholdCrossed(projectID: "ME-24", ratio: 0.72))
                context.emit(.deadlineNear(projectID: "ME-24", days: 2))
                fired = true
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(fired ? MykColor.positive.color : MykColor.faint.color)
                    .frame(width: 6, height: 6)
                    .animation(.easeInOut(duration: 0.3), value: fired)
                Text(fired ? "Signale aktiv" : "Signal-Demo")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.muted.color)
            }
            .padding(.horizontal, MykSpace.s4)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .stroke(MykColor.line.color, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
