import CoreGraphics
import RoomPlan
import simd

/// Wandelt RoomPlans 3D-Erfassung in eine einfache 2D-Grundriss-Geometrie
/// um (Draufsicht von oben, Höhe fällt weg). Nutzt, dass eine Wand-Surface
/// in RoomPlan ihre Breite entlang der lokalen X-Achse hat — die
/// Weltposition der beiden Wandenden ergibt sich aus Mittelpunkt ±
/// halbe Breite entlang der ins Weltkoordinatensystem transformierten
/// X-Achse.
///
/// **Mathematisch plausibel, aber nicht live gegen einen echten Scan
/// verifiziert** — gleiche Ehrlichkeit wie der Rest dieser RoomPlan-Batch.
/// Sollte die erste echte Zeichnung gespiegelt oder verdreht wirken, ist
/// das ein Vorzeichen-/Achsen-Fix, kein Konzeptfehler.
enum RaumGeometrieExtractor {
    static func extrahiere(aus raum: CapturedRoom) -> RaumGeometrie {
        var geometrie = RaumGeometrie()
        geometrie.waende = raum.walls.map { wandSegment(aus: $0) }
        geometrie.oeffnungen =
            raum.doors.map { oeffnungSegment(aus: $0, typ: .tuer) }
            + raum.windows.map { oeffnungSegment(aus: $0, typ: .fenster) }
            + raum.openings.map { oeffnungSegment(aus: $0, typ: .sonstige) }
        return geometrie
    }

    private static func wandSegment(aus surface: CapturedRoom.Surface) -> WandSegment {
        let (start, ende) = endpunkte(fuer: surface)
        return WandSegment(id: surface.identifier, start: start, ende: ende)
    }

    private static func oeffnungSegment(aus surface: CapturedRoom.Surface, typ: OeffnungSegment.Typ) -> OeffnungSegment {
        let (start, ende) = endpunkte(fuer: surface)
        return OeffnungSegment(id: surface.identifier, start: start, ende: ende, typ: typ)
    }

    private static func endpunkte(fuer surface: CapturedRoom.Surface) -> (CGPoint, CGPoint) {
        let transform = surface.transform
        let mitte = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        let xAchseRoh = SIMD3<Float>(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z)
        let richtung = simd_length(xAchseRoh) > 0 ? simd_normalize(xAchseRoh) : SIMD3<Float>(1, 0, 0)
        let halbeLaenge = surface.dimensions.x / 2

        let start = mitte - richtung * halbeLaenge
        let ende = mitte + richtung * halbeLaenge

        // Draufsicht: Welt-X/Welt-Z bilden die Grundriss-Ebene, Welt-Y (Höhe) fällt weg.
        return (
            CGPoint(x: CGFloat(start.x), y: CGFloat(start.z)),
            CGPoint(x: CGFloat(ende.x), y: CGFloat(ende.z))
        )
    }
}
