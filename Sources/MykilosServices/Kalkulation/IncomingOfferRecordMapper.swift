import Foundation
import MykilosKalkulationsCore

// MARK: - feat/tischler-predictor · Phase 2 (Lese-Adapter gegen das ECHTE Schema)
//
// `IncomingOfferRecordMapper` ist die getestete, NETZWERKFREIE Naht zwischen der
// Airtable-Tabelle `Eingehende-Angebote` (tbliKfs5FnufjdB36, Base appuVMh3KDfKw4OoQ)
// und `[AirtableOfferEntry]` → `LearningStore.syncAirtableOffers(_:)`.
//
// Bewusst nur das Mapping, KEIN Live-Fetch: die Tabelle ist aktuell leer (0 Zeilen,
// am 2026-06-29 verifiziert) — sie ist das Sync-ZIEL, nicht die Datenquelle. Sobald
// sie befüllt ist und ihre Vokabeln einen Geschäftsabschluss tragen, reicht ein dünner
// AirtableClient-Aufruf seine Records hier durch. Kein spekulativer Live-Pfad gegen Leere.
//
// ── Ehrlicher Schema-Befund (echtes Schema, kein Raten) ──────────────────────────────
// Reale Felder: SHA256 · Datei-Name · Projekt-Nr · Richtung(eingehend/ausgehend) ·
//   Kategorie(Tischler/Stein/Elektro/Sanitaer/Gesamt/Sonstiges) · Lieferant ·
//   Netto-Summe · Anker-Anzahl · Status(Neu/Verarbeitet/Archiviert) · Lern-Gewicht ·
//   Importiert-am.
//
// Zwei Lücken, die das Mapping NICHT überspielt (sonst wäre es Scheinpräzision):
//   1. `Status` ist ein WORKFLOW-Status (Neu/Verarbeitet/Archiviert), KEIN Geschäfts-
//      ausgang. Es gibt kein Feld „akzeptiert/abgelehnt/Schlussrechnung". Darum mappt
//      JEDE Zeile auf `.eingegangen` → `learningReason == nil` → `syncAirtableOffers`
//      importiert sie als „kein Learning-Signal". Ein Preis wird erst über das
//      MENSCHLICHE Review-Gate (`confirmOfferAnchor`) zum Anker — nie automatisch aus
//      dieser Tabelle abgeleitet. Das ist die Regel „keine Auto-Promotion" in Code.
//   2. Es gibt KEIN Angebotsdatum, nur „Importiert-am". Das tragen wir als `datum`
//      durch (besser als nichts für die Zeitgewichtung), aber der Konfidenz-Abschlag
//      in `OfferAnchorInflation` behandelt ein unbekanntes Angebotsjahr ohnehin
//      konservativ.
public enum IncomingOfferRecordMapper {

    /// Reale Airtable-Feldnamen der Tabelle `Eingehende-Angebote`.
    private enum Field {
        static let recordID = "_airtableRecordID"   // vom AirtablePage-Decoder injiziert
        static let richtung = "Richtung"
        static let lieferant = "Lieferant"
        static let nettoSumme = "Netto-Summe"
        static let projektNr = "Projekt-Nr"
        static let dateiName = "Datei-Name"
        static let importiertAm = "Importiert-am"
    }

    /// Mappt rohe Airtable-Records (Feld-Dictionaries inkl. `_airtableRecordID`) auf
    /// `[AirtableOfferEntry]`. Überspringt Zeilen ohne die Pflichtfelder Record-ID,
    /// Richtung und Lieferant — kein stilles Erfinden fehlender Daten.
    public static func map(from records: [[String: AirtableFieldValue]]) -> [AirtableOfferEntry] {
        records.compactMap { fields in
            guard let recordID = fields[Field.recordID]?.stringValue,
                  let kind = kind(from: fields[Field.richtung]?.stringValue),
                  let partner = fields[Field.lieferant]?.stringValue?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                  partner.isEmpty == false
            else { return nil }

            let netto = fields[Field.nettoSumme]?.numberValue ?? 0
            let projekt = fields[Field.projektNr]?.stringValue ?? ""
            let dateiName = fields[Field.dateiName]?.stringValue
            // Kein Angebotsdatum im Schema → „Importiert-am" als beste verfügbare Näherung.
            let datum = fields[Field.importiertAm]?.stringValue ?? ""

            return AirtableOfferEntry(
                airtableRecordID: recordID,
                kind: kind,
                projekt: projekt,
                partner: partner,
                datum: datum,
                nettoEur: Decimal(netto),
                // Workflow-Status trägt KEINEN Geschäftsausgang → bewusst signal-frei.
                // Promotion zum Anker nur über das menschliche Review-Gate.
                status: .eingegangen,
                dokumentURL: nil,
                leistungsbeschreibung: dateiName
            )
        }
    }

    /// Tolerantes Richtung-Mapping. Unbekannt/leer → nil (Zeile wird übersprungen).
    private static func kind(from raw: String?) -> AirtableOfferKind? {
        switch raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "eingehend": return .eingehend
        case "ausgehend": return .ausgehend
        default:          return nil
        }
    }
}
