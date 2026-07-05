import Foundation
import Observation
import UIKit

/// Eine gebaute Referenzkueche aus dem Studio-Portfolio — die "Stil-DNA"
/// (Johannes, 04.07.): "So in etwa soll's sein, das ist unser Stil." Dient
/// als Firefly-Stilreferenz: das Foto der fertig gebauten Kueche + ein Name
/// + Stil-Tag. Beim Render-Brief wird eine davon als Anker gewaehlt, die
/// projektspezifischen Anpassungen kommen obendrauf (spaeter aus dem
/// geplanten Material-Moodboard-Katalog je Projekt).
struct Referenzkueche: Identifiable, Codable, Hashable {
    let id: UUID
    let dateiname: String
    var name: String
    var stil: String
    var notiz: String
    let erfasstAm: Date

    init(id: UUID = UUID(), dateiname: String, name: String, stil: String = "", notiz: String = "", erfasstAm: Date = Date()) {
        self.id = id
        self.dateiname = dateiname
        self.name = name
        self.stil = stil
        self.notiz = notiz
        self.erfasstAm = erfasstAm
    }
}

/// Galerie-Store, gleiches Zwei-Datei-Muster wie `FeldFotoStore`: Bilder als
/// JPEG in `Documents/Referenzkuechen/`, Metadaten im Manifest.
@Observable
final class ReferenzkuechenStore {
    private(set) var kuechen: [Referenzkueche] = []
    private(set) var loadError: String?

    private let manifestURL: URL
    private let ordnerURL: URL

    init(documentsURL: URL? = nil) {
        let documents = documentsURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.manifestURL = documents.appendingPathComponent("referenzkuechen.json")
        self.ordnerURL = documents.appendingPathComponent("Referenzkuechen", isDirectory: true)
        try? FileManager.default.createDirectory(at: ordnerURL, withIntermediateDirectories: true)
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: manifestURL.path) else { kuechen = []; return }
        do {
            let data = try Data(contentsOf: manifestURL)
            kuechen = try JSONDecoder().decode([Referenzkueche].self, from: data)
            loadError = nil
        } catch {
            loadError = "Referenz-Galerie nicht lesbar: \(error.localizedDescription)"
        }
    }

    func bildURL(fuer kueche: Referenzkueche) -> URL {
        ordnerURL.appendingPathComponent(kueche.dateiname)
    }

    @discardableResult
    func aufnehmen(bild: UIImage, name: String, stil: String, notiz: String) throws -> Referenzkueche {
        guard let jpeg = bild.jpegData(compressionQuality: 0.85) else {
            throw FeldFotoError.bildKonnteNichtGespeichertWerden
        }
        let dateiname = "\(UUID().uuidString).jpg"
        try jpeg.write(to: ordnerURL.appendingPathComponent(dateiname), options: .atomic)
        let eintrag = Referenzkueche(dateiname: dateiname, name: name, stil: stil, notiz: notiz)
        var next = kuechen
        next.append(eintrag)
        do {
            try schreibeManifest(next)
        } catch {
            try? FileManager.default.removeItem(at: ordnerURL.appendingPathComponent(dateiname))
            throw error
        }
        kuechen = next
        return eintrag
    }

    func entfernen(_ id: UUID) throws {
        guard let index = kuechen.firstIndex(where: { $0.id == id }) else { return }
        let dateiname = kuechen[index].dateiname
        var next = kuechen
        next.remove(at: index)
        try schreibeManifest(next)
        kuechen = next
        try? FileManager.default.removeItem(at: ordnerURL.appendingPathComponent(dateiname))
    }

    private func schreibeManifest(_ kuechen: [Referenzkueche]) throws {
        let data = try JSONEncoder().encode(kuechen)
        try data.write(to: manifestURL, options: .atomic)
    }
}
