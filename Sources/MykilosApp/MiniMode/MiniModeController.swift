import AppKit
import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - MiniModeController
//
// Der Mini-Mode: die App geschrumpft auf NUR die eingeklappte Icon-Sidebar — ein schmales,
// SCHWEBENDES, immer-obenauf, FOKUS-NEUTRALES Fenster (NSPanel), das ÜBER Vollbild-Spaces
// erscheint (z. B. während man in Vectorworks im Vollbild zeichnet) und NIE den Fokus stiehlt.
//
// Aktivierung: einmalig in Settings → Darstellung freischalten (`ui.miniMode.enabled`),
// dann per Halte-Geste am mykilOS-Button oben links ausgelöst. Verlassen: Klick aufs Logo
// im Rail (bringt das Hauptfenster zurück nach vorn).
//
// LEAN: Der Controller pollt NICHTS Neues. Er liest ausschließlich den MiniModeStore, der
// seinerseits nur bestehende lokale Caches/Loops verdichtet (Timer/Signale/Aufgaben). Der
// 30-s-Ticker rechnet nur den vorhandenen Speicherzustand neu — kein Netzwerk.
//
// WindowGuard-Verträglichkeit: das Panel überschreibt `canBecomeMain = false` (siehe
// MiniModePanel), sodass WindowGuard.clampMainWindowToVisibleScreen es via seinem
// `canBecomeMain`-Filter transparent ignoriert und weiter nur das echte Hauptfenster fasst.
@MainActor
@Observable
final class MiniModeController {
    /// Läuft der Mini-Mode gerade (Panel sichtbar)? Treibt u. a. das Ausblenden des
    /// Hauptfensters durch den Aufrufer nicht — beide Fenster dürfen koexistieren; der
    /// Nutzer schiebt das Hauptfenster nur zur Seite bzw. arbeitet im Vollbild daneben.
    private(set) var isActive = false

    private var panel: MiniModePanel?
    private var refreshTimer: Timer?

    // Wird beim Boot verdrahtet (attach). Vorher kann der Mini-Mode nicht starten.
    private var store: MiniModeStore?

    // Klick-Ziele — von ContentView gesetzt, damit der Controller nichts über die
    // SwiftUI-Navigation wissen muss. Logo → Hauptfenster zurück; Icon → Modul öffnen.
    var onSelectModule: (AppModule) -> Void = { _ in }

    // MARK: Boot-Anbindung

    /// Vom App-Root aufgerufen, sobald der AppState bereit ist. Baut den MiniModeStore aus
    /// den vorhandenen Stores (kein neuer Poll) — startet aber NICHT automatisch das Panel.
    func attach(appState: AppState, context: StudioContext) {
        guard store == nil else { return }
        store = MiniModeStore(
            timer: appState.timer,
            tasks: appState.assistantTasks,
            context: context
        )
    }

    // MARK: Ein/Aus

    /// Schaltet den Mini-Mode um. Startet nur, wenn das Opt-in in Settings gesetzt ist.
    func toggle() {
        if isActive { deactivate() } else { activate() }
    }

    /// Startet den Mini-Mode (nur wenn Opt-in aktiv und Store verdrahtet).
    func activate() {
        guard MiniModeUserPrefs.enabled, let store, !isActive else { return }
        let panel = MiniModePanel(store: store, controller: self)
        panel.orderFrontFloating()
        self.panel = panel
        isActive = true
        startRefreshTicker()
        Task { await store.refresh() }
    }

    /// Beendet den Mini-Mode: Panel schließen, Ticker stoppen.
    func deactivate() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        panel?.close()
        panel = nil
        isActive = false
    }

    // MARK: Klick-Ziele

    /// Logo angetippt → Hauptfenster zurück nach vorn, Mini-Mode beenden.
    func returnToMainWindow() {
        deactivate()
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.canBecomeMain && window.contentView != nil {
            window.makeKeyAndOrderFront(nil)
            break
        }
    }

    /// Modul-Icon angetippt → Modul öffnen UND Hauptfenster nach vorn (Mini-Mode beenden).
    func openModule(_ module: AppModule) {
        onSelectModule(module)
        returnToMainWindow()
    }

    // MARK: Aktualisierung (nur aus Caches, kein Netzwerk)

    private func startRefreshTicker() {
        refreshTimer?.invalidate()
        // 30 s bewusst gemächlich — der Store liest nur lokale Caches (Timer/Signale/
        // Aufgaben). KEIN Netzwerk-Poll (LEAN-Regel).
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.store?.refresh() }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }
}

// MARK: - MiniModeUserPrefs
// SwiftUI-freie Auswertung des Mini-Mode-Opt-ins (Settings → Darstellung). Default AUS —
// der Mini-Mode ist eine bewusste Entscheidung, kein Überraschungs-Fenster beim ersten Start.
enum MiniModeUserPrefs {
    static let enabledKey = "ui.miniMode.enabled"
    static var enabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? false
    }
}

// MARK: - MiniModePanel
// Das schwebende, fokus-neutrale, immer-obenauf Fenster über Vollbild-Spaces.
//
//   • .floating-Level               → immer über normalen Fenstern
//   • .nonactivatingPanel           → Klicks stehlen dem Vordergrund-Programm nie den Fokus
//   • .canJoinAllSpaces             → folgt über alle Spaces mit
//   • .fullScreenAuxiliary          → erscheint ÜBER einem Vollbild-Space (Vectorworks etc.)
//   • canBecomeMain = false         → WindowGuard ignoriert es (canBecomeMain-Filter)
//   • hidesOnDeactivate = false     → bleibt sichtbar, während ein anderes Programm aktiv ist
final class MiniModePanel: NSPanel {
    init(store: MiniModeStore, controller: MiniModeController) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 64, height: 360),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        becomesKeyOnlyIfNeeded = true

        let root = MiniModeRailView(store: store, controller: controller)
        let hosting = NSHostingView(rootView: root)
        hosting.autoresizingMask = [.width, .height]
        contentView = hosting
    }

    // Nie Main — damit WindowGuard.clampMainWindowToVisibleScreen (canBecomeMain-Filter)
    // dieses Panel transparent überspringt und weiter nur das echte Hauptfenster fasst.
    override var canBecomeMain: Bool { false }
    // Darf Key werden (für Hover/Klick-Interaktion), ohne die App zu aktivieren.
    override var canBecomeKey: Bool { true }

    /// Positioniert das Panel dezent oben rechts im sichtbaren Bereich und zeigt es an,
    /// ohne die App zu aktivieren (fokus-neutral).
    func orderFrontFloating() {
        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let margin: CGFloat = 24
            let origin = NSPoint(
                x: visible.maxX - frame.width - margin,
                y: visible.maxY - frame.height - margin
            )
            setFrameOrigin(origin)
        }
        orderFrontRegardless()
    }
}
