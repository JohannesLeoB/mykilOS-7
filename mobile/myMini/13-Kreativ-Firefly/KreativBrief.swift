import Foundation
import Observation

/// Ein Kreativ-Brief je Projekt — die "Zutaten" fuer einen Firefly-Render
/// (#34/#46/#47): welches Bestandsfoto, welcher Stil, welche Materialien/
/// Farben, welche Elemente. Der `FireflyPromptKomponist` baut daraus den
/// fertigen Render-Prompt. Lokal gespeichert, neustart-fest.
struct KreativBrief: Identifiable, Codable, Hashable {
    let id: UUID
    let projectNumber: String
    let projectTitel: String
    /// Dateiname eines Feld-Fotos (Bestandsaufnahme) als Firefly-Leinwand.
    var bestandsfotoDateiname: String?
    /// Optionaler Stil-Anker aus der Referenzkuechen-Galerie (Name + Foto)
    /// — "so in etwa, das ist unser Stil". Optionals sind rueckwaerts-
    /// kompatibel: der synthetisierte Decoder liest fehlende Schluessel als nil.
    var referenzName: String?
    var referenzFotoDateiname: String?
    var stil: String
    var materialFarbe: String
    var elemente: String
    var zusatz: String
    var erstelltAm: Date

    init(
        id: UUID = UUID(),
        projectNumber: String,
        projectTitel: String,
        bestandsfotoDateiname: String? = nil,
        referenzName: String? = nil,
        referenzFotoDateiname: String? = nil,
        stil: String = "",
        materialFarbe: String = "",
        elemente: String = "",
        zusatz: String = "",
        erstelltAm: Date = Date()
    ) {
        self.id = id
        self.projectNumber = projectNumber
        self.projectTitel = projectTitel
        self.bestandsfotoDateiname = bestandsfotoDateiname
        self.referenzName = referenzName
        self.referenzFotoDateiname = referenzFotoDateiname
        self.stil = stil
        self.materialFarbe = materialFarbe
        self.elemente = elemente
        self.zusatz = zusatz
        self.erstelltAm = erstelltAm
    }
}

@Observable
final class KreativBriefStore {
    private(set) var briefs: [KreativBrief] = []
    private let fileURL: URL

    init(documentsURL: URL? = nil) {
        let documents = documentsURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documents.appendingPathComponent("kreativbriefs.json")
        if let d = try? Data(contentsOf: fileURL),
           let b = try? JSONDecoder().decode([KreativBrief].self, from: d) {
            briefs = b
        }
    }

    func sichern(_ brief: KreativBrief) throws {
        var next = briefs
        if let i = next.firstIndex(where: { $0.id == brief.id }) { next[i] = brief } else { next.append(brief) }
        try schreibe(next)
        briefs = next
    }

    func entfernen(_ id: UUID) throws {
        var next = briefs
        next.removeAll { $0.id == id }
        try schreibe(next)
        briefs = next
    }

    private func schreibe(_ briefs: [KreativBrief]) throws {
        let data = try JSONEncoder().encode(briefs)
        try data.write(to: fileURL, options: .atomic)
    }
}
