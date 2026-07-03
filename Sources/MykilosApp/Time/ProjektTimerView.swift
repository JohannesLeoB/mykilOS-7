import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - ProjektTimerView
// mykilOS 8, Block B (S1): das Timer-Widget auf der Projekt-Detailseite (Tab „Zeit").
// Großes Clock-Display, Start/Pause/Stopp, projektabhängige Kostenstellen-Buttons,
// Zielkontingent. Farbe Salbei (people). Rein lokal — Buchung erst nach Doppelbestätigung
// (global, siehe TimerGlobalDialogs). Live-Zeit über TimelineView (1 Hz).
struct ProjektTimerView: View {
    let projektNummer: String
    let projektTitel: String
    @Environment(AppState.self) private var appState

    // mykilOS 8, Block C (S2): Kostenstellen über den NomenklaturStore (Default jetzt,
    // Airtable-Quelle sobald ein Feld existiert) statt fest verdrahteter Liste. Direkte
    // Methode statt Provider-Allokation pro View-Frame (Block-C-Review-Fix).
    private var kostenstellen: [Kostenstelle] {
        appState.nomenklatur.kostenstellen(fuer: projektNummer)
    }
    @State private var pendingKostenstelle: String = Kostenstelle.defaults.first?.name ?? "Allgemein"
    @State private var zielInput: String = ""
    @State private var editingZiel = false

    private var store: TimerStore { appState.timer }
    private var isActiveHere: Bool { store.active?.projektNummer == projektNummer }
    private var aktiveKostenstelle: String {
        isActiveHere ? (store.active?.kostenstelle ?? pendingKostenstelle) : pendingKostenstelle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s7) {
            timerCard
            zielCard
            if store.active != nil && isActiveHere == false {
                otherRunningNote
            }
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.top, MykSpace.s7)
        .padding(.bottom, 40)
        .onAppear {
            if let z = store.zielkontingent(for: projektNummer) {
                zielInput = String(Int(z.zielStunden))
            }
        }
    }

    // MARK: Timer-Karte
    private var timerCard: some View {
        VStack(alignment: .leading, spacing: MykSpace.s6) {
            HStack(spacing: 7) {
                Circle().fill(MykColor.people.color).frame(width: 8, height: 8)
                Text("Zeit — \(projektTitel)")
                    .font(.mykHeadline).foregroundStyle(MykColor.people.color)
            }

            // Clock + Haupt-Button (Live über TimelineView)
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(TimerFormat.clock(isActiveHere ? store.currentRunSeconds() : 0))
                            .font(.mykTimerClock)
                            .monospacedDigit()
                            .foregroundStyle(MykColor.ink.color)
                        Text(isActiveHere
                             ? "Kostenstelle: \(aktiveKostenstelle)\(store.active?.isPaused == true ? " · pausiert" : "")"
                             : "kein Timer für dieses Projekt")
                            .font(.mykCaption).foregroundStyle(MykColor.muted.color)
                    }
                    Spacer()
                    controls
                }
            }

            Text("Kostenstelle in diesem Projekt").font(.mykCaption).foregroundStyle(MykColor.muted.color)
            kostenstellenRow
            // UI-Polish (2026-07-02, Johannes): Erklärabsatz zum Segment-Wechsel entfernt
            // (Mock-up-Überbleibsel) — das Verhalten steht im Benutzerhandbuch.
        }
        .padding(MykSpace.s7)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.lg).stroke(MykColor.line.color, lineWidth: 0.5))
    }

    @ViewBuilder
    private var controls: some View {
        HStack(spacing: MykSpace.s3) {
            if isActiveHere, let active = store.active {
                if active.isPaused {
                    pillButton("Weiter", systemImage: "play.fill", color: .people) { try? store.resume() }
                } else {
                    pillButton("Pause", systemImage: "pause.fill", color: .people, filled: false) { try? store.pause() }
                }
                pillButton("Stopp", systemImage: "stop.fill", color: .critical) { try? store.requestStop() }
            } else {
                pillButton("Starten", systemImage: "play.fill", color: .people) {
                    try? store.start(projektNummer: projektNummer, projektTitel: projektTitel, kostenstelle: pendingKostenstelle)
                }
            }
        }
    }

    private func pillButton(_ title: String, systemImage: String, color: MykColor, filled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage).font(.mykCaption)
                Text(title).font(.mykSmall)
            }
            .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s3)
            .foregroundStyle(filled ? Color.white : color.color)
            .background(filled ? color.color : Color.clear)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(color.color, lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private var kostenstellenRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MykSpace.s3) {
                ForEach(kostenstellen) { ks in
                    let isOn = aktiveKostenstelle == ks.name
                    Button {
                        if isActiveHere {
                            try? store.switchKostenstelle(to: ks.name)
                        } else {
                            pendingKostenstelle = ks.name
                        }
                    } label: {
                        Text(ks.name).font(.mykSmall)
                            .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s3)
                            .foregroundStyle(isOn ? MykColor.people.color : MykColor.inkSoft.color)
                            .background(isOn ? MykColor.people.color.opacity(0.14) : Color.clear)
                            .overlay(RoundedRectangle(cornerRadius: MykRadius.sm)
                                .stroke(isOn ? MykColor.people.color : MykColor.line.color, lineWidth: 0.5))
                            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Zielkontingent-Karte (S1: lokal editierbar, Feldgerüst)
    private var zielCard: some View {
        let ziel = store.zielkontingent(for: projektNummer)
        let gebucht = store.gebuchteStunden(for: projektNummer)
        return VStack(alignment: .leading, spacing: MykSpace.s4) {
            HStack {
                Text("Zielkontingent").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
                Spacer()
                if let ziel {
                    Text(ziel.herkunft == .auto ? "automatisch" : "manuell")
                        .font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
                }
            }
            if editingZiel || ziel == nil {
                HStack(spacing: MykSpace.s3) {
                    TextField("z. B. 40", text: $zielInput)
                        .textFieldStyle(.roundedBorder).frame(width: 90)
                    Text("Std").font(.mykSmall).foregroundStyle(MykColor.muted.color)
                    Button("Speichern") {
                        if let h = Double(zielInput.replacingOccurrences(of: ",", with: ".")) {
                            try? store.setZielkontingent(projektNummer: projektNummer, stunden: h, herkunft: .manuell)
                        }
                        editingZiel = false
                    }
                    .font(.mykSmall)
                    if ziel != nil {
                        Button("Abbrechen") { editingZiel = false }.font(.mykSmall).foregroundStyle(MykColor.muted.color)
                    }
                }
            } else if let ziel {
                HStack(spacing: MykSpace.s5) {
                    Text("\(Int(gebucht.rounded())) / \(Int(ziel.zielStunden)) Std")
                        .font(.mykBody).foregroundStyle(MykColor.ink.color).monospacedDigit()
                    ProgressView(value: min(gebucht, ziel.zielStunden), total: max(ziel.zielStunden, 1))
                        .tint(gebucht > ziel.zielStunden ? MykColor.critical.color : MykColor.people.color)
                        .frame(maxWidth: 180)
                    Button { editingZiel = true; zielInput = String(Int(ziel.zielStunden)) } label: {
                        Image(systemName: "pencil").font(.mykSmall).foregroundStyle(MykColor.muted.color)
                    }.buttonStyle(.plain)
                }
            }
            Text("Lokal · S1 manuell, automatische Herleitung folgt mit der Airtable-Anbindung.")
                .font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
        }
        .padding(MykSpace.s7)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.lg).stroke(MykColor.line.color, lineWidth: 0.5))
    }

    private var otherRunningNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.badge.exclamationmark").foregroundStyle(MykColor.people.color)
            Text("Ein Timer läuft gerade in \(store.active?.projektTitel ?? "einem anderen Projekt"). Der Starten-Knopf fragt, ob du hierher übernehmen willst.")
                .font(.mykCaption).foregroundStyle(MykColor.inkSoft.color)
        }
        .padding(MykSpace.s5)
        .background(MykColor.people.color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
    }
}
