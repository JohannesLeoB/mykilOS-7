import Testing
import Foundation
@testable import MykilosKit

// MARK: - Kontakt + Signatur Tests
// Prüft:
// 1. AirtableContactDraft.update-Intent baut korrekte Felder auf (Mapping-Regressions-Schutz).
// 2. Signatur-Append-Logik (kompakter Pure-Swift-Nachbau der ComposeMailView-Logik).
struct KontaktSignaturTests {

    // MARK: - AirtableContactDraft (update-Intent)

    @Test func updateDraftTraegtAlleFelder() {
        let draft = AirtableContactDraft(
            intent: .update,
            recordID: "recABC123",
            name: "Max Mustermann",
            organisation: "Tischler GmbH",
            email: "max@example.de",
            telefon: "+49 30 1234",
            adresse: "Musterstr. 1, Berlin",
            kategorie: "Lieferant"
        )
        #expect(draft.intent == .update)
        #expect(draft.recordID == "recABC123")
        let fields = draft.airtableFields
        #expect(fields["Name"] == "Max Mustermann")
        #expect(fields["Organisation"] == "Tischler GmbH")
        #expect(fields["E-Mail"] == "max@example.de")
        #expect(fields["Telefon"] == "+49 30 1234")
        #expect(fields["Adresse"] == "Musterstr. 1, Berlin")
        #expect(fields["Kategorie"] == "Lieferant")
    }

    @Test func updateDraftMitNilFeldernLaesstFelderWeg() {
        let draft = AirtableContactDraft(
            intent: .update,
            recordID: "recXYZ",
            name: "Lena Müller"
        )
        let fields = draft.airtableFields
        #expect(fields["Name"] == "Lena Müller")
        #expect(fields["Organisation"] == nil)
        #expect(fields["E-Mail"] == nil)
        // Name muss immer dabei sein
        #expect(fields.keys.contains("Name"))
    }

    @Test func createDraftHatKeineRecordID() {
        let draft = AirtableContactDraft(intent: .create, name: "Neuer Kontakt")
        #expect(draft.intent == .create)
        #expect(draft.recordID == nil)
    }

    @Test func displayNameGibtNamenZurueck() {
        let draft = AirtableContactDraft(intent: .update, recordID: "rec1", name: "Sinem Cirnavuk")
        #expect(draft.displayName == "Sinem Cirnavuk")
    }

    // MARK: - Signatur-Append-Logik
    // Kein echter ComposeMailView-Test (UI-Layer, nicht testbar ohne SwiftUI-Laufzeit).
    // Stattdessen dieselbe Logik als reine Funktion — Regression-Lock für das Verhalten,
    // das Gmail bei API-Entwürfen NICHT selbst tut.

    /// Dieselbe Logik wie `ComposeMailView.effectiveBody`.
    private func effectiveBody(bodyText: String, signature: String, append: Bool) -> String {
        let sig = signature.trimmingCharacters(in: .whitespacesAndNewlines)
        if append && !sig.isEmpty {
            return bodyText.isEmpty ? "\n\n-- \n\(sig)" : "\(bodyText)\n\n-- \n\(sig)"
        }
        return bodyText
    }

    @Test func signaturWirdAngehangen() {
        let result = effectiveBody(bodyText: "Hallo,\nTest.", signature: "Max M.", append: true)
        #expect(result == "Hallo,\nTest.\n\n-- \nMax M.")
    }

    @Test func signaturNichtAngehangen_WennSchalterAus() {
        let result = effectiveBody(bodyText: "Hallo,", signature: "Max M.", append: false)
        #expect(result == "Hallo,")
    }

    @Test func signaturNichtAngehangen_WennLeer() {
        let result = effectiveBody(bodyText: "Hallo,", signature: "   ", append: true)
        #expect(result == "Hallo,")
    }

    @Test func leererBodyMitSignatur() {
        let result = effectiveBody(bodyText: "", signature: "Max M.", append: true)
        #expect(result == "\n\n-- \nMax M.")
    }

    @Test func ohneSignaturBleibtBodyUnveraendert() {
        let result = effectiveBody(bodyText: "Nur Text.", signature: "", append: true)
        #expect(result == "Nur Text.")
    }

    // MARK: - StudioContact.matches Regression

    @Test func matchesTrifftNamen() {
        let c = StudioContact(id: "1", name: "Heinz Hustadt", organisation: "Studio GmbH")
        #expect(c.matches("heinz"))
        #expect(c.matches("HUSTADT"))
        #expect(c.matches("studio"))
        #expect(!c.matches("xxxxxx"))
    }

    @Test func matchesTrifftOrganisation() {
        let c = StudioContact(id: "2", name: "X", organisation: "Tischler AG")
        #expect(c.matches("tischler"))
    }

    @Test func matchesTrifftProjekt() {
        let c = StudioContact(id: "3", name: "Y", projekt: "2026-001")
        #expect(c.matches("2026-001"))
    }
}
