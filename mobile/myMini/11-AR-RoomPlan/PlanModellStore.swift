import Foundation

enum PlanModellError: Error, LocalizedError {
    case writeFailed(String)
    case zugriffVerweigert

    var errorDescription: String? {
        switch self {
        case .writeFailed(let detail): return "Planmodell nicht speicherbar: \(detail)"
        case .zugriffVerweigert: return "Zugriff auf die gewählte Datei wurde verweigert."
        }
    }
}

/// Gleiches Zwei-Datei-Muster wie `RoomPlanStore` — USDZ-Dateien in
/// `Documents/PlanModelle/`, Manifest (`planmodelle.json`) nur Metadaten.
@Observable
final class PlanModellStore {
    private(set) var modelle: [PlanModell] = []
    private(set) var loadError: String?

    private let manifestURL: URL
    private let ordnerURL: URL

    init(documentsURL: URL? = nil) {
        let documents = documentsURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.manifestURL = documents.appendingPathComponent("planmodelle.json")
        self.ordnerURL = documents.appendingPathComponent("PlanModelle", isDirectory: true)
        try? FileManager.default.createDirectory(at: ordnerURL, withIntermediateDirectories: true)
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            modelle = []
            loadError = nil
            return
        }
        do {
            let data = try Data(contentsOf: manifestURL)
            modelle = try JSONDecoder().decode([PlanModell].self, from: data)
            loadError = nil
        } catch {
            loadError = "Planmodelle nicht lesbar: \(error.localizedDescription)"
        }
    }

    func dateiURL(fuer modell: PlanModell) -> URL {
        ordnerURL.appendingPathComponent(modell.dateiname)
    }

    /// Kopiert eine per Dateien-App/AirDrop gewählte USDZ in die eigene
    /// Ablage. `.fileImporter`-URLs sind security-scoped — ohne
    /// `startAccessingSecurityScopedResource` schlägt das Kopieren bei
    /// Dateien außerhalb der eigenen Sandbox (iCloud Drive, "Auf meinem
    /// iPhone") kommentarlos fehl.
    @discardableResult
    func importieren(quelle: URL, projectNumber: String, projectTitel: String) throws -> PlanModell {
        let hatZugriff = quelle.startAccessingSecurityScopedResource()
        defer {
            if hatZugriff { quelle.stopAccessingSecurityScopedResource() }
        }

        let dateiname = "\(UUID().uuidString).usdz"
        let zielURL = ordnerURL.appendingPathComponent(dateiname)
        do {
            try FileManager.default.copyItem(at: quelle, to: zielURL)
        } catch {
            throw PlanModellError.writeFailed(error.localizedDescription)
        }

        let eintrag = PlanModell(
            dateiname: dateiname,
            anzeigeName: quelle.deletingPathExtension().lastPathComponent,
            projectNumber: projectNumber,
            projectTitel: projectTitel
        )
        var next = modelle
        next.append(eintrag)
        do {
            try schreibeManifest(next)
        } catch {
            try? FileManager.default.removeItem(at: zielURL)
            throw error
        }
        modelle = next
        return eintrag
    }

    func remove(_ id: UUID) throws {
        guard let index = modelle.firstIndex(where: { $0.id == id }) else { return }
        let dateiname = modelle[index].dateiname
        var next = modelle
        next.remove(at: index)
        try schreibeManifest(next)
        modelle = next
        try? FileManager.default.removeItem(at: ordnerURL.appendingPathComponent(dateiname))
    }

    private func schreibeManifest(_ modelle: [PlanModell]) throws {
        do {
            let data = try JSONEncoder().encode(modelle)
            try data.write(to: manifestURL, options: .atomic)
        } catch {
            throw PlanModellError.writeFailed(error.localizedDescription)
        }
    }
}
