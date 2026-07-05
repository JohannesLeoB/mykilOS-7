import Foundation

// MARK: - WarenkorbWorkBasketBridge (V10-Plan, Phase 1, Block D)
//
// `Warenkorb` (MykilosKit/Domain/Warenkorb.swift, Intake/Airtable-Domäne) und `WorkBasket`
// (MykilosKit/Domain/Wirbelsaeule/WirbelsaeuleFoundation.swift, Wirbelsäule/GRDB) sind ZWEI
// verschiedene Structs — das war der verifizierte Knackpunkt im V10-Plan. Diese Datei ist
// die explizite, kleine, testbare Naht dazwischen: Foundation-only, keine Airtable-/GRDB-
// Importe, passend zum Architektur-Rail „Foundation-only-Logik gehört nach MykilosKit".
//
// Regeln (V10-Plan, Block D):
// · KEIN Fuzzy-Match — `projektNummer` wird immer vom Aufrufer übergeben, nie geraten.
// · Status ist immer `.kalkulation` — die Bridge kennt keinen anderen Fall (der Happy Path,
//   siehe „Was V10 bewusst NICHT ist": keine Nachtrag-/Gutschrift-Zweige hier).
// · `inhaltsArt` ist immer `.artikel` — der Intake-Warenkorb trägt ausschließlich
//   Artikelpositionen (`WarenkorbItem`), keine gemischten Matrizen.
public enum WarenkorbWorkBasketBridge {

    /// Baut einen `WorkBasket` aus einem Intake-`Warenkorb`.
    ///
    /// - Parameters:
    ///   - warenkorb: die Intake-Positionen (Airtable-Domäne, `MykilosKit/Domain/Warenkorb.swift`).
    ///   - projektNummer: App-Format `JJJJ-NR` (Pflichtfeld, nie abgeleitet/geraten — der
    ///     Aufrufer muss die bereits aufgelöste, echte Projektnummer übergeben).
    ///   - id: die `WorkBasketID` des neuen Korbs (Aufrufer entscheidet über Vergabe/Version,
    ///     siehe `WorkBasketStore.speichere` — "eine neue ID/Version entsteht beim Aufrufer").
    ///   - erstellt: Erstellzeitpunkt, default `Date()` (injizierbar für deterministische Tests).
    public static func workBasket(
        aus warenkorb: Warenkorb,
        projektNummer: String,
        id: WorkBasketID,
        erstellt: Date = Date()
    ) -> WorkBasket {
        let picks: [any Pick] = warenkorb.items.map { item in
            BasicPick(
                matrix: .artikel,
                objektID: CatalogObjectID(objektID(fuer: item)),
                snapshot: PickSnapshot(
                    bezeichnung: item.bezeichnung,
                    menge: item.menge,
                    ekEinzel: item.ekNetto,
                    vkEinzel: item.vkNetto,
                    attribute: attribute(fuer: item)
                ),
                inhalt: .text(item.artikelnummer)
            )
        }
        return WorkBasket(
            id: id,
            projektNummer: projektNummer,
            inhaltsArt: .artikel,
            picks: picks,
            version: 1,
            status: .kalkulation,
            erstellt: erstellt
        )
    }

    /// Stabile Katalog-Objekt-ID: bevorzugt die echte Airtable-Record-ID des Artikels
    /// (Rückverfolgbarkeits-Leitlinie, §2/§10 der Wirbelsäule), fällt sonst auf die
    /// Artikelnummer zurück — nie eine neue, zufällige ID erfinden.
    private static func objektID(fuer item: WarenkorbItem) -> String {
        if let artikelRecordID = item.artikelRecordID, artikelRecordID.isEmpty == false {
            return artikelRecordID
        }
        return item.artikelnummer
    }

    private static func attribute(fuer item: WarenkorbItem) -> [String: String] {
        // Volle Daten-Fidelität: die freien Zusatzfelder des Items (Originaltext, Seite,
        // Richtung, Konfidenz, Quell-PDF … bei aus einem Angebot herausgelösten Positionen)
        // wandern mit in den PickSnapshot. `quelle`/`artikelnummer` überschreiben bewusst,
        // damit sie kanonisch aus den strukturierten Feldern stammen.
        var attribute = item.attribute
        attribute["quelle"] = item.quelle
        if item.artikelnummer.isEmpty == false {
            attribute["artikelnummer"] = item.artikelnummer
        }
        return attribute
    }
}
