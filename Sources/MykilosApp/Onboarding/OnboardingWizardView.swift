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

    @State private var step: OnboardingStep = .welcome
    @State private var displayName = ""
    @State private var role = ""
    @State private var claudeKey = ""
    @State private var claudeModel = ClaudeAuthService.defaultModel
    @State private var googleClientID = ""
    @State private var profileError: String?
    @State private var claudeError: String?
    @State private var googleError: String?

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
            if let p = appState.profile.profile { displayName = p.displayName; role = p.role }
            googleClientID = (try? appState.googleAuth.storedClientID()) ?? ""
            if let c = try? appState.claudeAuth.storedCredentials() { claudeKey = c.apiKey; claudeModel = c.model }
        }
    }

    // MARK: Header (Titel + Schritt-Punkte)
    private var header: some View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MykSpace.s7)
    }

    // MARK: Schritt-Inhalt
    @ViewBuilder
    private var stepBody: some View {
        switch step {
        case .welcome:  welcomeBody
        case .profile:  profileBody
        case .claude:   claudeBody
        case .google:   googleBody
        case .optional: optionalBody
        case .done:     doneBody
        }
    }

    private var welcomeBody: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Willkommen.")
                .font(.mykDisplay).foregroundStyle(MykColor.ink.color)
            Text("Zwei Dinge bringen dein Cockpit zum Leben:")
                .font(.mykBody).foregroundStyle(MykColor.inkSoft.color)
            bullet("Claude — das Gehirn des Assistenten.")
            bullet("Google Workspace — deine Daten, nur lesend (Drive, Kalender, Gmail, Kontakte).")
            Text("Dauert keine drei Minuten. Du kannst alles später in den Einstellungen ändern.")
                .font(.mykSmall).foregroundStyle(MykColor.muted.color)
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
            stepTitle("Google verbinden", "Nur Lesezugriff — Drive, Kalender, Gmail, Kontakte. Essenziell für Live-Antworten.")
            ConnectionStatusView(state: googleDisplay)
            labeledField("OAuth-Client-ID (Desktop App)", text: $googleClientID, placeholder: "…apps.googleusercontent.com")
            Button(appState.googleAuth.status == .connecting ? "Verbindet…" : "Verbinden") { connectGoogle() }
                .disabled(appState.googleAuth.status == .connecting
                          || googleClientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if let googleError { errorText(googleError) }
            hint("Es öffnet sich dein Browser zur Google-Anmeldung. mykilOS schreibt nie — alle Zugriffe sind read-only.")
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
                Text("Alles bereit. ✨")
                    .font(.mykDisplay).foregroundStyle(MykColor.ink.color)
                Text("Claude und Google sind verbunden — der Assistent kann deine Projekte, Mails und Termine lesen und mitdenken.")
                    .font(.mykBody).foregroundStyle(MykColor.inkSoft.color)
            } else {
                Text("Fast fertig.")
                    .font(.mykDisplay).foregroundStyle(MykColor.ink.color)
                Text("Der Assistent antwortet erst voll, wenn Claude UND Google verbunden sind.")
                    .font(.mykBody).foregroundStyle(MykColor.inkSoft.color)
                HStack(spacing: MykSpace.s5) {
                    miniStatus("Claude", claudeDisplay)
                    miniStatus("Google", googleDisplay)
                }
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
        case .profile: saveProfileAndAdvance()
        case .done:    onFinish()
        default:       advance()
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
            try appState.profile.save(UserProfile(
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                role: role.trimmingCharacters(in: .whitespacesAndNewlines)
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

    // MARK: Status-Mapper
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
