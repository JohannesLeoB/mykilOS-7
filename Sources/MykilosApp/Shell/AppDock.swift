import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers
import MykilosDesign

// MARK: - AppShortcutStore (S28)
// Persistente Liste von macOS-App-Shortcuts (Bundle-Pfade) für den Sidebar-Footer.
// Max 5; speichert nach UserDefaults. Rein lokal, keine externen Daten.
@MainActor @Observable
final class AppShortcutStore {
    static let maxCount = 7
    private static let key = "sidebar.appShortcuts"

    private(set) var paths: [String]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.paths = defaults.stringArray(forKey: Self.key) ?? []
    }

    func add(_ path: String) {
        guard paths.count < Self.maxCount, paths.contains(path) == false else { return }
        paths.append(path); persist()
    }
    func remove(_ path: String) { paths.removeAll { $0 == path }; persist() }
    func replace(_ old: String, with new: String) {
        guard let index = paths.firstIndex(of: old), paths.contains(new) == false else { return }
        paths[index] = new; persist()
    }
    private func persist() { defaults.set(paths, forKey: Self.key) }
}

// MARK: - AppDockStrip
// App-Shortcuts im Sidebar-Footer. Breit: Icon links wie die Menüpunkte ausgerichtet.
// Kompakt: nur Icons mittig, Running-Punkt als Overlay. Klick startet/fokussiert via
// NSWorkspace. Hinzufügen per „+"-Picker (/Applications) oder Drag einer .app aus Finder.
struct AppDockStrip: View {
    let store: AppShortcutStore
    var compact: Bool = false
    @State private var tick = 0
    private let heartbeat = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: compact ? .center : .leading, spacing: compact ? MykSpace.s2 : 2) {
            ForEach(store.paths, id: \.self) { path in
                AppDockIcon(
                    path: path, isRunning: Self.isRunning(path), compact: compact,
                    onRemove: { store.remove(path) },
                    onReplace: { if let new = Self.pickApp() { store.replace(path, with: new) } }
                )
                .transition(.scale.combined(with: .opacity))
            }
            if store.paths.count < AppShortcutStore.maxCount { addButton }
        }
        .padding(.vertical, MykSpace.s2)
        .frame(maxWidth: .infinity, alignment: compact ? .center : .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(MykColor.paper2.color.opacity(0.6))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(MykColor.line.color.opacity(0.6), lineWidth: 1))
        )
        .padding(.bottom, MykSpace.s2)
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: store.paths)
        .onReceive(heartbeat) { _ in tick &+= 1 }
        .dropDestination(for: URL.self) { urls, _ in
            var added = false
            for url in urls where url.pathExtension.lowercased() == "app" || url.hasDirectoryPath { store.add(url.path); added = true }
            return added
        }
        .id(tick)
    }

    private var addButton: some View {
        Button { if let new = Self.pickApp() { store.add(new) } } label: { plusLabel }
            .buttonStyle(.plain)
            .help("App hinzufügen")
            .accessibilityLabel("App hinzufügen")
    }

    @ViewBuilder private var plusLabel: some View {
        let box = Image(systemName: "plus")
            .font(.mykSmall).foregroundStyle(MykColor.faint.color)
            .frame(width: 28, height: 28)
            .background(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(MykColor.line.color, style: StrokeStyle(lineWidth: 1, dash: [3])))
        if compact {
            box.frame(maxWidth: .infinity)
        } else {
            HStack(spacing: 12) {
                Circle().fill(Color.clear).frame(width: 6, height: 6)
                box
                Spacer()
            }
            .padding(.horizontal, MykSpace.s4)
        }
    }

    /// NSOpenPanel auf /Applications, gibt den gewählten App-Pfad zurück.
    static func pickApp() -> String? {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application, .folder]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.prompt = "Hinzufügen"
        return panel.runModal() == .OK ? panel.url?.path : nil
    }

    static func isRunning(_ path: String) -> Bool {
        let target = URL(fileURLWithPath: path).standardizedFileURL
        return NSWorkspace.shared.runningApplications.contains { $0.bundleURL?.standardizedFileURL == target }
    }
}

// MARK: - AppDockIcon
private struct AppDockIcon: View {
    let path: String
    let isRunning: Bool
    let compact: Bool
    let onRemove: () -> Void
    let onReplace: () -> Void
    @State private var hovered = false

    var body: some View {
        Button { launch() } label: { label }
            .buttonStyle(.plain)
            .onHover { hover in withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { hovered = hover } }
            .help(FileManager.default.displayName(atPath: path))
            .accessibilityLabel(FileManager.default.displayName(atPath: path))
            .contextMenu {
                Button("Ersetzen …", action: onReplace)
                Button("Entfernen", role: .destructive, action: onRemove)
            }
    }

    @ViewBuilder private var label: some View {
        if compact {
            icon
                .overlay(alignment: .bottomTrailing) {
                    if isRunning {
                        Circle().fill(MykColor.positive.color).frame(width: 7, height: 7)
                            .overlay(Circle().stroke(MykColor.paper.color, lineWidth: 1.5))
                    }
                }
                .frame(maxWidth: .infinity)
        } else {
            HStack(spacing: 12) {
                Circle().fill(isRunning ? MykColor.positive.color : Color.clear).frame(width: 6, height: 6)
                icon
                Spacer()
            }
            .padding(.vertical, 3)
            .padding(.horizontal, MykSpace.s4)
            .contentShape(Rectangle())
        }
    }

    private var icon: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: path))
            .resizable().interpolation(.high)
            .frame(width: 28, height: 28)
            .scaleEffect(hovered ? 1.12 : 1.0)
    }

    private func launch() {
        let url = URL(fileURLWithPath: path)
        if path.hasSuffix(".app") {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: nil)
        } else {
            NSWorkspace.shared.open(url)   // Ordner im Finder / Datei in Standard-App
        }
    }
}
