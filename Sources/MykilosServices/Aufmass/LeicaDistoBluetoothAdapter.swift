import Foundation
import CoreBluetooth
import MykilosKit

// MARK: - LeicaDistoBluetoothAdapter (Aufmaß-Widget-Plan, Schritt 3)
// CoreBluetooth-Mac-Port des Laser-Adapters. Scannt/koppelt einen Leica-Disto-Laser, meldet
// Verbindungszustand + Messwerte über LaserMeasuring.
//
// ⚠️ EHRLICHER STAND (2026-07-06/07): Die exakte Leica-Disto-Service-/Characteristic-UUID +
// das Payload-Format (Rohbytes → Meter) sind PLATZHALTER, NICHT verifiziert. Der Plan selbst
// verlangt, das Protokoll vom iOS-Satelliten (`LeicaDistoProtokoll`) zu portieren — das ist ein
// ANDERES Repo (`mykilOS iOS`), und Maxime #1 verbietet, dort hineinzugehen ("Nie in ein
// anderes Ordner/Repo/Git"). Erfundene BLE-UUIDs wären eine unverifizierte Behauptung — gebaut
// ist stattdessen die vollständige, ECHTE CoreBluetooth-Infrastruktur (Scannen/Verbinden/
// Zustände) + eine reine, getestete Zustandsüberführung (`LeicaDistoStatusReducer`). Die beiden
// mit OFFEN markierten Stellen sind der einzige Rest, sobald jemand mit Zugriff auf den
// Satelliten (oder das reale Gerät) die echten Werte liefert.
public final class LeicaDistoBluetoothAdapter: NSObject, LaserMeasuring, @unchecked Sendable {
    // OFFEN(Satellit-Port): echte Service-UUID aus LeicaDistoProtokoll übernehmen.
    static let platzhalterServiceUUID = CBUUID(string: "0000FFF0-0000-1000-8000-00805F9B34FB")
    // OFFEN(Satellit-Port): echte Characteristic-UUID für den Messwert übernehmen.
    static let platzhalterMesswertCharacteristicUUID = CBUUID(string: "0000FFF1-0000-1000-8000-00805F9B34FB")

    private var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?

    private let statusContinuation: AsyncStream<LaserVerbindungsStatus>.Continuation
    public let status: AsyncStream<LaserVerbindungsStatus>
    private let massContinuation: AsyncStream<Double>.Continuation
    public let letztesMass: AsyncStream<Double>

    override public init() {
        var statusCont: AsyncStream<LaserVerbindungsStatus>.Continuation!
        self.status = AsyncStream { statusCont = $0 }
        self.statusContinuation = statusCont

        var massCont: AsyncStream<Double>.Continuation!
        self.letztesMass = AsyncStream { massCont = $0 }
        self.massContinuation = massCont
        super.init()
    }

    public func verbinde() async throws {
        statusContinuation.yield(.sucht)
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    public func trenne() async {
        if let peripheral, let centralManager {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        centralManager = nil
        peripheral = nil
        statusContinuation.yield(.getrennt)
    }
}

// MARK: - CBCentralManagerDelegate / CBPeripheralDelegate
extension LeicaDistoBluetoothAdapter: CBCentralManagerDelegate, CBPeripheralDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch LeicaDistoStatusReducer.fuerManagerState(central.state) {
        case .weiterScannen:
            central.scanForPeripherals(withServices: [Self.platzhalterServiceUUID])
        case .melden(let status):
            statusContinuation.yield(status)
        }
    }

    public func centralManager(
        _ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any], rssi RSSI: NSNumber
    ) {
        central.stopScan()
        self.peripheral = peripheral
        peripheral.delegate = self
        central.connect(peripheral)
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusContinuation.yield(.gekoppelt(geraetename: peripheral.name ?? "Laser"))
        peripheral.discoverServices([Self.platzhalterServiceUUID])
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        statusContinuation.yield(.fehler(error?.localizedDescription ?? "Verbindung fehlgeschlagen"))
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        statusContinuation.yield(.getrennt)
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let service = peripheral.services?.first else { return }
        peripheral.discoverCharacteristics([Self.platzhalterMesswertCharacteristicUUID], for: service)
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil, let characteristic = service.characteristics?.first else { return }
        peripheral.setNotifyValue(true, for: characteristic)
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value,
              let meter = LeicaDistoStatusReducer.meterAusRohwert(data) else { return }
        massContinuation.yield(meter)
    }
}

// MARK: - LeicaDistoStatusReducer (rein, getestet)
// Trennt die TESTBARE Logik (Zustandsüberführung, Payload-Parsing) von der CoreBluetooth-
// Delegate-Verdrahtung (ohne echtes/gemocktes Gerät nicht sinnvoll unit-testbar).
enum LeicaDistoStatusReducer {
    enum ManagerAktion: Equatable {
        case weiterScannen
        case melden(LaserVerbindungsStatus)
    }

    static func fuerManagerState(_ state: CBManagerState) -> ManagerAktion {
        switch state {
        case .poweredOn: return .weiterScannen
        case .poweredOff: return .melden(.fehler("Bluetooth ist ausgeschaltet"))
        case .unauthorized: return .melden(.fehler("Bluetooth-Zugriff nicht erlaubt"))
        case .unsupported: return .melden(.fehler("Bluetooth wird nicht unterstützt"))
        default: return .melden(.sucht)
        }
    }

    /// Roh-Payload → Meter. PLATZHALTER (siehe Typ-Kommentar): interpretiert einen Little-
    /// Endian Float32 (Meter) — plausibel, aber NICHT verifiziert, bis der echte Leica-Payload
    /// portiert ist.
    static func meterAusRohwert(_ data: Data) -> Double? {
        guard data.count >= 4 else { return nil }
        let bits = data.prefix(4).reversed().reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        let wert = Double(Float(bitPattern: bits))
        guard wert.isFinite, wert >= 0 else { return nil }
        return wert
    }
}
