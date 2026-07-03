import Foundation
import GRDB
import MykilosKit

// MARK: - VergebeneNummerRecord (GRDB)
private struct VergebeneNummerRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "vergebeneNummern" }
    var appFormat: String
    var jahr: Int
    var laufendeNummer: Int
    var status: String   // archiviert/reserviert/extern
    var quelle: String?
    var updatedAt: Double

    var projektnummer: Projektnummer { Projektnummer(jahr: jahr, laufendeNummer: laufendeNummer) }
}

// MARK: - LocalSequentialAuthority
// mykilOS 8, Block C (S2): die aktive NumberAuthority (HANDOFF_PROVISIONING_NOMENKLATUR §8).
// Nächste Nummer = max+1 über ALLE bekannten Nummern: die AKTIVEN (live aus der Registry,
// per injiziertem Provider) PLUS die GESPEICHERTEN (archiviert/reserviert/extern in GRDB).
// Strikt max+1, keine Lücken, nie wiederverwenden (auch Archiv prüfen).
//
// Austauschbar gegen AirtableAuthority/SevdeskPrescribedAuthority (per Config), ohne dass
// Vergabe-Aufrufer angefasst werden. `now`/`aktiveNummern` injizierbar für Tests.
public final class LocalSequentialAuthority: NumberAuthority, @unchecked Sendable {
    private let db: GRDBDatabase
    private let aktiveNummern: @Sendable () async -> [Projektnummer]
    private let now: @Sendable () -> Date

    public init(
        db: GRDBDatabase,
        aktiveNummern: @escaping @Sendable () async -> [Projektnummer],
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.db = db
        self.aktiveNummern = aktiveNummern
        self.now = now
    }

    /// Alle bekannten Nummern: aktiv (Registry) + gespeichert (GRDB).
    private func alleBekannten() async throws -> [Projektnummer] {
        let aktiv = await aktiveNummern()
        let gespeichert = try db.read { try VergebeneNummerRecord.fetchAll($0) }.map(\.projektnummer)
        return aktiv + gespeichert
    }

    /// Nur BERECHNUNG (Vorschau für die UI) — reserviert NICHT. Für die echte Vergabe
    /// `nextAndReserve()` nutzen, sonst könnten zwei Aufrufer dieselbe Nummer ziehen.
    public func nextProjektnummer(jahr: Int) async throws -> Projektnummer {
        Projektnummer.next(jahr: jahr, vorhandene: try await alleBekannten())
    }

    /// Härtung (2026-07-01): reine Vorschau (reserviert NICHT), aber zusätzlich gegen einen
    /// externen Kollisions-Check geprüft — damit eine UI-Vorschau exakt die Nummer zeigt, die
    /// `nextAndReserveKollisionsfrei` bei der echten Anlage auch vergeben würde. Übersprungene
    /// Kandidaten werden nur INNERHALB dieses einen Aufrufs lokal ausgeschlossen, nichts wird
    /// persistiert — für die tatsächliche, atomare Vergabe `nextAndReserveKollisionsfrei` nutzen.
    public func nextProjektnummerKollisionsfrei(
        jahr: Int, istExternKollidiert: (Projektnummer) -> Bool, maxVersuche: Int = 25
    ) async throws -> Projektnummer {
        let bekannte = try await alleBekannten()
        var ausgeschlossen: [Projektnummer] = []
        for _ in 0..<maxVersuche {
            let kandidat = Projektnummer.next(jahr: jahr, vorhandene: bekannte + ausgeschlossen)
            if istExternKollidiert(kandidat) == false { return kandidat }
            ausgeschlossen.append(kandidat)
        }
        throw NumberAuthorityError.keineKollisionsfreieNummerGefunden(jahr: jahr, versuche: maxVersuche)
    }

    /// ATOMARE Vergabe: berechnet die nächste freie Nummer UND reserviert sie in EINER
    /// GRDB-Transaktion. Race-frei — zwei gleichzeitige Aufrufe werden durch die serielle
    /// Write-Queue serialisiert; der zweite sieht die vom ersten reservierte Nummer und
    /// zieht max+1. Das ist der Pfad, den die echte Projekt-Anlage (Block D) nutzt.
    public func nextAndReserve(jahr: Int) async throws -> Projektnummer {
        let aktiv = await aktiveNummern()   // Snapshot der aktiven (Registry); ändert sich nicht durch Vergabe
        let ts = now().timeIntervalSince1970
        return try db.write { dbc in
            let gespeichert = try VergebeneNummerRecord.fetchAll(dbc).map(\.projektnummer)
            let next = Projektnummer.next(jahr: jahr, vorhandene: aktiv + gespeichert)
            try VergebeneNummerRecord(
                appFormat: next.appFormat, jahr: next.jahr, laufendeNummer: next.laufendeNummer,
                status: "reserviert", quelle: nil, updatedAt: ts).insert(dbc)
            return next
        }
    }

    /// Härtung (2026-07-01, echte Live-Kollision entdeckt): `nextAndReserve` allein kennt nur
    /// die Registry (Airtable-Snapshot, kann veraltet sein) + die eigenen GRDB-Reservierungen —
    /// beides blind gegenüber Ordnern/Nummern, die manuell oder außerhalb der App entstehen.
    /// Diese Variante nimmt zusätzlich einen externen Kollisions-Check entgegen (z. B. gegen den
    /// echten Drive-Ordnerinhalt) und probiert bei einem Treffer die nächste Nummer — max.
    /// `maxVersuche` Läufe, danach ein klarer Fehler statt einer Endlosschleife. Eine bereits
    /// reservierte, extern kollidierende Nummer wird NIE zurückgegeben/wiederverwendet
    /// (Projektnummern sind grundsätzlich einmalig) — das ist kein Nummern-„Verbrauch", sondern
    /// korrektes Verhalten: diese Nummer war real schon vergeben, nur der Registry unbekannt.
    public func nextAndReserveKollisionsfrei(
        jahr: Int, istExternKollidiert: (Projektnummer) -> Bool, maxVersuche: Int = 25
    ) async throws -> Projektnummer {
        for _ in 0..<maxVersuche {
            let kandidat = try await nextAndReserve(jahr: jahr)
            if istExternKollidiert(kandidat) == false { return kandidat }
        }
        throw NumberAuthorityError.keineKollisionsfreieNummerGefunden(jahr: jahr, versuche: maxVersuche)
    }

    public func isVergeben(_ nummer: Projektnummer) async throws -> Bool {
        try await alleBekannten().contains(nummer)
    }

    public func reserve(_ nummer: Projektnummer) async throws {
        guard try await isVergeben(nummer) == false else {
            throw NumberAuthorityError.bereitsVergeben(nummer)
        }
        try speichere(nummer, status: "reserviert", quelle: nil)
    }

    public func bindFromExternal(quelle: String, nummer: Projektnummer) async throws {
        // Extern vorgegeben (z. B. künftig Sevdesk via Airtable/Make): auch hier nie eine
        // bereits aktive/archivierte Nummer überschreiben.
        guard try await isVergeben(nummer) == false else {
            throw NumberAuthorityError.bereitsVergeben(nummer)
        }
        try speichere(nummer, status: "extern", quelle: quelle)
    }

    /// Markiert eine Nummer als archiviert (Projekt gelöscht) — nie wieder vergebbar.
    /// Überschreibt KEINE extern (z. B. Sevdesk) gebundene Nummer still — die behält
    /// ihre Herkunft; archivieren ist nur für lokale/reservierte/aktive Nummern gedacht.
    public func archiviere(_ nummer: Projektnummer) throws {
        let bestehend = try db.read { try VergebeneNummerRecord.fetchOne($0, key: nummer.appFormat) }
        if bestehend?.status == "extern" { return }   // Herkunft nicht still überschreiben
        try speichere(nummer, status: "archiviert", quelle: nil)
    }

    private func speichere(_ nummer: Projektnummer, status: String, quelle: String?) throws {
        let ts = now().timeIntervalSince1970
        try db.write { dbc in
            try VergebeneNummerRecord(
                appFormat: nummer.appFormat, jahr: nummer.jahr, laufendeNummer: nummer.laufendeNummer,
                status: status, quelle: quelle, updatedAt: ts).save(dbc)
        }
    }

    /// Alle gespeicherten (nicht-aktiven) Nummern — für Diagnose/Tests.
    public func gespeicherteNummern() throws -> [Projektnummer] {
        try db.read { try VergebeneNummerRecord.order(Column("jahr").desc, Column("laufendeNummer").desc).fetchAll($0) }
            .map(\.projektnummer)
    }
}
