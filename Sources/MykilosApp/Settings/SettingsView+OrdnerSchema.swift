import SwiftUI

// MARK: - SettingsView + Ordner-Schema (Admin, System-Tab)
// Ausgelagert aus SettingsView.swift (swiftlint file_length), gleiches Muster wie
// SettingsView+MiniMode.swift. Die eigentliche Editor-Logik lebt in OrdnerSchemaEditorView.
extension SettingsView {
    var ordnerSchemaSection: some View {
        OrdnerSchemaEditorView(store: appState.nomenklatur)
    }
}
