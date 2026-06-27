import SwiftUI
import MykilosDesign

// MARK: - ConnectionDisplayState
// Vereinheitlichter Anzeige-Zustand für Verbindungs-Badges. Die einzelnen
// Service-Status-Enums (Claude 3-stufig, Google mit .connecting, Airtable mit
// .syncing) werden je über einen kleinen Mapper hierauf abgebildet.
enum ConnectionDisplayState: Equatable {
    case connected
    case connecting
    case notConnected
    case error(String)
}

// MARK: - ConnectionStatusView
// Punkt + Label, ausschließlich Design-Tokens. Geteilt vom Onboarding-Wizard
// (SettingsView bleibt bewusst unangetastet — kein Refactor an der fragilen Datei).
struct ConnectionStatusView: View {
    let state: ConnectionDisplayState

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.mykMono(11))
                .foregroundStyle(MykColor.muted.color)
        }
    }

    private var color: Color {
        switch state {
        case .connected:    MykColor.positive.color
        case .connecting:   MykColor.tasks.color
        case .notConnected: MykColor.faint.color
        case .error:        MykColor.critical.color
        }
    }

    private var label: String {
        switch state {
        case .connected:          "VERBUNDEN"
        case .connecting:         "VERBINDET…"
        case .notConnected:       "NICHT VERBUNDEN"
        case .error(let message): "FEHLER · \(message)"
        }
    }
}
