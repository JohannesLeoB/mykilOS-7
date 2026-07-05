import Testing
import Foundation
@testable import MykilosWidgets

// MARK: - RechnerModelTests
// Additive Härtung der reinen, immediate-execution Rechenlogik im RechnerWidget.
// KEINE Verhaltensänderung am Code — nur die vorhandene Logik festgenagelt:
// verkettete Operationen (kein Operator-Vorrang), Division durch 0, Backspace,
// Dezimalpunkt-Einmaligkeit, Clear-Reset, Format großer/ganzer Zahlen.
// RechnerModel ist @MainActor, deshalb die Suite auch.
@MainActor
struct RechnerModelTests {

    // Ein Ausdruck als Ziffern/Operatoren tippen. Operatoren als Anzeige-Symbole
    // (− × ÷ +), so wie die Tastatur/Tasten sie an das Model geben.
    private func evaluate(_ steps: [String]) -> String {
        let model = RechnerModel()
        for step in steps {
            switch step {
            case "+", "−", "×", "÷": model.tapOperator(step)
            case "=":                model.tapEquals()
            case ".":                model.tapDecimal()
            case "C":                model.tapClear()
            default:                 for ch in step { model.tapDigit(String(ch)) }
            }
        }
        return model.display
    }

    // MARK: Startzustand
    @Test func startetBeiNull() {
        #expect(RechnerModel().display == "0")
    }

    // MARK: Verkettung ist immediate-execution (KEIN Operator-Vorrang)
    // 3 + 4 × 2 wird links-nach-rechts gefaltet: (3+4)=7, dann 7×2 = 14.
    // (Ein Rechner MIT Vorrang käme auf 11 — der Test nagelt bewusst die
    // dokumentierte Braun-ET66-Semantik fest.)
    @Test func verketteteOperationenImmediateExecution() {
        #expect(evaluate(["3", "+", "4", "×", "2", "="]) == "14")
    }

    @Test func einfacheAdditionUndSubtraktion() {
        #expect(evaluate(["7", "+", "8", "="]) == "15")
        #expect(evaluate(["2", "0", "−", "5", "="]) == "15")
    }

    @Test func multiplikationUndDivision() {
        #expect(evaluate(["6", "×", "7", "="]) == "42")
        #expect(evaluate(["8", "÷", "2", "="]) == "4")
    }

    // Operator ohne "=" wendet den vorherigen Schritt sofort an (Zwischenergebnis).
    @Test func operatorFaltetZwischenergebnisSofort() {
        let model = RechnerModel()
        model.tapDigit("1"); model.tapDigit("0")
        model.tapOperator("+")
        model.tapDigit("5")
        model.tapOperator("+")      // hier wird 10+5 = 15 sofort gefaltet
        #expect(model.display == "15")
        model.tapDigit("5")
        model.tapEquals()           // 15 + 5 = 20
        #expect(model.display == "20")
    }

    // MARK: Division durch 0 → "Fehler"
    @Test func divisionDurchNullGibtFehler() {
        #expect(evaluate(["5", "÷", "0", "="]) == "Fehler")
    }

    @Test func divisionDurchNullFehlerBleibtBisClear() {
        let model = RechnerModel()
        model.tapDigit("9"); model.tapOperator("÷"); model.tapDigit("0"); model.tapEquals()
        #expect(model.display == "Fehler")
        // Neue Ziffer startet frisch (typingNew war nach dem Fehler gesetzt).
        model.tapDigit("4")
        #expect(model.display == "4")
    }

    // MARK: Backspace läuft bis "0" zurück
    @Test func backspaceLoeschtStellenBisNull() {
        let model = RechnerModel()
        model.tapDigit("1"); model.tapDigit("2"); model.tapDigit("3")
        #expect(model.display == "123")
        model.tapBackspace(); #expect(model.display == "12")
        model.tapBackspace(); #expect(model.display == "1")
        model.tapBackspace(); #expect(model.display == "0")   // leer → "0"
        model.tapBackspace(); #expect(model.display == "0")   // bleibt "0"
    }

    // Backspace auf einem frisch berechneten/neu-getippten Wert fällt auf "0".
    @Test func backspaceAufFrischemErgebnisGibtNull() {
        let model = RechnerModel()
        model.tapDigit("6"); model.tapOperator("×"); model.tapDigit("7"); model.tapEquals()
        #expect(model.display == "42")
        model.tapBackspace()                    // typingNew == true → "0"
        #expect(model.display == "0")
    }

    // MARK: Mehrfacher Dezimalpunkt wird ignoriert
    @Test func mehrfacherDezimalpunktIgnoriert() {
        let model = RechnerModel()
        model.tapDigit("1"); model.tapDecimal(); model.tapDigit("5")
        #expect(model.display == "1.5")
        model.tapDecimal()                      // zweiter Punkt → ignoriert
        #expect(model.display == "1.5")
        model.tapDigit("7")
        #expect(model.display == "1.57")
    }

    // Dezimalpunkt als erste Eingabe erzeugt "0.".
    @Test func fuehrenderDezimalpunktGibtNullKomma() {
        let model = RechnerModel()
        model.tapDecimal()
        #expect(model.display == "0.")
        model.tapDigit("5")
        #expect(model.display == "0.5")
    }

    // MARK: Clear setzt alles zurück
    @Test func clearSetztKomplettZurueck() {
        let model = RechnerModel()
        model.tapDigit("9"); model.tapOperator("+"); model.tapDigit("9")
        model.tapClear()
        #expect(model.display == "0")
        // Nach Clear rechnet ein frischer Ausdruck ohne Alt-Akkumulator weiter.
        model.tapDigit("2"); model.tapOperator("+"); model.tapDigit("3"); model.tapEquals()
        #expect(model.display == "5")
    }

    // MARK: Format — ganze Zahlen ohne Nachkommastelle, führende Null geschluckt
    @Test func ganzzahligesErgebnisOhneKomma() {
        #expect(evaluate(["1", "0", "÷", "4", "×", "4", "="]) == "10")
    }

    @Test func fuehrendeNullWirdErsetzt() {
        let model = RechnerModel()
        model.tapDigit("0"); model.tapDigit("5")
        #expect(model.display == "5")   // nicht "05"
    }

    // MARK: Große Zahlen — Eingabe ist bei 12 Stellen gekappt
    @Test func eingabeIstBeiZwoelfStellenGekappt() {
        let model = RechnerModel()
        for _ in 0..<20 { model.tapDigit("9") }
        #expect(model.display.count == 12)
        #expect(model.display == "999999999999")
    }

    // Nicht-ganzzahliges Ergebnis nutzt %g-Format (keine Endlos-Nachkommastellen).
    @Test func nichtGanzzahligesErgebnisIstKompaktFormatiert() {
        // 10 ÷ 3 = 3.33333... → %g kürzt auf ~6 signifikante Stellen.
        #expect(evaluate(["1", "0", "÷", "3", "="]) == "3.33333")
    }
}
