import CryptoKit
import Foundation
import PDFKit
import UIKit

/// Ein unterzeichneter Vertrag im lokalen Signatur-Register. `sha256` ist
/// das Integritaets-Siegel des fertigen, unterschriebenen PDFs — wer die
/// Datei spaeter aendert, aendert den Fingerabdruck. Ehrliche Einordnung:
/// Das ist eine EINFACHE elektronische Signatur mit Beweiskette, KEINE
/// qualifizierte Signatur nach eIDAS — fuer formfreie Werkvertraege
/// gebraeuchlich, rechtliche Bewertung bleibt Sache von Menschen.
struct SignierterVertrag: Identifiable, Codable, Hashable {
    let id: UUID
    let dateiname: String
    let vertragsName: String
    let projectNumber: String
    let projectTitel: String
    let unterzeichner: String
    let unterschriebenAm: Date
    let sha256: String

    init(id: UUID = UUID(), dateiname: String, vertragsName: String, projectNumber: String, projectTitel: String, unterzeichner: String, unterschriebenAm: Date = Date(), sha256: String) {
        self.id = id
        self.dateiname = dateiname
        self.vertragsName = vertragsName
        self.projectNumber = projectNumber
        self.projectTitel = projectTitel
        self.unterzeichner = unterzeichner
        self.unterschriebenAm = unterschriebenAm
        self.sha256 = sha256
    }
}

enum VertragsFehler: Error, LocalizedError {
    case pdfNichtLesbar
    case siegelnFehlgeschlagen(String)

    var errorDescription: String? {
        switch self {
        case .pdfNichtLesbar: return "Das Vertrags-PDF konnte nicht gelesen werden."
        case .siegelnFehlgeschlagen(let text): return "Signieren fehlgeschlagen: \(text)"
        }
    }
}

/// Baut das versiegelte PDF: Original + angehaengte Signatur-Seite
/// (Unterschrift, Name, Zeitpunkt, Projekt, Fingerabdruck des Originals).
/// Danach wird der Fingerabdruck des FERTIGEN Dokuments berechnet und im
/// Register abgelegt — die zweistufige Kette macht Manipulation sichtbar.
enum VertragsSiegel {
    static func versiegele(
        originalPDF: URL,
        unterschrift: UIImage,
        unterzeichner: String,
        projekt: Project
    ) throws -> (daten: Data, sha256: String) {
        guard let dokument = PDFDocument(url: originalPDF),
              let originalDaten = try? Data(contentsOf: originalPDF) else {
            throw VertragsFehler.pdfNichtLesbar
        }
        let originalHash = SHA256.hash(data: originalDaten).map { String(format: "%02x", $0) }.joined()

        let seitenGroesse = CGSize(width: 595, height: 842)
        let renderer = UIGraphicsImageRenderer(size: seitenGroesse)
        let siegelBild = renderer.image { kontext in
            UIColor.white.setFill()
            kontext.fill(CGRect(origin: .zero, size: seitenGroesse))

            let titel: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 16)]
            let normal: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11)]
            let klein: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.gray]

            ("Signatur-Seite" as NSString).draw(at: CGPoint(x: 50, y: 50), withAttributes: titel)
            let zeilen = [
                "Dokument: \(originalPDF.deletingPathExtension().lastPathComponent)",
                "Projekt: \(projekt.title) (\(projekt.projectNumber))",
                "Unterzeichnet von: \(unterzeichner)",
                "Zeitpunkt: \(Date().formatted(date: .long, time: .standard))"
            ]
            for (i, zeile) in zeilen.enumerated() {
                (zeile as NSString).draw(at: CGPoint(x: 50, y: 90 + CGFloat(i) * 20), withAttributes: normal)
            }

            let maxBreite: CGFloat = 300
            let verhaeltnis = unterschrift.size.height / max(unterschrift.size.width, 1)
            unterschrift.draw(in: CGRect(x: 50, y: 190, width: maxBreite, height: maxBreite * verhaeltnis))
            ("Unterschrift" as NSString).draw(at: CGPoint(x: 50, y: 190 + maxBreite * verhaeltnis + 4), withAttributes: klein)

            ("Integritaets-Siegel (SHA-256 des Originaldokuments):" as NSString)
                .draw(at: CGPoint(x: 50, y: 560), withAttributes: normal)
            (originalHash as NSString).draw(
                in: CGRect(x: 50, y: 580, width: 495, height: 40), withAttributes: klein)
            ("Einfache elektronische Signatur mit Integritaets-Siegel - erstellt mit mykilOS mobile." as NSString)
                .draw(at: CGPoint(x: 50, y: 780), withAttributes: klein)
        }

        guard let siegelSeite = PDFPage(image: siegelBild) else {
            throw VertragsFehler.siegelnFehlgeschlagen("Signatur-Seite nicht erzeugbar.")
        }
        dokument.insert(siegelSeite, at: dokument.pageCount)

        guard let fertig = dokument.dataRepresentation() else {
            throw VertragsFehler.siegelnFehlgeschlagen("PDF nicht schreibbar.")
        }
        let fertigHash = SHA256.hash(data: fertig).map { String(format: "%02x", $0) }.joined()
        return (fertig, fertigHash)
    }
}

/// Register der unterzeichneten Vertraege — gleiches Zwei-Datei-Muster wie
/// FeldFotoStore. Signierte Vertraege sind NICHT loeschbar (ein Register,
/// das man leeren kann, ist keine Beweiskette).
@Observable
final class VertragsRegister {
    private(set) var vertraege: [SignierterVertrag] = []

    private let manifestURL: URL
    private let ordnerURL: URL

    init(documentsURL: URL? = nil) {
        let documents = documentsURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.manifestURL = documents.appendingPathComponent("vertraege.json")
        self.ordnerURL = documents.appendingPathComponent("Vertraege", isDirectory: true)
        try? FileManager.default.createDirectory(at: ordnerURL, withIntermediateDirectories: true)
        if let data = try? Data(contentsOf: manifestURL),
           let geladen = try? JSONDecoder().decode([SignierterVertrag].self, from: data) {
            vertraege = geladen
        }
    }

    func dateiURL(fuer vertrag: SignierterVertrag) -> URL {
        ordnerURL.appendingPathComponent(vertrag.dateiname)
    }

    @discardableResult
    func ablegen(daten: Data, vertragsName: String, projekt: Project, unterzeichner: String, sha256: String) throws -> SignierterVertrag {
        let dateiname = "\(UUID().uuidString).pdf"
        do {
            try daten.write(to: ordnerURL.appendingPathComponent(dateiname), options: .atomic)
        } catch {
            throw VertragsFehler.siegelnFehlgeschlagen(error.localizedDescription)
        }
        let eintrag = SignierterVertrag(
            dateiname: dateiname, vertragsName: vertragsName,
            projectNumber: projekt.projectNumber, projectTitel: projekt.title,
            unterzeichner: unterzeichner, sha256: sha256
        )
        var next = vertraege
        next.append(eintrag)
        do {
            let manifest = try JSONEncoder().encode(next)
            try manifest.write(to: manifestURL, options: .atomic)
        } catch {
            try? FileManager.default.removeItem(at: ordnerURL.appendingPathComponent(dateiname))
            throw VertragsFehler.siegelnFehlgeschlagen(error.localizedDescription)
        }
        vertraege = next
        return eintrag
    }
}
