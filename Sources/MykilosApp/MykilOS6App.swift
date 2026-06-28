import AppKit
import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

@main
struct MykilOS6App: App {
    @State private var appState = AppState(database: AppDatabase.production)
    @State private var context  = StudioContext()

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
    }
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(context)
                .task { await appState.bootstrap() }
                // Beim Wechsel in den Hintergrund / vor App-Quit (macOS geht über
                // .background) alle ungespeicherten Notizen sichern — sonst kann
                // Cmd-Q eine im Debounce-Fenster hängende Eingabe verlieren.
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background { appState.flushAllNotes() }
                }
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
}

// MARK: - AppModule
enum AppModule: String, CaseIterable, Identifiable {
    case today        = "Heute"
    case projects     = "Projekte"
    case assistant    = "Assistent"
    case brands       = "Marken & Daten"
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
                    Text("Version 6.4.0 · Sidebar CI + Brand Orange")
                        .font(.mykMono(11))
                        .foregroundStyle(MykColor.muted.color)
                }
            }

            Text("Das local-first Studio-Cockpit für Projektplanung, Quellen und Entscheidungen.")
                .font(.mykBody)
                .foregroundStyle(MykColor.inkSoft.color)
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(MykColor.line.color)

            Text("Copyright MYKILOS")
                .font(.mykCaption)
                .foregroundStyle(MykColor.muted.color)
        }
        .padding(MykSpace.s7)
        .frame(width: 440, alignment: .leading)
        .background(MykColor.paper.color)
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
            Button("Marken & Daten")  { activeModule = .brands }
                .keyboardShortcut("4", modifiers: .command)
            Button("Angebote")        { activeModule = .offers }
                .keyboardShortcut("5", modifiers: .command)
            Button("Kalkulation")     { activeModule = .kalkulation }
                .keyboardShortcut("6", modifiers: .command)
            Button("Einstellungen")   { activeModule = .settings }
                .keyboardShortcut("7", modifiers: .command)
        }
    }
}
