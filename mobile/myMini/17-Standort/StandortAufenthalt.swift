import Foundation

/// Ein vom Standort-Wächter erkannter Aufenthalt bei einem gemerkten
/// Projekt-Standort — reines Betreten/Verlassen, keine Bewegungsspur
/// dazwischen. `erledigt` markiert, dass der Mensch die Karte schon
/// gesehen und entschieden hat (bestätigt oder verworfen) — der Eintrag
/// selbst bleibt stehen, das ist das Audit ("was hat der Satellit gesehen").
struct StandortAufenthalt: Identifiable, Codable, Hashable {
    let id: UUID
    let projectNumber: String
    let projectTitel: String
    let betretenAm: Date
    var verlassenAm: Date?
    var erledigt: Bool

    init(
        id: UUID = UUID(),
        projectNumber: String,
        projectTitel: String,
        betretenAm: Date = Date(),
        verlassenAm: Date? = nil,
        erledigt: Bool = false
    ) {
        self.id = id
        self.projectNumber = projectNumber
        self.projectTitel = projectTitel
        self.betretenAm = betretenAm
        self.verlassenAm = verlassenAm
        self.erledigt = erledigt
    }

    var dauerText: String? {
        guard let verlassenAm else { return nil }
        let minuten = Int(verlassenAm.timeIntervalSince(betretenAm) / 60)
        let stunden = minuten / 60
        let rest = minuten % 60
        if stunden > 0 { return "\(stunden)h \(rest)min" }
        return "\(rest)min"
    }
}
