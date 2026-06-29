import SwiftUI
import MykilosDesign

// MARK: - SidebarView
// Der schmale Rail links. Einzige Navigation, volle Design-Kontrolle.
// Kein macOS-Standardsidebar — Custom-Layout, weil die CI es verlangt.
struct SidebarView: View {
    @Binding var selection: AppModule
    var onOpenProfile: () -> Void = {}
    var onToggleSidebar: () -> Void = {}
    @Environment(AppState.self) private var appState
    @State private var profileHovered = false
    @State private var appShortcuts = AppShortcutStore()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
            Spacer().frame(height: MykSpace.s8)
            navItems
            Spacer()
            AppDockStrip(store: appShortcuts)
            navFoot
        }
        .padding(.horizontal, MykSpace.s4)
        .padding(.vertical, MykSpace.s7)
        .frame(width: 212)
        .background(MykColor.paper.color)
    }

    // MARK: Brand
    private var brand: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(MykColor.brand.color)
                .frame(width: 26, height: 26)
            Text("mykilOS")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
        }
        .padding(.leading, MykSpace.s4)
    }

    // MARK: Navigations-Items (ohne Settings — kommt als Icon in den Footer)
    private var navItems: some View {
        VStack(spacing: 2) {
            ForEach(AppModule.allCases.filter { $0 != .settings }) { module in
                NavItem(module: module, isSelected: selection == module) {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = module }
                }
            }
        }
    }

    // MARK: Fußzeile — eine saubere Zeile: Profil links, Icons rechts
    private var navFoot: some View {
        HStack(spacing: 0) {
            // Profil-Button (Name + Status-Dot)
            Button(action: onOpenProfile) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(footIndicatorColor)
                        .frame(width: 5, height: 5)
                    Text(footDisplayName)
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.inkSoft.color)
                        .lineLimit(1)
                }
                .padding(.vertical, 8)
                .padding(.leading, MykSpace.s4)
                .padding(.trailing, 4)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(profileHovered ? MykColor.paper2.color : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .onHover { profileHovered = $0 }

            Spacer()

            // Einstellungen
            SidebarIconButton(systemName: "gearshape", help: "Einstellungen") {
                withAnimation(.easeInOut(duration: 0.18)) { selection = .settings }
            }
            // Sidebar-Toggle
            SidebarIconButton(
                systemName: "sidebar.left",
                help: "Sidebar ausblenden (⌘⇧S)",
                action: onToggleSidebar
            )
        }
        .padding(.horizontal, MykSpace.s4)
        .padding(.bottom, MykSpace.s3)
    }

    private var footIndicatorColor: Color {
        if appState.googleAuth.status == .connected { return MykColor.positive.color }
        return appState.profile.profile?.isComplete == true ? MykColor.positive.color : MykColor.faint.color
    }

    private var footDisplayName: String {
        if let google = appState.currentGoogleUser, !google.displayName.isEmpty {
            return google.displayName
        }
        let manual = appState.profile.profile?.displayName ?? ""
        return manual.isEmpty ? "Profil einrichten" : manual
    }

    private var footSubtitle: String {
        if let google = appState.currentGoogleUser {
            return google.email
        }
        return "Profil & Verbindungen"
    }
}

// MARK: - SidebarIconButton
// Kompakter Icon-Button in MYKILOS Orange für den Sidebar-Footer.
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
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(isHovered ? MykColor.paper2.color : Color.clear)
                )
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
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(isSelected ? MykColor.drive.color : MykColor.faint.color)
                    .frame(width: 6, height: 6)
                Text(module.rawValue)
                    .font(.mykBody)
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, MykSpace.s4)
            .background(
                RoundedRectangle(cornerRadius: 11)
                    .fill(
                        isSelected
                            ? MykColor.ink.color
                            : (isHovered ? MykColor.paper2.color : Color.clear)
                    )
            )
            .foregroundStyle(isSelected ? MykColor.paper.color : MykColor.inkSoft.color)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
