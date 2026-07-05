import Foundation
import Observation

enum PostboxError: Error, LocalizedError {
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .writeFailed(let detail): return "Postbox nicht beschreibbar: \(detail)"
        }
    }
}

/// Echte lokale Ablage statt Demo-Text. Solange der Airtable-Adapter-Base-
/// Schreibpfad nicht freigeschaltet ist, ist das Gerät selbst die Postbox —
/// jeder bestätigte Fang landet hier, überlebt einen App-Neustart und wartet
/// auf den späteren Sync. Jeder Schreibvorgang `throws` (Persistenz-Regel).
@Observable
final class PostboxStore {
    private(set) var items: [PostboxItem] = []
    private(set) var loadError: String?

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.fileURL = documents.appendingPathComponent("postbox.json")
        }
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            items = []
            loadError = nil
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            items = try JSONDecoder().decode([PostboxItem].self, from: data)
            loadError = nil
        } catch {
            loadError = "Postbox nicht lesbar: \(error.localizedDescription)"
        }
    }

    @discardableResult
    func append(_ item: PostboxItem) throws -> PostboxItem {
        var next = items
        next.append(item)
        try write(next)
        items = next
        return item
    }

    /// Markiert einen Eintrag als erfolgreich in die Adapter-Base synchronisiert.
    /// Der lokale Eintrag bleibt erhalten (kein Löschen) — die Postbox ist ein
    /// Protokoll, kein Durchlauf-Puffer.
    func markSynced(_ id: UUID) throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        var next = items
        next[index].syncedAt = Date()
        try write(next)
        items = next
    }

    /// Entfernt einen verunglückten Fang wieder — nur solange er noch NICHT
    /// synchronisiert ist. Ein schon gesendeter Eintrag bleibt stehen (lokales
    /// Löschen würde den echten Airtable-Record nicht mitlöschen, das wäre
    /// eine irreführende lokale Ansicht).
    func remove(_ id: UUID) throws {
        guard let index = items.firstIndex(where: { $0.id == id }), items[index].syncedAt == nil else { return }
        var next = items
        next.remove(at: index)
        try write(next)
        items = next
    }

    private func write(_ items: [PostboxItem]) throws {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw PostboxError.writeFailed(error.localizedDescription)
        }
    }
}
