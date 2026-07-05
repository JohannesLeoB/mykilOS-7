import Testing
import Foundation
@testable import MykilosServices

// MARK: - DriveFolderCategoryTests (D3 — Parent-Ordner-Herkunft)
// Reine, testbare Klassifikation eines Datei-Eltern-Ordnernamens auf eine
// Herkunfts-Kategorie. Deckt Diakritik-/Groß-Klein-Toleranz, Prioritäts-
// Eindeutigkeit (matchOrder), die realen MYKILOS-Ordnernamen und die
// Nichts-Treffer-Fälle ab (nil = keine Sackgasse in der UI).

struct DriveFolderCategoryTests {

    // (a) Reale MYKILOS-Ordnernamen treffen die erwartete Kategorie.
    @Test func matchtRealeOrdnernamen() {
        #expect(DriveFolderCategory.category(forFolderName: "04 ausgehende Angebote") == .angebote)
        #expect(DriveFolderCategory.category(forFolderName: "05 eingehende Angebote") == .angebote)
        #expect(DriveFolderCategory.category(forFolderName: "01 Pläne") == .zeichnungen)
        #expect(DriveFolderCategory.category(forFolderName: "08 Werkszeichnung") == .zeichnungen)
        #expect(DriveFolderCategory.category(forFolderName: "Präsentation") == .praesentation)
        #expect(DriveFolderCategory.category(forFolderName: "01 INFOS") == .infos)
    }

    // (b) Diakritik-/Groß-Klein-Toleranz.
    @Test func matchtDiakritikTolerant() {
        #expect(DriveFolderCategory.category(forFolderName: "PRÄSENTATION") == .praesentation)
        #expect(DriveFolderCategory.category(forFolderName: "praesentation") == .praesentation)
        #expect(DriveFolderCategory.category(forFolderName: "PLÄNE ALT") == .zeichnungen)
        #expect(DriveFolderCategory.category(forFolderName: "plaene") == .zeichnungen)
    }

    // (c) matchOrder: spezifischste Signale gewinnen. "01 INFOS/Angebote" ist
    //     Angebote, nicht Infos (Angebote wird zuerst geprüft).
    @Test func prioritaetIstEindeutig() {
        #expect(DriveFolderCategory.category(forFolderName: "Infos Angebote") == .angebote)
        #expect(DriveFolderCategory.category(forFolderName: "Layout Pläne") == .zeichnungen)
        // Reine "Info"-Ordner bleiben Infos.
        #expect(DriveFolderCategory.category(forFolderName: "01 INFOS Allgemein") == .infos)
    }

    // (d) Renderings/Moodboard zählen zur Präsentations-Herkunft.
    @Test func renderingsUndMoodboardSindPraesentation() {
        #expect(DriveFolderCategory.category(forFolderName: "07 Renderings") == .praesentation)
        #expect(DriveFolderCategory.category(forFolderName: "Moodboard") == .praesentation)
    }

    // (e) Kein Treffer → nil (die UI zeigt dann keinen Farbpunkt, keine Sackgasse).
    @Test func unbekannteOrdnerLiefernNil() {
        #expect(DriveFolderCategory.category(forFolderName: "02 Fotos Bestand") == nil)
        #expect(DriveFolderCategory.category(forFolderName: "Sonstiges") == nil)
        #expect(DriveFolderCategory.category(forFolderName: "") == nil)
        #expect(DriveFolderCategory.category(forFolderName: nil) == nil)
    }

    // (f) chipLabel ist VERSAL und stabil je Kategorie.
    @Test func chipLabelIstVersal() {
        for category in DriveFolderCategory.allCases {
            #expect(category.chipLabel == category.chipLabel.uppercased())
        }
        #expect(DriveFolderCategory.angebote.chipLabel == "ANGEBOTE")
        #expect(DriveFolderCategory.zeichnungen.chipLabel == "ZEICHNUNGEN")
    }

    // (g) Kollision zweier ECHTER Signalklassen: bei "Angebot" UND "Zeichnung"
    //     im selben Namen gewinnt Angebote (steht in matchOrder vor Zeichnungen).
    @Test func kollisionAngeboteSchlaegtZeichnung() {
        #expect(DriveFolderCategory.category(forFolderName: "Angebot Zeichnung Meyer") == .angebote)
        #expect(DriveFolderCategory.category(forFolderName: "Zeichnung Angebot Meyer") == .angebote)
        // Zeichnung UND Präsentation → Zeichnung gewinnt (steht davor).
        #expect(DriveFolderCategory.category(forFolderName: "Plan Rendering") == .zeichnungen)
    }

    // (h) Weitere Infos-Schlüsselwörter (nicht das generische "info") treffen
    //     eindeutig — decken die bisher ungetesteten Zweige ab.
    @Test func infosSpezifischeSchluesselwoerter() {
        #expect(DriveFolderCategory.category(forFolderName: "Schriftverkehr") == .infos)
        #expect(DriveFolderCategory.category(forFolderName: "Korrespondenz Kunde") == .infos)
    }

    // (h2) Dokumentierter Prioritäts-Quirk (KEIN Bug-Fix, nur festgehalten):
    //     Der Infos-Schlüsselbegriff "vorplanung" enthält das Substring "plan",
    //     und "plan" (Zeichnungen) steht in matchOrder VOR Infos. Ein Ordner
    //     "Vorplanung" wird daher als .zeichnungen erkannt, nie als .infos.
    //     Der Test nagelt das Ist-Verhalten fest, ohne die Logik zu ändern.
    @Test func vorplanungWirdWegenSubstringPlanAlsZeichnungErkannt() {
        #expect(DriveFolderCategory.category(forFolderName: "06 Vorplanung") == .zeichnungen)
    }

    // (i) Tipp-/Schreibvarianten und CAD greifen (typo-tolerante Keywords + ASCII).
    @Test func schreibvariantenUndCadGreifen() {
        #expect(DriveFolderCategory.category(forFolderName: "Moodbord") == .praesentation)  // Tippfehler-Variante
        #expect(DriveFolderCategory.category(forFolderName: "CAD Export") == .zeichnungen)
        #expect(DriveFolderCategory.category(forFolderName: "cad") == .zeichnungen)
        #expect(DriveFolderCategory.category(forFolderName: "Presentation") == .praesentation)  // ohne Umlaut
    }

    // (j) Diakritik-Naheschüsse dürfen NICHT fälschlich matchen (kein Substring-
    //     Übergriff nach der Faltung). "Präzision" faltet zu "prazision" —
    //     enthält NICHT "prasentation" → korrekt nil.
    @Test func diakritikNaheschussBleibtNil() {
        #expect(DriveFolderCategory.category(forFolderName: "Präzision") == nil)
        #expect(DriveFolderCategory.category(forFolderName: "Kläranlage") == nil)
        #expect(DriveFolderCategory.category(forFolderName: "   ") == nil)   // nur Whitespace, keine Keywords
    }
}
