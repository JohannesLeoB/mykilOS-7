import CoreBluetooth
import Foundation

/// Wie sicher ist ein empfangener Messwert?
enum LaserVertrauen {
    /// Dokumentiertes, verifiziertes Protokoll (Leica).
    case verifiziert
    /// Universeller Empfaenger hat einen plausiblen Wert rausgelesen - kann
    /// stimmen, ist aber nicht herstellerbestaetigt. Im Zweifel am Geraet
    /// gegenlesen.
    case generisch

    var label: String {
        switch self {
        case .verifiziert: return "verifiziert"
        case .generisch: return "generisch - bitte pruefen"
        }
    }
}

struct LaserMesswert {
    let millimeter: Int
    let quelle: String
    let vertrauen: LaserVertrauen
}

/// **Universeller Laser-Empfaenger** - der "Allesfresser". Statt 30 geratener
/// Hersteller-Protokolle hoert der Scanner auf JEDEM verbundenen Geraet alle
/// Mess-Kanaele ab und schickt jede Notification durch diese Dekoder-Kaskade.
/// Der erste, der einen plausiblen Wert findet, gewinnt.
///
/// Ehrlichkeit bleibt hart: Leica ist `verifiziert`, alles andere `generisch`
/// (best effort, sichtbar als solches). Kein stiller Anspruch auf mm-Genauigkeit
/// bei einem Geraet, dessen Protokoll wir nie gesehen haben.
enum LaserMesswertDecoder {
    /// Nordic UART Service (RX) - viele generische BLE-Module streamen darueber
    /// ihren Messwert als ASCII-Text.
    static let nordicUARTService = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    static let nordicUARTTx = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")

    /// Plausibles Fenster fuer eine Raum-/Bau-Distanz: 2 mm bis 500 m.
    private static let minMM = 2
    private static let maxMM = 500_000

    static func dekodiere(charakteristik: CBUUID, daten: Data) -> LaserMesswert? {
        // 1. Leica - verifiziertes Protokoll, hoechste Prioritaet.
        if LeicaDistoProtokoll.messCharakteristiken.contains(charakteristik),
           let mm = LeicaDistoProtokoll.distanzInMM(aus: daten) {
            return LaserMesswert(millimeter: mm, quelle: "Leica DISTO", vertrauen: .verifiziert)
        }
        // 2. ASCII-Text mit Zahl + Einheit (NUS-Streams, generische Module) -
        //    ein Einheiten-Kuerzel ist ein starkes Signal, dass es ein Messwert ist.
        if let mm = ausText(daten) {
            return LaserMesswert(millimeter: mm, quelle: "BLE-Laser (Text)", vertrauen: .generisch)
        }
        // 3. Roher Float32 (little/big endian) im plausiblen Meter-Fenster.
        if let mm = ausFloat(daten) {
            return LaserMesswert(millimeter: mm, quelle: "BLE-Laser (Float)", vertrauen: .generisch)
        }
        return nil
    }

    private static func plausibel(_ mm: Int) -> Bool { mm >= minMM && mm <= maxMM }

    private static func ausText(_ daten: Data) -> Int? {
        guard let roh = String(data: daten, encoding: .utf8) ?? String(data: daten, encoding: .ascii) else { return nil }
        let text = roh.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !text.isEmpty else { return nil }
        guard let zahl = ersteZahl(text) else { return nil }

        let mm: Double
        if text.contains("mm") { mm = zahl }
        else if text.contains("cm") { mm = zahl * 10 }
        else if text.contains("ft") || text.contains("'") { mm = zahl * 304.8 }
        else if text.contains("in") || text.contains("\"") { mm = zahl * 25.4 }
        else if text.contains("m") { mm = zahl * 1000 }
        else { return nil } // ohne Einheit lieber nichts behaupten
        let gerundet = Int(mm.rounded())
        return plausibel(gerundet) ? gerundet : nil
    }

    private static func ersteZahl(_ text: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: "[-+]?[0-9]*[.,]?[0-9]+") else { return nil }
        let bereich = NSRange(text.startIndex..., in: text)
        guard let treffer = regex.firstMatch(in: text, range: bereich),
              let r = Range(treffer.range, in: text) else { return nil }
        return Double(text[r].replacingOccurrences(of: ",", with: "."))
    }

    private static func ausFloat(_ daten: Data) -> Int? {
        guard daten.count >= 4 else { return nil }
        let bytes = [UInt8](daten.prefix(4))
        for reihenfolge in [bytes, bytes.reversed()] {
            var bits: UInt32 = 0
            for (i, b) in reihenfolge.enumerated() { bits |= UInt32(b) << (8 * i) }
            let meter = Float(bitPattern: bits)
            guard meter.isFinite else { continue }
            let mm = Int((meter * 1000).rounded())
            if plausibel(mm) { return mm }
        }
        return nil
    }
}
