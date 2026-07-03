import Foundation

// MARK: - WorkBasketEditing (V10-Plan, Phase 1, Block E)
//
// Reine, testbare Foundation-Logik für das Korrigieren eines persistierten
// `WorkBasket` in der Projekt-UI (WarenkorbWidget/-Panel). Gehört nach MykilosKit
// (Foundation-only, kein SwiftUI/GRDB), damit die Editier-Regeln unit-testbar
// bleiben und nicht in einer View verstreut liegen.
//
// Regeln (V10-Plan, Block E + `warenkorb-lebenszyklus`):
// · Nur `.kalkulation`-Körbe sind editierbar. Eingefrorene Körbe
//   (`WorkBasketStatus.istEingefroren`) werden unverändert zurückgegeben — die
//   append-only Kette (Nachtrag/Gutschrift) läuft NICHT über diese Naht.
// · Editieren ersetzt eine Position durch einen neuen `BasicPick` mit
//   angepasstem `PickSnapshot`; `matrix`, `objektID` und der bereits aufgelöste
//   Inhalt (`BasicPick.inhalt`) bleiben erhalten → Rückverfolgbarkeit intakt.
//   Positionen, die aus dem `WorkBasketStore` geladen wurden, sind stets
//   `BasicPick` (siehe `WorkBasketPickRecord.toDomain`), ihr Inhalt bleibt also
//   verlustfrei; für andere `Pick`-Typen fällt der Inhalt konservativ auf
//   `.keiner` zurück (kein Raten).
public enum WorkBasketEditing {

    /// Ändert Menge und/oder VK-Einzelpreis einer Position (per Index). Alle
    /// anderen Positionen bleiben unverändert. Gibt einen NEUEN `WorkBasket`
    /// zurück (gleiche `id`/`version` — der Aufrufer persistiert ihn via
    /// `WorkBasketStore.speichere`, das überschreibt in-place).
    ///
    /// - Parameters:
    ///   - basket: der zu bearbeitende Korb.
    ///   - index: 0-basierter Positionsindex. Ungültige Indizes → Korb unverändert.
    ///   - menge: neue Menge (>= 0), oder `nil` = unverändert. Negative Werte werden auf 0 geklemmt.
    ///   - vkEinzel: neuer VK-Netto-Einzelpreis, oder `nil` = unverändert.
    /// - Returns: bearbeiteter Korb; unverändert, wenn `basket.status.istEingefroren`.
    public static func aktualisierePosition(
        _ basket: WorkBasket,
        anIndex index: Int,
        menge: Int? = nil,
        vkEinzel: Double? = nil
    ) -> WorkBasket {
        guard basket.status.istEingefroren == false else { return basket }
        guard basket.picks.indices.contains(index) else { return basket }

        var picks = basket.picks
        let alt = picks[index]
        let s = alt.snapshot
        let neuSnapshot = PickSnapshot(
            bezeichnung: s.bezeichnung,
            menge: menge.map { max(0, $0) } ?? s.menge,
            ekEinzel: s.ekEinzel,
            vkEinzel: vkEinzel ?? s.vkEinzel,
            attribute: s.attribute
        )
        picks[index] = BasicPick(
            matrix: alt.matrix,
            objektID: alt.objektID,
            snapshot: neuSnapshot,
            inhalt: (alt as? BasicPick)?.inhalt ?? .keiner
        )
        var neu = basket
        neu.picks = picks
        return neu
    }

    /// Entfernt eine Position (per Index). Gibt einen NEUEN `WorkBasket` zurück.
    /// Ungültige Indizes oder eingefrorene Körbe → Korb unverändert.
    public static func entfernePosition(_ basket: WorkBasket, anIndex index: Int) -> WorkBasket {
        guard basket.status.istEingefroren == false else { return basket }
        guard basket.picks.indices.contains(index) else { return basket }
        var neu = basket
        neu.picks.remove(at: index)
        return neu
    }
}
