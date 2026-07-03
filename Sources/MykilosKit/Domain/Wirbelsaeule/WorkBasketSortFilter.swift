import Foundation

// MARK: - WorkBasket: Sortieren/Filtern (Welle C, Schritt C3)
//
// Reine, testbare Funktionen auf `[WorkBasket]`/`[any Pick]` — keine Persistenz,
// kein I/O. S10-Blueprint §3/§9 „WorkBasket-Ausbau … Sortieren/Filtern". Eigene
// Datei statt Ergänzung in `WirbelsaeuleFoundation.swift`, damit das C1-Fundament
// unverändert schlank bleibt (Token-Disziplin: 400-Zeilen-Richtwert).
//
// Generisch über die C1-Felder (`inhaltsArt`, `projektNummer`, `status`,
// `erstellt`, `matrix`) — kein Artikel-only-Hardwiring.

/// Sortierschlüssel für WorkBasket-Listen (Warenkorb-Übersicht, C3 §9 „Sortieren").
public enum WorkBasketSortKey: Sendable {
    /// Neueste zuerst (Standard).
    case erstelltAbsteigend
    /// Älteste zuerst.
    case erstelltAufsteigend
    /// Höchste Version zuerst.
    case versionAbsteigend
    /// Nach Projektnummer, alphabetisch.
    case projektNummer
}

extension Array where Element == WorkBasket {
    /// Sortiert eine WorkBasket-Liste nach dem gegebenen Schlüssel. Reine Funktion.
    public func sortiert(nach key: WorkBasketSortKey) -> [WorkBasket] {
        switch key {
        case .erstelltAbsteigend:
            return sorted { $0.erstellt > $1.erstellt }
        case .erstelltAufsteigend:
            return sorted { $0.erstellt < $1.erstellt }
        case .versionAbsteigend:
            return sorted { $0.version > $1.version }
        case .projektNummer:
            return sorted { $0.projektNummer < $1.projektNummer }
        }
    }

    /// Filtert nach Inhalts-Art. `nil` = keine Einschränkung (alle Arten).
    public func gefiltert(nachInhaltsArt inhaltsArt: InhaltsArt?) -> [WorkBasket] {
        guard let inhaltsArt else { return self }
        return filter { $0.inhaltsArt == inhaltsArt }
    }

    /// Filtert nach Projektnummer. `nil`/leer = keine Einschränkung.
    public func gefiltert(nachProjekt projektNummer: String?) -> [WorkBasket] {
        guard let projektNummer, !projektNummer.isEmpty else { return self }
        return filter { $0.projektNummer == projektNummer }
    }

    /// Filtert nach Lebenszyklus-Status (§7). `nil` = keine Einschränkung.
    /// Vergleicht nur den Fall (kalkulation/bestaetigt/nachtrag/gutschrift), nicht
    /// die assoziierte Eltern-ID — praktisch für „alle Nachträge" unabhängig vom Elternkorb.
    public func gefiltert(nachStatusFall wunsch: WorkBasketStatus?) -> [WorkBasket] {
        guard let wunsch else { return self }
        return filter { $0.status.istGleicherFall(wunsch) }
    }
}

extension WorkBasketStatus {
    /// Vergleicht nur den Enum-Fall, ignoriert die assoziierte Eltern-`WorkBasketID`
    /// bei `.nachtrag`/`.gutschrift`. Nützlich für Filter-UI („zeig mir alle Nachträge").
    public func istGleicherFall(_ other: WorkBasketStatus) -> Bool {
        switch (self, other) {
        case (.kalkulation, .kalkulation),
             (.bestaetigt, .bestaetigt),
             (.nachtrag, .nachtrag),
             (.gutschrift, .gutschrift):
            return true
        default:
            return false
        }
    }
}

extension Array where Element == any Pick {
    /// Sortiert Picks nach Bezeichnung (alphabetisch) — reine Funktion auf Snapshots.
    public func sortiertNachBezeichnung() -> [any Pick] {
        sorted { $0.snapshot.bezeichnung < $1.snapshot.bezeichnung }
    }

    /// Filtert Picks nach Quell-Matrix. `nil` = keine Einschränkung.
    public func gefiltert(nachMatrix matrix: CatalogMatrix?) -> [any Pick] {
        guard let matrix else { return self }
        return filter { $0.matrix == matrix }
    }
}
