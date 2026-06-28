import Testing
import Foundation
@testable import MykilosServices
import MykilosKit
import MykilosKalkulationsCore

// MARK: - KalkulationsEngine Adapter-Tests
// Testet den Adapter selbst (parse → estimate → Mapping), nicht die Preislogik des
// Kerns (die ist in MykilosKalkulationsCoreTests + den deferred Integrationstests).
// Stub-Provider ohne Anker hält den Test deterministisch und seed-frei.
struct KalkulationsEngineTests {

    /// Anker-Provider ohne Daten — deterministisch, keine externen Seed-Dateien nötig.
    private struct StubAnchorProvider: PriceAnchorProviding {
        func activeAnchors() throws -> [CandidateReleaseDecision] { [] }
    }

    private func tempStore() throws -> LearningStore {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mykilos-engine-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return LearningStore(directory: dir)
    }

    @Test func schaetzeLiefertGemappteKostenSchaetzung() async throws {
        let engine = KalkulationsEngine(provider: StubAnchorProvider(), learningStore: try tempStore())

        let schaetzung = try await engine.schaetze(
            projektID: "P-1",
            freitext: "5 laufmeter unterschränke mit linoleumfronten. 15 eichenschubkästen."
        )

        // Mapping korrekt verdrahtet
        #expect(schaetzung.projektID == "P-1")
        // Ohne Anker: keine Evidenzen, aber kein Crash
        #expect(schaetzung.evidenceCount == 0)
        #expect(schaetzung.topEvidences.isEmpty)
        // Div-by-Zero-Guard: mitte == 0 → ratio == 0 (nicht inf/NaN)
        #expect(schaetzung.kostenbodenRatio.isFinite)
        #expect(schaetzung.kostenboden >= 0)
        #expect(schaetzung.minNetto <= schaetzung.maxNetto)
    }

    @Test func nochNichtVerdrahteteFaehigkeitenWerfenKlar() async throws {
        let engine = KalkulationsEngine(provider: StubAnchorProvider(), learningStore: try tempStore())

        await #expect(throws: KalkulationsEngineError.self) {
            try await engine.importPDF(driveFileID: "x", projektID: "P-1")
        }
        await #expect(throws: KalkulationsEngineError.self) {
            try await engine.recordAdjustment(schaetzungsID: "s-1", faktor: 1.1, grund: "Test")
        }
        // Ohne injizierten Katalog ist geraetepreis bewusst nil (optionaler Lookup).
        let preis = await engine.geraetepreis(suchbegriff: "spüle")
        #expect(preis == nil)
    }

    // Synthetisch — niemals reale Preisbuch-Daten.
    private static let syntheticCSV = """
    Suchtext,Artikelnummer,Hersteller,Kategorie,Artikelbeschreibung,Netto-Verkaufspreis LISTE (€),Netto-Einkaufspreis (€),Netto-Verkaufspreis MYKILOS (€)
    gaggenau backofen,G-200,Gaggenau,Backofen,Gaggenau Backofen Serie 200,3200,2100,2890
    bora kochfeld abzug,B-PUR,BORA,Kochfeld,BORA Pure Kochfeldabzug,2450,1600,2190
    """

    @Test func schaetzeMitBaselineAnkernLiefertEchteZahlen() async throws {
        // Wie in der App verdrahtet: Baseline-Anker (eingebaut, keine externen Daten).
        let engine = KalkulationsEngine(provider: BaselineAnchorProvider(), learningStore: try tempStore())

        let s = try await engine.schaetze(
            projektID: "P-1",
            freitext: "5 laufmeter unterschränke mit linoleumfronten. 15 eichenschubkästen. Insel ca 2 x 1,2 m in Edelstahl."
        )

        // Echte, positive Schätzung mit Evidenz — nicht der leere Stub-Fall.
        #expect(s.mitteNetto > 0)
        #expect(s.evidenceCount > 0)
        #expect(s.minNetto <= s.mitteNetto)
        #expect(s.mitteNetto <= s.maxNetto)
    }

    @Test func geraetepreisLiefertPreisAusInjiziertemKatalog() async throws {
        let catalog = try DeviceCatalog(csv: Self.syntheticCSV)
        let engine = KalkulationsEngine(
            provider: StubAnchorProvider(),
            learningStore: try tempStore(),
            deviceCatalog: catalog
        )

        // Treffer → MYKILOS-VK (sellNet bevorzugt mykilosNet vor Liste)
        let bora = await engine.geraetepreis(suchbegriff: "bora kochfeld")
        #expect(bora == 2190)

        // Kein Treffer → nil
        let none = await engine.geraetepreis(suchbegriff: "nichtvorhandenerbegriffxyz")
        #expect(none == nil)
    }
}
