import AppKit
import SwiftUI

// MARK: - WindowGuard
// Schutz gegen das bekannte Fenster-Drift-Problem (siehe Kommentare in
// MykilOS6App.swift/ProjectGalleryView.swift: ein inhalts-dimensioniertes
// Fenster ohne .windowResizability kann bei Inhaltswechseln aus dem
// sichtbaren Bildschirmbereich wandern). Statt die exakte Ursache jedes
// einzelnen Drifts zu jagen, zieht dieser Guard das Fenster nach jedem
// relevanten Navigationsschritt zurück in den sichtbaren Bereich — eine
// Untergrenze, kein Ersatz für die eigentliche Layout-Stabilität.
@MainActor
enum WindowGuard {
    static func clampMainWindowToVisibleScreen() {
        guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }),
              let screen = window.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        var frame = window.frame
        // Größe nie über den sichtbaren Bereich hinaus erzwingen — nur Position
        // korrigieren, falls das Fenster ganz oder teilweise abgewandert ist.
        if frame.width > visible.width { frame.size.width = visible.width }
        if frame.height > visible.height { frame.size.height = visible.height }
        if frame.maxX > visible.maxX { frame.origin.x = visible.maxX - frame.width }
        if frame.minX < visible.minX { frame.origin.x = visible.minX }
        if frame.maxY > visible.maxY { frame.origin.y = visible.maxY - frame.height }
        if frame.minY < visible.minY { frame.origin.y = visible.minY }
        guard frame != window.frame else { return }
        window.setFrame(frame, display: true)
    }
}

extension View {
    /// Ruft den Window-Guard nach jeder Änderung von `value` einmal kurz
    /// verzögert auf (SwiftUI hat den neuen Inhalt zu dem Zeitpunkt schon
    /// gemessen, AppKit hat die Fenstergröße aber evtl. noch nicht final
    /// angewendet — eine Animation-Dauer entspricht etwa der Übergangszeit
    /// in ProjectGalleryView).
    func guardWindowPosition<T: Equatable>(on value: T) -> some View {
        onChange(of: value) { _, _ in
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(260))
                WindowGuard.clampMainWindowToVisibleScreen()
            }
        }
    }
}
