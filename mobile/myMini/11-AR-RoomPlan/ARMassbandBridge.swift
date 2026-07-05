import ARKit
import SceneKit
import SwiftUI

/// Bridge zur echten AR-Session (ARKit/SceneKit) — kein RoomPlan, kein
/// gespeicherter Weltanker über die Session hinaus. Tippen wirft einen
/// Raycast in die reale Geometrie (Ebenen-Schätzung), zwei Treffer ergeben
/// eine Distanz. Nutzt dieselbe Kamera-Berechtigung wie alles andere hier
/// (ARKit braucht keinen eigenen Info.plist-Schlüssel).
struct ARMassbandBridge: UIViewControllerRepresentable {
    let messer: ARMassbandMesser

    func makeUIViewController(context: Context) -> ARMassbandViewController {
        let controller = ARMassbandViewController()
        controller.onTreffer = { punkt in
            messer.punktGesetzt(punkt)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: ARMassbandViewController, context: Context) {
        if messer.ersterPunkt == nil && messer.abstandMeter == nil {
            uiViewController.alleMarkerEntfernen()
        }
    }

    static func dismantleUIViewController(_ uiViewController: ARMassbandViewController, coordinator: ()) {
        uiViewController.sessionBeenden()
    }
}

final class ARMassbandViewController: UIViewController {
    var onTreffer: ((SIMD3<Float>) -> Void)?

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

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let ort = gesture.location(in: sceneView)
        guard let anfrage = sceneView.raycastQuery(from: ort, allowing: .estimatedPlane, alignment: .any),
              let treffer = sceneView.session.raycast(anfrage).first else { return }

        let spalte = treffer.worldTransform.columns.3
        let punkt = SIMD3<Float>(spalte.x, spalte.y, spalte.z)
        markiere(bei: punkt)
        onTreffer?(punkt)
    }

    private func markiere(bei punkt: SIMD3<Float>) {
        let kugel = SCNSphere(radius: 0.006)
        kugel.firstMaterial?.diffuse.contents = UIColor.systemOrange
        let knoten = SCNNode(geometry: kugel)
        knoten.position = SCNVector3(punkt.x, punkt.y, punkt.z)
        sceneView.scene.rootNode.addChildNode(knoten)
        markerKnoten.append(knoten)
    }

    func alleMarkerEntfernen() {
        markerKnoten.forEach { $0.removeFromParentNode() }
        markerKnoten.removeAll()
    }
}
