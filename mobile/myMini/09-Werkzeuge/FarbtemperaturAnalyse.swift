import CoreImage
import UIKit

/// Farbtemperatur-Check: grobe on-device Kategorisierung (CoreImage
/// `CIAreaAverage`, kein Netzwerk, kein API-Key). Bewusst KEINE kalibrierte
/// Kelvin-Messung — iOS hat keinen echten Farbtemperatur-Sensor, ein
/// `UIImagePickerController`-Foto liefert keinen Zugriff auf die
/// Weißabgleich-Gains der Kamera-Session. Diese Kategorie ist ein grober
/// Anhaltspunkt aus dem Rot/Blau-Verhältnis des Bildes, kein Fakt — gleiche
/// Ehrlichkeitshaltung wie beim Beleuchtungs-Check.
enum Farbtemperaturkategorie: String {
    case warm = "Warm"
    case neutral = "Neutral"
    case kuehl = "Kühl"

    var empfehlung: String {
        switch self {
        case .warm:
            return "Warmweißes Licht — echte Farben wirken wärmer als sie sind, für Farbabgleich ungeeignet."
        case .neutral:
            return "Ausgewogenes Licht — für einen groben Farbeindruck brauchbar."
        case .kuehl:
            return "Kühles, bläuliches Licht — Farbeindruck tendenziell Richtung Blau verschoben."
        }
    }

    var systemImage: String {
        switch self {
        case .warm: return "flame.fill"
        case .neutral: return "circle.lefthalf.filled"
        case .kuehl: return "snowflake"
        }
    }
}

enum FarbtemperaturAnalyse {
    /// Rot-zu-Blau-Verhältnis des Fotos, gebündelt in drei grobe Kategorien.
    /// Kein Kelvin-Wert — reine Kategorie, wie hier im Dateikopf begründet.
    static func analysiere(_ bild: UIImage) -> Farbtemperaturkategorie {
        guard let ciImage = CIImage(image: bild) else { return .neutral }
        let context = CIContext()
        let extent = ciImage.extent

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: ciImage,
            kCIInputExtentKey: CIVector(cgRect: extent)
        ]), let outputImage = filter.outputImage else {
            return .neutral
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        let rot = Double(bitmap[0])
        let blau = Double(bitmap[2])
        let verhaeltnis = rot / max(blau, 1)

        switch verhaeltnis {
        case ..<0.9: return .kuehl
        case 1.15...: return .warm
        default: return .neutral
        }
    }
}
