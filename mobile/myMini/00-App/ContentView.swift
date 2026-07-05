import SwiftUI

/// Wirt für den Satelliten. Apples SwiftData-Vorlage ist bewusst raus —
/// schmaler Fuß, keine Datenbank, die wir heute nicht brauchen.
struct ContentView: View {
    let standortStore: ProjektStandortStore
    let aufenthaltStore: StandortAufenthaltStore
    let geofenceWaechter: GeofenceWaechter

    /// Weiche iPhone/iPad: auf breiter Flaeche (iPad) die Sidebar+Detail-
    /// Wurzel, sonst das unveraenderte einspaltige iPhone-Cockpit.
    @Environment(\.horizontalSizeClass) private var breite

    var body: some View {
        if breite == .regular {
            IPadRootView(standortStore: standortStore, aufenthaltStore: aufenthaltStore, geofenceWaechter: geofenceWaechter)
        } else {
            GlanceCockpitView(standortStore: standortStore, aufenthaltStore: aufenthaltStore, geofenceWaechter: geofenceWaechter)
        }
    }
}

#Preview {
    ContentView(
        standortStore: ProjektStandortStore(),
        aufenthaltStore: StandortAufenthaltStore(),
        geofenceWaechter: GeofenceWaechter(standortStore: ProjektStandortStore(), aufenthaltStore: StandortAufenthaltStore())
    )
}
