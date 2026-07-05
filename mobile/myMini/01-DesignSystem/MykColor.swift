import SwiftUI

/// Die mykilOS-Palette, aus dem Mothership-Design-System übernommen
/// (`MykilosDesign/Tokens.swift`, read-only gepeilt). Farbe ist Sprache —
/// man erkennt die Quelle, bevor man liest.
enum MykColor {
    static let paper = Color(light: 0xFAF8F3, dark: 0x141210)
    static let card = Color(light: 0xFFFFFF, dark: 0x1D1A17)
    static let ink = Color(light: 0x1A1814, dark: 0xF2ECE1)
    static let muted = Color(light: 0x6F675B, dark: 0x9B9284)
    static let line = Color(light: 0xE8E1D4, dark: 0x2C2822)

    static let brand = Color(light: 0xEA5B25, dark: 0xF26E3B)     // MYKILOS Orange
    static let drive = Color(light: 0xC26B4A, dark: 0xC26B4A)     // Terrakotta
    static let sage = Color(light: 0x6E8B6A, dark: 0x6E8B6A)      // Salbei
    static let ocker = Color(light: 0xC99A3E, dark: 0xC99A3E)     // Ocker (Aufgaben)
    static let plum = Color(light: 0x8A5B73, dark: 0x8A5B73)      // Pflaume (Notizen)
    static let ok = Color(light: 0x3E7A4E, dark: 0x5BA36B)
    static let crit = Color(light: 0xB4503C, dark: 0xD6725E)
}

private extension Color {
    /// Ein Farbwert für Hell, einer für Dunkel — kein blindes Invertieren.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { trait in
            let hex = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}
