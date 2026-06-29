import XCTest
@testable import MykilosKalkulationsCore

// MARK: - feat/tischler-predictor · Phase 2 (Ausstattungsgrad / Scope-Normalisierung)
// Beweist SCOPE-006 (Dichte-Klassifikation) und den dichtebewussten Ausschluss:
// eine schlichte 4,5-m-Eiche-Zeile mit 6 Schubkästen (low) darf NICHT gegen
// hochausgestattete Legrabox-/Innenauszug-Anker (high) gematcht werden.
final class KitchenEquipmentDensityTests: XCTestCase {

    // MARK: SCOPE-006 — Schwellwerte
    func testDensityThresholds() {
        // 6 Schübe / 4,5 m = 1,33 → low
        XCTAssertEqual(KitchenEquipmentDensity.classify(drawerCount: 6, lengthM: 4.5), .low)
        // 20 Schübe / 4,5 m = 4,44 → high
        XCTAssertEqual(KitchenEquipmentDensity.classify(drawerCount: 20, lengthM: 4.5), .high)
        // 0 Schübe (Anker-Seite, echte Daten) → none
        XCTAssertEqual(KitchenEquipmentDensity.classify(drawerCount: 0, lengthM: 5.0), KitchenEquipmentDensity.none)
        // genau an den Grenzen
        XCTAssertEqual(KitchenEquipmentDensity.classify(drawersPerLfm: 1.5), .low)
        XCTAssertEqual(KitchenEquipmentDensity.classify(drawersPerLfm: 3.0), .medium)
        XCTAssertEqual(KitchenEquipmentDensity.classify(drawersPerLfm: 4.5), .high)
        XCTAssertEqual(KitchenEquipmentDensity.classify(drawersPerLfm: 5.0), .veryHigh)
        // unbekannte Länge → unknown
        XCTAssertEqual(KitchenEquipmentDensity.classify(drawerCount: 6, lengthM: nil), .unknown)
    }

    // MARK: Query-Asymmetrie — „kein Schubkasten genannt" = unbekannt, nicht null
    func testQuerySideTreatsZeroAsUnknown() {
        XCTAssertEqual(KitchenEquipmentDensity.classifyQuery(drawerCount: 0, lengthM: 4.5), .unknown)
        XCTAssertEqual(KitchenEquipmentDensity.classifyQuery(drawerCount: 6, lengthM: 4.5), .low)
    }

    // MARK: Hart-Unvereinbarkeit nur bei ≥2 Stufen, nie bei unknown
    func testHardIncompatibility() {
        XCTAssertTrue(KitchenEquipmentDensity.low.isHardIncompatible(with: .high))
        XCTAssertTrue(KitchenEquipmentDensity.low.isHardIncompatible(with: .veryHigh))
        XCTAssertTrue(KitchenEquipmentDensity.none.isHardIncompatible(with: .medium))
        XCTAssertFalse(KitchenEquipmentDensity.low.isHardIncompatible(with: .medium))   // benachbart
        XCTAssertFalse(KitchenEquipmentDensity.low.isHardIncompatible(with: .unknown))  // unbekannt → kein Ausschluss
        XCTAssertFalse(KitchenEquipmentDensity.unknown.isHardIncompatible(with: .high))
    }

    // MARK: Korpus-Rohwert tolerant einlesen
    func testRawCorpusParsing() {
        XCTAssertEqual(KitchenEquipmentDensity(rawCorpus: "very_high"), .veryHigh)
        XCTAssertEqual(KitchenEquipmentDensity(rawCorpus: "LOW"), .low)
        XCTAssertEqual(KitchenEquipmentDensity(rawCorpus: ""), .unknown)
        XCTAssertEqual(KitchenEquipmentDensity(rawCorpus: "garbage"), .unknown)
    }

    // MARK: Akzeptanztest — low-Anfrage matcht NICHT gegen high-Anker
    func testLowDensityQueryExcludesHighDensityAnchor() throws {
        let lowAnchor = kitchenRunAnchor(id: "LOW-KR", price: 12_000, density: .low)
        let highAnchor = kitchenRunAnchor(id: "HIGH-KR", price: 16_000, density: .high)
        let estimator = EvidenceBasedEstimator(provider: StubAnchorProvider([lowAnchor, highAnchor]))

        let request = EstimateRequestParser().parse(
            "4,5 m Küche, Eiche furniert, 6 Schubkästen, ohne Geräte, ohne Arbeitsplatte"
        )
        let result = try estimator.estimate(request)
        let usedIDs = Set(result.evidence.map(\.priceAnchorID))

        XCTAssertTrue(usedIDs.contains("LOW-KR"), "Der passend ausgestattete low-Anker muss verwendet werden.")
        XCTAssertFalse(usedIDs.contains("HIGH-KR"), "Der hochausgestattete Anker (Legrabox-Niveau) darf NICHT matchen.")
    }

    // MARK: Unbekannte Anker-Dichte wird NICHT ausgeschlossen (ehrlich breites Band)
    func testUnknownAnchorDensityStillMatches() throws {
        let unknownAnchor = kitchenRunAnchor(id: "UNK-KR", price: 14_000, density: .unknown)
        let estimator = EvidenceBasedEstimator(provider: StubAnchorProvider([unknownAnchor]))
        let request = EstimateRequestParser().parse(
            "4,5 m Küche, Eiche furniert, 6 Schubkästen, ohne Geräte, ohne Arbeitsplatte"
        )
        let result = try estimator.estimate(request)
        XCTAssertTrue(result.evidence.map(\.priceAnchorID).contains("UNK-KR"))
    }

    // MARK: - Helpers

    private struct StubAnchorProvider: PriceAnchorProviding {
        let anchors: [CandidateReleaseDecision]
        init(_ anchors: [CandidateReleaseDecision]) { self.anchors = anchors }
        func activeAnchors() throws -> [CandidateReleaseDecision] { anchors }
    }

    private func kitchenRunAnchor(id: String, price: Decimal, density: KitchenEquipmentDensity) -> CandidateReleaseDecision {
        CandidateReleaseDecision(
            candidateID: id,
            sourceFile: "test.pdf",
            page: 1,
            supplier: "Weichsel78",
            project: "2026-015",
            component: "Küchenzeile Eiche 4,5 m",
            trade: "tischler",
            priceNetGuess: price,
            confidence: 0.8,
            duplicateCount: 0,
            currentStatus: "release_candidate",
            proposedStatus: "release_candidate",
            supersededBy: nil,
            decisionScore: 0.8,
            decisionReason: "test",
            helpNeeded: "",
            title: "Küchenzeile Eiche 4,5 m",
            evidenceQuote: "Küchenzeile Eiche furniert, 4,5 m, mit Schubkästen.",
            carryforwardRuleStatus: "",
            ruleSafePriceNet: nil,
            ruleNotes: "",
            componentClass: .kitchenRun,
            sourceKind: .pdfOffer,
            equipmentDensity: density
        )
    }
}
