import Foundation
import MykilosKalkulationsCore

// MARK: - StundensatzLoader
// Lädt Stundensätze aus Airtable `Clockodo-Leistungen` und merged sie
// gegen die im Code hinterlegten CostModel-Werte. Airtable gewinnt wo befüllt;
// fehlende Keys fallen auf den Hardcode zurück.
//
// Kein direkter AirtableClient-Aufruf hier — die Methode akzeptiert fertig
// deserialisierte Records (Array von [String: Any]), damit Tests ohne Netz laufen.
//
// DATENSCHUTZ: Keine nutzerbezogenen Stundensätze. Stundensätze sind Gewerke-
// Sätze des Studios (tischler-seitig) — nicht per-User.

public struct StundensatzLoader {

    // Hardcode-Fallback: exakt CostModel.stages → damit immer alle 8 Keys da sind.
    public static var hardcodedSaetze: [String: Decimal] {
        Dictionary(uniqueKeysWithValues: CostModel.stages.map { ($0.key, $0.ratePerHour) })
    }

    /// Parst Airtable-Records und merged sie über den Hardcode.
    /// `records` = Array aus `[[fieldID: value]]` oder `[[fieldName: value]]`.
    /// Erwartete Keys: `"Name"` (String) und `"Stundensatz (€/h)"` (Number).
    /// Unbekannte Namen werden übersprungen (kein Crash bei Schema-Änderungen).
    public static func merge(
        airtableRecords: [[String: Any]],
        base: [String: Decimal] = hardcodedSaetze
    ) -> [String: Decimal] {
        var result = base
        for record in airtableRecords {
            guard
                let name = (record["Name"] as? String) ?? (record["fld0Q4mwPLiKFAx0x"] as? String),
                let rateAny = record["Stundensatz (€/h)"] ?? record["fld4NBokj4MoOy8Uq"],
                let rate = decimal(from: rateAny),
                rate > 0,
                let key = stageKey(for: name)
            else { continue }
            result[key] = rate
        }
        return result
    }

    // MARK: - Internal helpers

    static func stageKey(for name: String) -> String? {
        let n = name.lowercased()
        if n.contains("av") || n.contains("aufmaß") || n.contains("aufmass") { return "av" }
        if n.contains("zuschnitt") { return "zuschnitt" }
        if n.contains("kante") { return "kante" }
        if n.contains("cnc") || n.contains("bhx") { return "cnc" }
        if n.contains("bank") { return "bankraum" }
        if n.contains("lager") { return "lager" }
        if n.contains("laden") { return "laden" }
        if n.contains("montage") || n.contains("anliefer") { return "montage" }
        return nil
    }

    static func decimal(from value: Any) -> Decimal? {
        if let d = value as? Double { return Decimal(d) }
        if let i = value as? Int { return Decimal(i) }
        if let s = value as? String { return Decimal(string: s, locale: Locale(identifier: "en_US")) }
        if let n = value as? NSNumber { return n.decimalValue }
        return nil
    }
}
