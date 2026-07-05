import Foundation

/// Ein gespeicherter RoomPlan-Scan (#5) — die USDZ-Datei liegt in
/// `Documents/RoomPlan/`, hier nur Metadaten. Gleiches Muster wie `FeldFoto`.
struct RoomPlanAufnahme: Identifiable, Codable, Hashable {
    let id: UUID
    let dateiname: String
    let projectNumber: String
    let projectTitel: String
    let aufgenommenAm: Date

    init(
        id: UUID = UUID(),
        dateiname: String,
        projectNumber: String,
        projectTitel: String,
        aufgenommenAm: Date = Date()
    ) {
        self.id = id
        self.dateiname = dateiname
        self.projectNumber = projectNumber
        self.projectTitel = projectTitel
        self.aufgenommenAm = aufgenommenAm
    }
}
