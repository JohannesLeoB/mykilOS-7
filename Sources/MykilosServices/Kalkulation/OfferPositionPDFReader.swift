import Foundation
import PDFKit
import MykilosKalkulationsCore

// MARK: - OfferPositionPDFReader (PDFKit → Text-Adapter für PDF-Positions v1)
//
// Der dünne Adapter zwischen PDFKit und dem reinen Extraktor-Kern
// (`OfferPositionExtractor`, Foundation-only in MykilosKalkulationsCore). Liest
// den Text jeder Seite via `PDFPage.string` und reicht ihn seitenweise durch
// Pass 1 (Blocking) + Pass 2 (Feld-Extraktion). Read-only, kein Schreiben.
//
// ⚠️ Die Blocking-Qualität (Pass 1) hängt an der realen PDF-Textstruktur und ist
// noch gegen echte EK-PDFs nachzujustieren (siehe Extraktor-Doku). Pass 2 ist an
// 815 echten Blöcken validiert (97,7 %).
public enum OfferPositionPDFReader {

    public typealias Position = OfferPositionExtractor.ExtractedPosition

    /// Eine erkannte Position mit ihrer Quellseite (1-basiert) für den Rückverweis.
    public struct PagedPosition: Sendable {
        public let pageNumber: Int
        public let position: Position
        public init(pageNumber: Int, position: Position) {
            self.pageNumber = pageNumber
            self.position = position
        }
    }

    /// Positionen aus einer lokalen PDF-Datei (mit Seitenzuordnung).
    public static func positions(fromPDFAt url: URL) -> [PagedPosition] {
        guard let doc = PDFDocument(url: url) else { return [] }
        return positions(from: doc)
    }

    /// Positionen aus PDF-Bytes (z. B. read-only aus Drive geladen).
    public static func positions(fromPDFData data: Data) -> [PagedPosition] {
        guard let doc = PDFDocument(data: data) else { return [] }
        return positions(from: doc)
    }

    static func positions(from doc: PDFDocument) -> [PagedPosition] {
        var result: [PagedPosition] = []
        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i), let text = page.string else { continue }
            for p in OfferPositionExtractor.extractPositions(fromPageText: text) {
                result.append(PagedPosition(pageNumber: i + 1, position: p))
            }
        }
        return result
    }
}
