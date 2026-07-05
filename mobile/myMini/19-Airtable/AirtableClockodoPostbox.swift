import Foundation

/// Spiegelt die Feld-Form des echten Mothership-Originals
/// (`Sources/MykilosServices/Clockodo/ClockodoAdapterWriter.swift`, Commit `9742b59`,
/// nur gelesen, nie verändert) — dieselbe Base, dieselbe Tabelle, dieselbe Semantik:
/// „Vorgebucht", append-only, ein Record pro Fang. ★1-Ziel bestätigt (Johannes, 2026-07-01).
///
/// Ehrlichkeitsgrenze: mobile erfasst (noch) kein Projekt, keine Kostenstelle, keine
/// echten Start-/End-Zeiten beim Fangen. Diese Felder werden bewusst NICHT erfunden,
/// sondern weggelassen — Airtable lässt sie dann leer, statt dass eine geteilte, echt
/// genutzte Tabelle falsche Daten bekommt. Die Zeile bleibt trotzdem sinnvoll: genau
/// das ist der Zweck von „Vorgebucht" — ein Mensch prüft und vervollständigt sie,
/// bevor irgendwas real in Clockodo gebucht wird.
///
/// Nur "zeit"-Einträge haben hier ein Ziel. "idee"-Einträge werden nicht synchronisiert —
/// ihre Ziel-Heimat ist noch offen (docs/09_V0_SPEZIFIKATION.md).
enum AirtableClockodoPostbox {
    static let baseID = "appuQDCFGLmjo2L6T"
    static let table = "Zeitbuchungen"

    private static let feldMitarbeiter = "fld7svgqwzUBJzkC9"
    private static let feldDatum       = "fld7ViaC4kPDNEEND"
    private static let feldKW          = "fldnq5arv7fhM6pUE"
    private static let feldDauerH      = "fldvN8gPs4urBygFY"
    private static let feldStatus      = "fldNzN4hs0IPcpeYl"
    private static let feldQuelle      = "fldiLBSYLpC1mCiFt"

    /// "Satellit" ist ein neuer Quelle-Wert (bisher kannte die Tabelle nur "Timer" vom
    /// Mac-Widget). Der Client erstellt ihn per `typecast` automatisch — abgestimmt mit
    /// Johannes in derselben Sitzung, in der dieser Code entstand, nicht auf eigene Faust.
    static let quelle = "Satellit"

    /// Reine, testbare Feld-Abbildung (kein Netzwerk). `nil`, wenn der Eintrag kein
    /// Zeit-Fang ist — der Aufrufer muss dann gar nicht erst synchronisieren.
    static func felder(fuer item: PostboxItem, mitarbeiter: String = "Johannes") -> [String: AirtableFieldValue]? {
        guard item.kind == "zeit" else { return nil }

        var isoCalendar = Calendar(identifier: .iso8601)
        isoCalendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .current
        let kw = isoCalendar.component(.weekOfYear, from: item.capturedAt)

        let datumFormatter = DateFormatter()
        datumFormatter.calendar = isoCalendar
        datumFormatter.timeZone = isoCalendar.timeZone
        datumFormatter.dateFormat = "yyyy-MM-dd"

        var felder: [String: AirtableFieldValue] = [
            feldMitarbeiter: .string(mitarbeiter),
            feldDatum: .string(datumFormatter.string(from: item.capturedAt)),
            feldKW: .number(Double(kw)),
            feldStatus: .string("Vorgebucht"),
            feldQuelle: .string(quelle),
        ]
        if let stunden = stunden(aus: item.text) {
            felder[feldDauerH] = .number(stunden)
        }
        return felder
    }

    /// Parst eine erkannte Dauer-Zeichenkette ("4h", "2,5 Std") in eine Stundenzahl.
    /// `nil` bei "?" (unbekannt) oder unlesbarem Text — dann bleibt DauerH einfach leer,
    /// statt eine Zahl zu raten.
    static func stunden(aus dauer: String) -> Double? {
        let bereinigt = dauer
            .lowercased()
            .replacingOccurrences(of: "std", with: "")
            .replacingOccurrences(of: "h", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        return Double(bereinigt)
    }
}
