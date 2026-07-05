import Testing
import Foundation
@testable import MykilosServices
import MykilosKalkulationsCore

// MARK: - PDFPositionLearningTests (Lern-Loop · Cold-Start + Review-Gate)
// Beweist: (1) das Gate hält unbestätigte PDF-Positionen zurück; (2) eine bestätigte
// Position überlebt den Neustart und wird zum Anker; (3) Re-Import dedupt; (4) der
// CompositeAnchorProvider mischt den PDF-Kanal additiv dazu.
@MainActor
struct PDFPositionLearningTests {

    private func tempDir() throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mykilos-pdf-learn-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func pos(_ id: String, title: String = "Küchenarbeitsplatte Granit",
                     type: ComponentType = .stoneCountertop, price: Decimal = 5911.70) -> PDFExtractedPosition {
        PDFExtractedPosition(
            id: id, sourceFile: "Angebot.pdf", pageNumber: 2, title: title,
            componentType: type, netPrice: price, unit: "Stk", quantity: 1,
            confidence: 0.8, extractedAt: Date(timeIntervalSince1970: 1_700_000_000))
    }

    @Test func gateHaeltUnbestaetigteZurueck() throws {
        let dir = try tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let store = LearningStore(directory: dir)
        let report = try store.importPDFExtractedPositions([pos("PDF-a-p2-0")])
        #expect(report.imported == 1)

        let provider = PDFLearnedAnchorProvider(store: store)
        #expect(try provider.activeAnchors().isEmpty)          // nicht freigegeben → kein Anker
        #expect(try store.pendingPDFPositions().count == 1)

        try store.confirmPDFPosition(recordID: "PDF-a-p2-0", note: "sauberer Beleg")
        let anchors = try provider.activeAnchors()
        #expect(anchors.count == 1)
        #expect(anchors.first?.priceNetGuess == Decimal(string: "5911.70"))
        #expect(anchors.first?.componentClass == .worktopSurface)
        #expect(try store.pendingPDFPositions().isEmpty)
    }

    @Test func bestaetigterPDFAnkerUeberlebtNeustart() throws {
        let dir = try tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let storeA = LearningStore(directory: dir)
        _ = try storeA.importPDFExtractedPositions([pos("PDF-x-p2-0", price: 180)])
        try storeA.confirmPDFPosition(recordID: "PDF-x-p2-0")

        // Neustart: frische Instanz, selbe learning.sqlite
        let storeB = LearningStore(directory: dir)
        let anchors = try PDFLearnedAnchorProvider(store: storeB).activeAnchors()
        #expect(anchors.count == 1)
        #expect(anchors.first?.candidateID == "PDF-x-p2-0")
        #expect(anchors.first?.priceNetGuess == 180)
    }

    @Test func reImportDerselbenPositionDedupt() throws {
        let dir = try tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let store = LearningStore(directory: dir)
        _ = try store.importPDFExtractedPositions([pos("PDF-dup-0")])
        let report = try store.importPDFExtractedPositions([pos("PDF-dup-0", price: 999)])
        #expect(report.imported == 0)
        #expect(report.skippedDuplicate == 1)
        #expect(try store.pdfExtractedPositions().count == 1)
    }

    @Test func compositeMischtPDFKanalAdditiv() throws {
        let dir = try tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let store = LearningStore(directory: dir)
        _ = try store.importPDFExtractedPositions([pos("PDF-c-0")])
        try store.confirmPDFPosition(recordID: "PDF-c-0")

        let composite = CompositeAnchorProvider(
            primary: BaselineAnchorProvider(),
            learned: LearnedAnchorProvider(store: store),
            pdfLearned: PDFLearnedAnchorProvider(store: store))
        let anchors = try composite.activeAnchors()
        // Baseline-Anker + genau ein PDF-Anker.
        #expect(anchors.contains { $0.candidateID == "PDF-c-0" })
        #expect(anchors.count >= 2)
    }
}
