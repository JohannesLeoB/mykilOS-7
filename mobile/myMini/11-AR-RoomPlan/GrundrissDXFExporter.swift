import Foundation
import CoreGraphics

enum GrundrissDXFFehler: Error, LocalizedError {
    case schreibenFehlgeschlagen(String)

    var errorDescription: String? {
        switch self {
        case .schreibenFehlgeschlagen(let text): return "DXF-Export fehlgeschlagen: \(text)"
        }
    }
}

/// Minimaler, handgeschriebener ASCII-DXF-Export — nur `LINE`- und
/// `TEXT`-Entities in einer reinen `ENTITIES`-Sektion (kein HEADER/TABLES/
/// BLOCKS). Das ist laut DXF-Spezifikation ein gültiges Minimaldokument,
/// aber der tatsächliche Import in VectorWorks wurde von hier aus nicht
/// getestet — falls VectorWorks eine Layer-Tabelle o. Ä. verlangt, wäre
/// das ein kleiner Nachbau, kein Konzeptfehler. Einheiten sind Meter,
/// direkt aus RoomPlan übernommen — VectorWorks fragt beim Import nach
/// der Einheit, dort "Meter" wählen.
enum GrundrissDXFExporter {
    static func erstelleDXF(geometrie: RaumGeometrie) throws -> URL {
        var zeilen: [String] = ["0", "SECTION", "2", "ENTITIES"]

        for wand in geometrie.waende {
            zeilen.append(contentsOf: linie(von: wand.start, bis: wand.ende, layer: "Waende"))
            let mitte = CGPoint(x: (wand.start.x + wand.ende.x) / 2, y: (wand.start.y + wand.ende.y) / 2)
            zeilen.append(contentsOf: text(an: mitte, inhalt: String(format: "%.2f m", wand.laengeMeter), layer: "Masse"))
        }

        for oeffnung in geometrie.oeffnungen {
            zeilen.append(contentsOf: linie(von: oeffnung.start, bis: oeffnung.ende, layer: "Oeffnungen"))
        }

        zeilen.append(contentsOf: ["0", "ENDSEC", "0", "EOF"])

        let inhalt = zeilen.joined(separator: "\n")
        let zielURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).dxf")
        do {
            try inhalt.write(to: zielURL, atomically: true, encoding: .ascii)
        } catch {
            throw GrundrissDXFFehler.schreibenFehlgeschlagen(error.localizedDescription)
        }
        return zielURL
    }

    private static func linie(von start: CGPoint, bis ende: CGPoint, layer: String) -> [String] {
        [
            "0", "LINE",
            "8", layer,
            "10", format(start.x), "20", format(start.y), "30", "0",
            "11", format(ende.x), "21", format(ende.y), "31", "0"
        ]
    }

    private static func text(an punkt: CGPoint, inhalt: String, layer: String) -> [String] {
        [
            "0", "TEXT",
            "8", layer,
            "10", format(punkt.x), "20", format(punkt.y), "30", "0",
            "40", "0.1",
            "1", inhalt
        ]
    }

    private static func format(_ wert: CGFloat) -> String {
        String(format: "%.4f", wert)
    }
}
