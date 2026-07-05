import SwiftUI

/// Alle bisher geloggten Wareneingänge, neustart-fest — kein Sync, kein
/// Abgleich gegen Bestelllisten, reine Ablage zum Nachschauen.
struct WareneingangsLogListView: View {
    let wareneingangStore: WareneingangsLogStore

    var body: some View {
        List {
            if wareneingangStore.ereignisse.isEmpty {
                ContentUnavailableView(
                    "Noch kein Wareneingang",
                    systemImage: "shippingbox",
                    description: Text("Kamera-Knopf in der Fang-Karte antippen, 'Lieferschein' wählen.")
                )
            } else {
                ForEach(wareneingangStore.ereignisse.reversed()) { ereignis in
                    row(for: ereignis)
                        .swipeActions(edge: .trailing) {
                            Button("Löschen", role: .destructive) {
                                try? wareneingangStore.remove(ereignis.id)
                            }
                        }
                }
            }
        }
        .navigationTitle("Wareneingang")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func row(for ereignis: WareneingangsEreignis) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Image(systemName: "shippingbox").foregroundStyle(MykColor.brand)
                VStack(alignment: .leading, spacing: 2) {
                    Text(ereignis.projectTitel).font(.subheadline.weight(.semibold))
                    if !ereignis.trackingNummer.isEmpty {
                        Text(ereignis.trackingNummer)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(MykColor.muted)
                    }
                    if !ereignis.absender.isEmpty {
                        Text(ereignis.absender).font(.caption).foregroundStyle(MykColor.muted)
                    }
                }
            }
            Text(ereignis.erfasstAm, style: .relative)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(MykColor.muted)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        WareneingangsLogListView(wareneingangStore: WareneingangsLogStore())
    }
}
