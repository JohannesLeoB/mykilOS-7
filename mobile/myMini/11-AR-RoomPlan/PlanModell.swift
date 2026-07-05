import Foundation

/// Ein importiertes 3D-Planungsmodell (#38, Stufe 1) — die USDZ kommt aus
/// VectorWorks (Export → Reality Converter → USDZ, Johannes' Seite der
/// Pipeline) per AirDrop/Dateien-App aufs iPhone. Die App zeigt sie über
/// AR Quick Look im echten Raum — frei platzierbar, KEINE automatische
/// Ausrichtung am Raum (das wäre Stufe 2, bewusst getrennt).
struct PlanModell: Identifiable, Codable, Hashable {
    let id: UUID
    let dateiname: String
    let anzeigeName: String
    let projectNumber: String
    let projectTitel: String
    let importiertAm: Date

    init(
        id: UUID = UUID(),
        dateiname: String,
        anzeigeName: String,
        projectNumber: String,
        projectTitel: String,
        importiertAm: Date = Date()
    ) {
        self.id = id
        self.dateiname = dateiname
        self.anzeigeName = anzeigeName
        self.projectNumber = projectNumber
        self.projectTitel = projectTitel
        self.importiertAm = importiertAm
    }
}
