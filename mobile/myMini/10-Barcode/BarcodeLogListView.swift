import SwiftUI

/// Alle bisher gescannten Rohtreffer, neustart-fest — kein Sync, kein
/// Abgleich, reine Ablage zum Nachschauen/Teilen.
struct BarcodeLogListView: View {
    let logStore: BarcodeLogStore

    var body: some View {
        List {
            if logStore.treffer.isEmpty {
                ContentUnavailableView(
                    "Noch nichts gescannt",
                    systemImage: "barcode.viewfinder",
                    description: Text("Scanner öffnen und einen Barcode/QR-Code einfangen.")
                )
            } else {
                ForEach(logStore.treffer.reversed()) { treffer in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(treffer.wert).font(.subheadline.weight(.semibold)).lineLimit(2)
                            Spacer()
                            ShareLink(item: treffer.wert) {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .accessibilityLabel("Wert teilen")
                        }
                        HStack {
                            Text(treffer.symbologie)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(MykColor.muted)
                            Spacer()
                            Text(treffer.erkanntAm, style: .relative)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(MykColor.muted)
                        }
                    }
                    .padding(.vertical, 2)
                    .swipeActions(edge: .trailing) {
                        Button("Löschen", role: .destructive) {
                            try? logStore.remove(treffer.id)
                        }
                    }
                }
            }
        }
        .navigationTitle("Scan-Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    BarcodeScannerScreen(logStore: logStore)
                } label: {
                    Image(systemName: "barcode.viewfinder")
                }
                .accessibilityLabel("Scanner öffnen")
            }
        }
    }
}

#Preview {
    NavigationStack {
        BarcodeLogListView(logStore: BarcodeLogStore())
    }
}
