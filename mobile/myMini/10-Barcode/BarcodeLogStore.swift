import Foundation
import Observation

enum BarcodeLogError: Error, LocalizedError {
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .writeFailed(let detail): return "Scan-Log nicht beschreibbar: \(detail)"
        }
    }
}

/// Echte lokale Ablage aller Scan-Treffer — neustart-fest, append-only.
/// Kein Sync, kein Abgleich gegen Schiffsdaten (siehe `BarcodeTreffer`).
@Observable
final class BarcodeLogStore {
    private(set) var treffer: [BarcodeTreffer] = []
    private(set) var loadError: String?

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.fileURL = documents.appendingPathComponent("barcode_log.json")
        }
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            treffer = []
            loadError = nil
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            treffer = try JSONDecoder().decode([BarcodeTreffer].self, from: data)
            loadError = nil
        } catch {
            loadError = "Scan-Log nicht lesbar: \(error.localizedDescription)"
        }
    }

    @discardableResult
    func append(_ eintrag: BarcodeTreffer) throws -> BarcodeTreffer {
        var next = treffer
        next.append(eintrag)
        try write(next)
        treffer = next
        return eintrag
    }

    func remove(_ id: UUID) throws {
        guard let index = treffer.firstIndex(where: { $0.id == id }) else { return }
        var next = treffer
        next.remove(at: index)
        try write(next)
        treffer = next
    }

    private func write(_ treffer: [BarcodeTreffer]) throws {
        do {
            let data = try JSONEncoder().encode(treffer)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw BarcodeLogError.writeFailed(error.localizedDescription)
        }
    }
}
