import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// Onboarding-Plan Ebene 2: Admin erstellt, neuer User öffnet eine .mykinvite-Datei — end-to-end
// über die echten AirtableCredentialsStoring-Slots (kein echtes Keychain/Netzwerk, InMemory-Fake
// wie in AirtableClientTests).
struct MykInviteServiceTests {

    @Test func einladungErstellenUndOeffnenUebertraegtDieAirtableZugangsdaten() throws {
        let adminStore = InMemoryAirtableCredentialsStore(
            credentials: AirtableCredentials(pat: "patAdmin123", baseID: "appMastermind")
        )
        let daten = try MykInviteService.einladungErstellen(airtableCredentials: adminStore, passwort: "hunter2")

        let neuerUserStore = InMemoryAirtableCredentialsStore()
        try MykInviteService.einladungOeffnen(daten: daten, passwort: "hunter2", airtableCredentials: neuerUserStore)

        let uebernommen = try neuerUserStore.load()
        #expect(uebernommen?.pat == "patAdmin123")
        #expect(uebernommen?.baseID == "appMastermind")
    }

    @Test func einladungErstellenOhneVerbundeneZugangsdatenWirft() throws {
        let leererStore = InMemoryAirtableCredentialsStore()
        #expect(throws: MykInviteError.keineZugangsdatenVerbunden) {
            _ = try MykInviteService.einladungErstellen(airtableCredentials: leererStore, passwort: "egal")
        }
    }

    @Test func einladungOeffnenMitFalschemPasswortAendertDenZielStoreNicht() throws {
        let adminStore = InMemoryAirtableCredentialsStore(
            credentials: AirtableCredentials(pat: "patX", baseID: "appY")
        )
        let daten = try MykInviteService.einladungErstellen(airtableCredentials: adminStore, passwort: "richtig")

        let neuerUserStore = InMemoryAirtableCredentialsStore()
        #expect(throws: MykInviteError.falschesPasswort) {
            try MykInviteService.einladungOeffnen(daten: daten, passwort: "falsch", airtableCredentials: neuerUserStore)
        }
        #expect(try neuerUserStore.load() == nil)   // nichts geschrieben bei Fehlschlag
    }

    @Test func gueltigTageNilErzeugtEinladungOhneAblauf() throws {
        let adminStore = InMemoryAirtableCredentialsStore(
            credentials: AirtableCredentials(pat: "patX", baseID: "appY")
        )
        let daten = try MykInviteService.einladungErstellen(
            airtableCredentials: adminStore, passwort: "geheim", gueltigTage: nil)
        let neuerUserStore = InMemoryAirtableCredentialsStore()
        // Darf auch weit in der Zukunft noch funktionieren (kein Ablaufdatum gesetzt).
        try MykInviteService.einladungOeffnen(daten: daten, passwort: "geheim", airtableCredentials: neuerUserStore)
        #expect(try neuerUserStore.load()?.pat == "patX")
    }

    // MARK: - Mehr-Key-Bündel + Metadaten (Johannes 2026-07-07)

    @Test func generischesBuendelUeberlebtVerschluesselnUndLesen() throws {
        let werte = [
            MykInvitePayload.Schluessel.airtablePAT: "pat1",
            MykInvitePayload.Schluessel.airtableBaseID: "app1",
            MykInvitePayload.Schluessel.googleClientID: "cid.apps.googleusercontent.com",
            MykInvitePayload.Schluessel.googleClientSecret: "gsecret",
            MykInvitePayload.Schluessel.claudeAPIKey: "sk-ant-team",
            MykInvitePayload.Schluessel.claudeModel: "claude-sonnet-4-6"
        ]
        let daten = try MykInviteService.einladungErstellen(
            werte: werte,
            eingeladeneEmail: "  neu@mykilos.com  ",
            eingeladenerName: "Neuer Kollege",
            passwort: "s3hr-l4ng-und-zuf4llig"
        )
        let payload = try MykInviteService.einladungLesen(daten: daten, passwort: "s3hr-l4ng-und-zuf4llig")
        #expect(payload.werte == werte)
        // Metadaten getrimmt und mit-verschlüsselt (kein Klartext-Leak auf der Datei).
        #expect(payload.eingeladeneEmail == "neu@mykilos.com")
        #expect(payload.eingeladenerName == "Neuer Kollege")
    }

    @Test func leeresBuendelWirft() throws {
        #expect(throws: MykInviteError.keineZugangsdatenVerbunden) {
            _ = try MykInviteService.einladungErstellen(werte: [:], passwort: "egal")
        }
    }

    @Test func lesenMitFalschemPasswortWirft() throws {
        let daten = try MykInviteService.einladungErstellen(
            werte: [MykInvitePayload.Schluessel.claudeAPIKey: "sk-ant"], passwort: "richtig")
        #expect(throws: MykInviteError.falschesPasswort) {
            _ = try MykInviteService.einladungLesen(daten: daten, passwort: "falsch")
        }
    }

    @Test func abgelaufeneEinladungWirftBeimLesen() throws {
        // gueltigTage negativ → Ablauf in der Vergangenheit → .abgelaufen beim Lesen.
        let daten = try MykInviteService.einladungErstellen(
            werte: [MykInvitePayload.Schluessel.airtablePAT: "p"], passwort: "pw", gueltigTage: -1)
        #expect(throws: MykInviteError.abgelaufen) {
            _ = try MykInviteService.einladungLesen(daten: daten, passwort: "pw")
        }
    }
}
