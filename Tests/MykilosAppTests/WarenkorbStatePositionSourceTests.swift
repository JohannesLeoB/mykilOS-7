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
