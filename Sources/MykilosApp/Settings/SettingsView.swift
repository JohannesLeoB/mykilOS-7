import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - SettingsView
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var clientID: String = ""
    @State private var errorMessage: String?
    @State private var clockodoEmail: String = ""
    @State private var clockodoApiKey: String = ""
    @State private var clockodoError: String?
    @State private var airtablePAT: String = ""
    @State private var airtableBaseID: String = ""
    @State private var airtableError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MykSpace.s7) {
                Text("Einstellungen")
                    .font(.mykDisplay)
                    .foregroundStyle(MykColor.ink.color)
                googleSection
                clockodoSection
                airtableSection
                Spacer()
            }
            .padding(MykSpace.s9)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(MykColor.paper.color)
        .task {
            clientID = (try? appState.googleAuth.storedClientID()) ?? ""
            if let creds = try? appState.clockodoAuth.storedCredentials() {
                clockodoEmail = creds.email
                clockodoApiKey = creds.apiKey
            }
            if let creds = try? appState.airtableAuth.storedCredentials() {
                airtablePAT = creds.pat
                airtableBaseID = creds.baseID
            }
        }
    }

    private var googleSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Google Workspace")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            statusBadge
            TextField("OAuth-Client-ID (Desktop App)", text: $clientID)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            HStack(spacing: MykSpace.s4) {
                Button(connectLabel) { connect() }
                    .disabled(appState.googleAuth.status == .connecting)
                if appState.googleAuth.status == .connected {
                    Button("Trennen", role: .destructive) { disconnect() }
                }
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.critical.color)
            }
            Text("Nur Lesezugriff (Drive-Metadaten, Kalender, Gmail, Kontakte) — keine Schreibrechte.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)
        }
        .padding(MykSpace.s6)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1)
        )
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle().fill(statusColor).frame(width: 7, height: 7)
            Text(statusText).font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
        }
    }

    private var statusColor: Color {
        switch appState.googleAuth.status {
        case .connected:    MykColor.positive.color
        case .connecting:   MykColor.tasks.color
        case .disconnected: MykColor.faint.color
        case .error:        MykColor.critical.color
        }
    }

    private var statusText: String {
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
        let clientID = self.clientID
        Task {
            do {
                try await appState.googleAuth.startAuthorization(clientID: clientID)
            } catch {
                errorMessage = "Verbindung fehlgeschlagen: \(error)"
            }
        }
    }

    private func disconnect() {
        do {
            try appState.googleAuth.disconnect()
        } catch {
            errorMessage = "Trennen fehlgeschlagen: \(error)"
        }
    }

    // MARK: - Clockodo

    private var clockodoSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Clockodo Zeiterfassung")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            clockodoStatusBadge
            TextField("E-Mail (Clockodo-Account)", text: $clockodoEmail)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            SecureField("API-Key", text: $clockodoApiKey)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            HStack(spacing: MykSpace.s4) {
                Button(clockodoConnectLabel) { connectClockodo() }
                if appState.clockodoAuth.status == .connected {
                    Button("Trennen", role: .destructive) { disconnectClockodo() }
                }
            }
            if let clockodoError {
                Text(clockodoError)
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.critical.color)
            }
            Text("API-Key findest du unter clockodo.com → Einstellungen → API. Nur Lesezugriff, keine Buchung.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)
        }
        .padding(MykSpace.s6)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1)
        )
    }

    private var clockodoStatusBadge: some View {
        HStack(spacing: 6) {
            Circle().fill(clockodoStatusColor).frame(width: 7, height: 7)
            Text(clockodoStatusText).font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
        }
    }

    private var clockodoStatusColor: Color {
        switch appState.clockodoAuth.status {
        case .connected:    MykColor.positive.color
        case .disconnected: MykColor.faint.color
        case .error:        MykColor.critical.color
        }
    }

    private var clockodoStatusText: String {
        switch appState.clockodoAuth.status {
        case .connected:          "VERBUNDEN"
        case .disconnected:       "NICHT VERBUNDEN"
        case .error(let message): "FEHLER · \(message)"
        }
    }

    private var clockodoConnectLabel: String {
        appState.clockodoAuth.status == .connected ? "Erneut verbinden" : "Verbinden"
    }

    private func connectClockodo() {
        clockodoError = nil
        do {
            try appState.clockodoAuth.connect(email: clockodoEmail, apiKey: clockodoApiKey)
        } catch {
            clockodoError = "Verbindung fehlgeschlagen: \(error)"
        }
    }

    private func disconnectClockodo() {
        do {
            try appState.clockodoAuth.disconnect()
            clockodoEmail = ""
            clockodoApiKey = ""
        } catch {
            clockodoError = "Trennen fehlgeschlagen: \(error)"
        }
    }

    // MARK: - Airtable

    private var airtableSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Airtable Projektdaten")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            airtableStatusBadge
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
                Text(airtableError)
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.critical.color)
            }
            Text("PAT unter airtable.com/create/tokens erstellen. Benötigt data.records:read auf die Base.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)
        }
        .padding(MykSpace.s6)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1)
        )
    }

    private var airtableStatusBadge: some View {
        HStack(spacing: 6) {
            Circle().fill(airtableStatusColor).frame(width: 7, height: 7)
            Text(airtableStatusText).font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
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
        do {
            try appState.airtableAuth.connect(pat: airtablePAT, baseID: airtableBaseID)
        } catch {
            airtableError = "Verbindung fehlgeschlagen: \(error)"
        }
    }

    private func syncAirtable() {
        airtableError = nil
        Task {
            await appState.registry.syncFromAirtable(
                baseID: airtableBaseID,
                auth: appState.airtableAuth
            )
        }
    }

    private func disconnectAirtable() {
        do {
            try appState.airtableAuth.disconnect()
            airtablePAT = ""
            airtableBaseID = ""
        } catch {
            airtableError = "Trennen fehlgeschlagen: \(error)"
        }
    }
}
