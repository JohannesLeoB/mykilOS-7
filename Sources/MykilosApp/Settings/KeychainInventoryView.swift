import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - KeychainInventoryView (read-only)
// Zeigt für jede der 6 Integrationen an: Quellfarbe + Name · Statuspunkt ·
// persönlich/geteilt-Badge · bei Verwaist ein DEZENTER Hinweis (kein Alarm,
// siehe eiserne Alerts-Regel).
//
// ⛔ EISERNE REGEL: NIE ein Secret-Wert. Diese View liest ausschließlich
// Status (aus den AuthServices) und Keychain-Metadaten (Service-Namen über
// KeychainMetadataLister, das mit kSecReturnData:false arbeitet). Kein Wert,
// kein Token, kein Key wird jemals geladen oder angezeigt.
struct KeychainInventoryView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            header
            if items.isEmpty {
                emptyState
            } else {
                VStack(spacing: MykSpace.s4) {
                    ForEach(items, id: \.integration.rawValue) { item in
                        row(item)
                    }
                }
            }
            quellzeile
        }
        .settingsCard()
    }

    // MARK: - Kopf

    private var header: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text("Schlüssel-Inventar")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            Text("Welche Zugänge liegen im Schlüsselbund — und gehören sie zur aktiven Identität?")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var emptyState: some View {
        HStack(spacing: MykSpace.s3) {
            Circle().fill(MykColor.faint.color).frame(width: 7, height: 7)
            Text("Keine mykilOS-Zugänge im Schlüsselbund gefunden.")
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
        }
    }

    // MARK: - Zeile

    private func row(_ item: KeyInventoryItem) -> some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            HStack(spacing: MykSpace.s4) {
                // Quellfarbe + Name
                Circle()
                    .fill(sourceColor(item.integration))
                    .frame(width: 10, height: 10)
                Text(item.integration.displayName)
                    .font(.mykBody)
                    .foregroundStyle(MykColor.ink.color)

                scopeBadge(item.scope)

                Spacer()

                // Statuspunkt + Label (geteiltes Muster)
                ConnectionStatusView(state: item.connected ? .connected : .notConnected)
            }
            // Verwaist: dezenter Hinweis, kein Alarm.
            if item.isOrphaned, let hint = item.orphanHint {
                HStack(spacing: MykSpace.s2) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.tasks.color)
                    Text(hint)
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.tasks.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 22)
            }
        }
        .padding(.vertical, MykSpace.s2)
    }

    private func scopeBadge(_ scope: KeyScope) -> some View {
        Text(scope.label.uppercased())
            .font(.mykMono(8.5))
            .tracking(0.8)
            .foregroundStyle(scopeColor(scope))
            .padding(.horizontal, MykSpace.s3)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(scopeColor(scope).opacity(0.12))
            )
    }

    // MARK: - Quellzeile

    private var quellzeile: some View {
        Text("KEYCHAIN · NUR STATUS + METADATEN · KEINE SCHLÜSSEL-WERTE")
            .font(.mykMono(9))
            .foregroundStyle(MykColor.faint.color)
    }

    // MARK: - Daten

    private var items: [KeyInventoryItem] {
        KeychainInventory.build(
            activeUserID: CurrentUserContext.current ?? "",
            storedServiceNames: KeychainMetadataLister().storedServiceNames(),
            connected: connectedMap
        )
    }

    /// Echter Verbindungsstatus je Integration (aus den AuthServices → Bool).
    private var connectedMap: [KeyIntegration: Bool] {
        [
            .google:   isGoogleConnected,
            .clockodo: isClockodoConnected,
            .clickup:  isClickUpConnected,
            .sevdesk:  isSevdeskConnected,
            .airtable: isAirtableConnected,
            .claude:   isClaudeConnected,
        ]
    }

    private var isGoogleConnected: Bool {
        if case .connected = appState.googleAuth.status { return true }
        return false
    }
    private var isClockodoConnected: Bool {
        if case .connected = appState.clockodoAuth.status { return true }
        return false
    }
    private var isClickUpConnected: Bool {
        if case .connected = appState.clickUpAuth.status { return true }
        return false
    }
    private var isSevdeskConnected: Bool {
        if case .connected = appState.sevdeskAuth.status { return true }
        return false
    }
    private var isAirtableConnected: Bool {
        // .connected und .syncing zählen beide als „Schlüssel liegt vor & aktiv".
        switch appState.airtableAuth.status {
        case .connected, .syncing: return true
        default:                   return false
        }
    }
    private var isClaudeConnected: Bool {
        if case .connected = appState.claudeAuth.status { return true }
        return false
    }

    // MARK: - Farb-Zuordnung (nur Design-Tokens)

    private func sourceColor(_ integration: KeyIntegration) -> Color {
        switch integration {
        case .google:   MykColor.people.color   // Salbei — Menschen/Kalender/Mail
        case .clockodo: MykColor.brand.color     // Private Area · MYKILOS Orange
        case .clickup:  MykColor.tasks.color      // Ocker — Aufgaben
        case .sevdesk:  MykColor.cash.color       // Tiefblau — Geld
        case .airtable: MykColor.drive.color      // Terrakotta — Daten
        case .claude:   MykColor.personal.color   // Pflaume — Assistent
        }
    }

    private func scopeColor(_ scope: KeyScope) -> Color {
        switch scope {
        case .persoenlich: MykColor.brand.color
        case .geteilt:     MykColor.muted.color
        }
    }
}
