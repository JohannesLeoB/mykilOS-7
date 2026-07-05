import Foundation

/// Ein während des Bluetooth-Scans entdecktes Gerät. `erkannterHersteller`
/// kommt aus der Namens-Heuristik in `LaserAdapterRegistry` — ein Hinweis,
/// kein verifiziertes Protokoll (siehe `LaserAdapter.istProtokollVerifiziert`).
struct BLEGeraet: Identifiable, Hashable {
    let id: UUID
    let name: String
    let rssi: Int
    let erkannterHersteller: String?

    init(id: UUID, name: String, rssi: Int) {
        self.id = id
        self.name = name
        self.rssi = rssi
        self.erkannterHersteller = LaserAdapterRegistry.erkenne(geraeteName: name)?.herstellerName
    }
}

/// Ein entdeckter GATT-Service eines verbundenen Geräts — das eigentliche
/// Werkzeug dieses Bausteins: sobald ein echtes Laser-Messgerät in der
/// Hand ist, zeigt diese Liste seine echten Service-/Characteristic-IDs,
/// damit das passende Mess-Protokoll darauf aufgebaut werden kann, statt
/// eine Hersteller-Schnittstelle zu erraten.
struct BLEService: Identifiable, Hashable {
    let id: String
    var characteristics: [BLECharacteristic]
}

struct BLECharacteristic: Identifiable, Hashable {
    let id: String
    let eigenschaften: [String]
}
