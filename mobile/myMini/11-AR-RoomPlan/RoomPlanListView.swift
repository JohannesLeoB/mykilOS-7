import SwiftUI
import QuickLook

/// Gespeicherte RoomPlan-Scans — Vorschau über das eingebaute
/// `.quickLookPreview` (USDZ braucht keinen eigenen 3D-Viewer, iOS bringt
/// das schon mit), Teilen über das System-Share-Sheet.
struct RoomPlanListView: View {
    let roomPlanStore: RoomPlanStore
    let store: ProjectStore

    @State private var vorschauURL: URL?

    var body: some View {
        List {
            if roomPlanStore.aufnahmen.isEmpty {
                ContentUnavailableView(
                    "Noch keine Raumscans",
                    systemImage: "cube.transparent",
                    description: Text("Werkzeuge → RoomPlan-Aufmaß, um einen Raum zu scannen.")
                )
            } else {
                ForEach(roomPlanStore.aufnahmen.reversed()) { aufnahme in
                    HStack {
                        Button {
                            vorschauURL = roomPlanStore.dateiURL(fuer: aufnahme)
                        } label: {
                            HStack {
                                Image(systemName: "cube.transparent.fill").foregroundStyle(MykColor.brand)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(aufnahme.projectTitel).font(.subheadline.weight(.semibold))
                                    Text(aufnahme.aufgenommenAm, style: .relative)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(MykColor.muted)
                                }
                            }
                        }
                        .foregroundStyle(MykColor.ink)
                        Spacer()
                        ShareLink(item: roomPlanStore.dateiURL(fuer: aufnahme)) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .buttonStyle(.plain)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Löschen", role: .destructive) {
                            try? roomPlanStore.remove(aufnahme.id)
                        }
                    }
                }
            }
        }
        .navigationTitle("Raumscans")
        .navigationBarTitleDisplayMode(.inline)
        .quickLookPreview($vorschauURL)
    }
}

#Preview {
    NavigationStack {
        RoomPlanListView(roomPlanStore: RoomPlanStore(), store: ProjectStore())
    }
}
