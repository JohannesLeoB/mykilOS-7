import Foundation

// MARK: - WarenkorbCSVExporter (HANDOFF_PLANNED_FEATURES.md Feature D, 2026-07-07)
//
// Johannes-Wunsch (2026-06-30): Warenkörbe als CSV exportierbar, "Excel öffnet CSV direkt".
// Rein lesend — kein Airtable-Write; die eigentliche Datei-Ablage läuft über den System-
// Speicherdialog (NSSavePanel), nicht hier. Diese Datei ist NUR die reine, voll testbare
// String-Erzeugung (kein AppKit, kein @MainActor).
//
// Bewusste Format-Entscheidungen (Korrektheit vor Bequemlichkeit):
//   • Trennzeichen SEMIKOLON — deutsches Excel (de_DE) nutzt `;`, weil `,` das
//     Dezimaltrennzeichen ist. So öffnet die Datei ohne Import-Assistent.
//   • RFC-4180-Escaping: Felder mit `;`, `"`, Zeilenumbruch oder CR werden in `"`
//     gesetzt, innenliegende `"` verdoppelt. Tischler-Artikelnamen enthalten oft Kommas,
//     Anführungszeichen (Zoll) oder Schrägstriche — naives CSV würde die Zeilen zerreißen.
//   • UTF-8-BOM voran, damit Excel (v.a. Windows) Umlaute korrekt liest statt als Mojibake.
//   • Preise deutsch formatiert (Komma-Dezimal, keine Tausender-Gruppierung — die würde
//     mit Punkten die Semikolon-Spalten nicht stören, aber Excel-Zahlparsing verwirren).
enum WarenkorbCSVExporter {

    /// Kopfzeilen-Kontext (optional) — nichts wird erfunden: leere Felder bleiben weg.
    struct Kopf {
        var bezeichnung: String?
        var projekt: String?
        var datum: Date
        init(bezeichnung: String? = nil, projekt: String? = nil, datum: Date = Date()) {
            self.bezeichnung = bezeichnung
            self.projekt = projekt
            self.datum = datum
        }
    }

    static let delimiter = ";"

    private static let datumsFormat: DateFormatter = {
        let fmt = DateFormatter(); fmt.dateFormat = "dd.MM.yyyy"; fmt.locale = Locale(identifier: "de_DE"); return fmt
    }()

    private static let preisFormat: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.locale = Locale(identifier: "de_DE")   // Komma-Dezimal
        fmt.minimumFractionDigits = 2
        fmt.maximumFractionDigits = 2
        fmt.usesGroupingSeparator = false
        return fmt
    }()

    /// Erzeugt den vollständigen CSV-Text (inkl. UTF-8-BOM) für die Positionen + optionalen Kopf.
    static func csv(positionen: [WarenkorbState.Position], kopf: Kopf = Kopf()) -> String {
        var zeilen: [String] = []

        // Kopfblock (nur nicht-leere Felder) — Schlüssel;Wert je Zeile.
        if let bezeichnung = kopf.bezeichnung, bezeichnung.isEmpty == false {
            zeilen.append(feld("Warenkorb") + delimiter + feld(bezeichnung))
        }
        if let projekt = kopf.projekt, projekt.isEmpty == false {
            zeilen.append(feld("Projekt") + delimiter + feld(projekt))
        }
        zeilen.append(feld("Datum") + delimiter + feld(datumsFormat.string(from: kopf.datum)))
        zeilen.append(feld("Positionen") + delimiter + feld(String(positionen.count)))
        zeilen.append("")   // Leerzeile zwischen Kopf und Tabelle

        // Spaltenüberschriften.
        let spalten = ["Pos.", "Artikelnummer", "Bezeichnung", "Lieferant", "Kategorie",
                       "Quelle", "Menge", "EK-Einzel", "VK-Einzel", "VK-Summe"]
        zeilen.append(spalten.map(feld).joined(separator: delimiter))

        // Positionszeilen.
        var summeVK = 0.0
        for (index, position) in positionen.enumerated() {
            let vkSumme = (position.vkNetto ?? 0) * Double(position.menge)
            summeVK += vkSumme
            let felder = [
                String(index + 1),
                position.artikelnummer,
                position.bezeichnung,
                position.attribute["lieferant"] ?? "",
                position.attribute["kategorie"] ?? "",
                position.source,
                String(position.menge),
                preis(position.ekNetto),
                preis(position.vkNetto),
                position.vkNetto == nil ? "" : preis(vkSumme)
            ]
            zeilen.append(felder.map(feld).joined(separator: delimiter))
        }

        // Summenzeile (nur VK-Summe, wie im Plan).
        let summenZeile = ["", "", "", "", "", "", "", "", "Summe VK", preis(summeVK)]
        zeilen.append(summenZeile.map(feld).joined(separator: delimiter))

        return "\u{FEFF}" + zeilen.joined(separator: "\r\n")
    }

    // MARK: - Reine Helfer

    /// Preis deutsch (Komma-Dezimal) oder leer, wenn nicht bekannt — nie erfundene 0,00.
    static func preis(_ wert: Double?) -> String {
        guard let wert else { return "" }
        return preisFormat.string(from: NSNumber(value: wert)) ?? ""
    }

    /// RFC-4180-Escaping mit Semikolon-Trennzeichen.
    static func feld(_ roh: String) -> String {
        let mussQuoten = roh.contains(delimiter) || roh.contains("\"")
            || roh.contains("\n") || roh.contains("\r")
        guard mussQuoten else { return roh }
        return "\"" + roh.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
