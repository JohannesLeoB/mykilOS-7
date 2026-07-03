import XCTest
@testable import MykilosServices

// Tests für die geteilte Filter-/Sortierlogik der Material-/Plan-Sammlungsansichten
// (PlanTypeFilter, MaterialSorter). Reine Logik, kein Netzwerk/Keychain.
final class MaterialSorterTests: XCTestCase {

    // MARK: - Fixtures

    private func pdf(_ name: String, at date: Date? = nil) -> GoogleDriveFile {
        GoogleDriveFile(id: name, name: name, mimeType: "application/pdf",
                        modifiedAt: date, webViewLink: nil)
    }
    private func image(_ name: String, mime: String = "image/jpeg", at date: Date? = nil) -> GoogleDriveFile {
        GoogleDriveFile(id: name, name: name, mimeType: mime,
                        modifiedAt: date, webViewLink: nil)
    }
    /// Datei mit generischem MIME, aber Bild-Endung — Typerkennung darf sich nicht
    /// allein auf den MIME-Typ verlassen.
    private func file(_ name: String, mime: String) -> GoogleDriveFile {
        GoogleDriveFile(id: name, name: name, mimeType: mime, modifiedAt: nil, webViewLink: nil)
    }

    // MARK: - PlanTypeFilter

    func testTypeFilterPDFErkenntEndungUndMIME() {
        XCTAssertTrue(PlanTypeFilter.pdf.matches(pdf("Grundriss.pdf")))
        XCTAssertTrue(PlanTypeFilter.pdf.matches(file("plan", mime: "application/pdf")))
        XCTAssertFalse(PlanTypeFilter.pdf.matches(image("render.jpg")))
    }

    func testTypeFilterBildErkenntRasterAberNiePDF() {
        XCTAssertTrue(PlanTypeFilter.bild.matches(image("render.jpg")))
        XCTAssertTrue(PlanTypeFilter.bild.matches(file("foto.PNG", mime: "application/octet-stream")))
        XCTAssertFalse(PlanTypeFilter.bild.matches(pdf("Grundriss.pdf")))
    }

    // MARK: - MaterialSorter Filter

    func testQueryFilterCaseInsensitiveTeilstring() {
        let files = [pdf("HUSTADT_Grundriss.pdf"), pdf("Elevations.pdf"), image("hero.png")]
        let hit = MaterialSorter.filtered(files, query: "grund")
        XCTAssertEqual(hit.map(\.name), ["HUSTADT_Grundriss.pdf"])
    }

    func testLeereQueryLaesstAllesDurch() {
        let files = [pdf("a.pdf"), pdf("b.pdf")]
        XCTAssertEqual(MaterialSorter.filtered(files, query: "   ").count, 2)
    }

    func testTypeFilterNilLaesstAllesDurch() {
        let files = [pdf("a.pdf"), image("b.png")]
        XCTAssertEqual(MaterialSorter.filtered(files, type: nil).count, 2)
        XCTAssertEqual(MaterialSorter.filtered(files, type: .pdf).map(\.name), ["a.pdf"])
        XCTAssertEqual(MaterialSorter.filtered(files, type: .bild).map(\.name), ["b.png"])
    }

    // MARK: - MaterialSorter Sortierung

    func testSortDatumNeuesteZuerst() {
        let alt = Date(timeIntervalSince1970: 1_000)
        let neu = Date(timeIntervalSince1970: 2_000)
        let files = [pdf("alt.pdf", at: alt), pdf("neu.pdf", at: neu)]
        XCTAssertEqual(MaterialSorter.sorted(files, by: .datum).map(\.name), ["neu.pdf", "alt.pdf"])
    }

    func testSortNameAufsteigendCaseInsensitiv() {
        let files = [pdf("Zeta.pdf"), pdf("alpha.pdf"), pdf("Beta.pdf")]
        XCTAssertEqual(MaterialSorter.sorted(files, by: .name).map(\.name),
                       ["alpha.pdf", "Beta.pdf", "Zeta.pdf"])
    }

    func testSortDatumSchiebtDateienOhneDatumNachHinten() {
        let neu = Date(timeIntervalSince1970: 2_000)
        let files = [pdf("ohne.pdf", at: nil), pdf("neu.pdf", at: neu)]
        XCTAssertEqual(MaterialSorter.sorted(files, by: .datum).map(\.name), ["neu.pdf", "ohne.pdf"])
    }
}
