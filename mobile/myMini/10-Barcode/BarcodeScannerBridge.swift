import SwiftUI
import VisionKit

/// Bridge zur nativen Live-Barcode-Erkennung (VisionKit, on-device, kein
/// Server). Liefert jeden neu erkannten Treffer roh weiter — keine
/// Interpretation, kein Abgleich, das entscheidet der Aufrufer.
@available(iOS 16.0, *)
struct BarcodeScannerBridge: UIViewControllerRepresentable {
    let onTreffer: (String, String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTreffer: onTreffer)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onTreffer: (String, String) -> Void
        private var gemeldet = Set<String>()

        init(onTreffer: @escaping (String, String) -> Void) {
            self.onTreffer = onTreffer
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            for item in addedItems {
                guard case .barcode(let barcode) = item, let wert = barcode.payloadStringValue else { continue }
                guard !gemeldet.contains(wert) else { continue }
                gemeldet.insert(wert)
                onTreffer(wert, barcode.observation.symbology.rawValue)
            }
        }
    }
}
