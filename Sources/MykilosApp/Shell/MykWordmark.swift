import SwiftUI
import AppKit
import MykilosDesign

// MARK: - MykWordmark
// Design-Hero (2026-07-02): das echte MYKILOS-Vektor-Wortmarken-SVG aus dem
// Marken-Design-System (Sources/MykilosApp/Resources/mykilos-wordmark-ink.svg,
// eigenes IP — keine Lizenzfrage, anders als die Schrift-Dateien). macOS 12+
// rendert SVG nativ über NSImage(contentsOf:). Fällt defensiv auf den Text
// "mykilOS" zurück, falls die Datei je fehlt (z. B. Test-/CI-Bundle ohne
// Resources) — nie ein harter Crash für ein Marken-Asset.
struct MykWordmark: View {
    private static let image: NSImage? = {
        guard let url = Bundle.module.url(forResource: "mykilos-wordmark-ink", withExtension: "svg") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }()

    var body: some View {
        if let image = Self.image {
            Image(nsImage: image)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(MykColor.ink.color)
        } else {
            Text("mykilOS").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
        }
    }
}
