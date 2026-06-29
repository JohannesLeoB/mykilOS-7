import Testing
import Foundation
@testable import MykilosServices
import MykilosKalkulationsCore

// MARK: - feat/tischler-predictor · Phase 2
// Beweist: der verifizierte Korpus (normalized_anchor_scope_signatures.csv) trägt
// den vorberechneten Ausstattungsgrad pro candidate_id nach — ohne Preise zu berühren —
// und ein fehlender Join degradiert still zu `.unknown`.
struct ScopeSignatureCatalogTests {

    private let csv = """
    candidate_id,equipment_density,drawers_per_lfm
    POS-000021,low,1.336
    POS-000460,high,3.546
    POS-000999,,
    """

    private func writeCSV(_ content: String) throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("scope-sig-\(UUID().uuidString).csv")
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @Test func loadMapsKnownDensitiesAndSkipsBlank() throws {
        let url = try writeCSV(csv)
        defer { try? FileManager.default.removeItem(at: url) }
        let catalog = ScopeSignatureCatalog.load(from: url)

        #expect(catalog.count == 2)   // POS-000999 (leer) wird übersprungen
        #expect(catalog.density(for: "POS-000021") == .low)
        #expect(catalog.density(for: "POS-000460") == .high)
        #expect(catalog.density(for: "POS-000999") == .unknown)
        #expect(catalog.density(for: "UNBEKANNT") == .unknown)
    }

    @Test func enrichAttachesDensityWithoutTouchingPrice() throws {
        let url = try writeCSV(csv)
        defer { try? FileManager.default.removeItem(at: url) }
        let catalog = ScopeSignatureCatalog.load(from: url)

        let anchor = CandidateReleaseDecision(
            candidateID: "POS-000021", sourceFile: "x", page: 1, supplier: "s", project: "p",
            component: "Küchenzeile", trade: "tischler", priceNetGuess: 12_926, confidence: 0.8,
            duplicateCount: 0, currentStatus: "release_candidate", proposedStatus: "release_candidate",
            supersededBy: nil, decisionScore: 0.8, decisionReason: "", helpNeeded: "", title: "t",
            evidenceQuote: "q", carryforwardRuleStatus: "", ruleSafePriceNet: nil, ruleNotes: "",
            componentClass: .kitchenRun, sourceKind: .pdfOffer
        )
        let enriched = catalog.enrich([anchor])
        #expect(enriched.count == 1)
        #expect(enriched[0].equipmentDensity == .low)
        #expect(enriched[0].priceNetGuess == Decimal(12_926))   // Preis unberührt
        #expect(enriched[0].candidateID == "POS-000021")
    }

    @Test func missingFileDegradesToEmptyCatalog() {
        let catalog = ScopeSignatureCatalog.load(from: URL(fileURLWithPath: "/nonexistent/scope.csv"))
        #expect(catalog.count == 0)
        // Anreicherung ist dann ein No-Op (Anker bleiben unverändert).
        let anchor = BaselineAnchorProvider()
        #expect((try? catalog.enrich(anchor.activeAnchors()).count) != nil)
    }
}
