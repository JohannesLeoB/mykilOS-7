import Foundation
import Observation
import GRDB
import MykilosKit

// MARK: - ProjectNumberBindingRecord (GRDB)
private struct ProjectNumberBindingRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "projectNumberBindings" }
    var businessRecordID: String
    var projectNumber: String
    var confirmedAt: Double
    var actorUserID: String

    init(from binding: ConfirmedProjectNumberBinding) {
        businessRecordID = binding.businessRecordID
        projectNumber = binding.projectNumber
        confirmedAt = binding.confirmedAt.timeIntervalSince1970
        actorUserID = binding.actorUserID
    }

    var toDomain: ConfirmedProjectNumberBinding {
        ConfirmedProjectNumberBinding(
            businessRecordID: businessRecordID, projectNumber: projectNumber,
            confirmedAt: Date(timeIntervalSince1970: confirmedAt), actorUserID: actorUserID)
    }
}

// MARK: - ProjectNumberBindingStore
// mykilOS 8, Block A (Erweiterung, Johannes-Entscheidung 2026-06-30): die REIN LOKALE,
// redundante Brücke Geschäftsprojekt → Projektnummer. Schreiben passiert NUR nach
// manueller Bestätigung eines `ProjectNumberBindingCandidate` (Karte→Bestätigung→Audit,
// siehe `AppState.confirmProjectNumberBinding`). Upsert (ein Geschäftsprojekt hat höchstens
// eine aktuell gültige Bindung — eine Korrektur überschreibt, der alte Wert wird nicht
// separat aufbewahrt; das ist hier akzeptabel, weil es eine lokale Brücke ist, kein
// externer Datenstrom — der Audit-Log behält trotzdem jede Bestätigung).
@MainActor
@Observable
public final class ProjectNumberBindingStore {
    public private(set) var bindings: [ConfirmedProjectNumberBinding] = []
    public private(set) var saveState: SaveState = .idle

    private let db: GRDBDatabase

    public init(db: GRDBDatabase) {
        self.db = db
    }

    public func load() throws {
        do {
            let records = try db.read { dbConn in
                try ProjectNumberBindingRecord.fetchAll(dbConn)
            }
            bindings = records.map(\.toDomain)
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }

    @discardableResult
    public func confirm(_ candidate: ProjectNumberBindingCandidate, actorUserID: String) throws -> ConfirmedProjectNumberBinding {
        let binding = ConfirmedProjectNumberBinding(
            businessRecordID: candidate.businessRecordID, projectNumber: candidate.projectNumber,
            actorUserID: actorUserID)
        saveState = .saving
        do {
            try db.write { dbConn in
                try ProjectNumberBindingRecord(from: binding).save(dbConn)
            }
            bindings.removeAll { $0.businessRecordID == binding.businessRecordID }
            bindings.append(binding)
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
        return binding
    }

    /// businessRecordID → projectNumber, für `ExternalMappingRegistry.resolve(confirmedBindings:)`.
    public var asLookup: [String: String] {
        Dictionary(uniqueKeysWithValues: bindings.map { ($0.businessRecordID, $0.projectNumber) })
    }
}
