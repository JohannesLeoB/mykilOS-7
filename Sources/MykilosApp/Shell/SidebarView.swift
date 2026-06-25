import SwiftUI
import MykilosDesign

// MARK: - SidebarView
// Der schmale Rail links. Einzige Navigation, volle Design-Kontrolle.
// Kein macOS-Standardsidebar — Custom-Layout, weil die CI es verlangt.
struct SidebarView: View {
    @Binding var selection: AppModule

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
            Spacer().frame(height: MykSpace.s8)
            navItems
            Spacer()
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
                .fill(
                    LinearGradient(
                        colors: [MykColor.drive.color, MykColor.tasks.color],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 26, height: 26)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("mykilOS")
                    .font(.mykHeadline)
                    .foregroundStyle(MykColor.ink.color)
                Text("6")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.faint.color)
            }
        }
        .padding(.leading, MykSpace.s4)
    }

    // MARK: Navigations-Items
    private var navItems: some View {
        VStack(spacing: 2) {
            ForEach(AppModule.allCases) { module in
                NavItem(module: module, isSelected: selection == module) {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = module }
                }
            }
        }
    }

    // MARK: Fußzeile
    private var navFoot: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(MykColor.positive.color)
                .frame(width: 5, height: 5)
            Text("LOKAL · GESPEICHERT")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)
        }
        .padding(.leading, MykSpace.s4)
        .padding(.bottom, MykSpace.s3)
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
