import Foundation
import GRDB

// MARK: - MultiUserBackfill
// Ordnet Alt-Zeilen der privaten, per-Bewohner-isolierten Stores (userID IS NULL,
// angelegt VOR der Multi-User-Isolation) dem geräteweiten Erst-Bewohner (Device
// Primary) zu. Ohne diesen Schritt würden nach Einführung der userID-Filterung
// die bestehenden Chats/Notizen/Zeiten des Erst-Bewohners für NIEMANDEN mehr
// sichtbar (Filter userID == aktiveID trifft die NULL-Zeilen nicht).
//
// EISERNE ISOLATIONS-INVARIANTE: Der Backfill läuft NUR, wenn der aktive Bewohner
// der Primary ist (Aufrufer prüft loadDevicePrimary() == aktive userID). Startet
// ein ZWEIT-Bewohner zuerst, bleiben die NULL-Zeilen unberührt — und sind für ihn
// (Filter userID == seineID) unsichtbar. So gibt es weder Datenverlust (der
// Primary bekommt seine Alt-Daten beim nächsten eigenen Start) noch ein Leak.
//
// Idempotent: nach dem ersten Lauf gibt es keine NULL-Zeilen mehr → 0 betroffene
// Zeilen. Darf bei jedem App-Start gefahrlos laufen.
public enum MultiUserBackfill {
    /// Die privaten Tabellen mit einer nullable userID-Spalte. Wird pro Store
    /// erweitert, sobald dessen Isolation gebaut ist. Feste, interne Whitelist —
    /// KEINE User-Eingabe, daher ist die Tabellennamen-Interpolation unten sicher.
    static let isolatedTables = ["chatMessages"]

    /// Setzt userID = primaryUserID für alle Zeilen mit userID IS NULL in den
    /// isolierten Tabellen. Leere/whitespace-userID ist ein No-Op (Schutz gegen
    /// einen kaputten Primary-Anker).
    public static func assignNullRowsToPrimary(db: GRDBDatabase, primaryUserID: String) throws {
        let trimmed = primaryUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        try db.write { dbConn in
            for table in isolatedTables {
                try dbConn.execute(
                    sql: "UPDATE \(table) SET userID = ? WHERE userID IS NULL",
                    arguments: [trimmed]
                )
            }
        }
    }
}
