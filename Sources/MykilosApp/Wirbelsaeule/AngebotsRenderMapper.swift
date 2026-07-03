import Foundation
import MykilosKit

// MARK: - AngebotsRenderMapper (Version 10, Phase 2 / Block F)
//
// Reine, testbare Foundation-Logik: verwandelt einen persistierten `WorkBasket`
// (Wirbelsäule) + Kunde/Projekt-Metadaten in die exakten Render-Args von
// `MykPDFRenderer.render(title:subtitle:sections:table:totals:)`.
//
// SCOPE-GRENZE (Block F, siehe docs/VERSION_10_PLAN.md §Phase 2):
//   - Rendert NICHTS selbst — liefert nur `AngebotsRenderArgs`, die 1:1 an
//     `MykPDFRenderer.render` durchgereicht werden können (Block G, „Zum Angebot"-Knopf).
//   - Kein Schreiben, kein Drive, kein PDF-Objekt — reine Werttransformation.
//   - Datum ist injizierbar (Parameter, nicht `Date()` hart codiert) — deterministisch testbar.
//   - MwSt-Satz ist fix (19 %) und im Summenblock **sichtbar** ausgewiesen (Plan-Vorgabe).
//
// Lebt in MykilosApp (nicht MykilosKit), weil `MykPDFRenderer` AppKit/PDFKit
// importiert und die Args-Struktur an dessen Signatur gebunden ist — MykilosKit
// bleibt Foundation-only (§ Absolute Regeln, Architektur).

// MARK: - AngebotsRenderArgs

/// Die exakten Render-Args für `MykPDFRenderer.render`. 1:1-Spiegel der Parameter,
/// damit der Aufrufer (Block G) sie ohne weitere Übersetzung durchreichen kann.
public struct AngebotsRenderArgs: Equatable {
    public let title: String
    public let subtitle: String?
    public let sections: [(heading: String, fields: [(label: String, value: String)])]
    public let table: [[String]]?
    public let totals: [(label: String, value: String)]

    public init(
        title: String,
        subtitle: String?,
        sections: [(heading: String, fields: [(label: String, value: String)])],
        table: [[String]]?,
        totals: [(label: String, value: String)]
    ) {
        self.title = title
        self.subtitle = subtitle
        self.sections = sections
        self.table = table
        self.totals = totals
    }

    // Tupel-Arrays sind nicht automatisch Equatable — für Tests von Hand vergleichbar machen.
    public static func == (lhs: AngebotsRenderArgs, rhs: AngebotsRenderArgs) -> Bool {
        guard lhs.title == rhs.title, lhs.subtitle == rhs.subtitle else { return false }
        guard lhs.sections.count == rhs.sections.count else { return false }
        for (a, b) in zip(lhs.sections, rhs.sections) {
            guard a.heading == b.heading else { return false }
            guard a.fields.count == b.fields.count else { return false }
            for (fa, fb) in zip(a.fields, b.fields) {
                guard fa.label == fb.label, fa.value == fb.value else { return false }
            }
        }
        guard lhs.table == rhs.table else { return false }
        guard lhs.totals.count == rhs.totals.count else { return false }
        for (a, b) in zip(lhs.totals, rhs.totals) {
            guard a.label == b.label, a.value == b.value else { return false }
        }
        return true
    }
}

// MARK: - AngebotsAbsender

/// MYKILOS-Briefkopf/Absender-Angaben — konstant, aber als Parameter injizierbar
/// (kein Hardcoding im Mapper-Kern, testbar mit abweichenden Werten).
public struct AngebotsAbsender: Equatable {
    public let firma: String
    public let adresse: String
    public let kontakt: String

    public init(
        firma: String = "MYKILOS GmbH",
        adresse: String = "Hamburg",
        kontakt: String = "mykilos.com"
    ) {
        self.firma = firma
        self.adresse = adresse
        self.kontakt = kontakt
    }
}

// MARK: - AngebotsRenderMapper

/// Reine Mapper-Funktion: `WorkBasket` + Kunde/Projekt-Metadaten → `AngebotsRenderArgs`.
public enum AngebotsRenderMapper {

    /// Fester, sichtbar ausgewiesener MwSt-Satz für das Schneider-Angebot (Plan-Vorgabe).
    public static let mwstSatz: Double = 0.19

    /// Baut die Render-Args für ein Angebots-PDF aus einem WorkBasket.
    ///
    /// - Parameters:
    ///   - basket: Der persistierte Warenkorb (Positionen = `picks`, VK-Preise maßgeblich).
    ///   - kunde: Kundenname (Pflichtfeld für den Kundenblock).
    ///   - projektTitel: Menschenlesbarer Projekttitel (Pflichtfeld für den Projektblock).
    ///   - absender: MYKILOS-Briefkopf-Angaben (Default = echte Firmendaten, injizierbar für Tests).
    ///   - datum: Angebotsdatum — injizierbar, NICHT `Date()` hart im Mapper (Determinismus/Tests).
    /// - Returns: Fertige `AngebotsRenderArgs`, 1:1 an `MykPDFRenderer.render` durchreichbar.
    public static func map(
        basket: WorkBasket,
        kunde: String,
        projektTitel: String,
        absender: AngebotsAbsender = AngebotsAbsender(),
        datum: Date
    ) -> AngebotsRenderArgs {
        let angebotsnummer = angebotsnummer(projektNummer: basket.projektNummer)
        let datumString = DateFormatter.localizedString(from: datum, dateStyle: .long, timeStyle: .none)

        let sections: [(heading: String, fields: [(label: String, value: String)])] = [
            (
                heading: "Absender",
                fields: [
                    (label: "Firma", value: absender.firma),
                    (label: "Adresse", value: absender.adresse),
                    (label: "Kontakt", value: absender.kontakt),
                ]
            ),
            (
                heading: "Kunde",
                fields: [
                    (label: "Name", value: kunde),
                ]
            ),
            (
                heading: "Projekt",
                fields: [
                    (label: "Projekt", value: projektTitel),
                    (label: "Projektnummer", value: basket.projektNummer),
                    (label: "Angebotsnummer", value: angebotsnummer),
                    (label: "Datum", value: datumString),
                ]
            ),
        ]

        let rows = tableRows(picks: basket.picks)
        let netto = nettoSumme(picks: basket.picks)
        let mwst = netto * mwstSatz
        let brutto = netto + mwst

        let totals: [(label: String, value: String)] = [
            (label: "Netto", value: euro(netto)),
            (label: "MwSt. (\(mwstProzentText))", value: euro(mwst)),
            (label: "Brutto", value: euro(brutto)),
        ]

        return AngebotsRenderArgs(
            title: "Angebot",
            subtitle: "\(projektTitel) · \(angebotsnummer)",
            sections: sections,
            table: rows.count > 1 ? rows : nil,   // nur Kopfzeile = leerer Korb → kein Tabellenblock
            totals: totals
        )
    }

    // MARK: - Helfer (rein, testbar)

    /// Angebotsnummer aus der Projektnummer abgeleitet: `2026-015` → `A-2026-015`.
    /// Kein Zähler/State nötig — deterministisch aus dem Projektbezug.
    public static func angebotsnummer(projektNummer: String) -> String {
        "A-\(projektNummer)"
    }

    /// MwSt-Satz als sichtbarer Prozent-Text, z. B. "19 %".
    static var mwstProzentText: String {
        "\(Int((mwstSatz * 100).rounded())) %"
    }

    /// Tabellenzeilen: Kopfzeile + eine Zeile je Pick (Bezeichnung · Menge · Einzelpreis · Summe).
    /// Bei leerem Korb: nur die Kopfzeile (Aufrufer entscheidet per `rows.count > 1`, ob `table` gesetzt wird).
    static func tableRows(picks: [any Pick]) -> [[String]] {
        var rows: [[String]] = [["Bezeichnung", "Menge", "Einzelpreis", "Summe"]]
        for pick in picks {
            let s = pick.snapshot
            let einzelpreis = s.vkEinzel ?? 0
            let summe = einzelpreis * Double(s.menge)
            rows.append([
                s.bezeichnung,
                String(s.menge),
                euro(einzelpreis),
                euro(summe),
            ])
        }
        return rows
    }

    /// Netto-Gesamtsumme aller Picks (VK-Einzelpreis × Menge). Leerer Korb → 0.
    static func nettoSumme(picks: [any Pick]) -> Double {
        picks.reduce(0.0) { sum, pick in
            let s = pick.snapshot
            return sum + (s.vkEinzel ?? 0) * Double(s.menge)
        }
    }

    /// Deutsche EUR-Formatierung (Komma-Dezimaltrennzeichen, "1.234,50 €").
    static func euro(_ wert: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: wert)) ?? String(format: "%.2f €", wert)
    }
}
