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
}
