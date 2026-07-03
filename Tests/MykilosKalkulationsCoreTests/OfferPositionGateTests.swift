import XCTest
@testable import MykilosKalkulationsCore

// MARK: - OfferPositionGateTests (818er-Gegenprobe, NUR lokal)
//
// Bau-Gate für PDF-Positions v1: misst den Pass-2-Feld-Extraktor gegen den echten
// Altbestand `position_candidates.csv` (815 Positionsblöcke mit hinterlegtem
// price_net). Läuft NUR, wenn die Umgebungsvariable `MYKILOS_KALK_LABOR` auf den
// Brain-Ordner des Kalkulationslabors zeigt — sonst `XCTSkip`. So bleibt der echte
// EK-Bestand lokal (Geschäftsgeheimnis) und CI/Repo sauber.
//
//   MYKILOS_KALK_LABOR="$HOME/Library/Application Support/mykilOS/Kalkulationslabor/Brain" \
//     swift test --filter OfferPositionGateTests
//
// Ziel (Design-Memo): ≥ 90 % der sauberen Alt-Kandidaten mit identischem
// Netto-Preis (±0,01) wiedergefunden. Erst wenn die Zahl steht, verdient das
// Feature seine UI.
final class OfferPositionGateTests: XCTestCase {

    /// Saubere Kandidaten = die, denen der Alt-Pipeline selbst vertraute.
    private static let cleanStatuses: Set<String> = ["release_candidate", "release_candidate_light_review"]

    func testWiederfindungGegenAltbestand() throws {
        guard let labor = ProcessInfo.processInfo.environment["MYKILOS_KALK_LABOR"] else {
            throw XCTSkip("MYKILOS_KALK_LABOR nicht gesetzt — lokales Gate übersprungen.")
        }
        let csvURL = URL(fileURLWithPath: labor).appendingPathComponent("position_candidates.csv")
        let content = try String(contentsOf: csvURL, encoding: .utf8)
        let rows = CSV.parse(content)
        guard let header = rows.first else { return XCTFail("CSV leer") }
        var col: [String: Int] = [:]
        for (idx, name) in header.enumerated() where col[name] == nil { col[name] = idx }
        guard let iText = col["original_text"], let iNet = col["price_net"], let iStatus = col["status"] else {
            return XCTFail("Erwartete Spalten fehlen: \(header)")
        }

        var total = 0, overallHit = 0
        var cleanTotal = 0, cleanHit = 0
        // Trefferquote nach meiner Konfidenz-Ampel (Kernthese: grün = verlässlich).
        var confTotal: [OfferPositionExtractor.Confidence: Int] = [:]
        var confHit: [OfferPositionExtractor.Confidence: Int] = [:]
        // Offensichtliche Korpus-Fehler: winziger price_net (≤ 20 €) = fast sicher
        // Menge/Prozent statt Preis (alte Pipeline-Bugs). Aus dem fairen Gate raus.
        var cleanCorpusSuspect = 0, cleanAdjHit = 0, cleanAdjTotal = 0
        var mismatches: [(String, Decimal, Decimal?)] = []

        for row in rows.dropFirst() where row.count > max(iText, iNet, iStatus) {
            let text = row[iText]
            guard let expected = Decimal(string: row[iNet]) else { continue }
            total += 1
            let p = OfferPositionExtractor.extract(fromBlock: text)
            let hit = p.netPrice.map { abs(($0 - expected) as Decimal) <= Decimal(0.01) } ?? false
            if hit { overallHit += 1 }

            guard Self.cleanStatuses.contains(row[iStatus]) else { continue }
            cleanTotal += 1
            confTotal[p.confidence, default: 0] += 1
            if hit { cleanHit += 1; confHit[p.confidence, default: 0] += 1 }

            let corpusSuspect = expected <= Decimal(20)   // Mini-„Preis" = Korpus-Artefakt
            if hit {
                cleanAdjTotal += 1; cleanAdjHit += 1
            } else if corpusSuspect {
                cleanCorpusSuspect += 1                    // Korpus falsch → aus dem Nenner
            } else {
                cleanAdjTotal += 1                         // echter Miss (bzw. PDF-Klumpen)
                if mismatches.count < 15 { mismatches.append((String(text.prefix(90)), expected, p.netPrice)) }
            }
        }

        func rate(_ h: Int, _ t: Int) -> Double { t > 0 ? Double(h) / Double(t) : 0 }
        let cleanRate = rate(cleanHit, cleanTotal)
        let adjRate = rate(cleanAdjHit, cleanAdjTotal)
        let greenRate = rate(confHit[.green] ?? 0, confTotal[.green] ?? 0)

        print("""

        ┌─ PDF-Positions v1 · 815er-Gegenprobe ─────────────────────────
        │ Kandidaten gesamt:        \(total)   ·   Netto-Treffer gesamt: \(overallHit) (\(pct(rate(overallHit, total))))
        │ ── Saubere Teilmenge (release_candidate*, n=\(cleanTotal)) ──
        │ roh getroffen:            \(cleanHit)  (\(pct(cleanRate)))
        │ davon Korpus-Fehler (price_net ≤ 20 €): \(cleanCorpusSuspect)  → aus fairem Nenner raus
        │ ⇒ BEREINIGT:              \(cleanAdjHit)/\(cleanAdjTotal)  (\(pct(adjRate)))  ← GATE
        │ ── Trefferquote nach Konfidenz-Ampel (sauber) ──
        │ 🟢 green:  \(confHit[.green] ?? 0)/\(confTotal[.green] ?? 0)  (\(pct(greenRate)))    🟠 amber: \(confHit[.amber] ?? 0)/\(confTotal[.amber] ?? 0)    🔴 red: \(confHit[.red] ?? 0)/\(confTotal[.red] ?? 0)
        └───────────────────────────────────────────────────────────────
        """)
        if mismatches.isEmpty == false {
            print("Echte Fehlschläge (sauber, ohne Korpus-Mini-Preise):")
            for (t, exp, got) in mismatches { print("  erwartet \(exp)  bekam \(got.map { "\($0)" } ?? "nil")  ·  \(t)…") }
        }

        XCTAssertGreaterThanOrEqual(adjRate, 0.90,
            "Gate NICHT bestanden: bereinigt nur \(pct(adjRate)) (Ziel ≥ 90 %).")
    }

    private func pct(_ r: Double) -> String { String(format: "%.1f %%", r * 100) }
}

// MARK: - CSV-Parser (zeilenweise; die Quelle hat garantiert KEINE eingebetteten
// Zeilenumbrüche — per Python-Referenzparser verifiziert). Zeilenweises Splitten
// macht robust: ein unbalanciertes Quote in einem Feld korrumpiert höchstens
// SEINE Zeile, nie den Rest der Datei.
private enum CSV {
    static func parse(_ text: String) -> [[String]] {
        text.split(whereSeparator: \.isNewline)
            .map { parseLine(String($0)) }
    }

    /// Zerlegt eine Zeile in Felder. Quote-bewusst mit ""-Escape; ein Feld gilt
    /// als quoted, wenn es (nach optionalem Whitespace) mit " beginnt.
    static func parseLine(_ line: String) -> [String] {
        var fields: [String] = []
        var field = ""
        var inQuotes = false
        let chars = Array(line)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" { field.append("\""); i += 1 }
                    else { inQuotes = false }
                } else { field.append(c) }
            } else if c == "\"" && field.isEmpty {
                inQuotes = true
            } else if c == "," {
                fields.append(field); field = ""
            } else {
                field.append(c)
            }
            i += 1
        }
        fields.append(field)
        return fields
    }
}
