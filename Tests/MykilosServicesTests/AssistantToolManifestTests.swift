import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

// MARK: - AssistantToolManifest GATE-Tests (Mandate E)
// Sichert die Brücke Tool-Name → Manifest-ID gegen Drift:
//  1. Jede Ziel-ID der Map existiert wirklich im DatastromManifest.json.
//  2. Die Map deckt exakt die kanonischen 9 Tool-Namen ab.
//  3. Jedes real registrierte Tool ist gemappt (kein stilles Umbrella-Fallthrough).
//  4. Konkrete Zuordnung (search_gmail → GMAIL_SEARCH) + Umbrella-Fallback.
struct AssistantToolManifestTests {

    private func manifestIDs() throws -> Set<String> {
        // Tests/MykilosServicesTests/<file> → ../../Sources/MykilosApp/Resources/
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/MykilosApp/Resources/DatastromManifest.json")
        let data = try Data(contentsOf: url)
        let entries = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]
        return Set(entries.compactMap { $0["integrationID"] as? String })
    }

    @Test func jedeMappingZielIDExistiertImManifest() throws {
        let manifest = try manifestIDs()
        for (tool, id) in AssistantToolManifest.toolToManifestID {
            #expect(manifest.contains(id),
                    "Manifest-ID '\(id)' (für Tool '\(tool)') fehlt in DatastromManifest.json")
        }
        #expect(manifest.contains(AssistantToolManifest.umbrellaID),
                "Umbrella-ID '\(AssistantToolManifest.umbrellaID)' fehlt im Manifest")
    }

    @Test func mapDecktKanonischeToolNamenAb() {
        let erwartet: Set<String> = [
            "search_gmail", "list_calendar_events", "suggest_calendar_event",
            "list_drive_folder", "search_contacts", "list_clickup_tasks",
            "search_katalog", "query_studio_knowledge", "schaetze_projekt",
        ]
        #expect(Set(AssistantToolManifest.toolToManifestID.keys) == erwartet,
                "Map-Schlüssel weichen von den kanonischen Tool-Namen ab")
    }

    @Test func jedesRegistrierteToolIstGemappt() {
        // Registry mit allen optionalen Tools (Kalkulation), damit alle Namen auftauchen.
        let registry = AssistantToolRegistry.standard(kalkulationsEngine: StubKalkEngine())
        for name in registry.toolNames {
            #expect(AssistantToolManifest.toolToManifestID[name] != nil,
                    "Registriertes Tool '\(name)' hat keine Manifest-Zuordnung — Map ergänzen")
        }
    }

    @Test func konkreteZuordnungUndUmbrellaFallback() {
        #expect(AssistantToolManifest.manifestID(forTool: "search_gmail") == "GMAIL_SEARCH")
        #expect(AssistantToolManifest.manifestID(forTool: "schaetze_projekt") == "KALKULATION_LOCAL")
        #expect(AssistantToolManifest.manifestID(forTool: "noch_kein_tool") == "ASSISTANT_TOOL_CALL")
    }
}

// Minimaler Engine-Stub nur für die Registry-Vollständigkeit (kein echtes Rechnen).
private final class StubKalkEngine: KalkulationsEngineProviding, @unchecked Sendable {
    func schaetze(projektID: String, freitext: String) async throws -> KostenSchaetzung {
        KostenSchaetzung(schaetzungsID: "stub", projektID: projektID,
                         minNetto: 0, maxNetto: 0, mitteNetto: 0,
                         confidence: 0, evidenceCount: 0,
                         kostenboden: 0, kostenbodenRatio: 0, topEvidences: [])
    }
    func geraetepreis(suchbegriff: String) async -> Double? { nil }
    func importPDF(driveFileID: String, projektID: String) async throws {}
    func recordAdjustment(schaetzungsID: String, faktor: Double, grund: String, lernen: Bool) async throws {}
    func lernUebersicht() async throws -> KalkulationsLernStand {
        KalkulationsLernStand(sessions: 0, adjustments: 0, outliers: 0, aktiveFaktoren: [], kandidaten: [])
    }
    func promote(candidateID: String) async throws {}
}
