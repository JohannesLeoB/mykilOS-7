import Testing
import Foundation
import MykilosKit
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

    // MARK: - istAusgefuelltGenug (Anlege-Stufen-Feature, 2026-07-01)
    // Review-Fix (Johannes): "es MUSS ein Minimum an Eingabedaten vorausgesetzt sein" —
    // das universelle Minimum ist nur noch der Nachname; Projektname/Adresse werden je
    // gewählter Anlege-Stufe in der Bestätigungsansicht geprüft (siehe FragebogenView).

    @Test func istAusgefuelltGenugBrauchtNurNachnamen() {
        let m = FragebogenModel()
        #expect(m.istAusgefuelltGenug == false)
        m.kundeNachname = "Mustermann"
        #expect(m.istAusgefuelltGenug == true)   // KEIN Projektname nötig — reicht für "Nur Kontakt"
    }

    @Test func istAusgefuelltGenugIgnoriertLeerenNachnamen() {
        let m = FragebogenModel()
        m.kundeNachname = "   "
        #expect(m.istAusgefuelltGenug == false)
    }
}

// MARK: - IntakeAdresse (atomarer Adress-Fallback, Review-Fix 2026-07-01)
@MainActor
struct IntakeAdresseTests {

    private func ergebnis(projektStrasse: String? = nil, projektOrt: String? = nil,
                          kundeStrasse: String? = nil, kundeOrt: String? = nil) -> IntakeErgebnis {
        var projektFelder: [String: String] = [:]
        if let projektStrasse { projektFelder["Projektadresse Straße"] = projektStrasse }
        if let projektOrt { projektFelder["Projektadresse Ort"] = projektOrt }
        var kundeFelder: [String: String] = [:]
        if let kundeStrasse { kundeFelder["Angebotsadresse Straße"] = kundeStrasse }
        if let kundeOrt { kundeFelder["Angebotsadresse Ort"] = kundeOrt }
        return IntakeErgebnis(kundeFelder: kundeFelder, projektFelder: projektFelder,
                              warenkorb: Warenkorb(items: []), zusammenfassung: "")
    }

    @Test func bevorzugtProjektAdresseKomplettAtomar() {
        let e = ergebnis(projektStrasse: "Heimhuder 8", projektOrt: "Hamburg",
                         kundeStrasse: "Musterweg 3", kundeOrt: "Berlin")
        let (strasse, hausnummer, ort) = IntakeAdresse.aufloesen(ergebnis: e)
        // Straße+Hausnummer+Ort müssen ALLE aus der Projekt-Adresse kommen, nie gemischt.
        #expect(strasse == "Heimhuder")
        #expect(hausnummer == "8")
        #expect(ort == "Hamburg")
    }

    @Test func faelltAufKundenAdresseAtomarZurueckWennProjektAdresseGanzFehlt() {
        // Projekt hat GAR KEINE Adressangabe (weder Straße noch Ort) → komplett auf
        // die Kunden-Adresse zurückfallen, atomar (nie einzelne Felder mischen).
        let e = ergebnis(projektStrasse: nil, projektOrt: nil,
                         kundeStrasse: "Musterweg 3", kundeOrt: "Berlin")
        let (strasse, hausnummer, ort) = IntakeAdresse.aufloesen(ergebnis: e)
        #expect(strasse == "Musterweg")
        #expect(hausnummer == "3")
        #expect(ort == "Berlin")
    }

    @Test func nutztProjektOrtAuchOhneProjektStrasseNichtDieKundenAdresse() {
        // Review-Fix: ein Projekt MIT Ort aber OHNE Straße zählt schon als "Projekt-Adresse
        // vorhanden" — der eigene Ort darf nicht verworfen werden zugunsten der Kunden-Adresse.
        let e = ergebnis(projektStrasse: nil, projektOrt: "Hamburg",
                         kundeStrasse: "Musterweg 3", kundeOrt: "Berlin")
        let (strasse, hausnummer, ort) = IntakeAdresse.aufloesen(ergebnis: e)
        #expect(strasse == nil)
        #expect(hausnummer == nil)
        #expect(ort == "Hamburg")
    }

    @Test func strNummerBildbarOhneJedeAdresse() {
        let e = ergebnis()
        #expect(IntakeAdresse.strNummerBildbar(ergebnis: e) == false)
    }

    @Test func strNummerBildbarMitOrtFallback() {
        let e = ergebnis(projektOrt: "Hamburg")
        #expect(IntakeAdresse.strNummerBildbar(ergebnis: e) == true)
    }
}
