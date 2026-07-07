import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - OnboardingWizardView
// First-Run-Wizard als Overlay-Karte über der Shell. Führt einen frischen
// Testuser linear durch Profil → Claude (essenziell) → Google (essenziell,
// read-only) → optionale Integrationen → fertig. Schreibt nur über die
// bestehenden Stores/Auth-Services. Feld-State ist im Container gehoben, damit
// Vor/Zurück nichts verliert. onFinish setzt das Erst-Start-Flag im ContentView.
struct OnboardingWizardView: View {
    @Environment(AppState.self) private var appState
    let onFinish: () -> Void
    var onDismiss: (() -> Void)? = nil   // gesetzt beim manuellen Wiederöffnen

    @State private var step: OnboardingStep = .welcome
    @State private var displayName = ""
    @State private var role = ""
    @State private var claudeKey = ""
    @State private var claudeModel = ClaudeAuthService.defaultModel
    @State private var googleClientID = ""
    @State private var profileError: String?
    @State private var claudeError: String?
    @State private var googleError: String?
    // E4: lokal bestätigbare clockodoUserID (Meldeadresse-Schritt).
    @State private var clockodoUserIDInput = ""
    @State private var meldeadresseError: String?
    // Schlüsselbund-Import (2026-07-07)
    @State private var einladungPasswort = ""
    @State private var einladungDaten: Data?
    @State private var einladungInfo: String?
    @State private var einladungFehler: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(MykColor.line.color)
            ScrollView { stepBody.padding(MykSpace.s8) }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider().overlay(MykColor.line.color)
            footer
        }
        .frame(width: 560, height: 600)
        .background(RoundedRectangle(cornerRadius: MykRadius.lg).fill(MykColor.paper.color))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.lg).stroke(MykColor.line.color, lineWidth: 1))
        .shadow(color: MykColor.ink.color.opacity(0.25), radius: 30, y: 12)
        .task {
            if let p = appState.profile.profile {
                displayName = p.displayName; role = p.role
                clockodoUserIDInput = p.clockodoUserID ?? ""
            }
            googleClientID = (try? appState.googleAuth.storedClientID()) ?? ""
            if let c = try? appState.claudeAuth.storedCredentials() { claudeKey = c.apiKey; claudeModel = c.model }
        }
    }

    // MARK: Header (Titel + Schritt-Punkte [+ Schließen beim Wiederöffnen])
    private var header: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: MykSpace.s3) {
                Text("mykilOS einrichten")
                    .font(.mykHeadline)
                    .foregroundStyle(MykColor.ink.color)
                HStack(spacing: 6) {
                    ForEach(OnboardingStep.allCases, id: \.rawValue) { s in
                        Capsule()
                            .fill(s.rawValue <= step.rawValue ? MykColor.drive.color : MykColor.line.color)
                            .frame(width: s == step ? 22 : 12, height: 4)
                    }
                }
            }
            Spacer()
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.mykCaption)
                        .foregroundStyle(MykColor.muted.color)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MykSpace.s7)
    }

    // MARK: Schritt-Inhalt
    @ViewBuilder
    private var stepBody: some View {
        switch step {
        case .welcome:  welcomeBody
        case .einladung: einladungBody
        case .profile:  profileBody
        case .claude:   claudeBody
        case .google:   googleBody
        case .meldeadresse: meldeadresseBody
        case .optional: optionalBody
        case .done:     doneBody
        }
    }

    private var welcomeBody: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Willkommen.")
                .font(.mykDisplay).foregroundStyle(MykColor.ink.color)
            Text("Ein Schritt, um den Assistenten zum Laufen zu bringen:")
                .font(.mykBody).foregroundStyle(MykColor.inkSoft.color)
            bullet("Claude — das Gehirn. Ohne Claude bleibt der Assistent stumm.")
            bullet("Google Workspace — empfohlen. Mail, Kalender, Drive live lesen (nur lesend).")
            Text("Claude genügt für den Start. Google ergänzt du jederzeit in den Einstellungen.")
                .font(.mykSmall).foregroundStyle(MykColor.muted.color)
        }
    }

    private var einladungBody: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            stepTitle("Hast du eine Einladung?",
                      "Eine .mykinvite-Datei von deinem Admin bringt alle geteilten Team-Zugänge mit. "
                      + "Kein Problem, wenn nicht — überspring einfach.")
            HStack(spacing: MykSpace.s3) {
                Button(einladungDaten == nil ? "Einladung wählen …" : "Andere Datei …") { einladungWaehlen() }
                    .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.drive.color)
                if einladungDaten != nil {
                    Label("Datei geladen", systemImage: "doc.badge.checkmark")
                        .font(.mykMono(9)).foregroundStyle(MykColor.positive.color)
                }
            }
            if einladungDaten != nil {
                secureField("Passwort (vom Admin über getrennten Kanal)", text: $einladungPasswort, placeholder: "Passwort")
                Button("Importieren") { einladungImportieren() }
                    .disabled(einladungPasswort.isEmpty)
            }
            if let einladungInfo { hint("✓ \(einladungInfo)") }
            if let einladungFehler { errorText(einladungFehler) }
            hint("Dein eigener Google-Login kommt erst in den nächsten Schritten — der reist nie in "
                 + "einer Einladung mit. Die Einladung bringt nur die geteilten Team-Keys.")
        }
    }

    private var profileBody: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            stepTitle("Dein Profil", "Damit das Cockpit weiß, wer hier arbeitet.")
            labeledField("Anzeigename", text: $displayName, placeholder: "z. B. Johannes")
            labeledField("Rolle (optional)", text: $role, placeholder: "z. B. Design & Projektleitung")
            SaveStateBar(state: appState.profile.saveState)
            if let profileError { errorText(profileError) }
        }
    }

    private var claudeBody: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            stepTitle("Claude verbinden", "Der Assistent denkt mit Claude. Essenziell.")
            ConnectionStatusView(state: claudeDisplay)
            secureField("Anthropic API-Key", text: $claudeKey, placeholder: "sk-ant-…")
            labeledField("Modell", text: $claudeModel, placeholder: ClaudeAuthService.defaultModel)
            Button("Verbinden") { connectClaude() }
                .disabled(claudeKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if let claudeError { errorText(claudeError) }
            if appState.claudeAuth.status != .connected {
                hint("Ohne Claude bleibt der Assistent stumm. Du kannst es überspringen und später nachholen.")
            }
        }
    }

    private var googleBody: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            stepTitle("Google verbinden", "Empfohlen — Lesezugriff auf Drive, Kalender, Gmail, Kontakte. Kannst du überspringen.")
            ConnectionStatusView(state: googleDisplay)
            labeledField("OAuth-Client-ID (Desktop App)", text: $googleClientID, placeholder: "…apps.googleusercontent.com")
            Button(appState.googleAuth.status == .connecting ? "Verbindet…" : "Verbinden") { connectGoogle() }
                .disabled(appState.googleAuth.status == .connecting
                          || googleClientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if let googleError { errorText(googleError) }
            hint("Es öffnet sich dein Browser zur Google-Anmeldung. mykilOS schreibt nie — alle Zugriffe sind read-only.")
        }
    }

    // E4: Meldeadresse-Bestätigung — der Ausweis zeigt die aus Google erkannte Identität
    // (read-only), die clockodoUserID lässt sich lokal ergänzen. Kein externer Write.
    private var meldeadresseBody: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            stepTitle("Deine Meldeadresse", "Erkannt aus deinem Google-Login. Stimmt das?")
            if let user = appState.currentGoogleUser {
                HStack(spacing: MykSpace.s4) {
                    Circle().fill(MykColor.brand.color).frame(width: 40, height: 40)
                        .overlay(
                            Text(mykNameInitials(user.displayName))
                                .font(.mykBody).foregroundStyle(MykColor.paper.color)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName).font(.mykBody).foregroundStyle(MykColor.ink.color)
                        Text(user.email).font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
                        if let domain = user.domain {
                            Text(domain).font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                        }
                    }
                }
                labeledField("Clockodo User-ID (optional)", text: $clockodoUserIDInput, placeholder: "z. B. 123456")
                if let meldeadresseError { errorText(meldeadresseError) }
                hint("Nur lokal gespeichert — mykilOS schreibt hier nichts nach außen. Dein Ausweis bleibt auf diesem Gerät.")
            } else {
                hint("Noch keine Google-Identität erkannt. Verbinde im vorigen Schritt Google "
                     + "oder überspringe — du kannst es später in den Einstellungen nachtragen.")
            }
        }
    }

    private var optionalBody: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            stepTitle("Optionale Quellen", "Kannst du jetzt überspringen und in den Einstellungen einrichten.")
            optionalRow("ClickUp Aufgaben", state: clickUpDisplay)
            optionalRow("Clockodo Zeiterfassung", state: clockodoDisplay)
            optionalRow("Airtable Projektdaten (read-only)", state: airtableDisplay)
            hint("Diese Quellen richtest du in den Einstellungen ein — der Assistent funktioniert auch ohne sie.")
        }
    }

    private var doneBody: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            if doneReady {
                Text("Startklar. 🚀")
                    .font(.mykDisplay).foregroundStyle(MykColor.ink.color)
                Text("Claude und Google sind verbunden — der Assistent denkt mit und kann Mails, Kalender und Projekte live lesen.")
                    .font(.mykBody).foregroundStyle(MykColor.inkSoft.color)
            } else if appState.claudeAuth.status == .connected {
                Text("Assistent bereit.")
                    .font(.mykDisplay).foregroundStyle(MykColor.ink.color)
                Text("Claude ist verbunden — du kannst sofort loslegen. Google ergänzt Live-Zugriffe auf Mail und Kalender.")
                    .font(.mykBody).foregroundStyle(MykColor.inkSoft.color)
                HStack(spacing: MykSpace.s5) {
                    miniStatus("Claude", claudeDisplay)
                    miniStatus("Google", googleDisplay)
                }
            } else {
                Text("Claude fehlt noch.")
                    .font(.mykDisplay).foregroundStyle(MykColor.ink.color)
                Text("Ohne Claude-Key bleibt der Assistent stumm. Trage ihn in den Einstellungen nach.")
                    .font(.mykBody).foregroundStyle(MykColor.inkSoft.color)
                miniStatus("Claude", claudeDisplay)
            }
        }
    }

    // MARK: Footer (Zurück · Schritt N/M · Primär)
    private var footer: some View {
        HStack(spacing: MykSpace.s4) {
            if step != .welcome {
                Button("Zurück") { goBack() }.buttonStyle(.plain)
                    .foregroundStyle(MykColor.muted.color).font(.mykSmall)
            }
            Spacer()
            Text("Schritt \(step.indicatorIndex) von \(OnboardingStep.indicatorTotal)")
                .font(.mykMono(10)).foregroundStyle(MykColor.faint.color)
            Spacer()
            if step != .welcome && step != .done && step != .profile {
                Button("Überspringen") { advance() }.buttonStyle(.plain)
                    .foregroundStyle(MykColor.muted.color).font(.mykSmall)
            }
            Button(primaryLabel) { primaryAction() }
                .disabled(primaryEnabled == false)
        }
        .padding(MykSpace.s7)
    }

    // MARK: Footer-Logik
    private var primaryLabel: String {
        switch step {
        case .welcome: "Los geht’s"
        case .done:    doneReady ? "Zum Assistenten" : "Trotzdem fertig"
        default:       "Weiter"
        }
    }

    private var primaryEnabled: Bool {
        step == .profile ? displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false : true
    }

    private func primaryAction() {
        switch step {
        case .profile:      saveProfileAndAdvance()
        case .meldeadresse: saveMeldeadresseAndAdvance()
        case .done:         onFinish()
        default:            advance()
        }
    }

    // E4: Nur lokaler Write — die bestätigte clockodoUserID in den Ausweis/das Profil,
    // alle anderen Felder unverändert mitführen (userID/googleDomain nicht verlieren).
    private func saveMeldeadresseAndAdvance() {
        meldeadresseError = nil
        let existing = appState.profile.profile
        let trimmedID = clockodoUserIDInput.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try appState.profile.save(UserProfile(
                displayName: existing?.displayName ?? displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                role: existing?.role ?? role.trimmingCharacters(in: .whitespacesAndNewlines),
                clockodoUserID: trimmedID.isEmpty ? nil : trimmedID,
                googleDomain: existing?.googleDomain ?? appState.currentGoogleUser?.domain,
                userID: existing?.userID
            ))
            advance()
        } catch {
            meldeadresseError = "Speichern fehlgeschlagen: \(error)"
        }
    }

    private func advance() {
        if let next = OnboardingStep(rawValue: step.rawValue + 1) {
            withAnimation(.easeInOut(duration: 0.18)) { step = next }
        }
    }

    private func goBack() {
        if let prev = OnboardingStep(rawValue: step.rawValue - 1) {
            withAnimation(.easeInOut(duration: 0.18)) { step = prev }
        }
    }

    // MARK: Aktionen
    private func saveProfileAndAdvance() {
        profileError = nil
        do {
            // V10 Folge-Block A: userID der bestehenden Zeile mitführen (von
            // AppState.init() → ProfileStore.ensureUserID() bereits erzeugt) —
            // sonst würde dieses Save die stabile Keychain-userID auf nil
            // zurücksetzen, sobald der Onboarding-Wizard zum ersten Mal speichert.
            try appState.profile.save(UserProfile(
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                role: role.trimmingCharacters(in: .whitespacesAndNewlines),
                clockodoUserID: appState.profile.profile?.clockodoUserID,
                googleDomain: appState.profile.profile?.googleDomain,
                userID: appState.profile.profile?.userID
            ))
            advance()
        } catch {
            profileError = "Speichern fehlgeschlagen: \(error)"
        }
    }

    private func connectClaude() {
        claudeError = nil
        do {
            try appState.claudeAuth.connect(apiKey: claudeKey, model: claudeModel)
        } catch {
            claudeError = "Verbindung fehlgeschlagen: \(error)"
        }
    }

    private func connectGoogle() {
        googleError = nil
        let id = googleClientID
        Task {
            do { try await appState.googleAuth.startAuthorization(clientID: id) }
            catch { googleError = "Verbindung fehlgeschlagen: \(error)" }
        }
    }

    // MARK: Schlüsselbund-Import
    private func einladungWaehlen() {
        einladungFehler = nil
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsOtherFileTypes = true
        panel.prompt = "Einladung wählen"
        panel.message = "Eine .mykinvite-Datei wählen"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            einladungDaten = try Data(contentsOf: url)
            einladungInfo = nil
        } catch {
            einladungFehler = "Datei konnte nicht gelesen werden: \(error.localizedDescription)"
        }
    }

    private func einladungImportieren() {
        einladungFehler = nil
        guard let daten = einladungDaten else { return }
        do {
            let payload = try appState.einladungOeffnen(daten: daten, passwort: einladungPasswort)
            // Wizard-Felder mit den importierten Team-Keys nachziehen, damit die folgenden
            // Schritte (Claude/Google) sie verbunden zeigen bzw. vorbefüllt haben.
            googleClientID = (try? appState.googleAuth.storedClientID()) ?? googleClientID
            if let claude = try? appState.claudeAuth.storedCredentials() {
                claudeKey = claude.apiKey; claudeModel = claude.model
            }
            let fuer = payload.eingeladenerName ?? payload.eingeladeneEmail
            einladungInfo = fuer.map { "Übernommen — Einladung für \($0). Team-Zugänge sind vorbereitet." }
                ?? "Team-Zugänge übernommen."
            einladungPasswort = ""
        } catch {
            einladungFehler = error.localizedDescription
        }
    }

    // MARK: Status-Mapper
    // Volle Bereitschaft = Claude UND Google. Claude allein = "Assistent bereit".
    // Wizard nennt Google "empfohlen" (nicht erzwingend) — essentialsConnected in
    // ContentView prüft nur Claude, was dazu konsistent ist.
    private var doneReady: Bool {
        appState.claudeAuth.status == .connected && appState.googleAuth.status == .connected
    }

    private var claudeDisplay: ConnectionDisplayState {
        switch appState.claudeAuth.status {
        case .connected:          .connected
        case .disconnected:       .notConnected
        case .error(let message): .error(message)
        }
    }

    private var googleDisplay: ConnectionDisplayState {
        switch appState.googleAuth.status {
        case .connected:          .connected
        case .connecting:         .connecting
        case .disconnected:       .notConnected
        case .error(let message): .error(message)
        }
    }

    private var clickUpDisplay: ConnectionDisplayState {
        switch appState.clickUpAuth.status {
        case .connected:          .connected
        case .disconnected:       .notConnected
        case .error(let message): .error(message)
        }
    }

    private var clockodoDisplay: ConnectionDisplayState {
        switch appState.clockodoAuth.status {
        case .connected:          .connected
        case .disconnected:       .notConnected
        case .error(let message): .error(message)
        }
    }

    private var airtableDisplay: ConnectionDisplayState {
        switch appState.airtableAuth.status {
        case .connected:          .connected
        case .syncing:            .connecting
        case .disconnected:       .notConnected
        case .error(let message): .error(message)
        }
    }

    // MARK: Bausteine
    private func stepTitle(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text(title).font(.mykHeadline).foregroundStyle(MykColor.ink.color)
            Text(subtitle).font(.mykSmall).foregroundStyle(MykColor.muted.color)
        }
    }

    private func labeledField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text(label).font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder).font(.mykMono(12))
        }
    }

    private func secureField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text(label).font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
            SecureField(placeholder, text: text)
                .textFieldStyle(.roundedBorder).font(.mykMono(12))
        }
    }

    private func optionalRow(_ title: String, state: ConnectionDisplayState) -> some View {
        HStack {
            Text(title).font(.mykBody).foregroundStyle(MykColor.ink.color)
            Spacer()
            ConnectionStatusView(state: state)
        }
        .padding(.vertical, MykSpace.s2)
    }

    private func miniStatus(_ title: String, _ state: ConnectionDisplayState) -> some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text(title).font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
            ConnectionStatusView(state: state)
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: MykSpace.s3) {
            Circle().fill(MykColor.drive.color).frame(width: 5, height: 5).padding(.top, 7)
            Text(text).font(.mykBody).foregroundStyle(MykColor.inkSoft.color)
        }
    }

    private func hint(_ text: String) -> some View {
        Text(text).font(.mykMono(9.5)).foregroundStyle(MykColor.faint.color)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func errorText(_ text: String) -> some View {
        Text(text).font(.mykMono(10)).foregroundStyle(MykColor.critical.color)
            .fixedSize(horizontal: false, vertical: true)
    }
}
