import Foundation

/// Ein Eintrag im Abnahmeprotokoll — Diktat + optionales Foto. Keine
/// persistierte Nummer: die Anzeige-Nummer ("Mangel #3") wird aus der
/// Listenposition berechnet, nicht gespeichert. Das vermeidet
/// Nummerierungs-Bugs nach dem Löschen eines mittleren Eintrags — eine
/// gespeicherte Nummer müsste nach jedem Löschen neu vergeben werden oder
/// Lücken zeigen, beides unnötige Komplexität für v0.
struct MangelEintrag: Identifiable, Codable, Hashable {
    let id: UUID
    let projectNumber: String
    let projectTitel: String
    let text: String
    var fotoDateiname: String?
    let erfasstAm: Date

    init(
        id: UUID = UUID(),
        projectNumber: String,
        projectTitel: String,
        text: String,
        fotoDateiname: String? = nil,
        erfasstAm: Date = Date()
    ) {
        self.id = id
        self.projectNumber = projectNumber
        self.projectTitel = projectTitel
        self.text = text
        self.fotoDateiname = fotoDateiname
        self.erfasstAm = erfasstAm
    }
}
