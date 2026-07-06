import SwiftUI

// MARK: - SettingsView + Datenschutz-Freigaben
// Ausgelagert (swiftlint file_length), gleiches Muster wie SettingsView+MiniMode.swift.
extension SettingsView {
    var datenschutzFreigabenSection: some View {
        DatenschutzFreigabenSectionView(
            store: appState.datenschutzPraeferenzen,
            profile: appState.profile,
            notes: appState.assistantNotes,
            tasks: appState.assistantTasks,
            chat: appState.chat,
            projektNummern: appState.registry.projects.map(\.projectNumber)
        )
    }
}
