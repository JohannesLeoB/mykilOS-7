import CoreImage
import UIKit

/// Beleuchtungs-Check: reine on-device Helligkeitsanalyse eines Fotos
/// (CoreImage `CIAreaAverage`, kein Netzwerk, kein API-Key). Bewusst
/// KEIN Sonnenstand/Azimut — Sonnenposition von Hand nachzurechnen ist
/// fehleranfällig und ohne geprüfte Astronomie-Bibliothek nicht verlässlich
/// zu verifizieren. Dieser Baustein bleibt ehrlich einfach: er sagt nur,
/// wie hell das Bild gerade ist, nicht wo die Sonne steht.
enum Beleuchtungsniveau: String {
    case hell = "Hell"
    case mittel = "Mittel"
    case dunkel = "Dunkel"

    var empfehlung: String {
        switch self {
        case .hell:
            return "Gutes Licht für Fotos und Detailarbeit."
        case .mittel:
            return "Nutzbar, aber für Foto-Dokumentation ggf. zusätzliches Licht erwägen."
        case .dunkel:
            return "Wenig Licht — für Foto-Dokumentation oder Feinarbeit zusätzliche Beleuchtung empfohlen."
        }
    }

    var systemImage: String {
        switch self {
        case .hell: return "sun.max.fill"
        case .mittel: return "cloud.sun.fill"
        case .dunkel: return "moon.fill"
        }
    }
}

enum HelligkeitsAnalyse {
    /// Durchschnittshelligkeit eines Fotos, 0 (schwarz) bis 1 (weiß) —
    /// via `CIAreaAverage`-Filter über das gesamte Bild.
    static func analysiere(_ bild: UIImage) -> Beleuchtungsniveau {
        guard let ciImage = CIImage(image: bild) else { return .mittel }
        let context = CIContext()
        let extent = ciImage.extent

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: ciImage,
            kCIInputExtentKey: CIVector(cgRect: extent)
        ]), let outputImage = filter.outputImage else {
            return .mittel
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

        let helligkeit = (Double(bitmap[0]) + Double(bitmap[1]) + Double(bitmap[2])) / 3.0 / 255.0

        switch helligkeit {
        case ..<0.3: return .dunkel
        case ..<0.65: return .mittel
        default: return .hell
        }
    }
}
