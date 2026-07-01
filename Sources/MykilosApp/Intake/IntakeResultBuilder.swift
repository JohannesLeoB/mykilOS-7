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
        // Adressblock
        var adressteile: [String] = []
        if !strasse.isEmpty { adressteile.append(strasse) }
        if !plz.isEmpty || !ort.isEmpty {
            let plzOrt = [plz, ort].filter { !$0.isEmpty }.joined(separator: " ")
            adressteile.append(plzOrt)
        }
        if !adressteile.isEmpty {
            felder["Angebotsadresse Straße"] = adressteile.first ?? ""
            if adressteile.count > 1 { felder["Angebotsadresse PLZ"] = plz }
            if !ort.isEmpty { felder["Angebotsadresse Ort"] = ort }
        }
        felder["Quelle"] = m.quelle.map(\.rawValue).sorted().joined(separator: ", ")
        // Sonderwünsche / Notizen
        let notizen = buildKundeNotizen(m)
        if !notizen.isEmpty { felder["Notizen"] = notizen }
        return felder
    }

    private static func buildKundeNotizen(_ m: FragebogenModel) -> String {
        var teile: [String] = []
        if !m.quelleFreitext.isEmpty { teile.append("Quelle: \(m.quelleFreitext)") }
        if !m.entscheidungFreitext.isEmpty { teile.append("Entscheidung: \(m.entscheidungFreitext)") }
        return teile.joined(separator: " | ")
    }

    // MARK: - Projekt-Felder (Artikel-DB "Projekte"-Tabelle)

    static func mapProjektFelder(_ m: FragebogenModel) -> [String: String] {
        var felder: [String: String] = [:]
        let name = m.projektName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { felder["Projektname"] = name }
        felder["Projektstatus"] = m.projektStatus
        if let budget = m.budget { felder["Budget"] = String(budget) }
        // Projektadresse
        let strasse = m.projektStrasse.trimmingCharacters(in: .whitespacesAndNewlines)
        let plz     = m.projektPLZ.trimmingCharacters(in: .whitespacesAndNewlines)
        let ort     = m.projektOrt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !strasse.isEmpty { felder["Projektadresse Straße"] = strasse }
        if !plz.isEmpty     { felder["Projektadresse PLZ"]    = plz }
        if !ort.isEmpty     { felder["Projektadresse Ort"]    = ort }
        // Projektart (immer kitchen bei Fragebogen)
        felder["Projektart"] = "kitchen"
        // Notizen aus Fragebogen
        let notizen = buildProjektNotizen(m)
        if !notizen.isEmpty { felder["Notizen"] = notizen }
        return felder
    }

    private static func buildProjektNotizen(_ m: FragebogenModel) -> String {
        var teile: [String] = []
        if !m.raumBreite.isEmpty || !m.raumTiefe.isEmpty {
            teile.append("Raum: \(m.raumBreite)m × \(m.raumTiefe)m (\(m.raumform.rawValue))")
        }
        if !m.einbausituation.isEmpty {
            teile.append("Einbau: \(m.einbausituation.map(\.rawValue).sorted().joined(separator: ", "))")
        }
        if !m.stil.isEmpty {
            teile.append("Stil: \(m.stil.map(\.rawValue).sorted().joined(separator: ", "))")
        }
        if !m.sonderwuensche.isEmpty { teile.append("Sonderwünsche: \(m.sonderwuensche)") }
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
