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
    // Mini-Mode V1: Menüleisten-Presence (NSStatusItem + Popover). Reine AppKit-
    // Infrastruktur, daher als NSApplicationDelegate angedockt statt in einer Scene.
    // Wird erst mit AppState/StudioContext verdrahtet, sobald der Boot fertig ist.
    @NSApplicationDelegateAdaptor(MiniModeAppDelegate.self) private var miniModeDelegate
    @Environment(\.scenePhase) private var scenePhase
    // Hell/Dunkel/Auto (2026-07-02): per-Nutzer-Wahl statt System-Zwang.
    @AppStorage("ui.appearance") private var appearanceRaw = AppAppearance.auto.rawValue
    private var appearance: AppAppearance { AppAppearance.from(appearanceRaw) }
    // Rainbow Mode (Easter Egg, 2026-07-04): Toggle sitzt in UserDefaults (MykColor liest
    // direkt daraus), `.id(rainbowMode)` erzwingt einen kompletten Redraw der Baumstruktur
    // beim Umschalten — gleiches Reaktivitätsmuster wie `appearanceRaw` oben.
    @AppStorage("ui.rainbowMode") private var rainbowMode = false

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
                // Per-Nutzer-Wahl treibt die gesamte App-Darstellung; nil (=auto)
                // folgt weiter dem System.
                .preferredColorScheme(appearance.preferredColorScheme)
                .id(rainbowMode)
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

        WindowGroup("Über mykilOS", id: "about") {
            AboutMykilOSView()
                .preferredColorScheme(appearance.preferredColorScheme)
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
                // Mini-Mode: sobald der AppState bereit ist, die Menüleisten-Presence
                // mit den bestehenden Stores + der geteilten StudioContext-Instanz
                // verdrahten (kein neuer Poll, nur Lesen aus Caches).
                .task { miniModeDelegate.attach(appState: appState, context: context) }
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
                    .font(.mykDisplay)
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
// Mail ist KEIN eigener Sidebar-Eintrag mehr — es lebt als Toggle innerhalb
// des Assistenten (AssistantPageView). Daher kein `.mail`-Case mehr hier.
// Angebote (offers) ist KEIN eigener Sidebar-Eintrag mehr — es lebt als Tab
// innerhalb von KatalogeView (Kataloge → Angebote). Analog zur Mail-Lösung.
enum AppModule: String, CaseIterable, Identifiable {
    case today        = "Heute"
    case projects     = "Projekte"
    case assistant    = "Assistent"
    case kataloge     = "Kataloge"
    case settings     = "Einstellungen"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .today:       "sun.min"
        case .projects:    "square.grid.2x2"
        case .assistant:   "sparkles"
        case .kataloge:    "books.vertical"
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
private struct PaletteOpenKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}
private struct PriceReviewOpenKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}
extension FocusedValues {
    var priceReviewOpen: Binding<Bool>? {
        get { self[PriceReviewOpenKey.self] }
        set { self[PriceReviewOpenKey.self] = newValue }
    }
    var activeModule: Binding<AppModule>? {
        get { self[ActiveModuleKey.self] }
        set { self[ActiveModuleKey.self] = newValue }
    }
    var sidebarCollapsed: Binding<Bool>? {
        get { self[SidebarCollapsedKey.self] }
        set { self[SidebarCollapsedKey.self] = newValue }
    }
    var paletteOpen: Binding<Bool>? {
        get { self[PaletteOpenKey.self] }
        set { self[PaletteOpenKey.self] = newValue }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @State private var module: AppModule = .today
    // Settings-Sidebar-Modus: gewählte Kategorie + letztes Nicht-Settings-Modul (Rückkehr).
    @State private var settingsCategory: SettingsCategory = .profil
    @State private var lastModule: AppModule = .today
    @AppStorage("ui.sidebarCollapsed") private var sidebarCollapsed = false
    @Environment(AppState.self) private var appState
    @Environment(StudioContext.self) private var context
    @AppStorage("onboarding.hasCompleted") private var hasCompleted = false
    @State private var showOnboarding = false
    // mykilOS 8, Block B: Check-in-Dialog (aus Sidebar-Pille) — global über allen Modulen.
    @State private var timerCheckInRequested = false
    // Härtung 2026-07-01: kurzer Start-Hinweis, welcher Build gerade läuft (Antwort
    // auf wiederholte Verwechslungen zwischen parallel installierten Versionen).
    @State private var showFreshnessBanner = true
    // ⌘K Command-Palette (S5): globaler Fuzzy-Sprung zu Modulen + Projekten.
    @State private var showPalette = false
    // Lern-Loop: Preis-Wissen-Review (offene PDF-Positions-Kandidaten freigeben),
    // dauerhaft über den Menübefehl erreichbar — nicht nur nach dem Vormerken.
    @State private var showPriceReview = false

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
            // mykilOS 8, Block B: zeit-bezogene Dialoge (Übernahme/Buchung/Check-in) —
            // über allen Modulen, unter dem Onboarding.
            TimerGlobalDialogs(checkInRequested: $timerCheckInRequested)
            if isOnboardingUp {
                MykColor.ink.color.opacity(0.55).ignoresSafeArea()
                    .onTapGesture { }   // blockierender Backdrop — kein Durchklicken
                OnboardingWizardView(
                    onFinish: { hasCompleted = true; showOnboarding = false },
                    onDismiss: hasCompleted ? { showOnboarding = false } : nil
                )
            }
            // ⌘K Command-Palette — über allen Modulen, unter dem Onboarding.
            if showPalette && !isOnboardingUp {
                CommandPaletteView(
                    isPresented: $showPalette,
                    projects: appState.registry.projects,
                    customerFor: { appState.registry.customer(for: $0) },
                    onSelectModule: { module = $0 },
                    onSelectProject: { project in
                        appState.pendingProjectSelection = project
                        module = .projects
                    }
                )
            }
        }
        .focusedValue(\.activeModule, $module)
        .focusedValue(\.sidebarCollapsed, $sidebarCollapsed)
        .focusedValue(\.paletteOpen, $showPalette)
        .focusedValue(\.priceReviewOpen, $showPriceReview)
        .sheet(isPresented: $showPriceReview) {
            PriceKnowledgeReviewView(store: appState.learningStore, onClose: { showPriceReview = false })
        }
        // Navigations-Brücke (siehe AppState.pendingProjectSelection): sobald ein
        // anderes Modul "öffne Projekt X" anfordert, wechselt hier nur das Modul
        // — das tatsächliche Öffnen übernimmt ProjectGalleryView selbst.
        .onChange(of: appState.pendingProjectSelection) { _, new in
            if new != nil { module = .projects }
        }
        // Mail-Compose-Weiche (StudioContext.mailComposeRequest): Klick auf eine
        // Kontakt-Mail-Adresse → hier nur das Modul auf „Assistent" schalten. Das
        // Öffnen des Mail-Tabs + Vorbefüllen des Entwurfs übernimmt AssistantPageView.
        .onChange(of: context.mailComposeRequest) { _, new in
            if new != nil { module = .assistant }
        }
        .guardWindowPosition(on: module)
        .overlay(alignment: .top) {
            if showFreshnessBanner {
                AppFreshnessBanner(onDismiss: { showFreshnessBanner = false })
                    .padding(.top, MykSpace.s4)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showFreshnessBanner)
        .task {
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            showFreshnessBanner = false
        }
    }

    private var shell: some View {
        HStack(spacing: 0) {
            // Sidebar ist IMMER sichtbar — sidebarCollapsed steuert jetzt nur
            // kompakt (nur Icons) vs. breit; der Brand-Button oben togglet das.
            SidebarView(
                selection: $module,
                isCompact: $sidebarCollapsed,
                // Klick auf den Initialen-Avatar wechselt in den Settings-Sidebar-Modus
                // (die Sidebar zeigt dann die Einstellungs-Kategorien). Merkt das aktuelle
                // Modul, um beim Zurücktoggeln (Avatar/MYKILOS-Button) dorthin zurückzukehren.
                onOpenProfile: {
                    if module != .settings { lastModule = module }
                    module = .settings
                },
                settingsMode: module == .settings,
                settingsCategory: $settingsCategory,
                onExitSettings: { module = lastModule },
                timerCheckInRequested: $timerCheckInRequested
            )
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(1)
            .zIndex(1)
            Divider()
                .overlay(MykColor.line.color)
                .zIndex(1)
            detailPane
        }
        .background(MykColor.paper.color)
        // minWidth schrumpft im Kompakt-Modus (Sidebar 212 → 64 px).
        .frame(minWidth: sidebarCollapsed ? 960 : 1100,
               maxWidth: .infinity,
               minHeight: 720, maxHeight: .infinity)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: sidebarCollapsed)
        .disabled(isOnboardingUp)
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
        case .kataloge:    KatalogeView()
        case .settings:    SettingsView(externalCategory: $settingsCategory)
        }
    }
}

// MARK: - AssistantPageView
// Enthält zwei Modi via Segmented-Picker: Assistent-Chat + Mail-Client.
// Mail ist KEIN eigener Sidebar-Eintrag mehr — es lebt hier als zweiter Tab.
struct AssistantPageView: View {
    enum AssistantTab: String, CaseIterable {
        case assistant = "Assistent"
        case mail      = "Mail"
        var systemImage: String {
            switch self {
            case .assistant: "sparkles"
            case .mail:      "envelope"
            }
        }
    }

    @Environment(StudioContext.self) private var context
    @Environment(AppState.self) private var appState
    @State private var activeTab: AssistantTab = .assistant
    // Vorbefüllter Empfänger aus einer Kontakt-Mail-Anfrage (StudioContext.mailComposeRequest).
    // Wird an MailClientView durchgereicht und dort beim Öffnen des Entwurfs konsumiert (→ nil).
    @State private var mailComposeTo: String? = nil

    var body: some View {
        // Wurzel VStack (kein äußeres ScrollView), damit der Chat eigenständig
        // scrollt und der Composer unten verankert bleibt.
        VStack(alignment: .leading, spacing: 0) {
            // Header mit Titel + Segmented-Picker.
            // UI-Polish (2026-07-02, Johannes): beschreibende Untertitel entfernt
            // (Mock-up-Überbleibsel) — der Toggle daneben erklärt die zwei Modi selbst.
            HStack(alignment: .center, spacing: MykSpace.s6) {
                Text(activeTab == .assistant ? "Assistent" : "Mail")
                    .font(.mykDisplay)
                    .foregroundStyle(MykColor.ink.color)
                Spacer()
                // Eigener mykilOS-Segmented-Toggle ganz am rechten Rand (2026-07-02, Johannes).
                // Ersetzt den System-.segmented-Picker (aktives Segment war system-blau, passt
                // nicht zur CI). „Verfassen" ist in die Postfach-Leiste des Mail-Tabs gewandert.
                // Feste Breite → der Toggle verspringt beim Wechsel Assistent⇄Mail nicht.
                ModeToggle(selection: $activeTab)
            }
            .padding(.horizontal, MykSpace.s9)
            .padding(.top, MykSpace.s9)
            .padding(.bottom, MykSpace.s5)
            Divider().overlay(MykColor.line.color)

            // Inhalt je nach aktivem Tab
            switch activeTab {
            case .assistant:
                AssistantChatView(
                    scope: .home,
                    chatStore: appState.chat,
                    engine: appState.conversation,
                    isConnected: appState.claudeAuth.status == .connected,
                    modelName: (try? appState.claudeAuth.storedCredentials()?.model) ?? ClaudeAuthService.defaultModel,
                    projects: appState.registry.projects,
                    focusedProjectID: context.focusedProjectID,
                    profile: appState.profile.profile,
                    onCreateContact: { await appState.createContact($0) },
                    onCreateDraft: { await appState.createDraft($0) },
                    // Fix 2026-07-03: war nie injiziert → „Kontakt anlegen"-Knopf der
                    // Airtable-Karte blieb permanent disabled (Live-Fund Johannes).
                    onWriteAirtableContact: { await appState.writeAirtableContact($0) },
                    // Home-Scope: kein Projekt fokussiert → Ordner kann nicht automatisch
                    // ermittelt werden. Der Nutzer bekommt einen klaren Hinweis.
                    onUploadFileToDrive: { _, _ in .failed("Bitte ein Projekt öffnen, um Dateien direkt in den Projekt-Ordner hochzuladen.") },
                    onAttachFilesToMailDraft: { await appState.createDraftWithAttachments($0) }
                )
            case .mail:
                MailClientView(showsOwnHeader: false, composeToRequest: $mailComposeTo)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(MykColor.paper.color)
        // Kontakt-Mail-Weiche: eine offene Anfrage (Klick auf Mail-Adresse) übernehmen —
        // Mail-Tab öffnen + Empfänger vorbefüllen. onAppear fängt den Fall ab, dass diese
        // Seite erst durch den Modulwechsel frisch montiert wird (dann feuert onChange nicht).
        .onAppear { consumeMailComposeRequestIfNeeded() }
        .onChange(of: context.mailComposeRequest) { _, _ in consumeMailComposeRequestIfNeeded() }
    }

    /// Übernimmt eine offene Mail-Compose-Anfrage aus dem StudioContext: schaltet auf den
    /// Mail-Tab, merkt sich den Empfänger (MailClientView öffnet damit den Entwurf) und
    /// gibt die Weiche im Context sofort wieder frei.
    private func consumeMailComposeRequestIfNeeded() {
        guard let email = context.mailComposeRequest else { return }
        mailComposeTo = email
        activeTab = .mail
        context.clearMailComposeRequest()
    }
}

// MARK: - ModeToggle
// Eigener mykilOS-Segmented-Toggle (Assistent ⇄ Mail). Ersetzt den System-`.segmented`-
// Picker, dessen aktives Segment system-blau rendert (2026-07-02, Johannes) — passt nicht
// zur CI (monochrom + Terrakotta/Ink). Aufbau wie die übrigen Pill-Toggles der App
// (KatalogeView.tabPill): recessed Track (bone + line), aktives Segment gefüllt
// (Terrakotta) mit Papier-Text, inaktives Segment nur muted-Text.
// Feste Gesamtbreite + gleich breite Segmente → der Toggle behält beim Wechsel exakt
// Größe und Position (kein Verspringen; ersetzt den früheren „festen Verfassen-Slot").
private struct ModeToggle: View {
    @Binding var selection: AssistantPageView.AssistantTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AssistantPageView.AssistantTab.allCases, id: \.self) { tab in
                segment(tab)
            }
        }
        .padding(3)
        .frame(width: 208)
        .background(MykColor.bone.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: MykRadius.md)
                .stroke(MykColor.line.color, lineWidth: 1)
        )
    }

    private func segment(_ tab: AssistantPageView.AssistantTab) -> some View {
        let isActive = selection == tab
        return Button {
            guard selection != tab else { return }
            withAnimation(.easeInOut(duration: 0.15)) { selection = tab }
        } label: {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: tab.systemImage)
                    .font(.mykCaption)
                Text(tab.rawValue)
                    .font(.mykSmall)
            }
            .foregroundStyle(isActive ? MykColor.paper.color : MykColor.muted.color)
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .background(isActive ? MykColor.drive.color : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// Härtung 2026-07-01: kurzer Start-Hinweis, welcher Build gerade läuft — Antwort
// auf wiederholte Verwechslungen zwischen mehreren parallel installierten
// mykilOS-Versionen (siehe script/cleanup_old_app_versions.sh). Zeigt nur den
// eigenen Build-Fingerabdruck aus AppIdentity (Version, Commit, Datum) — keine
// Behauptung "das ist weltweit die neueste Version" (dafür gäbe es in einer
// local-first App keine Vergleichsgrundlage), sondern ehrlich "das läuft hier
// gerade". Auto-Dismiss nach 6s (ContentView.task) + manueller Schließen-Button.
private struct AppFreshnessBanner: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: MykSpace.s4) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(MykColor.positive.color)
            Text("mykilOS \(AppIdentity.version) · Commit \(AppIdentity.gitCommit) · gebaut \(AppIdentity.buildDate)")
                .font(.mykMono(10.5))
                .foregroundStyle(MykColor.ink.color)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.muted.color)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, MykSpace.s5)
        .padding(.vertical, MykSpace.s3)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.md)
                .fill(MykColor.card.color)
                .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1))
        )
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
                    Text(version)
                        .font(.mykHeadline)
                        .foregroundStyle(MykColor.paper.color)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: MykSpace.s2) {
                    Text("mykilOS \(version)")
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
    @FocusedBinding(\.paletteOpen)            private var paletteOpen
    @FocusedBinding(\.priceReviewOpen)        private var priceReviewOpen
    @AppStorage("ui.sidebarCollapsed") private var sidebarCollapsed = false

    var body: some Commands {
        CommandGroup(replacing: .newItem) {}
        CommandGroup(replacing: .appInfo) {
            Button("Über mykilOS") {
                openWindow(id: "about")
            }
        }
        // Einstellungen im App-Menü mit dem macOS-Standard Cmd+, (spiegelt den
        // Initialen-Avatar in der Sidebar — Integrationen sind Teil der Einstellungen).
        CommandGroup(replacing: .appSettings) {
            Button("Einstellungen …") { activeModule = .settings }
                .keyboardShortcut(",", modifiers: .command)
        }
        CommandMenu("Navigation") {
            Button("Suchen & Springen …") { paletteOpen = true }
                .keyboardShortcut("k", modifiers: .command)
            Button(sidebarCollapsed ? "Sidebar ausklappen" : "Sidebar einklappen") {
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
            Button("Kataloge")        { activeModule = .kataloge }
                .keyboardShortcut("4", modifiers: .command)
            Button("Einstellungen")   { activeModule = .settings }
                .keyboardShortcut(",", modifiers: .command)
            Divider()
            // Lern-Loop: offene PDF-Positions-Kandidaten freigeben (dauerhaft erreichbar).
            Button("Preis-Wissen freigeben …") { priceReviewOpen = true }
        }
    }
}
