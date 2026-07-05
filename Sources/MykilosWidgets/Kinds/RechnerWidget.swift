import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - RechnerTheme
// Drei Farbwelten für den Taschenrechner, wählbar über den Mini-Toggle im Header
// (Johannes-Feedback 2026-07-05: Braun ET66 schwarz · Braun-hell · „Mustard"-Rost).
// Alles über MykColor-Tokens — kein rohes Hex. Der Ocker-„="-Akzent bleibt konstant
// als Signatur. Persistiert per @AppStorage (nutzer-eigene Ansichts-Vorliebe).
enum RechnerTheme: String, CaseIterable, Identifiable {
    case weiss, schwarz, rot
    var id: String { rawValue }
    var label: String {
        switch self { case .weiss: "Weiß"; case .schwarz: "Schwarz"; case .rot: "Rot" }
    }
    var swatch: Color            { keyBackground }
    var keyBackground: Color {
        switch self { case .weiss: MykColor.paper2.color; case .schwarz: MykColor.ink.color; case .rot: MykColor.drive.color }
    }
    var digitText: Color {
        switch self { case .weiss: MykColor.ink.color; default: MykColor.paper.color }
    }
    var operatorText: Color {
        switch self { case .weiss, .schwarz: MykColor.tasks.color; case .rot: MykColor.paper.color }
    }
    var clearText: Color {
        switch self { case .rot: MykColor.paper.color; default: MykColor.critical.color }
    }
    var equalsBackground: Color  { MykColor.tasks.color }   // Ocker-Signatur, immer
    var equalsText: Color {
        switch self { case .weiss: MykColor.paper.color; default: MykColor.ink.color }
    }
    var displayBackground: Color { keyBackground }
    var displayText: Color {
        switch self { case .weiss: MykColor.ink.color; default: MykColor.paper.color }
    }
}

// MARK: - RechnerWidget
// Kleiner Taschenrechner auf der Übersichtsseite. Braun-angelehnt (Dieter Rams,
// ET66) mit wählbarer Farbwelt. Rein lokal — kein Schreiben.
public struct RechnerWidget: View {
    @State private var model = RechnerModel()
    @AppStorage("rechnerTheme") private var themeRaw = RechnerTheme.weiss.rawValue
    @FocusState private var isFocused: Bool

    public init() {}

    private var theme: RechnerTheme { RechnerTheme(rawValue: themeRaw) ?? .weiss }

    public var body: some View {
        WidgetContainer(kind: .rechner, sourceLabel: "RECHNER", projectID: "home") {
            VStack(alignment: .leading, spacing: MykSpace.s4) {
                header
                display
                keypad
            }
            // Hardware-Num-Block-Eingabe (H1): dezenter Ocker-Rahmen bei Fokus,
            // damit sichtbar ist, dass die Tastatur den Rechner bedient.
            .padding(MykSpace.s3)
            .overlay(
                RoundedRectangle(cornerRadius: MykRadius.sm)
                    .strokeBorder(isFocused ? MykColor.tasks.color : Color.clear, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
            .focusable()
            .focused($isFocused)
            .onTapGesture { isFocused = true }
            .onKeyPress { press in handleKeyPress(press) }
        }
    }

    // Mappt Hardware-Tasten auf die bestehende Rechenlogik. Ziffern 0–9 + "."
    // direkt, Operatoren + - * / auf die Anzeige-Symbole − × ÷ +, Enter = "=",
    // Delete/Backspace löscht eine Stelle, Escape = C. Alles unbekannte → .ignored.
    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        switch press.key {
        case .return:
            model.tapEquals(); return .handled
        case .delete, .deleteForward:
            model.tapBackspace(); return .handled
        case .escape:
            model.tapClear(); return .handled
        default:
            break
        }

        guard let ch = press.characters.first else { return .ignored }
        switch ch {
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
            model.tapDigit(String(ch)); return .handled
        case ".", ",":
            model.tapDecimal(); return .handled
        case "+":
            model.tapOperator("+"); return .handled
        case "-":
            model.tapOperator("−"); return .handled
        case "*", "x", "X":
            model.tapOperator("×"); return .handled
        case "/", ":":
            model.tapOperator("÷"); return .handled
        case "=":
            model.tapEquals(); return .handled
        case "c", "C":
            model.tapClear(); return .handled
        default:
            return .ignored
        }
    }

    private var header: some View {
        HStack {
            SourceChip(kind: .rechner)
            Text("Rechner").mykWidgetTitle()
            Spacer()
            themeToggle
        }
    }

    // Mini-Toggle: drei Farbpunkte, der aktive trägt einen Ring.
    private var themeToggle: some View {
        HStack(spacing: MykSpace.s3) {
            ForEach(RechnerTheme.allCases) { t in
                Button { themeRaw = t.rawValue } label: {
                    Circle()
                        .fill(t.swatch)
                        .frame(width: 13, height: 13)
                        .overlay(
                            Circle().strokeBorder(
                                theme == t ? MykColor.ink.color : MykColor.line.color,
                                lineWidth: theme == t ? 2 : 1)
                        )
                }
                .buttonStyle(.plain)
                .help("Farbe: \(t.label)")
            }
        }
    }

    private var display: some View {
        Text(model.display)
            .font(.mykMono(24))
            .foregroundStyle(theme.displayText)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, MykSpace.s4)
            .padding(.vertical, MykSpace.s4)
            .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(theme.displayBackground))
    }

    private var keypad: some View {
        VStack(spacing: MykSpace.s3) {
            row(["7", "8", "9", "÷"])
            row(["4", "5", "6", "×"])
            row(["1", "2", "3", "−"])
            row(["C", "0", ".", "+"])
            RechnerKey(label: "=", foreground: theme.equalsText, background: theme.equalsBackground) {
                model.tapEquals()
            }
        }
    }

    private func row(_ labels: [String]) -> some View {
        HStack(spacing: MykSpace.s3) {
            ForEach(labels, id: \.self) { label in
                RechnerKey(label: label, foreground: foreground(for: label), background: theme.keyBackground) {
                    tap(label)
                }
            }
        }
    }

    private func foreground(for label: String) -> Color {
        switch label {
        case "÷", "×", "−", "+": theme.operatorText
        case "C":                theme.clearText
        default:                 theme.digitText
        }
    }

    private func tap(_ label: String) {
        switch label {
        case "C":                model.tapClear()
        case ".":                model.tapDecimal()
        case "÷", "×", "−", "+": model.tapOperator(label)
        default:                 model.tapDigit(label)
        }
    }
}

// MARK: - RechnerKey (eine Taste)
private struct RechnerKey: View {
    let label: String
    let foreground: Color
    let background: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.mykMono(16))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(background))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - RechnerModel (immediate-execution Rechenlogik)
// `internal` (nicht `private`), damit die reine Rechenlogik testbar ist
// (@testable import MykilosWidgets). Keine Verhaltensänderung — nur Sichtbarkeit.
@MainActor
@Observable
final class RechnerModel {
    private(set) var display = "0"
    private var accumulator: Double?
    private var pendingOperator: String?
    private var typingNew = true

    func tapDigit(_ d: String) {
        if typingNew { display = d; typingNew = false }
        else if display == "0" { display = d }
        else if display.count < 12 { display += d }
    }

    func tapDecimal() {
        if typingNew { display = "0."; typingNew = false }
        else if display.contains(".") == false { display += "." }
    }

    func tapOperator(_ op: String) {
        applyPending()
        pendingOperator = op
        typingNew = true
    }

    func tapEquals() {
        applyPending()
        pendingOperator = nil
        typingNew = true
    }

    func tapClear() {
        display = "0"; accumulator = nil; pendingOperator = nil; typingNew = true
    }

    // Backspace: eine Stelle löschen. Wird die Anzeige leer (oder war sie ein
    // frisch berechnetes/neu getipptes Ergebnis), fällt sie auf "0" zurück.
    func tapBackspace() {
        if typingNew { display = "0"; return }
        display.removeLast()
        if display.isEmpty || display == "-" { display = "0"; typingNew = true }
    }

    private func applyPending() {
        let current = Double(display) ?? 0
        guard let op = pendingOperator, let acc = accumulator else {
            accumulator = current
            return
        }
        let result: Double
        switch op {
        case "+": result = acc + current
        case "−": result = acc - current
        case "×": result = acc * current
        case "÷":
            guard current != 0 else {
                display = "Fehler"; accumulator = nil; pendingOperator = nil; typingNew = true
                return
            }
            result = acc / current
        default:  result = current
        }
        accumulator = result
        display = format(result)
    }

    private func format(_ v: Double) -> String {
        if v.isNaN || v.isInfinite { return "Fehler" }
        if v == v.rounded() && abs(v) < 1e12 { return String(Int(v)) }
        return String(format: "%g", v)
    }
}
