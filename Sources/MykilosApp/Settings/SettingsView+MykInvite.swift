import SwiftUI

// MARK: - SettingsView + Kollegen einladen (Admin, System-Tab)
// Ausgelagert (swiftlint file_length), gleiches Muster wie SettingsView+MiniMode.swift.
extension SettingsView {
    var mykInviteSection: some View {
        MykInviteSectionView()
    }
}
