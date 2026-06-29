import AppKit
import SwiftUI
import os
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

@main
struct MykilOS6App: App {
    // Mandate F: Start-Phase explizit — ready (DB offen) oder failed (Wiederherstellung).
    // Kein eagerly-force-unwrapped AppState mehr, der vor dem ersten View crashen kann.
    enum BootPhase { case ready(AppState); case failed(message: String, dbPath: String) }
    @State private var phase: BootPhase
    @State private var context = StudioContext()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Single-Instance-Guard: läuft bereits eine andere Instanz, diese aktivieren
        // und die neue sofort beenden. build_and_run.sh killt via pkill vor dem Build,
        // sodass beim Entwickeln immer die frischeste Version läuft; dieser Guard
        // verhindert zusätzlich Doppelstarts aus Finder oder Dock.
        let bundleID = Bundle.main.bundleIdentifier ?? "de.mykilos.mykilos6"
        let current = NSRunningApplication.current
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0 != current }
        if !others.isEmpty {
            others.first?.activate(options: [.activateIgnoringOtherApps])
            exit(0)
        }
        // Launch-Marker + wiederherstellbarer DB-Start.
        MykLog.lifecycle.notice("mykilOS Start — v\(AppIdentity.version, privacy: .public) build \(AppIdentity.build, privacy: .public) commit \(AppIdentity.gitCommit, privacy: .public)")
        switch AppDatabase.boot() {
        case .ready(let db):
            _phase = State(initialValue: .ready(AppState(database: db)))
        case .failed(let message, let dbPath):
            _phase = State(initialValue: .failed(message: message, dbPath: dbPath))
        }
    }

    var body: some Scene {
        WindowGroup {
            rootView
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1340, height: 860)
        // KEIN .windowResizability(.contentMinSize): das positionierte das Fenster
        // bei jedem Inhaltswechsel neu (Drift aus dem Bild). Der Crash ist bereits
        // anders behoben — durch die entschärfte Transition (.opacity statt .move,
        // siehe ProjectGalleryView) und den festen Mindestrahmen an ContentView,
        // der der NSHostingView einen stabilen, endlichen unteren Anker gibt.
        // Damit bleibt die normale, stabile .automatic-Fensterlogik erhalten.
        .commands { AppCommands() }

        WindowGroup("Über mykilOS 6", id: "about") {
            AboutMykilOSView()
        }
        .defaultSize(width: 440, height: 300)
        .windowResizability(.contentSize)
    }

    @ViewBuilder
    private var rootView: some View {
        switch phase {
        case .ready(let appState):
            ContentView()
                .environment(appState)
                .environment(context)
                .task { await appState.bootstrap() }
                // Beim Wechsel in den Hintergrund / vor App-Quit (macOS geht über
                // .background) alle ungespeicherten Notizen sichern — sonst kann
                // Cmd-Q eine im Debounce-Fenster hängende Eingabe verlieren.
                .onChange(of: scenePhase) { _, scene in
                    if scene == .background { appState.flushAllNotes() }
                }
        case .failed(let message, let dbPath):
            DatabaseRecoveryView(
                message: message, dbPath: dbPath,
                onRestoreLatest: {
                    switch AppDatabase.restoreLatestBackupThenBoot() {
                    case .ready(let db): phase = .ready(AppState(database: db))
                    case .failed(let m, let p): phase = .failed(message: m, dbPath: p)
                    }
                },
                onReset: {
                    switch AppDatabase.recoverByResettingDatabase() {
                    case .ready(let db): phase = .ready(AppState(database: db))
                    case .failed(let m, let p): phase = .failed(message: m, dbPath: p)
                    }
                }
            )
        }
    }
}

// MARK: - DatabaseRecoveryView (Mandate F)
// Sichtbarer, handlungsfähiger Fehlerzustand statt stillem Absturz, wenn die
// Produktions-DB nicht geöffnet werden kann. Zeigt den DB-Pfad und bietet ein
// zerstörungsfreies Zurücksetzen (korrupte Datei wird in Quarantäne verschoben,
// nicht gelöscht) als letzte Rettung an.
struct DatabaseRecoveryView: View {
    let message: String
    let dbPath: String
    let onRestoreLatest: () -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s6) {
            HStack(spacing: MykSpace.s4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(MykColor.critical.color)
                Text("Datenbank konnte nicht geöffnet werden")
                    .font(.mykDisplay)
                    .foregroundStyle(MykColor.ink.color)
            }
            Text("mykilOS konnte die lokale Datenbank nicht laden. Deine geteilten Daten "
                 + "(Drive, Kalender, Airtable) sind nicht betroffen — sie liegen extern.")
                .font(.mykBody)
                .foregroundStyle(MykColor.inkSoft.color)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: MykSpace.s2) {
                Text("Fehler").font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                Text(message).font(.mykMono(10)).foregroundStyle(MykColor.critical.color)
                    .lineLimit(4).textSelection(.enabled)
                Text("DB-Pfad").font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                Text(dbPath).font(.mykMono(10)).foregroundStyle(MykColor.inkSoft.color)
                    .lineLimit(2).truncationMode(.middle).textSelection(.enabled)
            }
            .padding(MykSpace.s5)
            .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.paper2.color))

            VStack(alignment: .leading, spacing: MykSpace.s4) {
                HStack(spacing: MykSpace.s4) {
                    Button("Aus letztem Backup wiederherstellen", action: onRestoreLatest)
                    Text("Stellt das jüngste konsistente Backup wieder her (atomar, geprüft).")
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.faint.color)
                }
                HStack(spacing: MykSpace.s4) {
                    Button("Datenbank zurücksetzen", role: .destructive, action: onReset)
                    Text("Verschiebt die beschädigte Datei in Quarantäne und legt eine neue an.")
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.faint.color)
                }
            }
        }
        .padding(MykSpace.s9)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(MykColor.paper.color)
    }
}

// MARK: - AppModule
enum AppModule: String, CaseIterable, Identifiable {
    case today        = "Heute"
    case projects     = "Projekte"
    case assistant    = "Assistent"
    case brands       = "Integrationen"
    case kataloge     = "Kataloge"
    case offers       = "Angebote"
    case kalkulation  = "Kalkulation"
    case settings     = "Einstellungen"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .today:       "sun.min"
        case .projects:    "square.grid.2x2"
        case .assistant:   "sparkles"
        case .brands:      "building.2"
        case .kataloge:    "books.vertical"
        case .offers:      "doc.text"
        case .kalkulation: "eurosign.square"
        case .settings:    "gearshape"
        }
    }
}

// MARK: - FocusedValues — Navigation + Sidebar
private struct ActiveModuleKey: FocusedValueKey {
    typealias Value = Binding<AppModule>
}
private struct SidebarCollapsedKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}
extension FocusedValues {
    var activeModule: Binding<AppModule>? {
        get { self[ActiveModuleKey.self] }
        set { self[ActiveModuleKey.self] = newValue }
    }
    var sidebarCollapsed: Binding<Bool>? {
        get { self[SidebarCollapsedKey.self] }
        set { self[SidebarCollapsedKey.self] = newValue }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @State private var module: AppModule = .today
    @AppStorage("ui.sidebarCollapsed") private var sidebarCollapsed = false
    @Environment(AppState.self) private var appState
    @AppStorage("onboarding.hasCompleted") private var hasCompleted = false
    @State private var showOnboarding = false

    // Direkt nutzbar: der Wizard erzwingt sich beim ersten Start NUR, wenn Claude
    // fehlt (= Assistent stumm). Google ist "empfohlen", nicht Pflicht — wer nur
    // Claude verbindet, bekommt den vollen Chat-Assistenten, nur ohne Live-Tools.
    // Konsistent mit Wizard-Copy und doneReady in OnboardingWizardView.
    private var essentialsConnected: Bool { appState.claudeAuth.status == .connected }
    private var isOnboardingUp: Bool {
        showOnboarding || (hasCompleted == false && essentialsConnected == false)
    }

    var body: some View {
        ZStack {
            shell
            if isOnboardingUp {
                MykColor.ink.color.opacity(0.55).ignoresSafeArea()
                    .onTapGesture { }   // blockierender Backdrop — kein Durchklicken
                OnboardingWizardView(
                    onFinish: { hasCompleted = true; showOnboarding = false },
                    onDismiss: hasCompleted ? { showOnboarding = false } : nil
                )
            }
        }
        .focusedValue(\.activeModule, $module)
        .focusedValue(\.sidebarCollapsed, $sidebarCollapsed)
        // Navigations-Brücke (siehe AppState.pendingProjectSelection): sobald ein
        // anderes Modul "öffne Projekt X" anfordert, wechselt hier nur das Modul
        // — das tatsächliche Öffnen übernimmt ProjectGalleryView selbst.
        .onChange(of: appState.pendingProjectSelection) { _, new in
            if new != nil { module = .projects }
        }
        .guardWindowPosition(on: module)
    }

    private var shell: some View {
        HStack(spacing: 0) {
            if !sidebarCollapsed {
                SidebarView(
                    selection: $module,
                    onOpenProfile: {
                        if appState.profile.profile?.isComplete == true { module = .settings }
                        else { showOnboarding = true }
                    },
                    onToggleSidebar: {
                        withAnimation(.easeInOut(duration: 0.22)) { sidebarCollapsed.toggle() }
                    }
                )
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)
                .zIndex(1)
                .transition(.move(edge: .leading))
                Divider()
                    .overlay(MykColor.line.color)
                    .zIndex(1)
                    .transition(.move(edge: .leading))
            }
            detailPane
                .overlay(alignment: .topLeading) { sidebarToggleButton }
        }
        .background(MykColor.paper.color)
        // minWidth schrumpft wenn Sidebar eingeklappt (212 px weniger).
        .frame(minWidth: sidebarCollapsed ? 888 : 1100,
               maxWidth: .infinity,
               minHeight: 720, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.22), value: sidebarCollapsed)
        .disabled(isOnboardingUp)
    }

    private var sidebarToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) { sidebarCollapsed.toggle() }
        } label: {
            Image(systemName: sidebarCollapsed ? "sidebar.left" : "sidebar.left")
                .symbolVariant(sidebarCollapsed ? .none : .slash)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(MykColor.faint.color)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, MykSpace.s5)
        .padding(.leading, MykSpace.s5)
        .help(sidebarCollapsed ? "Sidebar einblenden (⌘⇧S)" : "Sidebar ausblenden (⌘⇧S)")
    }

    /// Harte Layout-Grenze zwischen Sidebar und Modulinhalt.
    ///
    /// Ein normaler `frame(maxWidth: .infinity)` verhindert nicht, dass ein
    /// intrinsisch breites Kind (hier: das Widget-`Grid`) seine Idealbreite
    /// zurück in den äußeren `HStack` meldet. `GeometryReader` nimmt stattdessen
    /// ausschließlich den tatsächlich verbleibenden Platz ein. Der Modulinhalt
    /// erhält danach exakt diese endliche Breite und Höhe; `contentShape`
    /// begrenzt zusätzlich seine Interaktionsfläche auf die Detail-Pane.
    private var detailPane: some View {
        GeometryReader { proxy in
            moduleView
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height,
                    alignment: .topLeading
                )
                .clipped()
                .contentShape(.interaction, Rectangle())
        }
        .frame(minWidth: 0, maxWidth: .infinity,
               minHeight: 0, maxHeight: .infinity)
        .layoutPriority(0)
        .zIndex(0)
    }

    @ViewBuilder
    private var moduleView: some View {
        switch module {
        case .today:       TodayView()
        case .projects:    ProjectGalleryView()
        case .assistant:   AssistantPageView()
        case .offers:      GlobalOffersView()
        case .brands:      BrandsView(onNavigateToSettings: { module = .settings })
        case .kataloge:    KatalogeView()
        case .kalkulation: KalkulationsPageView()
        case .settings:    SettingsView()
        }
    }
}

struct AssistantPageView: View {
    @Environment(StudioContext.self) private var context
    @Environment(AppState.self) private var appState

    var body: some View {
        // Wurzel VStack (kein äußeres ScrollView), damit der Chat eigenständig
        // scrollt und der Composer unten verankert bleibt.
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: MykSpace.s2) {
                Text("Assistent")
                    .font(.mykDisplay)
                    .foregroundStyle(MykColor.ink.color)
                Text("Fragt deine Projekte, Signale und den Tag — im Dialog.")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            }
            .padding(.horizontal, MykSpace.s9)
            .padding(.top, MykSpace.s9)
            .padding(.bottom, MykSpace.s5)
            Divider().overlay(MykColor.line.color)
            AssistantChatView(
                scope: .home,
                chatStore: appState.chat,
                engine: appState.conversation,
                isConnected: appState.claudeAuth.status == .connected,
                modelName: (try? appState.claudeAuth.storedCredentials()?.model) ?? ClaudeAuthService.defaultModel,
                projects: appState.registry.projects,
                focusedProjectID: context.focusedProjectID,
                profile: appState.profile.profile
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(MykColor.paper.color)
    }
}

// MARK: - KalkulationsPageView
// Eigenständiger Sidebar-Tab "Kalkulation". Bettet KalkulationsWidget ein und
// reicht AppState.kalkulationsEngine als Dependency durch.
// projektID "global" = Tab-weite Schätzung, nicht an ein einzelnes Projekt gebunden.
struct KalkulationsPageView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(MykColor.line.color)
            ScrollView {
                KalkulationsWidget(
                    projektID: "global",
                    engine: appState.kalkulationsEngine
                )
                .padding(MykSpace.s7)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(MykColor.paper.color)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text("Kalkulation")
                .font(.mykDisplay)
                .foregroundStyle(MykColor.ink.color)
            Text("Schätze Projektkosten auf Basis historischer Baseline-Anker.")
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.top, MykSpace.s9)
        .padding(.bottom, MykSpace.s5)
    }
}

struct ComingSoonView: View {
    let module: AppModule
    var body: some View {
        ZStack {
            MykColor.paper.color
            Text("\(module.rawValue) — kommt in einem späteren Akt")
                .font(.mykBody).foregroundStyle(MykColor.muted.color)
        }
    }
}

struct AboutMykilOSView: View {
    // Alle Diagnose-Werte aus der EINEN Quelle (AppIdentity) — kein Netzwerk,
    // kein Keychain, keine zweite Pfad-/Versionsberechnung.
    private var version: String   { AppIdentity.version }
    private var build: String     { AppIdentity.build }
    private var bundlePath: String { AppIdentity.bundlePath }
    private var gitCommit: String { AppIdentity.gitCommit }
    private var buildDate: String { AppIdentity.buildDate }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s6) {
            HStack(alignment: .center, spacing: MykSpace.s5) {
                ZStack {
                    RoundedRectangle(cornerRadius: MykRadius.md)
                        .fill(MykColor.ink.color)
                    Text("6")
                        .font(.mykDisplay)
                        .foregroundStyle(MykColor.paper.color)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: MykSpace.s2) {
                    Text("mykilOS 6")
                        .font(.mykDisplay)
                        .foregroundStyle(MykColor.ink.color)
                    Text("Version \(version) · Build \(build)")
                        .font(.mykMono(11))
                        .foregroundStyle(MykColor.muted.color)
                }
            }

            Text("Das local-first Studio-Cockpit für Projektplanung, Quellen und Entscheidungen.")
                .font(.mykBody)
                .foregroundStyle(MykColor.inkSoft.color)
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(MykColor.line.color)

            // Diagnose-Informationen — kein Keychain, keine Tokens
            VStack(alignment: .leading, spacing: MykSpace.s3) {
                DiagRow(label: "Commit", value: gitCommit)
                DiagRow(label: "Gebaut", value: buildDate)
                DiagRow(label: "Bundle", value: bundlePath)
                DiagRow(label: "DB", value: AppIdentity.dbPath)
            }

            Divider().overlay(MykColor.line.color)

            Text("Copyright MYKILOS")
                .font(.mykCaption)
                .foregroundStyle(MykColor.muted.color)
        }
        .padding(MykSpace.s7)
        .frame(width: 540, alignment: .leading)
        .background(MykColor.paper.color)
    }
}

private struct DiagRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .top, spacing: MykSpace.s3) {
            Text(label)
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
                .frame(width: 48, alignment: .trailing)
            Text(value)
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.inkSoft.color)
                .lineLimit(2)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
    }
}

// MARK: - AppIdentity
// Statische Diagnose-Informationen ohne Keychain/Netzwerk. EINE Quelle der Wahrheit
// für About-Fenster UND Settings → Diagnose. Git-Commit/Branch/Build-Datum werden
// vom Build-Skript (build_and_run.sh) in die Info.plist injiziert (Keys Myk…);
// bei `swift run` ohne Bundle fallen sie ehrlich auf „–"/„unbekannt" zurück.
public enum AppIdentity {
    public static var dbPath: String { AppDatabase.productionURL.path }
    public static var bundlePath: String { Bundle.main.bundlePath }
    public static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
    }
    public static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
    }
    public static var gitCommit: String {
        Bundle.main.infoDictionary?["MykGitCommit"] as? String ?? "unbekannt"
    }
    public static var gitBranch: String {
        Bundle.main.infoDictionary?["MykGitBranch"] as? String ?? "–"
    }
    public static var buildDate: String {
        Bundle.main.infoDictionary?["MykBuildDate"] as? String ?? "–"
    }
}

struct AppCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    @FocusedBinding(\.activeModule)           private var activeModule
    @AppStorage("ui.sidebarCollapsed") private var sidebarCollapsed = false

    var body: some Commands {
        CommandGroup(replacing: .newItem) {}
        CommandGroup(replacing: .appInfo) {
            Button("Über mykilOS 6") {
                openWindow(id: "about")
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        CommandMenu("Navigation") {
            Button(sidebarCollapsed ? "Sidebar einblenden" : "Sidebar ausblenden") {
                withAnimation(.easeInOut(duration: 0.22)) { sidebarCollapsed.toggle() }
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            Divider()
            Button("Heute")           { activeModule = .today }
                .keyboardShortcut("1", modifiers: .command)
            Button("Projekte")        { activeModule = .projects }
                .keyboardShortcut("2", modifiers: .command)
            Button("Assistent")       { activeModule = .assistant }
                .keyboardShortcut("3", modifiers: .command)
            Button("Integrationen")   { activeModule = .brands }
                .keyboardShortcut("4", modifiers: .command)
            Button("Kataloge")        { activeModule = .kataloge }
                .keyboardShortcut("8", modifiers: .command)
            Button("Angebote")        { activeModule = .offers }
                .keyboardShortcut("5", modifiers: .command)
            Button("Kalkulation")     { activeModule = .kalkulation }
                .keyboardShortcut("6", modifiers: .command)
            Button("Einstellungen")   { activeModule = .settings }
                .keyboardShortcut("7", modifiers: .command)
        }
    }
}
