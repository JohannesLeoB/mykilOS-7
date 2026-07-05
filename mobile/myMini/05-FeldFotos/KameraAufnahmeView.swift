import SwiftUI
import UIKit

/// Bridge zur nativen Live-Kamera — kein Fotoalbum-Zugriff, das Foto wird im
/// Moment geboren, nie nachsortiert (Johannes' ★3-UX-Design, Nacht 04.07.).
/// Liefert Bild + rohe Metadaten direkt aus dem Aufnahme-Callback.
struct KameraAufnahmeView: UIViewControllerRepresentable {
    let onAufnahme: (UIImage, [String: Any]) -> Void
    let onAbbruch: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onAufnahme: onAufnahme, onAbbruch: onAbbruch)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onAufnahme: (UIImage, [String: Any]) -> Void
        let onAbbruch: () -> Void

        init(onAufnahme: @escaping (UIImage, [String: Any]) -> Void, onAbbruch: @escaping () -> Void) {
            self.onAufnahme = onAufnahme
            self.onAbbruch = onAbbruch
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard let bild = info[.originalImage] as? UIImage else {
                onAbbruch()
                return
            }
            let metadaten = info[.mediaMetadata] as? [String: Any] ?? [:]
            onAufnahme(bild, metadaten)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onAbbruch()
        }
    }
}
