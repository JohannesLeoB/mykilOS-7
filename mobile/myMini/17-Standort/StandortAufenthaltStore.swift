import Foundation
import Observation

enum StandortAufenthaltError: Error, LocalizedError {
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .writeFailed(let detail): return "Aufenthalte nicht speicherbar: \(detail)"
        }
    }
}

/// Gleiches Muster wie `PostboxStore` — echt, neustart-fest, throws-basiert.
/// Reine on-device Ablage, verlässt das Gerät nie (kein Sync-Kanal, kein
/// Kalender-Abgleich — das bräuchte Google-OAuth wie #61 und bleibt draußen).
@Observable
final class StandortAufenthaltStore {
    private(set) var aufenthalte: [StandortAufenthalt] = []
    private(set) var loadError: String?

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.fileURL = documents.appendingPathComponent("standort_aufenthalte.json")
        }
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            aufenthalte = []
            loadError = nil
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            aufenthalte = try JSONDecoder().decode([StandortAufenthalt].self, from: data)
            loadError = nil
        } catch {
            loadError = "Aufenthalte nicht lesbar: \(error.localizedDescription)"
        }
    }

    /// Nur EIN offener Aufenthalt je Projekt gleichzeitig — ein zweites
    /// "Betreten"-Ereignis für dasselbe Projekt (z. B. doppelt ausgelöst
    /// durch GPS-Schwankung am Rand des Radius) öffnet keinen neuen Eintrag.
    @discardableResult
    func betreten(projectNumber: String, projectTitel: String) throws -> StandortAufenthalt? {
        guard !aufenthalte.contains(where: { $0.projectNumber == projectNumber && $0.verlassenAm == nil }) else {
            return nil
        }
        let eintrag = StandortAufenthalt(projectNumber: projectNumber, projectTitel: projectTitel)
        var next = aufenthalte
        next.append(eintrag)
        try write(next)
        aufenthalte = next
        return eintrag
    }

    func verlassen(projectNumber: String) throws {
        guard let index = aufenthalte.lastIndex(where: { $0.projectNumber == projectNumber && $0.verlassenAm == nil }) else {
            return
        }
        var next = aufenthalte
        next[index].verlassenAm = Date()
        try write(next)
        aufenthalte = next
    }

    func alsErledigtMarkieren(_ id: UUID) throws {
        guard let index = aufenthalte.firstIndex(where: { $0.id == id }) else { return }
        var next = aufenthalte
        next[index].erledigt = true
        try write(next)
        aufenthalte = next
    }

    /// Abgeschlossene, noch unbehandelte Aufenthalte — nur die werden als
    /// Vorschlags-Karte gezeigt (laufende Aufenthalte haben noch keine
    /// verlässliche Dauer).
    var offeneVorschlaege: [StandortAufenthalt] {
        aufenthalte.filter { $0.verlassenAm != nil && !$0.erledigt }
    }

    private func write(_ aufenthalte: [StandortAufenthalt]) throws {
        do {
            let data = try JSONEncoder().encode(aufenthalte)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw StandortAufenthaltError.writeFailed(error.localizedDescription)
        }
    }
}
