import SwiftUI

/// `standortStore`/`aufenthaltStore`/`geofenceWaechter` werden hier auf
/// App-Ebene gehalten, nicht erst in einer Unteransicht erzeugt — Region-
/// Monitoring weckt die App notfalls im Hintergrund neu, und nur wenn der
/// `CLLocationManager` samt Delegate schon beim App-Start existiert, kommt
/// das Betreten/Verlassen-Ereignis überhaupt an.
@main
struct myMiniApp: App {
    @State private var standortStore: ProjektStandortStore
    @State private var aufenthaltStore: StandortAufenthaltStore
    @State private var geofenceWaechter: GeofenceWaechter

    init() {
        let standortStore = ProjektStandortStore()
        let aufenthaltStore = StandortAufenthaltStore()
        _standortStore = State(initialValue: standortStore)
        _aufenthaltStore = State(initialValue: aufenthaltStore)
        _geofenceWaechter = State(initialValue: GeofenceWaechter(standortStore: standortStore, aufenthaltStore: aufenthaltStore))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(standortStore: standortStore, aufenthaltStore: aufenthaltStore, geofenceWaechter: geofenceWaechter)
        }
    }
}
