import Foundation

// MARK: - feat/tischler-predictor · Phase 2 (Ausstattungsgrad / Scope-Normalisierung)
//
// Der verifizierte Korpus (EstimationCore_v1_BRANDLESS) trägt pro Anker einen
// VORBERECHNETEN `equipment_density` (Ausstattungsgrad) plus `drawers_per_lfm`.
// Das ist der Verlässlichkeits-Parameter, der die breite €/m²-Front-Spanne
// (1365–2809, siehe BottomUpCost) in begründbare Bänder zerlegt: eine schlichte
// 4,5-m-Eiche-Zeile mit 6 Schubkästen darf NICHT gegen einen hochausgestatteten
// Legrabox-/Innenauszug-Anker gematcht werden.
//
// Regel SCOPE-006 (verbatim aus scope_signature_rules):
//   drawers_per_lfm = drawer_count / length_m
//     0           → none
//     >0  ≤ 1.5   → low
//     >1.5 ≤ 3.0  → medium
//     >3.0 ≤ 4.5  → high
//     >4.5        → very_high
//     length/Anzahl unbekannt → unknown
//
// WICHTIGE Asymmetrie (Datenhygiene): Auf der ANKER-Seite ist die Dichte echt
// vorberechnet (aus strukturierten Positionsdaten). Auf der ANFRAGE-Seite leiten
// wir sie aus dem Freitext ab — dort bedeutet „kein Schubkasten genannt" NICHT
// „null Schubkästen", sondern schlicht „unbekannt". Darum klassifiziert die
// Query-Variante `drawerCount == 0` bewusst als `.unknown`, nicht als `.none`.
// So entsteht kein falscher Ausschluss aus bloßer Schweigsamkeit der Eingabe.

/// Ausstattungsgrad einer Küchenzeile (Schubkasten-Dichte pro Laufmeter).
public enum KitchenEquipmentDensity: String, Codable, Equatable, Sendable, CaseIterable {
    case none
    case low
    case medium
    case high
    case veryHigh = "very_high"
    case unknown

    /// Tolerantes Einlesen des Korpus-Rohwerts (z. B. „very_high", „LOW", "").
    public init(rawCorpus: String) {
        let key = rawCorpus.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch key {
        case "none":               self = .none
        case "low":                self = .low
        case "medium":             self = .medium
        case "high":               self = .high
        case "very_high", "veryhigh": self = .veryHigh
        default:                   self = .unknown
        }
    }

    /// Ordinaler Rang (none=0 … very_high=4). `unknown` hat keinen Rang.
    public var level: Int? {
        switch self {
        case .none:     return 0
        case .low:      return 1
        case .medium:   return 2
        case .high:     return 3
        case .veryHigh: return 4
        case .unknown:  return nil
        }
    }

    /// SCOPE-006: Klassifikation direkt aus Schubkästen pro Laufmeter.
    public static func classify(drawersPerLfm value: Double?) -> KitchenEquipmentDensity {
        guard let value, value >= 0 else { return .unknown }
        if value == 0 { return .none }
        if value <= 1.5 { return .low }
        if value <= 3.0 { return .medium }
        if value <= 4.5 { return .high }
        return .veryHigh
    }

    /// ANKER-Seite (Korpus): echte Daten — 0 Schubkästen bei bekannter Länge ist `.none`.
    public static func classify(drawerCount: Int, lengthM: Double?) -> KitchenEquipmentDensity {
        guard let lengthM, lengthM > 0 else { return .unknown }
        return classify(drawersPerLfm: Double(drawerCount) / lengthM)
    }

    /// ANFRAGE-Seite (Freitext): „kein Schubkasten genannt" = unbekannt, nicht null.
    public static func classifyQuery(drawerCount: Int, lengthM: Double?) -> KitchenEquipmentDensity {
        guard drawerCount > 0, let lengthM, lengthM > 0 else { return .unknown }
        return classify(drawersPerLfm: Double(drawerCount) / lengthM)
    }

    /// Hart unvereinbar, wenn BEIDE Dichten bekannt sind und mindestens zwei Stufen
    /// auseinanderliegen (z. B. low ↔ high, none ↔ medium, low ↔ very_high). Benachbarte
    /// Stufen (low ↔ medium) bleiben kompatibel — ein ehrlich breites Band statt
    /// Scheinpräzision. Ist eine Seite `unknown`, wird NIE ausgeschlossen.
    public func isHardIncompatible(with other: KitchenEquipmentDensity) -> Bool {
        guard let selfLevel = level, let otherLevel = other.level else { return false }
        return abs(selfLevel - otherLevel) >= 2
    }
}

/// Minimale Scope-Signatur einer Küchenzeile für das dichtebewusste Matching.
/// Bewusst schlank: nur, was der Estimator zum Ausschluss/Bonus braucht.
public struct KitchenScopeSignature: Equatable, Codable, Sendable {
    public let equipmentDensity: KitchenEquipmentDensity
    public let drawerCount: Int
    public let lengthM: Double?

    public init(equipmentDensity: KitchenEquipmentDensity, drawerCount: Int, lengthM: Double?) {
        self.equipmentDensity = equipmentDensity
        self.drawerCount = drawerCount
        self.lengthM = lengthM
    }

    /// Aus einer geparsten Anfrage-Komponente (Freitext-Seite).
    public static func fromQuery(drawerCount: Int, lengthM: Double?) -> KitchenScopeSignature {
        KitchenScopeSignature(
            equipmentDensity: .classifyQuery(drawerCount: drawerCount, lengthM: lengthM),
            drawerCount: drawerCount,
            lengthM: lengthM
        )
    }
}
