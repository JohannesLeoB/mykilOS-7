import CoreLocation
import Observation

/// Standort-Wächter (#9/#62) — bewusst OFF by default, ein Kippschalter im
/// Fähigkeiten-Panel schaltet ihn ein (§14-Doktrin: Opt-in, nie Opt-out,
/// jederzeit widerrufbar). Erkennt Betreten/Verlassen gemerkter
/// Projekt-Standorte über echtes `CLLocationManager`-Region-Monitoring —
/// funktioniert auch, wenn die App im Hintergrund ist oder neu gestartet
/// wird (iOS weckt die App für Region-Ereignisse). Deshalb muss diese
/// Instanz app-weit früh existieren (siehe `myMiniApp.swift`), nicht erst,
/// wenn eine bestimmte Ansicht geöffnet wird.
///
/// **Nicht live getestet:** echtes Hintergrund-Wecken über mehrere Stunden,
/// App-Kill-und-Neustart durch iOS, und das genaue Verhalten bei nur
/// "Bei App-Nutzung" statt "Immer" erteilter Berechtigung sind von hier aus
/// nicht überprüfbar — bleibt ein manueller Beta-Check wie beim ★3
/// Drive-Upload.
@MainActor
@Observable
final class GeofenceWaechter: NSObject, CLLocationManagerDelegate {
    private(set) var aktiv: Bool
    private(set) var berechtigungsStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()
    private let standortStore: ProjektStandortStore
    private let aufenthaltStore: StandortAufenthaltStore

    private static let aktivKey = "standortWaechterAktiv"

    init(standortStore: ProjektStandortStore, aufenthaltStore: StandortAufenthaltStore) {
        self.standortStore = standortStore
        self.aufenthaltStore = aufenthaltStore
        self.aktiv = UserDefaults.standard.bool(forKey: Self.aktivKey)
        self.berechtigungsStatus = CLLocationManager().authorizationStatus
        super.init()
        manager.delegate = self
        if aktiv {
            aktualisiereRegionen()
        }
    }

    /// Fragt "Immer"-Standortzugriff an und startet die Überwachung. Der
    /// Nutzer entscheidet im iOS-Dialog — kein stiller Zugriff.
    func aktivieren() {
        manager.requestAlwaysAuthorization()
        aktiv = true
        UserDefaults.standard.set(true, forKey: Self.aktivKey)
        aktualisiereRegionen()
    }

    /// Sofortiger, vollständiger Widerruf — kein Umweg über iOS-Einstellungen.
    func deaktivieren() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        aktiv = false
        UserDefaults.standard.set(false, forKey: Self.aktivKey)
    }

    /// Nach jeder Änderung an gemerkten Standorten aufrufen, damit der
    /// Wächter die aktuelle Liste überwacht. iOS erlaubt maximal 20
    /// überwachte Regionen je App — bei mehr gemerkten Standorten gewinnen
    /// die zuletzt gemerkten.
    func aktualisiereRegionen() {
        guard aktiv else { return }
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        let orte = standortStore.orte.sorted { $0.gespeichertAm > $1.gespeichertAm }.prefix(20)
        for ort in orte {
            let region = CLCircularRegion(
                center: CLLocationCoordinate2D(latitude: ort.breitengrad, longitude: ort.laengengrad),
                radius: ort.radiusMeter,
                identifier: ort.id.uuidString
            )
            region.notifyOnEntry = true
            region.notifyOnExit = true
            manager.startMonitoring(for: region)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            berechtigungsStatus = status
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            guard let ort = standortStore.orte.first(where: { $0.id.uuidString == region.identifier }) else { return }
            try? aufenthaltStore.betreten(projectNumber: ort.projectNumber, projectTitel: ort.projectTitel)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in
            guard let ort = standortStore.orte.first(where: { $0.id.uuidString == region.identifier }) else { return }
            try? aufenthaltStore.verlassen(projectNumber: ort.projectNumber)
        }
    }
}
