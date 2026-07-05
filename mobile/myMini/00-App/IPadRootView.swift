import SwiftUI

/// iPad-Wurzel: Sidebar (Sektionen) + Detail-Spalte. Nutzt die grosse
/// Flaeche, waehrend das iPhone unveraendert einspaltig bleibt (die
/// Weiche steht in ContentView via horizontalSizeClass). Erster iPad-
/// Schritt - der Satellit wird zum vollwertigen Tablet-Instrument.
struct IPadRootView: View {
    let standortStore: ProjektStandortStore
    let aufenthaltStore: StandortAufenthaltStore
    let geofenceWaechter: GeofenceWaechter

    @State private var store = ProjectStore()
    @State private var feldFotoStore = FeldFotoStore()
    @State private var auswahl: Sektion = .herzschlag

    enum Sektion: String, CaseIterable, Identifiable, Hashable {
        case herzschlag, projekte, copilot, werkzeuge, kontakte, verbindungen
        var id: String { rawValue }
        var titel: String {
            switch self {
            case .herzschlag: return "Herzschlag"
            case .projekte: return "Projekte"
            case .copilot: return "Satellit-Copilot"
            case .werkzeuge: return "Werkzeuge"
            case .kontakte: return "Kontakte"
            case .verbindungen: return "Verbindungen"
            }
        }
        var icon: String {
            switch self {
            case .herzschlag: return "waveform.path.ecg"
            case .projekte: return "square.grid.2x2"
            case .copilot: return "sparkles"
            case .werkzeuge: return "wrench.and.screwdriver"
            case .kontakte: return "person.2"
            case .verbindungen: return "antenna.radiowaves.left.and.right"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $auswahl) {
                ForEach(Sektion.allCases) { sektion in
                    Label(sektion.titel, systemImage: sektion.icon).tag(sektion)
                }
            }
            .navigationTitle("mykilOS")
            .tint(MykColor.brand)
        } detail: {
            detailSpalte
        }
        .tint(MykColor.brand)
    }

    @ViewBuilder
    private var detailSpalte: some View {
        switch auswahl {
        case .herzschlag:
            GlanceCockpitView(standortStore: standortStore, aufenthaltStore: aufenthaltStore, geofenceWaechter: geofenceWaechter)
        case .projekte:
            NavigationStack { IPadProjekteView(store: store, feldFotoStore: feldFotoStore) }
        case .copilot:
            NavigationStack { CopilotView(store: store, feldFotoStore: feldFotoStore) }
        case .werkzeuge:
            NavigationStack { WerkzeugeView(store: store, feldFotoStore: feldFotoStore) }
        case .kontakte:
            NavigationStack { KontakteVerzeichnisView() }
        case .verbindungen:
            NavigationStack { VerbindungenView(standortStore: standortStore, geofenceWaechter: geofenceWaechter) }
        }
    }
}

#Preview {
    let s = ProjektStandortStore()
    let a = StandortAufenthaltStore()
    IPadRootView(standortStore: s, aufenthaltStore: a, geofenceWaechter: GeofenceWaechter(standortStore: s, aufenthaltStore: a))
}
