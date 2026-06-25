import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - DriveWidget
// Dateien & Zeichnungen. Mosaikvorschau. Terrakotta.
// Akt 1: Demo-Daten. Akt 3: echte Drive-API.
public struct DriveWidget: View {
    public let projectID: String
    public init(projectID: String) { self.projectID = projectID }

    public var body: some View {
        WidgetContainer(
            kind: .drive,
            sourceLabel: "DRIVE  ·  ZEICHNUNGEN MEYER  ·  14 DATEIEN",
            renderState: .content,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                widgetHeader
                mosaic
            }
        }
    }

    private var widgetHeader: some View {
        HStack {
            SourceChip(kind: .drive)
            Text("Zeichnungen & Pläne").mykWidgetTitle()
            Spacer()
            newBadge
        }
    }

    private var newBadge: some View {
        Text("1 NEU")
            .font(.mykMono(9))
            .foregroundStyle(.white)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(MykColor.drive.color))
    }

    private var mosaic: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 6), count: 3), spacing: 6) {
            ForEach(demoTiles, id: \.id) { tile in
                RoundedRectangle(cornerRadius: 8)
                    .fill(tile.gradient)
                    .frame(height: 52)
                    .overlay(alignment: .topLeading) {
                        if tile.isNew {
                            Text("NEU")
                                .font(.mykMono(8))
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 4).fill(MykColor.drive.color))
                                .padding(5)
                        }
                    }
            }
        }
    }

    private struct DemoTile: Identifiable {
        let id = UUID()
        let gradient: LinearGradient
        let isNew: Bool
    }

    private var demoTiles: [DemoTile] {
        [
            DemoTile(gradient: .init(colors: [Color(hex: 0xEAD9CB), Color(hex: 0xD3BBA6)], startPoint: .topLeading, endPoint: .bottomTrailing), isNew: false),
            DemoTile(gradient: .init(colors: [Color(hex: 0xE0D3C4), Color(hex: 0xC2A98F)], startPoint: .topLeading, endPoint: .bottomTrailing), isNew: false),
            DemoTile(gradient: .init(colors: [Color(hex: 0xEFE6DA), Color(hex: 0xDCC8B2)], startPoint: .topLeading, endPoint: .bottomTrailing), isNew: false),
            DemoTile(gradient: .init(colors: [Color(hex: 0xEFE6DA), Color(hex: 0xDCC8B2)], startPoint: .topLeading, endPoint: .bottomTrailing), isNew: false),
            DemoTile(gradient: .init(colors: [Color(hex: 0xEAD9CB), Color(hex: 0xD3BBA6)], startPoint: .topLeading, endPoint: .bottomTrailing), isNew: true),
            DemoTile(gradient: .init(colors: [Color(hex: 0xE0D3C4), Color(hex: 0xC2A98F)], startPoint: .topLeading, endPoint: .bottomTrailing), isNew: false),
        ]
    }
}

private extension Color {
    init(hex: UInt32) { self.init(.sRGB, red: Double((hex >> 16) & 0xFF)/255, green: Double((hex >> 8) & 0xFF)/255, blue: Double(hex & 0xFF)/255, opacity: 1) }
}
