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
}
