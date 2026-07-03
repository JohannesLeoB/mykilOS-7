import Foundation
import MykilosKit

// MARK: - ClockodoAdapterWriter
// mykilOS 8, Multi-Base-Architektur v2 (2026-07-01, Johannes freigegeben): spiegelt ein
// lokal bestätigtes `TimeSegment` (TimerStore.confirmBooking, "Karte→Bestätigung" bereits
// erfolgt) als "Vorgebucht"-Zeile in die neue Airtable-Base `mykilOS-Adapter Clockodo`
// (appuQDCFGLmjo2L6T, Tabelle Zeitbuchungen). Append-only, ein Record pro Segment.
//
// Bewusst KEIN echter Clockodo-API-POST — das ist dauerhaft ausgeschlossen (Eiserne
// Regel: Clockodo read-only + Postbox). Diese Airtable-Zeile ist die einzige Schreib-
// Eskalationsstufe: sichtbar, nach Mitarbeiter/Tag/Woche/Projekt/Kostenstelle
// aufgegliedert, editierbar/prüfbar direkt in Airtable — die tatsächliche Buchung
// bleibt manuelle Eigeneingabe des Nutzers in Clockodo selbst.
public struct ClockodoAdapterWriter: Sendable {
    public static let baseID = "appuQDCFGLmjo2L6T"
    public static let table = "Zeitbuchungen"

    // Feld-IDs (aus der Tabellen-Anlage 2026-07-01, tbllYkxcHzI2YMUqn) — Airtable
    // akzeptiert beim Schreiben sowohl Namen als auch IDs, IDs überleben aber ein
    // künftiges Umbenennen der Spalte in der Airtable-UI.
    static let feldProjektnummer = "fldZiKQ53dwlIzoWN"
    static let feldMitarbeiter   = "fld7svgqwzUBJzkC9"
    static let feldDatum         = "fld7ViaC4kPDNEEND"
    static let feldKW            = "fldnq5arv7fhM6pUE"
    static let feldProjektTitel  = "fld6PKTznAtIw6pWq"
    static let feldKostenstelle  = "fld481ZJPcJZfa0kb"
    static let feldDauerH        = "fldvN8gPs4urBygFY"
    static let feldStart         = "fldDzRbp4B3slfBzo"
    static let feldEnde          = "fldE5GKPD7OumULcP"
    static let feldStatus        = "fldNzN4hs0IPcpeYl"
    static let feldQuelle        = "fldiLBSYLpC1mCiFt"

    private let creator: AirtableRecordCreating

    public init(creator: AirtableRecordCreating) {
        self.creator = creator
    }

    /// Schreibt EIN gebuchtes `TimeSegment` als "Vorgebucht"-Zeile. Wirft bei Whitelist-
    /// Verletzung oder Netzwerkfehler — der Aufrufer (AppState) behandelt das non-fatal:
    /// die lokale Buchung bleibt in jedem Fall gültig, dieser Sync ist ein Best-Effort-Spiegel.
    @discardableResult
    public func schreibeVorbuchung(_ segment: TimeSegment, mitarbeiter: String) async throws -> String {
        try await creator.createRecord(
            baseID: Self.baseID, table: Self.table,
            fields: Self.felder(fuer: segment, mitarbeiter: mitarbeiter))
    }

    /// Reine, testbare Feld-Abbildung (kein Netzwerk) — Kalenderwoche nach ISO-8601
    /// (Montag als Wochenstart, Woche 1 enthält den ersten Donnerstag des Jahres).
    public nonisolated static func felder(
        fuer segment: TimeSegment, mitarbeiter: String
    ) -> [String: AirtableFieldValue] {
        var isoCalendar = Calendar(identifier: .iso8601)
        isoCalendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .current
        let kw = isoCalendar.component(.weekOfYear, from: segment.startedAt)

        let datumFormatter = DateFormatter()
        datumFormatter.calendar = isoCalendar
        datumFormatter.timeZone = isoCalendar.timeZone
        datumFormatter.dateFormat = "yyyy-MM-dd"

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        let stunden = (segment.seconds / 3600 * 100).rounded() / 100

        return [
            feldProjektnummer: .string(segment.projektNummer),
            feldMitarbeiter: .string(mitarbeiter),
            feldDatum: .string(datumFormatter.string(from: segment.startedAt)),
            feldKW: .number(Double(kw)),
            feldProjektTitel: .string(segment.projektTitel),
            feldKostenstelle: .string(segment.kostenstelle),
            feldDauerH: .number(stunden),
            feldStart: .string(isoFormatter.string(from: segment.startedAt)),
            feldEnde: .string(isoFormatter.string(from: segment.endedAt)),
            feldStatus: .string("Vorgebucht"),
            feldQuelle: .string("Timer"),
        ]
    }
}
