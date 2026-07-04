import XCTest
@testable import MykilosKalkulationsCore

// Tests für den Pass-2-Feld-Extraktor (Netto-Preis + Selbstbeweis-Konfidenz).
// Alle Fixtures sind SYNTHETISCH: echte Struktur dreier Lieferanten-Layouts
// nachgebaut, aber erfundene Preise/Namen — echte EK-PDFs bleiben lokal
// (Geschäftsgeheimnis). Die echte 815er-Gegenprobe läuft env-gated separat
// (OfferPositionGateTests).
final class OfferPositionExtractorTests: XCTestCase {

    private typealias X = OfferPositionExtractor

    // MARK: - Betrags-Parser

    func testGermanAmountsInReihenfolge() {
        let amounts = X.germanAmounts(in: "Position 1.234,56 dann 60,00 und 5.911,70 Ende")
        XCTAssertEqual(amounts, [Decimal(string: "1234.56"), Decimal(string: "60.00"), Decimal(string: "5911.70")])
    }

    func testGermanAmountIgnoriertNummernOhneNachkommastellen() {
        // "2cm", "35mm", "2024" dürfen keine Beträge sein.
        XCTAssertEqual(X.germanAmounts(in: "2cm Quarzit 2024 D=35mm 350,00"), [Decimal(string: "350.00")])
    }

    func testDecimalFromGerman() {
        XCTAssertEqual(X.decimal(fromGerman: "5.911,70"), Decimal(string: "5911.70"))
        XCTAssertEqual(X.decimal(fromGerman: "56,00"), Decimal(string: "56.00"))
    }

    // MARK: - Selbstbeweis-Ampel

    func testStueckEinsFallZweiGleicheBetraege_Gruen() {
        // Naturstein-typisch: "1 1 Stck. <Titel> E.P. G.P." mit E.P. == G.P.
        let text = "1 1 Stck. Kuechenarbeitsplatte 1.234,56 1.234,56 nach Aufmass liefern und einbauen 3,50 m2 Material 4,00 m Kante"
        let p = X.extract(fromBlock: text)
        XCTAssertEqual(p.confidence, .green)
        XCTAssertEqual(p.netPrice, Decimal(string: "1234.56"))
        XCTAssertEqual(p.areaM2, 3.5)
        XCTAssertEqual(p.lengthM, 4.0)
    }

    func testMengeMalEinzelGleichGesamt_EinzelIstNetto_Gruen() {
        // Korpus-Semantik: price_net = Einzelpreis (E.P.), nicht die Zeilensumme.
        let text = "5 Stk Griffleiste Alu 12,00 60,00"
        let p = X.extract(fromBlock: text)
        XCTAssertEqual(p.confidence, .green)
        XCTAssertEqual(p.quantity, 5)
        XCTAssertEqual(p.netPrice, Decimal(string: "12.00"))   // E.P.
        XCTAssertEqual(p.lineTotal, Decimal(string: "60.00"))  // G.P.
    }

    func testBetragOhneTausenderpunkt() {
        // Regressionsschutz: "2995,00" darf nicht als "995,00" verstümmelt werden.
        XCTAssertEqual(X.germanAmounts(in: "Waschtisch 2995,00 Sondermass"),
                       [Decimal(string: "2995.00")])
    }

    func testMengeMitEinheitIstKeinBetrag() {
        // Sondierung 2026-07-04: "1,00 Stk", "4,97 m2", "10,15 m" sind MASSE,
        // keine Beträge — sonst beweist der Selbstbeweis Mengen (netto=1-Bug).
        let amounts = X.germanAmounts(in: "1,00 Stk. Arbeitsplatte 4,97 m2 10,15 m 5.911,70 5.911,70")
        XCTAssertEqual(amounts, [Decimal(string: "5911.70"), Decimal(string: "5911.70")])
    }

    func testNatursteinPositionMitMengenzeilenBleibtEinePosition() {
        // Reale Struktur (synthetisch): eine Position mit vielen "N Stk"-Unterzeilen
        // darf NICHT in Splitter zerfallen — netto = Positionspreis, nicht 1/2/3.
        let page = """
        1 1 Stck. Küchenarbeitsplatte 5.911,70 5.911,70 nach Aufmaß liefern
        2 Stk Bohrung D=35mm
        1 Stk Ausklinkung zweiseitig gesägt
        2 Stk Becken werkseits anbauen
        1 Stk Pflegemittel
        """
        let positions = X.extractPositions(fromPageText: page)
        XCTAssertEqual(positions.count, 1)
        XCTAssertEqual(positions[0].netPrice, Decimal(string: "5911.70"))
        XCTAssertEqual(positions[0].confidence, .green)
    }

    func testRabattLayout_NettoUndListe_Gruen() {
        // "1,0 Stk 250,00 20,00% 200,00 200,00 €" → netto 200 (nach Rabatt), Liste 250.
        let text = "2 Aufmaß pauschal Raum Hamburg 1,0 Stk 250,00 20,00% 200,00 200,00 €"
        let p = X.extract(fromBlock: text)
        XCTAssertEqual(p.confidence, .green)
        XCTAssertEqual(p.netPrice, Decimal(string: "200.00"))   // was gezahlt wird
        XCTAssertEqual(p.listPrice, Decimal(string: "250.00"))  // vor Rabatt
    }

    func testKeinFalscherRabattBeiMwStProzent() {
        // "19,00 %" ist MwSt, kein Zeilenrabatt — darf kein listPrice setzen.
        let p = X.extract(fromBlock: "1 Stk Sockelblende 120,00 120,00 zzgl. 19,00 % MwSt")
        XCTAssertNil(p.listPrice)
        XCTAssertEqual(p.netPrice, Decimal(string: "120.00"))
    }

    func testPauschaleOhnePruefbareRechnung_Amber() {
        let text = "1 Pauschale Lieferung und Anfahrt 350,00"
        let p = X.extract(fromBlock: text)
        XCTAssertEqual(p.confidence, .amber)
        XCTAssertEqual(p.netPrice, Decimal(string: "350.00"))
    }

    func testKeinBetrag_Rot() {
        let p = X.extract(fromBlock: "Zwischensumme wird auf Folgeseite ausgewiesen")
        XCTAssertEqual(p.confidence, .red)
        XCTAssertNil(p.netPrice)
    }

    func testErsterBetragBeiFehlendemBeweis() {
        // Ohne passende Menge: Positionspreis = erster Betrag (steht vor MwSt/Summe).
        let text = "Sonderanfertigung Nische 1.850,00 zzgl. 19,00 % MwSt 351,50 Gesamt 2.201,50"
        let p = X.extract(fromBlock: text)
        XCTAssertEqual(p.netPrice, Decimal(string: "1850.00"))
    }

    // MARK: - Pass 1: Blocking (synthetisch — echte PDFs zum Nachjustieren offen)

    func testBlockingZerlegtMehrerePositionen() {
        // Drei Positionen, je an einem Anker (Nummer + Menge/Titel) startend.
        let page = """
        Angebot Nr. 4711 vom 01.02.2026
        1 1 Stck. Küchenarbeitsplatte Granit 1.234,56 1.234,56 nach Aufmaß
        2 5 Stk Griffleiste Alu 12,00 60,00
        3 1 Pauschale Lieferung und Montage 350,00 350,00
        Nettobetrag 1.644,56
        """
        let positions = X.extractPositions(fromPageText: page)
        XCTAssertEqual(positions.count, 3)
        XCTAssertEqual(positions[0].netPrice, Decimal(string: "1234.56"))
        XCTAssertEqual(positions[1].netPrice, Decimal(string: "12.00"))
        XCTAssertEqual(positions[2].netPrice, Decimal(string: "350.00"))
    }

    func testBlockingOhneAnkerGibtGanzenTextAlsEinenBlock() {
        let positions = X.extractPositions(fromPageText: "Sonderposten 1.850,00 pauschal")
        XCTAssertEqual(positions.count, 1)
        XCTAssertEqual(positions[0].netPrice, Decimal(string: "1850.00"))
    }

    // MARK: - Bauteil-Klassifikation (synthetisch, Küchen-Domäne)

    func testKlassifikatorKategorien() {
        typealias C = OfferPositionClassifier
        XCTAssertEqual(C.classify(text: "Küchenarbeitsplatte 2cm Quarzit TAJ MAHAL"), .stoneCountertop)
        XCTAssertEqual(C.classify(text: "Fronten der Schubkästen mit Auszug"), .drawerAddon)
        XCTAssertEqual(C.classify(text: "1 St Küchenhochschrank, ca. 2269x2850mm"), .tallCabinetBlock)
        XCTAssertEqual(C.classify(text: "Kochinsel Korpus lackiert"), .island)
        XCTAssertEqual(C.classify(text: "Inselarbeitsplatte Naturstein"), .stoneCountertop) // Stein vor Insel
        XCTAssertEqual(C.classify(text: "Bora Kochfeld flächenbündig"), .applianceScope)
        XCTAssertEqual(C.classify(text: "1 St Küchenzeile Unterschrank Korpus"), .baseCabinetRun)
        XCTAssertEqual(C.classify(text: "Lieferung und Montage der gesamten Küche"), .installation)
        XCTAssertEqual(C.classify(text: "An- und Abfahrt Fahrkostenpauschale"), .projectLogistics)
        XCTAssertEqual(C.classify(text: "Irgendwas völlig Unbekanntes XYZ"), .other)
    }

    func testExtractSetztKomponentenTyp() {
        let p = X.extract(fromBlock: "1 1 Stck. Küchenarbeitsplatte Granit 1.234,56 1.234,56")
        XCTAssertEqual(p.componentType, .stoneCountertop)
    }

    func testAlternativePositionWirdMarkiert() {
        let p = X.extract(fromBlock: "2 wie Pos.1, jedoch Materialvariante Eiche 5.174,65 5.174,65")
        XCTAssertTrue(p.isAlternative)
        let normal = X.extract(fromBlock: "1 1 Stck. Küchenarbeitsplatte 1.234,56 1.234,56")
        XCTAssertFalse(normal.isAlternative)
    }

    func testHeaderNoiseWirdGefiltert() {
        // Seitenkopf mit Seitenzahl+Adresse: darf keine Position werden.
        let page = """
        9 Werkstatt für Innenausbau | Rellinger Weg 2-4 375,00 375,00
        1 1 Stck. Küchenarbeitsplatte Granit 1.234,56 1.234,56
        """
        let positions = X.extractPositions(fromPageText: page)
        XCTAssertEqual(positions.count, 1)
        XCTAssertEqual(positions[0].netPrice, Decimal(string: "1234.56"))
    }

    // MARK: - selfProof direkt

    func testSelfProofBrauchtMindestensZweiBetraege() {
        XCTAssertNil(X.selfProof(amounts: [Decimal(string: "100.00")!], quantities: [1]))
    }

    func testSelfProofToleranzEinProzent() {
        // 3 × 33,34 = 100,02 ~ 100,00 (0,02 % Abweichung) → beweist.
        let proof = X.selfProof(amounts: [Decimal(string: "33.34")!, Decimal(string: "100.00")!], quantities: [3])
        XCTAssertEqual(proof?.gesamt, Decimal(string: "100.00"))
    }
}
