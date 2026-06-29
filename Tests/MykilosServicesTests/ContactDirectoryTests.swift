import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

// MARK: - S13: Airtable-Kontaktverzeichnis (lookup_kontakt)

struct ContactDirectoryTests {

    private func sample() -> [StudioContact] {
        [StudioContact(id: "1", name: "Sinem Cirnavuk", email: "s@example.com",
                       telefon: "+49 175 0000", adresse: "Siebenbrüderweide 9, Hamburg",
                       projekt: "2026-015", kategorie: "Kunde"),
         StudioContact(id: "2", name: "Mario Weck", organisation: "PSLab",
                       email: "m.weck@pslab.de", telefon: "+49 171 264",
                       adresse: "20A Wolframstrasse, Stuttgart", kategorie: "Lieferant"),
         StudioContact(id: "3", name: "Holger Adickes", telefon: "+49 175 8233")]
    }

    // MARK: mapContacts (Airtable → Domain)

    @Test func mapContactsZiehtNurGesetzteFelder() {
        let records: [[String: AirtableFieldValue]] = [
            ["Name": .string("Mario Weck"), "Organisation": .string("PSLab"),
             "E-Mail": .string("m.weck@pslab.de"), "Telefon": .string("+49171"),
             "Adresse": .string("Wolframstrasse 20A"), "Projekt": .string("2026-009")],
            ["Name": .string("  ")],                       // leer → verworfen
            ["Organisation": .string("ohne Name")],        // kein Name → verworfen
            ["Name": .string("Nur Name")],
        ]
        let contacts = AirtableClient.mapContacts(from: records)
        #expect(contacts.count == 2)
        let weck = contacts.first { $0.name == "Mario Weck" }
        #expect(weck?.organisation == "PSLab")
        #expect(weck?.adresse == "Wolframstrasse 20A")
        #expect(weck?.projekt == "2026-009")
        let nur = contacts.first { $0.name == "Nur Name" }
        #expect(nur?.telefon == nil)
        #expect(nur?.adresse == nil)
    }

    // MARK: ContactDirectory.search

    @Test func sucheFindetPerNameFirmaProjekt() {
        let dir = ContactDirectory(contacts: sample())
        #expect(dir.search("cirnavuk").first?.name == "Sinem Cirnavuk")
        #expect(dir.search("pslab").first?.name == "Mario Weck")       // Organisation
        #expect(dir.search("2026-015").first?.name == "Sinem Cirnavuk") // Projekt
        #expect(dir.search("gibtsnicht").isEmpty)
        #expect(dir.search("   ").isEmpty)
    }

    @Test func exakterNameRankedZuerst() {
        let dir = ContactDirectory(contacts: [
            StudioContact(id: "a", name: "Mario Weckmann"),
            StudioContact(id: "b", name: "Mario Weck"),
        ])
        #expect(dir.search("Mario Weck").first?.name == "Mario Weck")  // exakt vor Präfix
    }

    // MARK: Tool über die Registry

    @Test func lookupKontaktToolLiefertAdresse() async {
        let reg = AssistantToolRegistry.standard(contactDirectory: ContactDirectory(contacts: sample()))
        let r = await reg.run(name: "lookup_kontakt", inputJSON: Data(#"{"query":"Cirnavuk"}"#.utf8))
        #expect(r.isError == false)
        #expect(r.text.contains("Siebenbrüderweide 9"))
        #expect(r.text.contains("Sinem Cirnavuk"))
    }

    @Test func lookupKontaktLeerIstFehler() async {
        let reg = AssistantToolRegistry.standard(contactDirectory: ContactDirectory(contacts: sample()))
        let r = await reg.run(name: "lookup_kontakt", inputJSON: Data(#"{"query":""}"#.utf8))
        #expect(r.isError == true)
    }

    @Test func toolFehltOhneDirectory() {
        let reg = AssistantToolRegistry.standard()
        #expect(reg.toolNames.contains("lookup_kontakt") == false)
    }
}
