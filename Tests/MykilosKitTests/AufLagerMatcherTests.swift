import Testing
import Foundation
@testable import MykilosKit

// MARK: - AufLagerMatcherTests
// Testet reine Matching-Funktionen — kein Netzwerk, kein State.
struct AufLagerMatcherTests {

    // MARK: - Normalisierung

    @Test func normalisierungEntferntBindestrichUndLeerzeichen() {
        let result = LagerItem.normalisiereArtikelnummer("FRANKE-UPX 500")
        #expect(result == "FRANKEUPX500")
    }

    @Test func normalisierungGrossuchstaben() {
        let result = LagerItem.normalisiereArtikelnummer("grohe-gfw-750")
        #expect(result == "GROHEGFW750")
    }

    @Test func normalisierungLeererString() {
        #expect(LagerItem.normalisiereArtikelnummer("").isEmpty)
    }

    @Test func normalisierungNurSonderzeichen() {
        // Nur Sonderzeichen → leerer normalisierter String
        let result = LagerItem.normalisiereArtikelnummer("---/+")
        #expect(result.isEmpty)
    }

    // MARK: - Exakter Treffer

    @Test func exakterTrefferBeiGleicherNormalisierterArtikelnummer() {
        let artikel = ArtikelItem(
            id: "a1", artikelnummer: "GROHE-GFW-750",
            hersteller: "GROHE", artikelbeschreibung: "Eurosmart"
        )
        let lager = [
            LagerItem(id: "l1", bezeichnung: "Grohe Einhebelmischer",
                      hersteller: "GROHE", artikelnummer: "GROHE GFW 750")
        ]
        let result = AufLagerMatcher.suche(artikel: artikel, in: lager)
        #expect(result.exakt.count == 1)
        #expect(result.exakt[0].lagerItem.id == "l1")
        #expect(result.exakt[0].trefftyp == .exakt)
        #expect(result.aehnlich.isEmpty)
        #expect(result.hatTreffer)
    }

    @Test func exakterTrefferCaseInsensitiv() {
        let artikel = ArtikelItem(id: "a1", artikelnummer: "gfw750")
        let lager = [LagerItem(id: "l1", bezeichnung: "Armatur", artikelnummer: "GFW750")]
        let result = AufLagerMatcher.suche(artikel: artikel, in: lager)
        #expect(result.exakt.count == 1)
    }

    @Test func keinExakterTrefferBeiVerschiedenenNummern() {
        let artikel = ArtikelItem(id: "a1", artikelnummer: "GFW-750")
        let lager = [LagerItem(id: "l1", bezeichnung: "Anderes Produkt", artikelnummer: "GFW-751")]
        let result = AufLagerMatcher.suche(artikel: artikel, in: lager)
        #expect(result.exakt.isEmpty)
    }

    @Test func keinTrefferBeiLeererArtikelNummer() {
        let artikel = ArtikelItem(id: "a1", artikelnummer: "")
        let lager = [LagerItem(id: "l1", bezeichnung: "Produkt", artikelnummer: "")]
        let result = AufLagerMatcher.suche(artikel: artikel, in: lager)
        // Beide leer → kein exakter Treffer (leere normalisierte Nummern matchen nicht)
        #expect(result.exakt.isEmpty)
    }

    // MARK: - Ähnlicher Treffer

    @Test func aehnlicherTrefferGleicherHerstellerTokenOverlap() {
        let artikel = ArtikelItem(
            id: "a1", artikelnummer: "XYZ-999",
            hersteller: "GROHE",
            artikelbeschreibung: "Eurosmart Einhebelmischer"
        )
        let lager = [
            LagerItem(
                id: "l1",
                bezeichnung: "Eurosmart Wannenarmatur",
                hersteller: "GROHE",
                artikelnummer: "GROHE-999B"  // andere Nummer → kein exakter Treffer
            )
        ]
        let result = AufLagerMatcher.suche(artikel: artikel, in: lager)
        #expect(result.exakt.isEmpty)
        #expect(result.aehnlich.count == 1)
        #expect(result.aehnlich[0].trefftyp == .aehnlich)
        #expect(result.aehnlich[0].lagerItem.id == "l1")
    }

    @Test func keinAehnlicherTrefferBeiVerschiedenemHersteller() {
        let artikel = ArtikelItem(
            id: "a1", artikelnummer: "XYZ-999",
            hersteller: "GROHE",
            artikelbeschreibung: "Eurosmart Einhebelmischer"
        )
        let lager = [
            LagerItem(
                id: "l1",
                bezeichnung: "Eurosmart Einhebelmischer",
                hersteller: "Hansgrohe",  // anderer Hersteller
                artikelnummer: "HG-123"
            )
        ]
        let result = AufLagerMatcher.suche(artikel: artikel, in: lager)
        #expect(result.aehnlich.isEmpty)
    }

    @Test func keinAehnlicherTrefferBeiKeinemTokenOverlap() {
        let artikel = ArtikelItem(
            id: "a1", artikelnummer: "XYZ-999",
            hersteller: "GROHE",
            artikelbeschreibung: "Eurosmart Mischer"
        )
        let lager = [
            LagerItem(
                id: "l1",
                bezeichnung: "Zulaufventil Kompakt",  // kein gemeinsamer Token
                hersteller: "GROHE",
                artikelnummer: "GR-VLV-1"
            )
        ]
        let result = AufLagerMatcher.suche(artikel: artikel, in: lager)
        #expect(result.aehnlich.isEmpty)
    }

    @Test func exakterTrefferNichtAlsAehnlicherGemeldet() {
        // Ein Record ist exakter Treffer → darf nicht ZUSÄTZLICH als ähnlich erscheinen
        let artikel = ArtikelItem(
            id: "a1", artikelnummer: "GROHE-GFW-750",
            hersteller: "GROHE",
            artikelbeschreibung: "Eurosmart Einhebelmischer"
        )
        let lager = [
            LagerItem(
                id: "l1",
                bezeichnung: "Eurosmart Einhebelmischer",
                hersteller: "GROHE",
                artikelnummer: "GROHEGFW750"  // normalisiert identisch
            )
        ]
        let result = AufLagerMatcher.suche(artikel: artikel, in: lager)
        #expect(result.exakt.count == 1)
        #expect(result.aehnlich.isEmpty)
    }

    // MARK: - Mehrere Treffer

    @Test func mehrereExakteTreffer() {
        let artikel = ArtikelItem(id: "a1", artikelnummer: "GFW-750")
        let lager = [
            LagerItem(id: "l1", bezeichnung: "Version A", artikelnummer: "GFW 750"),
            LagerItem(id: "l2", bezeichnung: "Version B", artikelnummer: "GFW750"),
        ]
        let result = AufLagerMatcher.suche(artikel: artikel, in: lager)
        #expect(result.exakt.count == 2)
    }

    @Test func alleGibtExaktVorAehnlich() {
        let artikel = ArtikelItem(
            id: "a1", artikelnummer: "GFW-750",
            hersteller: "GROHE",
            artikelbeschreibung: "Eurosmart Mischer"
        )
        let lager = [
            LagerItem(id: "l_aehnlich", bezeichnung: "Eurosmart Wannenarmatur",
                      hersteller: "GROHE", artikelnummer: "GFW-999"),  // ähnlich
            LagerItem(id: "l_exakt", bezeichnung: "Exaktes Produkt",
                      artikelnummer: "GFW750"),  // exakt
        ]
        let result = AufLagerMatcher.suche(artikel: artikel, in: lager)
        let alle = result.alle
        #expect(alle.count == 2)
        // Exakter Treffer zuerst
        #expect(alle.first?.trefftyp == .exakt)
    }

    // MARK: - Bestand

    @Test func trefferTraegtBestandAusLagerItem() {
        let artikel = ArtikelItem(id: "a1", artikelnummer: "GFW-750")
        let lager = [LagerItem(id: "l1", bezeichnung: "Armatur", artikelnummer: "GFW750", bestand: 5)]
        let result = AufLagerMatcher.suche(artikel: artikel, in: lager)
        #expect(result.exakt[0].bestand == 5)
    }

    @Test func trefferBestandNilWennNichtAngegeben() {
        let artikel = ArtikelItem(id: "a1", artikelnummer: "GFW-750")
        let lager = [LagerItem(id: "l1", bezeichnung: "Armatur", artikelnummer: "GFW750")]
        let result = AufLagerMatcher.suche(artikel: artikel, in: lager)
        #expect(result.exakt[0].bestand == nil)
    }

    // MARK: - Leere Lagerliste / kein Treffer

    @Test func leereLagerliste() {
        let artikel = ArtikelItem(id: "a1", artikelnummer: "GFW-750")
        let result = AufLagerMatcher.suche(artikel: artikel, in: [])
        #expect(!result.hatTreffer)
        #expect(result.alle.isEmpty)
    }

    @Test func keinTrefferWennKeineUebereinstimmung() {
        let artikel = ArtikelItem(id: "a1", artikelnummer: "UNBEKANNT-999",
                                  hersteller: "UnbekannterHersteller")
        let lager = [
            LagerItem(id: "l1", bezeichnung: "Grohe Armatur", hersteller: "GROHE", artikelnummer: "GR-001"),
        ]
        let result = AufLagerMatcher.suche(artikel: artikel, in: lager)
        #expect(!result.hatTreffer)
    }

    // MARK: - Batch-Suche

    @Test func batchSucheGibtResultatJeArtikelID() {
        let artikel1 = ArtikelItem(id: "a1", artikelnummer: "GFW-750")
        let artikel2 = ArtikelItem(id: "a2", artikelnummer: "TUX-100")
        let lager = [
            LagerItem(id: "l1", bezeichnung: "Armatur", artikelnummer: "GFW750"),
        ]
        let batch = AufLagerMatcher.sucheBatch(artikel: [artikel1, artikel2], in: lager)
        #expect(batch["a1"]?.exakt.count == 1)
        #expect(batch["a2"]?.exakt.isEmpty == true)
    }

    @Test func batchSucheLeereEingabe() {
        let result = AufLagerMatcher.sucheBatch(artikel: [], in: [])
        #expect(result.isEmpty)
    }

    // MARK: - Hersteller-Normalisierung (Hilfsmethode)

    @Test func normalisiereHerstellerTrimmtUndKleinbuchstaben() {
        let result = AufLagerMatcher.normalisiereHersteller("  GROHE  ")
        #expect(result == "grohe")
    }
}
