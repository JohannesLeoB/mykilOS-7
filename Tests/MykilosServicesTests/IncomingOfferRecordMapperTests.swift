import Testing
import Foundation
@testable import MykilosServices
import MykilosKalkulationsCore

// MARK: - feat/tischler-predictor · Phase 2
// Beweist den Lese-Adapter gegen das ECHTE `Eingehende-Angebote`-Schema:
// reale Feldnamen werden korrekt gemappt, der Workflow-Status (Neu/Verarbeitet/
// Archiviert) erzeugt bewusst KEIN Learning-Signal (Promotion nur via Review-Gate),
// und unvollständige Zeilen werden übersprungen statt erfunden.
struct IncomingOfferRecordMapperTests {

    private func row(_ pairs: [String: AirtableFieldValue]) -> [String: AirtableFieldValue] { pairs }

    @Test func mapsRealSchemaFields() {
        let records = [row([
            "_airtableRecordID": .string("rec123"),
            "Richtung": .string("eingehend"),
            "Lieferant": .string("Weichsel78"),
            "Netto-Summe": .number(12_926),
            "Projekt-Nr": .string("2026-015"),
            "Datei-Name": .string("Angebot_Kueche.pdf"),
            "Importiert-am": .string("2026-06-29T08:00:00.000Z")
        ])]

        let entries = IncomingOfferRecordMapper.map(from: records)
        #expect(entries.count == 1)
        let e = entries[0]
        #expect(e.airtableRecordID == "rec123")
        #expect(e.kind == .eingehend)
        #expect(e.partner == "Weichsel78")
        #expect(e.nettoEur == Decimal(12_926))
        #expect(e.projekt == "2026-015")
        #expect(e.leistungsbeschreibung == "Angebot_Kueche.pdf")
        #expect(e.datum == "2026-06-29T08:00:00.000Z")
    }

    // Der Workflow-Status trägt KEINEN Geschäftsausgang → kein Auto-Lernsignal.
    // syncAirtableOffers würde solche Zeilen als „kein Learning-Signal" überspringen.
    @Test func mappedStatusCarriesNoLearningSignal() {
        let entry = IncomingOfferRecordMapper.map(from: [row([
            "_airtableRecordID": .string("rec1"),
            "Richtung": .string("eingehend"),
            "Lieferant": .string("Stein GmbH"),
            "Netto-Summe": .number(5_000)
        ])])[0]
        #expect(entry.status == .eingegangen)
        #expect(entry.status.learningReason(kind: entry.kind) == nil)
    }

    @Test func skipsRowsMissingMandatoryFields() {
        let records = [
            row(["_airtableRecordID": .string("rec1"), "Lieferant": .string("X")]),          // keine Richtung
            row(["_airtableRecordID": .string("rec2"), "Richtung": .string("eingehend")]),   // kein Lieferant
            row(["Richtung": .string("eingehend"), "Lieferant": .string("Y")]),              // keine Record-ID
            row(["_airtableRecordID": .string("rec4"), "Richtung": .string("seitwaerts"),    // ungültige Richtung
                 "Lieferant": .string("Z")])
        ]
        #expect(IncomingOfferRecordMapper.map(from: records).isEmpty)
    }

    @Test func mapsAusgehendDirection() {
        let entry = IncomingOfferRecordMapper.map(from: [row([
            "_airtableRecordID": .string("rec9"),
            "Richtung": .string("Ausgehend"),   // Groß-/Kleinschreibung tolerant
            "Lieferant": .string("MYKILOS")
        ])])[0]
        #expect(entry.kind == .ausgehend)
    }
}
