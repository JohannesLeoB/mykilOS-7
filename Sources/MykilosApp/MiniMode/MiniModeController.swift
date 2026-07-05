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
// dann per Halte-Geste am mykilOS-Button oben links ausgelöst. Beim Aktivieren wird das
// Hauptfenster AUSGEBLENDET (orderOut) — der schwebende Icon-Streifen steht dann allein und
// liegt NIE über der Großversion (C3). Verlassen: Klick aufs Logo im Rail — das blendet genau
// dieses Hauptfenster wieder ein und bringt es nach vorn.
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
    /// Läuft der Mini-Mode gerade (Panel sichtbar)? Beim Aktivieren wird das Hauptfenster
    /// AUSGEBLENDET (orderOut), sodass der schwebende Icon-Streifen ALLEIN steht und nie über
    /// der Großversion liegt (C3). Beim Verlassen wird genau dieses Fenster wiederhergestellt.
    private(set) var isActive = false

    private var panel: MiniModePanel?
    private var refreshTimer: Timer?

    /// Das beim Aktivieren ausgeblendete Hauptfenster — gemerkt, damit beim Verlassen exakt
    /// dieses eine Fenster wiederhergestellt wird (nicht irgendein Fenster). Schwach gehalten:
    /// verschwindet das Fenster anderweitig, restauriert der Fallback in `restoreMainWindow`.
    private weak var hiddenMainWindow: NSWindow?

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
        // C3: Hauptfenster ausblenden, damit der Icon-Streifen ALLEIN schwebt und nicht
        // über der Großversion liegt. Das schwebende Panel (canBecomeMain = false) wird
        // vom Filter unten übersprungen — nur das echte Hauptfenster wird verborgen.
        hideMainWindow()
        startRefreshTicker()
        Task { await store.refresh() }
    }

    /// Beendet den Mini-Mode: Panel schließen, Ticker stoppen, Hauptfenster wiederherstellen.
    func deactivate() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        panel?.close()
        panel = nil
        isActive = false
        // C3: das beim Aktivieren ausgeblendete Hauptfenster wieder einblenden.
        restoreMainWindow()
    }

    // MARK: Fenster-Sichtbarkeit (C3)

    /// Blendet das echte Hauptfenster aus (orderOut) und merkt es sich für die spätere
    /// Wiederherstellung. Das schwebende MiniModePanel (canBecomeMain = false) ist durch den
    /// Filter ausgenommen — es bleibt sichtbar. WindowGuard fasst ein ausgeblendetes Fenster
    /// ohnehin nicht (isVisible == false), es kann also nicht klammernd „zurückwandern".
    private func hideMainWindow() {
        guard let window = mainWindow() else { return }
        hiddenMainWindow = window
        window.orderOut(nil)
    }

    /// Stellt genau das zuvor ausgeblendete Hauptfenster wieder her und bringt es nach vorn.
    /// Fällt (falls die Referenz verloren ging) auf ein passendes sichtbares Fenster zurück.
    private func restoreMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = hiddenMainWindow {
            window.makeKeyAndOrderFront(nil)
        } else {
            for window in NSApp.windows where window.canBecomeMain && window.contentView != nil {
                window.makeKeyAndOrderFront(nil)
                break
            }
        }
        hiddenMainWindow = nil
    }

    /// Findet das echte Hauptfenster — bevorzugt das aktuelle Key/Main-Fenster, sonst das erste
    /// sichtbare inhaltstragende Fenster, das Main werden kann. Das MiniModePanel
    /// (canBecomeMain = false) wird dabei niemals getroffen.
    private func mainWindow() -> NSWindow? {
        if let key = NSApp.keyWindow, key.canBecomeMain, key.contentView != nil { return key }
        if let main = NSApp.mainWindow, main.canBecomeMain, main.contentView != nil { return main }
        return NSApp.windows.first { $0.isVisible && $0.canBecomeMain && $0.contentView != nil }
    }

    // MARK: Klick-Ziele

    /// Logo angetippt → Mini-Mode beenden. `deactivate()` blendet das zuvor ausgeblendete
    /// Hauptfenster wieder ein und bringt es nach vorn (C3-Wiederherstellung).
    func returnToMainWindow() {
        deactivate()
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
