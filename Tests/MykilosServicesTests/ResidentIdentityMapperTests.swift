import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// Reine Unit-Tests für AirtableClient.mapResidentIdentity (kein Netzwerk/Keychain).
struct ResidentIdentityMapperTests {

    @Test func trefferPerMailLoestHandlesAuf() {
        let records: [[String: AirtableFieldValue]] = [
            ["E-Mail": .string("fremd@mykilos.com")],
            ["E-Mail": .string("johannes@mykilos.com"),
             "Name": .string("Johannes"),
             "Clockodo-User-ID": .number(9001),
             "Airtable-Entwurf-Tabelle": .string("tbl4vZ2UFyeTRD8hd"),
             "_airtableRecordID": .string("recJO")]
        ]
        let handles = AirtableClient.mapResidentIdentity(from: records, matchingEmail: "johannes@mykilos.com")
        #expect(handles != nil)
        #expect(handles?.displayName == "Johannes")
        #expect(handles?.clockodoUserID == "9001")   // number → String
        #expect(handles?.clockodoEntwurfsTabelle == "tbl4vZ2UFyeTRD8hd")
        #expect(handles?.airtableRecordID == "recJO")
    }

    @Test func keinMailTrefferLiefertNil() {
        let records: [[String: AirtableFieldValue]] = [
            ["E-Mail": .string("jemand@mykilos.com"), "Name": .string("Jemand")]
        ]
        #expect(AirtableClient.mapResidentIdentity(from: records, matchingEmail: "niemand@mykilos.com") == nil)
    }

    // KRITIKER-AUFLAGE: eine Zeile MIT passender Mail aber OHNE clockodo-Feld darf
    // NICHT verworfen werden — der guard steht auf dem Mail-Treffer, nie auf Handle-Präsenz.
    @Test func mailTrefferOhneClockodoFeldWirdNichtVerworfen() {
        let records: [[String: AirtableFieldValue]] = [
            ["E-Mail": .string("johannes@mykilos.com"), "Name": .string("Johannes")]
        ]
        let handles = AirtableClient.mapResidentIdentity(from: records, matchingEmail: "johannes@mykilos.com")
        #expect(handles != nil)                       // Ausweis bleibt bestehen
        #expect(handles?.clockodoUserID == nil)       // Handle nur leer, kein Crash, kein nil-Record
        #expect(handles?.displayName == "Johannes")
    }

    @Test func mailVergleichIstCaseInsensitiv() {
        let records: [[String: AirtableFieldValue]] = [
            ["E-Mail": .string("Johannes@MykilOS.com"), "Name": .string("Johannes")]
        ]
        // Angefragt in Kleinschreibung, Zeile gemischt → matcht.
        let handles = AirtableClient.mapResidentIdentity(from: records, matchingEmail: "johannes@mykilos.com")
        #expect(handles != nil)
    }

    // Clockodo-User-ID kann als string ODER als number kommen — beide korrekt.
    @Test func clockodoUserIDAlsStringWieAlsNumber() {
        let alsString: [[String: AirtableFieldValue]] = [
            ["E-Mail": .string("a@mykilos.com"), "Clockodo-User-ID": .string("777")]
        ]
        #expect(AirtableClient.mapResidentIdentity(from: alsString, matchingEmail: "a@mykilos.com")?.clockodoUserID == "777")

        let alsNumber: [[String: AirtableFieldValue]] = [
            ["E-Mail": .string("a@mykilos.com"), "Clockodo-User-ID": .number(777)]
        ]
        #expect(AirtableClient.mapResidentIdentity(from: alsNumber, matchingEmail: "a@mykilos.com")?.clockodoUserID == "777")
    }

    // Feldnamen-Kandidaten: "E-Mail" vs "Email" — beide matchen.
    @Test func emailFeldnameKandidatenBeideMatchen() {
        let mitBindestrich: [[String: AirtableFieldValue]] = [["E-Mail": .string("x@mykilos.com")]]
        #expect(AirtableClient.mapResidentIdentity(from: mitBindestrich, matchingEmail: "x@mykilos.com") != nil)

        let ohneBindestrich: [[String: AirtableFieldValue]] = [["Email": .string("x@mykilos.com")]]
        #expect(AirtableClient.mapResidentIdentity(from: ohneBindestrich, matchingEmail: "x@mykilos.com") != nil)
    }

    // Leere Mail wird nie zum Schlüssel — auch nicht wenn eine Zeile ein leeres Mail-Feld hat.
    @Test func leereMailWirdNieSchluessel() {
        let records: [[String: AirtableFieldValue]] = [["E-Mail": .string(""), "Name": .string("Leer")]]
        #expect(AirtableClient.mapResidentIdentity(from: records, matchingEmail: "") == nil)
        #expect(AirtableClient.mapResidentIdentity(from: records, matchingEmail: "   ") == nil)
    }
}
