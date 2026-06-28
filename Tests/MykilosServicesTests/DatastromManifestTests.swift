import Testing
import Foundation

// MARK: - DatastromManifest GATE-Tests (L6)
// Prüft, dass DatastromManifest.json existiert, gültiges JSON ist und
// alle Pflichtfelder (integrationID, name, system, direction, link) enthält.
// Navigiert per #filePath relativ zum Package-Root — kein Bundle nötig.
struct DatastromManifestTests {

    private func manifestURL() throws -> URL {
        // Tests/MykilosServicesTests/<file> → ../../Sources/MykilosApp/Resources/
        let testFile = URL(fileURLWithPath: #filePath)
        let url = testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/MykilosApp/Resources/DatastromManifest.json")
        return url
    }

    @Test func manifestDateiExistiert() throws {
        let url = try manifestURL()
        #expect(FileManager.default.fileExists(atPath: url.path),
                "DatastromManifest.json fehlt unter \(url.path)")
    }

    @Test func manifestIstGueltigesJSON() throws {
        let url = try manifestURL()
        let data = try Data(contentsOf: url)
        let parsed = try JSONSerialization.jsonObject(with: data)
        #expect(parsed is [[String: Any]], "Manifest muss ein JSON-Array von Objekten sein")
    }

    @Test func manifestEnthaeltMindestens3Weichen() throws {
        let url = try manifestURL()
        let data = try Data(contentsOf: url)
        let entries = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]
        #expect(entries.count >= 3, "Manifest hat \(entries.count) Einträge — mindestens 3 erwartet")
    }

    @Test func alleEintraegeHabenIntegrationID() throws {
        let url = try manifestURL()
        let data = try Data(contentsOf: url)
        let entries = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]
        for (i, entry) in entries.enumerated() {
            let id = entry["integrationID"] as? String ?? ""
            #expect(!id.isEmpty, "Eintrag \(i) fehlt integrationID oder sie ist leer")
        }
    }

    @Test func alleEintraegeHabenPflichtfelder() throws {
        let url = try manifestURL()
        let data = try Data(contentsOf: url)
        let entries = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]
        let required = ["integrationID", "name", "system", "direction", "link"]
        for (i, entry) in entries.enumerated() {
            for field in required {
                let value = entry[field] as? String ?? ""
                #expect(!value.isEmpty, "Eintrag \(i) (\(entry["integrationID"] ?? "?")): Feld '\(field)' fehlt oder leer")
            }
        }
    }

    @Test func manifestLinkFormatKorrekt() throws {
        let url = try manifestURL()
        let data = try Data(contentsOf: url)
        let entries = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]
        for entry in entries {
            let id = entry["integrationID"] as? String ?? ""
            let link = entry["link"] as? String ?? ""
            let expected = "mykilos://datastream/\(id)"
            #expect(link == expected,
                    "Link für '\(id)' ist '\(link)', erwartet '\(expected)'")
        }
    }
}
