import Foundation

// MARK: - WorkBasket-Summen (V10-Plan, Block E/H)
//
// Reine, testbare Foundation-Werte über einen WorkBasket. Eine Quelle für die
// VK-Netto-Summe: das WarenkorbWidget (Block E), die Cash-„kalkuliert"-Zeile
// (Block H) und der Angebots-Mapper (Block F/G) rechnen damit identisch.
public extension WorkBasket {

    /// Netto-VK-Gesamtsumme aller Positionen (Σ vkEinzel × menge).
    /// Positionen ohne kalkulierten VK zählen mit 0.
    var vkNettoSumme: Double {
        picks.reduce(0.0) { summe, pick in
            summe + (pick.snapshot.vkEinzel ?? 0) * Double(pick.snapshot.menge)
        }
    }
}
