import Foundation

// MARK: - WarenkorbEintrag
// Ein Warenkorb-Eintrag aus der Airtable-Tabelle „Warenkörbe" (tblhZujm3Ig6hlafX,
// Base appdxTeT6bhSBmwx5). Foundation-only — kein SwiftUI, kein GRDB.
//
// Read-only aus der Liste; Schreiben nur append-only über CartStore.
// Autor-Feld: noch nicht in der Tabelle vorhanden (geplant für Backend/Daniel).
public struct WarenkorbEintrag: Sendable, Equatable, Identifiable {
    /// Airtable-Record-ID (stabiler Primärschlüssel).
    public let id: String
    /// Menschenlesbarer Name des Warenkorbs.
    public let bezeichnung: String
    /// Projektname (optional, aus Lookup-Feld).
    public let projekt: String?
    /// Status: "Aktuell" oder "Archiviert".
    public let status: String
    /// Versionsnummer (Integer, steigt mit jedem Speichern).
    public let version: Int
    /// Datum der Erstellung (aus Airtable-Datumsfeld).
    public let erstelltAm: Date?
    /// Anzahl der Positionen.
    public let anzahlPositionen: Int?
    /// Gesamtsumme EK netto (€).
    public let gesamtEK: Double?
    /// Gesamtsumme VK netto (€).
    public let gesamtVK: Double?
    /// Positionen als JSON-String (für Wiederherstellung in den Warenkorb).
    public let positionenJSON: String?

    public var istAktuell: Bool { status == "Aktuell" }

    public init(
        id: String,
        bezeichnung: String,
        projekt: String? = nil,
        status: String = "Aktuell",
        version: Int = 1,
        erstelltAm: Date? = nil,
        anzahlPositionen: Int? = nil,
        gesamtEK: Double? = nil,
        gesamtVK: Double? = nil,
        positionenJSON: String? = nil
    ) {
        self.id = id
        self.bezeichnung = bezeichnung
        self.projekt = projekt
        self.status = status
        self.version = version
        self.erstelltAm = erstelltAm
        self.anzahlPositionen = anzahlPositionen
        self.gesamtEK = gesamtEK
        self.gesamtVK = gesamtVK
        self.positionenJSON = positionenJSON
    }

    /// Versucht, die Positionen aus dem JSON-String zu dekodieren.
    /// Gibt nil zurück, wenn kein JSON vorhanden oder Dekodierung fehlschlägt.
    public func decodedItems() -> [WarenkorbItem]? {
        guard let json = positionenJSON,
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([WarenkorbItem].self, from: data)
    }
}
