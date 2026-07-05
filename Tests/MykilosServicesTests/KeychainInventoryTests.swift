import Testing
import Foundation
@testable import MykilosServices

// MARK: - FakeStoredKeyLister
// Kein echtes Keychain im Testlauf — der Fake liefert die Service-Namen, die
// der Test vorgibt (nur Namen, nie Werte).
private struct FakeStoredKeyLister: StoredKeyLister {
    let names: [String]
    func storedServiceNames() -> [String] { names }
}

struct KeychainInventoryTests {

    // MARK: - Klassifizierung persönlich/geteilt

    @Test func klassifizierungIstStabilVierPersoenlichZweiGeteilt() {
        let persoenlich = KeyIntegration.allCases.filter { $0.scope == .persoenlich }
        let geteilt = KeyIntegration.allCases.filter { $0.scope == .geteilt }

        #expect(Set(persoenlich) == [.google, .clockodo, .clickup, .claude])
        #expect(Set(geteilt) == [.airtable, .sevdesk])
        #expect(persoenlich.count == 4)
        #expect(geteilt.count == 2)
    }

    @Test func buildUebernimmtScopeAusIntegration() {
        let items = KeychainInventory.build(
            activeUserID: "user-1",
            storedServiceNames: [],
            connected: [:]
        )
        for item in items {
            #expect(item.scope == item.integration.scope)
        }
    }

    // MARK: - Verwaist-Erkennung (a) nur Fremd-Suffix, aktive userID fehlt

    @Test func verwaistWennNurFremdeUserIDVorhanden() {
        // Nur ein Eintrag unter einer ANDEREN userID, kein aktiver.
        let names = ["com.mykilos6.google.fremde-uuid-999"]
        let items = KeychainInventory.build(
            activeUserID: "aktive-uuid-111",
            storedServiceNames: names,
            connected: [:]
        )
        let google = items.first { $0.integration == .google }
        #expect(google?.isOrphaned == true)
        #expect(google?.orphanHint != nil)
    }

    // MARK: - Verwaist-Erkennung (b) Eintrag unter aktiver userID vorhanden

    @Test func nichtVerwaistWennAktiveUserIDVorhanden() {
        let names = [
            "com.mykilos6.google.aktive-uuid-111",
            "com.mykilos6.google.fremde-uuid-999", // zusätzlich fremd — darf egal sein
        ]
        let items = KeychainInventory.build(
            activeUserID: "aktive-uuid-111",
            storedServiceNames: names,
            connected: [:]
        )
        let google = items.first { $0.integration == .google }
        #expect(google?.isOrphaned == false)
        #expect(google?.orphanHint == nil)
    }

    // MARK: - Verwaist-Erkennung (c) .local / Legacy ohne aktives Suffix

    @Test func localSuffixOhneAktivesWirdAlsVerwaistGeflaggt() {
        // Genau der bekannte Claude-Bug: Store ohne userID → landet unter ".local".
        let names = ["com.mykilos6.claude.local"]
        let items = KeychainInventory.build(
            activeUserID: "aktive-uuid-111",
            storedServiceNames: names,
            connected: [:]
        )
        let claude = items.first { $0.integration == .claude }
        #expect(claude?.isOrphaned == true)
        #expect(claude?.orphanHint?.contains("local") == true)
    }

    @Test func legacyOhneSuffixWirdAlsVerwaistGeflaggt() {
        // Teamweiter Legacy-Eintrag ganz ohne userID-Suffix.
        let names = ["com.mykilos6.airtable"]
        let items = KeychainInventory.build(
            activeUserID: "aktive-uuid-111",
            storedServiceNames: names,
            connected: [:]
        )
        let airtable = items.first { $0.integration == .airtable }
        #expect(airtable?.isOrphaned == true)
        #expect(airtable?.orphanHint != nil)
    }

    // MARK: - Gar kein Eintrag → nicht verwaist (nur schlicht nicht vorhanden)

    @Test func keinEintragBedeutetNichtVerwaist() {
        let items = KeychainInventory.build(
            activeUserID: "aktive-uuid-111",
            storedServiceNames: [],
            connected: [:]
        )
        for item in items {
            #expect(item.isOrphaned == false)
            #expect(item.orphanHint == nil)
        }
    }

    // MARK: - Fremd-Base darf eine andere Integration nicht anfassen

    @Test func fremdeBaseBeeinflusstAndereIntegrationNicht() {
        // Nur ein clickup-Eintrag; google/airtable/… bleiben unberührt.
        let names = ["com.mykilos6.clickup.fremde-uuid-999"]
        let items = KeychainInventory.build(
            activeUserID: "aktive-uuid-111",
            storedServiceNames: names,
            connected: [:]
        )
        let clickup = items.first { $0.integration == .clickup }
        let google = items.first { $0.integration == .google }
        #expect(clickup?.isOrphaned == true)
        #expect(google?.isOrphaned == false) // andere Base — kein Eintrag → nicht verwaist
    }

    // MARK: - connected-Map wird durchgereicht

    @Test func connectedFlagWirdUebernommen() {
        let items = KeychainInventory.build(
            activeUserID: "aktive-uuid-111",
            storedServiceNames: ["com.mykilos6.google.aktive-uuid-111"],
            connected: [.google: true, .airtable: false]
        )
        #expect(items.first { $0.integration == .google }?.connected == true)
        #expect(items.first { $0.integration == .airtable }?.connected == false)
        // Fehlender Eintrag in der Map → false (Default).
        #expect(items.first { $0.integration == .claude }?.connected == false)
    }

    @Test func buildLiefertGenauSechsEintraege() {
        let items = KeychainInventory.build(
            activeUserID: "x",
            storedServiceNames: [],
            connected: [:]
        )
        #expect(items.count == 6)
        #expect(Set(items.map(\.integration)) == Set(KeyIntegration.allCases))
    }

    // MARK: - Kein Secret-Feld: die API reicht niemals Werte durch

    @Test func inventarItemTraegtKeinenSecretWert() {
        // Strukturbeweis: KeyInventoryItem lässt sich vollständig OHNE jeden
        // Secret-Wert konstruieren — es gibt kein solches Feld. Die StoredKeyLister-
        // Naht liefert ausschließlich Service-NAMEN, nie Werte.
        let lister = FakeStoredKeyLister(names: ["com.mykilos6.google.aktive-uuid-111"])
        let items = KeychainInventory.build(
            activeUserID: "aktive-uuid-111",
            storedServiceNames: lister.storedServiceNames(),
            connected: [.google: true]
        )
        let item = items.first { $0.integration == .google }
        #expect(item != nil)
        // Nur Status/Metadaten sind erreichbar — persönliche Felder-Zusicherung.
        #expect(item?.connected == true)
        #expect(item?.scope == .persoenlich)
        // Der Lister-Rückgabewert enthält nur Namen mit dem erwarteten Präfix.
        for name in lister.storedServiceNames() {
            #expect(name.hasPrefix("com.mykilos6."))
        }
    }
}
