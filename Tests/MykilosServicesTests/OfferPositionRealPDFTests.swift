import XCTest
import PDFKit
@testable import MykilosServices
@testable import MykilosKalkulationsCore

// MARK: - OfferPositionRealPDFTests (Pass-1-Sondierung an echter PDF, NUR lokal)
//
// Läuft nur, wenn MYKILOS_ALLE_ANGEBOTE_PDF auf die echte (gemergte) Angebots-PDF
// zeigt — sonst XCTSkip. Misst, ob das Blocking (Pass 1) an realer PDFKit-Textstruktur
// greift. Kein Assert (Sondierung) — druckt Diagnose. Die EK-PDF bleibt lokal.
//
// Kanonische Quelle: Vault MYK-KALK-KORPUS-01 (bit-genau verifizierte Sicherung).
//   MYKILOS_ALLE_ANGEBOTE_PDF="$HOME/mykilOS-App-Backups/kalk-korpus-groundtruth-01/pdf/ALLEANGEBOTE.pdf" \
//     swift test --filter OfferPositionRealPDFTests
final class OfferPositionRealPDFTests: XCTestCase {

    func testSondiereBlockingAnEchterPDF() throws {
        guard let path = ProcessInfo.processInfo.environment["MYKILOS_ALLE_ANGEBOTE_PDF"] else {
            throw XCTSkip("MYKILOS_ALLE_ANGEBOTE_PDF nicht gesetzt — reale PDF-Sondierung übersprungen.")
        }
        guard let doc = PDFDocument(url: URL(fileURLWithPath: path)) else {
            return XCTFail("PDF nicht ladbar: \(path)")
        }

        var pagesWithText = 0, pagesWithNewline = 0
        var totalChars = 0, totalBlocks = 0
        var totalPositions = 0
        var conf: [OfferPositionExtractor.Confidence: Int] = [:]
        var samples: [(page: Int, title: String, net: String, list: String, c: String)] = []
        var blocksPerPage: [Int] = []

        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i), let text = page.string, text.isEmpty == false else { continue }
            pagesWithText += 1
            totalChars += text.count
            if text.contains("\n") { pagesWithNewline += 1 }

            let blocks = OfferPositionExtractor.blocks(inPageText: text)
            totalBlocks += blocks.count
            blocksPerPage.append(blocks.count)

            for p in OfferPositionExtractor.extractPositions(fromPageText: text) {
                totalPositions += 1
                conf[p.confidence, default: 0] += 1
                if samples.count < 18 {
                    samples.append((i + 1, String(p.title.prefix(46)),
                                    p.netPrice.map { "\($0)" } ?? "—",
                                    p.listPrice.map { "\($0)" } ?? "—",
                                    p.confidence.rawValue))
                }
            }
        }

        let avgBlocks = pagesWithText > 0 ? Double(totalBlocks) / Double(pagesWithText) : 0
        print("""

        ┌─ Pass-1-Sondierung · ALLEANGEBOTE.pdf ─────────────────────────
        │ Seiten gesamt:            \(doc.pageCount)   ·   mit Text: \(pagesWithText)
        │ Seiten mit Zeilenumbruch: \(pagesWithNewline)/\(pagesWithText)   ← entscheidet, ob Anker greift
        │ Ø Zeichen/Seite:          \(pagesWithText > 0 ? totalChars / pagesWithText : 0)
        │ ── Blocking (Pass 1) ──
        │ Blöcke gesamt:            \(totalBlocks)   ·   Ø Blöcke/Seite: \(String(format: "%.1f", avgBlocks))
        │ Positionen (netPrice≠nil): \(totalPositions)
        │ 🟢 green: \(conf[.green] ?? 0)   🟠 amber: \(conf[.amber] ?? 0)   🔴 red: \(conf[.red] ?? 0)
        └────────────────────────────────────────────────────────────────
        """)
        print("Stichprobe extrahierter Positionen (Seite · Ampel · netto/liste · Titel):")
        for s in samples { print("  S\(s.page) [\(s.c)] netto=\(s.net) liste=\(s.list)  ·  \(s.title)") }
        // Blocks-pro-Seite Extreme (Diagnose: 1/Seite = Blob-Problem, sehr viele = Über-Splitting)
        let sorted = blocksPerPage.sorted()
        if sorted.isEmpty == false {
            print("Blöcke/Seite: min=\(sorted.first!) median=\(sorted[sorted.count/2]) max=\(sorted.last!)")
        }
    }
}
