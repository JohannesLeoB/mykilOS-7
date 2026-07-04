import Testing
import Foundation
@testable import MykilosKit

// Tests für den Vectorworks-Plankopf-Port (Port #17, v1 „ausgestreckte Hand"):
// reiner I/O-Vertrag — TSV-Nutzlast, kein externer Write, keine Preise im Plan.
struct VectorworksPlankopfPortTests {

    private func korb(picks: [any Pick] = []) -> WorkBasket {
        WorkBasket(id: WorkBasketID("wb-test-1"), projektNummer: "2026-015",
                   inhaltsArt: .artikel, picks: picks)
    }

    private func geraet(_ name: String, menge: Int) -> BasicPick {
        BasicPick(matrix: .artikel, objektID: CatalogObjectID("art-x"),
                  snapshot: PickSnapshot(bezeichnung: name, menge: menge,
                                         ekEinzel: 111.0, vkEinzel: 222.0, attribute: [:]))
    }

    private var ziel: PortZiel {
        PortZiel(kind: VectorworksPlankopfPort.zielKind, parameter: [
            "kunde": "Hustadt", "projekt_nr": "2026-015",
            "adresse": "Siebenbrüderweide 9", "plz_ort": "21109 Hamburg",
        ])
    }

    @Test func executeLiefertTSVMitKopffeldernUndFooter() async throws {
        let result = try await VectorworksPlankopfPort().execute(basket: korb(), ziel: ziel)
        #expect(result.erfolg)
        #expect(result.referenz == nil)   // v1: bewusst keine Postbox-Ablage
        let tsv = String(decoding: try #require(result.nutzlast), as: UTF8.self)
        #expect(tsv.contains("KUNDE\tHustadt"))
        #expect(tsv.contains("PROJEKT_NR\t2026-015"))
        #expect(tsv.contains("DATUM\t"))               // fehlender Wert → leer, Zeile bleibt
        #expect(tsv.contains("FIRMA\tMYKILOS GmbH"))   // konstanter Footer
    }

    @Test func geraeteZeilenOhnePreise() async throws {
        let result = try await VectorworksPlankopfPort()
            .execute(basket: korb(picks: [geraet("Kochfeld Bora X", menge: 1)]), ziel: ziel)
        let tsv = String(decoding: try #require(result.nutzlast), as: UTF8.self)
        #expect(tsv.contains("GERAET\tKochfeld Bora X\t1"))
        #expect(tsv.contains("111") == false)   // EK nie im Plankopf
        #expect(tsv.contains("222") == false)   // VK nie im Plankopf
    }

    @Test func previewWarntBeiFehlendenPflichtfeldernUndFalscherZielArt() async throws {
        let leer = PortZiel(kind: "postbox", parameter: [:])
        let preview = try await VectorworksPlankopfPort().preview(basket: korb(), ziel: leer)
        #expect(preview.warnungen.count == 2)
        #expect(preview.warnungen[0].contains("KUNDE"))
        #expect(preview.warnungen[0].contains("PROJEKT_NR"))
    }

    @Test func bereinigtEntferntTabsUndUmbrueche() {
        #expect(VectorworksPlankopfPort.bereinigt("A\tB\nC") == "A B C")
    }
}
