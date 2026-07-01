import Testing
import Foundation
@testable import MykilosKit

// Block C / S2: die reine Nomenklatur-Domain (Projektnummer, STR-Nr, FolderSchema,
// Anti-Duplikat). Alles ohne GRDB/Netzwerk — reine, deterministische Logik.
struct NomenklaturTests {

    // MARK: Projektnummer

    @Test func projektnummerParstTolerantUndNormalisiert() {
        #expect(Projektnummer(parsing: "2026_030")?.appFormat == "2026-030")
        #expect(Projektnummer(parsing: "2026-15")?.appFormat == "2026-015")        // führende Null ergänzt
        #expect(Projektnummer(parsing: "2026_20_Liebig_Quooker")?.appFormat == "2026-020") // Anomalie normalisiert + Slug ignoriert
        #expect(Projektnummer(parsing: "2026_015_Schmidt_HEI8")?.appFormat == "2026-015")   // Slug ignoriert
        #expect(Projektnummer(parsing: "kein Datum") == nil)
        #expect(Projektnummer(parsing: "") == nil)
    }

    @Test func projektnummerDriveFormatUndVergleich() {
        let a = Projektnummer(jahr: 2026, laufendeNummer: 30)
        #expect(a.driveFormat == "2026_030")
        #expect(a.appFormat == "2026-030")
        #expect(Projektnummer(jahr: 2026, laufendeNummer: 5) < a)
        #expect(Projektnummer(jahr: 2025, laufendeNummer: 99) < Projektnummer(jahr: 2026, laufendeNummer: 1))
    }

    @Test func nextIstStriktMaxPlusEinsOhneLueckenAuffuellen() {
        // Bestand: 001-004, 006, 007, 012-029 → nächste MUSS 030 sein (nicht 005/008).
        let vorhandene = ([1,2,3,4,6,7] + Array(12...29)).map { Projektnummer(jahr: 2026, laufendeNummer: $0) }
        let next = Projektnummer.next(jahr: 2026, vorhandene: vorhandene)
        #expect(next.appFormat == "2026-030")
    }

    @Test func nextStartetBeiEinsWennJahrLeer() {
        let next = Projektnummer.next(jahr: 2027, vorhandene: [Projektnummer(jahr: 2026, laufendeNummer: 99)])
        #expect(next.appFormat == "2027-001")
    }

    // MARK: STR-Nr

    @Test func strNummerAdresseAbgekuerzt() {
        // HEI8 = Heimhuder 8; Umlaut-Transliteration KOE/MUE.
        #expect(STRNummer.bilde(strasse: "Heimhuder", hausnummer: "8", ort: nil) == .gebildet("HEI8", quelle: .adresse))
        #expect(STRNummer.bilde(strasse: "Königstraße", hausnummer: "66", ort: nil) == .gebildet("KOE66", quelle: .adresse))
        #expect(STRNummer.bilde(strasse: "Müllerweg", hausnummer: "71", ort: nil) == .gebildet("MUE71", quelle: .adresse))
    }

    @Test func strNummerOrtFallback() {
        let r = STRNummer.bilde(strasse: nil, hausnummer: nil, ort: "Paris")
        #expect(r == .gebildet("PAR", quelle: .ort))
    }

    @Test func strNummerVarianteNurAufWhitelist() {
        #expect(STRNummer.bilde(strasse: nil, hausnummer: nil, ort: nil, variante: "Quooker") == .gebildet("QUOOKER", quelle: .variante))
        // Nicht-Whitelist-Variante → nicht bildbar (Warnung).
        if case .nichtBildbar = STRNummer.bilde(strasse: nil, hausnummer: nil, ort: nil, variante: "Irgendwas") {} else {
            Issue.record("Nicht-Whitelist-Variante hätte nichtBildbar liefern müssen")
        }
    }

    @Test func strNummerNichtsBildbarWarntUndBlockt() {
        if case .nichtBildbar = STRNummer.bilde(strasse: nil, hausnummer: nil, ort: nil) {} else {
            Issue.record("Ohne Adresse/ORT/Variante hätte nichtBildbar geliefert werden müssen")
        }
    }

    // MARK: STRNummer.splitStrasseHausnummer (Fragebogen: kombiniertes "Straße + Nr."-Feld)

    @Test func splitStrasseHausnummerTrennteinfacheHausnummer() {
        let r = STRNummer.splitStrasseHausnummer("Heimhuder 8")
        #expect(r.strasse == "Heimhuder")
        #expect(r.hausnummer == "8")
    }

    @Test func splitStrasseHausnummerTrenntBuchstabenSuffix() {
        let r = STRNummer.splitStrasseHausnummer("Königstraße 12a")
        #expect(r.strasse == "Königstraße")
        #expect(r.hausnummer == "12a")
    }

    @Test func splitStrasseHausnummerTrenntBindestrichBereich() {
        let r = STRNummer.splitStrasseHausnummer("Müllerweg 3-5")
        #expect(r.strasse == "Müllerweg")
        #expect(r.hausnummer == "3-5")
    }

    // Review-Fix: Leerzeichen-vor-Suffix und Schrägstrich-Zusatz wurden vorher NICHT erkannt.
    @Test func splitStrasseHausnummerTrenntLeerzeichenVorBuchstabenSuffix() {
        let r = STRNummer.splitStrasseHausnummer("An der Alster 10 b")
        #expect(r.strasse == "An der Alster")
        #expect(r.hausnummer?.contains("10") == true)
    }

    @Test func splitStrasseHausnummerTrenntSchraegstrichZusatz() {
        let r = STRNummer.splitStrasseHausnummer("Wiesenweg 4/2")
        #expect(r.strasse == "Wiesenweg")
        #expect(r.hausnummer?.contains("4") == true)
    }

    @Test func splitStrasseHausnummerOhneErkennbareHausnummerBleibtGanzStrasse() {
        let r = STRNummer.splitStrasseHausnummer("Nur ein Straßenname")
        #expect(r.strasse == "Nur ein Straßenname")
        #expect(r.hausnummer == nil)
    }

    @Test func splitStrasseHausnummerNilUndLeerBleibenNil() {
        #expect(STRNummer.splitStrasseHausnummer(nil).strasse == nil)
        #expect(STRNummer.splitStrasseHausnummer("").strasse == nil)
        #expect(STRNummer.splitStrasseHausnummer("   ").strasse == nil)
    }

    // MARK: FolderSchema

    @Test func folderSchemaV1HatDokumentiertenBaum() {
        let pfade = FolderSchema.v1.allePfade()
        #expect(pfade.contains("01 INFOS/07 Fragebogen"))
        #expect(pfade.contains("02 CAD/VectorWorks"))
        #expect(pfade.contains("03 PRÄSENTATION/PDF"))
        #expect(FolderSchema.v1.rootDateien.contains("MYKILOS_Abnahmeprotokoll BLANKO.pdf"))
        #expect(FolderSchema.v1.version == 1)
    }

    @Test func ordnerKonnektorenMappenAufSchema() {
        let fragebogen = OrdnerKonnektor.v1Defaults.first { $0.slot == .fragebogen }
        #expect(fragebogen?.relativerPfad == "01 INFOS/07 Fragebogen")
        // Jeder Slot ist genau einmal abgedeckt.
        #expect(Set(OrdnerKonnektor.v1Defaults.map(\.slot)).count == OrdnerKonnektor.v1Defaults.count)
    }

    // MARK: Anti-Duplikat

    @Test func antiDuplikatFindetKundennummerUndName() {
        let bestand = [
            Customer(customerNumber: "K-1001", name: "Familie Meyer"),
            Customer(customerNumber: "K-1002", name: "Schmidt GmbH"),
        ]
        // Kdnr-Treffer (stärkster).
        let t1 = AntiDuplikat.pruefeKunde(DuplikatKandidat(kundennummer: "K-1001"), bestand: bestand)
        #expect(t1.first?.grund == .kundennummer)
        // Name-Treffer (schwächer, diakritik-/case-insensitiv).
        let t2 = AntiDuplikat.pruefeKunde(DuplikatKandidat(name: "familie meyer"), bestand: bestand)
        #expect(t2.contains { $0.grund == .name && $0.customerNumber == "K-1001" })
        // Kein Treffer.
        let t3 = AntiDuplikat.pruefeKunde(DuplikatKandidat(name: "Unbekannt"), bestand: bestand)
        #expect(t3.isEmpty)
    }

    @Test func antiDuplikatEmailUeberKontakte() {
        let kontakte = [StudioContact(id: "c1", name: "Meyer", email: "meyer@x.de", telefon: "040 123")]
        let treffer = AntiDuplikat.pruefeKunde(DuplikatKandidat(email: "MEYER@X.DE"), bestand: [], kontakte: kontakte)
        #expect(treffer.first?.grund == .email)
    }
}
