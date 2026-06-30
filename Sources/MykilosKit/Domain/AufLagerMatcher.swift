import Foundation

// MARK: - LagerTreffer
// Strukturiertes Matching-Ergebnis: ein Lager-Artikel mit Bestand und Trefftyp.
public struct LagerTreffer: Sendable, Equatable {
    /// Lagerartikel, der zutrifft.
    public let lagerItem: LagerItem
    /// Art des Treffers.
    public let trefftyp: LagerTrefftyp
    /// Aktueller Lagerbestand (aus LagerItem.bestand, kann nil sein).
    public var bestand: Int? { lagerItem.bestand }

    public init(lagerItem: LagerItem, trefftyp: LagerTrefftyp) {
        self.lagerItem = lagerItem
        self.trefftyp = trefftyp
    }
}

// MARK: - LagerTrefftyp
public enum LagerTrefftyp: Sendable, Equatable, CaseIterable {
    /// Exakter Treffer: normalisierte Artikelnummer stimmt überein.
    case exakt
    /// Ähnlichkeitstreffer: gleicher Hersteller + Token-Overlap der Bezeichnung ≥ 1.
    case aehnlich
}

// MARK: - AufLagerMatcherResult
// Kombiniertes Ergebnis für einen Suchartikel.
public struct AufLagerMatcherResult: Sendable, Equatable {
    /// Exakte Treffer (normalisierte Artikelnummer stimmt überein).
    public let exakt: [LagerTreffer]
    /// Ähnliche Treffer (gleicher Hersteller + Token-Overlap ≥ 1, nicht bereits exakt).
    public let aehnlich: [LagerTreffer]

    /// Alle Treffer: erst exakt, dann ähnlich.
    public var alle: [LagerTreffer] { exakt + aehnlich }
    /// true, wenn mindestens ein Treffer vorhanden.
    public var hatTreffer: Bool { !exakt.isEmpty || !aehnlich.isEmpty }

    public init(exakt: [LagerTreffer], aehnlich: [LagerTreffer]) {
        self.exakt = exakt
        self.aehnlich = aehnlich
    }
}

// MARK: - AufLagerMatcher
// Reine Funktionen (kein Netzwerk, kein State) für das Matching eines ArtikelItem
// gegen eine Lagerliste. Konservativ: lieber keine als falsche Treffer.
//
// Matching-Regeln:
//   Exakt:    normalisierte Artikelnummer (Großbuchstaben, nur [A-Z0-9]) stimmt überein.
//             Leere Artikelnummern → kein Treffer.
//   Ähnlich:  Hersteller stimmt überein (Groß-/Kleinschreibung ignoriert, trimmend)
//             UND mindestens 1 gemeinsamer Token (≥ 2 Zeichen) in Artikelbezeichnung
//             UND nicht bereits exakter Treffer.
public enum AufLagerMatcher {

    // MARK: - Haupt-API

    /// Zu einem ArtikelItem alle Lager-Treffer finden.
    /// - Parameters:
    ///   - artikel: Der zu suchende Artikel.
    ///   - lagerliste: Die vollständige Lagerliste (151 Einträge in Prod).
    /// - Returns: Strukturiertes `AufLagerMatcherResult`.
    public static func suche(
        artikel: ArtikelItem,
        in lagerliste: [LagerItem]
    ) -> AufLagerMatcherResult {
        let normArtikel = LagerItem.normalisiereArtikelnummer(artikel.artikelnummer)
        let artikelHersteller = artikel.hersteller?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
        let artikelTokens = Set(ArtikelItem.tokenize(artikel.artikelbeschreibung ?? artikel.artikelnummer))

        var exaktTreffer: [LagerTreffer] = []
        var aehnlichTreffer: [LagerTreffer] = []

        for lager in lagerliste {
            let normLager = lager.normalisierteArtikelnummer

            // Exakter Treffer: normalisierte Artikelnummer muss nicht-leer und gleich sein
            if !normArtikel.isEmpty && !normLager.isEmpty && normArtikel == normLager {
                exaktTreffer.append(LagerTreffer(lagerItem: lager, trefftyp: .exakt))
                continue
            }

            // Ähnlichkeit: gleicher Hersteller + Token-Overlap ≥ 1
            // Nur wenn Hersteller auf beiden Seiten vorhanden
            if !artikelHersteller.isEmpty,
               let lagerHersteller = lager.hersteller?.trimmingCharacters(in: .whitespaces).lowercased(),
               !lagerHersteller.isEmpty,
               artikelHersteller == lagerHersteller {
                // Token-Overlap der Bezeichnung
                let lagerTokens = Set(ArtikelItem.tokenize(lager.bezeichnung))
                if !artikelTokens.isDisjoint(with: lagerTokens) {
                    aehnlichTreffer.append(LagerTreffer(lagerItem: lager, trefftyp: .aehnlich))
                }
            }
        }

        return AufLagerMatcherResult(exakt: exaktTreffer, aehnlich: aehnlichTreffer)
    }

    // MARK: - Batch-Suche

    /// Sucht mehrere Artikel auf einen Schlag gegen dieselbe Lagerliste.
    /// Gibt ein Dictionary ArtikelItem.id → AufLagerMatcherResult zurück.
    public static func sucheBatch(
        artikel: [ArtikelItem],
        in lagerliste: [LagerItem]
    ) -> [String: AufLagerMatcherResult] {
        var result: [String: AufLagerMatcherResult] = [:]
        for a in artikel {
            result[a.id] = suche(artikel: a, in: lagerliste)
        }
        return result
    }

    // MARK: - Normalisierungs-Hilfsmethode (wiederverwendbar, pure)

    /// Normalisiert Herstellernamen für den Vergleich.
    /// Führende/nachfolgende Leerzeichen entfernen, Kleinbuchstaben.
    public static func normalisiereHersteller(_ h: String) -> String {
        h.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
