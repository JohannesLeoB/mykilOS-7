import SwiftUI

/// STERN-2 — der Herzschlag. Übersetzung des HTML-Prototyps der Gründungsnacht
/// in echtes SwiftUI. Liest nur (Registry-Snapshot + Drive-Puls-Schnappschuss),
/// schreibt nirgends — der Satellit dirigiert, er rendert nicht.
struct GlanceCockpitView: View {
    let standortStore: ProjektStandortStore
    let aufenthaltStore: StandortAufenthaltStore
    let geofenceWaechter: GeofenceWaechter

    @State private var store = ProjectStore()
    @State private var postbox = PostboxStore()
    @State private var feldFotoStore = FeldFotoStore()
    @State private var wareneingangStore = WareneingangsLogStore()
    @State private var sprecher = MorgenBriefSprecher()
    @State private var suche = ""
    @State private var standortFehler: String?
    @State private var infoProjekt: Project?

    private var gefiltert: [Project] {
        store.matching(suche).sorted { $0.projectNumber > $1.projectNumber }
    }

    private var begruessung: String {
        let stunde = Calendar.current.component(.hour, from: Date())
        switch stunde {
        case ..<5: return "Nachtschicht, Johannes"
        case ..<11: return "Moin Johannes"
        case ..<18: return "Moin Moin Johannes"
        default: return "N'Abend Johannes"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if !aufenthaltStore.offeneVorschlaege.isEmpty { standortVorschlaege }
                    FangCard(postbox: postbox, store: store, feldFotoStore: feldFotoStore, wareneingangStore: wareneingangStore)
                    puls
                    if !store.hotProjects.isEmpty { geradeHeiss }
                    projektListe
                }
                .padding(16)
            }
            .background(MykColor.paper)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("mykilOS mobile").font(.system(.footnote, design: .monospaced)).foregroundStyle(MykColor.muted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        CopilotView(store: store, feldFotoStore: feldFotoStore)
                    } label: {
                        Image(systemName: "sparkles")
                    }
                    .accessibilityLabel("Satellit-Copilot öffnen")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AssistantChatView(store: store)
                    } label: {
                        Image(systemName: "bubble.left.and.bubble.right")
                    }
                    .accessibilityLabel("Assistent öffnen")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        KontakteVerzeichnisView()
                    } label: {
                        Image(systemName: "person.2")
                    }
                    .accessibilityLabel("Kontakte öffnen")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        WerkzeugeView(store: store, feldFotoStore: feldFotoStore)
                    } label: {
                        Image(systemName: "wrench.and.screwdriver")
                    }
                    .accessibilityLabel("Werkzeuge öffnen")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        VerbindungenView(standortStore: standortStore, geofenceWaechter: geofenceWaechter)
                    } label: {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                    }
                    .accessibilityLabel("Verbindungen anzeigen")
                }
            }
        }
        .tint(MykColor.brand)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SATELLIT · HERZSCHLAG").font(.system(.caption2, design: .monospaced)).foregroundStyle(MykColor.brand)
                Text(begruessung).font(.largeTitle.weight(.bold)).foregroundStyle(MykColor.ink)
            }
            Spacer()
            Button {
                if sprecher.sprichtGerade {
                    sprecher.stoppen()
                } else {
                    sprecher.sprich(MorgenBriefText.formuliere(
                        begruessung: begruessung,
                        projektAnzahl: store.projects.count,
                        offenePostbox: offenePostboxEintraege,
                        offeneFotos: offeneFeldFotos,
                        heissesProjekt: store.hotProjects.first?.project.title
                    ))
                }
            } label: {
                Image(systemName: sprecher.sprichtGerade ? "stop.fill" : "speaker.wave.2.fill")
                    .font(.title3)
                    .foregroundStyle(MykColor.brand)
                    .frame(width: 40, height: 40)
                    .background(MykColor.card)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(MykColor.line))
            }
            .accessibilityLabel(sprecher.sprichtGerade ? "Morgen-Brief stoppen" : "Morgen-Brief vorlesen")
            .padding(.top, 4)
        }
    }

    private var offenePostboxEintraege: Int {
        postbox.items.filter { $0.syncedAt == nil }.count
    }

    private var offeneFeldFotos: Int {
        feldFotoStore.fotos.filter { $0.syncedAt == nil }.count
    }

    private var wareneingangAnzahl: Int {
        wareneingangStore.ereignisse.count
    }

    /// Passiver Zeit-Fang aus #62: der Standort-Wächter hat einen
    /// abgeschlossenen Aufenthalt erkannt — Karte→Bestätigung wie überall,
    /// nie automatisch in die Postbox. Nur sichtbar, wenn die Fähigkeit
    /// überhaupt aktiviert wurde (`aufenthaltStore` bleibt sonst leer).
    private var standortVorschlaege: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(aufenthaltStore.offeneVorschlaege) { aufenthalt in
                VStack(alignment: .leading, spacing: 6) {
                    Text("STANDORT-WÄCHTER")
                        .font(.system(.caption2, design: .monospaced).weight(.semibold))
                        .foregroundStyle(MykColor.brand)
                    Text("Du warst bei \(aufenthalt.projectTitel) — \(aufenthalt.dauerText ?? "").")
                        .font(.subheadline)
                    HStack(spacing: 8) {
                        Button("Als Zeit in die Postbox") {
                            uebernehmenAlsZeit(aufenthalt)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(MykColor.brand)
                        Button("Verwerfen") {
                            try? aufenthaltStore.alsErledigtMarkieren(aufenthalt.id)
                        }
                        .buttonStyle(.bordered)
                    }
                    .font(.footnote.weight(.semibold))
                }
                .padding(12)
                .background(MykColor.brand.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(MykColor.brand, lineWidth: 1.4))
            }
            if let standortFehler {
                Text(standortFehler).font(.footnote.weight(.semibold)).foregroundStyle(MykColor.crit)
            }
        }
    }

    private func uebernehmenAlsZeit(_ aufenthalt: StandortAufenthalt) {
        do {
            try postbox.append(PostboxItem(
                kind: "zeit",
                text: aufenthalt.dauerText ?? "",
                kontext: "\(aufenthalt.projectTitel) (Standort-Wächter)"
            ))
            try aufenthaltStore.alsErledigtMarkieren(aufenthalt.id)
            standortFehler = nil
        } catch {
            standortFehler = Fehlertext.deutsch(error)
        }
    }

    private var puls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                pulsKarte("\(store.projects.count)", "Projekte", akzent: true)
                pulsKarte("\(store.projects.filter { $0.kind == "kitchen" }.count)", "Küchen")
                pulsKarte("\(store.projects.filter { $0.kind == "studioInternal" }.count)", "Studio")
                NavigationLink {
                    PostboxView(postbox: postbox)
                } label: {
                    pulsKarte("\(offenePostboxEintraege)", "Postbox", akzent: offenePostboxEintraege > 0)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Postbox öffnen, \(offenePostboxEintraege) offen")
                NavigationLink {
                    FeldFotoListView(feldFotoStore: feldFotoStore, store: store)
                } label: {
                    pulsKarte("\(offeneFeldFotos)", "Fotos", akzent: offeneFeldFotos > 0)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Feld-Fotos öffnen, \(offeneFeldFotos) offen")
                NavigationLink {
                    WareneingangsLogListView(wareneingangStore: wareneingangStore)
                } label: {
                    pulsKarte("\(wareneingangAnzahl)", "Pakete")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Wareneingang öffnen, \(wareneingangAnzahl) Einträge")
            }
        }
    }

    private func pulsKarte(_ zahl: String, _ label: String, akzent: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(zahl).font(.title2.weight(.bold)).foregroundStyle(akzent ? MykColor.brand : MykColor.ink)
            Text(label.uppercased()).font(.system(.caption2, design: .monospaced)).foregroundStyle(MykColor.muted)
        }
        .frame(width: 84)
        .padding(.vertical, 10)
        .background(MykColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(MykColor.line))
    }

    private var geradeHeiss: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GERADE HEISS · LIVE AUS DRIVE")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(MykColor.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.hotProjects) { HotProjectCard(hot: $0) }
                }
            }
        }
    }

    private var projektListe: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PROJEKTE").font(.system(.caption2, design: .monospaced)).foregroundStyle(MykColor.muted)
                Spacer()
                Text("\(gefiltert.count) / \(store.projects.count)")
                    .font(.system(.caption2, design: .monospaced)).foregroundStyle(MykColor.muted)
            }
            TextField("Suchen: Name oder Nummer…", text: $suche)
                .textFieldStyle(.plain)
                .padding(11)
                .background(MykColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(MykColor.line))

            if let error = store.loadError {
                Text(error).font(.footnote).foregroundStyle(MykColor.crit)
            }

            // Kacheln statt Zeilen (Johannes, 04.07. Abend): antippen
            // oeffnet den Info-Modus mit Kunde, Springen, lokaler
            // Zeitleiste, Unterlagen und Standort-Waechter.
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(gefiltert) { project in
                    Button {
                        infoProjekt = project
                    } label: {
                        ProjektKachel(project: project, pulsText: pulsText(fuer: project))
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(item: $infoProjekt) { project in
                ProjektInfoView(
                    project: project,
                    shortcuts: project.title == "Schmidt" ? store.schmidtShortcuts : [],
                    pulsText: pulsText(fuer: project),
                    store: store,
                    feldFotoStore: feldFotoStore,
                    postbox: postbox,
                    standortStore: standortStore,
                    geofenceWaechter: geofenceWaechter
                )
            }
        }
    }

    private func pulsText(fuer project: Project) -> String? {
        store.hotProjects.first { $0.project.id == project.id }?.relativeLabel
    }
}

#Preview {
    let standortStore = ProjektStandortStore()
    let aufenthaltStore = StandortAufenthaltStore()
    GlanceCockpitView(
        standortStore: standortStore,
        aufenthaltStore: aufenthaltStore,
        geofenceWaechter: GeofenceWaechter(standortStore: standortStore, aufenthaltStore: aufenthaltStore)
    )
}
