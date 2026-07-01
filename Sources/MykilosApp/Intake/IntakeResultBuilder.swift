import Foundation
import MykilosKit
import MykilosServices

// MARK: - IntakeErgebnis
// Ergebnis des Mappings Fragebogen → Airtable-Felder + Warenkorb.
// Pure struct — kein SwiftUI, kein @Observable, testbar.
public struct IntakeErgebnis: Sendable, Equatable {
    /// Felder für Airtable-Tabelle „Kunden" (Artikel-DB appdxTeT6bhSBmwx5, tblImZ3fKYBXBT7Wb)
    public let kundeFelder: [String: String]
    /// Felder für Airtable-Tabelle „Projekte" (Artikel-DB appdxTeT6bhSBmwx5, tblOXF9Cv8Jze6595)
    public let projektFelder: [String: String]
    /// Erste Warenkorb-Positionen (aus ausgewählten Geräten + Freitext-Positionen)
    public let warenkorb: Warenkorb
    /// Zusammenfassung für die Bestätigungs-Karte (menschenlesbar)
    public let zusammenfassung: String
}

// MARK: - IntakeAnlageErgebnis
// Ergebnis von AppState.erzeugeKundeUndProjekt: die Bestätigungs-Zusammenfassung plus,
// falls die echte Provisionierung (Drive-Ordner + Mastermind-Routing) erfolgreich war,
// die neue Projekt-Ordner-ID (sonst nil — nicht-fatal, Kunde+Projekt sind trotzdem live).
public struct IntakeAnlageErgebnis: Sendable, Equatable {
    public let summary: String
    public let driveProjektOrdnerID: String?
}

// MARK: - IntakeAdresse
// Eine Wahrheit für die Adress-Auflösung: Projekt-Baustellenadresse bevorzugt,
// sonst Kunden-(Rechnungs-)Adresse — aber IMMER als GANZE Adresse (Straße+Hausnummer+Ort
// zusammen), nie Felder aus unterschiedlichen Adressen gemischt (Review-Fix, 2026-07-01).
// Von der Bestätigungsansicht (Stufe-3-Readiness) UND von AppState.provisioniereEchtesProjekt
// (der tatsächlichen STR-Nr-Bildung) genutzt — exakt dieselbe Logik, kein zweiter Ort.
public enum IntakeAdresse {
    public static func aufloesen(ergebnis: IntakeErgebnis) -> (strasse: String?, hausnummer: String?, ort: String?) {
        let projektAdresse = STRNummer.splitStrasseHausnummer(ergebnis.projektFelder["Projektadresse Straße"])
        let projektOrt = ergebnis.projektFelder["Projektadresse Ort"]
        // "Projekt-Adresse vorhanden" heißt: IRGENDEIN Projekt-Adressfeld ist gesetzt
        // (Straße ODER Ort) — sonst würde ein Projekt mit nur Ort (ohne Straße) fälschlich
        // die Kunden-Adresse benutzen und dabei den eigenen, bereits bekannten Ort verwerfen.
        if projektAdresse.strasse != nil || projektOrt != nil {
            return (projektAdresse.strasse, projektAdresse.hausnummer, projektOrt)
        }
        let kundeAdresse = STRNummer.splitStrasseHausnummer(ergebnis.kundeFelder["Angebotsadresse Straße"])
        return (kundeAdresse.strasse, kundeAdresse.hausnummer, ergebnis.kundeFelder["Angebotsadresse Ort"])
    }

    /// Ob aus der aufgelösten Adresse überhaupt eine STR-Nr gebildet werden kann
    /// (Straße+Hausnummer ODER ORT-Fallback). Für die Stufe-3-Button-Gate-Prüfung.
    public static func strNummerBildbar(ergebnis: IntakeErgebnis) -> Bool {
        let (strasse, hausnummer, ort) = aufloesen(ergebnis: ergebnis)
        switch STRNummer.bilde(strasse: strasse, hausnummer: hausnummer, ort: ort) {
        case .gebildet: return true
        case .nichtBildbar: return false
        }
    }
}

// MARK: - IntakeResultBuilder
// Mappt den ausgefüllten FragebogenModel → IntakeErgebnis.
// Reine, testbare Funktion — keine Seiteneffekte.
// @MainActor, weil FragebogenModel main-actor-isoliert ist (gelesen, nicht mutiert).
@MainActor
public enum IntakeResultBuilder {

    // MARK: Kunden-Tabellen-IDs (Mastermind appuVMh3KDfKw4OoQ)
    // Feldnamen nach Airtable-Spalten-Name (Name-API — nicht ID).
    static let kundeTableName  = "Kunden"
    static let kundeBaseID     = CartStore.artikelBaseID  // appdxTeT6bhSBmwx5 — Artikel-Base (Kunde + Projekt zusammen, Sevdesk-Pipeline)

    // MARK: Projekt-Tabellen-IDs (Artikel-DB appdxTeT6bhSBmwx5)
    // Feldnamen laut HANDOFF_PLANNED_FEATURES Feature B.
    static let projektTableName = "Projekte"
    static let projektBaseID    = CartStore.artikelBaseID       // appdxTeT6bhSBmwx5

    /// Wandelt den ausgefüllten Fragebogen in ein IntakeErgebnis um.
    /// Rein funktional — kein Netzwerk, kein Audit.
    public static func build(from modell: FragebogenModel) -> IntakeErgebnis {
        let kundeFelder = mapKundeFelder(modell)
        let projektFelder = mapProjektFelder(modell)
        let warenkorb = buildWarenkorb(modell)
        let zusammenfassung = buildZusammenfassung(modell, warenkorb: warenkorb)
        return IntakeErgebnis(
            kundeFelder: kundeFelder,
            projektFelder: projektFelder,
            warenkorb: warenkorb,
            zusammenfassung: zusammenfassung
        )
    }

    // MARK: - Kunden-Felder (Mastermind "Kunden"-Tabelle)

    static func mapKundeFelder(_ m: FragebogenModel) -> [String: String] {
        var felder: [String: String] = [:]
        let nachname = m.kundeNachname.trimmingCharacters(in: .whitespacesAndNewlines)
        let vorname  = m.kundeVorname.trimmingCharacters(in: .whitespacesAndNewlines)
        let firma    = m.kundeFirma.trimmingCharacters(in: .whitespacesAndNewlines)
        let email    = m.kundeEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let telefon  = m.kundeTelefon.trimmingCharacters(in: .whitespacesAndNewlines)
        let strasse  = m.kundeStrasse.trimmingCharacters(in: .whitespacesAndNewlines)
        let plz      = m.kundePLZ.trimmingCharacters(in: .whitespacesAndNewlines)
        let ort      = m.kundeOrt.trimmingCharacters(in: .whitespacesAndNewlines)

        if !nachname.isEmpty  { felder["Nachname"]  = nachname }
        if !vorname.isEmpty   { felder["Vorname"]   = vorname }
        if !firma.isEmpty     { felder["Firma"]     = firma }
        if !email.isEmpty     { felder["Kontakt 1 Email"] = email }
        if !telefon.isEmpty   { felder["Kontakt 1 Telefon"] = telefon }
        // Adressblock — Straße/PLZ/Ort unabhängig voneinander gesetzt, exakt wie
        // mapProjektFelder unten. Fix (2026-07-01, Härtung): die vorherige kombinierte
        // "adressteile"-Liste hat bei fehlender Straße (nur PLZ/Ort ausgefüllt) die
        // PLZ+Ort-Kombination fälschlich ins Straßenfeld geschrieben und dabei die
        // echte PLZ stillschweigend verworfen.
        if !strasse.isEmpty { felder["Angebotsadresse Straße"] = strasse }
        if !plz.isEmpty      { felder["Angebotsadresse PLZ"]    = plz }
        if !ort.isEmpty      { felder["Angebotsadresse Ort"]    = ort }
        // Härtung (2026-07-01, Live-Schema-Diagnose): die echten Kunden-Feldnamen wurden über
        // ExternalMappingRegistry.syncBusiness ausgelesen (Vereinigung über alle 6 vorhandenen
        // Records): Nachname, Vorname, Firma, Kontakt 1/2 Email, Kontakt 1/2 Telefon, Land,
        // Angebotsadresse Straße/PLZ/Ort, Erstellt am, Projekte (Link), sevDesk Kontakt-ID.
        // "Quelle" existiert NICHT (in keinem der 6 Records) — bisher blind gesendet, hätte
        // (nach Behebung des Notizen-Fehlers) den nächsten HTTP 422 ausgelöst. Bewusst NICHT
        // geraten — Feld weggelassen, bis Johannes den echten Feldnamen/Zielort nennt.
        // let notizen = buildKundeNotizen(m)
        // if !notizen.isEmpty { felder["Notizen"] = notizen }
        // let notizen = buildKundeNotizen(m)
        // if !notizen.isEmpty { felder["Notizen"] = notizen }
        return felder
    }

    private static func buildKundeNotizen(_ m: FragebogenModel) -> String {
        var teile: [String] = []
        // Härtung (2026-07-01): getrimmt wie jeder andere Freitext-Guard in dieser Datei —
        // ein reiner Leerzeichen-String war bisher "nicht leer" und landete als sichtbar
        // leere Zeile ("Quelle: ") in den Notizen.
        let quelleFreitext = m.quelleFreitext.trimmingCharacters(in: .whitespacesAndNewlines)
        let entscheidungFreitext = m.entscheidungFreitext.trimmingCharacters(in: .whitespacesAndNewlines)
        if m.quelle.count > 1 {
            // Vollständige Mehrfachauswahl bleibt hier erhalten, da nur der erste Wert
            // ins Airtable-Feld "Quelle" geschrieben wird (siehe mapKundeFelder oben).
            teile.append("Quelle (alle): \(m.quelle.map(\.rawValue).sorted().joined(separator: ", "))")
        }
        if !quelleFreitext.isEmpty { teile.append("Quelle: \(quelleFreitext)") }
        if !entscheidungFreitext.isEmpty { teile.append("Entscheidung: \(entscheidungFreitext)") }
        return teile.joined(separator: " | ")
    }

    // MARK: - Projekt-Felder (Artikel-DB "Projekte"-Tabelle)

    // Härtung (2026-07-01, Live-Schema-Diagnose): die echten Feldnamen der Projekte-Tabelle
    // wurden über einen bereits laufenden, echten Read (ExternalMappingRegistry.syncBusiness)
    // ausgelesen (Vereinigung über alle 9 vorhandenen Records — kein Rätselraten mehr):
    //   Projektname, Status, Kunde, Projektadresse Straße/PLZ/Ort, Projektartikel,
    //   Summe EK/VK, Ertrag (€), Kostenabweichung, Marge %, Gesamtkosten geplant,
    //   sevDesk Angebot-ID/-Link/Kostenstellen-ID, ClickUp Lead ID/Link, Firma/Nachname/
    //   Vorname (from Kunde) [Lookups, nicht schreibbar], Angebot an sevDesk senden.
    // "Projektstatus", "Budget" und "Projektart" existieren NICHT — sie wurden bisher blind
    // gesendet und haben JEDE Projekt-Anlage mit HTTP 422 blockiert. "Status" existiert echt,
    // aber der einzige bisher beobachtete Wert ist "In progress" (Englisch) — passt zu KEINER
    // der 6 deutschen Picker-Optionen dieser App. Ohne die vollständige Options-Liste würde
    // jeder geratene Wert erneut 422en (Select-Feld, kein typecast in dieser Base erlaubt).
    // Alle drei bewusst weggelassen, bis Johannes die echten Status-Optionen nennt UND
    // bestätigt, wo Budget/Projektart tatsächlich hingehören (evtl. in eine eigene Tabelle,
    // siehe "Bau-Runde Intake+Webshop"-Notiz zu separaten, eigenen Tabellen).
    static func mapProjektFelder(_ m: FragebogenModel) -> [String: String] {
        var felder: [String: String] = [:]
        let name = m.projektName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { felder["Projektname"] = name }
        // Projektadresse
        let strasse = m.projektStrasse.trimmingCharacters(in: .whitespacesAndNewlines)
        let plz     = m.projektPLZ.trimmingCharacters(in: .whitespacesAndNewlines)
        let ort     = m.projektOrt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !strasse.isEmpty { felder["Projektadresse Straße"] = strasse }
        if !plz.isEmpty     { felder["Projektadresse PLZ"]    = plz }
        if !ort.isEmpty     { felder["Projektadresse Ort"]    = ort }
        return felder
    }

    private static func buildProjektNotizen(_ m: FragebogenModel) -> String {
        var teile: [String] = []
        // Härtung (2026-07-01): getrimmt wie die übrigen Freitext-Guards — ein reiner
        // Leerzeichen-String war bisher "nicht leer" und erzeugte eine sichtbar leere Zeile.
        let raumBreite = m.raumBreite.trimmingCharacters(in: .whitespacesAndNewlines)
        let raumTiefe = m.raumTiefe.trimmingCharacters(in: .whitespacesAndNewlines)
        let sonderwuensche = m.sonderwuensche.trimmingCharacters(in: .whitespacesAndNewlines)
        if !raumBreite.isEmpty || !raumTiefe.isEmpty {
            teile.append("Raum: \(raumBreite)m × \(raumTiefe)m (\(m.raumform.rawValue))")
        }
        if !m.einbausituation.isEmpty {
            teile.append("Einbau: \(m.einbausituation.map(\.rawValue).sorted().joined(separator: ", "))")
        }
        if !m.stil.isEmpty {
            teile.append("Stil: \(m.stil.map(\.rawValue).sorted().joined(separator: ", "))")
        }
        if !sonderwuensche.isEmpty { teile.append("Sonderwünsche: \(sonderwuensche)") }
        teile.append("Nächster Schritt: \(m.naechsterSchritt.rawValue)")
        teile.append("Planungsphase: \(m.planungsphase.rawValue)")
        teile.append("Budget-Kategorie: \(m.budgetKategorie.rawValue)")
        return teile.joined(separator: " | ")
    }

    // MARK: - Warenkorb aus Geräte-Sektionen

    static func buildWarenkorb(_ m: FragebogenModel) -> Warenkorb {
        var items: [WarenkorbItem] = []

        // Geräte-Sektionen: Fronten (4), Arbeitsplatten (5), Kochfeld (6),
        // Backofen (9), Haushaltsgeräte (15), Technik (16)
        let geraeteSektionen: [[FragebogenArtikelAuswahl]] = [
            m.frontenArtikel,
            m.arbeitsplattenArtikel,
            m.kochfeldArtikel,
            m.backofenArtikel,
            m.haushaltsgeraeteArtikel,
            m.technikArtikel,
        ]
        for sektion in geraeteSektionen {
            for auswahl in sektion {
                let bezeichnung = auswahl.freitextOverride.isEmpty
                    ? auswahl.bezeichnung
                    : auswahl.freitextOverride
                let item = WarenkorbItem(
                    artikelRecordID: auswahl.artikelRecordID,
                    bezeichnung: bezeichnung,
                    artikelnummer: auswahl.artikelnummer,
                    menge: auswahl.menge,
                    ekNetto: auswahl.ekNetto,
                    vkNetto: auswahl.vkNetto,
                    quelle: "intake"
                )
                items.append(item)
            }
        }

        // Freitext-Sektionen: wenn Freitext gesetzt aber keine Artikel, als Position aufnehmen
        let freitextSektionen: [(String, String)] = [
            ("Fronten", m.frontenFreitext),
            ("Arbeitsplatten", m.arbeitsplattenFreitext),
            ("Kochfeld", m.kochfeldFreitext),
            ("Dunstabzug", m.dunstabzugFreitext),
            ("Beleuchtung", m.beleuchtungFreitext),
            ("Backofen", m.backofenFreitext),
            ("Spüle", m.spuelFreitext),
            ("Kühlgeräte", m.kuehlgeraeteFreitext),
        ]
        for (kategorie, freitext) in freitextSektionen {
            let text = freitext.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                items.append(WarenkorbItem(
                    bezeichnung: "\(kategorie): \(text)",
                    artikelnummer: "INTAKE-\(kategorie.prefix(4).uppercased())",
                    menge: 1,
                    quelle: "intake-freitext"
                ))
            }
        }

        return Warenkorb(
            items: items,
            projektRecordID: nil,   // wird nach Anlage verdrahtet
            projektName: m.projektName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        )
    }

    // MARK: - Zusammenfassung für Bestätigungs-Karte

    static func buildZusammenfassung(_ m: FragebogenModel, warenkorb: Warenkorb) -> String {
        var zeilen: [String] = []
        zeilen.append("Kunde: \(m.vollstaendigerKundeName)")
        if !m.kundeFirma.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            zeilen.append("Firma: \(m.kundeFirma)")
        }
        zeilen.append("Projekt: \(m.projektName)")
        if !warenkorb.items.isEmpty {
            zeilen.append("Warenkorb: \(warenkorb.items.count) Position(en)")
        }
        return zeilen.joined(separator: "\n")
    }
}

// MARK: - Hilfserweiterung (lokal)
private extension String {
    var nilIfEmpty: String? { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self }
}
