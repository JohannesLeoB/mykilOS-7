import ARKit
import Observation

/// Reiner Zustand einer AR-Maßband-Session — zwei Punkte antippen, Distanz
/// sehen. Kein SceneKit/ARKit-Typ verlässt diese Datei nach außen als
/// gespeicherter Zustand (kein Anker-Persistenz-Anspruch über die laufende
/// Session hinaus — anders als ein "Vorher-Standort wiederfinden" braucht
/// ein Maßband keine Session-Wiederherstellung, deshalb ist das hier viel
/// unkomplizierter als der zurückgestellte ARWorldMap-Teil von #51/#53).
@MainActor
@Observable
final class ARMassbandMesser {
    private(set) var ersterPunkt: SIMD3<Float>?
    private(set) var abstandMeter: Double?

    func punktGesetzt(_ punkt: SIMD3<Float>) {
        guard let ersterPunkt else {
            self.ersterPunkt = punkt
            return
        }
        let differenz = punkt - ersterPunkt
        abstandMeter = Double(simd_length(differenz))
        self.ersterPunkt = nil
    }

    func zuruecksetzen() {
        ersterPunkt = nil
        abstandMeter = nil
    }

    var abstandText: String? {
        guard let abstandMeter else { return nil }
        if abstandMeter < 1 {
            return String(format: "%.0f cm", abstandMeter * 100)
        }
        return String(format: "%.2f m", abstandMeter)
    }
}
