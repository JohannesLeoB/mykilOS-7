import Testing
import Foundation
@testable import MykilosApp

// Mapping-Test für den Projektfragebogen-Intake:
// Fragebogen → Kunde-/Projekt-Felder (Airtable-Feld-NAMEN) + Warenkorb.
// @MainActor, weil FragebogenModel/IntakeResultBuilder main-actor-isoliert sind.
@MainActor
struct IntakeResultBuilderTests {

    @Test func mapptKundeFelderAufAirtableFeldnamen() {
        let m = FragebogenModel()
        m.kundeVorname = "Anna"
        m.kundeNachname = "Mustermann"
        m.kundeFirma = "Muster GmbH"
        m.kundeEmail = "anna@example.com"
        m.kundeTelefon = "+49 40 123456"

        let ergebnis = IntakeResultBuilder.build(from: m)

        #expect(ergebnis.kundeFelder["Nachname"] == "Mustermann")
        #expect(ergebnis.kundeFelder["Vorname"] == "Anna")
        #expect(ergebnis.kundeFelder["Firma"] == "Muster GmbH")
        #expect(ergebnis.kundeFelder["Kontakt 1 Email"] == "anna@example.com")
        #expect(ergebnis.kundeFelder["Kontakt 1 Telefon"] == "+49 40 123456")
    }

    @Test func mapptProjektNameUndStatus() {
        let m = FragebogenModel()
        m.projektName = "2026-099 Mustermann"

        let ergebnis = IntakeResultBuilder.build(from: m)

        #expect(ergebnis.projektFelder["Projektname"] == "2026-099 Mustermann")
        // Status wird immer gesetzt (Default-Status), Zusammenfassung nie leer.
        #expect(ergebnis.projektFelder["Projektstatus"] != nil)
        #expect(ergebnis.zusammenfassung.isEmpty == false)
    }

    @Test func leererBogenErzeugtKeineLeerenPflichtfelderUndKeinenCrash() {
        let m = FragebogenModel()
        let ergebnis = IntakeResultBuilder.build(from: m)
        // Leere Strings dürfen nicht als Felder durchrutschen (Airtable-Hygiene).
        #expect(ergebnis.kundeFelder["Vorname"] == nil || ergebnis.kundeFelder["Vorname"]?.isEmpty == false)
    }
}
