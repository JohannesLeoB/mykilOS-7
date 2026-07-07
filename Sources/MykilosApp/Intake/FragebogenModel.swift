import Foundation
import MykilosKit

// MARK: - FragebogenModel
// @Observable Datenmodell für den Küchen-Projekt-Fragebogen.
// Alle 24 Sektionen + Kopf (Kontakt) + Budget + Raumgröße.
// Mehrfachauswahl per Sets, Freitext je Sektion.
// Zwischenspeicherbar (lokal, nichts geht verloren). Kein GRDB.
// Bewusst NICHT @MainActor: reines @Observable-Datenmodell, von SwiftUI auf dem
// Main-Actor genutzt; so bleibt der Init im View-Default-Argument nonisolated.
@Observable
public final class FragebogenModel {

    // MARK: - Kontakt / Kunde

    public var kundeVorname: String = ""
    public var kundeNachname: String = ""
    public var kundeFirma: String = ""
    public var kundeEmail: String = ""
    public var kundeTelefon: String = ""
    /// Adresse des Kunden (Straße + Hausnummer)
    public var kundeStrasse: String = ""
    public var kundePLZ: String = ""
    public var kundeOrt: String = ""

    // MARK: - Projekt-Kopf

    public var projektName: String = ""
    /// Adresse des Bauvorhabens / abweichend von Kundenadresse
    public var projektStrasse: String = ""
    public var projektPLZ: String = ""
    public var projektOrt: String = ""
    /// Projektstatus (Mastermind "Projekte"-Tabelle)
    public var projektStatus: String = "Lead"
    /// Budget (Netto, €)
    public var budget: Double? = nil
    public var budgetText: String = ""

    // MARK: - Ordnername (Härtung 2026-07-01, Live-Kollision)

    /// Manueller Edit-Modus für den beschreibenden Teil des Drive-Ordnernamens
    /// (Kundenname_STR-Block) — leer = automatischer Vorschlag wird verwendet.
    /// Die laufende Projektnummer selbst ist NIE über dieses Feld beeinflussbar
    /// (nur die kollisionsgeprüfte Vergabe entscheidet über die Nummer).
    public var ordnerNameSuffixOverride: String = ""

    // MARK: - Raumgröße

    /// Grundfläche in m² (Freitext-Eingabe, gespeichert als String)
    public var raumBreite: String = ""
    public var raumTiefe: String = ""
    public var raumHoeheText: String = ""
    /// Raumform
    public var raumform: Raumform = .rechteckig
    public var raumformFreitext: String = ""

    // MARK: - Sektion 1: Einbausituation
    public var einbausituation: Set<Einbausituation> = []
    public var einbausituationFreitext: String = ""

    // MARK: - Sektion 2: Küchen-Stil
    public var stil: Set<KuecheStil> = []
    public var stilFreitext: String = ""

    // MARK: - Sektion 3: Griffkonzept
    public var griffkonzept: Set<Griffkonzept> = []
    public var griffkonzeptFreitext: String = ""

    // MARK: - Sektion 4: Fronten / Oberfläche (Gerät-Sektion)
    public var frontenMaterial: Set<FrontenMaterial> = []
    public var frontenFreitext: String = ""
    /// Gewählte Artikel aus Katalog (artielbRecordID → Freitext-Override)
    public var frontenArtikel: [FragebogenArtikelAuswahl] = []

    // MARK: - Sektion 5: Arbeitsplatten (Gerät-Sektion)
    public var arbeitsplattenMaterial: Set<ArbeitsplattenMaterial> = []
    public var arbeitsplattenFreitext: String = ""
    public var arbeitsplattenArtikel: [FragebogenArtikelAuswahl] = []

    // MARK: - Sektion 6: Kochfeld (Gerät-Sektion)
    public var kochfeldTyp: Set<KochfeldTyp> = []
    public var kochfeldFreitext: String = ""
    public var kochfeldArtikel: [FragebogenArtikelAuswahl] = []

    // MARK: - Sektion 7: Dunstabzug
    public var dunstabzugTyp: Set<DunstabzugTyp> = []
    public var dunstabzugFreitext: String = ""

    // MARK: - Sektion 8: Beleuchtung
    public var beleuchtung: Set<Beleuchtung> = []
    public var beleuchtungFreitext: String = ""

    // MARK: - Sektion 9: Backofen / Einbaugeräte (Gerät-Sektion)
    public var backofenTyp: Set<BackofenTyp> = []
    public var backofenFreitext: String = ""
    public var backofenArtikel: [FragebogenArtikelAuswahl] = []

    // MARK: - Sektion 10: Spüle & Armatur
    public var spuelTyp: Set<SpuelTyp> = []
    public var spuelFreitext: String = ""

    // MARK: - Sektion 11: Kühlgeräte
    public var kuehlgeraete: Set<Kuehlgeraet> = []
    public var kuehlgeraeteFreitext: String = ""

    // MARK: - Sektion 12: Schubladen & Auszüge
    public var schubladen: Set<SchubladenTyp> = []
    public var schubladenFreitext: String = ""

    // MARK: - Sektion 13: Inneneinteilung / Ordnung
    public var inneneinteilung: Set<Inneneinteilung> = []
    public var inneneinteilungFreitext: String = ""

    // MARK: - Sektion 14: Hängeschränke
    public var haengeschraenke: Set<Haengeschraenk> = []
    public var haengeschraenkeFreitext: String = ""

    // MARK: - Sektion 15: Haushaltsgeräte / Weiße Ware (Gerät-Sektion)
    public var haushaltsgerate: Set<Haushaltgeraet> = []
    public var haushaltsgeraeteFreitext: String = ""
    public var haushaltsgeraeteArtikel: [FragebogenArtikelAuswahl] = []

    // MARK: - Sektion 16: Besondere Wünsche Technik (Gerät-Sektion)
    public var technikWuensche: Set<TechnikWunsch> = []
    public var technikFreitext: String = ""
    public var technikArtikel: [FragebogenArtikelAuswahl] = []

    // MARK: - Sektion 17: Planung & Zeitplan
    public var planungsphase: Planungsphase = .erstgespraech
    public var wunschtermin: String = ""
    public var planungsFreitext: String = ""

    // MARK: - Sektion 18: Budget-Kategorie
    public var budgetKategorie: BudgetKategorie = .mittel
    public var budgetKategorieFreitext: String = ""

    // MARK: - Sektion 19: Quelle / Wie auf uns aufmerksam?
    public var quelle: Set<Kundenquelle> = []
    public var quelleFreitext: String = ""

    // MARK: - Sektion 20: Bestandsküche
    public var bestandskueche: BestandsKueche = .nein
    public var bestandsFreitext: String = ""

    // MARK: - Sektion 21: Anschlüsse & Bauzustand
    public var anschluesse: Set<Anschluss> = []
    public var anschluessFreitext: String = ""

    // MARK: - Sektion 22: Sonderwünsche & Notizen
    public var sonderwuensche: String = ""

    // MARK: - Sektion 23: Entscheidungsstruktur
    public var entscheidungstraeger: EntscheidungsTraeger = .alleine
    public var entscheidungFreitext: String = ""

    // MARK: - Sektion 24: Nächster Schritt
    public var naechsterSchritt: NaechsterSchritt = .angebot
    public var naechsterSchrittFreitext: String = ""

    // MARK: - Validierung

    /// Universelles Mindest-Pflichtfeld für ALLE Stufen: der Nachname. Die feineren,
    /// stufenspezifischen Minima (Kontaktweg für „Kontakt", Projektname für „Lead",
    /// STR-Nr-fähige Adresse für „Projekt mit Ordner") werden in der Bestätigungs-
    /// ansicht anhand des `IntakeErgebnis` geprüft (siehe `IntakeAdresse`/`FragebogenView`).
    public var istAusgefuelltGenug: Bool {
        !kundeNachname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var vollstaendigerKundeName: String {
        let vorname = kundeVorname.trimmingCharacters(in: .whitespacesAndNewlines)
        let nachname = kundeNachname.trimmingCharacters(in: .whitespacesAndNewlines)
        if vorname.isEmpty { return nachname }
        return "\(vorname) \(nachname)"
    }

    public init() {}

    /// Härtung (2026-07-01, Johannes: "Verwerfen"-Button): setzt JEDES Feld auf seinen
    /// Init-Default zurück — genutzt vom expliziten "Verwerfen" in FragebogenView UND vom
    /// automatischen Zurücksetzen nach erfolgreichem "Jetzt anlegen" (siehe dort). Bewusst
    /// keine neue Instanz (die würde das @Bindable-Binding der View brechen) — dieselbe
    /// Instanz wird in-place auf den Leerzustand zurückgesetzt.
    public func reset() {
        kundeVorname = ""; kundeNachname = ""; kundeFirma = ""
        kundeEmail = ""; kundeTelefon = ""
        kundeStrasse = ""; kundePLZ = ""; kundeOrt = ""

        projektName = ""; projektStrasse = ""; projektPLZ = ""; projektOrt = ""
        projektStatus = "Lead"
        budget = nil; budgetText = ""

        raumBreite = ""; raumTiefe = ""; raumHoeheText = ""
        raumform = .rechteckig; raumformFreitext = ""

        einbausituation = []; einbausituationFreitext = ""
        stil = []; stilFreitext = ""
        griffkonzept = []; griffkonzeptFreitext = ""

        frontenMaterial = []; frontenFreitext = ""; frontenArtikel = []
        arbeitsplattenMaterial = []; arbeitsplattenFreitext = ""; arbeitsplattenArtikel = []
        kochfeldTyp = []; kochfeldFreitext = ""; kochfeldArtikel = []
        dunstabzugTyp = []; dunstabzugFreitext = ""
        beleuchtung = []; beleuchtungFreitext = ""
        backofenTyp = []; backofenFreitext = ""; backofenArtikel = []
        spuelTyp = []; spuelFreitext = ""
        kuehlgeraete = []; kuehlgeraeteFreitext = ""
        schubladen = []; schubladenFreitext = ""
        inneneinteilung = []; inneneinteilungFreitext = ""
        haengeschraenke = []; haengeschraenkeFreitext = ""
        haushaltsgerate = []; haushaltsgeraeteFreitext = ""; haushaltsgeraeteArtikel = []
        technikWuensche = []; technikFreitext = ""; technikArtikel = []

        planungsphase = .erstgespraech; wunschtermin = ""; planungsFreitext = ""
        budgetKategorie = .mittel; budgetKategorieFreitext = ""

        quelle = []; quelleFreitext = ""
        bestandskueche = .nein; bestandsFreitext = ""
        anschluesse = []; anschluessFreitext = ""
        sonderwuensche = ""
        entscheidungstraeger = .alleine; entscheidungFreitext = ""
        naechsterSchritt = .angebot; naechsterSchrittFreitext = ""
    }

    /// Härtung (2026-07-01, Johannes: "Verwerfen"-Button): ob überhaupt etwas Nennenswertes
    /// eingegeben wurde — steuert, ob "Verwerfen" ohne Rückfrage oder mit Sicherheitsabfrage
    /// ausgeführt wird (ein leeres Formular verwerfen braucht keine Bestätigung).
    /// Härtung (2026-07-01, Audit): geprüft wurden bisher NUR Kontakt/Projektname/Budget (7 von
    /// 74 Feldern) — wer z. B. nur Raum/Einbau/Stil/Geräte ausgefüllt hatte, verlor beim
    /// "Verwerfen" alles OHNE Sicherheitsabfrage. Jetzt EVERY Feld geprüft, die `reset()`
    /// zurücksetzt — nicht getrimmt vs. `.trim()`, sondern exakt gegen den `reset()`-Leerwert.
    public var hatNennenswerteEingaben: Bool {
        !kundeVorname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !kundeNachname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !kundeFirma.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !kundeEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !kundeTelefon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !kundeStrasse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !kundePLZ.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !kundeOrt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !projektName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !projektStrasse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !projektPLZ.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !projektOrt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || projektStatus != "Lead"
            || budget != nil
            || !budgetText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !raumBreite.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !raumTiefe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !raumHoeheText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || raumform != .rechteckig
            || !raumformFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !einbausituation.isEmpty
            || !einbausituationFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !stil.isEmpty
            || !stilFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !griffkonzept.isEmpty
            || !griffkonzeptFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !frontenMaterial.isEmpty
            || !frontenFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !frontenArtikel.isEmpty
            || !arbeitsplattenMaterial.isEmpty
            || !arbeitsplattenFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !arbeitsplattenArtikel.isEmpty
            || !kochfeldTyp.isEmpty
            || !kochfeldFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !kochfeldArtikel.isEmpty
            || !dunstabzugTyp.isEmpty
            || !dunstabzugFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !beleuchtung.isEmpty
            || !beleuchtungFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !backofenTyp.isEmpty
            || !backofenFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !backofenArtikel.isEmpty
            || !spuelTyp.isEmpty
            || !spuelFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !kuehlgeraete.isEmpty
            || !kuehlgeraeteFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !schubladen.isEmpty
            || !schubladenFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !inneneinteilung.isEmpty
            || !inneneinteilungFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !haengeschraenke.isEmpty
            || !haengeschraenkeFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !haushaltsgerate.isEmpty
            || !haushaltsgeraeteFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !haushaltsgeraeteArtikel.isEmpty
            || !technikWuensche.isEmpty
            || !technikFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !technikArtikel.isEmpty
            || planungsphase != .erstgespraech
            || !wunschtermin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !planungsFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || budgetKategorie != .mittel
            || !budgetKategorieFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !quelle.isEmpty
            || !quelleFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || bestandskueche != .nein
            || !bestandsFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !anschluesse.isEmpty
            || !anschluessFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !sonderwuensche.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || entscheidungstraeger != .alleine
            || !entscheidungFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || naechsterSchritt != .angebot
            || !naechsterSchrittFreitext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Härtung (2026-07-01, Audit): parst Budget-Eingaben im deutschen Zahlenformat
    /// (Punkt = Tausendertrenner, Komma = Dezimaltrenner) statt naiv nur ',' → '.' zu tauschen —
    /// das hätte "25.000" (25.000 €) auf 25.0 kollabiert und den falschen Wert unbemerkt nach
    /// Airtable geschrieben (kein HTTP-Fehler, da 25.0 ein gültiger Number-Wert ist).
    /// Heuristik: ein Komma ist immer der Dezimaltrenner (Punkte davor sind Tausendertrenner).
    /// Ohne Komma gilt ein Punkt mit genau 3 Nachkommastellen als Tausendertrenner (z. B.
    /// "25.000"), alles andere (z. B. "25.5") als normaler Dezimalpunkt.
    public static func parseGermanBudget(_ input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.contains(",") {
            let ohneTausenderpunkte = trimmed.replacingOccurrences(of: ".", with: "")
            return Double(ohneTausenderpunkte.replacingOccurrences(of: ",", with: "."))
        }
        if let punktIndex = trimmed.lastIndex(of: ".") {
            let nachPunkt = trimmed[trimmed.index(after: punktIndex)...]
            if nachPunkt.count == 3, nachPunkt.allSatisfy(\.isNumber) {
                return Double(trimmed.replacingOccurrences(of: ".", with: ""))
            }
        }
        return Double(trimmed)
    }
}

// MARK: - FragebogenArtikelAuswahl
// Eine im Fragebogen ausgewählte Artikel-Position (aus dem Katalog oder Freitext).
public struct FragebogenArtikelAuswahl: Identifiable, Sendable, Equatable {
    public let id: UUID
    /// Airtable-Record-ID des Artikels (nil = Freitext-Position)
    public let artikelRecordID: String?
    /// Bezeichnung (aus Katalog-Artikel oder Freitext)
    public var bezeichnung: String
    /// Artikelnummer (aus Katalog oder Freitext)
    public var artikelnummer: String
    public var menge: Int
    public var ekNetto: Double?
    public var vkNetto: Double?
    public var freitextOverride: String = ""

    public init(
        id: UUID = UUID(),
        artikelRecordID: String? = nil,
        bezeichnung: String,
        artikelnummer: String,
        menge: Int = 1,
        ekNetto: Double? = nil,
        vkNetto: Double? = nil,
        freitextOverride: String = ""
    ) {
        self.id = id
        self.artikelRecordID = artikelRecordID
        self.bezeichnung = bezeichnung
        self.artikelnummer = artikelnummer
        self.menge = menge
        self.ekNetto = ekNetto
        self.vkNetto = vkNetto
        self.freitextOverride = freitextOverride
    }
}

// MARK: - FragebogenTriggerStufe
// mykilOS: welche Schreibwirkung ein Fragebogen-Submit auslöst. Ausgewählt am
// letzten Dialog-Schritt (Bestätigungsansicht), NICHT auf der Projekt-Sektion —
// getrennt vom rein deskriptiven `projektStatus`-Feld.
public enum FragebogenTriggerStufe: String, CaseIterable, Sendable, Identifiable {
    /// Minimal: nur ein Kontakt (Google-Kontakt + Artikel-DB-Kunde). Kein Projekt,
    /// kein Drive-Ordner, kein Mastermind-Routing-Eintrag.
    case kontakt = "Nur Kontakt speichern"
    /// Kunde + Projekt (Artikel-DB, Projektstatus „Lead") + ein Rumpf-Ordner im
    /// echten Drive unter `PROJEKTE/_LEADS/` (nur Wurzelordner, keine Schema-
    /// Unterstruktur) + Mastermind-Routing-Eintrag (Phase „Lead", sichtbar in der Galerie).
    case lead = "Als Lead anlegen"
    /// Voller Umfang: Kunde + Projekt + kompletter Drive-Ordnerbaum im echten
    /// PROJEKTE-Root + Mastermind-Routing-Eintrag (Phase „Aktiv") + Fragebogen-PDF.
    case projektMitOrdner = "Projekt mit Ordner + allen Triggern"
    public var id: String { rawValue }
}

// MARK: - Enums für Mehrfachauswahl

public enum Raumform: String, CaseIterable, Sendable, Identifiable {
    case rechteckig = "Rechteckig"
    case lForm = "L-Form"
    case uForm = "U-Form"
    case parallelForm = "Parallel / Galley"
    case einzeilig = "Einzeilig"
    case inselkueche = "Inselküche"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum Einbausituation: String, CaseIterable, Sendable, Hashable, Identifiable {
    case neubau = "Neubau"
    case umbau = "Umbau / Renovierung"
    case bestandFreihalten = "Bestand bleibt (Teilerneuerung)"
    case anbau = "Anbau / Erweiterung"
    public var id: String { rawValue }
}

public enum KuecheStil: String, CaseIterable, Sendable, Hashable, Identifiable {
    case modern = "Modern / Minimalistisch"
    case klassisch = "Klassisch / Landhaus"
    case skandinavisch = "Skandinavisch"
    case industrial = "Industrial"
    case mediterran = "Mediterran / Naturton"
    case individuell = "Individuell / Frei geplant"
    public var id: String { rawValue }
}

public enum Griffkonzept: String, CaseIterable, Sendable, Hashable, Identifiable {
    case grifflos = "Grifflos (Jfroesse, Push-to-open)"
    case stangengriff = "Stangengriff"
    case knopfgriff = "Knopfgriff"
    case versenkt = "Versenkte Griffmulde"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum FrontenMaterial: String, CaseIterable, Sendable, Hashable, Identifiable {
    case matt = "Matt lackiert"
    case hochglanz = "Hochglanz lackiert"
    case holz = "Echtholz / Furnier"
    case melamin = "Melamin / Folie"
    case glas = "Glas"
    case beton = "Beton-Optik"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum ArbeitsplattenMaterial: String, CaseIterable, Sendable, Hashable, Identifiable {
    case granit = "Granit / Naturstein"
    case quarz = "Quarzkomposit (Silestone etc.)"
    case keramik = "Keramik / Feinsteinzeug"
    case holz = "Holz / Massivholz"
    case edelstahl = "Edelstahl"
    case laminat = "Schichtstoff / HPL"
    case beton = "Beton"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum KochfeldTyp: String, CaseIterable, Sendable, Hashable, Identifiable {
    case induktion = "Induktion"
    case gas = "Gas"
    case elektro = "Elektro (Glaskeramik)"
    case induktionWok = "Induktion + Wok-Zone"
    case tischkochfeld = "Tischkochfeld"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum DunstabzugTyp: String, CaseIterable, Sendable, Hashable, Identifiable {
    case wandhaube = "Wandhaube"
    case inselhaube = "Inselhaube"
    case flachschirmhaube = "Flachschirmhaube / integriert"
    case deckenabzug = "Deckenabzug / Deckenlüfter"
    case induktionMitAbzug = "Induktion mit integriertem Abzug"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum Beleuchtung: String, CaseIterable, Sendable, Hashable, Identifiable {
    case led = "LED-Unterbauleuchte"
    case spots = "Spots / Strahler"
    case pendelleuchte = "Pendelleuchte über Insel"
    case sockelbeleuchtung = "Sockelbeleuchtung"
    case glasboeden = "Glasböden beleuchtet"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum BackofenTyp: String, CaseIterable, Sendable, Hashable, Identifiable {
    case einbauOfen = "Einbaubackofen"
    case dampfofen = "Dampfofen / Kombidämpfer"
    case mikrowelleKombi = "Mikrowellen-Kombi"
    case wärmeschublade = "Wärmeschublade"
    case kaffeevollaut = "Kaffeevollautomat (eingebaut)"
    case weinkuehlschrank = "Weinkühlschrank"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum SpuelTyp: String, CaseIterable, Sendable, Hashable, Identifiable {
    case einzel = "Einzelspüle"
    case doppel = "Doppelspüle"
    case unterflur = "Unterbaumont. / Flush-Mount"
    case granit = "Granit-Spüle"
    case edelstahl = "Edelstahlspüle"
    case keramik = "Keramikspüle"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum Kuehlgeraet: String, CaseIterable, Sendable, Hashable, Identifiable {
    case einbauKuehlschrank = "Einbaukühlschrank"
    case gefrierschrank = "Gefrierschrank / -fach"
    case amerikanerFridge = "Side-by-Side"
    case frigoBlock = "Kühl-Gefrier-Kombination"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum SchubladenTyp: String, CaseIterable, Sendable, Hashable, Identifiable {
    case vollauszug = "Vollauszug"
    case softclose = "Softclose / Pushopen"
    case topfauszug = "Töpfe-/Innenauszug"
    case besteckeinsatz = "Besteck-Einsatz"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum Inneneinteilung: String, CaseIterable, Sendable, Hashable, Identifiable {
    case orga = "Organizer-Einsätze"
    case muelltrennung = "Mülltrennung / Abfalleinsatz"
    case eckschrank = "Eckauszug / Le-Mans"
    case hochraum = "Hochraumschrank-System"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum Haengeschraenk: String, CaseIterable, Sendable, Hashable, Identifiable {
    case standard = "Standard"
    case bisDecke = "Bis zur Decke"
    case offen = "Offene Regalzone"
    case kein = "Keine Hängeschränke"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum Haushaltgeraet: String, CaseIterable, Sendable, Hashable, Identifiable {
    case geschirrspueler = "Geschirrspüler"
    case waschmaschine = "Waschmaschine"
    case trockner = "Trockner"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum TechnikWunsch: String, CaseIterable, Sendable, Hashable, Identifiable {
    case kabelloseLaden = "Induktives Laden (Qi)"
    case smarthome = "Smart-Home-Integration"
    case sprachsteuerung = "Sprachsteuerung"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum Planungsphase: String, CaseIterable, Sendable, Identifiable {
    case erstgespraech = "Erstgespräch"
    case planung = "Planung läuft"
    case angebot = "Angebot gewünscht"
    case auftrag = "Auftrag bereit"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum BudgetKategorie: String, CaseIterable, Sendable, Identifiable {
    case kompakt = "Kompakt (< 15.000 €)"
    case mittel = "Mittel (15.000–30.000 €)"
    case premium = "Premium (30.000–60.000 €)"
    case exklusiv = "Exklusiv (> 60.000 €)"
    public var id: String { rawValue }
}

public enum Kundenquelle: String, CaseIterable, Sendable, Hashable, Identifiable {
    case empfehlung = "Empfehlung"
    case instagram = "Instagram / Social Media"
    case google = "Google / Internet"
    case messe = "Messe / Event"
    case architekt = "Architekt / Planer"
    case stammkunde = "Stammkunde"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum BestandsKueche: String, CaseIterable, Sendable, Identifiable {
    case nein = "Nein, Neukauf"
    case teilerneuerung = "Teilweise erneuern"
    case behaltenNeu = "Teile behalten, Ergänzung"
    public var id: String { rawValue }
}

public enum Anschluss: String, CaseIterable, Sendable, Hashable, Identifiable {
    case gas = "Gas vorhanden"
    case druckluftwasser = "Druckwasser vorhanden"
    case abwasser = "Abwasseranschluss OK"
    case starkstrom = "Starkstrom (400V) vorhanden"
    case lueftung = "Lüftungskanal / Abluftkanal"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}

public enum EntscheidungsTraeger: String, CaseIterable, Sendable, Identifiable {
    case alleine = "Alleine"
    case partner = "Partner / Familie entscheidet mit"
    case architekt = "Architekt / Planer entscheidet mit"
    public var id: String { rawValue }
}

public enum NaechsterSchritt: String, CaseIterable, Sendable, Identifiable {
    case angebot = "Angebot erstellen"
    case aufmass = "Aufmaß Termin"
    case beratung = "Weitere Beratung"
    case referenzobjekte = "Referenzobjekte zeigen"
    case sonstige = "Sonstige"
    public var id: String { rawValue }
}
