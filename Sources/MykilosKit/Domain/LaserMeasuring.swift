import Foundation

// MARK: - LaserMeasuring (Aufmaß-Widget-Plan, docs/handoffs/AUFMASS_WIDGET_PLAN.md)
// Schaltschrank-Adapter: Laser (Quelle) → Maßlinie (Ziel) ist eine steckbare Route. Ein neuer
// Laser-Typ = ein neuer LaserPort-Adapter (z. B. LeicaDistoBluetoothAdapter), kein Umbau der
// Aufmaß-Canvas. Foundation-only (MykilosKit-Regel: kein SwiftUI, kein GRDB, kein CoreBluetooth
// — das Bluetooth-Konkrete lebt im Adapter in MykilosServices).
public protocol LaserMeasuring: Sendable {
    /// Verbindungszustand, live beobachtbar (Renderstates: sucht/gekoppelt/getrennt/Fehler).
    var status: AsyncStream<LaserVerbindungsStatus> { get }
    /// Jeder empfangene Messwert in Metern, live beobachtbar.
    var letztesMass: AsyncStream<Double> { get }
    func verbinde() async throws
    func trenne() async
}

public enum LaserVerbindungsStatus: Equatable, Sendable {
    case getrennt
    case sucht
    case gekoppelt(geraetename: String)
    case fehler(String)
}
