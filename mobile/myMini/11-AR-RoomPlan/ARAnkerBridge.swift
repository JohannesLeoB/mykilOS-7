import ARKit
import SceneKit
import SwiftUI

/// Bridge zur AR-Session fürs Gewerke-Taggen (#6). Tippen platziert einen
/// farbigen, beschrifteten Marker vom aktuell gewählten Gewerke-Typ — rein
/// visuell für den Moment der Aufnahme, keine Anker-Persistenz über die
/// Session hinaus. Der Screenshot (`snapshot()`) enthält die Marker direkt,
/// kein eigener Overlay-Compositing-Schritt nötig.
struct ARAnkerBridge: UIViewControllerRepresentable {
    let aktuellerTyp: GewerkeTyp
    @Binding var snapshotAnfrage: Bool
    let onSnapshot: (UIImage) -> Void

    func makeUIViewController(context: Context) -> ARAnkerViewController {
        ARAnkerViewController()
    }

    func updateUIViewController(_ uiViewController: ARAnkerViewController, context: Context) {
        uiViewController.aktuellerTyp = aktuellerTyp
        if snapshotAnfrage {
            let bild = uiViewController.snapshotErstellen()
            DispatchQueue.main.async {
                onSnapshot(bild)
                snapshotAnfrage = false
            }
        }
    }

    static func dismantleUIViewController(_ uiViewController: ARAnkerViewController, coordinator: ()) {
        uiViewController.sessionBeenden()
    }
}

final class ARAnkerViewController: UIViewController {
    var aktuellerTyp: GewerkeTyp = .wasser

    private let sceneView = ARSCNView()
    private var markerKnoten: [SCNNode] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.frame = view.bounds
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.scene = SCNScene()
        sceneView.automaticallyUpdatesLighting = true
        view.addSubview(sceneView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let konfiguration = ARWorldTrackingConfiguration()
        konfiguration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(konfiguration)
    }

    func sessionBeenden() {
        sceneView.session.pause()
    }

    func snapshotErstellen() -> UIImage {
        sceneView.snapshot()
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let ort = gesture.location(in: sceneView)
        guard let anfrage = sceneView.raycastQuery(from: ort, allowing: .estimatedPlane, alignment: .any),
              let treffer = sceneView.session.raycast(anfrage).first else { return }

        let spalte = treffer.worldTransform.columns.3
        markiere(bei: SCNVector3(spalte.x, spalte.y, spalte.z), typ: aktuellerTyp)
    }

    private func markiere(bei punkt: SCNVector3, typ: GewerkeTyp) {
        let kugel = SCNSphere(radius: 0.012)
        kugel.firstMaterial?.diffuse.contents = typ.farbe
        let kugelKnoten = SCNNode(geometry: kugel)
        kugelKnoten.position = punkt

        let text = SCNText(string: typ.rawValue, extrusionDepth: 0.2)
        text.font = .systemFont(ofSize: 10)
        text.firstMaterial?.diffuse.contents = UIColor.white
        let textKnoten = SCNNode(geometry: text)
        let skala: Float = 0.003
        textKnoten.scale = SCNVector3(skala, skala, skala)
        textKnoten.position = SCNVector3(punkt.x, punkt.y + 0.03, punkt.z)
        textKnoten.constraints = [SCNBillboardConstraint()]

        sceneView.scene.rootNode.addChildNode(kugelKnoten)
        sceneView.scene.rootNode.addChildNode(textKnoten)
        markerKnoten.append(kugelKnoten)
        markerKnoten.append(textKnoten)
    }
}
