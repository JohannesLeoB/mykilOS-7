import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - TimerGlobalDialogs
// mykilOS 8, Block B (S1): die zeit-bezogenen Dialoge, die UNABHÄNGIG vom offenen
// Modul/Tab erscheinen müssen — als Overlay über der ganzen App eingehängt (ContentView):
//   · Übernahme-Karte  (Start während ein anderer Timer läuft)
//   · Buchungs-Bestätigung (zwei Schritte: Übersicht → endgültig „Ja, buchen")
//   · Check-in         (Klick auf die pulsierende Sidebar-Pille)
// Reihenfolge der Priorität: Buchung > Übernahme > Check-in.
struct TimerGlobalDialogs: View {
    @Environment(AppState.self) private var appState
    @Binding var checkInRequested: Bool
    @State private var bookingStep = 1

    private var store: TimerStore { appState.timer }
    private var showBooking: Bool { store.active == nil && store.pendingDrafts.isEmpty == false }
    private var showTakeover: Bool { store.pendingTakeover != nil }
    private var showCheckIn: Bool { checkInRequested && store.active != nil }

    private var isAnyUp: Bool { showBooking || showTakeover || showCheckIn }

    var body: some View {
        ZStack {
            if isAnyUp {
                MykColor.ink.color.opacity(0.45).ignoresSafeArea()
                    .onTapGesture { /* modal — nicht durchklicken */ }
                Group {
                    if showBooking {
                        bookingCard
                    } else if showTakeover, let t = store.pendingTakeover {
                        takeoverCard(t)
                    } else if showCheckIn {
                        checkInCard
                    }
                }
                .frame(width: 380)
                .padding(MykSpace.s7)
                .background(MykColor.card.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.lg))
                .overlay(RoundedRectangle(cornerRadius: MykRadius.lg).stroke(MykColor.line.color, lineWidth: 0.5))
                .shadow(color: .black.opacity(0.2), radius: 24, y: 8)
                .transition(.scale(scale: 0.96).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: isAnyUp)
        .onChange(of: showBooking) { _, up in if up { bookingStep = 1 } }
    }

    // MARK: Übernahme
    private func takeoverCard(_ t: PendingTakeover) -> some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Label("Timer läuft noch", systemImage: "clock.badge.exclamationmark")
                .font(.mykHeadline).foregroundStyle(MykColor.people.color)
            Text("In \(t.laufendesProjekt) läuft seit \(TimerFormat.human(t.laufendeSekunden)) ein Timer (\(t.laufendeKostenstelle)).")
                .font(.mykBody).foregroundStyle(MykColor.ink.color).fixedSize(horizontal: false, vertical: true)
            Text("Hierher übernehmen? Der laufende Timer wird gestoppt und du bestätigst die Buchung dafür — danach startet \(t.neuesProjektTitel) · \(t.neueKostenstelle).")
                .font(.mykCaption).foregroundStyle(MykColor.muted.color).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: MykSpace.s3) {
                dialogButton("Abbrechen", style: .ghost) { store.cancelTakeover() }
                dialogButton("Übernehmen", style: .people) { try? store.confirmTakeover() }
            }
        }
    }

    // MARK: Buchungs-Bestätigung (zwei Schritte)
    private var bookingCard: some View {
        let drafts = store.pendingDrafts
        let total = drafts.reduce(0) { $0 + $1.seconds }
        let titel = drafts.first?.projektTitel ?? ""
        return VStack(alignment: .leading, spacing: MykSpace.s5) {
            HStack {
                Text(bookingStep == 1 ? "\(TimerFormat.human(total)) buchen?" : "Sicher buchen?")
                    .font(.mykHeadline).foregroundStyle(MykColor.ink.color)
                Spacer()
                Text("Schritt \(bookingStep) / 2").font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
            }
            if bookingStep == 1 {
                Text(titel).font(.mykBody).foregroundStyle(MykColor.ink.color)
                VStack(alignment: .leading, spacing: MykSpace.s2) {
                    ForEach(drafts) { d in
                        HStack {
                            Text(d.kostenstelle).font(.mykSmall).foregroundStyle(MykColor.inkSoft.color)
                            Spacer()
                            Text(TimerFormat.human(d.seconds)).font(.mykSmall).monospacedDigit().foregroundStyle(MykColor.ink.color)
                        }
                    }
                }
                .padding(MykSpace.s4)
                .background(MykColor.paper2.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                HStack(spacing: MykSpace.s3) {
                    dialogButton("Verwerfen", style: .ghost) { try? store.cancelBooking() }
                    dialogButton("Weiter", style: .people) { bookingStep = 2 }
                }
            } else {
                Text("Diese Buchung wird lokal gespeichert (\(TimerFormat.human(total)), \(titel)).")
                    .font(.mykBody).foregroundStyle(MykColor.inkSoft.color).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: MykSpace.s3) {
                    dialogButton("Zurück", style: .ghost) { bookingStep = 1 }
                    dialogButton("Ja, buchen", style: .critical) {
                        // Vor confirmBooking() sichern — die Methode leert pendingDrafts.
                        let gebuchteDrafts = store.pendingDrafts
                        try? store.confirmBooking()
                        bookingStep = 1
                        // Best-effort-Spiegel in die Clockodo-Adapter-Base (Multi-Base-
                        // Architektur v2) — läuft im Hintergrund, blockiert nie die UI.
                        appState.synchronisiereZeitbuchungenZuClockodoAdapter(
                            gebuchteDrafts.map { TimeSegment(fromDraft: $0) })
                    }
                }
            }
        }
    }

    // MARK: Check-in (aus pulsierender Sidebar)
    private var checkInCard: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Läuft noch?").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
            if let a = store.active {
                Text("\(a.projektTitel) · \(a.kostenstelle) · \(TimerFormat.clock(store.currentRunSeconds()))")
                    .font(.mykSmall).monospacedDigit().foregroundStyle(MykColor.muted.color)
            }
            HStack(spacing: MykSpace.s3) {
                dialogButton("Jetzt stoppen", style: .critical) {
                    checkInRequested = false
                    try? store.requestStop()
                }
                dialogButton("Läuft weiter", style: .people) {
                    store.resetReminder()
                    checkInRequested = false
                }
            }
        }
    }

    // MARK: Button-Helfer
    private enum DialogStyle { case ghost, people, critical }
    private func dialogButton(_ title: String, style: DialogStyle, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.mykSmall)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MykSpace.s4)
                .foregroundStyle(style == .ghost ? MykColor.ink.color : .white)
                .background(backgroundFor(style))
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm)
                    .stroke(style == .ghost ? MykColor.line.color : Color.clear, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        }
        .buttonStyle(.plain)
    }
    private func backgroundFor(_ style: DialogStyle) -> Color {
        switch style {
        case .ghost:    Color.clear
        case .people:   MykColor.people.color
        case .critical: MykColor.critical.color
        }
    }
}
