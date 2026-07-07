import Testing
import Foundation
@testable import MykilosApp

// MARK: - HilfeViewParseTests
//
// Reiner Parser-Test für das In-App-Handbuch (HilfeView): zerlegt Markdown an jeder
// `## `-Überschrift; der `# `-Titel eröffnet den Einleitungs-Abschnitt, alles davor
// gehört zu ihm. `### ` ist KEINE Sektionsgrenze. Kein Bundle, kein Netzwerk.
@MainActor
struct HilfeViewParseTests {

    @Test func teiltAnUeberschriftenUndFaengtEinleitungAb() {
        let markdown = """
        # Handbuch
        Einleitungszeile.

        ## Erster Abschnitt
        Inhalt A1
        Inhalt A2

        ## Zweiter Abschnitt
        Inhalt B1
        """
        let sektionen = HilfeView.parse(markdown)
        #expect(sektionen.count == 3)
        #expect(sektionen[0].titel == "Handbuch")
        #expect(sektionen[0].rohtext.contains("Einleitungszeile."))
        #expect(sektionen[1].titel == "Erster Abschnitt")
        #expect(sektionen[1].rohtext.contains("Inhalt A1"))
        #expect(sektionen[1].rohtext.contains("Inhalt A2"))
        #expect(sektionen[2].titel == "Zweiter Abschnitt")
        #expect(sektionen[2].rohtext.contains("Inhalt B1"))
    }

    @Test func stabileEindeutigeIDs() {
        let sektionen = HilfeView.parse("## A\nx\n## B\ny\n## C\nz")
        #expect(sektionen.map(\.id) == [0, 1, 2])
        #expect(Set(sektionen.map(\.id)).count == sektionen.count)
    }

    @Test func ohneTitelKeineSektionen() {
        // Nur Fließtext ohne jede Überschrift → keine Sektion (nichts zu strukturieren).
        let sektionen = HilfeView.parse("nur text\nzweite zeile")
        #expect(sektionen.isEmpty)
    }

    @Test func unterUeberschriftIstKeineSektionsgrenze() {
        // `### ` bleibt Inhalt der aktuellen `## `-Sektion, wird nicht zur eigenen Sektion.
        let sektionen = HilfeView.parse("## A\n### Unterpunkt\nZeile")
        #expect(sektionen.count == 1)
        #expect(sektionen[0].titel == "A")
        #expect(sektionen[0].rohtext.contains("### Unterpunkt"))
    }
}
