import UIKit

enum GrundrissPDFFehler: Error, LocalizedError {
    case keineWaende

    var errorDescription: String? {
        "Keine Wände im Scan gefunden — Grundriss kann nicht gezeichnet werden."
    }
}

/// Reine Draufsicht-Zeichnung aus RoomPlan-Geometrie — Wände als Linien,
/// Öffnungen als blaue Linien, Wandlängen als Beschriftung. Kein CAD-Ersatz,
/// ein schneller Referenz-Grundriss fürs Kundengespräch oder die Akte.
enum GrundrissPDFRenderer {
    static func erstellePDF(geometrie: RaumGeometrie, titel: String) throws -> URL {
        guard !geometrie.waende.isEmpty else { throw GrundrissPDFFehler.keineWaende }

        let alleXPunkte = geometrie.waende.flatMap { [$0.start.x, $0.ende.x] }
        let alleYPunkte = geometrie.waende.flatMap { [$0.start.y, $0.ende.y] }
        guard let minX = alleXPunkte.min(), let maxX = alleXPunkte.max(),
              let minY = alleYPunkte.min(), let maxY = alleYPunkte.max() else {
            throw GrundrissPDFFehler.keineWaende
        }

        let rand: CGFloat = 60
        let kopfHoehe: CGFloat = 40
        let seitenGroesse = CGSize(width: 842, height: 595) // A4 quer, Punkte
        let verfuegbareBreite = seitenGroesse.width - 2 * rand
        let verfuegbareHoehe = seitenGroesse.height - 2 * rand - kopfHoehe
        let raumBreite = max(maxX - minX, 0.1)
        let raumHoehe = max(maxY - minY, 0.1)
        let massstab = min(verfuegbareBreite / raumBreite, verfuegbareHoehe / raumHoehe)

        func projiziere(_ punkt: CGPoint) -> CGPoint {
            CGPoint(
                x: rand + (punkt.x - minX) * massstab,
                y: rand + kopfHoehe + (punkt.y - minY) * massstab
            )
        }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: seitenGroesse))
        let zielURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")

        try renderer.writePDF(to: zielURL) { context in
            context.beginPage()
            let cgContext = context.cgContext

            let titelAttribute: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 16)]
            (titel as NSString).draw(at: CGPoint(x: rand, y: 16), withAttributes: titelAttribute)

            let hinweisAttribute: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.gray
            ]
            ("RoomPlan-Grundriss — Referenzmaße, kein Ersatz für Laser-Aufmaß" as NSString)
                .draw(at: CGPoint(x: rand, y: 36), withAttributes: hinweisAttribute)

            cgContext.setLineWidth(3)
            cgContext.setStrokeColor(UIColor.black.cgColor)
            for wand in geometrie.waende {
                let start = projiziere(wand.start)
                let ende = projiziere(wand.ende)
                cgContext.move(to: start)
                cgContext.addLine(to: ende)
                cgContext.strokePath()

                let mitte = CGPoint(x: (start.x + ende.x) / 2, y: (start.y + ende.y) / 2)
                let beschriftung = String(format: "%.2f m", wand.laengeMeter)
                let attribute: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9),
                    .foregroundColor: UIColor.darkGray
                ]
                (beschriftung as NSString).draw(at: mitte, withAttributes: attribute)
            }

            cgContext.setLineWidth(2)
            cgContext.setStrokeColor(UIColor.systemBlue.cgColor)
            for oeffnung in geometrie.oeffnungen {
                cgContext.move(to: projiziere(oeffnung.start))
                cgContext.addLine(to: projiziere(oeffnung.ende))
                cgContext.strokePath()
            }
        }

        return zielURL
    }
}
