import Foundation

/// Ein roher Wareneingangs-Treffer — bewusst OHNE WorkBasket-Abgleich (kein
/// WorkBasket-Sync auf mobile existiert). Ein ehrlicher Rohdaten-Log, kein
/// vorgetäuschter Soll/Ist-Vergleich. Kein `syncedAt` — es gibt für diesen
/// Log (noch) keinen Sync-Kanal, also auch keinen Fake-Sync-Knopf.
struct WareneingangsEreignis: Identifiable, Codable, Hashable {
    let id: UUID
    let projectNumber: String
    let projectTitel: String
    let trackingNummer: String
    let absender: String
    let erfasstAm: Date

    init(
        id: UUID = UUID(),
        projectNumber: String,
        projectTitel: String,
        trackingNummer: String,
        absender: String,
        erfasstAm: Date = Date()
    ) {
        self.id = id
        self.projectNumber = projectNumber
        self.projectTitel = projectTitel
        self.trackingNummer = trackingNummer
        self.absender = absender
        self.erfasstAm = erfasstAm
    }
}
