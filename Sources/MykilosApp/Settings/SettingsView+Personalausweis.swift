import SwiftUI
import MykilosDesign

// MARK: - SettingsView + Personalausweis-Header (E2, 2026-07-05)
// Ausgelagert aus SettingsView.swift (swiftlint type_body_length) — reine Verschiebung,
// analog zu SettingsView+MiniMode.swift. Der „Ausweis" oben im Content-Pane:
// Avatar · Name · Mail · Rolle · Hausmeister. Speist aus DERSELBEN Google-Quelle wie
// identitySection (currentGoogleUser) + lokalem Profil — KEIN ResidentIdentity-Merge in
// dieser Etappe. Klick öffnet das Detail (.profil). Trägt nie ein Secret (eiserne Regel).
extension SettingsView {
    var personalausweisHeader: some View {
        Button { withAnimation(.easeInOut(duration: 0.15)) { selectCategory(.profil) } } label: {
            HStack(spacing: MykSpace.s5) {
                Circle()
                    .fill(MykColor.brand.color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(mykNameInitials(ausweisName))
                            .font(.mykHeadline)
                            .foregroundStyle(MykColor.paper.color)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(ausweisName)
                        .font(.mykHeadline)
                        .foregroundStyle(MykColor.ink.color)
                    if let email = appState.currentGoogleUser?.email {
                        Text(email)
                            .font(.mykMono(10))
                            .foregroundStyle(MykColor.muted.color)
                    }
                    HStack(spacing: MykSpace.s3) {
                        if !ausweisRole.isEmpty {
                            Text(ausweisRole)
                                .font(.mykMono(9.5))
                                .foregroundStyle(MykColor.muted.color)
                        }
                        Text("· aktiver Bewohner (dieses Gerät)")
                            .font(.mykMono(9))
                            .foregroundStyle(MykColor.faint.color)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.mykSmall)
                    .foregroundStyle(category == .profil ? MykColor.brand.color : MykColor.faint.color)
            }
            .padding(.horizontal, MykSpace.s9)
            .padding(.vertical, MykSpace.s5)
            .contentShape(Rectangle())
            .background(category == .profil ? MykColor.brand.color.opacity(0.04) : Color.clear)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Personalausweis: \(ausweisName)")
    }

    // Name/Rolle für den Ausweis — Google-Identität zuerst, sonst lokales Profil.
    private var ausweisName: String {
        if let user = appState.currentGoogleUser, !user.displayName.isEmpty { return user.displayName }
        let manual = appState.profile.profile?.displayName ?? ""
        return manual.isEmpty ? "Profil einrichten" : manual
    }
    private var ausweisRole: String { appState.profile.profile?.role ?? "" }
}
