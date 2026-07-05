import Foundation
import UIKit

enum FeldFotoError: Error, LocalizedError {
    case writeFailed(String)
    case bildKonnteNichtGespeichertWerden

    var errorDescription: String? {
        switch self {
        case .writeFailed(let detail): return "Feld-Fotos nicht speicherbar: \(detail)"
        case .bildKonnteNichtGespeichertWerden: return "Bild konnte nicht als Datei gespeichert werden."
        }
    }
}

/// Gleiches Muster wie `PostboxStore` — echt, neustart-fest, throws-basiert.
/// Bilder liegen als JPEG-Dateien in `Documents/FeldFotos/`, dieses Manifest
/// (`Documents/feldfotos.json`) hält nur die Metadaten. Zwei Dateien pro
/// Foto, ein Manifest-Eintrag — kein Bild-Blob im JSON (bliebe sonst schnell
/// riesig und langsam zu laden).
@Observable
final class FeldFotoStore {
    private(set) var fotos: [FeldFoto] = []
    private(set) var loadError: String?

    private let manifestURL: URL
    private let ordnerURL: URL

    init(documentsURL: URL? = nil) {
        let documents = documentsURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.manifestURL = documents.appendingPathComponent("feldfotos.json")
        self.ordnerURL = documents.appendingPathComponent("FeldFotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: ordnerURL, withIntermediateDirectories: true)
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            fotos = []
            loadError = nil
            return
        }
        do {
            let data = try Data(contentsOf: manifestURL)
            fotos = try JSONDecoder().decode([FeldFoto].self, from: data)
            loadError = nil
        } catch {
            loadError = "Feld-Fotos nicht lesbar: \(error.localizedDescription)"
        }
    }

    func bildURL(fuer foto: FeldFoto) -> URL {
        ordnerURL.appendingPathComponent(foto.dateiname)
    }

    /// Speichert das Bild als JPEG-Datei und legt einen Manifest-Eintrag an.
    @discardableResult
    func aufnehmen(
        bild: UIImage,
        projectNumber: String,
        projectTitel: String,
        kanonZiel: KanonZiel,
        aufgenommenAm: Date,
        breitengrad: Double?,
        laengengrad: Double?,
        foerderrelevant: Bool = false
    ) throws -> FeldFoto {
        // Near-lossless: volle Pixelaufloesung, nur minimale JPEG-Kompression
        // (Doku-/Beweisfotos sollen keine sichtbare Qualitaet verlieren).
        guard let jpeg = bild.jpegData(compressionQuality: 0.95) else {
            throw FeldFotoError.bildKonnteNichtGespeichertWerden
        }
        let dateiname = "\(UUID().uuidString).jpg"
        let zielURL = ordnerURL.appendingPathComponent(dateiname)
        do {
            try jpeg.write(to: zielURL, options: .atomic)
        } catch {
            throw FeldFotoError.writeFailed(error.localizedDescription)
        }

        let eintrag = FeldFoto(
            dateiname: dateiname,
            projectNumber: projectNumber,
            projectTitel: projectTitel,
            kanonZiel: kanonZiel,
            aufgenommenAm: aufgenommenAm,
            breitengrad: breitengrad,
            laengengrad: laengengrad,
            foerderrelevant: foerderrelevant
        )
        var next = fotos
        next.append(eintrag)
        do {
            try schreibeManifest(next)
        } catch {
            try? FileManager.default.removeItem(at: zielURL)
            throw error
        }
        fotos = next
        return eintrag
    }

    func markSynced(_ id: UUID, driveFileID: String) throws {
        guard let index = fotos.firstIndex(where: { $0.id == id }) else { return }
        var next = fotos
        next[index].syncedAt = Date()
        next[index].driveFileID = driveFileID
        try schreibeManifest(next)
        fotos = next
    }

    /// Nachträgliches Markieren fürs Förderungs-Beweispaket (#52) — auch
    /// wieder entfernbar, falls versehentlich gesetzt.
    func setzeFoerderrelevant(_ id: UUID, foerderrelevant: Bool) throws {
        guard let index = fotos.firstIndex(where: { $0.id == id }) else { return }
        var next = fotos
        next[index].foerderrelevant = foerderrelevant
        try schreibeManifest(next)
        fotos = next
    }

    /// Nur unsynchronisierte Fotos lassen sich löschen — Bild UND Manifest-Zeile.
    func remove(_ id: UUID) throws {
        guard let index = fotos.firstIndex(where: { $0.id == id }), fotos[index].syncedAt == nil else { return }
        let dateiname = fotos[index].dateiname
        var next = fotos
        next.remove(at: index)
        try schreibeManifest(next)
        fotos = next
        try? FileManager.default.removeItem(at: ordnerURL.appendingPathComponent(dateiname))
    }

    private func schreibeManifest(_ fotos: [FeldFoto]) throws {
        do {
            let data = try JSONEncoder().encode(fotos)
            try data.write(to: manifestURL, options: .atomic)
        } catch {
            throw FeldFotoError.writeFailed(error.localizedDescription)
        }
    }
}
