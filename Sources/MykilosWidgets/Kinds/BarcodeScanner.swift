import SwiftUI
import AVFoundation
import CoreMedia
import Vision
import AppKit
import MykilosDesign

// MARK: - BarcodeScannerSheet
// Live-Kamera-Sheet: Vorschau + Vision-Barcode/QR-Erkennung, meldet den ersten
// Treffer zurück. Reine Erfassung, kein Schreiben. Live-Gate: echte Kamera prüft
// Johannes am Gerät — der Code kompiliert, der Scan selbst ist nicht unit-testbar.
struct BarcodeScannerSheet: View {
    let onCode: (String) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            CameraPreview(onCode: onCode)
                .frame(minWidth: 480, minHeight: 360)
            HStack {
                Image(systemName: "barcode.viewfinder").foregroundStyle(MykColor.drive.color)
                Text("Barcode oder QR-Code vor die Kamera halten")
                    .font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
                Spacer()
                Button("Schließen", action: onClose)
                    .font(.mykCaption).buttonStyle(.plain)
                    .foregroundStyle(MykColor.drive.color)
            }
            .padding(MykSpace.s5)
            .background(MykColor.card.color)
        }
    }
}

// MARK: - CameraPreview (NSViewRepresentable)
struct CameraPreview: NSViewRepresentable {
    let onCode: (String) -> Void

    func makeCoordinator() -> BarcodeCaptureController { BarcodeCaptureController(onCode: onCode) }

    func makeNSView(context: Context) -> PreviewNSView {
        let view = PreviewNSView()
        context.coordinator.attach(to: view)
        return view
    }

    func updateNSView(_ nsView: PreviewNSView, context: Context) {}

    static func dismantleNSView(_ nsView: PreviewNSView, coordinator: BarcodeCaptureController) {
        coordinator.stop()
    }
}

// NSView, dessen Backing-Layer die Vorschau hostet; hält Sublayer auf Bounds.
final class PreviewNSView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) wird nicht genutzt") }
    override func layout() {
        super.layout()
        layer?.sublayers?.forEach { $0.frame = bounds }
    }
}

// MARK: - BarcodeCaptureController
// Baut die Session auf einer Hintergrund-Queue, erkennt Codes via Vision und
// meldet den ERSTEN Treffer genau einmal auf dem MainActor zurück.
final class BarcodeCaptureController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "mykilos.barcode.capture")
    private let onCode: (String) -> Void
    private var didFind = false

    init(onCode: @escaping (String) -> Void) {
        self.onCode = onCode
        super.init()
    }

    func attach(to view: PreviewNSView) {
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer?.addSublayer(preview)
        queue.async { [weak self] in self?.configureAndStart() }
    }

    private func configureAndStart() {
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration(); return
        }
        session.addInput(input)
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        session.startRunning()
    }

    func stop() {
        queue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard !didFind, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNDetectBarcodesRequest()
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        guard let payload = (request.results?.first as? VNBarcodeObservation)?.payloadStringValue,
              payload.isEmpty == false else { return }
        didFind = true
        let callback = onCode
        DispatchQueue.main.async { callback(payload) }
    }
}
