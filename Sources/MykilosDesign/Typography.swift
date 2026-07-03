import SwiftUI
import AppKit

// MARK: - mykilOS Typografie — Website-CI-Angleichung (Design-Hero, 2026-07-02)
// Alle Schrift läuft durch diese Tokens. Direkte .font(.system(...)) sind in
// Feature-/Widget-Code verboten (SwiftLint erzwingt das).
//
// Leitbild ist die MYKILOS-Website (mykilos.com): fette Grotesk-Headlines,
// Monospace für Navigation/Labels/Metadaten, fast-monochrome Fläche.
//
// ABC Monument Grotesk ist die Marken-Schrift. WICHTIG (Befund 2026-07-02, jetzt
// bestätigt gegen die echte Design-System-Quelle): `.custom(...)` fällt bei
// fehlender Schrift still auf SF Pro PROPORTIONAL zurück — auf Macs ohne
// installierten Monument war die „Mono"-Optik der App also nie mono. UND: es
// gibt laut Lieferung des Foundry (Dinamo Typefaces) NUR ZWEI Schnitte —
// Grotesk **Medium** (kein Regular!) und **Mono Regular**. Ein Aufruf von
// "ABCMonumentGrotesk-Medium" träfe daher NIE eine echte Datei, selbst wenn
// Monument installiert ist — vorher ein stiller Fallback-Bug (die
// monument-Verfügbarkeitsprüfung deckte nur Medium ab, Regular-Aufrufe
// schlugen trotzdem lautlos fehl). Jetzt: EIN Schnitt (Medium) für den ganzen
// Grotesk-Sans-Voice, exakt wie die Marke ihn liefert. Lizenz (Dinamo) ist
// NICHT bestätigt — die .otf-Dateien liegen lokal vor, werden aber bewusst
// NICHT ins App-Bundle eingebettet, bis Johannes das freigibt (siehe
// docs/brand/README.md §3). Ohne Bundle-Einbettung + Font-Installation bleibt
// der System-Fallback aktiv; das ist erwartet, nicht kaputt.
enum MykFontAvailability {
    static let monument: Bool = NSFont(name: "ABCMonumentGrotesk-Medium", size: 12) != nil
    static let monumentMono: Bool = NSFont(name: "ABCMonumentGroteskMono-Regular", size: 12) != nil
}

public extension Font {
    // Display — Hero, große Überschriften (Website: fette, große Grotesk)
    static var mykHero: Font {
        MykFontAvailability.monument
            ? .custom("ABCMonumentGrotesk-Medium", size: 42, relativeTo: .largeTitle)
            : .system(size: 42, weight: .bold)
    }
    static var mykDisplay: Font {
        MykFontAvailability.monument
            ? .custom("ABCMonumentGrotesk-Medium", size: 28, relativeTo: .title)
            : .system(size: 28, weight: .bold)
    }

    // Inhalt
    static var mykTitle: Font {
        MykFontAvailability.monument
            ? .custom("ABCMonumentGrotesk-Medium", size: 18, relativeTo: .title2)
            : .system(size: 18, weight: .semibold)
    }
    static var mykHeadline: Font {
        MykFontAvailability.monument
            ? .custom("ABCMonumentGrotesk-Medium", size: 15, relativeTo: .headline)
            : .system(size: 15, weight: .semibold)
    }
    static var mykBody: Font {
        MykFontAvailability.monument
            ? .custom("ABCMonumentGrotesk-Medium", size: 14, relativeTo: .body)
            : .system(size: 14)
    }
    static var mykSmall: Font {
        MykFontAvailability.monument
            ? .custom("ABCMonumentGrotesk-Medium", size: 13, relativeTo: .callout)
            : .system(size: 13)
    }
    static var mykCaption: Font {
        MykFontAvailability.monument
            ? .custom("ABCMonumentGrotesk-Medium", size: 12, relativeTo: .caption)
            : .system(size: 12)
    }

    // Mono — Quellenzeilen, Nummern, Daten, Navigation (Website-Kernsprache).
    // Fallback ist ECHTES Mono (SF Mono), nicht mehr SF Pro Proportional.
    static func mykMono(_ size: CGFloat = 10.5) -> Font {
        MykFontAvailability.monumentMono
            ? .custom("ABCMonumentGroteskMono-Regular", size: size, relativeTo: .caption)
            : .system(size: size, design: .monospaced)
    }

    // Timer-Uhr (mykilOS 8, Block B): große, leichte Ziffernanzeige. Mit
    // `.monospacedDigit()` kombinieren → tabulare Ziffern, kein Springen beim Ticken.
    static var mykTimerClock: Font {
        MykFontAvailability.monument
            ? .custom("ABCMonumentGrotesk-Medium", size: 38, relativeTo: .largeTitle)
            : .system(size: 38, weight: .light)
    }
}

// MARK: - Widget-Titel (Versalien, Mono)
public extension Text {
    func mykWidgetTitle() -> some View {
        self.font(.mykMono(11))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(MykColor.inkSoft.color)
    }

    /// Seiten-/Modul-Titel im Website-Stil (Design-Hero 2026-07-02): VERSALIEN,
    /// fett, leicht gesperrt — wie „RAY GLASS"/„MYKILOS" auf mykilos.com.
    /// Für die großen Modul-Header (Heute, Projekte, Kataloge, …).
    func mykPageTitle() -> some View {
        self.font(.mykDisplay)
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(MykColor.ink.color)
    }
}
