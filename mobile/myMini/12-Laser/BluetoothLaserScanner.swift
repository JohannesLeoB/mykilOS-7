import CoreBluetooth
import Observation

/// Generisches Bluetooth-LE-Gerüst für den Laser-Messgeräte-Anschluss
/// (#14) — bewusst OHNE erfundene Leica-/Bosch-Protokolldetails, solange
/// nicht feststeht, welches Gerät Johannes kauft. Was hier wirklich passiert:
/// scannen, verbinden, die echten GATT-Services/Characteristics des
/// verbundenen Geräts anzeigen. Das ist der Explorer, der später — sobald
/// ein echtes Gerät in der Hand ist — die richtigen IDs für das eigentliche
/// Mess-Wert-Parsing liefert, statt eine Herstellerschnittstelle zu raten.
///
/// Off-by-default wie jede sensible Fähigkeit (§14-Doktrin). Kein
/// Mess-Wert wird hier interpretiert — das ist ausdrücklich ein
/// späterer, eigener Schritt.
@MainActor
@Observable
final class BluetoothLaserScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    /// Eine App-weite Instanz: die BLE-Verbindung muss die Navigation
    /// ueberleben (koppeln in "Verbindungen", messen in der Foto-Bemassung).
    /// Erst der Toggle erzeugt den CBCentralManager — off-by-default bleibt.
    static let shared = BluetoothLaserScanner()

    private(set) var aktiv: Bool
    private(set) var scanntGerade = false
    private(set) var gefundeneGeraete: [BLEGeraet] = []
    private(set) var verbundenesGeraet: BLEGeraet?
    private(set) var entdeckteServices: [BLEService] = []
    private(set) var fehler: String?

    /// Letzter echter Laser-Messwert (Leica-DISTO-Protokoll), in Millimetern.
    /// Bleibt nil, bis ein Geraet wirklich funkt — nie ein Platzhalterwert.
    private(set) var letzterMesswertMM: Int?
    private(set) var letzterMesswertZeit: Date?
    private(set) var messwertQuelle: String?
    private(set) var letzterMesswertVerifiziert = false

    private var manager: CBCentralManager?
    private var peripherals: [UUID: CBPeripheral] = [:]

    private static let aktivKey = "bluetoothLaserAktiv"

    override init() {
        self.aktiv = UserDefaults.standard.bool(forKey: Self.aktivKey)
        super.init()
        if aktiv {
            manager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    func aktivieren() {
        aktiv = true
        UserDefaults.standard.set(true, forKey: Self.aktivKey)
        if manager == nil {
            manager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    func deaktivieren() {
        scanStoppen()
        if let verbundenesGeraet, let peripheral = peripherals[verbundenesGeraet.id] {
            manager?.cancelPeripheralConnection(peripheral)
        }
        self.verbundenesGeraet = nil
        entdeckteServices = []
        gefundeneGeraete = []
        aktiv = false
        UserDefaults.standard.set(false, forKey: Self.aktivKey)
    }

    func scanStarten() {
        guard let manager, manager.state == .poweredOn else {
            fehler = "Bluetooth ist nicht eingeschaltet oder noch nicht bereit."
            return
        }
        gefundeneGeraete = []
        fehler = nil
        scanntGerade = true
        manager.scanForPeripherals(withServices: nil)
    }

    func scanStoppen() {
        manager?.stopScan()
        scanntGerade = false
    }

    func verbinden(_ geraet: BLEGeraet) {
        guard let peripheral = peripherals[geraet.id] else { return }
        scanStoppen()
        manager?.connect(peripheral)
    }

    func trennen() {
        guard let verbundenesGeraet, let peripheral = peripherals[verbundenesGeraet.id] else { return }
        manager?.cancelPeripheralConnection(peripheral)
    }

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let zustand = central.state
        Task { @MainActor in
            if zustand != .poweredOn {
                scanntGerade = false
                if zustand == .unauthorized {
                    fehler = "Keine Berechtigung für Bluetooth erteilt."
                }
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name ?? "Unbekanntes Gerät"
        let id = peripheral.identifier
        let rssiWert = RSSI.intValue
        Task { @MainActor in
            peripherals[id] = peripheral
            if let index = gefundeneGeraete.firstIndex(where: { $0.id == id }) {
                gefundeneGeraete[index] = BLEGeraet(id: id, name: name, rssi: rssiWert)
            } else {
                gefundeneGeraete.append(BLEGeraet(id: id, name: name, rssi: rssiWert))
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let name = peripheral.name ?? "Unbekanntes Gerät"
        let id = peripheral.identifier
        Task { @MainActor in
            verbundenesGeraet = BLEGeraet(id: id, name: name, rssi: 0)
            entdeckteServices = []
            peripheral.delegate = self
            peripheral.discoverServices(nil)
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            fehler = "Verbindung fehlgeschlagen: \(error?.localizedDescription ?? "unbekannter Fehler")"
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            verbundenesGeraet = nil
            entdeckteServices = []
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let serviceID = service.uuid.uuidString
        let charakteristiken = (service.characteristics ?? []).map { charakteristik in
            BLECharacteristic(id: charakteristik.uuid.uuidString, eigenschaften: lesbareEigenschaften(charakteristik.properties))
        }
        // Universeller Empfaenger: JEDE Notify-/Indicate-Characteristic
        // abonnieren, nicht nur Leicas. So faengt der Scanner auch generische
        // BLE-Laser (Nordic-UART-Streams, roher Float) ab. Der Wert selbst
        // wird in didUpdateValueFor durch die LaserMesswertDecoder-Kaskade
        // geprueft - ehrliche Vertrauensstufe statt geratener Protokolle.
        for charakteristik in service.characteristics ?? []
        where charakteristik.properties.contains(.notify) || charakteristik.properties.contains(.indicate) {
            peripheral.setNotifyValue(true, for: charakteristik)
        }
        Task { @MainActor in
            if let index = entdeckteServices.firstIndex(where: { $0.id == serviceID }) {
                entdeckteServices[index].characteristics = charakteristiken
            } else {
                entdeckteServices.append(BLEService(id: serviceID, characteristics: charakteristiken))
            }
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let daten = characteristic.value,
              let messwert = LaserMesswertDecoder.dekodiere(charakteristik: characteristic.uuid, daten: daten)
        else { return }
        Task { @MainActor in
            // Ein verifizierter Wert (Leica) wird nie von einem generischen
            // Rauscher ueberschrieben, solange er frisch ist (< 3 s).
            if letzterMesswertVerifiziert, messwert.vertrauen == .generisch,
               let zeit = letzterMesswertZeit, Date().timeIntervalSince(zeit) < 3 { return }
            letzterMesswertMM = messwert.millimeter
            letzterMesswertZeit = Date()
            messwertQuelle = messwert.quelle
            letzterMesswertVerifiziert = messwert.vertrauen == .verifiziert
        }
    }

    private func lesbareEigenschaften(_ eigenschaften: CBCharacteristicProperties) -> [String] {
        var ergebnis: [String] = []
        if eigenschaften.contains(.read) { ergebnis.append("read") }
        if eigenschaften.contains(.write) { ergebnis.append("write") }
        if eigenschaften.contains(.notify) { ergebnis.append("notify") }
        if eigenschaften.contains(.indicate) { ergebnis.append("indicate") }
        return ergebnis
    }
}
