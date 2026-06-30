import SwiftUI

// MARK: - mykilOS 6 Typografie
// Alle Schrift läuft durch diese Tokens. Direkte .font(.system(...)) sind in
// Feature-/Widget-Code verboten (SwiftLint erzwingt das).
// ABC Monument Grotesk ist die Display-Schrift; fehlt die Datei, greift der
// System-Grotesk ein — die Hierarchie stimmt in beiden Fällen.

public extension Font {
    // Display — Hero, große Überschriften
    static var mykHero:    Font { .custom("ABCMonumentGrotesk-Medium", size: 42, relativeTo: .largeTitle) }
    static var mykDisplay: Font { .custom("ABCMonumentGrotesk-Medium", size: 28, relativeTo: .title) }

    // Inhalt
    static var mykTitle:   Font { .custom("ABCMonumentGrotesk-Medium", size: 18, relativeTo: .title2) }
    static var mykHeadline:Font { .custom("ABCMonumentGrotesk-Medium", size: 15, relativeTo: .headline) }
    static var mykBody:    Font { .custom("ABCMonumentGrotesk-Regular", size: 14, relativeTo: .body) }
    static var mykSmall:   Font { .custom("ABCMonumentGrotesk-Regular", size: 13, relativeTo: .callout) }
    static var mykCaption: Font { .custom("ABCMonumentGrotesk-Regular", size: 12, relativeTo: .caption) }

    // Mono — Quellenzeilen, Nummern, Daten
    static func mykMono(_ size: CGFloat = 10.5) -> Font {
        .custom("ABCMonumentGroteskMono-Regular", size: size, relativeTo: .caption)
    }

    // Timer-Uhr (mykilOS 8, Block B): große, leichte Ziffernanzeige. Mit
    // `.monospacedDigit()` kombinieren → tabulare Ziffern, kein Springen beim Ticken.
    static var mykTimerClock: Font { .custom("ABCMonumentGrotesk-Regular", size: 38, relativeTo: .largeTitle) }
}

// MARK: - Widget-Titel (Versalien, Mono-ähnlich)
public extension Text {
    func mykWidgetTitle() -> some View {
        self.font(.mykMono(11))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(MykColor.inkSoft.color)
    }
}
