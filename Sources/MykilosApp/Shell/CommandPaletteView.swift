import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - CommandPaletteView (S5)
// ⌘K-Overlay: ein Suchfeld + Fuzzy-Ergebnisse über App-Bereiche UND Projekte
// (Nummer/Titel/Kunde). Enter oder Klick springt hin. Esc/Backdrop schließt.
// Rein lokal, read-only auf die Registry — keine externen Daten.
struct CommandPaletteView: View {
    @Binding var isPresented: Bool
    let projects: [Project]
    let customerFor: (Project) -> Customer?
    let onSelectModule: (AppModule) -> Void
    let onSelectProject: (Project) -> Void

    @State private var query = ""
    @FocusState private var fieldFocused: Bool

    enum PaletteItem: Identifiable {
        case module(AppModule)
        case project(Project)
        var id: String {
            switch self {
            case .module(let m):  "mod:\(m.rawValue)"
            case .project(let p): "proj:\(p.projectNumber)"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Backdrop
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture { close() }

            card
                .padding(.top, 96)
        }
        .onExitCommand { close() }          // Esc
        .transition(.opacity)
        .onAppear { fieldFocused = true }
    }

    private var card: some View {
        VStack(spacing: 0) {
            // Suchfeld
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "magnifyingglass")
                    .font(.mykBody).foregroundStyle(MykColor.muted.color)
                TextField("Springe zu Bereich, Projekt, Kunde …", text: $query)
                    .textFieldStyle(.plain)
                    .font(.mykHeadline)
                    .focused($fieldFocused)
                    .onSubmit { if let first = results.first { activate(first) } }
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(MykColor.faint.color)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, MykSpace.s6)
            .padding(.vertical, MykSpace.s5)

            Divider().overlay(MykColor.line.color)

            // Ergebnisse
            if results.isEmpty {
                Text("Keine Treffer für „\(query)“")
                    .font(.mykSmall).foregroundStyle(MykColor.muted.color)
                    .frame(maxWidth: .infinity).padding(MykSpace.s8)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(results) { item in
                            PaletteRow(item: item, customerFor: customerFor) { activate(item) }
                        }
                    }
                    .padding(MykSpace.s3)
                }
                .frame(maxHeight: 360)
            }

            Divider().overlay(MykColor.line.color)
            HStack(spacing: MykSpace.s4) {
                Text("↩ öffnen").font(.mykMono(9.5)).foregroundStyle(MykColor.faint.color)
                Text("esc schließen").font(.mykMono(9.5)).foregroundStyle(MykColor.faint.color)
                Spacer()
                Text("⌘K").font(.mykMono(9.5)).foregroundStyle(MykColor.faint.color)
            }
            .padding(.horizontal, MykSpace.s6).padding(.vertical, MykSpace.s3)
        }
        .frame(width: 580)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.lg)
                .fill(MykColor.card.color)
                .overlay(RoundedRectangle(cornerRadius: MykRadius.lg).stroke(MykColor.line.color, lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.18), radius: 30, x: 0, y: 12)
    }

    // MARK: - Ergebnisberechnung

    private var results: [PaletteItem] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        let modules = AppModule.allCases
            .filter { q.isEmpty || $0.rawValue.lowercased().contains(q) }
            .map { PaletteItem.module($0) }
        let matchedProjects = projects
            .filter { matches($0, q) }
            .sorted { rank($0, q) < rank($1, q) }
            .prefix(q.isEmpty ? 6 : 25)
            .map { PaletteItem.project($0) }
        return modules + Array(matchedProjects)
    }

    private func matches(_ p: Project, _ q: String) -> Bool {
        guard !q.isEmpty else { return true }
        if p.projectNumber.lowercased().contains(q) { return true }
        if p.title.lowercased().contains(q) { return true }
        if let c = customerFor(p)?.name.lowercased(), c.contains(q) { return true }
        return false
    }

    // Prefix-Treffer (Nummer/Titel) ranken vor bloßen Enthält-Treffern.
    private func rank(_ p: Project, _ q: String) -> Int {
        guard !q.isEmpty else { return 0 }
        if p.projectNumber.lowercased().hasPrefix(q) { return 0 }
        if p.title.lowercased().hasPrefix(q) { return 1 }
        return 2
    }

    private func activate(_ item: PaletteItem) {
        close()
        switch item {
        case .module(let m):  onSelectModule(m)
        case .project(let p): onSelectProject(p)
        }
    }

    private func close() {
        withAnimation(.easeInOut(duration: 0.15)) { isPresented = false }
    }
}

// MARK: - PaletteRow
private struct PaletteRow: View {
    let item: CommandPaletteView.PaletteItem
    let customerFor: (Project) -> Customer?
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: MykSpace.s4) {
                Image(systemName: icon)
                    .font(.mykBody).foregroundStyle(accent).frame(width: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text(primary).font(.mykBody).foregroundStyle(MykColor.ink.color).lineLimit(1)
                    if let secondary { Text(secondary).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color).lineLimit(1) }
                }
                Spacer()
                Text(kindLabel).font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
            }
            .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s3)
            .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(hovered ? MykColor.paper2.color : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }

    private var icon: String {
        switch item {
        case .module(let m):  m.icon
        case .project:        "folder"
        }
    }
    private var accent: Color {
        switch item {
        case .module:  MykColor.brand.color
        case .project: MykColor.drive.color
        }
    }
    private var primary: String {
        switch item {
        case .module(let m):  m.rawValue
        case .project(let p): "\(p.projectNumber) · \(p.title)"
        }
    }
    private var secondary: String? {
        switch item {
        case .module:         nil
        case .project(let p): customerFor(p)?.name
        }
    }
    private var kindLabel: String {
        switch item {
        case .module:  "Bereich"
        case .project: "Projekt"
        }
    }
}
