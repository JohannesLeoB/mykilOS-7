import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - BrandsView
// Sidebar-Modul "Marken & Daten": Integrations-Dashboard aller Datenquellen.
struct BrandsView: View {
    var onNavigateToSettings: () -> Void = {}
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MykSpace.s7) {
                Text("Integrationen")
                    .font(.mykDisplay)
                    .foregroundStyle(MykColor.ink.color)
                Text("Datenquellen und Verbindungen dieses Studios.")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: MykSpace.s5),
                        GridItem(.flexible(), spacing: MykSpace.s5),
                        GridItem(.flexible()),
                    ],
                    spacing: MykSpace.s5
                ) {
                    IntegrationCard(
                        name: "Google",
                        detail: "Drive · Kalender · Kontakte · Mail",
                        icon: "person.crop.circle",
                        color: MykColor.drive.color,
                        state: googleState
                    ) { onNavigateToSettings() }
                    IntegrationCard(
                        name: "Claude",
                        detail: "Assistent · Chat · Analyse",
                        icon: "sparkles",
                        color: MykColor.personal.color,
                        state: claudeState
                    ) { onNavigateToSettings() }
                    IntegrationCard(
                        name: "Airtable",
                        detail: "Projektsync · System-of-Record",
                        icon: "table",
                        color: MykColor.tasks.color,
                        state: airtableState
                    ) { onNavigateToSettings() }
                    IntegrationCard(
                        name: "ClickUp",
                        detail: "Aufgaben · Tasks-Widget",
                        icon: "checklist",
                        color: MykColor.tasks.color,
                        state: clickUpState
                    ) { onNavigateToSettings() }
                    IntegrationCard(
                        name: "Clockodo",
                        detail: "Zeiterfassung",
                        icon: "clock",
                        color: MykColor.people.color,
                        state: clockodoState
                    ) { onNavigateToSettings() }
                    IntegrationCard(
                        name: "Sevdesk",
                        detail: "Rechnungen · Cash-Widget",
                        icon: "eurosign",
                        color: MykColor.cash.color,
                        state: sevdeskState
                    ) { onNavigateToSettings() }
                }

                Divider().overlay(MykColor.line.color)

                SchaltzentrumView()

                Divider().overlay(MykColor.line.color)

                Button {
                    onNavigateToSettings()
                } label: {
                    HStack(spacing: MykSpace.s3) {
                        Image(systemName: "gearshape")
                            .font(.mykMono(10))
                            .foregroundStyle(MykColor.muted.color)
                        Text("Verbindungen in den Einstellungen verwalten")
                            .font(.mykMono(10))
                            .foregroundStyle(MykColor.muted.color)
                        Image(systemName: "chevron.right")
                            .font(.mykMono(9.5))
                            .foregroundStyle(MykColor.faint.color)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(MykSpace.s9)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(MykColor.paper.color)
    }

    // MARK: Status-Mapping

    private var googleState: ConnectionDisplayState {
        switch appState.googleAuth.status {
        case .connected:       .connected
        case .connecting:      .connecting
        case .disconnected:    .notConnected
        case .error(let msg):  .error(msg)
        }
    }

    private var claudeState: ConnectionDisplayState {
        switch appState.claudeAuth.status {
        case .connected:       .connected
        case .disconnected:    .notConnected
        case .error(let msg):  .error(msg)
        }
    }

    private var airtableState: ConnectionDisplayState {
        switch appState.airtableAuth.status {
        case .connected:       .connected
        case .syncing:         .connecting
        case .disconnected:    .notConnected
        case .error(let msg):  .error(msg)
        }
    }

    private var clickUpState: ConnectionDisplayState {
        switch appState.clickUpAuth.status {
        case .connected:       .connected
        case .disconnected:    .notConnected
        case .error(let msg):  .error(msg)
        }
    }

    private var clockodoState: ConnectionDisplayState {
        switch appState.clockodoAuth.status {
        case .connected:       .connected
        case .disconnected:    .notConnected
        case .error(let msg):  .error(msg)
        }
    }

    private var sevdeskState: ConnectionDisplayState {
        switch appState.sevdeskAuth.status {
        case .connected:       .connected
        case .disconnected:    .notConnected
        case .error(let msg):  .error(msg)
        }
    }
}

// MARK: - IntegrationCard

private struct IntegrationCard: View {
    let name: String
    let detail: String
    let icon: String
    let color: Color
    let state: ConnectionDisplayState
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: MykSpace.s4) {
                HStack(spacing: MykSpace.s3) {
                    Image(systemName: icon)
                        .font(.mykCaption)
                        .foregroundStyle(color)
                        .frame(width: 20)
                    Text(name)
                        .font(.mykHeadline)
                        .foregroundStyle(MykColor.ink.color)
                }
                Text(detail)
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.muted.color)
                    .lineLimit(1)
                ConnectionStatusView(state: state)
            }
            .padding(MykSpace.s5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: MykRadius.md)
                    .fill(MykColor.card.color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MykRadius.md)
                    .stroke(isHovered ? color.opacity(0.4) : MykColor.line.color, lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
