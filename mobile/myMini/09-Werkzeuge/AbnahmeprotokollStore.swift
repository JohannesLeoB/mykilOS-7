import Foundation
import UIKit

enum AbnahmeprotokollError: Error, LocalizedError {
    case writeFailed(String)
    case bildKonnteNichtGespeichertWerden

    var errorDescription: String? {
        switch self {
        case .writeFailed(let detail): return "Abnahmeprotokoll nicht speicherbar: \(detail)"
        case .bildKonnteNichtGespeichertWerden: return "Bild konnte nicht als Datei gespeichert werden."
        }
    }
}

/// Gleiches Zwei-Datei-Muster wie `FeldFotoStore` — echt, neustart-fest,
/// throws-basiert. Foto ist optional, Text ist Pflicht (Diktat oder Tippen).
/// Kein Sync-Kanal in v0, daher bleibt Löschen immer erlaubt.
@Observable
final class AbnahmeprotokollStore {
    private(set) var eintraege: [MangelEintrag] = []
    private(set) var loadError: String?

    private let manifestURL: URL
    private let ordnerURL: URL

    init(documentsURL: URL? = nil) {
        let documents = documentsURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.manifestURL = documents.appendingPathComponent("abnahmeprotokoll.json")
        self.ordnerURL = documents.appendingPathComponent("AbnahmeprotokollFotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: ordnerURL, withIntermediateDirectories: true)
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            eintraege = []
            loadError = nil
            return
        }
        do {
            let data = try Data(contentsOf: manifestURL)
            eintraege = try JSONDecoder().decode([MangelEintrag].self, from: data)
            loadError = nil
        } catch {
            loadError = "Abnahmeprotokoll nicht lesbar: \(error.localizedDescription)"
        }
    }

    func bildURL(fuer eintrag: MangelEintrag) -> URL? {
        guard let dateiname = eintrag.fotoDateiname else { return nil }
        return ordnerURL.appendingPathComponent(dateiname)
    }

    @discardableResult
    func hinzufuegen(projectNumber: String, projectTitel: String, text: String, foto: UIImage?) throws -> MangelEintrag {
        var dateiname: String?
        var geschriebeneDatei: URL?
        if let foto {
            guard let jpeg = foto.jpegData(compressionQuality: 0.85) else {
                throw AbnahmeprotokollError.bildKonnteNichtGespeichertWerden
            }
            let name = "\(UUID().uuidString).jpg"
            let zielURL = ordnerURL.appendingPathComponent(name)
            do {
                try jpeg.write(to: zielURL, options: .atomic)
            } catch {
                throw AbnahmeprotokollError.writeFailed(error.localizedDescription)
            }
            dateiname = name
            geschriebeneDatei = zielURL
        }

        let eintrag = MangelEintrag(
            projectNumber: projectNumber,
            projectTitel: projectTitel,
            text: text,
            fotoDateiname: dateiname
        )
        var next = eintraege
        next.append(eintrag)
        do {
            try schreibeManifest(next)
        } catch {
            if let geschriebeneDatei {
                try? FileManager.default.removeItem(at: geschriebeneDatei)
            }
            throw error
        }
        eintraege = next
        return eintrag
    }

    func remove(_ id: UUID) throws {
        guard let index = eintraege.firstIndex(where: { $0.id == id }) else { return }
        let dateiname = eintraege[index].fotoDateiname
        var next = eintraege
        next.remove(at: index)
        try schreibeManifest(next)
        eintraege = next
        if let dateiname {
            try? FileManager.default.removeItem(at: ordnerURL.appendingPathComponent(dateiname))
        }
    }

    private func schreibeManifest(_ eintraege: [MangelEintrag]) throws {
        do {
            let data = try JSONEncoder().encode(eintraege)
            try data.write(to: manifestURL, options: .atomic)
        } catch {
            throw AbnahmeprotokollError.writeFailed(error.localizedDescription)
        }
    }
}
