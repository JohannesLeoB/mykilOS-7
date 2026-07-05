import RoomPlan
import SwiftUI

/// Bridge zu Apples eigenem RoomPlan-Framework (#5) — Apple liefert die
/// komplette Scan-UI (`RoomCaptureView`) und die 3D-Verarbeitung selbst,
/// wir wiren nur Start/Stopp + Export. **Das unsichere Stück dieser ganzen
/// AR-Batch:** RoomPlans Delegate-Protokolle sind neuer und stärker
/// versionsabhängig als klassisches ARKit/SceneKit — sollte Xcode beim
/// ersten Bauen eine fehlende Protokoll-Methode melden, ist das ein
/// kleiner, offensichtlicher Fix (Xcode schlägt den fehlenden Stub direkt
/// vor), kein grundlegendes Problem.

/// Ergebnis eines abgeschlossenen RoomPlan-Scans — USDZ fürs 3D-Ansehen/
/// Teilen, dazu die schon extrahierte 2D-Geometrie fürs PDF/DXF, ohne den
/// Scan doppelt anfassen zu müssen.
struct RoomPlanErgebnis {
    let usdzURL: URL
    let geometrie: RaumGeometrie
}

struct RoomPlanCaptureBridge: UIViewControllerRepresentable {
    @Binding var stoppAnfrage: Bool
    let onFertig: (RoomPlanErgebnis?) -> Void

    func makeUIViewController(context: Context) -> RoomPlanCaptureViewController {
        RoomPlanCaptureViewController(onFertig: onFertig)
    }

    func updateUIViewController(_ uiViewController: RoomPlanCaptureViewController, context: Context) {
        if stoppAnfrage {
            uiViewController.stoppen()
            DispatchQueue.main.async { stoppAnfrage = false }
        }
    }

    static func dismantleUIViewController(_ uiViewController: RoomPlanCaptureViewController, coordinator: ()) {
        uiViewController.aufraeumen()
    }
}

final class RoomPlanCaptureViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
    /// `RoomCaptureViewDelegate` erbt kurioserweise von `NSSecureCoding` —
    /// ohne diese eine Zeile bricht der Build mit "does not conform to
    /// protocol NSSecureCoding". `encode(with:)`/`init(coder:)` deckt
    /// UIViewController selbst ab; State-Restoration nutzen wir nicht.
    static var supportsSecureCoding: Bool { true }

    private let captureView = RoomCaptureView(frame: .zero)
    private let onFertig: (RoomPlanErgebnis?) -> Void

    init(onFertig: @escaping (RoomPlanErgebnis?) -> Void) {
        self.onFertig = onFertig
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) wird nicht unterstützt")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        captureView.frame = view.bounds
        captureView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        captureView.captureSession.delegate = self
        captureView.delegate = self
        view.addSubview(captureView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
    }

    func stoppen() {
        captureView.captureSession.stop()
    }

    func aufraeumen() {
        captureView.captureSession.stop()
    }

    /// RoomPlan hat die Rohdaten fertig verarbeitet — `true` heißt "ja,
    /// zeig mir das Endergebnis" statt eines neuen Scan-Versuchs.
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        error == nil
    }

    /// Der fertige, verarbeitete Raum — hier exportieren wir direkt als
    /// USDZ in eine temporäre Datei und ziehen parallel die 2D-Geometrie
    /// für PDF/DXF aus denselben Rohdaten, statt den Scan zweimal anfassen
    /// zu müssen.
    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        guard error == nil else {
            onFertig(nil)
            return
        }
        let zielURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).usdz")
        do {
            try processedResult.export(to: zielURL)
            let geometrie = RaumGeometrieExtractor.extrahiere(aus: processedResult)
            onFertig(RoomPlanErgebnis(usdzURL: zielURL, geometrie: geometrie))
        } catch {
            onFertig(nil)
        }
    }
}
