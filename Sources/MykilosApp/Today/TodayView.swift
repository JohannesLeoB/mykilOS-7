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

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Guten Morgen."
        case 12..<17: return "Guten Nachmittag."
        case 17..<22: return "Guten Abend."
        default: return "Noch wach?"
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
