import Testing
import Foundation
@testable import MykilosApp

// MARK: - MykPDFRendererTests
// Reine Funktions-Tests — kein Netzwerk, kein Keychain, kein AppKit-Rendering auf CI.
// Prüft: render() gibt nicht-leere Data zurück; die zurückgegebenen Bytes beginnen
// mit dem PDF-Magic-Byte (%PDF), der Renderer also wirklich ein valides PDF erzeugt.

struct MykPDFRendererTests {

    @Test func renderGibtNichtLeereDataZurueck() {
        let data = MykPDFRenderer.render(
            title: "Testdokument",
            subtitle: "Projekt 2026-001 — MUSTER",
            sections: [
                (heading: "Kundendaten", fields: [
                    (label: "Name",    value: "Max Mustermann"),
                    (label: "Adresse", value: "Musterstraße 1"),
                ]),
            ],
            table: nil,
            totals: []
        )
        #expect(!data.isEmpty)
    }

    @Test func renderErzeugtesPDFBeginnMitMagicBytes() {
        let data = MykPDFRenderer.render(title: "Magic Test", sections: [])
        // Alle PDFs beginnen mit "%PDF" (0x25 0x50 0x44 0x46).
        let magic = Data([0x25, 0x50, 0x44, 0x46])
        #expect(data.prefix(4) == magic)
    }

    @Test func renderMitTabelleGibtNichtLeereDataZurueck() {
        let data = MykPDFRenderer.render(
            title: "Warenkorb",
            sections: [],
            table: [
                ["Position", "Menge", "Preis"],
                ["Tischplatte Eiche",  "1", "890,00 €"],
                ["Schubkasten-Set",    "3", "210,00 €"],
            ],
            totals: [
                ("Netto", "1.100,00 €"),
                ("MwSt. 19%", "209,00 €"),
                ("Gesamt", "1.309,00 €"),
            ]
        )
        #expect(!data.isEmpty)
        #expect(data.prefix(4) == Data([0x25, 0x50, 0x44, 0x46]))
    }

    @Test func renderOhneSectionsUndTabelleGibtValidePDF() {
        let data = MykPDFRenderer.render(title: "Leer", sections: [])
        #expect(!data.isEmpty)
        #expect(data.prefix(4) == Data([0x25, 0x50, 0x44, 0x46]))
    }
}
