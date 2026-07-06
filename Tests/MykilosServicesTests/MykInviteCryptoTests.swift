import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// Onboarding-Plan Ebene 2 (.mykinvite): reine Krypto-/Format-Tests, kein Netzwerk/Keychain.
struct MykInviteCryptoTests {

    @Test func verschluesselnUndEntschluesselnMitRichtigemPasswortLiefertIdentischenPayload() throws {
        let payload = MykInvitePayload(werte: [
            MykInvitePayload.Schluessel.airtablePAT: "patABC123",
            MykInvitePayload.Schluessel.airtableBaseID: "appXYZ789"
        ])
        let daten = try MykInviteCrypto.verschluesseln(payload, passwort: "korrekt-pferd-batterie")
        let entschluesselt = try MykInviteCrypto.entschluesseln(daten, passwort: "korrekt-pferd-batterie")
        #expect(entschluesselt == payload)
    }

    @Test func falschesPasswortWirftFehler() throws {
        let payload = MykInvitePayload(werte: [MykInvitePayload.Schluessel.airtablePAT: "patABC123"])
        let daten = try MykInviteCrypto.verschluesseln(payload, passwort: "richtig")
        #expect(throws: MykInviteError.falschesPasswort) {
            _ = try MykInviteCrypto.entschluesseln(daten, passwort: "falsch")
        }
    }

    @Test func kaputteDatenWerfenFehlerStattAbsturz() throws {
        let muell = Data((0..<40).map { UInt8($0) })
        #expect(throws: (any Error).self) {
            _ = try MykInviteCrypto.entschluesseln(muell, passwort: "irgendwas")
        }
    }

    @Test func zuKurzeDatenWerfenKaputteDatei() throws {
        let zuKurz = Data([1, 2, 3])
        #expect(throws: MykInviteError.kaputteDatei) {
            _ = try MykInviteCrypto.entschluesseln(zuKurz, passwort: "irgendwas")
        }
    }

    @Test func abgelaufeneEinladungWirftAbgelaufenTrotzRichtigemPasswort() throws {
        let vergangenheit = Date().addingTimeInterval(-3600)
        let payload = MykInvitePayload(werte: [:], ablaufAm: vergangenheit)
        let daten = try MykInviteCrypto.verschluesseln(payload, passwort: "geheim")
        #expect(throws: MykInviteError.abgelaufen) {
            _ = try MykInviteCrypto.entschluesseln(daten, passwort: "geheim")
        }
    }

    @Test func nichtAbgelaufeneEinladungLaesstSichLesen() throws {
        let zukunft = Date().addingTimeInterval(3600)
        let payload = MykInvitePayload(werte: ["x": "y"], ablaufAm: zukunft)
        let daten = try MykInviteCrypto.verschluesseln(payload, passwort: "geheim")
        let gelesen = try MykInviteCrypto.entschluesseln(daten, passwort: "geheim")
        #expect(gelesen.werte["x"] == "y")
    }

    @Test func zweiVerschluesselungenDesselbenPayloadsErzeugenUnterschiedlicheBytes() throws {
        // Zufälliges Salt + Nonce → nie dieselben Bytes, selbst bei identischem Payload/Passwort.
        let payload = MykInvitePayload(werte: ["a": "b"])
        let d1 = try MykInviteCrypto.verschluesseln(payload, passwort: "geheim")
        let d2 = try MykInviteCrypto.verschluesseln(payload, passwort: "geheim")
        #expect(d1 != d2)
        // Trotzdem entschlüsseln beide zum selben Klartext.
        #expect(try MykInviteCrypto.entschluesseln(d1, passwort: "geheim") == payload)
        #expect(try MykInviteCrypto.entschluesseln(d2, passwort: "geheim") == payload)
    }
}
