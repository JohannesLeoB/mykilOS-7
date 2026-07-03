import Testing
import Foundation
@testable import MykilosKit

// MARK: - WorkBasketSummenTests (V10, Block E/H)
// Reine Summen-Logik: VK-Netto über alle Positionen; Positionen ohne VK zählen 0.

struct WorkBasketSummenTests {

    private func pick(_ bez: String, menge: Int, vk: Double?) -> BasicPick {
        BasicPick(
            matrix: .artikel,
            objektID: CatalogObjectID(bez),
            snapshot: PickSnapshot(bezeichnung: bez, menge: menge, vkEinzel: vk)
        )
    }

    @Test func vkNettoSummeRechnetMengeMalEinzelpreis() {
        let korb = WorkBasket(
            id: WorkBasketID("WK-1"),
            projektNummer: "2026-015",
            inhaltsArt: .artikel,
            picks: [pick("Spüle", menge: 2, vk: 240), pick("Backofen", menge: 1, vk: 950)]
        )
        // 2×240 + 1×950 = 1430
        #expect(korb.vkNettoSumme == 1430)
    }

    @Test func positionOhneVKZaehltNull() {
        let korb = WorkBasket(
            id: WorkBasketID("WK-2"),
            projektNummer: "2026-016",
            inhaltsArt: .artikel,
            picks: [pick("Mit VK", menge: 3, vk: 10), pick("Ohne VK", menge: 5, vk: nil)]
        )
        #expect(korb.vkNettoSumme == 30)
    }

    @Test func leererKorbSummeNull() {
        let korb = WorkBasket(id: WorkBasketID("WK-3"), projektNummer: "2026-017", inhaltsArt: .artikel, picks: [])
        #expect(korb.vkNettoSumme == 0)
    }
}
