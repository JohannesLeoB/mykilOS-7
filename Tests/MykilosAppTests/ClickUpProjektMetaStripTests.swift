import Testing
import Foundation
import MykilosKit
@testable import MykilosApp

// MARK: - ClickUpProjektMetaStrip.chips (CLICKUP_DATENINTEGRATION Schritt 2, 2026-07-07)
// Reine Chip-Ableitung — nur gesetzte Felder, in stabiler Reihenfolge, nichts erfunden.

struct ClickUpProjektMetaStripTests {

    @Test func leeresMetaErgibtKeineChips() {
        #expect(ClickUpProjektMetaStrip.chips(from: .empty).isEmpty)
    }

    @Test func nurGesetzteFelderErscheinen() {
        let meta = ClickUpProjektMeta(ort: "Hamburg", lead: "Jo")
        let chips = ClickUpProjektMetaStrip.chips(from: meta)
        #expect(chips.count == 2)
        #expect(chips.contains { $0.label == "Ort" && $0.value == "Hamburg" })
        #expect(chips.contains { $0.label == "Lead" && $0.value == "Jo" })
        // Nicht gesetzte Felder tauchen NICHT auf.
        #expect(chips.contains { $0.label == "Budget" } == false)
    }

    @Test func reihenfolgeIstStabil() {
        // Budget zuerst, dann Daten, dann Ort/Lead/Typ/Risiko, dann Lieferanten.
        let meta = ClickUpProjektMeta(
            budget: 15000,
            naechstesNachfassen: Date(timeIntervalSince1970: 1_800_000_000),
            ort: "Kiel",
            lieferanten: ["Häfele", "Blum"]
        )
        let labels = ClickUpProjektMetaStrip.chips(from: meta).map(\.label)
        #expect(labels == ["Budget", "Nachfassen", "Ort", "Lieferanten"])
    }

    @Test func budgetWirdAlsWaehrungFormatiert() {
        let chips = ClickUpProjektMetaStrip.chips(from: ClickUpProjektMeta(budget: 15000))
        let budget = chips.first { $0.label == "Budget" }
        // de_DE-Währung: enthält den Betrag und das Euro-Zeichen (exakte Formatierung locale-abhängig).
        #expect(budget?.value.contains("€") == true)
        #expect(budget?.value.contains("15") == true)
    }

    @Test func lieferantenWerdenKommaVerbunden() {
        let chips = ClickUpProjektMetaStrip.chips(from: ClickUpProjektMeta(lieferanten: ["Häfele", "Blum", "Hettich"]))
        #expect(chips.first { $0.label == "Lieferanten" }?.value == "Häfele, Blum, Hettich")
    }

    @Test func leereLieferantenListeErscheintNicht() {
        let chips = ClickUpProjektMetaStrip.chips(from: ClickUpProjektMeta(lieferanten: []))
        #expect(chips.contains { $0.label == "Lieferanten" } == false)
    }
}
