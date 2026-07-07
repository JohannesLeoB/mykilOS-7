import Foundation

// MARK: - WarenkorbPDFExporter (HANDOFF_PLANNED_FEATURES.md Feature D, Teil 2, 2026-07-07)
//
// Teil 2 des Warenkorb-Exports (nach CSV): eine druckbare A4-Tabelle im mykilOS-Stil über
// den bestehenden `MykPDFRenderer` (derselbe Renderer wie DokumentPort — Wiederverwendung,
// kein neuer PDF-Stack). Rein lesend — kein Airtable-Write; die Datei-Ablage läuft über den
// System-Speicherdialog (NSSavePanel), nicht hier.
//
// ⚠️ BELEGFÜHRUNG (CLAUDE.md, eiserne Regel): Jedes von mykilOS erzeugte Dokument mit Preisen
// ist eine BESCHRIFTETE VORSCHAU — nie ein fertiges/offizielles Angebot. Deshalb trägt das PDF
// zwingend die Fußnote "Kalkulations-Vorschau — kein offizielles Angebot". Das offizielle
// Angebot entsteht separat in sevDesk.
enum WarenkorbPDFExporter {

    static let vorschauHinweis = "Kalkulations-Vorschau — kein offizielles Angebot"

    /// Spaltenüberschriften der Positionstabelle (bewusst schlanker als der CSV-Export,
    /// damit die Tabelle auf A4-Breite lesbar bleibt — Lieferant/Kategorie/Quelle bleiben
    /// dem datenreicheren CSV vorbehalten).
    static let spaltenkopf = ["Pos.", "Artikelnummer", "Bezeichnung", "Menge", "EK-Einzel", "VK-Einzel", "VK-Summe"]

    /// Reine, testbare Erzeugung der Tabellenzeilen (erste Zeile = Kopf). Preise deutsch
    /// (Komma-Dezimal, via WarenkorbCSVExporter.preis — eine Quelle der Preisformatierung),
    /// unbekannte Preise bleiben leer statt erfundener 0,00.
    static func tabelle(positionen: [WarenkorbState.Position]) -> [[String]] {
        var zeilen: [[String]] = [spaltenkopf]
        for (index, position) in positionen.enumerated() {
            let vkSumme = (position.vkNetto ?? 0) * Double(position.menge)
            zeilen.append([
                String(index + 1),
                position.artikelnummer,
                position.bezeichnung,
                String(position.menge),
                WarenkorbCSVExporter.preis(position.ekNetto),
                WarenkorbCSVExporter.preis(position.vkNetto),
                position.vkNetto == nil ? "" : WarenkorbCSVExporter.preis(vkSumme)
            ])
        }
        return zeilen
    }

    /// Summen (EK/VK netto) unter der Tabelle — deutsch formatiert.
    static func summen(positionen: [WarenkorbState.Position]) -> [(label: String, value: String)] {
        let summeEK = positionen.reduce(0.0) { $0 + ($1.ekNetto ?? 0) * Double($1.menge) }
        let summeVK = positionen.reduce(0.0) { $0 + ($1.vkNetto ?? 0) * Double($1.menge) }
        return [
            (label: "Summe EK netto", value: WarenkorbCSVExporter.preis(summeEK)),
            (label: "Summe VK netto", value: WarenkorbCSVExporter.preis(summeVK))
        ]
    }

    private static let datumsFormat: DateFormatter = {
        let fmt = DateFormatter(); fmt.dateFormat = "dd.MM.yyyy"; fmt.locale = Locale(identifier: "de_DE"); return fmt
    }()

    /// Rendert das A4-PDF (Data). Titel/Untertitel + Positionstabelle + Summen + Belegführungs-
    /// Fußnote. `bezeichnung`/`projekt` optional — nichts wird erfunden.
    static func pdf(
        positionen: [WarenkorbState.Position],
        bezeichnung: String? = nil,
        projekt: String? = nil,
        datum: Date = Date()
    ) -> Data {
        let titel = (bezeichnung?.isEmpty == false ? bezeichnung! : "Warenkorb")
        var untertitelTeile: [String] = []
        if let projekt, projekt.isEmpty == false { untertitelTeile.append("Projekt \(projekt)") }
        untertitelTeile.append(datumsFormat.string(from: datum))
        untertitelTeile.append("\(positionen.count) Position\(positionen.count == 1 ? "" : "en")")

        return MykPDFRenderer.render(
            title: titel,
            subtitle: untertitelTeile.joined(separator: " · "),
            sections: [],
            table: positionen.isEmpty ? nil : tabelle(positionen: positionen),
            totals: positionen.isEmpty ? [] : summen(positionen: positionen),
            footerNote: vorschauHinweis
        )
    }
}
