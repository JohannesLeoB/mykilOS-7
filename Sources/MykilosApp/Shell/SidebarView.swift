import SwiftUI
import MykilosDesign

// MARK: - SidebarView
// Der schmale Rail links. Zwei Zustände: BREIT (Logo + Text-Menüpunkte + App-Dock mit
// Namen) und KOMPAKT (nur Icons). Nie ganz ausgeblendet. Der orange Brand-Button oben
// togglet zwischen den Zuständen. Footer: immer ein Avatar-Kreis (Initialen) + Zahnrad.
struct SidebarView: View {
    @Binding var selection: AppModule
    @Binding var isCompact: Bool
    var onOpenProfile: () -> Void = {}
    @Environment(AppState.self) private var appState
    @State private var profileHovered = false
    @State private var brandHovered = false
    @State private var appShortcuts = AppShortcutStore()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
            Spacer().frame(height: MykSpace.s8)
            navItems
            Spacer()
            AppDockStrip(store: appShortcuts, compact: isCompact)
            navFoot
        }
        .padding(.horizontal, MykSpace.s4)
        .padding(.vertical, MykSpace.s7)
        .frame(width: isCompact ? 64 : 212)
        .background(MykColor.paper.color)
    }

    // MARK: Brand — toggelt kompakt/breit
    private var brand: some View {
        Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) { isCompact.toggle() }
        } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(MykColor.brand.color)
                    .frame(width: 26, height: 26)
                    .scaleEffect(brandHovered ? 1.08 : 1.0)
                if !isCompact {
                    Text("mykilOS").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
                    Spacer()
                }
            }
            .padding(.leading, isCompact ? 0 : MykSpace.s4)
            .frame(maxWidth: .infinity, alignment: isCompact ? .center : .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { brandHovered = $0 }
        .help(isCompact ? "Sidebar ausklappen" : "Sidebar einklappen")
    }

    // MARK: Navigations-Items (ohne Settings — kommt als Icon in den Footer)
    private var navItems: some View {
        VStack(spacing: 2) {
            ForEach(AppModule.allCases.filter { $0 != .settings }) { module in
                NavItem(module: module, isSelected: selection == module, compact: isCompact) {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = module }
                }
            }
        }
    }

    // MARK: Fußzeile — immer Avatar (Initialen) + Einstellungs-Icon
    private var navFoot: some View {
        Group {
            if isCompact {
                VStack(spacing: MykSpace.s3) { profileButton; settingsButton }
                    .frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 0) { profileButton; Spacer(); settingsButton }
                    .padding(.horizontal, MykSpace.s4)
            }
        }
        .padding(.bottom, MykSpace.s3)
    }

    private var profileButton: some View {
        Button(action: onOpenProfile) {
            AvatarCircle(initials: initials, online: footIsOnline)
                .scaleEffect(profileHovered ? 1.06 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hover in withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { profileHovered = hover } }
        .help(footDisplayName)
    }

    private var settingsButton: some View {
        SidebarIconButton(systemName: "gearshape", help: "Einstellungen") {
            withAnimation(.easeInOut(duration: 0.18)) { selection = .settings }
        }
    }

    private var footIsOnline: Bool {
        appState.googleAuth.status == .connected || appState.profile.profile?.isComplete == true
    }

    private var footDisplayName: String {
        if let google = appState.currentGoogleUser, !google.displayName.isEmpty {
            return google.displayName
        }
        let manual = appState.profile.profile?.displayName ?? ""
        return manual.isEmpty ? "Profil einrichten" : manual
    }

    private var initials: String {
        let parts = footDisplayName.split(separator: " ").prefix(2)
        let joined = parts.compactMap(\.first).map(String.init).joined().uppercased()
        return joined.isEmpty ? "?" : joined
    }
}

// MARK: - AvatarCircle
private struct AvatarCircle: View {
    let initials: String
    let online: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(MykColor.brand.color)
                .frame(width: 28, height: 28)
                .overlay(Text(initials).font(.mykMono(10)).foregroundStyle(MykColor.paper.color))
            if online {
                Circle()
                    .fill(MykColor.positive.color)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(MykColor.paper.color, lineWidth: 1.5))
            }
        }
    }
}

// MARK: - SidebarIconButton
private struct SidebarIconButton: View {
    let systemName: String
    let help: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.mykBody)
                .foregroundStyle(isHovered ? MykColor.brand.color.opacity(0.7) : MykColor.brand.color)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 9).fill(isHovered ? MykColor.paper2.color : Color.clear))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(help)
    }
}

// MARK: - NavItem
private struct NavItem: View {
    let module: AppModule
    let isSelected: Bool
    let compact: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            content
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(isSelected ? MykColor.ink.color : (isHovered ? MykColor.paper2.color : Color.clear))
                )
                .foregroundStyle(isSelected ? MykColor.paper.color : MykColor.inkSoft.color)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(compact ? module.rawValue : "")
    }

    @ViewBuilder private var content: some View {
        if compact {
            Image(systemName: module.icon)
                .font(.mykBody)
                .frame(width: 44, height: 38)
        } else {
            HStack(spacing: 12) {
                Circle()
                    .fill(isSelected ? MykColor.drive.color : MykColor.faint.color)
                    .frame(width: 6, height: 6)
                Text(module.rawValue).font(.mykBody)
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, MykSpace.s4)
        }
    }
}
