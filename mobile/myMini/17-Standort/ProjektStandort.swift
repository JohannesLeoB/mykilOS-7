import Foundation

/// Ein von Hand gemerkter Projekt-Standort — es gibt keine Adress-Tabelle
/// in der Registry, also lernt der Satellit selbst: einmal vor Ort "Diesen
/// Ort merken" antippen, danach erkennt der Standort-Wächter diesen Punkt
/// wieder. Kein Reverse-Geocoding nötig — das Projekt ist beim Merken schon
/// explizit gewählt, nie geraten.
struct ProjektStandort: Identifiable, Codable, Hashable {
    let id: UUID
    let projectNumber: String
    let projectTitel: String
    let breitengrad: Double
    let laengengrad: Double
    let radiusMeter: Double
    let gespeichertAm: Date

    init(
        id: UUID = UUID(),
        projectNumber: String,
        projectTitel: String,
        breitengrad: Double,
        laengengrad: Double,
        radiusMeter: Double = 150,
        gespeichertAm: Date = Date()
    ) {
        self.id = id
        self.projectNumber = projectNumber
        self.projectTitel = projectTitel
        self.breitengrad = breitengrad
        self.laengengrad = laengengrad
        self.radiusMeter = radiusMeter
        self.gespeichertAm = gespeichertAm
    }
}
