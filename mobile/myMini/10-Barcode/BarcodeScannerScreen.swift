import SwiftUI
import VisionKit

/// Live-Scan → sofort ins Log. Bewusst OHNE WorkBasket-Abgleich (kein
/// WorkBasket-Sync auf mobile existiert) — ein ehrlicher Rohdaten-Log,
/// kein vorgetäuschter Treffer/Fehltreffer gegen Schiffsdaten.
struct BarcodeScannerScreen: View {
    let logStore: BarcodeLogStore

    @State private var sessionTreffer: [BarcodeTreffer] = []

    var body: some View {
        Group {
            if #available(iOS 16.0, *), DataScannerViewController.isSupported, DataScannerViewController.isAvailable {
                liveAnsicht
            } else {
                ContentUnavailableView(
                    "Scanner nicht verfügbar",
                    systemImage: "barcode.viewfinder",
                    description: Text("Dieses Gerät oder der iOS-Stand unterstützt den Live-Scanner nicht.")
                )
            }
        }
        .navigationTitle("Barcode/QR-Scanner")
        .navigationBarTitleDisplayMode(.inline)
    }

    @available(iOS 16.0, *)
    private var liveAnsicht: some View {
        VStack(spacing: 0) {
            BarcodeScannerBridge { wert, symbologie in
                let eintrag = BarcodeTreffer(wert: wert, symbologie: symbologie)
                sessionTreffer.insert(eintrag, at: 0)
                try? logStore.append(eintrag)
            }
            .frame(maxHeight: .infinity)

            if !sessionTreffer.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DIESE SITZUNG · ROHDATEN, KEIN ABGLEICH")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(MykColor.muted)
                        .padding(.horizontal, 14)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(sessionTreffer) { treffer in
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(treffer.wert).font(.subheadline.weight(.semibold)).lineLimit(1)
                                    Text(treffer.symbologie)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(MykColor.muted)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .frame(maxHeight: 160)
                }
                .padding(.vertical, 8)
                .background(MykColor.card)
            }
        }
    }
}

#Preview {
    NavigationStack {
        BarcodeScannerScreen(logStore: BarcodeLogStore())
    }
}
