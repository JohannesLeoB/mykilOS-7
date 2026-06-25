import SwiftUI

// MARK: - mykilOS 6 Farb-Tokens — die warme Palette
// Die EINE Quelle der Wahrheit für Farbe. Direkte Color(red:green:blue:) ist in
// Feature-/Widget-Code verboten (SwiftLint erzwingt das). Farbe ist hier eine
// Sprache: jede Quelle trägt ihren eigenen, gedämpften Ton.
public enum MykColor {
    // Grund & Tinte
    case paper, paper2, card, bone, line, ink, inkSoft, muted, faint
    // Quellen-Farben
    case drive      // Terrakotta — Dateien
    case people     // Salbei — Menschen & Termine
    case tasks      // Ocker — Aufgaben
    case cash       // Tiefblau — Geld
    case personal   // Pflaume — Notizen
    // Status (selten, nie als Fläche)
    case positive, critical

    public var color: Color {
        switch self {
        case .paper:    Color(hex: 0xFAF8F3)
        case .paper2:   Color(hex: 0xF2EFE7)
        case .card:     Color(hex: 0xFFFFFF)
        case .bone:     Color(hex: 0xE8E3D8)
        case .line:     Color(hex: 0xE0DACE)
        case .ink:      Color(hex: 0x1A1814)
        case .inkSoft:  Color(hex: 0x4A463E)
        case .muted:    Color(hex: 0x8C8678)
        case .faint:    Color(hex: 0xB4AEA0)
        case .drive:    Color(hex: 0xC26B4A)
        case .people:   Color(hex: 0x6E8B6A)
        case .tasks:    Color(hex: 0xC99A3E)
        case .cash:     Color(hex: 0x4C6280)
        case .personal: Color(hex: 0x8A5B73)
        case .positive: Color(hex: 0x3E7A4E)
        case .critical: Color(hex: 0xB4503C)
        }
    }
}

// MARK: - Maße
public enum MykRadius { public static let sm: CGFloat = 8, md: CGFloat = 14, lg: CGFloat = 20, xl: CGFloat = 26 }
public enum MykSpace {
    public static let s2: CGFloat = 6, s3: CGFloat = 9, s4: CGFloat = 13,
                      s5: CGFloat = 17, s6: CGFloat = 22, s7: CGFloat = 28,
                      s8: CGFloat = 36, s9: CGFloat = 48
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
