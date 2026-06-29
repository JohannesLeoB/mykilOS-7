import Foundation
import MykilosKalkulationsCore

// MARK: - ScopeSignatureCatalog (feat/tischler-predictor · Phase 2)
//
// Liest die VORBERECHNETEN Ausstattungsgrade aus dem zwei-KI-verifizierten Korpus
// (`EstimationCore_v1_BRANDLESS_verifiziert/exports/normalized_anchor_scope_signatures.csv`)
// und stellt sie als `candidate_id → KitchenEquipmentDensity`-Nachschlag bereit.
//
// Bewusst NICHT die Preisquelle: die Preise/Backtest-Disziplin bleiben bei
// `active_price_anchors.csv` (unverändert, 201/201 identisch). Diese Datei trägt
// AUSSCHLIESSLICH den Verlässlichkeits-Parameter (Dichte) nach. Fehlt sie oder
// fehlt eine candidate_id, bleibt der Anker `.unknown` → Matching wie zuvor.
//
// Datenschutz: liegt im gelben _Daten-Ordner (lokal), NIE ins Repo gebündelt.
public struct ScopeSignatureCatalog {
    private let densityByCandidate: [String: KitchenEquipmentDensity]

    public init(densityByCandidate: [String: KitchenEquipmentDensity]) {
        self.densityByCandidate = densityByCandidate
    }

    public var count: Int { densityByCandidate.count }

    public func density(for candidateID: String) -> KitchenEquipmentDensity {
        densityByCandidate[candidateID] ?? .unknown
    }

    /// Reichert eine Anker-Liste an: jeder Anker bekommt seinen vorberechneten
    /// Ausstattungsgrad (oder bleibt `.unknown`). Preise/IDs bleiben unberührt.
    public func enrich(_ anchors: [CandidateReleaseDecision]) -> [CandidateReleaseDecision] {
        guard densityByCandidate.isEmpty == false else { return anchors }
        return anchors.map { anchor in
            let density = density(for: anchor.candidateID)
            return density == .unknown ? anchor : anchor.withEquipmentDensity(density)
        }
    }

    /// Standardpfad neben dem Brain-Korpus (gelber Mac-Ordner). Leer, wenn die
    /// verifizierte Export-CSV fehlt — der Provider degradiert dann still.
    public static var defaultURL: URL {
        URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Claude/Projects/mykilOS/MYKILOS 6/_Daten/Kalkulation/EstimationCore_v1_BRANDLESS_verifiziert/exports/normalized_anchor_scope_signatures.csv")
    }

    /// Lädt den Katalog aus einer CSV. Fehlende Datei/leere Spalte → leerer Katalog
    /// (kein Wurf: das Fehlen des Verlässlichkeits-Parameters ist kein Fehlerzustand,
    /// nur eine breitere Schätzung).
    public static func load(from url: URL = defaultURL) -> ScopeSignatureCatalog {
        guard let raw = try? String(contentsOf: url, encoding: .utf8),
              let table = try? CSVTable(data: raw, lenient: true) else {
            return ScopeSignatureCatalog(densityByCandidate: [:])
        }
        var map: [String: KitchenEquipmentDensity] = [:]
        for row in table.rows {
            let id = row.string("candidate_id")
            guard id.isEmpty == false else { continue }
            let density = KitchenEquipmentDensity(rawCorpus: row.string("equipment_density"))
            guard density != .unknown else { continue }
            map[id] = density
        }
        return ScopeSignatureCatalog(densityByCandidate: map)
    }
}
