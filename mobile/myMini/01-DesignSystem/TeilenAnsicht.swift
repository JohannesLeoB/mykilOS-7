import SwiftUI
import UIKit

/// Gemeinsamer Wrapper um `UIActivityViewController` — für Dateien, die
/// erst im Moment des Antippens entstehen (PDF/DXF-Export), wo `ShareLink`
/// nicht reicht, weil die Datei beim Aufbau des Buttons noch nicht
/// existiert. Vorher als private Kopie in `RoomPlanCaptureScreen`, jetzt
/// geteilt, weil drei Export-Flows sie brauchen.
struct TeilenAnsicht: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Identifiable-Hülle für `.sheet(item:)`-Präsentation einer frisch
/// erzeugten Export-Datei.
struct ExportDatei: Identifiable {
    let id = UUID()
    let url: URL
}
