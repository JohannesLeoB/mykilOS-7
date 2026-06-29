import Testing
import Foundation

// MARK: - DatastromAudit GATE-Tests (L8)
// Prüft, dass alle hardcodierten integrationID-Strings im Produktionscode
// im DatastromManifest.json dokumentiert sind. Tool-Calls werden seit Mandate E
// über AssistantToolManifest auf ihre eigene Manifest-ID gemappt (z. B. search_gmail
// → GMAIL_SEARCH; Cross-Check in AssistantToolManifestTests); ein noch nicht
// gemapptes Tool fällt auf den Umbrella-Eintrag ASSISTANT_TOOL_CALL zurück.
struct DatastromAuditTests {

    // Bekannte dynamische Muster, die NICHT als Literal im Manifest stehen müssen,
    // weil sie durch einen Umbrella-Eintrag dokumentiert sind.
    private static let umbrellaPatterns = ["toolUse.name", "tool.name"]

    private func sourcesRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources")
    }

    private func manifestIDs() throws -> Set<String> {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/MykilosApp/Resources/DatastromManifest.json")
        let data = try Data(contentsOf: url)
        let entries = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]
        return Set(entries.compactMap { $0["integrationID"] as? String })
    }

    private func hardcodedIDs(in root: URL) throws -> [(id: String, file: String, line: Int)] {
        var found: [(id: String, file: String, line: Int)] = []
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: nil) else {
            return found
        }
        for case let url as URL in enumerator {
            guard url.pathExtension == "swift",
                  !url.path.contains("Tests/") else { continue }
            let source = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            for (lineIndex, line) in source.components(separatedBy: "\n").enumerated() {
                // Match: integrationID: "SOME_ID"
                guard line.contains("integrationID:") else { continue }
                let pattern = #/integrationID:\s*"([A-Z0-9_]+)"/#
                if let match = try? pattern.firstMatch(in: line) {
                    found.append((id: String(match.1), file: url.lastPathComponent, line: lineIndex + 1))
                }
            }
        }
        return found
    }

    @Test func alleHardcodiertenIDsImManifest() throws {
        let root = sourcesRoot()
        let manifestIDs = try manifestIDs()
        let hardcoded = try hardcodedIDs(in: root)

        #expect(!hardcoded.isEmpty, "Keine hardcodierten integrationID-Strings gefunden — Audit-Logik prüfen")

        var undocumented: [String] = []
        for entry in hardcoded {
            if !manifestIDs.contains(entry.id) {
                undocumented.append("\(entry.id) (\(entry.file):\(entry.line))")
            }
        }
        #expect(undocumented.isEmpty,
                "Undokumentierte integrationIDs gefunden — ins Manifest eintragen: \(undocumented.joined(separator: ", "))")
    }

    @Test func auditFindetMindestens2HardcodierteIDs() throws {
        let root = sourcesRoot()
        let hardcoded = try hardcodedIDs(in: root)
        #expect(hardcoded.count >= 2,
                "Erwartet mindestens 2 hardcodierte IDs (DRIVE_POLL_OFFERS + AIRTABLE_KUNDEN_PROJEKTE), gefunden: \(hardcoded.count)")
    }
}
