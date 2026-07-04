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
    @State private var showWidgetSelector = false

    var body: some View {
        ZStack(alignment: .bottom) {
            MykColor.paper.color
            VStack(spacing: 0) {
                commandBar
                Divider().overlay(MykColor.line.color)
                DriveFolderRefreshBar()
                Divider().overlay(MykColor.line.color.opacity(0.4))
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: MykSpace.s8) {
                        greeting
                        if context.signals.isEmpty == false {
                            signalStrip
                        }
                        HeuteAnstehendView()
                        HomeBoardView(
                            boardStore: appState.homeBoard,
                            noteStore:  appState.homeNotes
                        )
                    }
                    .padding(.horizontal, MykSpace.s9)
                    .padding(.vertical, MykSpace.s8)
                    .padding(.bottom, 48)   // Platz für SaveStateBar
                }
                .clipped()
            }
            SaveStateBar(state: appState.homeBoard.saveState)
        }
        // Drive-Live-Quelle jetzt für ALLE aktiven Projekte, nicht nur für das
        // gerade geöffnete (das deckt nur ProjectDetailView's eigener 60s-Loop
        // ab). Läuft, solange die Heute-Seite offen ist — bewusst seltener als
        // der Pro-Projekt-Loop (read-only, aber 31 Ordner statt 1 pro Tick).
        .task {
            while Task.isCancelled == false {
                _ = await appState.pollAllActiveProjectsForOffers(into: context)
                try? await Task.sleep(for: .seconds(300))
            }
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
            // Widget-Selektor für das Heute-Board (frei ein-/ausblenden + Größe).
            Button { showWidgetSelector.toggle() } label: {
                HStack(spacing: MykSpace.s2) {
                    Image(systemName: "square.grid.2x2").font(.mykMono(11))
                    Text("Widgets").font(.mykMono(11))
                }
                .foregroundStyle(MykColor.muted.color)
                .padding(.horizontal, MykSpace.s3)
                .padding(.vertical, MykSpace.s2)
                .background(MykColor.card.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Widgets der Heute-Ansicht ein-/ausblenden und Größe wählen")
            .accessibilityLabel("Widgets konfigurieren")
            .popover(isPresented: $showWidgetSelector, arrowEdge: .bottom) {
                WidgetSelectorView(boardStore: appState.homeBoard, kinds: WidgetBoardDefault.homeSelectableKinds)
            }
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

    // Neueste-zuerst, dann entdoppelt (Polish 2026-07-04: dasselbe „Projekt
    // fokussiert: X" stapelte sich mehrfach). Ein Signal je Identität, max. 5.
    private var distinctSignals: [WidgetSignal] {
        var seen = Set<String>()
        var out: [WidgetSignal] = []
        for signal in context.signals.reversed() {
            let key = String(describing: signal)
            if seen.insert(key).inserted { out.append(signal) }
            if out.count == 5 { break }
        }
        return out
    }

    // MARK: Signal-Strip
    private var signalStrip: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            Text("Signale dieser Sitzung")
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
                .tracking(0.5)
            ForEach(Array(distinctSignals.enumerated()), id: \.offset) { _, signal in
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

// MARK: - DriveFolderRefreshBar
// Vollbreite Status-Leiste: zeigt den letzten Drive-Poll-Zustand aller
// aktiven Projektordner und löst auf Knopfdruck sofort einen neuen aus
// (dieselbe `pollAllActiveProjectsForOffers`-Logik wie der 300s-Hintergrund-
// Loop weiter oben). Optik identisch mit dem Status-Balken im Dateien-Tab.
private struct DriveFolderRefreshBar: View {
    @Environment(AppState.self) private var appState
    @Environment(StudioContext.self) private var context
    @State private var isPolling = false
    @State private var lastPolled: Date?
    @State private var lastResultCount: Int?

    var body: some View {
        HStack(spacing: MykSpace.s4) {
            Circle()
                .fill(dotColor)
                .frame(width: 7, height: 7)
                .animation(.easeInOut(duration: 0.3), value: isPolling)
            Text(statusText)
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
            Spacer()
            Button("Jetzt prüfen") {
                Task { await poll() }
            }
            .font(.mykMono(10))
            .foregroundStyle(isPolling ? MykColor.muted.color : MykColor.drive.color)
            .buttonStyle(.plain)
            .disabled(isPolling)
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s3)
        .background(MykColor.line.color.opacity(0.18))
    }

    private var dotColor: Color {
        if isPolling { return MykColor.tasks.color }
        if let count = lastResultCount, count > 0 { return MykColor.positive.color }
        return MykColor.muted.color.opacity(0.5)
    }

    private var statusText: String {
        if isPolling { return "Drive-Ordner werden geprüft …" }
        guard let polled = lastPolled else { return "Drive-Ordner noch nicht geprüft" }
        let h = Calendar.current.component(.hour,   from: polled)
        let m = Calendar.current.component(.minute, from: polled)
        if let count = lastResultCount, count > 0 {
            return String(format: "Zuletzt geprüft %02d:%02d · %d neue Belege", h, m, count)
        }
        return String(format: "Zuletzt geprüft %02d:%02d · Keine neuen Belege", h, m)
    }

    private func poll() async {
        isPolling = true
        lastResultCount = await appState.pollAllActiveProjectsForOffers(into: context)
        lastPolled = Date()
        isPolling = false
    }
}
