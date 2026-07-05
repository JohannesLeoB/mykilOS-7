import Foundation
import Observation

enum ChatHistoryError: Error, LocalizedError {
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .writeFailed(let detail): return "Verlauf nicht speicherbar: \(detail)"
        }
    }
}

/// Gleiches Muster wie `PostboxStore` — echt, neustart-fest statt nur im
/// Speicher. Gerätelokal (`Documents/chatverlauf.json`), kein Sync, kein
/// Server. Jeder Schreibvorgang `throws`.
@Observable
final class ChatHistoryStore {
    private(set) var nachrichten: [ChatMessage] = []
    private(set) var loadError: String?

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.fileURL = documents.appendingPathComponent("chatverlauf.json")
        }
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            nachrichten = []
            loadError = nil
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            nachrichten = try JSONDecoder().decode([ChatMessage].self, from: data)
            loadError = nil
        } catch {
            loadError = "Verlauf nicht lesbar: \(error.localizedDescription)"
        }
    }

    func append(_ nachricht: ChatMessage) throws {
        var next = nachrichten
        next.append(nachricht)
        try write(next)
        nachrichten = next
    }

    func loeschen() throws {
        try write([])
        nachrichten = []
    }

    private func write(_ nachrichten: [ChatMessage]) throws {
        do {
            let data = try JSONEncoder().encode(nachrichten)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw ChatHistoryError.writeFailed(error.localizedDescription)
        }
    }
}
