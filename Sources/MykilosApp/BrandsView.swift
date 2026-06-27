import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - BrandsView
// Sidebar-Modul "Marken & Daten": Integrations-Dashboard aller Datenquellen.
struct BrandsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MykSpace.s7) {
                Text("Marken & Daten")
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
                    )
                    IntegrationCard(
                        name: "Claude",
                        detail: "Assistent · Chat · Analyse",
                        icon: "sparkles",
                        color: MykColor.personal.color,
                        state: claudeState
                    )
                    IntegrationCard(
                        name: "Airtable",
                        detail: "Projektsync · System-of-Record",
                        icon: "table",
                        color: MykColor.tasks.color,
                        state: airtableState
                    )
                    IntegrationCard(
                        name: "ClickUp",
                        detail: "Aufgaben · Tasks-Widget",
                        icon: "checklist",
                        color: MykColor.tasks.color,
                        state: clickUpState
                    )
                    IntegrationCard(
                        name: "Clockodo",
                        detail: "Zeiterfassung",
                        icon: "clock",
                        color: MykColor.people.color,
                        state: clockodoState
                    )
                    IntegrationCard(
                        name: "Sevdesk",
                        detail: "Rechnungen · Cash-Widget",
                        icon: "eurosign",
                        color: MykColor.cash.color,
                        state: sevdeskState
                    )
                }

                Divider().overlay(MykColor.line.color)

                Text("Verbindungen werden in den Einstellungen verwaltet.")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.faint.color)
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

    var body: some View {
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
            RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1)
        )
    }
}
