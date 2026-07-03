import Testing
import Foundation
@testable import MykilosKit

// MARK: - WorkBasketEditingTests (V10-Plan, Phase 1, Block E)
//
// Reine Foundation-Logik: Menge/Preis korrigieren, Position entfernen,
// Rückverfolgbarkeit (matrix/objektID/inhalt) erhalten, eingefrorene Körbe
// unantastbar, ungültige Indizes no-op.

struct WorkBasketEditingTests {

    private func korb(status: WorkBasketStatus = .kalkulation) -> WorkBasket {
        let a = BasicPick(
            matrix: .artikel,
            objektID: CatalogObjectID("art-1"),
            snapshot: PickSnapshot(bezeichnung: "Spüle", menge: 2, ekEinzel: 120, vkEinzel: 240),
            inhalt: .text("SP-100")
        )
        let b = BasicPick(
            matrix: .artikel,
            objektID: CatalogObjectID("art-2"),
            snapshot: PickSnapshot(bezeichnung: "Backofen", menge: 1, ekEinzel: 600, vkEinzel: 950),
            inhalt: .text("BO-950")
        )
        return WorkBasket(
            id: WorkBasketID("WK-2026-015-0001"),
            projektNummer: "2026-015",
            inhaltsArt: .artikel,
            picks: [a, b],
            status: status
        )
    }

    // MARK: - Menge ändern

    @Test func aktualisiereMengeAendertNurZielPosition() {
        let neu = WorkBasketEditing.aktualisierePosition(korb(), anIndex: 0, menge: 5)
        #expect(neu.picks[0].snapshot.menge == 5)
        #expect(neu.picks[1].snapshot.menge == 1)          // unverändert
        #expect(neu.picks.count == 2)
    }

    @Test func aktualisierePreisAendertNurVK() {
        let neu = WorkBasketEditing.aktualisierePosition(korb(), anIndex: 1, vkEinzel: 1099)
        #expect(neu.picks[1].snapshot.vkEinzel == 1099)
        #expect(neu.picks[1].snapshot.ekEinzel == 600)     // EK unverändert
        #expect(neu.picks[0].snapshot.vkEinzel == 240)     // andere Position unverändert
    }

    @Test func negativeMengeWirdAuf0Geklemmt() {
        let neu = WorkBasketEditing.aktualisierePosition(korb(), anIndex: 0, menge: -3)
        #expect(neu.picks[0].snapshot.menge == 0)
    }

    // MARK: - Rückverfolgbarkeit bleibt erhalten

    @Test func editErhaeltMatrixObjektIDUndInhalt() async throws {
        let neu = WorkBasketEditing.aktualisierePosition(korb(), anIndex: 0, menge: 3, vkEinzel: 250)
        let pick = neu.picks[0]
        #expect(pick.matrix == .artikel)
        #expect(pick.objektID == CatalogObjectID("art-1"))
        let inhalt = try await pick.resolve()
        #expect(inhalt == .text("SP-100"))                 // Inhalt verlustfrei
    }

    // MARK: - Entfernen

    @Test func entferneReduziertPositionen() {
        let neu = WorkBasketEditing.entfernePosition(korb(), anIndex: 0)
        #expect(neu.picks.count == 1)
        #expect(neu.picks[0].objektID == CatalogObjectID("art-2"))
    }

    // MARK: - Eingefrorene Körbe sind unantastbar (§7 / warenkorb-lebenszyklus)

    @Test func eingefrorenerKorbBleibtUnveraendert() {
        let bestaetigt = korb(status: .bestaetigt)
        let nachEdit = WorkBasketEditing.aktualisierePosition(bestaetigt, anIndex: 0, menge: 99)
        #expect(nachEdit.picks[0].snapshot.menge == 2)     // keine Änderung
        let nachRemove = WorkBasketEditing.entfernePosition(bestaetigt, anIndex: 0)
        #expect(nachRemove.picks.count == 2)               // keine Änderung
    }

    // MARK: - Ungültiger Index = no-op

    @Test func ungueltigerIndexLaesstKorbUnveraendert() {
        let neu = WorkBasketEditing.aktualisierePosition(korb(), anIndex: 9, menge: 1)
        #expect(neu.picks.count == 2)
        #expect(neu.picks[0].snapshot.menge == 2)
        let neu2 = WorkBasketEditing.entfernePosition(korb(), anIndex: -1)
        #expect(neu2.picks.count == 2)
    }
}
