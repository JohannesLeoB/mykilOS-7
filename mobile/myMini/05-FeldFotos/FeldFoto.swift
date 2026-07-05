import Foundation

/// Die Kanon-Zielschublade aus Johannes' ★3-Design: Rohbau→„06 Fotos
/// Baustelle", Bestand→„02", Mangel→„09". Feste, kleine Auswahl —
/// nie geraten, immer vom Menschen bestätigt.
enum KanonZiel: String, Codable, CaseIterable, Identifiable {
    case bestand
    case rohbau
    case mangel

    var id: String { rawValue }

    var titel: String {
        switch self {
        case .bestand: return "Bestand"
        case .rohbau: return "Rohbau"
        case .mangel: return "Mangel"
        }
    }

    var ordner: String {
        switch self {
        case .bestand: return "02"
        case .rohbau: return "06 Fotos Baustelle"
        case .mangel: return "09"
        }
    }
}

/// Ein Feld-Foto, lokal auf dem Gerät geparkt — echt, neustart-fest.
/// EXIF-Zeit + Standort sind die „gratis Beweiskette" für Abnahmen
/// (Johannes' ★3-Design). Bild selbst liegt als Datei in
/// `Documents/FeldFotos/`, hier nur der Dateiname + Metadaten.
struct FeldFoto: Identifiable, Codable {
    let id: UUID
    let dateiname: String
    let projectNumber: String
    let projectTitel: String
    let kanonZiel: KanonZiel
    let aufgenommenAm: Date
    var breitengrad: Double?
    var laengengrad: Double?
    var driveFileID: String?
    var syncedAt: Date?
    /// Förderungs-Beweispaket (KfW/BAFA, #52): markiert ein Feld-Foto als
    /// Teil eines datierten Vorher/Nachher-Belegs. Nur Tagging + Export,
    /// bewusst ohne den ARWorldMap-Rückkehr-Teil der Idee.
    var foerderrelevant: Bool = false

    init(
        id: UUID = UUID(),
        dateiname: String,
        projectNumber: String,
        projectTitel: String,
        kanonZiel: KanonZiel,
        aufgenommenAm: Date = Date(),
        breitengrad: Double? = nil,
        laengengrad: Double? = nil,
        driveFileID: String? = nil,
        syncedAt: Date? = nil,
        foerderrelevant: Bool = false
    ) {
        self.id = id
        self.dateiname = dateiname
        self.projectNumber = projectNumber
        self.projectTitel = projectTitel
        self.kanonZiel = kanonZiel
        self.aufgenommenAm = aufgenommenAm
        self.breitengrad = breitengrad
        self.laengengrad = laengengrad
        self.driveFileID = driveFileID
        self.syncedAt = syncedAt
        self.foerderrelevant = foerderrelevant
    }

    private enum CodingKeys: String, CodingKey {
        case id, dateiname, projectNumber, projectTitel, kanonZiel, aufgenommenAm
        case breitengrad, laengengrad, driveFileID, syncedAt, foerderrelevant
    }

    /// Handgeschrieben statt synthetisiert: `foerderrelevant` ist neu, aber
    /// bereits gespeicherte `feldfotos.json`-Dateien auf Johannes' Gerät
    /// kennen das Feld noch nicht. Ein synthetisierter Decoder würde beim
    /// fehlenden Schlüssel abstürzen (`keyNotFound`) statt einen Default zu
    /// nehmen — `decodeIfPresent` macht das Feld rückwärtskompatibel.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        dateiname = try container.decode(String.self, forKey: .dateiname)
        projectNumber = try container.decode(String.self, forKey: .projectNumber)
        projectTitel = try container.decode(String.self, forKey: .projectTitel)
        kanonZiel = try container.decode(KanonZiel.self, forKey: .kanonZiel)
        aufgenommenAm = try container.decode(Date.self, forKey: .aufgenommenAm)
        breitengrad = try container.decodeIfPresent(Double.self, forKey: .breitengrad)
        laengengrad = try container.decodeIfPresent(Double.self, forKey: .laengengrad)
        driveFileID = try container.decodeIfPresent(String.self, forKey: .driveFileID)
        syncedAt = try container.decodeIfPresent(Date.self, forKey: .syncedAt)
        foerderrelevant = try container.decodeIfPresent(Bool.self, forKey: .foerderrelevant) ?? false
    }
}
