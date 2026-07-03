import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

struct ClockodoAdapterWriterTests {

    // Montag, 2026-06-29, 09:00-11:30 Uhr (Europe/Berlin) → KW 27, 2.5 h.
    private func segment(
        projektNummer: String = "2026-015", projektTitel: String = "Hustadt", kostenstelle: String = "Planung"
    ) -> TimeSegment {
        var berlin = Calendar(identifier: .iso8601)
        berlin.timeZone = TimeZone(identifier: "Europe/Berlin")!
        let start = berlin.date(from: DateComponents(year: 2026, month: 6, day: 29, hour: 9, minute: 0))!
        let ende = berlin.date(from: DateComponents(year: 2026, month: 6, day: 29, hour: 11, minute: 30))!
        return TimeSegment(
            projektNummer: projektNummer, projektTitel: projektTitel, kostenstelle: kostenstelle,
            startedAt: start, endedAt: ende, seconds: ende.timeIntervalSince(start))
    }

    @Test func mappedAlleGrunddatenKorrekt() {
        let felder = ClockodoAdapterWriter.felder(fuer: segment(), mitarbeiter: "Johannes")
        #expect(felder[ClockodoAdapterWriter.feldProjektnummer]?.stringValue == "2026-015")
        #expect(felder[ClockodoAdapterWriter.feldProjektTitel]?.stringValue == "Hustadt")
        #expect(felder[ClockodoAdapterWriter.feldKostenstelle]?.stringValue == "Planung")
        #expect(felder[ClockodoAdapterWriter.feldMitarbeiter]?.stringValue == "Johannes")
        #expect(felder[ClockodoAdapterWriter.feldStatus]?.stringValue == "Vorgebucht")
        #expect(felder[ClockodoAdapterWriter.feldQuelle]?.stringValue == "Timer")
    }

    @Test func datumIstISOFormatiertOhneUhrzeit() {
        let felder = ClockodoAdapterWriter.felder(fuer: segment(), mitarbeiter: "Jilliana")
        #expect(felder[ClockodoAdapterWriter.feldDatum]?.stringValue == "2026-06-29")
    }

    @Test func kalenderwocheWirdKorrektBerechnet() {
        // 2026-06-29 ist ein Montag in KW 27 (ISO-8601).
        let felder = ClockodoAdapterWriter.felder(fuer: segment(), mitarbeiter: "Daniel")
        #expect(felder[ClockodoAdapterWriter.feldKW]?.numberValue == 27)
    }

    @Test func dauerWirdInStundenGerundetAufZweiNachkommastellen() {
        let felder = ClockodoAdapterWriter.felder(fuer: segment(), mitarbeiter: "Frauke")
        #expect(felder[ClockodoAdapterWriter.feldDauerH]?.numberValue == 2.5)
    }

    @Test func startUndEndeSindGueltigeISO8601Zeitstempel() {
        let felder = ClockodoAdapterWriter.felder(fuer: segment(), mitarbeiter: "Johannes")
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        #expect(felder[ClockodoAdapterWriter.feldStart]?.stringValue.flatMap { iso.date(from: $0) } != nil)
        #expect(felder[ClockodoAdapterWriter.feldEnde]?.stringValue.flatMap { iso.date(from: $0) } != nil)
    }

    @Test func unterschiedlicheSegmenteErzeugenUnterschiedlicheFelder() {
        let a = ClockodoAdapterWriter.felder(fuer: segment(kostenstelle: "Beratung"), mitarbeiter: "Johannes")
        let b = ClockodoAdapterWriter.felder(fuer: segment(kostenstelle: "Montage"), mitarbeiter: "Johannes")
        #expect(a[ClockodoAdapterWriter.feldKostenstelle]?.stringValue != b[ClockodoAdapterWriter.feldKostenstelle]?.stringValue)
    }

    // MARK: - Schreibpfad (Fake, kein Netzwerk)

    private struct FakeCreator: AirtableRecordCreating {
        let recordID: String
        func createRecord(baseID: String, table: String, fields: [String: AirtableFieldValue]) async throws -> String {
            recordID
        }
    }

    @Test func schreibeVorbuchungRuftCreatorMitRichtigerBaseUndTabelleAuf() async throws {
        let writer = ClockodoAdapterWriter(creator: FakeCreator(recordID: "recTEST123"))
        let id = try await writer.schreibeVorbuchung(segment(), mitarbeiter: "Johannes")
        #expect(id == "recTEST123")
    }

    private struct ThrowingCreator: AirtableRecordCreating {
        func createRecord(baseID: String, table: String, fields: [String: AirtableFieldValue]) async throws -> String {
            throw AirtableError.notConnected
        }
    }

    @Test func schreibeVorbuchungWirftBeiNetzwerkfehlerWeiter() async {
        let writer = ClockodoAdapterWriter(creator: ThrowingCreator())
        await #expect(throws: (any Error).self) {
            try await writer.schreibeVorbuchung(segment(), mitarbeiter: "Johannes")
        }
    }

    @Test func baseUndTabelleStehenAufDerWhitelist() {
        #expect(AirtableClient.isWritable(baseID: ClockodoAdapterWriter.baseID, table: ClockodoAdapterWriter.table))
    }
}
