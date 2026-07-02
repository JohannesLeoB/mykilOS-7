import Testing
import Foundation
@testable import MykilosKit

// MARK: - DevBasketExportTests
// Deckt den Dev-Checkout-Exporter-Datentyp ab (lokaler Sandbox-Export, kein Live-Write):
// 1. Encoding-Rundtrip: prettyJSON() → decode(fromJSON:) → Gleichheit.
// 2. exportID-Eindeutigkeit: zwei Exporte erzeugen nie dieselbe ID.
// 3. Leere Positionen kodieren weiterhin zu validem JSON (Edge Case).
struct DevBasketExportTests {

    private func machePosition(
        quelle: String = "katalog",
        bezeichnung: String = "Griff Edelstahl 128mm",
        artikelnummer: String? = "ART-001",
        menge: Int = 2,
        ekNetto: Double? = 4.5,
        vkNetto: Double? = 9.9
    ) -> DevBasketExportPosition {
        DevBasketExportPosition(
            quelle: quelle,
            bezeichnung: bezeichnung,
            artikelnummer: artikelnummer,
            menge: menge,
            ekNetto: ekNetto,
            vkNetto: vkNetto
        )
    }

    // MARK: - Rundtrip

    @Test func encodingRundtripBleibtGleich() throws {
        let export = DevBasketExport(
            quelle: "session",
            bezeichnung: "Testkorb",
            projekt: "2026-015",
            positionen: [
                machePosition(),
                machePosition(quelle: "lager", bezeichnung: "Scharnier", artikelnummer: nil, menge: 4, ekNetto: nil, vkNetto: nil),
                machePosition(quelle: "angebot-eingehend", bezeichnung: "Arbeitsplatte Eiche", artikelnummer: "AN-2026-0099", menge: 1, ekNetto: nil, vkNetto: nil),
            ],
            summeEKNetto: 9.0,
            summeVKNetto: 19.8
        )

        let json = try export.prettyJSON()
        let decoded = try DevBasketExport.decode(fromJSON: json)

        #expect(decoded == export)
        #expect(decoded.positionen.count == 3)
        #expect(decoded.anzahlPositionen == 3)
    }

    // MARK: - exportID-Eindeutigkeit

    @Test func exportIDIstJedesMalNeu() {
        let a = DevBasketExport(quelle: "session", positionen: [machePosition()])
        let b = DevBasketExport(quelle: "session", positionen: [machePosition()])
        #expect(a.exportID != b.exportID)
    }

    // MARK: - Leere Positionen (Edge Case)

    @Test func leerePositionenKodierenValide() throws {
        let export = DevBasketExport(
            quelle: "gespeicherter-warenkorb:recXYZ",
            bezeichnung: nil,
            projekt: nil,
            positionen: [],
            summeEKNetto: nil,
            summeVKNetto: nil
        )

        #expect(export.anzahlPositionen == 0)

        let json = try export.prettyJSON()
        #expect(json.contains("\"positionen\""))

        let decoded = try DevBasketExport.decode(fromJSON: json)
        #expect(decoded.positionen.isEmpty)
        #expect(decoded == export)
    }

    // MARK: - anzahlPositionen-Default aus positionen.count

    @Test func anzahlPositionenDefaultetAufArrayCount() {
        let export = DevBasketExport(
            quelle: "session",
            positionen: [machePosition(), machePosition(artikelnummer: "ART-002")]
        )
        #expect(export.anzahlPositionen == 2)
    }
}
