import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

@main
struct MykilOS6App: App {
    @State private var appState = AppState(database: AppDatabase.production)
    @State private var context  = StudioContext()
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
    case today      = "Heute"
    case projects   = "Projekte"
    case assistant  = "Assistent"
    case brands     = "Marken & Daten"
    case offers     = "Angebote"
    case settings   = "Einstellungen"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .today:     "sun.min"
        case .projects:  "square.grid.2x2"
        case .assistant: "sparkles"
        case .brands:    "building.2"
        case .offers:    "doc.text"
        case .settings:  "gearshape"
        }
    }
}

// MARK: - FocusedValues — Navigation
private struct ActiveModuleKey: FocusedValueKey {
    typealias Value = Binding<AppModule>
}
extension FocusedValues {
    var activeModule: Binding<AppModule>? {
        get { self[ActiveModuleKey.self] }
        set { self[ActiveModuleKey.self] = newValue }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @State private var module: AppModule = .today
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
    }

    private var shell: some View {
        HStack(spacing: 0) {
            SidebarView(selection: $module, onOpenProfile: {
                // Profil vollständig → direkt zu Einstellungen; sonst Wizard.
                if appState.profile.profile?.isComplete == true { module = .settings }
                else { showOnboarding = true }
            })
            Divider().overlay(MykColor.line.color)
            moduleView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(MykColor.paper.color)
        // Nur MIN/MAX, KEIN idealWidth/idealHeight: der Mindestrahmen gibt der
        // NSHostingView eine feste, endliche untere Schranke (verhindert die
        // Fenster-Extrema-Endlosschleife → Crash). Ein idealWidth ließ das
        // Fenster bei jeder Navigation Richtung Ideal „springen" und aus dem Bild
        // driften — darum bewusst weggelassen. Die Startgröße kommt aus
        // .defaultSize(1340×860), die laufende Größe behält der Nutzer.
        .frame(minWidth: 1100, maxWidth: .infinity,
               minHeight: 720, maxHeight: .infinity)
        .disabled(isOnboardingUp)
    }

    @ViewBuilder
    private var moduleView: some View {
        switch module {
        case .today:     TodayView()
        case .projects:  ProjectGalleryView()
        case .assistant: AssistantPageView()
        case .offers:    GlobalOffersView()
        case .brands:    BrandsView()
        case .settings:  SettingsView()
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

struct ComingSoonView: View {
    let module: AppModule
    var body: some View {
        ZStack {
            MykColor.paper.color.ignoresSafeArea()
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
                    Text("Version 6.2.0 · Streaming + Profil")
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
    @FocusedBinding(\.activeModule) private var activeModule

    var body: some Commands {
        CommandGroup(replacing: .newItem) {}
        CommandGroup(replacing: .appInfo) {
            Button("Über mykilOS 6") {
                openWindow(id: "about")
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        CommandMenu("Navigation") {
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
            Button("Einstellungen")   { activeModule = .settings }
                .keyboardShortcut("6", modifiers: .command)
        }
    }
}
