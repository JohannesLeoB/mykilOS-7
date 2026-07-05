import Foundation
import Observation

enum WareneingangsLogError: Error, LocalizedError {
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .writeFailed(let detail): return "Wareneingangs-Log nicht beschreibbar: \(detail)"
        }
    }
}

/// Gleiches Muster wie `PostboxStore` — echt, neustart-fest, throws-basiert.
@Observable
final class WareneingangsLogStore {
    private(set) var ereignisse: [WareneingangsEreignis] = []
    private(set) var loadError: String?

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.fileURL = documents.appendingPathComponent("wareneingang.json")
        }
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            ereignisse = []
            loadError = nil
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            ereignisse = try JSONDecoder().decode([WareneingangsEreignis].self, from: data)
            loadError = nil
        } catch {
            loadError = "Wareneingangs-Log nicht lesbar: \(error.localizedDescription)"
        }
    }

    @discardableResult
    func append(_ ereignis: WareneingangsEreignis) throws -> WareneingangsEreignis {
        var next = ereignisse
        next.append(ereignis)
        try write(next)
        ereignisse = next
        return ereignis
    }

    /// Kein Sync-Kanal existiert für diesen Log — Löschen bleibt daher immer
    /// erlaubt (anders als Postbox/Feld-Foto, wo ein Sync-Lock greift).
    func remove(_ id: UUID) throws {
        guard let index = ereignisse.firstIndex(where: { $0.id == id }) else { return }
        var next = ereignisse
        next.remove(at: index)
        try write(next)
        ereignisse = next
    }

    private func write(_ ereignisse: [WareneingangsEreignis]) throws {
        do {
            let data = try JSONEncoder().encode(ereignisse)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw WareneingangsLogError.writeFailed(error.localizedDescription)
        }
    }
}
