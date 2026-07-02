import SwiftUI
import AppKit

// MARK: - mykilOS 6 Farb-Tokens — die warme Palette
// Die EINE Quelle der Wahrheit für Farbe. Direkte Color(red:green:blue:) ist in
// Feature-/Widget-Code verboten (SwiftLint erzwingt das). Farbe ist hier eine
// Sprache: jede Quelle trägt ihren eigenen, gedämpften Ton.
// Akt 5: Adaptive Light/Dark — die Palette atmet jetzt mit dem System.
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
    // Brand-Akzent — MYKILOS Orange #EA5B25 (Sidebar-Actions, Home-Button)
    case brand
    // L26 — zusätzliche adaptive Tokens (ersetzen hartkodierte Hex/RGB)
    case folderIcon   // Mac-Ordner-Blau (Dateien-Baum) — dunkel angehoben für Kontrast
    case notesPaper   // Notiz-Pergament-Hintergrund (dark = warmes Dunkelpapier)
    case notesInk     // Notiz-Tinte auf Pergament (dark = warmes Cremé, lesbar)

    public var color: Color {
        switch self {
        case .paper:    Self.adaptive(light: 0xFAF8F3, dark: 0x1A1814)
        case .paper2:   Self.adaptive(light: 0xF2EFE7, dark: 0x222019)
        case .card:     Self.adaptive(light: 0xFFFFFF, dark: 0x2A2721)
        case .bone:     Self.adaptive(light: 0xE8E3D8, dark: 0x3A362E)
        case .line:     Self.adaptive(light: 0xE0DACE, dark: 0x3E3A32)
        case .ink:      Self.adaptive(light: 0x1A1814, dark: 0xF0EDE6)
        case .inkSoft:  Self.adaptive(light: 0x4A463E, dark: 0xC4BFB4)
        // A11y-Härtung (2026-07-02, Design-Kritik): muted/faint fielen im WCAG-Kontrasttest
        // durch (muted 3.4:1, faint 2.1:1 auf paper). Neu: muted ≥4.5 (AA Normaltext) und
        // faint ≥3.0 (AA Großtext/UI) auf paper, card UND paper2 — in beiden Appearances.
        // Die Stufung ink > inkSoft > muted > faint bleibt sichtbar erhalten.
        case .muted:    Self.adaptive(light: 0x716B5D, dark: 0x9A9486)
        case .faint:    Self.adaptive(light: 0x8E8879, dark: 0x7A7466)
        case .drive:    Self.adaptive(light: 0xC26B4A, dark: 0xD4815E)
        case .people:   Self.adaptive(light: 0x6E8B6A, dark: 0x82A37E)
        case .tasks:    Self.adaptive(light: 0xC99A3E, dark: 0xDAAE52)
        case .cash:     Self.adaptive(light: 0x4C6280, dark: 0x6A849E)
        case .personal: Self.adaptive(light: 0x8A5B73, dark: 0xA27389)
        case .positive: Self.adaptive(light: 0x3E7A4E, dark: 0x5A9A68)
        case .critical: Self.adaptive(light: 0xB4503C, dark: 0xCC6854)
        case .brand:    Self.adaptive(light: 0xEA5B25, dark: 0xEA5B25)
        case .folderIcon: Self.adaptive(light: 0x478AE6, dark: 0x5A9CF0)
        case .notesPaper: Self.adaptive(light: 0xFBF3DA, dark: 0x2E2A1E)
        case .notesInk:   Self.adaptive(light: 0x6B5A2F, dark: 0xE6D9B0)
        }
    }

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let hex = isDark ? dark : light
            let r: CGFloat = CGFloat((hex >> 16) & 0xFF) / 255
            let g: CGFloat = CGFloat((hex >> 8) & 0xFF) / 255
            let b: CGFloat = CGFloat(hex & 0xFF) / 255
            return NSColor(red: r, green: g, blue: b, alpha: 1)
        })
    }
}

// MARK: - Maße
public enum MykRadius { public static let sm: CGFloat = 8, md: CGFloat = 14, lg: CGFloat = 20, xl: CGFloat = 26 }
public enum MykSpace {
    public static let s2: CGFloat = 6, s3: CGFloat = 9, s4: CGFloat = 13,
                      s5: CGFloat = 17, s6: CGFloat = 22, s7: CGFloat = 28,
                      s8: CGFloat = 36, s9: CGFloat = 48
}

public extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
