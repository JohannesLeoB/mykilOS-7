import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - RechnerWidget
// Kleiner Taschenrechner auf der Übersichtsseite. Braun-angelehnt (Dieter Rams,
// ET66): klares 4er-Raster, ruhige Flächen, ein warmer Ocker-Akzent für die
// Operatoren und „=". Rein lokal — kein Schreiben, keine Persistenz (v1).
public struct RechnerWidget: View {
    @State private var model = RechnerModel()

    public init() {}

    public var body: some View {
        WidgetContainer(kind: .rechner, sourceLabel: "RECHNER", projectID: "home") {
            VStack(alignment: .leading, spacing: MykSpace.s4) {
                header
                display
                keypad
            }
        }
    }

    private var header: some View {
        HStack {
            SourceChip(kind: .rechner)
            Text("Rechner").mykWidgetTitle()
            Spacer()
        }
    }

    private var display: some View {
        Text(model.display)
            .font(.mykMono(24))
            .foregroundStyle(MykColor.ink.color)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, MykSpace.s4)
            .padding(.vertical, MykSpace.s4)
            .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.paper2.color))
    }

    private var keypad: some View {
        VStack(spacing: MykSpace.s3) {
            row(["7", "8", "9", "÷"])
            row(["4", "5", "6", "×"])
            row(["1", "2", "3", "−"])
            row(["C", "0", ".", "+"])
            RechnerKey(label: "=", kind: .equals) { model.tapEquals() }
        }
    }

    private func row(_ labels: [String]) -> some View {
        HStack(spacing: MykSpace.s3) {
            ForEach(labels, id: \.self) { label in
                RechnerKey(label: label, kind: kind(for: label)) { tap(label) }
            }
        }
    }

    private func kind(for label: String) -> RechnerKey.Kind {
        switch label {
        case "÷", "×", "−", "+": .operatorKey
        case "C":                .clear
        default:                 .digit
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
    enum Kind { case digit, operatorKey, equals, clear }
    let label: String
    let kind: Kind
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

    private var foreground: Color {
        switch kind {
        case .digit:       MykColor.ink.color
        case .operatorKey: MykColor.tasks.color
        case .clear:       MykColor.critical.color
        case .equals:      MykColor.paper.color
        }
    }

    private var background: Color {
        switch kind {
        case .equals: MykColor.tasks.color   // Ocker-Akzent (der „Braun-Gelb"-Moment)
        default:      MykColor.paper2.color
        }
    }
}

// MARK: - RechnerModel (immediate-execution Rechenlogik)
@MainActor
@Observable
private final class RechnerModel {
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
