import Foundation
import Observation

/// Neustart-fester Cache des Kunden-Verzeichnisses — einmal geladen, auch
/// offline da. Gleiches JSON-in-Documents-Muster wie alle Stores; der
/// Cache ist nur Spiegel, System-of-Record bleibt Airtable.
@Observable
final class KontakteStore {
    private(set) var kontakte: [KundenKontakt] = []
    private(set) var fehler: String?
    private(set) var laedtGerade = false

    private let fileURL: URL
    private let client = AirtableKundenClient()

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.fileURL = documents.appendingPathComponent("kontakte_cache.json")
        }
        ladeCache()
    }

    private func ladeCache() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let geladen = try? JSONDecoder().decode([KundenKontakt].self, from: data) else { return }
        kontakte = geladen
    }

    @MainActor
    func aktualisieren() async {
        fehler = nil
        laedtGerade = true
        defer { laedtGerade = false }
        do {
            let frisch = try await client.ladeAlle()
            let data = try JSONEncoder().encode(frisch)
            try data.write(to: fileURL, options: .atomic)
            kontakte = frisch
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }
}
