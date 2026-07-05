import UIKit

enum AbnahmeprotokollPDFFehler: Error, LocalizedError {
    case keineEintraege

    var errorDescription: String? {
        "Kein Mangel erfasst — Protokoll kann nicht erzeugt werden."
    }
}

/// Das Abnahmeprotokoll als übergabefähiges PDF — nummerierte Mängel mit
/// Erfassungszeit und Foto. Gleiches `UIGraphicsPDFRenderer`-Muster wie der
/// Grundriss-Export. A4 hoch, neue Seite, wenn der Platz ausgeht.
enum AbnahmeprotokollPDFRenderer {
    static func erstellePDF(
        projektTitel: String,
        projectNumber: String,
        eintraege: [MangelEintrag],
        bildURL: (MangelEintrag) -> URL?
    ) throws -> URL {
        guard !eintraege.isEmpty else { throw AbnahmeprotokollPDFFehler.keineEintraege }

        let seitenGroesse = CGSize(width: 595, height: 842) // A4 hoch, Punkte
        let rand: CGFloat = 50
        let inhaltsBreite = seitenGroesse.width - 2 * rand
        let fotoGroesse: CGFloat = 110

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: seitenGroesse))
        let zielURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")

        let titelAttribute: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 18)]
        let metaAttribute: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]
        let nummerAttribute: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 12)]
        let textAttribute: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11)]

        try renderer.writePDF(to: zielURL) { context in
            var y: CGFloat = 0

            func neueSeite() {
                context.beginPage()
                ("Abnahmeprotokoll — \(projektTitel)" as NSString)
                    .draw(at: CGPoint(x: rand, y: 40), withAttributes: titelAttribute)
                let meta = "Projekt \(projectNumber) · erstellt \(Date().formatted(date: .long, time: .shortened)) · \(eintraege.count) Mängel"
                (meta as NSString).draw(at: CGPoint(x: rand, y: 64), withAttributes: metaAttribute)
                y = 90
            }

            neueSeite()

            for (index, eintrag) in eintraege.enumerated() {
                let text = eintrag.text as NSString
                let textRahmen = text.boundingRect(
                    with: CGSize(width: inhaltsBreite - 30, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin],
                    attributes: textAttribute,
                    context: nil
                )
                let hatFoto = bildURL(eintrag) != nil
                let blockHoehe = max(textRahmen.height + 30, hatFoto ? fotoGroesse + 30 : 0) + 14

                if y + blockHoehe > seitenGroesse.height - rand {
                    neueSeite()
                }

                ("Mangel \(index + 1)" as NSString)
                    .draw(at: CGPoint(x: rand, y: y), withAttributes: nummerAttribute)
                (eintrag.erfasstAm.formatted(date: .abbreviated, time: .shortened) as NSString)
                    .draw(at: CGPoint(x: rand + 80, y: y + 1), withAttributes: metaAttribute)

                var textX = rand
                if let url = bildURL(eintrag), let bild = UIImage(contentsOfFile: url.path) {
                    let seitenverhaeltnis = bild.size.width / max(bild.size.height, 1)
                    let fotoRechteck = CGRect(x: rand, y: y + 18, width: fotoGroesse * seitenverhaeltnis, height: fotoGroesse)
                    bild.draw(in: fotoRechteck)
                    textX = rand + fotoRechteck.width + 12
                }

                text.draw(
                    in: CGRect(x: textX, y: y + 18, width: seitenGroesse.width - rand - textX, height: textRahmen.height + 4),
                    withAttributes: textAttribute
                )

                y += blockHoehe
            }
        }

        return zielURL
    }
}
