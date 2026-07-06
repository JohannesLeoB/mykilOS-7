import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - SettingsCategory
enum SettingsCategory: String, CaseIterable, Identifiable {
    // Stufe 2, Etappe 1 (2026-07-05): Reihenfolge in privat→geteilt-Bändern
    // (Nutzer-Mentalmodell: erst ich/meine Darstellung + Schlüssel, dann Geteiltes,
    // dann System). rawValues unverändert → @AppStorage-Persistenz bleibt gültig.
    // `.profil` steht oben (wird in Etappe 2 zum Personalausweis-Header).
    case profil, darstellung, privat, schluesselInventar, verbindungen, datenschutz, system
    var id: String { rawValue }
    // E2 (2026-07-05): Der Personalausweis (`.profil`) lebt als sticky Header im
    // Content-Pane, NICHT als Rail-Eintrag. Beide Rails (SettingsView.categoryRail +
    // SidebarView.navItems) iterieren `railCases` statt `allCases`.
    static let railCases: [SettingsCategory] = allCases.filter { $0 != .profil }
    var title: String {
        switch self {
        case .profil:             "Personalausweis"
        case .darstellung:        "Darstellung"
        case .verbindungen:       "Integrationen"
        case .schluesselInventar: "Schlüssel-Inventar"
        case .privat:             "Privat"
        case .datenschutz:        "Datenschutz"
        case .system:             "System"
        }
    }
    var icon: String {
        switch self {
        case .profil:             "person.crop.circle"
        case .darstellung:        "paintbrush"
        case .verbindungen:       "app.connected.to.app.below.fill"
        case .schluesselInventar: "key"
        case .privat:             "lock.shield"
        case .datenschutz:        "hand.raised"
        case .system:             "gearshape.2"
        }
    }
}

// MARK: - SettingsView
struct SettingsView: View {
    // internal (nicht private): die ausgelagerte Extension SettingsView+Personalausweis
    // greift auf appState zu (gleiches Modul), analog zu den @AppStorage-Props für MiniMode.
    @Environment(AppState.self) var appState
    // Item D (2026-07-05): globaler Drive-Sync über alle aktiven Projekt-Ordner an
    // EINEM Ort (Parent-I/O). Der StudioContext ist app-weit injiziert (MykilOS6App).
    @Environment(StudioContext.self) private var context
    @State private var driveSyncing = false
    @State private var driveSyncResult: String?
    @State private var diagnosticsCopied = false
    @State private var profileName: String = ""
    @State private var profileRole: String = ""
    // v28: persönliche Profil-Angaben (Geburtsdatum optional via Toggle, Rest Text).
    // Default-Geburtsdatum 1990-01-01 als Picker-Startwert, bis der Nutzer eins setzt.
    @State private var profileBirthDate: Date = Date(timeIntervalSince1970: 631_152_000)
    @State private var profileHasBirthDate: Bool = false
    @State private var profilePhone: String = ""
    @State private var profileDepartment: String = ""
    @State private var profileBio: String = ""
    @State private var profileSaved = false
    @State private var clockodoUserIDInput: String = ""
    @State private var clientID: String = ""
    @State private var clientSecret: String = ""
    @State private var errorMessage: String?
    @State private var clockodoEmail: String = ""
    @State private var clockodoApiKey: String = ""
    @State private var clockodoError: String?
    @State private var clickUpToken: String = ""
    @State private var clickUpError: String?
    @State private var sevdeskToken: String = ""
    @State private var sevdeskError: String?
    @State private var airtablePAT: String = ""
    @State private var airtableBaseID: String = ""
    @State private var airtableError: String?
    @State private var claudeApiKey: String = ""
    @State private var claudeModel: String = ClaudeAuthService.defaultModel
    @State private var claudeError: String?
    // Multi-User: Abmelden (bestätigungs-gated, destructive).
    @State private var showSignOutConfirm = false
    // E6: Team-Verzeichnis-Eintragung (bestätigungs-gated).
    @State private var showProvisionConfirm = false
    @State private var provisioning = false
    @State private var provisioningResult: String?
    // Backup/Restore-Liste (S2 Stabilitäts-Fundament)
    @State private var backups: [BackupService.BackupInfo] = []
    @State private var restoreConfirm: BackupService.BackupInfo? = nil
    @State private var restoreStagedName: String? = nil

    // Zweispaltige Einstellungsebene (2026-07-02, Johannes: „Benutzer-Menü + Einstellungs-
    // ebene ausbauen"). Kategorie-Rail links (wie macOS-Systemeinstellungen) statt eines
    // endlosen Scrolls; die Sektionen selbst bleiben unverändert.
    // 2026-07-02: Die Kategorie kann EXTERN gesteuert werden — dann lebt die Rail in der
    // Sidebar (Settings-Sidebar-Modus) und hier bleibt nur der Content. `nil` = eigenständig.
    var externalCategory: Binding<SettingsCategory>? = nil
    @State private var internalCategory: SettingsCategory = .profil
    var category: SettingsCategory { externalCategory?.wrappedValue ?? internalCategory }
    func selectCategory(_ c: SettingsCategory) {
        if let e = externalCategory { e.wrappedValue = c } else { internalCategory = c }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Im Settings-Sidebar-Modus (externalCategory gesetzt) lebt die Kategorie-Rail
            // in der Sidebar — hier bleibt nur der Content.
            if externalCategory == nil {
                categoryRail
                Divider().overlay(MykColor.line.color)
            }
            // E2: Personalausweis als sticky Header über dem scrollenden Inhalt.
            VStack(spacing: 0) {
                personalausweisHeader
                Divider().overlay(MykColor.line.color)
                ScrollView {
                    VStack(alignment: .leading, spacing: MykSpace.s7) {
                        // Der .profil-Detailtitel ist redundant zum Header → nur bei anderen
                        // Kategorien den großen Kategorie-Titel zeigen.
                        if category != .profil {
                            HStack(spacing: MykSpace.s4) {
                                Image(systemName: category.icon).font(.mykTitle).foregroundStyle(MykColor.brand.color)
                                Text(category.title).font(.mykDisplay).foregroundStyle(MykColor.ink.color)
                            }
                        }
                        categoryContent
                        Spacer()
                    }
                    .padding(MykSpace.s9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .background(MykColor.paper.color)
        .task {
            if let p = appState.profile.profile {
                profileName = p.displayName
                profileRole = p.role
                clockodoUserIDInput = p.clockodoUserID ?? ""
                profileHasBirthDate = p.birthDate != nil
                if let bd = p.birthDate { profileBirthDate = bd }
                profilePhone = p.phone ?? ""
                profileDepartment = p.department ?? ""
                profileBio = p.bio ?? ""
            }
            clientID = (try? appState.googleAuth.storedClientID()) ?? ""
            clientSecret = (try? appState.googleAuth.storedClientSecret()) ?? ""
            if let creds = try? appState.clockodoAuth.storedCredentials() {
                clockodoEmail = creds.email
                clockodoApiKey = creds.apiKey
            }
            if let creds = try? appState.clickUpAuth.storedCredentials() {
                clickUpToken = creds.apiToken
            }
            if let creds = try? appState.sevdeskAuth.storedCredentials() {
                sevdeskToken = creds.apiToken
            }
            if let creds = try? appState.airtableAuth.storedCredentials() {
                airtablePAT = creds.pat
                airtableBaseID = creds.baseID
            }
            if let creds = try? appState.claudeAuth.storedCredentials() {
                claudeApiKey = creds.apiKey
                claudeModel = creds.model
            }
        }
    }

    // MARK: - Kategorie-Rail + Content
    private var categoryRail: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Einstellungen")
                .font(.mykMono(10)).tracking(1.2).textCase(.uppercase)
                .foregroundStyle(MykColor.muted.color)
                .padding(.horizontal, MykSpace.s4).padding(.bottom, MykSpace.s4).padding(.top, MykSpace.s2)
            ForEach(SettingsCategory.railCases) { cat in
                Button { withAnimation(.easeInOut(duration: 0.15)) { selectCategory(cat) } } label: {
                    HStack(spacing: MykSpace.s4) {
                        Image(systemName: cat.icon).font(.mykBody).frame(width: 20)
                        Text(cat.title).font(.mykBody)
                        Spacer()
                    }
                    .padding(.vertical, 9).padding(.horizontal, MykSpace.s4)
                    .background(
                        RoundedRectangle(cornerRadius: MykRadius.sm)
                            .fill(category == cat ? MykColor.ink.color : Color.clear)
                    )
                    .foregroundStyle(category == cat ? MykColor.paper.color : MykColor.inkSoft.color)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Einstellungen: \(cat.title)")
            }
            Spacer()
        }
        .padding(MykSpace.s5)
        .frame(width: 208)
        .background(MykColor.paper2.color)
    }

    @ViewBuilder private var categoryContent: some View {
        switch category {
        case .profil:
            identitySection
            mailSignaturSection
        case .darstellung:
            darstellungSection
        case .verbindungen:
            integrationStatusSection
            googleSection
            airtableSection
            clickUpSection
            sevdeskSection
            claudeSection
        case .schluesselInventar:
            KeychainInventoryView()
        case .privat:
            privateAreaSection
        case .datenschutz:
            datenschutzFreigabenSection
            MitteilungenSectionView()
            miniModeSection
        case .system:
            diagnoseSection
            ordnerSchemaSection
            mykInviteSection
            SchaltzentrumView()
        }
    }

    // MARK: - Darstellung (Hell/Dunkel/Auto)
    // Per-Nutzer-Wahl (AppStorage `ui.appearance`) — dieselbe Quelle wie die Scene
    // in MykilOS6App. Nicht mehr stur nach System.
    @AppStorage("ui.appearance") private var appearanceRaw = AppAppearance.auto.rawValue
    @AppStorage("ui.rainbowMode") private var rainbowMode = false
    // v28: welche Seite mykilOS direkt nach dem Start zeigt (MykilOS6App liest
    // denselben Key beim Aufbau der Root-View). settings ist bewusst kein Start-Ziel.
    @AppStorage("ui.startView") private var startViewRaw = AppModule.today.rawValue

    // Module, die als Start-Ansicht sinnvoll sind (ohne Einstellungen selbst).
    private var startableModules: [AppModule] { [.today, .projects, .assistant, .kataloge] }

    private var darstellungSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Darstellung & Fenster")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            Text("ERSCHEINUNGSBILD")
                .font(.mykMono(10)).tracking(1.5)
                .foregroundStyle(MykColor.muted.color)
            Picker("", selection: $appearanceRaw) {
                ForEach(AppAppearance.allCases) { mode in
                    Label(mode.label, systemImage: mode.symbol).tag(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 360, alignment: .leading)

            // v28: Start-Ansicht — welche Seite nach dem Öffnen zuerst erscheint.
            Text("START-ANSICHT")
                .font(.mykMono(10)).tracking(1.5)
                .foregroundStyle(MykColor.muted.color)
            Picker("", selection: $startViewRaw) {
                ForEach(startableModules) { mode in
                    Label(mode.rawValue, systemImage: mode.icon).tag(mode.rawValue)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(maxWidth: 260, alignment: .leading)
            Text("Diese Seite zeigt mykilOS direkt nach dem Start.")
                .font(.mykMono(9)).foregroundStyle(MykColor.faint.color)

            Toggle(isOn: $rainbowMode) {
                Label("Rainbow Mode 🌈", systemImage: "paintpalette")
                    .font(.mykSmall)
            }
            .toggleStyle(.switch)

            Divider().overlay(MykColor.line.color)

            // Mini-Mode Opt-in (Ansichts-Option). Default aus — bewusste Entscheidung.
            Text("MINI-MODE")
                .font(.mykMono(10)).tracking(1.5)
                .foregroundStyle(MykColor.muted.color)
            Toggle(isOn: $miniModeViewEnabled) {
                Label("Mini-Mode erlauben", systemImage: "rectangle.trailinghalf.inset.filled.arrow.trailing")
                    .font(.mykSmall)
            }
            .toggleStyle(.switch)
            Text("Wenn aktiv: den mykilOS-Button oben links ~2 s HALTEN schrumpft die App "
                 + "auf ein schmales, schwebendes Icon-Rail, das über Vollbild-Programmen "
                 + "(z. B. Vectorworks) obenauf bleibt und nie den Fokus stiehlt. Klick aufs "
                 + "Logo im Rail holt die volle App zurück. Ist der Schalter aus, bleibt der "
                 + "Button ein reiner Sidebar-Umschalter.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // Mini-Mode-Opt-in — MUSS mit MiniModeUserPrefs.enabledKey übereinstimmen (der
    // MiniModeController liest exakt diesen UserDefaults-Schlüssel). Default aus.
    @AppStorage("ui.miniMode.enabled") private var miniModeViewEnabled = false

    // MARK: - Identität

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Wer bin ich?")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            if let user = appState.currentGoogleUser {
                HStack(spacing: MykSpace.s4) {
                    Circle()
                        .fill(MykColor.positive.color.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .overlay(
                            // Gleiche Initialen-Logik wie der Sidebar-Avatar (Vorname+Nachname).
                            Text(mykNameInitials(user.displayName))
                                .font(.mykHeadline)
                                .foregroundStyle(MykColor.positive.color)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName)
                            .font(.mykBody)
                            .foregroundStyle(MykColor.ink.color)
                        Text(user.email)
                            .font(.mykMono(10))
                            .foregroundStyle(MykColor.muted.color)
                        if let domain = user.domain {
                            Text(domain)
                                .font(.mykMono(9))
                                .foregroundStyle(MykColor.faint.color)
                        }
                    }
                }
            } else {
                HStack(spacing: MykSpace.s3) {
                    Circle().fill(MykColor.faint.color).frame(width: 7, height: 7)
                    Text("Google noch nicht verbunden — Name erscheint nach Login")
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.muted.color)
                }
            }
            Divider()
            TextField("Anzeigename (lokal)", text: $profileName)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            TextField("Rolle (z. B. Design & Projektleitung)", text: $profileRole)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            // v28: persönliche Angaben — „richtiges" Profil. Rein lokal.
            TextField("Telefon", text: $profilePhone)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            TextField("Abteilung / Bereich", text: $profileDepartment)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            TextField("Über mich", text: $profileBio, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            Toggle(isOn: $profileHasBirthDate) {
                Text("Geburtsdatum").font(.mykMono(12)).foregroundStyle(MykColor.ink.color)
            }
            .toggleStyle(.switch)
            if profileHasBirthDate {
                DatePicker("", selection: $profileBirthDate, in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.field)
            }
            HStack(spacing: MykSpace.s4) {
                Button("Speichern") { saveProfile() }
                    .disabled(!profileDirty)
                if profileDirty {
                    Button("Abbrechen") {
                        profileName = storedProfileName
                        profileRole = storedProfileRole
                        resetPersonalProfileFields()
                    }
                    .buttonStyle(.plain)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
                } else if profileSaved {
                    Text("Gespeichert")
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.positive.color)
                }
            }
            // UI-Polish (2026-07-02, Johannes): Erklärtext („fließen in den System-Prompt…")
            // entfernt — Mock-up-Überbleibsel, Detail steht im Benutzerhandbuch.

            // E6: sich selbst (bestätigungs-gated) ins geteilte Team-Verzeichnis eintragen.
            if appState.currentGoogleUser != nil {
                Divider()
                Text("TEAM-VERZEICHNIS")
                    .font(.mykMono(9)).tracking(1.2).foregroundStyle(MykColor.muted.color)
                HStack(spacing: MykSpace.s4) {
                    Button("Ins Team-Verzeichnis eintragen") { showProvisionConfirm = true }
                        .disabled(provisioning)
                    if provisioning {
                        Text("Trage ein…").font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
                    } else if let provisioningResult {
                        Text(provisioningResult).font(.mykMono(10)).foregroundStyle(MykColor.positive.color)
                    }
                }
                Text("Trägt dich (Name + Mail) einmalig ins geteilte Team-Verzeichnis (Airtable) ein — "
                     + "idempotent, nie löschend. Deine Bestätigung ist der Absender.")
                    .font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Multi-User: Abmelden — trennt alle 6 Integrationen, gibt den
            // Namespace frei, startet die App neu. Geteilte Team-Daten
            // (Airtable/Projekte) bleiben unberührt (kein clearLocalCache).
            Divider()
            Button("Abmelden (dieses Gerät)", role: .destructive) { showSignOutConfirm = true }
            Text("Trennt Google/Clockodo/ClickUp/Sevdesk/Airtable/Claude, meldet dich ab und startet "
                 + "die App neu. Der nächste Bewohner startet dann sauber isoliert — deine Daten bleiben "
                 + "erhalten (per Mail-Login wiedererkannt), geteilte Team-Daten sind unberührt.")
                .font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MykSpace.s6)
        .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1))
        .confirmationDialog("Ins Team-Verzeichnis eintragen?",
                            isPresented: $showProvisionConfirm, titleVisibility: .visible) {
            Button("Eintragen") { runProvision() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Legt einen Menschen-Record (Name + Mail) in der geteilten Airtable-Tabelle "
                 + "Clockodo-Nutzer an, falls noch keiner mit deiner Mail existiert. Append-only, kein Doppel.")
        }
        .confirmationDialog("Wirklich abmelden?",
                            isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Abmelden + App neu starten", role: .destructive) {
                appState.signOutEverywhere()
                AppRelaunch.relaunch()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Trennt alle deine persönlichen Integrationen auf diesem Gerät und startet die App neu. "
                 + "Geteilte Team-Daten (Airtable-Projekte) bleiben unberührt.")
        }
    }

    // E6: bestätigte Team-Verzeichnis-Eintragung ausführen (async, Ergebnis sichtbar).
    private func runProvision() {
        provisioning = true
        provisioningResult = nil
        Task {
            let recordID = await appState.provisionCurrentUserIntoTeamDirectory()
            provisioning = false
            provisioningResult = recordID != nil ? "Eingetragen ✓" : "Fehlgeschlagen — Airtable verbunden?"
        }
    }

    // MARK: - Mail-Signatur

    /// Signatur wird per @AppStorage gespeichert (UserDefaults) — kein GRDB nötig,
    /// rein lokaler Einstellungswert. ComposeMailView liest dieselbe Key "mail.signature"
    /// und hängt sie beim Anlegen des Entwurfs an den Body an (Gmail macht das NICHT automatisch).
    @AppStorage("mail.signature") private var mailSignature: String = ""

    private var mailSignaturSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            HStack {
                Image(systemName: "signature")
                    .foregroundStyle(MykColor.personal.color)
                Text("Mail-Signatur")
                    .font(.mykHeadline)
                    .foregroundStyle(MykColor.ink.color)
            }
            // UI-Polish (2026-07-02, Johannes): Erklärtext entfernt (Mock-up-Überbleibsel);
            // das Gmail-API-Detail steht im Benutzerhandbuch + als Code-Kommentar oben.
            TextEditor(text: $mailSignature)
                .font(.mykMono(11))
                .foregroundStyle(MykColor.ink.color)
                .scrollContentBackground(.hidden)
                .padding(MykSpace.s3)
                .frame(minHeight: 90, maxHeight: 160)
                .background(
                    RoundedRectangle(cornerRadius: MykRadius.sm)
                        .fill(MykColor.paper.color)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MykRadius.sm)
                        .stroke(MykColor.line.color, lineWidth: 1)
                )
            // Quellzeile im Design-System-Stil (SaveState sichtbar = Eiserne Regel) —
            // das technische „(UserDefaults)"-Detail ist raus (UI-Polish 2026-07-02).
            Text("LOKAL · SOFORT GESPEICHERT")
                .font(.mykMono(9))
                .foregroundStyle(MykColor.faint.color)
        }
        .padding(MykSpace.s6)
        .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1))
    }

    // Dirty-State fürs Profil: Speichern nur aktiv bei echter Änderung, „Abbrechen"
    // stellt den gespeicherten Stand wieder her (kein stiller Verlust bei Kategoriewechsel).
    private var storedProfile: UserProfile? { appState.profile.profile }
    private var storedProfileName: String { storedProfile?.displayName ?? "" }
    private var storedProfileRole: String { storedProfile?.role ?? "" }
    // v28: Geburtsdatum-Dirty separat — Toggle-Wechsel ODER geändertes Datum
    // (Sekunden-Toleranz gegen Sub-Sekunden-Rauschen beim Picker-Roundtrip).
    private var birthDateDirty: Bool {
        let storedHas = storedProfile?.birthDate != nil
        if profileHasBirthDate != storedHas { return true }
        if profileHasBirthDate, let stored = storedProfile?.birthDate {
            return abs(profileBirthDate.timeIntervalSince1970 - stored.timeIntervalSince1970) > 1
        }
        return false
    }
    private var profileDirty: Bool {
        profileName != storedProfileName
            || profileRole != storedProfileRole
            || profilePhone != (storedProfile?.phone ?? "")
            || profileDepartment != (storedProfile?.department ?? "")
            || profileBio != (storedProfile?.bio ?? "")
            || birthDateDirty
    }

    // v28: persönliche Felder auf den gespeicherten Stand zurücksetzen („Abbrechen").
    private func resetPersonalProfileFields() {
        profilePhone = storedProfile?.phone ?? ""
        profileDepartment = storedProfile?.department ?? ""
        profileBio = storedProfile?.bio ?? ""
        profileHasBirthDate = storedProfile?.birthDate != nil
        if let bd = storedProfile?.birthDate { profileBirthDate = bd }
    }

    private func saveProfile() {
        profileSaved = false
        let existing = appState.profile.profile
        do {
            // V10 Folge-Block A: userID unverändert mitführen — sonst würde
            // jedes Settings-Save die stabile Keychain-userID auf nil zurücksetzen.
            // v28: leere Textfelder als nil speichern (kein "" statt echter Angabe).
            try appState.profile.save(UserProfile(
                displayName: profileName,
                role: profileRole,
                updatedAt: Date(),
                clockodoUserID: clockodoUserIDInput.isEmpty ? nil : clockodoUserIDInput,
                googleDomain: existing?.googleDomain ?? appState.currentGoogleUser?.domain,
                userID: existing?.userID,
                birthDate: profileHasBirthDate ? profileBirthDate : nil,
                phone: profilePhone.isEmpty ? nil : profilePhone,
                department: profileDepartment.isEmpty ? nil : profileDepartment,
                bio: profileBio.isEmpty ? nil : profileBio
            ))
            profileSaved = true
        } catch {}
    }

    // MARK: - Integrations-Status (Traffic-Light)

    private var integrationStatusSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            Text("Verbindungsstatus")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            HStack(spacing: MykSpace.s5) {
                statusLight("Google",   color: googleStatusColor)
                statusLight("Airtable", color: airtableStatusColor)
                statusLight("ClickUp",  color: clickUpStatusColor)
                statusLight("Sevdesk",  color: sevdeskStatusColor)
                statusLight("Claude",   color: claudeStatusColor)
                statusLight("Clockodo", color: clockodoStatusColor)
            }
        }
        .padding(MykSpace.s6)
        .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1))
    }

    private func statusLight(_ label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.mykMono(8.5)).foregroundStyle(MykColor.muted.color)
        }
    }

    private var googleStatusColor: Color {
        switch appState.googleAuth.status {
        case .connected:    MykColor.positive.color
        case .connecting:   MykColor.tasks.color
        case .disconnected: MykColor.faint.color
        case .error:        MykColor.critical.color
        }
    }
    private var airtableStatusColor: Color {
        switch appState.airtableAuth.status {
        case .connected:    MykColor.positive.color
        case .syncing:      MykColor.tasks.color
        case .disconnected: MykColor.faint.color
        case .error:        MykColor.critical.color
        }
    }
    private var clickUpStatusColor: Color {
        switch appState.clickUpAuth.status {
        case .connected:    MykColor.positive.color
        case .disconnected: MykColor.faint.color
        case .error:        MykColor.critical.color
        }
    }
    private var sevdeskStatusColor: Color {
        switch appState.sevdeskAuth.status {
        case .connected:    MykColor.positive.color
        case .disconnected: MykColor.faint.color
        case .error:        MykColor.critical.color
        }
    }
    private var claudeStatusColor: Color {
        switch appState.claudeAuth.status {
        case .connected:    MykColor.positive.color
        case .disconnected: MykColor.faint.color
        case .error:        MykColor.critical.color
        }
    }
    private var clockodoStatusColor: Color {
        switch appState.clockodoAuth.status {
        case .connected:    MykColor.positive.color
        case .disconnected: MykColor.faint.color
        case .error:        MykColor.critical.color
        }
    }

    // MARK: - Google

    @ViewBuilder private var googleSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Google Workspace")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            serviceStatusBadge(color: googleStatusColor, text: googleStatusText)
            // Onboarding-Plan Ebene 1: ist ein Client-ID/Secret eingebacken (Build-Zeit-Inject,
            // script/build_and_run.sh), braucht der Nutzer NIE ein Formular auszufüllen — nur
            // "Verbinden" tippen. Kein Bundle-Wert (Normalfall ohne die lokale Secrets-Datei)?
            // Exakt das bisherige manuelle Formular als Notausgang.
            if BundledGoogleOAuthConfig.istVerfuegbar == false {
                TextField("OAuth-Client-ID (Desktop App)", text: $clientID)
                    .textFieldStyle(.roundedBorder)
                    .font(.mykMono(12))
                SecureField("Client-Secret (nur falls Google es verlangt)", text: $clientSecret)
                    .textFieldStyle(.roundedBorder)
                    .font(.mykMono(12))
            }
            HStack(spacing: MykSpace.s4) {
                Button(connectLabel) { connect() }
                    .disabled(appState.googleAuth.status == .connecting)
                if appState.googleAuth.status == .connected {
                    Button("Trennen", role: .destructive) { disconnect() }
                }
            }
            if let errorMessage {
                Text(errorMessage).font(.mykMono(10)).foregroundStyle(MykColor.critical.color)
            }
            Text("Nur Lesezugriff (Drive-Metadaten, Kalender, Gmail, Kontakte) — keine Schreibrechte.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)
            if appState.googleAuth.status == .connected {
                Divider().overlay(MykColor.line.color)
                driveSyncRow
            }
        }
        .settingsCard()

        if appState.googleAuth.status == .connected && appState.airtableAuth.status == .connected {
            ContactsImportView()
        }
    }

    // Item D (2026-07-05): der EINE globale Drive-Sync über alle aktiven Projekt-Ordner
    // (Parent-I/O: gehört zu Google/Drive). Ersetzt die verstreuten „Jetzt prüfen"-Leisten
    // in Heute + Dateien-Tab. Nutzt exakt dieselbe Logik wie der 300s-Hintergrund-Loop.
    private var driveSyncRow: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            HStack(spacing: MykSpace.s4) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(MykColor.drive.color)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Drive-Ordner synchronisieren")
                        .font(.mykBody).foregroundStyle(MykColor.ink.color)
                    Text("Prüft alle aktiven Projekt-Ordner in einem Durchgang.")
                        .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                }
                Spacer()
                Button(driveSyncing ? "Synchronisiert…" : "Jetzt synchronisieren") {
                    Task { await syncAllDrive() }
                }
                .font(.mykMono(10))
                .foregroundStyle(driveSyncing ? MykColor.muted.color : MykColor.drive.color)
                .buttonStyle(.plain)
                .disabled(driveSyncing)
            }
            if let driveSyncResult {
                Text(driveSyncResult)
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.muted.color)
            }
        }
    }

    private func syncAllDrive() async {
        driveSyncing = true
        driveSyncResult = nil
        let count = await appState.pollAllActiveProjectsForOffers(into: context)
        driveSyncResult = count > 0
            ? "Fertig · \(count) neue Belege gefunden."
            : "Fertig · keine neuen Belege."
        driveSyncing = false
    }

    private var googleStatusText: String {
        switch appState.googleAuth.status {
        case .connected:          "VERBUNDEN"
        case .connecting:         "VERBINDET…"
        case .disconnected:       "NICHT VERBUNDEN"
        case .error(let message): "FEHLER · \(message)"
        }
    }
    private var connectLabel: String {
        switch appState.googleAuth.status {
        case .connected:  "Erneut verbinden"
        case .connecting: "Verbindet…"
        default:          "Verbinden"
        }
    }
    private func connect() {
        errorMessage = nil
        let id = BundledGoogleOAuthConfig.clientID ?? clientID
        let secret = BundledGoogleOAuthConfig.clientSecret ?? clientSecret
        Task {
            do { try await appState.googleAuth.startAuthorization(clientID: id, clientSecret: secret) }
            catch { errorMessage = "Verbindung fehlgeschlagen: \(error)" }
        }
    }
    private func disconnect() {
        do { try appState.googleAuth.disconnect() }
        catch { errorMessage = "Trennen fehlgeschlagen: \(error)" }
    }

    // MARK: - Airtable

    private var airtableSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Airtable Projektdaten")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            serviceStatusBadge(color: airtableStatusColor, text: airtableStatusText)
            TextField("Base-ID (z. B. appXYZ123)", text: $airtableBaseID)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            SecureField("Personal Access Token", text: $airtablePAT)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            HStack(spacing: MykSpace.s4) {
                Button(airtableConnectLabel) { connectAirtable() }
                    .disabled(appState.airtableAuth.status == .syncing)
                if appState.airtableAuth.status == .connected {
                    Button("Jetzt synchronisieren") { syncAirtable() }
                    Button("Trennen", role: .destructive) { disconnectAirtable() }
                }
            }
            if let airtableError {
                Text(airtableError).font(.mykMono(10)).foregroundStyle(MykColor.critical.color)
            }
            Divider()
            HStack(spacing: MykSpace.s4) {
                Button("Projekt-Cache leeren") {
                    Task { await appState.registry.clearLocalCache() }
                }
                .foregroundStyle(MykColor.muted.color)
                Text("Lädt Seed-Daten neu. Airtable-Sync danach empfohlen.")
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.faint.color)
            }
            Text("PAT unter airtable.com/create/tokens erstellen. Benötigt data.records:read auf die Base.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)
        }
        .settingsCard()
    }

    private var airtableStatusText: String {
        switch appState.airtableAuth.status {
        case .connected:          "VERBUNDEN"
        case .syncing:            "SYNCHRONISIERT…"
        case .disconnected:       "NICHT VERBUNDEN"
        case .error(let message): "FEHLER · \(message)"
        }
    }
    private var airtableConnectLabel: String {
        switch appState.airtableAuth.status {
        case .connected: "Erneut verbinden"
        case .syncing:   "Synchronisiert…"
        default:         "Verbinden"
        }
    }
    private func connectAirtable() {
        airtableError = nil
        do { try appState.airtableAuth.connect(pat: airtablePAT, baseID: airtableBaseID) }
        catch { airtableError = "Verbindung fehlgeschlagen: \(error)" }
    }
    private func syncAirtable() {
        airtableError = nil
        Task { await appState.registry.syncFromAirtable(baseID: airtableBaseID, auth: appState.airtableAuth) }
    }
    private func disconnectAirtable() {
        do { try appState.airtableAuth.disconnect(); airtablePAT = ""; airtableBaseID = "" }
        catch { airtableError = "Trennen fehlgeschlagen: \(error)" }
    }

    // MARK: - ClickUp

    @ViewBuilder private var clickUpSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("ClickUp Aufgaben")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            serviceStatusBadge(color: clickUpStatusColor, text: clickUpStatusText)
            SecureField("Personal API-Token (pk_…)", text: $clickUpToken)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            HStack(spacing: MykSpace.s4) {
                Button(clickUpConnectLabel) { connectClickUp() }
                if appState.clickUpAuth.status == .connected {
                    Button("Trennen", role: .destructive) { disconnectClickUp() }
                }
            }
            if let clickUpError {
                Text(clickUpError).font(.mykMono(10)).foregroundStyle(MykColor.critical.color)
            }
            Text("Token unter clickup.com → Settings → Apps erstellen. Nur Lesezugriff auf die im Projekt verlinkte Liste.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)
        }
        .settingsCard()

        if appState.clickUpAuth.status == .connected {
            ClickUpTestWerkbankView()
        }
    }

    private var clickUpStatusText: String {
        switch appState.clickUpAuth.status {
        case .connected:          "VERBUNDEN"
        case .disconnected:       "NICHT VERBUNDEN"
        case .error(let message): "FEHLER · \(message)"
        }
    }
    private var clickUpConnectLabel: String { appState.clickUpAuth.status == .connected ? "Erneut verbinden" : "Verbinden" }
    private func connectClickUp() {
        clickUpError = nil
        do { try appState.clickUpAuth.connect(apiToken: clickUpToken) }
        catch { clickUpError = "Verbindung fehlgeschlagen: \(error)" }
    }
    private func disconnectClickUp() {
        do { try appState.clickUpAuth.disconnect(); clickUpToken = "" }
        catch { clickUpError = "Trennen fehlgeschlagen: \(error)" }
    }

    // MARK: - Sevdesk

    private var sevdeskSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Sevdesk Umsatz")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            serviceStatusBadge(color: sevdeskStatusColor, text: sevdeskStatusText)
            SecureField("API-Token", text: $sevdeskToken)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            HStack(spacing: MykSpace.s4) {
                Button(sevdeskConnectLabel) { connectSevdesk() }
                if appState.sevdeskAuth.status == .connected {
                    Button("Trennen", role: .destructive) { disconnectSevdesk() }
                }
            }
            if let sevdeskError {
                Text(sevdeskError).font(.mykMono(10)).foregroundStyle(MykColor.critical.color)
            }
            Text("Token unter sevdesk.de → Einstellungen → Benutzer → API. Nur Lesezugriff: speist den Ist-Umsatz im Budget-Balken.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)
        }
        .settingsCard()
    }

    private var sevdeskStatusText: String {
        switch appState.sevdeskAuth.status {
        case .connected:          "VERBUNDEN"
        case .disconnected:       "NICHT VERBUNDEN"
        case .error(let message): "FEHLER · \(message)"
        }
    }
    private var sevdeskConnectLabel: String { appState.sevdeskAuth.status == .connected ? "Erneut verbinden" : "Verbinden" }
    private func connectSevdesk() {
        sevdeskError = nil
        do { try appState.sevdeskAuth.connect(apiToken: sevdeskToken) }
        catch { sevdeskError = "Verbindung fehlgeschlagen: \(error)" }
    }
    private func disconnectSevdesk() {
        do { try appState.sevdeskAuth.disconnect(); sevdeskToken = "" }
        catch { sevdeskError = "Trennen fehlgeschlagen: \(error)" }
    }

    // MARK: - Claude

    private var claudeSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Claude Assistent")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            serviceStatusBadge(color: claudeStatusColor, text: claudeStatusText)
            SecureField("Anthropic API-Key", text: $claudeApiKey)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            TextField("Modell", text: $claudeModel)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            HStack(spacing: MykSpace.s4) {
                Button(claudeConnectLabel) { connectClaude() }
                if appState.claudeAuth.status == .connected {
                    Button("Trennen", role: .destructive) { disconnectClaude() }
                }
            }
            if let claudeError {
                Text(claudeError).font(.mykMono(10)).foregroundStyle(MykColor.critical.color)
            }
            Text("Nutzt den Keychain. Der Assistent erzeugt nur Zusammenfassungen; Schreibaktionen bleiben bestätigungspflichtig.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)
        }
        .settingsCard()
    }

    private var claudeStatusText: String {
        switch appState.claudeAuth.status {
        case .connected:          "VERBUNDEN"
        case .disconnected:       "NICHT VERBUNDEN"
        case .error(let message): "FEHLER · \(message)"
        }
    }
    private var claudeConnectLabel: String { appState.claudeAuth.status == .connected ? "Erneut verbinden" : "Verbinden" }
    private func connectClaude() {
        claudeError = nil
        do {
            try appState.claudeAuth.connect(apiKey: claudeApiKey, model: claudeModel)
            claudeModel = (try appState.claudeAuth.storedCredentials())?.model ?? ClaudeAuthService.defaultModel
        } catch { claudeError = "Verbindung fehlgeschlagen: \(error)" }
    }
    private func disconnectClaude() {
        do { try appState.claudeAuth.disconnect(); claudeApiKey = ""; claudeModel = ClaudeAuthService.defaultModel }
        catch { claudeError = "Trennen fehlgeschlagen: \(error)" }
    }

    // MARK: - Datenschutz → Mini-Mode
    // Master-Schalter (Puls an/aus) + je ein Schalter pro Aufmerksamkeits-Quelle. Alle
    // default = an; die Schlüssel MÜSSEN mit MiniModeDefaults / MiniModeSource.defaultsKey
    // übereinstimmen (der MiniModeStore/MiniModeRailView liest exakt diese UserDefaults).
    // Dezent + jederzeit abschaltbar (eiserne Alerts-Regel): Master aus → kein Orange-Puls
    // im Mini-Rail, keine Quelle wird mehr gelesen.
    // `miniModeSection` selbst lebt in SettingsView+MiniMode.swift (swiftlint file_length) —
    // die @AppStorage-Properties bleiben hier, weil Extensions keine stored properties
    // hinzufügen dürfen; daher ohne `private`, damit die Extension-Datei im selben
    // Modul darauf zugreifen kann (kein externes Modul sieht diesen Typ von außen anders
    // an als vorher — SettingsView ist ohnehin `internal`/nicht public).
    @AppStorage("privacy.miniMode.enabled")  var miniModeEnabled = true
    @AppStorage("privacy.miniMode.calendar") var miniModeCalendar = true
    @AppStorage("privacy.miniMode.tasks")    var miniModeTasks = true
    @AppStorage("privacy.miniMode.mail")     var miniModeMail = true
    @AppStorage("privacy.miniMode.timer")    var miniModeTimer = true
    @AppStorage("privacy.miniMode.signals")  var miniModeSignals = true

    // MARK: - Private Area (Clockodo — datensensitiv)

    private var privateAreaSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "lock.fill")
                    .font(.mykMono(11))
                    .foregroundStyle(MykColor.brand.color)
                Text("PRIVATE AREA")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.brand.color)
                    .tracking(1.5)
            }
            Text("Clockodo Zeiterfassung")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            Text("Persönliche Credentials — nur du siehst deine Zeiteinträge.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
            serviceStatusBadge(color: clockodoStatusColor, text: clockodoStatusText)
            TextField("E-Mail (Clockodo-Account)", text: $clockodoEmail)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            SecureField("API-Key", text: $clockodoApiKey)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            TextField("Clockodo User-ID (optional)", text: $clockodoUserIDInput)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            HStack(spacing: MykSpace.s4) {
                Button(clockodoConnectLabel) { connectClockodo() }
                if appState.clockodoAuth.status == .connected {
                    Button("Speichern & Verbinden") { connectClockodoAndSave() }
                    Button("Trennen", role: .destructive) { disconnectClockodo() }
                }
            }
            if let clockodoError {
                Text(clockodoError).font(.mykMono(10)).foregroundStyle(MykColor.critical.color)
            }
            Text("API-Key: clockodo.com → Einstellungen → API. Deine Buchungen sind nur für dich sichtbar.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)
        }
        .padding(MykSpace.s6)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.md)
                .fill(MykColor.brand.color.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: MykRadius.md)
                .stroke(MykColor.brand.color.opacity(0.25), lineWidth: 1)
        )
    }

    private var clockodoStatusText: String {
        switch appState.clockodoAuth.status {
        case .connected:          "VERBUNDEN"
        case .disconnected:       "NICHT VERBUNDEN"
        case .error(let message): "FEHLER · \(message)"
        }
    }
    private var clockodoConnectLabel: String { appState.clockodoAuth.status == .connected ? "Erneut verbinden" : "Verbinden" }
    private func connectClockodo() {
        clockodoError = nil
        do { try appState.clockodoAuth.connect(email: clockodoEmail, apiKey: clockodoApiKey) }
        catch { clockodoError = "Verbindung fehlgeschlagen: \(error)" }
    }
    private func connectClockodoAndSave() {
        connectClockodo()
        saveProfile()
    }
    private func disconnectClockodo() {
        do { try appState.clockodoAuth.disconnect(); clockodoEmail = ""; clockodoApiKey = "" }
        catch { clockodoError = "Trennen fehlgeschlagen: \(error)" }
    }

    // MARK: - Diagnose (Mandate A) — Version · Commit · Pfade, sichtbar in Settings

    private var diagnoseSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            Text("Diagnose")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            Text("App-Identität für Support & Fehlersuche — keine Tokens, keine Keychain-Daten.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
            VStack(alignment: .leading, spacing: MykSpace.s3) {
                diagRow("Version", "\(AppIdentity.version) (Build \(AppIdentity.build))")
                diagRow("Commit",  AppIdentity.gitCommit)
                diagRow("Branch",  AppIdentity.gitBranch)
                diagRow("Gebaut",  AppIdentity.buildDate)
                diagRow("Bundle",  AppIdentity.bundlePath)
                diagRow("DB",      AppIdentity.dbPath)
            }
            HStack(spacing: MykSpace.s4) {
                Button("Diagnose kopieren") { copyDiagnostics() }
                if diagnosticsCopied {
                    Text("In Zwischenablage kopiert")
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.positive.color)
                }
            }
            Divider()
            HStack(spacing: MykSpace.s4) {
                Button("Backup jetzt") { Task { await appState.createBackup(); backups = appState.listBackups() } }
                    .disabled(appState.backupState == .saving)
                backupStatusLabel
                Spacer()
                Button("Im Finder") { openBackupsFolder() }
                    .font(.mykMono(10))
            }
            Text("Automatisch höchstens 1×/Tag beim Start; „Backup jetzt“ erzwingt sofort einen "
                 + "WAL-Checkpoint + geprüften Snapshot (db.sqlite + projects/customers.json). Max. 30 Snapshots.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)

            backupListView
        }
        .settingsCard()
        .onAppear { backups = appState.listBackups() }
        .confirmationDialog(
            "Dieses Backup beim nächsten Start wiederherstellen?",
            isPresented: Binding(get: { restoreConfirm != nil }, set: { if !$0 { restoreConfirm = nil } }),
            titleVisibility: .visible
        ) {
            if let info = restoreConfirm {
                Button("Wiederherstellen", role: .destructive) {
                    appState.stageRestore(info)
                    restoreStagedName = info.folderURL.lastPathComponent
                    restoreConfirm = nil
                }
                Button("Abbrechen", role: .cancel) { restoreConfirm = nil }
            }
        } message: {
            Text("Der aktuelle Stand wird vorher automatisch gesichert (Rettungsbackup). "
                 + "Die Wiederherstellung greift beim nächsten App-Start.")
        }
    }

    // Liste vorhandener Backups mit Wiederherstellen-Aktion (staged auf nächsten Start).
    @ViewBuilder
    private var backupListView: some View {
        if let staged = restoreStagedName {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "clock.arrow.circlepath").foregroundStyle(MykColor.tasks.color)
                Text("Beim nächsten Start wird „\(staged)“ wiederhergestellt — bitte App neu starten.")
                    .font(.mykMono(9.5)).foregroundStyle(MykColor.tasks.color)
            }
            .padding(.top, MykSpace.s2)
        }
        if backups.isEmpty {
            Text("Noch keine Backups vorhanden.")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.faint.color)
                .padding(.top, MykSpace.s2)
        } else {
            VStack(spacing: 0) {
                ForEach(backups.prefix(8)) { info in
                    HStack(spacing: MykSpace.s3) {
                        Text(info.createdAt.formatted(.dateTime.day().month().hour().minute()))
                            .font(.mykMono(10)).foregroundStyle(MykColor.ink.color)
                        Text(info.tag).font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
                        Text(ByteCountFormatter.string(fromByteCount: Int64(info.sizeBytes), countStyle: .file))
                            .font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                        Spacer()
                        Button("Wiederherstellen") { restoreConfirm = info }
                            .font(.mykMono(9.5))
                            .buttonStyle(.plain)
                            .foregroundStyle(MykColor.drive.color)
                    }
                    .padding(.vertical, MykSpace.s2)
                    if info.id != backups.prefix(8).last?.id {
                        Divider().overlay(MykColor.line.color.opacity(0.5))
                    }
                }
            }
            .padding(.top, MykSpace.s2)
        }
    }

    private func openBackupsFolder() {
        let dir = AppDatabase.productionURL.deletingLastPathComponent().appendingPathComponent("backups", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        NSWorkspace.shared.open(dir)
    }

    @ViewBuilder
    private var backupStatusLabel: some View {
        switch appState.backupState {
        case .idle:
            EmptyView()
        case .saving:
            Text("Sichert…").font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
        case .saved:
            Text("Backup erstellt").font(.mykMono(10)).foregroundStyle(MykColor.positive.color)
        case .failed(let msg):
            Text("Fehlgeschlagen: \(msg)").font(.mykMono(10)).foregroundStyle(MykColor.critical.color)
                .lineLimit(1)
        }
    }

    // Redaktierter Diagnose-Export (keine Tokens/Keys/Clockodo-Rohdaten) → Zwischenablage.
    private func copyDiagnostics() {
        let entries = appState.dataFlow.entries
        let lines = entries.prefix(15).map { e in
            "\(e.integrationID) · \(e.action.rawValue) · \(e.timestamp.formatted(.relative(presentation: .named)))"
        }
        let report = DiagnosticsReport.build(
            identity: .init(
                version: AppIdentity.version, build: AppIdentity.build,
                commit: AppIdentity.gitCommit, branch: AppIdentity.gitBranch,
                buildDate: AppIdentity.buildDate, bundlePath: AppIdentity.bundlePath,
                dbPath: AppIdentity.dbPath
            ),
            handshakeCount: entries.count,
            handshakeLines: Array(lines),
            generatedAt: Date().formatted(.dateTime)
        )
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        diagnosticsCopied = true
    }

    private func diagRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: MykSpace.s3) {
            Text(label)
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
                .frame(width: 56, alignment: .trailing)
            Text(value)
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.inkSoft.color)
                .lineLimit(2)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
    }

    // MARK: - Shared Helpers

    private func serviceStatusBadge(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text).font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
        }
    }
}

// MARK: - View-Extension: einheitliche Karten-Formatierung
extension View {
    func settingsCard() -> some View {
        self
            .padding(MykSpace.s6)
            .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color))
            .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1))
    }
}
