import Foundation

// MARK: - OfferPositionExtractor (PDF-Positions v1, Pass 2: Feld-Extraktion)
//
// Reiner Text-Extraktor: aus dem Text EINES Positionsblocks die harten Felder
// herauslösen — Netto-Preis, Einzelpreis, Menge/Einheit, Maße — mit
// arithmetischem Selbstbeweis als Konfidenz (Menge × Einzel ≈ Gesamt).
// Foundation-only, kein PDFKit, kein SwiftUI → in MykilosKalkulationsCore
// testbar (PDFKit ist später nur ein dünner Adapter, der Seiten-Strings liefert).
//
// Kernidee (siehe Design-Memo): eine Position, deren Menge × Einzelpreis den
// Gesamtpreis trifft, hat sich selbst bewiesen — kein Vertrauen in die Heuristik
// nötig. Der Mensch sieht an der Ampel sofort, welche Karten Aufmerksamkeit brauchen.
public enum OfferPositionExtractor {

    // MARK: Ergebnis-Typen

    /// Selbstbeweis-Ampel einer extrahierten Position.
    public enum Confidence: String, Equatable, Sendable {
        case green   // Menge × Einzel ≈ Gesamt (±1 %) — arithmetisch bewiesen
        case amber   // Preis vorhanden, Rechnung nicht prüfbar (z. B. Pauschale ohne Menge)
        case red     // unvollständig (kein verwertbarer Preis)
    }

    /// Herausgelöste Felder eines Positionsblocks. Bewusst schlanker als
    /// `OfferPositionBlock` (dem finalen Landemodell): nur, was die Heuristik aus
    /// reinem Text ableitet. Die App mappt das später in `OfferPositionBlock`/Pick.
    public struct ExtractedPosition: Equatable, Sendable {
        public let title: String
        /// Netto-Einzelpreis der Position (E.P.) — das, was der Lernkorpus als
        /// `price_net` führt. Bei Menge 1 gleich der Zeilensumme.
        public let netPrice: Decimal?
        /// Zeilensumme (G.P. = Menge × Einzel), sofern per Selbstbeweis bestätigt.
        public let lineTotal: Decimal?
        public let quantity: Double?
        public let unit: String?
        public let lengthM: Double?
        public let areaM2: Double?
        public let confidence: Confidence
        public let originalText: String

        public init(title: String, netPrice: Decimal?, lineTotal: Decimal?, quantity: Double?,
                    unit: String?, lengthM: Double?, areaM2: Double?, confidence: Confidence,
                    originalText: String) {
            self.title = title
            self.netPrice = netPrice
            self.lineTotal = lineTotal
            self.quantity = quantity
            self.unit = unit
            self.lengthM = lengthM
            self.areaM2 = areaM2
            self.confidence = confidence
            self.originalText = originalText
        }
    }

    // MARK: Öffentliche API

    /// Extrahiert die Felder EINES Positionsblocks aus seinem Text.
    public static func extract(fromBlock text: String) -> ExtractedPosition {
        let amounts = germanAmounts(in: text)
        let qty = leadingQuantity(in: text)
        let (lengthM, areaM2) = dimensions(in: text)
        let unitToken = unit(in: text)

        // Selbstbeweis: das erste Betrags-Paar (einzel, gesamt) suchen, das mit einer
        // plausiblen Menge aufgeht. Kandidat-Mengen bewusst nur Stück-Menge + 1
        // (der Stück-1-Fall = zwei gleiche Beträge). Maße als Multiplikator würden
        // bei m²-Platten fälschlich den m²-Preis als „Einzel" beweisen — der Korpus
        // führt dort aber die Zeilensumme; darum Länge/Fläche NICHT als Multiplikator.
        let candidateQuantities: [Double] = [qty, 1.0].compactMap { $0 }.filter { $0 > 0 }

        // Der Lernkorpus führt price_net = Einzelpreis (E.P.); bei Menge 1 == Zeilensumme.
        if let proof = selfProof(amounts: amounts, quantities: candidateQuantities) {
            return ExtractedPosition(
                title: firstTextLine(text), netPrice: proof.einzel, lineTotal: proof.gesamt,
                quantity: proof.quantity, unit: unitToken, lengthM: lengthM, areaM2: areaM2,
                confidence: .green, originalText: text)
        }

        // Kein Selbstbeweis: der erste Betrag ist in der Praxis der Positionspreis
        // (die Positionszeile steht vor Zwischensummen/Bank-/MwSt-Zeilen).
        if let first = amounts.first {
            return ExtractedPosition(
                title: firstTextLine(text), netPrice: first, lineTotal: nil,
                quantity: qty, unit: unitToken, lengthM: lengthM, areaM2: areaM2,
                confidence: .amber, originalText: text)
        }

        return ExtractedPosition(
            title: firstTextLine(text), netPrice: nil, lineTotal: nil, quantity: qty,
            unit: unitToken, lengthM: lengthM, areaM2: areaM2, confidence: .red, originalText: text)
    }

    // MARK: - Selbstbeweis

    struct Proof: Equatable { let einzel: Decimal; let gesamt: Decimal; let quantity: Double }

    /// Findet den ersten (frühesten) Gesamtpreis, der sich aus einem früheren
    /// Einzelpreis × einer Kandidat-Menge (±1 %) beweist. Deckt den Stück-1-Fall
    /// (zwei gleiche Beträge), Menge × EP = GP und Fläche/Länge × EP = GP ab.
    static func selfProof(amounts: [Decimal], quantities: [Double]) -> Proof? {
        guard amounts.count >= 2 else { return nil }
        for g in 1..<amounts.count {
            let gesamt = amounts[g]
            guard gesamt > 0 else { continue }
            for e in 0..<g {
                let einzel = amounts[e]
                guard einzel > 0 else { continue }
                for q in quantities {
                    let erwartet = decimalDouble(einzel) * q
                    let ziel = decimalDouble(gesamt)
                    guard ziel > 0 else { continue }
                    if abs(erwartet - ziel) / ziel <= 0.01 {
                        return Proof(einzel: einzel, gesamt: gesamt, quantity: q)
                    }
                }
            }
        }
        return nil
    }

    // MARK: - Feld-Parser (rein, ohne Zustand)

    // Deutscher Betrag: entweder mit Tausenderpunkten (5.911,70) ODER als reine
    // Ziffernfolge (2995,00). Beide enden auf ,dd. Kein voranstehender Ziffern/Punkt/
    // Komma, damit "9.762,889.762,8"-Klumpen nicht als ein Riesenbetrag durchgehen.
    private static let amountRegex = try! NSRegularExpression(
        pattern: #"(?<![\d.,])(?:\d{1,3}(?:\.\d{3})+|\d+),\d{2}(?![\d])"#)

    // PDF-Extraktion klebt Beträge oft ohne Trennzeichen aneinander
    // ("9.762,88 9.762,889.762,8" = E.P., G.P. und eine Wiederholung). Ein `,dd`
    // direkt gefolgt von einer Ziffer trennt zwei Beträge → Leerzeichen einfügen.
    private static let deGlueRegex = try! NSRegularExpression(pattern: #"(,\d{2})(?=\d)"#)

    /// Alle deutschen Geldbeträge (1.234,56) in Textreihenfolge als Decimal.
    static func germanAmounts(in text: String) -> [Decimal] {
        let deGlued = deGlue(text)
        let ns = deGlued as NSString
        return amountRegex.matches(in: deGlued, range: NSRange(location: 0, length: ns.length))
            .compactMap { m in decimal(fromGerman: ns.substring(with: m.range)) }
    }

    /// Trennt aneinandergeklebte Beträge ("…,88 9…" statt "…,889…").
    static func deGlue(_ text: String) -> String {
        let ns = text as NSString
        return deGlueRegex.stringByReplacingMatches(
            in: text, range: NSRange(location: 0, length: ns.length), withTemplate: "$1 ")
    }

    /// "5.911,70" → Decimal(5911.70). Tausenderpunkte raus, Komma → Punkt.
    static func decimal(fromGerman s: String) -> Decimal? {
        let normalized = s.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }

    private static let quantityRegex = try! NSRegularExpression(
        pattern: #"(\d+(?:,\d+)?)\s*(Stk|Stck|Stück|Stueck|St\b|x)"#, options: [.caseInsensitive])

    /// Erste Stück-Menge im Block (z. B. "2 Stk", "3 Stck."). `nil` wenn keine.
    static func leadingQuantity(in text: String) -> Double? {
        let ns = text as NSString
        guard let m = quantityRegex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges > 1 else { return nil }
        return germanDouble(ns.substring(with: m.range(at: 1)))
    }

    private static let lengthRegex = try! NSRegularExpression(pattern: #"(\d+(?:,\d+)?)\s*m(?![²2a-zA-Z])"#)
    private static let areaRegex = try! NSRegularExpression(pattern: #"(\d+(?:,\d+)?)\s*m(?:²|2)"#)

    /// Länge (m) und Fläche (m²) — erster Treffer je Maß.
    static func dimensions(in text: String) -> (lengthM: Double?, areaM2: Double?) {
        let ns = text as NSString
        let full = NSRange(location: 0, length: ns.length)
        let area = areaRegex.firstMatch(in: text, range: full).flatMap { m in
            m.numberOfRanges > 1 ? germanDouble(ns.substring(with: m.range(at: 1))) : nil }
        let length = lengthRegex.firstMatch(in: text, range: full).flatMap { m in
            m.numberOfRanges > 1 ? germanDouble(ns.substring(with: m.range(at: 1))) : nil }
        return (length, area)
    }

    private static let unitRegex = try! NSRegularExpression(
        pattern: #"\b(Stk|Stck|Stück|Stueck|lfm|m²|m2|m|cm|h|psch|pauschal)\b"#, options: [.caseInsensitive])

    static func unit(in text: String) -> String? {
        let ns = text as NSString
        guard let m = unitRegex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) else { return nil }
        return ns.substring(with: m.range)
    }

    /// Erste „echte" Textzeile als Titel (überspringt führende Nummern/Mengen).
    static func firstTextLine(_ text: String) -> String {
        let line = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? text
        // Führende Positions-/Mengennummern + Stück-Token abschneiden.
        let cleaned = line.replacingOccurrences(
            of: #"^\s*(\d+\s+){0,3}(Stck\.?|Stk\.?|Stück|x)?\s*"#,
            with: "", options: .regularExpression)
        return String(cleaned.prefix(120)).trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Zahl-Helfer

    static func germanDouble(_ s: String) -> Double? {
        Double(s.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "."))
    }

    static func decimalDouble(_ d: Decimal) -> Double {
        (d as NSDecimalNumber).doubleValue
    }
}
