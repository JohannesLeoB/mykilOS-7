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

    @Test func geraetepreisOhneKatalogIstNil() async throws {
        let engine = KalkulationsEngine(provider: StubAnchorProvider(), learningStore: try tempStore())
        // Ohne injizierten Katalog ist geraetepreis bewusst nil (optionaler Lookup).
        let preis = await engine.geraetepreis(suchbegriff: "spüle")
        #expect(preis == nil)
    }

    // MARK: importPDF (Härtung 2026-07-01) — SHA256-Dedup + Airtable-Ablage

    private struct FakeDrivePDF: GoogleDriveFetching {
        let content: Data
        let fileName: String
        func listFolder(folderID: String) async throws -> [GoogleDriveFile] { [] }
        func getFileName(folderID: String) async throws -> String { fileName }
        func downloadContent(fileID: String) async throws -> Data { content }
    }

    private final class FakeAirtableCreate: AirtableRecordCreating, @unchecked Sendable {
        private(set) var aufrufe = 0
        private(set) var letzteFelder: [String: AirtableFieldValue]?
        func createRecord(baseID: String, table: String, fields: [String: AirtableFieldValue]) async throws -> String {
            aufrufe += 1
            letzteFelder = fields
            return "rec_import_\(aufrufe)"
        }
    }

    @Test func importPDFOhneInjizierteAbhaengigkeitenWirftKlar() async throws {
        let engine = KalkulationsEngine(provider: StubAnchorProvider(), learningStore: try tempStore())
        await #expect(throws: KalkulationsEngineError.self) {
            try await engine.importPDF(driveFileID: "x", projektID: "P-1")
        }
    }

    @Test func importPDFLegtNeuenAirtableRecordUndDedupLogAn() async throws {
        let store = try tempStore()
        let airtable = FakeAirtableCreate()
        let engine = KalkulationsEngine(
            provider: StubAnchorProvider(), learningStore: store,
            drive: FakeDrivePDF(content: Data("erstes-pdf".utf8), fileName: "Angebot_Tischler.pdf"),
            airtable: airtable
        )

        try await engine.importPDF(driveFileID: "file-1", projektID: "2026-042")

        #expect(airtable.aufrufe == 1)
        #expect(airtable.letzteFelder?["Datei-Name"] == .string("Angebot_Tischler.pdf"))
        #expect(airtable.letzteFelder?["Projekt-Nr"] == .string("2026-042"))
        #expect(airtable.letzteFelder?["Richtung"] == .string("eingehend"))
        #expect(airtable.letzteFelder?["Status"] == .string("Neu"))

        let imports = try store.database().documentImports()
        #expect(imports.count == 1)
        #expect(imports.first?.isDuplicate == false)
        #expect(imports.first?.recordID == "rec_import_1")
    }

    @Test func importPDFUeberspringtEchtesDuplikatOhneZweitenAirtableRecord() async throws {
        let store = try tempStore()
        let airtable = FakeAirtableCreate()
        let sameContent = Data("identisches-pdf".utf8)
        let engine = KalkulationsEngine(
            provider: StubAnchorProvider(), learningStore: store,
            drive: FakeDrivePDF(content: sameContent, fileName: "Angebot.pdf"),
            airtable: airtable
        )

        try await engine.importPDF(driveFileID: "file-1", projektID: "2026-042")
        try await engine.importPDF(driveFileID: "file-1-kopie", projektID: "2026-042")   // gleicher Inhalt

        // NUR EIN Airtable-Record — das Duplikat erzeugt ausschließlich einen lokalen Log-Eintrag.
        #expect(airtable.aufrufe == 1)

        let imports = try store.database().documentImports()
        #expect(imports.count == 2)
        #expect(imports.filter { $0.isDuplicate }.count == 1)
        #expect(imports.filter { $0.isDuplicate == false }.count == 1)
    }

    // MARK: recordAdjustment — persistiert die Anpassung append-only

    @Test func recordAdjustmentBuchtAnpassungGegenSchaetzung() async throws {
        let store = try tempStore()
        let engine = KalkulationsEngine(provider: StubAnchorProvider(), learningStore: store)

        // Eine Schätzung erzeugt die persistierte Session + stabile schaetzungsID.
        let schaetzung = try await engine.schaetze(projektID: "P-7", freitext: "5 lfm unterschränke")
        #expect(!schaetzung.schaetzungsID.isEmpty)

        // Anpassung gegen genau diese Schätzung — wirft NICHT mehr.
        try await engine.recordAdjustment(schaetzungsID: schaetzung.schaetzungsID, faktor: 0.8, grund: "Aufmaß kleiner")

        // Genau ein Adjustment, korrekt gegen die Session gebucht.
        let adjustments = try store.estimateAdjustments()
        #expect(adjustments.count == 1)
        #expect(adjustments.first?.sessionID == schaetzung.schaetzungsID)
        // faktor 0.8 → −20 % Prozent-Delta (Toleranz für Decimal-Rundung)
        #expect(abs((adjustments.first?.percentDelta ?? 0) - (-20)) < 0.5)
        #expect(adjustments.first?.note == "Aufmaß kleiner")
    }

    @Test func recordAdjustmentMitUnbekannterSessionWirft() async throws {
        let engine = KalkulationsEngine(provider: StubAnchorProvider(), learningStore: try tempStore())
        // Ohne vorherige Schätzung gibt es keine Session → klarer Fehler.
        await #expect(throws: (any Error).self) {
            try await engine.recordAdjustment(schaetzungsID: "gibt-es-nicht", faktor: 1.1, grund: "Test")
        }
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

    // MARK: L4 — Lern-Loop Audit-Pfad (promote schreibt AuditEntry)
    @Test @MainActor func promoteSchreibtAuditEntry() async throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mykilos-l4-audit-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let db = try GRDBDatabase(url: dir.appendingPathComponent("test.sqlite"))
        let auditStore = AuditStore(db: db)
        let learningStore = LearningStore(directory: dir)
        let engine = KalkulationsEngine(
            provider: BaselineAnchorProvider(),
            learningStore: learningStore,
            auditStore: auditStore
        )

        // 3× Anpassung mit lernen: true → Kandidat entsteht.
        let freitext = "5 laufmeter unterschränke"
        for _ in 0..<3 {
            let s = try await engine.schaetze(projektID: "P-audit", freitext: freitext)
            try await engine.recordAdjustment(schaetzungsID: s.schaetzungsID, faktor: 1.1, grund: "Markt", lernen: true)
        }

        // Kandidat promoten → AuditEntry(.calibrationPromoted) wird geschrieben.
        let stand = try await engine.lernUebersicht()
        if let kandidat = stand.kandidaten.first {
            try await engine.promote(candidateID: kandidat.id)
            let entries = await auditStore.entries
            let promoted = entries.filter {
                if case .calibrationPromoted = $0.action { return true }
                return false
            }
            #expect(!promoted.isEmpty, "promote() muss AuditEntry(.calibrationPromoted) schreiben")
            #expect(promoted.first?.projectID == "kalkulation")
        }

        // recordAdjustment schreibt AuditEntry(.estimateAdjusted) — 3 Stück.
        let adjustEntries = await auditStore.entries.filter {
            if case .estimateAdjusted = $0.action { return true }
            return false
        }
        #expect(adjustEntries.count == 3)
    }
}
