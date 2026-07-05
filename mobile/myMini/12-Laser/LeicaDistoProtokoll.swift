import CoreBluetooth
import Foundation

/// Leica-DISTO-BLE-Protokoll — die EINE dokumentierte Ausnahme von der
/// "keine geratenen GATT-IDs"-Regel: Leica veroeffentlicht sein
/// DISTO-BLE-Kit, die IDs sind aus zwei unabhaengigen Quellen bestaetigt
/// (d2relay-Reverse-Notes fuer die D2-Generation, B4X-Forum fuer die
/// X-Generation mit BASIC_MEASUREMENT). Messwert = IEEE754 Float32,
/// little-endian, in Metern (Geraet auf Meter stellen!).
///
/// `istProtokollVerifiziert` im Adapter bleibt trotzdem false, bis der
/// erste echte Messwert im Studio angekommen ist — dokumentiert ist nicht
/// dasselbe wie live gesehen.
enum LeicaDistoProtokoll {
    static let service = CBUUID(string: "3AB10100-F831-4395-B29D-570977D5BF94")

    /// D2-Generation: Distanz-Characteristic (Float32 LE, Meter, notify).
    static let distanzD2 = CBUUID(string: "3AB10101-F831-4395-B29D-570977D5BF94")

    /// X-/neuere Generation: BASIC_MEASUREMENT (erste 4 Bytes = Float32 LE).
    static let basicMeasurement = CBUUID(string: "3AB1010D-F831-4395-B29D-570977D5BF94")

    static let messCharakteristiken: Set<CBUUID> = [distanzD2, basicMeasurement]

    /// Erste 4 Bytes little-endian als Float32 (Meter) -> Millimeter.
    /// Bewusst mit Plausibilitaets-Fenster: alles ausserhalb 2 cm - 500 m
    /// wird verworfen statt als "Messwert" angezeigt.
    static func distanzInMM(aus daten: Data) -> Int? {
        guard daten.count >= 4 else { return nil }
        var bits: UInt32 = 0
        for (index, byte) in daten.prefix(4).enumerated() {
            bits |= UInt32(byte) << (8 * index)
        }
        let meter = Float(bitPattern: bits)
        guard meter.isFinite, meter > 0.02, meter < 500 else { return nil }
        return Int((meter * 1000).rounded())
    }
}
