import SwiftUI

// MARK: - MykIconButton
// A11y-Härtung (2026-07-02, Design-Kritik): der EINE Baustein für Icon-only-Buttons.
// Vorher hatte jede Stelle ihr eigenes Styling (Rahmen ja/nein, Hover-Opacity,
// Padding-Streuung) und KEINE der 25+ Icon-only-Stellen ein accessibilityLabel —
// die App war für VoiceOver praktisch unbedienbar. Hier ist das Label ein
// PFLICHT-Parameter: ein neuer Icon-Button ohne Label kompiliert nicht.
//
// `label` dient dreifach: VoiceOver-Label, Tooltip (.help) und — falls
// `showsTitle` — sichtbarer Text daneben. Styling folgt den Tokens; kein
// Hover-Opacity-Trick als einziges Zustandssignal (Design-Kritik: Tastatur-
// Nutzer sehen Hover nie).
public struct MykIconButton: View {
    public enum Style {
        /// Dezenter Rahmen auf Karten-Hintergrund (Sekundär-Aktion in Listenzeilen).
        case bordered
        /// Nur das Icon, kein Rahmen (Toolbar-/Header-Aktionen).
        case plain
        /// Gefüllte Pille in einer Quellfarbe (Primär-Aktion einer Zeile).
        case filled(MykColor)
    }

    private let systemImage: String
    private let label: String
    private let style: Style
    private let showsTitle: Bool
    private let action: () -> Void

    public init(
        _ systemImage: String,
        label: String,
        style: Style = .plain,
        showsTitle: Bool = false,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.label = label
        self.style = style
        self.showsTitle = showsTitle
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            content
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }

    @ViewBuilder private var content: some View {
        switch style {
        case .bordered:
            core(foreground: MykColor.muted.color)
                .padding(MykSpace.s2)
                .background(MykColor.card.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm)
                    .stroke(MykColor.line.color, lineWidth: 1))
        case .plain:
            core(foreground: MykColor.muted.color)
        case .filled(let tint):
            core(foreground: MykColor.paper.color)
                .padding(.horizontal, MykSpace.s3)
                .padding(.vertical, MykSpace.s2)
                .background(tint.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        }
    }

    private func core(foreground: Color) -> some View {
        HStack(spacing: MykSpace.s2) {
            Image(systemName: systemImage)
                .font(.mykCaption)
            if showsTitle {
                Text(label)
                    .font(.mykMono(9))
            }
        }
        .foregroundStyle(foreground)
    }
}
