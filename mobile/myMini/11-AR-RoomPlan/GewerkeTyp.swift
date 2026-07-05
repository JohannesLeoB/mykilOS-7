import UIKit

/// Die vier Gewerke-Kategorien für AR-Anker (#6) — feste, kleine Auswahl,
/// gleiche Haltung wie `KanonZiel`: nie geraten, der Mensch wählt vorher,
/// welcher Typ als Nächstes markiert wird.
enum GewerkeTyp: String, CaseIterable, Identifiable {
    case wasser = "Wasser"
    case strom = "Strom"
    case abfluss = "Abfluss"
    case sonstiges = "Sonstiges"

    var id: String { rawValue }

    var farbe: UIColor {
        switch self {
        case .wasser: return .systemBlue
        case .strom: return .systemYellow
        case .abfluss: return .systemBrown
        case .sonstiges: return .systemGray
        }
    }

    var symbol: String {
        switch self {
        case .wasser: return "drop.fill"
        case .strom: return "bolt.fill"
        case .abfluss: return "arrow.down.circle.fill"
        case .sonstiges: return "mappin"
        }
    }
}
