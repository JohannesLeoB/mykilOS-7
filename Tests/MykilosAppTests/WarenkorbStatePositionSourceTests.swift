import Testing
import Foundation
@testable import MykilosApp
@testable import MykilosKit

// MARK: - WarenkorbStatePositionSourceTests
// Deckt die Task-A-Generalisierung ab: WarenkorbState.Position.source war bisher nur
// "katalog"/"lager", akzeptiert jetzt zusätzlich "angebot-eingehend"/"angebot-ausgehend"
// über addAngebot(...) — ohne die bestehenden Artikel-/Lager-Pfade zu verändern.
@MainActor
struct WarenkorbStatePositionSourceTests {

    @Test func bestehendeKatalogQuelleBleibtUnveraendert() {
        let state = WarenkorbState()
        let artikel = ArtikelItem(
            id: "rec1", artikelnummer: "ART-001",
            hersteller: "Blum", kategorie: "Beschläge", artikelbeschreibung: "Testartikel",
            ekNetto: 4.5, vkNetto: 9.9,
            produktbildURL: nil
        )
        state.addArtikel(artikel)
        #expect(state.positionen.count == 1)
        #expect(state.positionen[0].source == "katalog")
    }

    @Test func bestehendeLagerQuelleBleibtUnveraendert() {
        let state = WarenkorbState()
        let item = LagerItem(
            id: "lager1", bezeichnung: "Scharnier", kategorie: nil, hersteller: nil,
            artikelnummer: nil, bestand: 12, ekNetto: nil, vkNetto: nil, quelle: nil
        )
        state.addLagerItem(item)
        #expect(state.positionen.count == 1)
        #expect(state.positionen[0].source == "lager")
    }

    @Test func angebotEingehendLegtNeueQuelleAn() {
        let state = WarenkorbState()
        state.addAngebot(fileID: "file123", bezeichnung: "Arbeitsplatte Eiche.pdf",
                          belegNummer: "AN-2026-0099", eingehend: true)
        #expect(state.positionen.count == 1)
        #expect(state.positionen[0].source == "angebot-eingehend")
        #expect(state.positionen[0].artikelnummer == "AN-2026-0099")
        #expect(state.positionen[0].ekNetto == nil)
        #expect(state.positionen[0].vkNetto == nil)
    }

    @Test func angebotAusgehendLegtNeueQuelleAn() {
        let state = WarenkorbState()
        state.addAngebot(fileID: "file456", bezeichnung: "Angebot Schmidt.pdf",
                          belegNummer: nil, eingehend: false)
        #expect(state.positionen.count == 1)
        #expect(state.positionen[0].source == "angebot-ausgehend")
        // Ohne Belegnummer fällt die Artikelnummer auf die fileID zurück (keine erfundenen Werte).
        #expect(state.positionen[0].artikelnummer == "file456")
    }

    @Test func gleichesAngebotErhoehtMengeStattDuplikat() {
        let state = WarenkorbState()
        state.addAngebot(fileID: "file789", bezeichnung: "Kostenvoranschlag.pdf",
                          belegNummer: "KV-1", eingehend: true)
        state.addAngebot(fileID: "file789", bezeichnung: "Kostenvoranschlag.pdf",
                          belegNummer: "KV-1", eingehend: true)
        #expect(state.positionen.count == 1)
        #expect(state.positionen[0].menge == 2)
    }

    // MARK: - Positionen-Picker → Warenkorb (Bugfix 2026-07-05)
    //
    // Der Klick auf „In Warenkorb" im Positionen-Picker (PDF-Positions v1) landet über
    // `addPosition(...)` im SELBEN WarenkorbState, den das WarenkorbPanel dieser Ansicht
    // zeigt. Vorher schrieb der Picker in den projektgebundenen WorkBasketStore — das
    // sichtbare Panel blieb bei „0 Pos." (zwei getrennte Korb-Instanzen).

    @Test func pickerPositionLandetImWarenkorbUndZaehlerSteigt() {
        let state = WarenkorbState()
        #expect(state.istLeer)
        #expect(state.anzahl == 0)

        state.addPosition(
            objektID: "fileZ-2-0",
            bezeichnung: "Grifflose Front",
            menge: 3,
            preisNetto: 42.0,
            eingehend: true,
            attribute: ["seite": "2", "richtung": "eingehend"])

        #expect(state.positionen.count == 1)
        #expect(state.istLeer == false)
        #expect(state.anzahl == 3)                       // Zähler = Summe der Mengen
        #expect(state.positionen[0].source == "angebot-eingehend")
        #expect(state.positionen[0].ekNetto == 42.0)     // eingehend → EK, nicht VK
        #expect(state.positionen[0].vkNetto == nil)
    }

    @Test func pickerPositionTraegtVolleDatenBisInDenCheckout() {
        let state = WarenkorbState()
        // Vollständiges Attribut-Set wie der echte positionsAttribute-Helper es liefert.
        let attribute: [String: String] = [
            "originalText": "3 Stk Grifflose Front 42,00 = 126,00",
            "quelle": "Angebot Schmidt.pdf",
            "seite": "2",
            "richtung": "eingehend",
            "kategorie": "Front",
            "status": "green",
            "artikelnummer": "ART-42",
            "einheit": "Stk",
            "menge": "3.0",
            "einzelpreisNetto": "42",
            "gesamtpreisNetto": "126",
            "listenpreis": "50",
        ]
        state.addPosition(
            objektID: "fileZ-2-0",
            bezeichnung: "Grifflose Front",
            menge: 3, preisNetto: 42.0, eingehend: true,
            attribute: attribute)

        // Position trägt ALLE Felder (Feld-für-Feld).
        let pos = state.positionen[0]
        #expect(pos.attribute["originalText"] == "3 Stk Grifflose Front 42,00 = 126,00")
        #expect(pos.attribute["seite"] == "2")
        #expect(pos.attribute["richtung"] == "eingehend")
        #expect(pos.attribute["kategorie"] == "Front")
        #expect(pos.attribute["status"] == "green")           // selbstbewiesen
        #expect(pos.attribute["menge"] == "3.0")
        #expect(pos.attribute["einzelpreisNetto"] == "42")
        #expect(pos.attribute["gesamtpreisNetto"] == "126")
        #expect(pos.attribute["listenpreis"] == "50")
        #expect(pos.artikelnummer == "ART-42")                // aus attribute übernommen

        // Nichts wird beim Checkout abgeschnitten: WarenkorbItem trägt dasselbe attribute.
        let item = pos.warenkorbItem
        #expect(item.attribute == attribute)
        #expect(item.ekNetto == 42.0)
        #expect(item.quelle == "angebot-eingehend")

        // Und weiter bis in den persistenten WorkBasket (Bridge → PickSnapshot.attribute).
        let basket = WarenkorbWorkBasketBridge.workBasket(
            aus: Warenkorb(items: [item]),
            projektNummer: "2026-015",
            id: WorkBasketID("WK-TEST"))
        let snapshot = basket.picks[0].snapshot
        #expect(snapshot.attribute["originalText"] == "3 Stk Grifflose Front 42,00 = 126,00")
        #expect(snapshot.attribute["status"] == "green")
        #expect(snapshot.attribute["gesamtpreisNetto"] == "126")
        #expect(snapshot.attribute["quelle"] == "angebot-eingehend")   // kanonisch aus quelle
    }

    @Test func gleichePickerPositionErhoehtMengeStattDuplikat() {
        let state = WarenkorbState()
        state.addPosition(objektID: "fileZ-1-0", bezeichnung: "Sockelblende",
                          menge: 1, preisNetto: 10, eingehend: false, attribute: [:])
        state.addPosition(objektID: "fileZ-1-0", bezeichnung: "Sockelblende",
                          menge: 2, preisNetto: 10, eingehend: false, attribute: [:])
        #expect(state.positionen.count == 1)
        #expect(state.positionen[0].menge == 3)
        #expect(state.positionen[0].source == "angebot-ausgehend")
        #expect(state.positionen[0].vkNetto == 10)   // ausgehend → VK
        #expect(state.positionen[0].ekNetto == nil)
    }

    @Test func devExportPositionUebernimmtQuelleUndFelder() {
        let state = WarenkorbState()
        state.addAngebot(fileID: "fileABC", bezeichnung: "Rechnung.pdf",
                          belegNummer: "RE-2026-01", eingehend: false)
        let export = state.positionen[0].devExportPosition
        #expect(export.quelle == "angebot-ausgehend")
        #expect(export.bezeichnung == "Rechnung.pdf")
        #expect(export.artikelnummer == "RE-2026-01")
        #expect(export.ekNetto == nil)
        #expect(export.vkNetto == nil)
    }
}
