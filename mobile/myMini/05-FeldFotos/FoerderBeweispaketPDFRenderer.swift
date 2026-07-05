import UIKit

enum FoerderBeweispaketPDFFehler: Error, LocalizedError {
    case keineFotos

    var errorDescription: String? {
        "Keine förderrelevanten Fotos für dieses Projekt — Bericht kann nicht erzeugt werden."
    }
}

/// Das Förderungs-Beweispaket (#52) als datierter PDF-Bericht — eine Seite
/// je Foto, chronologisch, mit Aufnahmezeit (aus der EXIF-Beweiskette) und
/// Standort, falls erfasst. Der zuvor gebaute Rohdaten-Share (nur die
/// Bilddateien) bleibt daneben bestehen — das hier ist die einreichfertige
/// Fassung für KfW/BAFA-Unterlagen.
enum FoerderBeweispaketPDFRenderer {
    static func erstellePDF(
        projektTitel: String,
        projectNumber: String,
        fotos: [FeldFoto],
        bildURL: (FeldFoto) -> URL
    ) throws -> URL {
        guard !fotos.isEmpty else { throw FoerderBeweispaketPDFFehler.keineFotos }

        let seitenGroesse = CGSize(width: 595, height: 842) // A4 hoch, Punkte
        let rand: CGFloat = 50

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: seitenGroesse))
        let zielURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")

        let titelAttribute: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 18)]
        let untertitelAttribute: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
        let metaAttribute: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]

        try renderer.writePDF(to: zielURL) { context in
            // Deckblatt
            context.beginPage()
            ("Förderungs-Beweispaket" as NSString)
                .draw(at: CGPoint(x: rand, y: 60), withAttributes: titelAttribute)
            ("\(projektTitel) · Projekt \(projectNumber)" as NSString)
                .draw(at: CGPoint(x: rand, y: 88), withAttributes: untertitelAttribute)
            let deckMeta = "\(fotos.count) datierte Belege · erstellt \(Date().formatted(date: .long, time: .shortened))\nZeitstempel aus der Aufnahme (EXIF-Beweiskette), chronologisch sortiert."
            (deckMeta as NSString).draw(
                in: CGRect(x: rand, y: 112, width: seitenGroesse.width - 2 * rand, height: 60),
                withAttributes: metaAttribute
            )

            // Eine Seite je Foto, chronologisch
            for (index, foto) in fotos.sorted(by: { $0.aufgenommenAm < $1.aufgenommenAm }).enumerated() {
                context.beginPage()

                ("Beleg \(index + 1) von \(fotos.count) — \(projektTitel)" as NSString)
                    .draw(at: CGPoint(x: rand, y: 40), withAttributes: untertitelAttribute)

                var meta = "\(foto.kanonZiel.titel) · aufgenommen \(foto.aufgenommenAm.formatted(date: .long, time: .shortened))"
                if let breite = foto.breitengrad, let laenge = foto.laengengrad {
                    meta += String(format: " · Standort %.5f, %.5f", breite, laenge)
                }
                (meta as NSString).draw(at: CGPoint(x: rand, y: 62), withAttributes: metaAttribute)

                if let bild = UIImage(contentsOfFile: bildURL(foto).path) {
                    let verfuegbar = CGRect(
                        x: rand, y: 90,
                        width: seitenGroesse.width - 2 * rand,
                        height: seitenGroesse.height - 90 - rand
                    )
                    let seitenverhaeltnis = bild.size.width / max(bild.size.height, 1)
                    var zielRechteck = verfuegbar
                    if verfuegbar.width / seitenverhaeltnis <= verfuegbar.height {
                        zielRechteck.size.height = verfuegbar.width / seitenverhaeltnis
                    } else {
                        zielRechteck.size.width = verfuegbar.height * seitenverhaeltnis
                    }
                    bild.draw(in: zielRechteck)
                }
            }
        }

        return zielURL
    }
}
