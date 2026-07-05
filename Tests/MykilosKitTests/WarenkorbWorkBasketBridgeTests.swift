import Testing
import Foundation
@testable import MykilosKit

// MARK: - WarenkorbWorkBasketBridgeTests (V10-Plan, Phase 1, Block D)
// Beweist die Naht zwischen der Intake-`Warenkorb`-Domäne (Airtable) und `WorkBasket`
// (Wirbelsäule/GRDB): Positionen→Picks korrekt, Summen erhalten, projektNummer sauber
// durchgereicht (kein Fuzzy-Match), leerer Korb, Schneider-artige Testdaten.
struct WarenkorbWorkBasketBridgeTests {

    // MARK: 1. Leerer Korb → leerer WorkBasket, keine Picks, Projektnummer trotzdem exakt gesetzt

    @Test func leererWarenkorbErgibtLeerenWorkBasketMitExakterProjektnummer() {
        let leer = Warenkorb(items: [])
        let basket = WarenkorbWorkBasketBridge.workBasket(
            aus: leer, projektNummer: "2026-015", id: WorkBasketID("WK-2026-015-leer"))

        #expect(basket.picks.isEmpty)
        #expect(basket.projektNummer == "2026-015")
        #expect(basket.inhaltsArt == .artikel)
        #expect(basket.status == .kalkulation)
        #expect(basket.version == 1)
    }

    // MARK: 2. Positionen → Picks: Bezeichnung/Menge/Preise/Attribute korrekt übertragen

    @Test func positionenWerdenKorrektZuPicksGemappt() async throws {
        let items = [
            WarenkorbItem(
                artikelRecordID: "rec123",
                bezeichnung: "Spüle Blanco Subline 500-U",
                artikelnummer: "BLA-500U",
                menge: 1,
                ekNetto: 420.0,
                vkNetto: 690.0,
                quelle: "katalog"),
            WarenkorbItem(
                bezeichnung: "Montage vor Ort",
                artikelnummer: "MONT-01",
                menge: 3,
                ekNetto: nil,
                vkNetto: 95.0,
                quelle: "manuell"),
        ]
        let warenkorb = Warenkorb(items: items, projektRecordID: "recProjekt", projektName: "Küche Schneider")
        let basket = WarenkorbWorkBasketBridge.workBasket(
            aus: warenkorb, projektNummer: "2026-015", id: WorkBasketID("WK-2026-015-0001"))

        #expect(basket.picks.count == 2)

        let erste = basket.picks[0]
        #expect(erste.matrix == .artikel)
        // Bevorzugt die echte Airtable-Record-ID als stabile CatalogObjectID.
        #expect(erste.objektID == CatalogObjectID("rec123"))
        #expect(erste.snapshot.bezeichnung == "Spüle Blanco Subline 500-U")
        #expect(erste.snapshot.menge == 1)
        #expect(erste.snapshot.ekEinzel == 420.0)
        #expect(erste.snapshot.vkEinzel == 690.0)
        #expect(erste.snapshot.attribute["quelle"] == "katalog")
        #expect(erste.snapshot.attribute["artikelnummer"] == "BLA-500U")
        let ersterInhalt = try await erste.resolve()
        #expect(ersterInhalt == .text("BLA-500U"))

        let zweite = basket.picks[1]
        // Ohne artikelRecordID: Fallback auf die Artikelnummer als CatalogObjectID.
        #expect(zweite.objektID == CatalogObjectID("MONT-01"))
        #expect(zweite.snapshot.menge == 3)
        #expect(zweite.snapshot.ekEinzel == nil)
        #expect(zweite.snapshot.vkEinzel == 95.0)
        #expect(zweite.snapshot.attribute["quelle"] == "manuell")
    }

    // MARK: 3. projektNummer wird nie geraten — exakt der übergebene Wert, unabhängig vom Warenkorb-Inhalt

    @Test func projektNummerWirdExaktDurchgereichtNieAbgeleitet() {
        let warenkorb = Warenkorb(
            items: [WarenkorbItem(bezeichnung: "X", artikelnummer: "X-1", menge: 1, quelle: "manuell")],
            projektRecordID: "recAnderesProjekt",
            projektName: "Ein völlig anderer Name")
        let basket = WarenkorbWorkBasketBridge.workBasket(
            aus: warenkorb, projektNummer: "2026-099", id: WorkBasketID("WK-2026-099-0001"))

        // Die App-Projektnummer kommt ausschließlich aus dem expliziten Parameter —
        // nicht aus projektRecordID/projektName des Warenkorbs (kein Fuzzy-Match).
        #expect(basket.projektNummer == "2026-099")
    }

    // MARK: 4. Summen bleiben erhalten (Menge × Preis je Position, wie in Warenkorb.gesamtEKNetto/gesamtVKNetto)

    @Test func summenBleibenUeberDieBridgeErhalten() {
        let items = [
            WarenkorbItem(bezeichnung: "A", artikelnummer: "A-1", menge: 2, ekNetto: 100.0, vkNetto: 150.0, quelle: "katalog"),
            WarenkorbItem(bezeichnung: "B", artikelnummer: "B-1", menge: 1, ekNetto: 50.0, vkNetto: 80.0, quelle: "manuell"),
        ]
        let warenkorb = Warenkorb(items: items)
        #expect(warenkorb.gesamtEKNetto == 250.0)   // 2*100 + 1*50
        #expect(warenkorb.gesamtVKNetto == 380.0)   // 2*150 + 1*80

        let basket = WarenkorbWorkBasketBridge.workBasket(
            aus: warenkorb, projektNummer: "2026-015", id: WorkBasketID("WK-2026-015-summen"))

        let ekSumme = basket.picks.reduce(0.0) { sum, pick in
            sum + (pick.snapshot.ekEinzel ?? 0) * Double(pick.snapshot.menge)
        }
        let vkSumme = basket.picks.reduce(0.0) { sum, pick in
            sum + (pick.snapshot.vkEinzel ?? 0) * Double(pick.snapshot.menge)
        }
        #expect(ekSumme == warenkorb.gesamtEKNetto)
        #expect(vkSumme == warenkorb.gesamtVKNetto)
    }

    // MARK: 5. Schneider-artige Testdaten (V10-Plan: der eine echte Auftrag, der durchläuft)

    @Test func schneiderArtigerWarenkorbWirdVollstaendigGemappt() {
        let schneiderPositionen = [
            WarenkorbItem(
                artikelRecordID: "recSpuele01",
                bezeichnung: "Spüle Schock Typos D-150S",
                artikelnummer: "SCH-TYPOS-D150S",
                menge: 1, ekNetto: 380.0, vkNetto: 620.0, quelle: "katalog"),
            WarenkorbItem(
                artikelRecordID: "recArmatur01",
                bezeichnung: "Küchenarmatur Blanco Linus-S",
                artikelnummer: "BLA-LINUS-S",
                menge: 1, ekNetto: 210.0, vkNetto: 349.0, quelle: "katalog"),
            WarenkorbItem(
                bezeichnung: "Elektroanschluss Herd + Spüle",
                artikelnummer: "MONT-ELEK-01",
                menge: 1, ekNetto: nil, vkNetto: 180.0, quelle: "manuell"),
        ]
        let warenkorb = Warenkorb(
            items: schneiderPositionen, projektRecordID: "recSchneider", projektName: "Küche Schneider")
        let basket = WarenkorbWorkBasketBridge.workBasket(
            aus: warenkorb, projektNummer: "2026-015", id: WorkBasketID("WK-2026-015-schneider"))

        #expect(basket.picks.count == 3)
        #expect(basket.projektNummer == "2026-015")
        #expect(basket.status == .kalkulation)
        #expect(basket.inhaltsArt == .artikel)
        #expect(Set(basket.picks.map(\.matrix)) == [.artikel])
        #expect(basket.picks.map(\.snapshot.bezeichnung) == [
            "Spüle Schock Typos D-150S",
            "Küchenarmatur Blanco Linus-S",
            "Elektroanschluss Herd + Spüle",
        ])
    }

    // MARK: 6. Volle Daten-Fidelität: freie `attribute`-Felder wandern über die Bridge mit
    // (Bugfix 2026-07-05 — herausgelöste PDF-Positionen tragen Originaltext/Seite/Status usw.)

    @Test func freieAttributeWandernUeberDieBridgeInDenPickSnapshot() {
        let item = WarenkorbItem(
            bezeichnung: "Grifflose Front", artikelnummer: "ART-42",
            menge: 3, ekNetto: 42.0, quelle: "angebot-eingehend",
            attribute: [
                "originalText": "3 Stk Grifflose Front 42,00 = 126,00",
                "seite": "2", "richtung": "eingehend", "kategorie": "Front",
                "status": "green", "gesamtpreisNetto": "126", "listenpreis": "50",
            ])
        let basket = WarenkorbWorkBasketBridge.workBasket(
            aus: Warenkorb(items: [item]), projektNummer: "2026-015", id: WorkBasketID("WK-attr"))
        let attr = basket.picks[0].snapshot.attribute
        #expect(attr["originalText"] == "3 Stk Grifflose Front 42,00 = 126,00")
        #expect(attr["seite"] == "2")
        #expect(attr["kategorie"] == "Front")
        #expect(attr["status"] == "green")
        #expect(attr["gesamtpreisNetto"] == "126")
        #expect(attr["listenpreis"] == "50")
        // quelle/artikelnummer kanonisch aus den strukturierten Feldern.
        #expect(attr["quelle"] == "angebot-eingehend")
        #expect(attr["artikelnummer"] == "ART-42")
    }

    // MARK: 7. Cold-Start-Toleranz: altes WarenkorbItem-JSON OHNE `attribute` bleibt lesbar
    // (EISERN „Assistent-Gedächtnis = Codable": neues Nicht-Optional-Feld darf alte Daten
    // nicht unlesbar machen — decodeIfPresent ?? [:]).

    @Test func altesWarenkorbItemOhneAttributeDekodiertZuLeeremDict() throws {
        let altesJSON = """
        {"bezeichnung":"Spüle","artikelnummer":"SPL-001","menge":2,"quelle":"katalog","ekNetto":100.0}
        """.data(using: .utf8)!
        let item = try JSONDecoder().decode(WarenkorbItem.self, from: altesJSON)
        #expect(item.bezeichnung == "Spüle")
        #expect(item.menge == 2)
        #expect(item.ekNetto == 100.0)
        #expect(item.attribute.isEmpty)   // fehlendes Feld → leeres Dict, kein Decode-Fehler
    }

    @Test func warenkorbItemMitAttributeRoundtrippt() throws {
        let original = WarenkorbItem(
            bezeichnung: "Front", artikelnummer: "F-1", menge: 1, quelle: "angebot-eingehend",
            attribute: ["seite": "3", "status": "amber"])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WarenkorbItem.self, from: data)
        #expect(decoded == original)
        #expect(decoded.attribute["seite"] == "3")
        #expect(decoded.attribute["status"] == "amber")
    }
}
