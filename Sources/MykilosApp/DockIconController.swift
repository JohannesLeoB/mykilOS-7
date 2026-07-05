import AppKit

// MARK: - MykAppDelegate — Dock-Icon nach System-Hell/Dunkel (2026-07-05, Johannes-Sidequest)
// Setzt das Dock-Icon der LAUFENDEN App auf die neue MYKILOS-„M"-Wortmarke und wechselt
// zwischen Ink (Dunkelmodus) und Paper (Hellmodus), sobald der macOS-System-Modus umschaltet.
// Reine AppKit-Laufzeit-Anpassung (`NSApp.applicationIconImage`) — lädt die SVGs wie die
// Wortmarke über `Bundle.module`. Das statische Bundle-Icon (`AppIcon.icns`) bleibt separat
// und ist ein eigener kleiner Folge-Strang (braucht einen SVG-Rasterizer, der hier nicht da war).
final class MykAppDelegate: NSObject, NSApplicationDelegate {
    private var appearanceObservation: NSKeyValueObservation?

    func applicationDidFinishLaunching(_ notification: Notification) {
        updateDockIcon()
        // Auf System-Hell/Dunkel-Umschaltung reagieren und das Icon live tauschen.
        appearanceObservation = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
            self?.updateDockIcon()
        }
    }

    private func updateDockIcon() {
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        // Dunkel → Ink (dunkler Grund, helles M) · Hell → Paper (heller Grund, dunkles M).
        let resource = isDark ? "mykilos-icon-ink" : "mykilos-icon-paper"
        guard let url = Bundle.module.url(forResource: resource, withExtension: "svg"),
              let image = NSImage(contentsOf: url) else { return }
        image.size = NSSize(width: 512, height: 512)
        NSApp.applicationIconImage = image
    }
}
