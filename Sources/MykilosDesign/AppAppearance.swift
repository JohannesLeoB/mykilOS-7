import SwiftUI

// MARK: - AppAppearance
// Nutzer-Wahl für Hell/Dunkel/Auto (Härtung 2026-07-02, Johannes-Wunsch): die
// Ansicht richtet sich NICHT mehr stur nach dem System, sondern nach dieser
// per-Nutzer-Einstellung (in AppStorage `ui.appearance` — pro macOS-Account/
// Installation, passt zum local-first Ein-Nutzer-pro-Gerät-Modell).
//
// `.auto` gibt nil zurück → SwiftUI folgt dem System; `.light`/`.dark`
// überschreiben es. `.preferredColorScheme(...)` an der Scene treibt die
// MykColor-Auflösung (NSColor-Appearance-Provider) korrekt um.
public enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case auto
    case light
    case dark

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .auto:  "Automatisch"
        case .light: "Hell"
        case .dark:  "Dunkel"
        }
    }

    public var symbol: String {
        switch self {
        case .auto:  "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark:  "moon"
        }
    }

    public var preferredColorScheme: ColorScheme? {
        switch self {
        case .auto:  nil
        case .light: .light
        case .dark:  .dark
        }
    }

    /// Toleranter Parser für den AppStorage-Rohwert (unbekannt → .auto).
    public static func from(_ raw: String) -> AppAppearance {
        AppAppearance(rawValue: raw) ?? .auto
    }
}
