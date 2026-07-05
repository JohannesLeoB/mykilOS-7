import Foundation

enum RoomPlanStoreError: Error, LocalizedError {
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .writeFailed(let detail): return "Raumscan nicht speicherbar: \(detail)"
        }
    }
}

/// Gleiches Zwei-Datei-Muster wie `FeldFotoStore` — echt, neustart-fest,
/// throws-basiert. USDZ-Dateien liegen in `Documents/RoomPlan/`, dieses
/// Manifest (`Documents/roomplan_aufnahmen.json`) hält nur die Metadaten.
@Observable
final class RoomPlanStore {
    private(set) var aufnahmen: [RoomPlanAufnahme] = []
    private(set) var loadError: String?

    private let manifestURL: URL
    private let ordnerURL: URL

    init(documentsURL: URL? = nil) {
        let documents = documentsURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.manifestURL = documents.appendingPathComponent("roomplan_aufnahmen.json")
        self.ordnerURL = documents.appendingPathComponent("RoomPlan", isDirectory: true)
        try? FileManager.default.createDirectory(at: ordnerURL, withIntermediateDirectories: true)
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            aufnahmen = []
            loadError = nil
            return
        }
        do {
            let data = try Data(contentsOf: manifestURL)
            aufnahmen = try JSONDecoder().decode([RoomPlanAufnahme].self, from: data)
            loadError = nil
        } catch {
            loadError = "Raumscans nicht lesbar: \(error.localizedDescription)"
        }
    }

    func dateiURL(fuer aufnahme: RoomPlanAufnahme) -> URL {
        ordnerURL.appendingPathComponent(aufnahme.dateiname)
    }

    /// Kopiert die von RoomPlan exportierte USDZ-Datei in die eigene Ablage
    /// und legt einen Manifest-Eintrag an — die Quelldatei liegt vorher in
    /// einem temporären Verzeichnis (RoomPlan-Export-Ziel) und wird hier
    /// nicht mehr gebraucht.
    @discardableResult
    func aufnehmen(usdzQuelle: URL, projectNumber: String, projectTitel: String) throws -> RoomPlanAufnahme {
        let dateiname = "\(UUID().uuidString).usdz"
        let zielURL = ordnerURL.appendingPathComponent(dateiname)
        do {
            try FileManager.default.copyItem(at: usdzQuelle, to: zielURL)
        } catch {
            throw RoomPlanStoreError.writeFailed(error.localizedDescription)
        }

        let eintrag = RoomPlanAufnahme(dateiname: dateiname, projectNumber: projectNumber, projectTitel: projectTitel)
        var next = aufnahmen
        next.append(eintrag)
        do {
            try schreibeManifest(next)
        } catch {
            try? FileManager.default.removeItem(at: zielURL)
            throw error
        }
        aufnahmen = next
        return eintrag
    }

    func remove(_ id: UUID) throws {
        guard let index = aufnahmen.firstIndex(where: { $0.id == id }) else { return }
        let dateiname = aufnahmen[index].dateiname
        var next = aufnahmen
        next.remove(at: index)
        try schreibeManifest(next)
        aufnahmen = next
        try? FileManager.default.removeItem(at: ordnerURL.appendingPathComponent(dateiname))
    }

    private func schreibeManifest(_ aufnahmen: [RoomPlanAufnahme]) throws {
        do {
            let data = try JSONEncoder().encode(aufnahmen)
            try data.write(to: manifestURL, options: .atomic)
        } catch {
            throw RoomPlanStoreError.writeFailed(error.localizedDescription)
        }
    }
}
