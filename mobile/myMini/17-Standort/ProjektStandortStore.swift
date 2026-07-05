import Foundation
import Observation

enum ProjektStandortError: Error, LocalizedError {
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .writeFailed(let detail): return "Standort nicht speicherbar: \(detail)"
        }
    }
}

/// Gleiches Muster wie `PostboxStore` — echt, neustart-fest, throws-basiert.
/// Reine on-device Ablage, verlässt das Gerät nie.
@Observable
final class ProjektStandortStore {
    private(set) var orte: [ProjektStandort] = []
    private(set) var loadError: String?

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.fileURL = documents.appendingPathComponent("projektstandorte.json")
        }
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            orte = []
            loadError = nil
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            orte = try JSONDecoder().decode([ProjektStandort].self, from: data)
            loadError = nil
        } catch {
            loadError = "Standorte nicht lesbar: \(error.localizedDescription)"
        }
    }

    @discardableResult
    func merken(_ standort: ProjektStandort) throws -> ProjektStandort {
        var next = orte
        next.removeAll { $0.projectNumber == standort.projectNumber }
        next.append(standort)
        try write(next)
        orte = next
        return standort
    }

    func vergessen(_ id: UUID) throws {
        guard let index = orte.firstIndex(where: { $0.id == id }) else { return }
        var next = orte
        next.remove(at: index)
        try write(next)
        orte = next
    }

    private func write(_ orte: [ProjektStandort]) throws {
        do {
            let data = try JSONEncoder().encode(orte)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw ProjektStandortError.writeFailed(error.localizedDescription)
        }
    }
}
