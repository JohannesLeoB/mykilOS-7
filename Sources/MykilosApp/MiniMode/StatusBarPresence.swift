import AppKit
import SwiftUI
import Combine
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - MiniModeAppDelegate
// Die einzige AppKit-Delegate-Infrastruktur der App. Setzt das Menüleisten-Element
// (NSStatusItem) mit Zähler-Badge + Popover auf. Bewusst KEINE Änderung der
// Activation-Policy — Dock-Icon und Hauptfenster (WindowGroup) bleiben unverändert.
//
// V1 liefert NUR das Menüleisten-Element. Das schwebende NSPanel (.floating,
// .nonactivatingPanel) ist ein ehrlicher Folgeschritt: es erschiene ebenfalls in
// NSApp.windows und könnte mit WindowGuard.clampMainWindowToVisibleScreen kollidieren
// (dessen `first(where:)`-Filter greift das erste sichtbare Fenster). Erst wenn der
// Guard-Filter auf eine bekannte Fenster-Identität geschärft ist, ist das Panel sicher.
@MainActor
final class MiniModeAppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var refreshTimer: Timer?

    // Wird gesetzt, sobald der Boot fertig ist (AppState existiert). Vorher zeigt das
    // Icon nur den Ruhezustand (kein Badge), das Popover einen Platzhalter.
    private var appState: AppState?
    private var store: MiniModeStore?
    private var context: StudioContext?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpStatusItemIfEnabled()
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTimer?.invalidate()
    }

    // MARK: Boot-Anbindung
    // Vom App-Root aufgerufen, sobald phase == .ready(appState). Baut den MiniModeStore
    // aus den bereits vorhandenen Stores (kein neuer Poll) und startet den ruhigen
    // Aktualisierungs-Ticker.
    func attach(appState: AppState, context: StudioContext) {
        self.appState = appState
        self.context = context
        let store = MiniModeStore(
            timer: appState.timer,
            tasks: appState.assistantTasks,
            context: context
        )
        self.store = store
        // Falls der Master-Toggle das Element beim Start ausgeblendet hatte, jetzt
        // (mit gültigem Store) nachziehen.
        setUpStatusItemIfEnabled()
        startRefreshTicker()
        Task { await refreshAndRender() }
    }

    // MARK: Status-Item

    private func setUpStatusItemIfEnabled() {
        guard MiniModeDefaults.masterEnabled else {
            teardownStatusItem()
            return
        }
        guard statusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = Self.templateIcon()
            button.image?.isTemplate = true
            button.imagePosition = .imageLeading
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        self.statusItem = item

        let pop = NSPopover()
        pop.behavior = .transient
        pop.animates = true
        self.popover = pop
        renderPopoverContent()
    }

    private func teardownStatusItem() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItem = nil
        popover = nil
    }

    /// Menüleisten-Symbol. SF Symbol als Template-Image (folgt Hell/Dunkel der Leiste).
    private static func templateIcon() -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        let image = NSImage(systemSymbolName: "circle.grid.2x2", accessibilityDescription: "mykilOS")
        return image?.withSymbolConfiguration(config) ?? image
    }

    // MARK: Popover

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            renderPopoverContent()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Beim Öffnen frisch aus den Caches rechnen (kein Netzwerk).
            Task { await refreshAndRender() }
        }
    }

    private func renderPopoverContent() {
        guard let popover else { return }
        if let store {
            let view = MiniModePopoverView(store: store, onOpenApp: { [weak self] in
                self?.bringMainWindowToFront()
            })
            popover.contentViewController = NSHostingController(rootView: view)
        } else {
            // Boot noch nicht fertig: schlichter Platzhalter statt Absturz.
            popover.contentViewController = NSHostingController(rootView: MiniModeBootingView())
        }
    }

    private func bringMainWindowToFront() {
        popover?.performClose(nil)
        NSApp.activate(ignoringOtherApps: true)
        // Das erste „echte" Hauptfenster nach vorn holen (nicht das About-Fenster).
        for window in NSApp.windows where window.canBecomeMain && window.contentView != nil {
            window.makeKeyAndOrderFront(nil)
            break
        }
    }

    // MARK: Aktualisierung (nur aus Caches, kein Netzwerk)

    private func startRefreshTicker() {
        refreshTimer?.invalidate()
        // 30 s ist bewusst gemächlich — der Store liest nur lokale Caches (Timer/Signale/
        // Aufgaben) + Cache-Treffer für Mail. KEIN Netzwerk-Poll (LEAN-Regel). Der
        // laufende Timer soll trotzdem einigermaßen aktuell im Badge/Popover stehen.
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refreshAndRender() }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    private func refreshAndRender() async {
        // Master-Toggle kann zur Laufzeit umgeschaltet werden (Settings) — Element
        // entsprechend zeigen/verstecken.
        if !MiniModeDefaults.masterEnabled {
            teardownStatusItem()
            refreshTimer?.invalidate()
            refreshTimer = nil
            return
        }
        setUpStatusItemIfEnabled()
        if refreshTimer == nil { startRefreshTicker() }

        await store?.refresh()
        renderBadge()
    }

    private func renderBadge() {
        guard let button = statusItem?.button else { return }
        let count = store?.snapshot.badgeCount ?? 0
        if count > 0 {
            button.title = "  \(count)"
        } else {
            button.title = ""
        }
    }
}

// MARK: - MiniModeBootingView
// Winziger Platzhalter, solange der AppState noch nicht bereitsteht.
private struct MiniModeBootingView: View {
    var body: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: "hourglass")
                .foregroundStyle(MykColor.muted.color)
            Text("mykilOS startet …")
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
        }
        .padding(MykSpace.s5)
        .frame(width: 240)
        .background(MykColor.paper.color)
    }
}
