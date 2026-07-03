import Testing
import Foundation
@testable import MykilosApp
@testable import MykilosKit

// MARK: - AngebotsRenderMapperTests (Version 10, Phase 2 / Block F)
//
// Reine Foundation-Logik, kein Netzwerk, kein Rendern. Deckt: voller Korb
// (Zeilen/Summen/MwSt), leerer Korb (definierter Zustand), Rundung, sowie
// deterministisch injiziertes Datum/Angebotsnummer.

struct AngebotsRenderMapperTests {

    // MARK: - Test-Bausteine

    private static func fixDatum() -> Date {
        // 2026-07-03 12:00:00 UTC — fest, damit die Formatierung deterministisch bleibt.
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 7
        comps.day = 3
        comps.hour = 12
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.date(from: comps)!
    }

    private func vollerKorb() -> WorkBasket {
        let spuele = BasicPick(
            matrix: .artikel,
            objektID: CatalogObjectID("art-1"),
            snapshot: PickSnapshot(bezeichnung: "Blanco Spüle", menge: 2, ekEinzel: 120, vkEinzel: 240)
        )
        let backofen = BasicPick(
            matrix: .artikel,
            objektID: CatalogObjectID("art-2"),
            snapshot: PickSnapshot(bezeichnung: "Backofen Bosch", menge: 1, ekEinzel: 600, vkEinzel: 950)
        )
        return WorkBasket(
            id: WorkBasketID("WK-2026-015-0001"),
            projektNummer: "2026-015",
            inhaltsArt: .artikel,
            picks: [spuele, backofen]
        )
    }

    private func leererKorb(projektNummer: String = "2026-020") -> WorkBasket {
        WorkBasket(
            id: WorkBasketID("WK-2026-020-0001"),
            projektNummer: projektNummer,
            inhaltsArt: .artikel,
            picks: []
        )
    }

    // MARK: - 1. Voller Korb: Zeilen, Netto/MwSt/Brutto

    @Test func vollerKorbErzeugtKorrekteZeilenUndSummen() {
        let args = AngebotsRenderMapper.map(
            basket: vollerKorb(),
            kunde: "Familie Schneider",
            projektTitel: "Küche Schneider",
            datum: Self.fixDatum()
        )

        #expect(args.title == "Angebot")
        #expect(args.subtitle == "Küche Schneider · A-2026-015")

        // Tabelle: Kopfzeile + 2 Positionszeilen.
        let table = try? #require(args.table)
        #expect(table?.count == 3)
        #expect(table?.first == ["Bezeichnung", "Menge", "Einzelpreis", "Summe"])
        #expect(table?[1][0] == "Blanco Spüle")
        #expect(table?[1][1] == "2")
        #expect(table?[2][0] == "Backofen Bosch")
        #expect(table?[2][1] == "1")

        // Netto = 2×240 + 1×950 = 1430. MwSt 19% = 271,70. Brutto = 1701,70.
        #expect(args.totals.count == 3)
        #expect(args.totals[0].label == "Netto")
        #expect(args.totals[1].label.contains("MwSt"))
        #expect(args.totals[1].label.contains("19"))
        #expect(args.totals[2].label == "Brutto")

        let netto = AngebotsRenderMapper.nettoSumme(picks: vollerKorb().picks)
        #expect(netto == 1430)
        let mwst = netto * AngebotsRenderMapper.mwstSatz
        #expect((mwst - 271.7).magnitude < 0.001)
        let brutto = netto + mwst
        #expect((brutto - 1701.7).magnitude < 0.001)
    }

    @Test func vollerKorbEnthaeltAbsenderUndKundenblock() {
        let args = AngebotsRenderMapper.map(
            basket: vollerKorb(),
            kunde: "Familie Schneider",
            projektTitel: "Küche Schneider",
            datum: Self.fixDatum()
        )
        let absenderSection = args.sections.first { $0.heading == "Absender" }
        #expect(absenderSection != nil)
        #expect(absenderSection?.fields.contains { $0.label == "Firma" && $0.value == "MYKILOS GmbH" } == true)

        let kundeSection = args.sections.first { $0.heading == "Kunde" }
        #expect(kundeSection?.fields.contains { $0.value == "Familie Schneider" } == true)

        let projektSection = args.sections.first { $0.heading == "Projekt" }
        #expect(projektSection?.fields.contains { $0.label == "Projektnummer" && $0.value == "2026-015" } == true)
        #expect(projektSection?.fields.contains { $0.label == "Angebotsnummer" && $0.value == "A-2026-015" } == true)
    }

    // MARK: - 2. Leerer Korb: definierter Zustand

    @Test func leererKorbHatKeineTabelleAberSummenNull() {
        let args = AngebotsRenderMapper.map(
            basket: leererKorb(),
            kunde: "Herr Muster",
            projektTitel: "Lichtplanung Muster",
            datum: Self.fixDatum()
        )
        #expect(args.table == nil)
        #expect(args.totals.count == 3)
        #expect(args.totals[0].value.contains("0,00"))
        #expect(args.totals[2].value.contains("0,00"))
    }

    // MARK: - 3. Rundung (3×9,99)

    @Test func rundungBei3x999() {
        let pick = BasicPick(
            matrix: .artikel,
            objektID: CatalogObjectID("art-3"),
            snapshot: PickSnapshot(bezeichnung: "Kleinteil", menge: 3, vkEinzel: 9.99)
        )
        let basket = WorkBasket(
            id: WorkBasketID("WK-2026-030-0001"),
            projektNummer: "2026-030",
            inhaltsArt: .artikel,
            picks: [pick]
        )
        let netto = AngebotsRenderMapper.nettoSumme(picks: basket.picks)
        // 3 × 9.99 = 29.97 exakt in Double-Arithmetik hier unproblematisch, aber wir prüfen
        // die gerundete String-Ausgabe (2 Nachkommastellen, kein Rundungsdrift).
        #expect((netto - 29.97).magnitude < 0.0001)

        let args = AngebotsRenderMapper.map(
            basket: basket,
            kunde: "Testkunde",
            projektTitel: "Testprojekt",
            datum: Self.fixDatum()
        )
        let table = try? #require(args.table)
        // NumberFormatter(de_DE, .currency) trennt Betrag/Symbol mit U+00A0 (NBSP).
        #expect(table?[1][2] == "9,99\u{00A0}€")
        #expect(table?[1][3] == "29,97\u{00A0}€")
        #expect(args.totals[0].value == "29,97\u{00A0}€")
    }

    // MARK: - 4. Datum/Nummer deterministisch injiziert

    @Test func datumWirdDeterministischFormatiert() {
        let args = AngebotsRenderMapper.map(
            basket: vollerKorb(),
            kunde: "Familie Schneider",
            projektTitel: "Küche Schneider",
            datum: Self.fixDatum()
        )
        let projektSection = args.sections.first { $0.heading == "Projekt" }
        let datumFeld = projektSection?.fields.first { $0.label == "Datum" }
        #expect(datumFeld != nil)
        // Long-Style-Formatierung des injizierten Datums enthält Jahr 2026.
        #expect(datumFeld?.value.contains("2026") == true)
    }

    @Test func angebotsnummerIstAusProjektnummerAbgeleitetUndDeterministisch() {
        #expect(AngebotsRenderMapper.angebotsnummer(projektNummer: "2026-015") == "A-2026-015")
        #expect(AngebotsRenderMapper.angebotsnummer(projektNummer: "2026-999") == "A-2026-999")
    }

    @Test func gleicherKorbGleichesDatumErzeugtIdentischeArgs() {
        let a = AngebotsRenderMapper.map(
            basket: vollerKorb(), kunde: "X", projektTitel: "Y", datum: Self.fixDatum()
        )
        let b = AngebotsRenderMapper.map(
            basket: vollerKorb(), kunde: "X", projektTitel: "Y", datum: Self.fixDatum()
        )
        #expect(a == b)
    }

    // MARK: - 5. MwSt-Satz sichtbar

    @Test func mwstSatzIst19ProzentUndSichtbarAusgewiesen() {
        #expect(AngebotsRenderMapper.mwstSatz == 0.19)
        let args = AngebotsRenderMapper.map(
            basket: vollerKorb(), kunde: "X", projektTitel: "Y", datum: Self.fixDatum()
        )
        #expect(args.totals[1].label == "MwSt. (19 %)")
    }
}
