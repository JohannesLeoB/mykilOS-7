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

    // Härtung (2026-07-01, Live-Schema-Diagnose): "Quelle" existiert NICHT als Feldname in der
    // echten Kunden-Tabelle (bestätigt über eine Vereinigung aller 6 live vorhandenen Records) —
    // wird deshalb NIE mehr gesendet, unabhängig von der Auswahl im Fragebogen.
    @Test func quelleWirdNieAlsAirtableFeldGesendet() {
        let m = FragebogenModel()
        m.kundeNachname = "Berger"
        m.quelle = [.empfehlung]
        let ergebnis = IntakeResultBuilder.build(from: m)
        #expect(ergebnis.kundeFelder["Quelle"] == nil)
    }

    // Härtung (2026-07-01, Live-Schema-Diagnose): "Projektstatus" existiert NICHT (echter
    // Feldname ist "Status", dessen gültige Select-Optionen noch unbekannt sind) — wird
    // deshalb bewusst NICHT gesendet, bis Johannes die echten Optionen nennt.
    @Test func mapptNurProjektnameKeinProjektstatusFeld() {
        let m = FragebogenModel()
        m.projektName = "2026-099 Mustermann"

        let ergebnis = IntakeResultBuilder.build(from: m)

        #expect(ergebnis.projektFelder["Projektname"] == "2026-099 Mustermann")
        #expect(ergebnis.projektFelder["Projektstatus"] == nil)
        #expect(ergebnis.projektFelder["Status"] == nil)
        #expect(ergebnis.zusammenfassung.isEmpty == false)
    }

    // Härtung (2026-07-01, Live-Schema-Diagnose): weder "Budget" noch "Projektart" existieren
    // in der echten Projekte-Tabelle — beide werden bewusst nicht gesendet.
    @Test func budgetUndProjektartWerdenNieAlsAirtableFeldGesendet() {
        let m = FragebogenModel()
        m.projektName = "2026-099 Mustermann"
        m.budget = 25000
        let ergebnis = IntakeResultBuilder.build(from: m)
        #expect(ergebnis.projektFelder["Budget"] == nil)
        #expect(ergebnis.projektFelder["Projektart"] == nil)
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

    // MARK: - Härtung (2026-07-01, Audit): Straße/PLZ/Ort unabhängig, Quelle nur ein Wert

    @Test func angebotsadressePLZUndOrtOhneStrasseWerdenNichtInsStrassenfeldGequetscht() {
        let m = FragebogenModel()
        m.kundeNachname = "Berger"
        m.kundePLZ = "20095"
        m.kundeOrt = "Hamburg"
        let ergebnis = IntakeResultBuilder.build(from: m)
        #expect(ergebnis.kundeFelder["Angebotsadresse Straße"] == nil)
        #expect(ergebnis.kundeFelder["Angebotsadresse PLZ"] == "20095")
        #expect(ergebnis.kundeFelder["Angebotsadresse Ort"] == "Hamburg")
    }

    @Test func angebotsadresseMitAllenDreiFeldernUnabhaengigGesetzt() {
        let m = FragebogenModel()
        m.kundeNachname = "Berger"
        m.kundeStrasse = "Musterweg 3"
        m.kundePLZ = "20095"
        m.kundeOrt = "Hamburg"
        let ergebnis = IntakeResultBuilder.build(from: m)
        #expect(ergebnis.kundeFelder["Angebotsadresse Straße"] == "Musterweg 3")
        #expect(ergebnis.kundeFelder["Angebotsadresse PLZ"] == "20095")
        #expect(ergebnis.kundeFelder["Angebotsadresse Ort"] == "Hamburg")
    }

    @Test func quelleBeiMehrfachauswahlWirdEbenfallsNieGesendet() {
        let m = FragebogenModel()
        m.kundeNachname = "Berger"
        m.quelle = [.empfehlung, .google]
        let ergebnis = IntakeResultBuilder.build(from: m)
        // "Quelle" existiert nicht als Feldname (Live-Schema-Diagnose) — auch bei
        // Mehrfachauswahl wird nichts gesendet, kein zusammengefügter String mehr möglich.
        #expect(ergebnis.kundeFelder["Quelle"] == nil)
    }

    // Härtung (2026-07-01, Live-Test): "Notizen" existiert NICHT als echter Feldname in der
    // Kunden-/Projekte-Tabelle der Artikel-DB (Airtable: "Unknown field name: 'Notizen'") —
    // das Feld wird bewusst NICHT gesendet, bis der echte Feldname bekannt ist (kein Raten).
    @Test func kundeFelderEnthaltenKeinNotizenFeld() {
        let m = FragebogenModel()
        m.kundeNachname = "Berger"
        m.quelleFreitext = "Empfehlung von Nachbarn"
        m.entscheidungFreitext = "Alleine"
        let ergebnis = IntakeResultBuilder.build(from: m)
        #expect(ergebnis.kundeFelder["Notizen"] == nil)
    }

    @Test func projektFelderEnthaltenKeinNotizenFeld() {
        let m = FragebogenModel()
        m.projektName = "2026-099 Mustermann"
        m.sonderwuensche = "Bitte leise Geräte"
        let ergebnis = IntakeResultBuilder.build(from: m)
        #expect(ergebnis.projektFelder["Notizen"] == nil)
    }

    // MARK: - Härtung (2026-07-01, Audit): Budget-Parsing im deutschen Zahlenformat

    @Test func parseGermanBudgetErkenntTausenderpunktOhneKomma() {
        #expect(FragebogenModel.parseGermanBudget("25.000") == 25000)
    }

    @Test func parseGermanBudgetErkenntKommaAlsDezimaltrenner() {
        #expect(FragebogenModel.parseGermanBudget("25000,50") == 25000.50)
    }

    @Test func parseGermanBudgetErkenntTausenderUndDezimalKombiniert() {
        #expect(FragebogenModel.parseGermanBudget("25.000,50") == 25000.50)
    }

    @Test func parseGermanBudgetOhneTrennerBleibtUnveraendert() {
        #expect(FragebogenModel.parseGermanBudget("25000") == 25000)
    }

    @Test func parseGermanBudgetMitZweiNachkommastellenBleibtDezimal() {
        #expect(FragebogenModel.parseGermanBudget("25.5") == 25.5)
    }

    @Test func parseGermanBudgetLeererStringGibtNilZurueck() {
        #expect(FragebogenModel.parseGermanBudget("") == nil)
        #expect(FragebogenModel.parseGermanBudget("   ") == nil)
    }

    // MARK: - Härtung (2026-07-01, Johannes: Erinnerungsfunktion + "Verwerfen"-Button)

    @Test func resetSetztAlleFelderAufDenLeerzustandZurueck() {
        let m = FragebogenModel()
        m.kundeNachname = "Berger"
        m.kundeVorname = "Johannes"
        m.projektName = "2026-099 Berger"
        m.budgetText = "25.000"
        m.budget = 25000
        m.quelle = [.empfehlung, .google]
        m.einbausituation = [.neubau]
        m.frontenArtikel = [FragebogenArtikelAuswahl(bezeichnung: "Front", artikelnummer: "F-1")]
        m.sonderwuensche = "Bitte schnell"
        m.raumform = .lForm

        m.reset()

        #expect(m.kundeNachname == "")
        #expect(m.kundeVorname == "")
        #expect(m.projektName == "")
        #expect(m.budgetText == "")
        #expect(m.budget == nil)
        #expect(m.quelle.isEmpty)
        #expect(m.einbausituation.isEmpty)
        #expect(m.frontenArtikel.isEmpty)
        #expect(m.sonderwuensche == "")
        #expect(m.raumform == .rechteckig)
        #expect(m.istAusgefuelltGenug == false)
    }

    @Test func hatNennenswerteEingabenErkenntLeeresFormular() {
        let m = FragebogenModel()
        #expect(m.hatNennenswerteEingaben == false)
        m.kundeNachname = "Berger"
        #expect(m.hatNennenswerteEingaben == true)
    }

    @Test func hatNennenswerteEingabenErkenntBudgetOhneNachnamen() {
        let m = FragebogenModel()
        m.budget = 15000
        #expect(m.hatNennenswerteEingaben == true)
    }

    // Härtung (2026-07-01, Audit): hatNennenswerteEingaben prüfte bisher NUR Kontakt/Projekt/
    // Budget (7 von 74 Feldern) — wer nur Raum/Einbau/Stil/Geräte ausgefüllt hatte, hätte beim
    // "Verwerfen" alles ohne Sicherheitsabfrage verloren.
    @Test func hatNennenswerteEingabenErkenntNurRaumUndStilOhneKontakt() {
        let m = FragebogenModel()
        m.raumBreite = "3.5"
        m.stil = [.modern]
        #expect(m.hatNennenswerteEingaben == true)
    }

    @Test func hatNennenswerteEingabenErkenntNurGeraeteAuswahlOhneKontakt() {
        let m = FragebogenModel()
        m.kochfeldTyp = [.induktion]
        #expect(m.hatNennenswerteEingaben == true)
    }

    @Test func hatNennenswerteEingabenErkenntNurSonderwuenscheOhneKontakt() {
        let m = FragebogenModel()
        m.sonderwuensche = "Bitte besonders leise Geräte"
        #expect(m.hatNennenswerteEingaben == true)
    }

    @Test func hatNennenswerteEingabenErkenntArtikelAuswahlOhneKontakt() {
        let m = FragebogenModel()
        m.frontenArtikel = [FragebogenArtikelAuswahl(bezeichnung: "Front", artikelnummer: "F-1")]
        #expect(m.hatNennenswerteEingaben == true)
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
