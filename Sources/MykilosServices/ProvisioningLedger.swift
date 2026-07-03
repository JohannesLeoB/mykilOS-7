import Foundation
import GRDB
import MykilosKit

// MARK: - ProvisioningLedgerRecord (GRDB)
private struct ProvisioningLedgerRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "provisioningLedger" }
    var idempotenzSchluessel: String
    var projektnummer: String
    var kdnr: String
    var status: String
    var erledigteSchritteJSON: String
    var driveProjektOrdnerID: String?
    var driveUnterordnerJSON: String
    var airtableRecordID: String?
    var clickUpListID: String?
    var letzterFehler: String?
    var updatedAt: Double

    init(from r: ProvisioningResult) {
        idempotenzSchluessel = r.idempotenzSchluessel
        projektnummer = r.projektnummer
        kdnr = r.kdnr
        status = r.status.rawValue
        erledigteSchritteJSON = Self.encode(Array(r.erledigteSchritte).map(\.rawValue))
        driveProjektOrdnerID = r.driveProjektOrdnerID
        driveUnterordnerJSON = Self.encode(r.driveUnterordnerIDs)
        airtableRecordID = r.airtableRecordID
        clickUpListID = r.clickUpListID
        letzterFehler = r.letzterFehler
        updatedAt = r.updatedAt.timeIntervalSince1970
    }

    var toDomain: ProvisioningResult {
        let schritte = (Self.decode([String].self, erledigteSchritteJSON) ?? [])
            .compactMap(ProvisioningStep.init(rawValue:))
        return ProvisioningResult(
            idempotenzSchluessel: idempotenzSchluessel, projektnummer: projektnummer, kdnr: kdnr,
            status: ProvisioningStatus(rawValue: status) ?? .offen,
            erledigteSchritte: Set(schritte),
            driveProjektOrdnerID: driveProjektOrdnerID,
            driveUnterordnerIDs: Self.decode([String: String].self, driveUnterordnerJSON) ?? [:],
            airtableRecordID: airtableRecordID, clickUpListID: clickUpListID, letzterFehler: letzterFehler,
            updatedAt: Date(timeIntervalSince1970: updatedAt))
    }

    // Review-Fix (high): ein stiller Encode-Fehler durfte NIE unbemerkt auf "[]"/"{}" zurückfallen —
    // das würde Ledger-Zustand (z. B. driveUnterordnerIDs) unsichtbar verlieren. Fehler wird jetzt
    // laut geloggt; der Fallback bleibt nur als letzte Absicherung gegen einen Crash beim Schreiben.
    static func encode<T: Encodable>(_ v: T) -> String {
        do {
            let data = try JSONEncoder().encode(v)
            guard let json = String(data: data, encoding: .utf8) else {
                MykLog.lifecycle.error("ProvisioningLedger: UTF8-Dekodierung nach JSON-Encode fehlgeschlagen für \(String(describing: T.self), privacy: .public)")
                return v is [String] ? "[]" : "{}"
            }
            return json
        } catch {
            MykLog.lifecycle.error("ProvisioningLedger: JSON-Encode fehlgeschlagen für \(String(describing: T.self), privacy: .public): \(String(describing: error), privacy: .public)")
            return v is [String] ? "[]" : "{}"
        }
    }
    static func decode<T: Decodable>(_ type: T.Type, _ json: String) -> T? {
        guard let data = json.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            MykLog.lifecycle.error("ProvisioningLedger: JSON-Decode fehlgeschlagen für \(String(describing: T.self), privacy: .public): \(String(describing: error), privacy: .public)")
            return nil
        }
    }
}

// MARK: - ProvisioningLedger
// mykilOS 8, Block D (S4): persistiert den Provisioning-Stand je Projekt (Kdnr+Projektnummer).
// Quelle der Idempotenz UND der Teilfehler-Wiederaufnahme: der Service liest hier, was schon
// erledigt ist, und führt nur fehlende Schritte aus. Rein lokal — kein externer Write.
@MainActor
@Observable
public final class ProvisioningLedger {
    public private(set) var saveState: SaveState = .idle
    private let db: GRDBDatabase

    public init(db: GRDBDatabase) { self.db = db }

    /// Bestehender Stand für einen Idempotenz-Schlüssel (Kdnr+Projektnummer) oder nil.
    public func eintrag(fuer schluessel: String) throws -> ProvisioningResult? {
        try db.read { try ProvisioningLedgerRecord.fetchOne($0, key: schluessel) }?.toDomain
    }

    public func alle() throws -> [ProvisioningResult] {
        try db.read { try ProvisioningLedgerRecord.order(Column("updatedAt").desc).fetchAll($0) }.map(\.toDomain)
    }

    /// Schreibt/aktualisiert den Stand (Upsert). Wirft bei DB-Fehler.
    public func speichere(_ result: ProvisioningResult) throws {
        saveState = .saving
        do {
            var r = result; r.updatedAt = Date()
            try db.write { try ProvisioningLedgerRecord(from: r).save($0) }
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }

    /// Entfernt einen Ledger-Eintrag (z. B. nach TEST-Sandbox-Cleanup).
    public func entferne(schluessel: String) throws {
        try db.write { _ = try ProvisioningLedgerRecord.deleteOne($0, key: schluessel) }
    }
}
