import SwiftUI
import MykilosDesign
import MykilosServices

// MARK: - SchaltzentrumView
// Zeigt alle Datenstrom-Weichen aus DatastromManifest.json mit letztem Handshake
// (aus DataFlowLogger.entries) und Status-Farbe. Read-only.
struct SchaltzentrumView: View {
    @Environment(AppState.self) private var appState

    private let manifest: [ManifestEntry] = Self.loadManifest()

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            Text("Datenstrom-Schaltzentrale")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            Text("Alle \(manifest.count) Weichen · Live-Status")
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)

            ProjectNumberBindingSection()

            // mykilOS 8, Block D: Projekt-Geburt in der TEST-Sandbox (Live-Verifikation).
            ProvisioningTestView()

            VStack(spacing: 1) {
                // Header
                HStack(spacing: 0) {
                    Text("Integrations-ID")
                        .frame(width: 230, alignment: .leading)
                    Text("System")
                        .frame(width: 130, alignment: .leading)
                    Text("Richtung")
                        .frame(width: 90, alignment: .leading)
                    Text("Letzter Handshake")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Status")
                        .frame(width: 70, alignment: .trailing)
                }
                .font(.mykMono(9))
                .foregroundStyle(MykColor.muted.color)
                .padding(.horizontal, MykSpace.s4)
                .padding(.vertical, MykSpace.s2)
                .background(MykColor.paper2.color)

                ForEach(manifest) { entry in
                    WeichenRow(entry: entry, lastEntry: lastEntry(for: entry.integrationID))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: MykRadius.md)
                    .stroke(MykColor.line.color, lineWidth: 1)
            )
        }
    }

    private func lastEntry(for id: String) -> DataFlowEntry? {
        appState.dataFlow.entries.first { $0.integrationID == id }
    }

    // MARK: - Manifest Loading

    struct ManifestEntry: Decodable, Identifiable {
        let integrationID: String
        let name: String
        let system: String
        let direction: String
        let link: String
        var id: String { integrationID }
    }

    private static func loadManifest() -> [ManifestEntry] {
        // 1) Aus dem App-Bundle laden (ausgelieferte App). Resources werden via
        //    .copy("Resources") gebündelt → Bundle.module kennt sie. DAS ist der
        //    Live-Pfad; vorher lud die View nur über #filePath und zeigte deshalb
        //    im Bundle „0 Weichen".
        var data: Data?
        if let url = Bundle.module.url(forResource: "DatastromManifest", withExtension: "json", subdirectory: "Resources")
            ?? Bundle.module.url(forResource: "DatastromManifest", withExtension: "json") {
            data = try? Data(contentsOf: url)
        }
        // 2) Dev/Test-Fallback: relativ zur Quelldatei. EINMAL hochnavigieren
        //    (SchaltzentrumView.swift → MykilosApp/), dann Resources/… — die frühere
        //    Variante navigierte eine Ebene zu weit (Sources/Resources/…, existiert nicht).
        if data == nil {
            let devPath = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .appendingPathComponent("Resources/DatastromManifest.json")
            data = try? Data(contentsOf: devPath)
        }
        guard let data,
              let entries = try? JSONDecoder().decode([ManifestEntry].self, from: data)
        else { return [] }
        return entries
    }
}

// MARK: - WeichenRow

private struct WeichenRow: View {
    let entry: SchaltzentrumView.ManifestEntry
    let lastEntry: DataFlowEntry?

    var body: some View {
        HStack(spacing: 0) {
            Text(entry.integrationID)
                .font(.mykMono(10))
                .foregroundStyle(MykColor.ink.color)
                .frame(width: 230, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.tail)

            Text(entry.system)
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
                .frame(width: 130, alignment: .leading)
                .lineLimit(1)

            directionBadge
                .frame(width: 90, alignment: .leading)

            Text(handshakeLabel)
                .font(.mykMono(9))
                .foregroundStyle(MykColor.muted.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, MykSpace.s4)
        .padding(.vertical, MykSpace.s3)
        .background(MykColor.paper.color)
    }

    private var directionBadge: some View {
        Text(entry.direction)
            .font(.mykMono(8))
            .foregroundStyle(directionColor)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(directionColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private var directionColor: Color {
        switch entry.direction {
        case "READ":          MykColor.people.color
        case "WRITE":         MykColor.tasks.color
        case "BIDIRECTIONAL": MykColor.brand.color
        default:              MykColor.muted.color
        }
    }

    private var handshakeLabel: String {
        guard let e = lastEntry else { return "–" }
        let fmt = RelativeDateTimeFormatter()
        fmt.locale = Locale(identifier: "de_DE")
        fmt.unitsStyle = .abbreviated
        return fmt.localizedString(for: e.timestamp, relativeTo: Date())
            + (e.action == .error ? " · Fehler" : "")
    }

    private var statusColor: Color {
        guard let e = lastEntry else { return MykColor.faint.color }
        switch e.action {
        case .success: return MykColor.positive.color
        case .error:   return MykColor.critical.color
        case .start:   return MykColor.tasks.color
        }
    }
}
