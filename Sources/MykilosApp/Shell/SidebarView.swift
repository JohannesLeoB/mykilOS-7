import SwiftUI
import MykilosDesign

// Einheitliche Initialen (Vorname + Nachname), damit Sidebar-Avatar UND Settings-Avatar
// dasselbe zeigen (Härtung 2026-07-02, Johannes: Initialen waren ungleich). Beispiel:
// „Johannes Leo Berger" → „JB" (nicht „JL" und nicht nur „J").
func mykNameInitials(_ name: String) -> String {
    let words = name.split(separator: " ").filter { !$0.isEmpty }
    guard let first = words.first else { return "?" }
    let firstInitial = first.first.map(String.init) ?? ""
    let lastInitial = words.count > 1 ? (words.last?.first.map(String.init) ?? "") : ""
    let joined = (firstInitial + lastInitial).uppercased()
    return joined.isEmpty ? "?" : joined
}

// MARK: - SidebarView
// Der schmale Rail links. Zwei Zustände: BREIT (Logo + Text-Menüpunkte + App-Dock mit
// Namen) und KOMPAKT (nur Icons). Nie ganz ausgeblendet. Der orange Brand-Button oben
// togglet zwischen den Zuständen. Footer: immer ein Avatar-Kreis (Initialen) + Zahnrad.
struct SidebarView: View {
    @Binding var selection: AppModule
    @Binding var isCompact: Bool
    var onOpenProfile: () -> Void = {}
    // Settings-Sidebar-Modus (2026-07-02, Johannes): der Avatar/MYKILOS-Button
    // wechselt die normale Nav-Sidebar gegen die Einstellungs-Kategorien aus
    // (gleiches Layout). settingsMode = ob wir gerade im Einstellungs-Modul sind.
    var settingsMode: Bool = false
    var settingsCategory: Binding<SettingsCategory>? = nil
    var onExitSettings: () -> Void = {}
    // mykilOS 8, Block B: Klick auf die Aktiv-Timer-Pille öffnet den globalen Check-in.
    @Binding var timerCheckInRequested: Bool
    // Mini-Mode: Halte-Geste am mykilOS-Button (~2 s) startet den Mini-Mode. Der Aufrufer
    // prüft selbst das Opt-in (MiniModeUserPrefs) — ist es aus, feuert das Closure ins Leere
    // und der Button bleibt ein reiner Sidebar-Toggle.
    var onEnterMiniMode: () -> Void = {}
    @Environment(AppState.self) private var appState
    @State private var profileHovered = false
    @State private var brandHovered = false
    // Halte-Geste-Zustand: Fortschritt 0…1 des Füll-Rings + der laufende Timer-Task.
    @State private var holdProgress: CGFloat = 0
    @State private var holdTask: Task<Void, Never>?
    @State private var holdFired = false
    @State private var appShortcuts = AppShortcutStore()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
            Spacer().frame(height: MykSpace.s8)
            navItems
            // mykilOS 8, Block B: minimale Aktiv-Timer-Pille (nur sichtbar wenn ein Timer läuft).
            TimerSidebarPill(compact: isCompact, checkInRequested: $timerCheckInRequested)
                .padding(.top, MykSpace.s4)
            Spacer()
            AppDockStrip(store: appShortcuts, compact: isCompact)
            navFoot
        }
        .padding(.horizontal, MykSpace.s4)
        .padding(.vertical, MykSpace.s7)
        .frame(width: isCompact ? 64 : 212)
        .background(MykColor.paper.color)
        // mykilOS 8, Block B: sanfter Puls über die ganze Sidebar bei Erinnerungs-Marke.
        .background(SidebarPulseBackground())
    }

    // MARK: Brand — toggelt kompakt/breit
    // Design-Hero (2026-07-02): echtes MYKILOS-Wortmarken-SVG statt Platzhalter-Text
    // im Breitmodus — es ist unser eigenes Markenzeichen, keine Lizenzfrage (anders
    // als die Schrift-Dateien, siehe Typography.swift). Kompakt-Modus behält den
    // orangen Marken-Chip (die Wortmarke ist zu breit für ein 26pt-Quadrat).
    // Kurzer Klick = Sidebar schmal/breit (bzw. im Settings-Modus zurück zur Navigation).
    // HALTEN ~2 s = Mini-Mode: ein Füll-Ring läuft um den Chip + der Chip pulst; früher
    // loslassen bricht ab. Kein `Button` + zusätzliche Gesture (die konkurrieren ums
    // Hit-Testing) — ein reines gestengesteuertes View, das selbst zwischen Tap und Hold
    // unterscheidet.
    private var brand: some View {
        HStack(spacing: 11) {
            brandChip
            if !isCompact {
                MykWordmark()
                    .frame(height: 20)
                Spacer()
            }
        }
        .padding(.leading, isCompact ? 0 : MykSpace.s3)
        .frame(maxWidth: .infinity, alignment: isCompact ? .center : .leading)
        .contentShape(Rectangle())
        .onHover { brandHovered = $0 }
        .gesture(brandHoldGesture)
        .help(settingsMode ? "Zurück zur Navigation" : (isCompact ? "Sidebar ausklappen · Halten für Mini-Mode" : "Sidebar einklappen · Halten für Mini-Mode"))
        .accessibilityLabel(settingsMode ? "Zurück zur Navigation" : (isCompact ? "Sidebar ausklappen" : "Sidebar einklappen"))
    }

    private var brandChip: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(MykColor.brand.color)
                .frame(width: 34, height: 34)
                // Pulsieren während des Haltens (zusätzlich zum Hover-Scale).
                .scaleEffect(holdProgress > 0 ? 1.0 + 0.06 * holdProgress : (brandHovered ? 1.08 : 1.0))
            // Füll-Ring: läuft im Uhrzeigersinn voll, während gehalten wird.
            if holdProgress > 0 {
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(MykColor.paper.color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 42, height: 42)
            }
        }
        .frame(width: 42, height: 42)
    }

    // MARK: Halte-Geste
    // DragGesture(minimumDistance: 0) als Presse-Tracker: onChanged startet den Halte-Timer
    // beim ersten Kontakt, onEnded entscheidet zwischen kurzem Klick (Toggle) und
    // abgebrochenem/vollendetem Halten. Erreicht der Timer 1.0, feuert er selbst den
    // Mini-Mode und markiert holdFired, damit onEnded nicht zusätzlich den Klick auslöst.
    private var brandHoldGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if holdTask == nil { startHoldTimer() }
            }
            .onEnded { _ in
                let fired = holdFired
                cancelHoldTimer()
                if !fired { handleShortClick() }
            }
    }

    private func handleShortClick() {
        if settingsMode {
            withAnimation(.easeInOut(duration: 0.2)) { onExitSettings() }
        } else {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) { isCompact.toggle() }
        }
    }

    private func startHoldTimer() {
        holdFired = false
        holdTask = Task { @MainActor in
            let steps = 60          // ~2 s bei 33 ms Schritten
            let stepNanos: UInt64 = 33_000_000
            for step in 1...steps {
                try? await Task.sleep(nanoseconds: stepNanos)
                if Task.isCancelled { return }
                withAnimation(.linear(duration: 0.033)) {
                    holdProgress = CGFloat(step) / CGFloat(steps)
                }
            }
            if !Task.isCancelled {
                holdFired = true
                onEnterMiniMode()
                // Ring nach dem Auslösen zurückfedern.
                withAnimation(.easeOut(duration: 0.2)) { holdProgress = 0 }
            }
        }
    }

    private func cancelHoldTimer() {
        holdTask?.cancel()
        holdTask = nil
        withAnimation(.easeOut(duration: 0.15)) { holdProgress = 0 }
    }

    // MARK: Navigations-Items. Normal: App-Module (ohne Settings). Im Settings-Modus:
    // die Einstellungs-Kategorien (gleiche Zeilen-Optik) — die Sidebar IST dann die
    // Settings-Navigation, der Content zeigt nur noch die gewählte Kategorie.
    @ViewBuilder private var navItems: some View {
        if settingsMode, let category = settingsCategory {
            VStack(spacing: 2) {
                ForEach(SettingsCategory.allCases) { cat in
                    NavItem(title: cat.title, icon: cat.icon, isSelected: category.wrappedValue == cat, compact: isCompact) {
                        withAnimation(.easeInOut(duration: 0.18)) { category.wrappedValue = cat }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 2) {
                ForEach(AppModule.allCases.filter { $0 != .settings }) { module in
                    NavItem(title: module.rawValue, icon: module.icon, isSelected: selection == module, compact: isCompact) {
                        withAnimation(.easeInOut(duration: 0.18)) { selection = module }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Fußzeile — nur noch der Avatar (Initialen). Klick öffnet die Einstellungen
    // (Härtung 2026-07-02, Johannes: kein Zahnrad mehr, alles auf den Initialen-Button).
    private var navFoot: some View {
        Group {
            if isCompact {
                profileButton.frame(maxWidth: .infinity)
            } else {
                // Gleiche Zeilenstruktur wie die App-Dock-Icons: führender Platzhalter-Dot
                // (6 px) + 12 Spacing → der Avatar fluchtet exakt mit der Icon-Spalte.
                HStack(spacing: 12) {
                    Circle().fill(Color.clear).frame(width: 6, height: 6)
                    profileButton
                    Spacer()
                }
                .padding(.horizontal, MykSpace.s4)
            }
        }
        .padding(.top, MykSpace.s2)
        .padding(.bottom, MykSpace.s3)
    }

    // Erscheinungsbild — dieselbe AppStorage-Quelle wie SettingsView/Scene.
    @AppStorage("ui.appearance") private var appearanceRaw = AppAppearance.auto.rawValue

    private var profileButton: some View {
        // Toggle: im Settings-Modus zurück zur normalen Sidebar, sonst Einstellungen öffnen.
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { settingsMode ? onExitSettings() : onOpenProfile() } }) {
            AvatarCircle(initials: initials, online: footIsOnline)
                .scaleEffect(profileHovered ? 1.06 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hover in withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { profileHovered = hover } }
        .help("Einstellungen · \(footDisplayName)")
        .accessibilityLabel("Einstellungen · \(footDisplayName)")
        // Benutzer-Menü (2026-07-02): Rechtsklick → Schnellaktionen, ohne den
        // Primär-Klick (Einstellungen öffnen) zu verändern.
        .contextMenu {
            Section(footDisplayName) {
                Button("Einstellungen öffnen", systemImage: "gearshape") { onOpenProfile() }
            }
            Menu("Erscheinungsbild") {
                ForEach(AppAppearance.allCases, id: \.rawValue) { mode in
                    Button {
                        appearanceRaw = mode.rawValue
                    } label: {
                        Label(mode.label, systemImage: appearanceRaw == mode.rawValue ? "checkmark" : mode.symbol)
                    }
                }
            }
        }
    }

    private var footIsOnline: Bool {
        appState.googleAuth.status == .connected || appState.profile.profile?.isComplete == true
    }

    private var footDisplayName: String {
        if let google = appState.currentGoogleUser, !google.displayName.isEmpty {
            return google.displayName
        }
        let manual = appState.profile.profile?.displayName ?? ""
        return manual.isEmpty ? "Profil einrichten" : manual
    }

    private var initials: String { mykNameInitials(footDisplayName) }
}

// MARK: - AvatarCircle
private struct AvatarCircle: View {
    let initials: String
    let online: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(MykColor.brand.color)
                .frame(width: 28, height: 28)
                .overlay(Text(initials).font(.mykMono(10)).foregroundStyle(MykColor.paper.color))
            if online {
                Circle()
                    .fill(MykColor.positive.color)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(MykColor.paper.color, lineWidth: 1.5))
            }
        }
    }
}

// MARK: - NavItem
// Generische Sidebar-Nav-Zeile (title/icon) — von den App-Modulen UND (im
// Settings-Modus) von den Einstellungs-Kategorien genutzt. Gleiches Design.
private struct NavItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let compact: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            content
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(isSelected ? MykColor.ink.color : (isHovered ? MykColor.paper2.color : Color.clear))
                )
                .foregroundStyle(isSelected ? MykColor.paper.color : MykColor.inkSoft.color)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(compact ? title : "")
        .accessibilityLabel(title)
    }

    @ViewBuilder private var content: some View {
        if compact {
            Image(systemName: icon)
                .font(.mykBody)
                .frame(height: 38)
                .frame(maxWidth: .infinity)
        } else {
            HStack(spacing: 12) {
                Circle()
                    .fill(isSelected ? MykColor.drive.color : MykColor.faint.color)
                    .frame(width: 6, height: 6)
                Text(title).font(.mykBody)
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, MykSpace.s4)
        }
    }
}
