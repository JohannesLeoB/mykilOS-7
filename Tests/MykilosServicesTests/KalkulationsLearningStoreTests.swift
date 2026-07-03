import Testing
import Foundation
@testable import MykilosServices
import MykilosKalkulationsCore

// MARK: - KalkulationsLearningStore Cold-Start-Tests
// Beweist: Lern-/Kalibrierungsdaten überleben den App-Neustart.
// LearningStore schreibt append-only in eine eigene `learning.sqlite`
// (nicht in die Haupt-GRDB-Migration). Cold-Start ist hier der stärkste
// Beweis: eine ZWEITE Store-Instanz öffnet dieselbe Datei frisch von Platte.
struct KalkulationsLearningStoreTests {

    /// Anker-Provider ohne Daten — deterministisch, keine externen Seed-Dateien nötig.
    private struct StubAnchorProvider: PriceAnchorProviding {
        func activeAnchors() throws -> [CandidateReleaseDecision] { [] }
    }

    private func tempDir() throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mykilos-learning-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Minimale, gültige Schätzung — kein Seed/Estimator nötig, nur der Persistenz-Pfad.
    private func minimalResult() -> EstimateResult {
        let request = EstimateRequest(
            rawText: "Cold-Start Test",
            components: [],
            materials: [],
            scope: ScopeFlags()
        )
        let band = PriceBand(low: 1000, expected: 1500, high: 2000, currency: "EUR")
        return EstimateResult(
            request: request,
            lines: [],
            totalBand: band,
            laborValue: 500,
            confidence: 0.5,
            evidence: [],
            dataGaps: [],
            excludedRisks: [],
            scopeNotes: []
        )
    }

    // MARK: Core: Lern-Daten überleben Neustart
    @Test func lernDatenUeberlebenNeustart() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        // Session A: schreiben (Session + Adjustment, append-only)
        let storeA = LearningStore(directory: dir)
        let session = try storeA.saveSession(from: minimalResult())
        let adjustment = try storeA.appendAdjustment(
            sessionID: session.id,
            percentDelta: 10,
            euroDelta: nil,
            reason: .marketPrice,
            target: .wholeEstimate,
            learn: false
        )
        #expect(try storeA.estimateSessions().count == 1)
        #expect(try storeA.estimateAdjustments().count == 1)

        // "App neu gestartet": neue Store-Instanz, selbe learning.sqlite auf Platte
        let storeB = LearningStore(directory: dir)
        let sessionsB = try storeB.estimateSessions()
        let adjustmentsB = try storeB.estimateAdjustments()

        #expect(sessionsB.count == 1)
        #expect(adjustmentsB.count == 1)
        // Identisch — kein Datenverlust über den Neustart
        #expect(sessionsB.first?.id == session.id)
        #expect(sessionsB.first?.requestText == "Cold-Start Test")
        #expect(sessionsB.first?.baseMidNet == Decimal(1500))
        #expect(adjustmentsB.first?.id == adjustment.id)
        #expect(adjustmentsB.first?.adjustedMidNet == adjustment.adjustedMidNet)
    }

    // MARK: recordAdjustment-Flow überlebt Neustart (Engine → LearningStore → Platte)
    // Stärkster Beweis für Schritt 7: die Anpassung wird NICHT direkt über den
    // LearningStore geschrieben, sondern über `KalkulationsEngine.recordAdjustment`
    // (der echte Produktionspfad) — und ist nach einem Neustart trotzdem lesbar.
    @Test func recordAdjustmentUeberlebtNeustart() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        // Session A: Engine auf eigenem Store. schaetze persistiert die Session,
        // recordAdjustment bucht die Anpassung append-only.
        let storeA = LearningStore(directory: dir)
        let engine = KalkulationsEngine(provider: StubAnchorProvider(), learningStore: storeA)
        let schaetzung = try await engine.schaetze(projektID: "P-9", freitext: "5 lfm unterschränke")
        try await engine.recordAdjustment(schaetzungsID: schaetzung.schaetzungsID, faktor: 0.9, grund: "Aufmaß kleiner")

        // "App neu gestartet": frische Store-Instanz auf derselben learning.sqlite.
        let storeB = LearningStore(directory: dir)
        let adjustmentsB = try storeB.estimateAdjustments()
        #expect(adjustmentsB.count == 1)
        #expect(adjustmentsB.first?.sessionID == schaetzung.schaetzungsID)
        #expect(adjustmentsB.first?.note == "Aufmaß kleiner")
        // faktor 0.9 → −10 % Prozent-Delta (Toleranz für Decimal-Rundung)
        #expect(abs((adjustmentsB.first?.percentDelta ?? 0) - (-10)) < 0.5)
    }

    // MARK: importPDF (Härtung 2026-07-01) überlebt Neustart
    // Stärkster Beweis für den PDF-Import-Dedup-Log: nach einem Neustart (frische
    // LearningDatabase-Instanz, dieselbe learning.sqlite) ist sowohl der importierte
    // Record als auch der Duplikat-Status korrekt lesbar.
    private struct FakeDrivePDF: GoogleDriveFetching {
        func listFolder(folderID: String) async throws -> [GoogleDriveFile] { [] }
        func getFileName(folderID: String) async throws -> String { "Angebot_Cold_Start.pdf" }
        func downloadContent(fileID: String) async throws -> Data { Data("cold-start-inhalt".utf8) }
    }
    private final class FakeAirtableCreate: AirtableRecordCreating, @unchecked Sendable {
        func createRecord(baseID: String, table: String, fields: [String: AirtableFieldValue]) async throws -> String {
            "rec_cold_start"
        }
    }

    @Test func importPDFUeberlebtNeustart() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let storeA = LearningStore(directory: dir)
        let engine = KalkulationsEngine(
            provider: StubAnchorProvider(), learningStore: storeA,
            drive: FakeDrivePDF(), airtable: FakeAirtableCreate()
        )
        try await engine.importPDF(driveFileID: "file-cold-start", projektID: "2026-099")

        // "App neu gestartet": frische Store-Instanz auf derselben learning.sqlite.
        let storeB = LearningStore(directory: dir)
        let importsB = try storeB.database().documentImports()
        #expect(importsB.count == 1)
        #expect(importsB.first?.recordID == "rec_cold_start")
        #expect(importsB.first?.fileName == "Angebot_Cold_Start.pdf")
        #expect(importsB.first?.isDuplicate == false)
    }

    // MARK: Lern-Loop schließt sich und überlebt Neustart (Schritt 8)
    // Stärkster Beweis für den Lern-Loop: drei Anpassungen mit `lernen: true` über
    // die Engine erzeugen einen Kandidaten; `promote` macht daraus einen aktiven
    // Faktor; nach einem Neustart (frische Store-Instanz, selbe learning.sqlite)
    // ist der Faktor lesbar UND der EvidenceBasedEstimator nutzt ihn — die mittlere
    // Schätzung verschiebt sich messbar gegenüber der unkalibrierten Baseline.
    @Test func lernLoopUeberlebtNeustartUndVerschiebtSchaetzung() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        // Baseline-Anker (eingebaut, deterministisch) liefert eine echte, positive
        // Schätzung — der Stub-Provider ohne Anker hätte mitteNetto == 0, dann
        // könnte keine Kalibrierung greifen.
        let freitext = "5 laufmeter unterschränke mit linoleumfronten. 15 eichenschubkästen. Insel ca 2 x 1,2 m in Edelstahl."

        let storeA = LearningStore(directory: dir)
        let engineA = KalkulationsEngine(provider: BaselineAnchorProvider(), learningStore: storeA)

        // Drei ähnliche Anpassungen (+10 %), jede mit Lernen → ab der dritten
        // entsteht ein Kalibrierungs-Kandidat (gleicher reason/target im Store).
        var baselineMitte = 0.0
        for index in 0..<3 {
            let s = try await engineA.schaetze(projektID: "P-1", freitext: freitext)
            if index == 0 { baselineMitte = s.mitteNetto }   // noch unkalibriert
            try await engineA.recordAdjustment(
                schaetzungsID: s.schaetzungsID,
                faktor: 1.10,
                grund: "Marktpreis höher",
                lernen: true
            )
        }
        #expect(baselineMitte > 0)

        // Der Kandidat ist über die Engine sichtbar und promotebar.
        let stand = try await engineA.lernUebersicht()
        let kandidat = try #require(stand.kandidaten.first)
        try await engineA.promote(candidateID: kandidat.id)

        // "App neu gestartet": frische Store-Instanz auf derselben learning.sqlite.
        let storeB = LearningStore(directory: dir)
        #expect(try storeB.activeCalibrationFactors().count >= 1)

        // Eine NEUE Engine über den Cold-Start-Store schätzt höher: der aktive
        // Faktor (+10 % auf die Gesamtschätzung) verschiebt die Mitte messbar.
        let engineB = KalkulationsEngine(provider: BaselineAnchorProvider(), learningStore: storeB)
        let kalibriert = try await engineB.schaetze(projektID: "P-1", freitext: freitext)
        #expect(kalibriert.mitteNetto > baselineMitte)
    }

    // MARK: Append-only: zwei Adjustments = zwei physische Zeilen nach Neustart
    @Test func appendOnlyBleibtNachNeustartErhalten() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let storeA = LearningStore(directory: dir)
        let session = try storeA.saveSession(from: minimalResult())
        _ = try storeA.appendAdjustment(sessionID: session.id, percentDelta: 8, euroDelta: nil,
                                        reason: .materialUnderestimated, target: .wholeEstimate, learn: false)
        _ = try storeA.appendAdjustment(sessionID: session.id, percentDelta: 6, euroDelta: nil,
                                        reason: .materialUnderestimated, target: .wholeEstimate, learn: false)

        let storeB = LearningStore(directory: dir)
        #expect(try storeB.estimateAdjustments().count == 2)
    }
}
