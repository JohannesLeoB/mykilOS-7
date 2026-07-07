import Testing
import Foundation
@testable import MykilosApp

// MARK: - WarenkorbPDFExporter (Feature D Teil 2, 2026-07-07)
// Die reine Tabellen-/Summen-Logik ist deterministisch testbar; das gerenderte PDF
// prüfen wir wie DokumentPort über die %PDF-Magic-Bytes (CGContext-Rendering ist nicht
// byte-genau vergleichbar, aber "erzeugt echtes PDF" ist verifizierbar).

struct WarenkorbPDFExporterTests {

    private func position(
        bezeichnung: String,
        artikelnummer: String = "A-1",
        menge: Int = 1,
        ek: Double? = nil,
        vk: Double? = nil
    ) -> WarenkorbState.Position {
        WarenkorbState.Position(
            id: "katalog-\(artikelnummer)", source: "katalog",
            bezeichnung: bezeichnung, artikelnummer: artikelnummer,
            menge: menge, ekNetto: ek, vkNetto: vk
        )
    }

    // MARK: - Reine Tabellen-Logik

    @Test func tabelleBeginntMitSpaltenkopf() {
        let tabelle = WarenkorbPDFExporter.tabelle(positionen: [position(bezeichnung: "X", vk: 1)])
        #expect(tabelle.first == WarenkorbPDFExporter.spaltenkopf)
    }

    @Test func tabellenzeileTraegtPositionUndVKSumme() {
        let tabelle = WarenkorbPDFExporter.tabelle(positionen: [
            position(bezeichnung: "Backofen", artikelnummer: "B-9", menge: 2, ek: 600, vk: 950)
        ])
        // Zeile 1 (nach Kopf): Pos.; Art.-Nr.; Bez.; Menge; EK; VK; VK-Summe(=1900)
        #expect(tabelle[1] == ["1", "B-9", "Backofen", "2", "600,00", "950,00", "1900,00"])
    }

    @Test func positionOhneVKHatLeereVKFelder() {
        let tabelle = WarenkorbPDFExporter.tabelle(positionen: [
            position(bezeichnung: "OhnePreis", menge: 3, vk: nil)
        ])
        #expect(tabelle[1][5] == "")   // VK-Einzel leer
        #expect(tabelle[1][6] == "")   // VK-Summe leer (nie erfundene 0)
    }

    @Test func summenRechnenEKUndVKUeberMenge() {
        let summen = WarenkorbPDFExporter.summen(positionen: [
            position(bezeichnung: "A", menge: 2, ek: 10, vk: 20),   // EK 20, VK 40
            position(bezeichnung: "B", menge: 1, ek: 5, vk: 8)      // EK 5, VK 8
        ])
        #expect(summen.first { $0.label == "Summe EK netto" }?.value == "25,00")
        #expect(summen.first { $0.label == "Summe VK netto" }?.value == "48,00")
    }

    // MARK: - Gerendertes PDF

    @Test func pdfErzeugtEchteBytesMitMagicHeader() {
        let data = WarenkorbPDFExporter.pdf(positionen: [position(bezeichnung: "Spüle", vk: 240)])
        #expect(data.isEmpty == false)
        // %PDF-Magic-Bytes.
        #expect(data.prefix(4) == Data([0x25, 0x50, 0x44, 0x46]))
    }

    @Test func pdfAuchBeiLeeremKorbEchtesDokument() {
        // Leerer Korb: Renderer bekommt keine Tabelle, liefert aber ein gültiges PDF (Kopf + Fußnote).
        let data = WarenkorbPDFExporter.pdf(positionen: [])
        #expect(data.prefix(4) == Data([0x25, 0x50, 0x44, 0x46]))
    }

    @Test func belegfuehrungsHinweisIstGesetzt() {
        // Eiserne Regel: priced document = Vorschau, nie offizielles Angebot.
        #expect(WarenkorbPDFExporter.vorschauHinweis.contains("kein offizielles Angebot"))
    }
}
