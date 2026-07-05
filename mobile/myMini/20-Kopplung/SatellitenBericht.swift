import Foundation

/// Phase 3 der Fusion — der Rueckkanal. Der Satellit fasst alles, was er zu
/// einem Projekt im Feld erfasst hat, in einem Bericht zusammen, den das
/// Schiff einlesen kann. So wird aus der Einbahn-Antenne (Schiff -> Satellit,
/// docs/23) eine Zwei-Wege-Fusion: jede Feld-Erfassung findet zurueck in die
/// Projektakte.
///
/// Bewusst als EXPORT (Datei zum Teilen/AirDrop/Drive), nicht als stiller
/// Schreibzugriff ins Schiff - der Mensch schickt den Bericht bewusst raus.
/// Format-Vertrag: docs/24_RUECKKANAL.md.
struct SatellitenBericht: Codable {
    struct Foto: Codable {
        let dateiname: String
        let ziel: String
        let aufgenommenAm: Date
        let breitengrad: Double?
        let laengengrad: Double?
        let foerderrelevant: Bool
        let inDrive: Bool
    }
    struct Scan: Codable { let dateiname: String; let aufgenommenAm: Date }
    struct Vertrag: Codable {
        let vertragsName: String
        let unterzeichner: String
        let unterschriebenAm: Date
        let sha256: String
    }
    struct Anfrage: Codable { let partnerName: String; let geraet: String; let gesendetAm: Date }
    struct Mangel: Codable { let text: String; let erfasstAm: Date }

    let projectNumber: String
    let projectTitel: String
    let erstelltAm: Date
    let quelle = "mykilOS mobile (Satellit)"
    let fotos: [Foto]
    let scans: [Scan]
    let vertraege: [Vertrag]
    let anfragen: [Anfrage]
    let maengel: [Mangel]

    private enum CodingKeys: String, CodingKey {
        case projectNumber, projectTitel, erstelltAm, quelle, fotos, scans, vertraege, anfragen, maengel
    }
}

enum SatellitenBerichtFehler: Error, LocalizedError {
    case schreibenFehlgeschlagen(String)
    var errorDescription: String? {
        switch self {
        case .schreibenFehlgeschlagen(let d): return "Bericht nicht schreibbar: \(d)"
        }
    }
}

extension SatellitenBericht {
    /// Schreibt den Bericht als JSON in eine temporaere Datei und gibt die URL
    /// zum Teilen (AirDrop an den Mac / Upload in den Projekt-Drive) zurueck.
    func alsDatei() throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let daten: Data
        do { daten = try encoder.encode(self) }
        catch { throw SatellitenBerichtFehler.schreibenFehlgeschlagen(error.localizedDescription) }
        let name = "Feldbericht_\(projectNumber).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do { try daten.write(to: url, options: .atomic) }
        catch { throw SatellitenBerichtFehler.schreibenFehlgeschlagen(error.localizedDescription) }
        return url
    }
}
