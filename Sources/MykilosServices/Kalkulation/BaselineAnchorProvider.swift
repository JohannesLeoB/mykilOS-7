import Foundation
import MykilosKalkulationsCore

// MARK: - BaselineAnchorProvider
// Liefert die hartcodierten Baseline-Anker (Foundation-only, keine externen
// Seed-Dateien). Macht `schaetze` schon ohne den großen Korpus funktional —
// konservative Regelanker statt leerer Schätzung. Wird später durch den echten
// Seed-Provider (BrainSeedRepository, destillierte Anker) ergänzt/ersetzt.
public struct BaselineAnchorProvider: PriceAnchorProviding {
    public init() {}

    public func activeAnchors() throws -> [CandidateReleaseDecision] {
        BaselineAnchors.all()
    }
}
