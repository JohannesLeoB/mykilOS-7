import Testing
import Foundation
@testable import MykilosServices
import MykilosKalkulationsCore

// MARK: - feat/tischler-predictor · Phase 1 (B-gated)
// Beweist den selbstwachsenden, review-gegateten Anker-Pfad:
//   import → Review-Gate → LearnedAnchorProvider → CompositeAnchorProvider → schaetze,
// inkl. Zeitgewichtung, Schutzschaltern, Dedup und Cold-Start-Überleben.
struct OfferAnchorSyncTests {

    private func tempDir() throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mykilos-offer-anchor-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func offer(
        _ recordID: String,
        kind: AirtableOfferKind = .eingehend,
        status: AirtableOfferStatus = .schlussrechnung,
        netto: Decimal = 23000,
        partner: String = "Weichsel78",
        datum: String = "2025-05-01"
    ) -> AirtableOfferEntry {
        AirtableOfferEntry(
            airtableRecordID: recordID,
            kind: kind,
            projekt: "2026-015",
            partner: partner,
            datum: datum,
            nettoEur: netto,
            status: status,
            dokumentURL: nil,
            leistungsbeschreibung: nil
        )
    }

    // MARK: Schutzschalter: nur eingehend mit Lernsignal wird Kostenanker
    @Test func syncFiltertAusgehendeUndSignallose() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = LearningStore(directory: dir)

        let report = try store.syncAirtableOffers([
            offer("rec-in-final", status: .schlussrechnung),          // ✓ Kostenanker
            offer("rec-in-accept", status: .akzeptiert),              // ✓ Kostenanker
            offer("rec-in-open", status: .offen),                     // ✗ kein Signal
            offer("rec-in-reject", status: .abgelehnt),               // ✗ kein Signal (eingehend abgelehnt)
            offer("rec-out", kind: .ausgehend, status: .akzeptiert)   // ✗ ausgehend → kein Kostenanker
        ])

        #expect(report.imported == 2)
        #expect(report.skippedNoSignal == 3)
        #expect(try store.offerSyncEntries().count == 2)
    }

    // MARK: Dedup über airtableRecordID
    @Test func syncDedupliziertProRecordID() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = LearningStore(directory: dir)

        _ = try store.syncAirtableOffers([offer("rec-A")])
        let second = try store.syncAirtableOffers([offer("rec-A"), offer("rec-B")])

        #expect(second.imported == 1)
        #expect(second.skippedDuplicate == 1)
        #expect(try store.offerSyncEntries().count == 2)
    }

    // MARK: Review-Gate: ohne Bestätigung KEIN Anker
    @Test func gateHaeltUnbestaetigteZurueck() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = LearningStore(directory: dir)
        _ = try store.syncAirtableOffers([offer("rec-A"), offer("rec-B")])

        let provider = LearnedAnchorProvider(store: store, referenceYear: 2026)
        #expect(try provider.activeAnchors().isEmpty)          // nichts freigegeben
        #expect(try store.pendingOfferSyncEntries().count == 2)

        try store.confirmOfferAnchor(airtableRecordID: "rec-A", note: "geprüft")
        #expect(try provider.activeAnchors().count == 1)        // nur das bestätigte
        #expect(try store.pendingOfferSyncEntries().count == 1)
        #expect(try provider.activeAnchors().first?.candidateID == "LEARNED-rec-A")
    }

    // MARK: Zeitgewichtung: alter Preis wird auf Gegenwartswert gehoben
    @Test func zeitgewichtungHebtAltenPreis() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = LearningStore(directory: dir)
        _ = try store.syncAirtableOffers([offer("rec-old", netto: 20000, datum: "2021-03-01")])
        try store.confirmOfferAnchor(airtableRecordID: "rec-old")

        let provider = LearnedAnchorProvider(store: store, referenceYear: 2026)
        let anchor = try #require(try provider.activeAnchors().first)
        // 2021 → 2026 = 5 Jahre × 4 % p. a. ⇒ Faktor ~1,217 ⇒ deutlich über 20.000.
        #expect(anchor.priceNetGuess > Decimal(22000))
        #expect(anchor.priceNetGuess < Decimal(26000))
    }

    // MARK: Cold-Start (Kern-Gate): bestätigter Anker überlebt Neustart, unbestätigter nicht
    @Test func bestaetigterAnkerUeberlebtNeustart() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        // Session A: importieren + nur einen bestätigen
        let storeA = LearningStore(directory: dir)
        _ = try storeA.syncAirtableOffers([offer("rec-A"), offer("rec-B")])
        try storeA.confirmOfferAnchor(airtableRecordID: "rec-A")

        // "App neu gestartet": frische Store-Instanz auf derselben learning.sqlite
        let storeB = LearningStore(directory: dir)
        let providerB = LearnedAnchorProvider(store: storeB, referenceYear: 2026)
        let anchors = try providerB.activeAnchors()
        #expect(anchors.count == 1)
        #expect(anchors.first?.candidateID == "LEARNED-rec-A")
        #expect(try storeB.offerSyncEntries().count == 2)   // beide Importe persistent
    }

    // MARK: Cold-Start (voller Pfad): bestätigte Anker verschieben schaetze messbar
    @Test func gelernteAnkerVerschiebenSchaetzungUeberNeustart() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        // „Gesamtküche" erzeugt eine aggregateKitchen-Position → genau der Kanal, in den die
        // gelernten Whole-Offer-Anker einfließen. Die Zeile hält die Baseline > 0.
        let freitext = "Gesamtküche, 6 laufmeter unterschränke mit linoleumfronten, 15 eichenschubkästen, Insel ca 2 x 1,2 m in Edelstahl."

        // Baseline: Seed-Anker (Baseline) ohne gelernte Anker.
        let storeA = LearningStore(directory: dir)
        let baselineEngine = KalkulationsEngine(
            provider: CompositeAnchorProvider(
                primary: BaselineAnchorProvider(),
                learned: LearnedAnchorProvider(store: storeA, referenceYear: 2026)
            ),
            learningStore: storeA
        )
        let baseline = try await baselineEngine.schaetze(projektID: "P-1", freitext: freitext)
        #expect(baseline.mitteNetto > 0)

        // Mehrere hochpreisige, bestätigte eingehende Schlussrechnungen einspeisen.
        for i in 0..<5 {
            _ = try storeA.syncAirtableOffers([offer("rec-\(i)", netto: 48000, datum: "2025-06-01")])
            try storeA.confirmOfferAnchor(airtableRecordID: "rec-\(i)")
        }

        // "App neu gestartet": frischer Store + frische Engine auf derselben Datei.
        let storeB = LearningStore(directory: dir)
        let engineB = KalkulationsEngine(
            provider: CompositeAnchorProvider(
                primary: BaselineAnchorProvider(),
                learned: LearnedAnchorProvider(store: storeB, referenceYear: 2026)
            ),
            learningStore: storeB
        )
        let kalibriert = try await engineB.schaetze(projektID: "P-1", freitext: freitext)
        // Die gelernten, hochpreisigen Aggregat-Anker ziehen die Mitte nach oben.
        #expect(kalibriert.mitteNetto > baseline.mitteNetto)
    }
}
