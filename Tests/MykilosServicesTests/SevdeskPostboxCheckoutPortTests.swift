import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// sevDesk-Postbox-CheckoutPort: append-only Drop in die zwei Airtable-Tabellen,
// idempotent über den Objekt-Hash. Alles mit Fakes — KEIN echter Airtable-Write.
struct SevdeskPostboxCheckoutPortTests {

    // MARK: - Fake (Create + Fetch in einem, spiegelt angelegte Belege in die Fetch-Liste)

    private final class FakeAirtable: AirtableRecordCreating, AirtableFetching, @unchecked Sendable {
        var belege: [[String: AirtableFieldValue]] = []
        var positionen: [[String: AirtableFieldValue]] = []
        var createAufrufe = 0
        private var counter = 0

        func createRecord(baseID: String, table: String, fields: [String: AirtableFieldValue]) async throws -> String {
            createAufrufe += 1
            counter += 1
            let id = "rec\(counter)"
            var mitID = fields
            mitID["_airtableRecordID"] = .string(id)
            if table == "Postbox-Beleg" { belege.append(mitID) } else { positionen.append(mitID) }
            return id
        }

        func fetchRecords(baseID: String, table: String) async throws -> [[String: AirtableFieldValue]] {
            table == "Postbox-Beleg" ? belege : positionen
        }
    }

    private func makeBasket() -> WorkBasket {
        let p1 = BasicPick(
            matrix: .eingangsangebot,
            objektID: CatalogObjectID("pos-1"),
            snapshot: PickSnapshot(
                bezeichnung: "Korpus Ahorn",
                menge: 2,
                ekEinzel: 100,
                vkEinzel: 150,
                attribute: [
                    "artikelnummer": "155.01.595",
                    "originalText": "2 Stk Korpus Ahorn, Art.-Nr. 155.01.595",
                    "einheit": "Stk",
                    "richtung": "eingehend",
                    "quelle": "Tischler-Angebot.pdf",
                ]))
        let p2 = BasicPick(
            matrix: .eingangsangebot,
            objektID: CatalogObjectID("pos-2"),
            snapshot: PickSnapshot(
                bezeichnung: "Beschlagsatz",
                menge: 1,
                vkEinzel: 80,
                attribute: ["richtung": "eingehend"]))
        return WorkBasket(id: WorkBasketID("wb-1"), projektNummer: "2026-015",
                          inhaltsArt: .artikel, picks: [p1, p2])
    }

    private func makePort(_ fake: FakeAirtable) -> SevdeskPostboxCheckoutPort {
        SevdeskPostboxCheckoutPort(
            airtableCreate: fake, airtableFetch: fake,
            jetzt: { Date(timeIntervalSince1970: 1_700_000_000) })
    }

    // MARK: - Drop legt Beleg + Positionen an

    @Test func dropLegtBelegUndPositionenAn() async throws {
        let fake = FakeAirtable()
        let port = makePort(fake)
        let ziel = PortZiel(kind: "postbox", parameter: [
            "belegTyp": "Angebot", "status": "Test", "user": "johannes",
            "lieferant": "Tischlerei Meier",
        ])

        let result = try await port.execute(basket: makeBasket(), ziel: ziel)

        #expect(result.erfolg)
        #expect(fake.belege.count == 1)
        #expect(fake.positionen.count == 2)

        let beleg = fake.belege[0]
        #expect(beleg["Beleg-Typ"]?.stringValue == "Angebot")
        #expect(beleg["Status"]?.stringValue == "Test")
        #expect(beleg["Projekt-Nr"]?.stringValue == "2026-015")
        #expect(beleg["Lieferant"]?.stringValue == "Tischlerei Meier")
        #expect(beleg["Importiert-von"]?.stringValue == "johannes")
        // Netto-Gegenprobe: 2×150 + 1×80 = 380. Brutto/Steuer NICHT gesetzt (sevDesk BOSSMODE).
        #expect(beleg["Netto-Summe"]?.numberValue == 380)
        #expect(beleg["Brutto-Summe"] == nil)

        // Position 1 trägt Art.-Nr. + Original-Text + Einheit + Preise.
        let pos1 = fake.positionen[0]
        #expect(pos1["Titel"]?.stringValue == "Korpus Ahorn")
        #expect(pos1["Artikelnummer"]?.stringValue == "155.01.595")
        #expect(pos1["Einheit"]?.stringValue == "Stk")
        #expect(pos1["Menge"]?.numberValue == 2)
        #expect(pos1["Einzelpreis"]?.numberValue == 150)
        #expect(pos1["Gesamtpreis"]?.numberValue == 300)
        #expect(pos1["Richtung"]?.stringValue == "eingehend")
        // Verlinkt auf den Beleg-Record.
        let belegID = beleg["_airtableRecordID"]?.stringValue
        #expect(pos1["Beleg"] == .array([belegID ?? ""]))
    }

    // MARK: - Idempotenz: zweiter identischer Drop legt nichts Neues an
    // (Analog Cold-Start: eine NEUE Port-Instanz sieht den bereits abgelegten Beleg
    // über den Objekt-Hash und dedupliziert — der Hash ist stabil über Instanzen.)

    @Test func zweiterIdentischerDropIstIdempotent() async throws {
        let fake = FakeAirtable()
        let ziel = PortZiel(kind: "postbox", parameter: ["belegTyp": "Angebot", "user": "johannes"])

        let r1 = try await makePort(fake).execute(basket: makeBasket(), ziel: ziel)
        let belegeNach1 = fake.belege.count
        let positionenNach1 = fake.positionen.count

        // Frische Port-Instanz, gleicher Korb → muss den bestehenden Beleg erkennen.
        let r2 = try await makePort(fake).execute(basket: makeBasket(), ziel: ziel)

        #expect(fake.belege.count == belegeNach1)          // KEIN neuer Beleg
        #expect(fake.positionen.count == positionenNach1)  // KEINE neuen Positionen
        #expect(r2.erfolg)
        #expect(r2.referenz == r1.referenz)                // gleicher Record
        #expect(r2.meldung?.contains("idempotent") == true)
    }

    // MARK: - Objekt-Hash ist deterministisch & inhaltsabhängig

    @Test func objektHashStabilUndInhaltsabhaengig() {
        let a = makeBasket()
        #expect(SevdeskPostboxCheckoutPort.objektHash(a) == SevdeskPostboxCheckoutPort.objektHash(a))

        let anders = WorkBasket(id: WorkBasketID("wb-2"), projektNummer: "2026-099",
                                inhaltsArt: .artikel, picks: a.picks)
        #expect(SevdeskPostboxCheckoutPort.objektHash(a) != SevdeskPostboxCheckoutPort.objektHash(anders))
    }

    // MARK: - Vorschau schreibt nichts und nennt sevDesk-Hoheit

    @Test func vorschauSchreibtNichtsUndWarntVorHoheit() async throws {
        let fake = FakeAirtable()
        let preview = try await makePort(fake).preview(
            basket: makeBasket(), ziel: PortZiel(kind: "postbox", parameter: ["belegTyp": "Angebot"]))
        #expect(fake.belege.isEmpty)
        #expect(fake.positionen.isEmpty)
        #expect(preview.zusammenfassung.contains("2 Positionen"))
        #expect(preview.warnungen.contains { $0.contains("sevDesk") })
    }
}
