import CoreGraphics
import Foundation

/// Eine Wand als 2D-Draufsicht-Liniensegment (Y-Achse/Höhe ist weg-
/// projiziert) — Einheiten sind Meter, direkt aus RoomPlan übernommen.
struct WandSegment: Identifiable {
    let id: UUID
    let start: CGPoint
    let ende: CGPoint

    var laengeMeter: Double {
        Double(hypot(ende.x - start.x, ende.y - start.y))
    }
}

struct OeffnungSegment: Identifiable {
    enum Typ {
        case tuer, fenster, sonstige
    }

    let id: UUID
    let start: CGPoint
    let ende: CGPoint
    let typ: Typ
}

/// Vereinfachte 2D-Grundriss-Geometrie aus einem RoomPlan-Scan — Grundlage
/// für PDF-Zeichnung und DXF-Export.
struct RaumGeometrie {
    var waende: [WandSegment] = []
    var oeffnungen: [OeffnungSegment] = []
}
