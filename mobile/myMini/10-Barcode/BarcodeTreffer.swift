import Foundation

/// Ein roher Scan-Treffer — bewusst OHNE WorkBasket-Abgleich (kein
/// WorkBasket-Sync auf mobile existiert). Ein ehrlicher Rohdaten-Log:
/// Wert + Symbologie + Zeitpunkt, sonst nichts vorgetäuscht.
struct BarcodeTreffer: Identifiable, Codable, Hashable {
    let id: UUID
    let wert: String
    let symbologie: String
    let erkanntAm: Date

    init(id: UUID = UUID(), wert: String, symbologie: String, erkanntAm: Date = Date()) {
        self.id = id
        self.wert = wert
        self.symbologie = symbologie
        self.erkanntAm = erkanntAm
    }
}
