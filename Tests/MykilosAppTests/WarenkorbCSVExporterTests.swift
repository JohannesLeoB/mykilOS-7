import Testing
import Foundation
@testable import MykilosApp

// MARK: - WarenkorbCSVExporter (Feature D, 2026-07-07)
// Reine String-Erzeugung — voll testbar ohne AppKit/UI.

struct WarenkorbCSVExporterTests {

    private func position(
        bezeichnung: String,
        artikelnummer: String = "A-1",
        source: String = "katalog",
        menge: Int = 1,
        ek: Double? = nil,
        vk: Double? = nil,
        attribute: [String: String] = [:]
    ) -> WarenkorbState.Position {
        WarenkorbState.Position(
            id: "\(source)-\(artikelnummer)", source: source,
            bezeichnung: bezeichnung, artikelnummer: artikelnummer,
            menge: menge, ekNetto: ek, vkNetto: vk, attribute: attribute
        )
    }

    // MARK: - Escaping (der Korrektheits-Kern)

    @Test func feldMitSemikolonWirdGequotet() {
        #expect(WarenkorbCSVExporter.feld("Platte 600; weiß") == "\"Platte 600; weiß\"")
    }

    @Test func feldMitAnfuehrungszeichenVerdoppelt() {
        // 24"-Auszug → Anführungszeichen im Feld muss verdoppelt + gequotet werden.
        #expect(WarenkorbCSVExporter.feld("24\" Auszug") == "\"24\"\" Auszug\"")
    }

    @Test func feldMitZeilenumbruchWirdGequotet() {
        #expect(WarenkorbCSVExporter.feld("Zeile1\nZeile2") == "\"Zeile1\nZeile2\"")
    }

    @Test func harmlosesFeldBleibtUnveraendert() {
        #expect(WarenkorbCSVExporter.feld("Blanco Spüle") == "Blanco Spüle")
    }

    // MARK: - Preis-Formatierung (deutsch, Komma-Dezimal)

    @Test func preisDeutschesFormat() {
        #expect(WarenkorbCSVExporter.preis(1234.5) == "1234,50")
    }

    @Test func preisNilIstLeerNichtNull() {
        // Unbekannter Preis → leer, NIE erfundene 0,00.
        #expect(WarenkorbCSVExporter.preis(nil) == "")
    }

    // MARK: - Voll-Export

    @Test func csvBeginntMitBOMUndKopf() {
        let csv = WarenkorbCSVExporter.csv(
            positionen: [position(bezeichnung: "Backofen", vk: 950)],
            kopf: .init(bezeichnung: "Küche Müller", projekt: "2026-015",
                        datum: Date(timeIntervalSince1970: 1_800_000_000))
        )
        #expect(csv.hasPrefix("\u{FEFF}"))
        #expect(csv.contains("Warenkorb;Küche Müller"))
        #expect(csv.contains("Projekt;2026-015"))
        #expect(csv.contains("Positionen;1"))
    }

    @Test func csvEnthaeltSpaltenkopfUndPositionMitLieferantUndKategorie() {
        let csv = WarenkorbCSVExporter.csv(positionen: [
            position(bezeichnung: "Blum Legrabox", artikelnummer: "637.38.054", menge: 4,
                     ek: 12, vk: 24, attribute: ["lieferant": "Häfele", "kategorie": "Beschlag"])
        ])
        #expect(csv.contains("Pos.;Artikelnummer;Bezeichnung;Lieferant;Kategorie;Quelle;Menge;EK-Einzel;VK-Einzel;VK-Summe"))
        #expect(csv.contains("1;637.38.054;Blum Legrabox;Häfele;Beschlag;katalog;4;12,00;24,00;96,00"))
    }

    @Test func summenzeileSummiertVKUeberMenge() {
        let csv = WarenkorbCSVExporter.csv(positionen: [
            position(bezeichnung: "A", menge: 2, vk: 10),   // 20
            position(bezeichnung: "B", menge: 3, vk: 5)     // 15
        ])
        #expect(csv.contains("Summe VK;35,00"))
    }

    @Test func positionOhneVKHatLeereVKSummeUndZaehltNichtInSumme() {
        let csv = WarenkorbCSVExporter.csv(positionen: [
            position(bezeichnung: "MitPreis", menge: 1, vk: 100),
            position(bezeichnung: "OhnePreis", menge: 5, vk: nil)
        ])
        // OhnePreis-Zeile: VK-Einzel + VK-Summe leer, keine erfundene 0.
        #expect(csv.contains("2;A-1;OhnePreis;;;katalog;5;;;"))
        // Summe nur aus MitPreis.
        #expect(csv.contains("Summe VK;100,00"))
    }

    @Test func leererKorbLiefertKopfSpaltenUndNullsumme() {
        let csv = WarenkorbCSVExporter.csv(positionen: [])
        #expect(csv.contains("Positionen;0"))
        #expect(csv.contains("Pos.;Artikelnummer"))
        #expect(csv.contains("Summe VK;0,00"))
    }

    @Test func bezeichnungMitSemikolonZerreisstZeileNicht() {
        // Realer Tischler-Fall: Artikelname mit Semikolon.
        let csv = WarenkorbCSVExporter.csv(positionen: [
            position(bezeichnung: "Seite links; Ahorn", menge: 1, vk: 50)
        ])
        #expect(csv.contains("\"Seite links; Ahorn\""))
    }

    @Test func zeilenSindMitCRLFGetrennt() {
        let csv = WarenkorbCSVExporter.csv(positionen: [position(bezeichnung: "X", vk: 1)])
        #expect(csv.contains("\r\n"))
    }
}
