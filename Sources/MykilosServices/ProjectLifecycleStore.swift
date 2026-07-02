import Foundation
import Observation
import GRDB
import MykilosKit

// MARK: - ProjectLifecycleRecord (GRDB)
private struct ProjectLifecycleRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "projectLifecycleStage" }
    var projectNumber: String
    var stageIndex: Int
    var setAt: Double
}

// MARK: - ProjectLifecycleStore
// Rein lokale, vom Nutzer gesetzte Lebenszyklus-Stufe je Projekt (mykilOS 8, 2026-07-02).
// Die App hat sonst keine Stufe (phase = nur Status). Upsert je Projektnummer; kein
// externer Write. Wer keine Stufe gesetzt hat, bekommt beim Anzeigen die aus echten
// Signalen abgeleitete Startstufe (ProjectLifecycleDeriver) — die wird NICHT automatisch
// persistiert, sonst würde ein Vorschlag zur „Wahrheit" ohne Zutun des Nutzers.
@MainActor
@Observable
public final class ProjectLifecycleStore {
    public private(set) var stages: [String: ProjectLifecycleStage] = [:]
    public private(set) var saveState: SaveState = .idle

    private let db: GRDBDatabase

    public init(db: GRDBDatabase) {
        self.db = db
    }

    public func load() throws {
        do {
            let records = try db.read { try ProjectLifecycleRecord.fetchAll($0) }
            var map: [String: ProjectLifecycleStage] = [:]
            for r in records {
                if let stage = ProjectLifecycleStage(rawValue: r.stageIndex) {
                    map[r.projectNumber] = stage
                }
            }
            stages = map
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }

    /// Die vom Nutzer gesetzte Stufe, falls vorhanden (nil = noch nie gesetzt → Aufrufer
    /// nutzt die abgeleitete Startstufe).
    public func stage(for projectNumber: String) -> ProjectLifecycleStage? {
        stages[projectNumber]
    }

    public func setStage(_ stage: ProjectLifecycleStage, for projectNumber: String) throws {
        saveState = .saving
        let record = ProjectLifecycleRecord(
            projectNumber: projectNumber, stageIndex: stage.rawValue, setAt: Date().timeIntervalSince1970)
        do {
            try db.write { try record.save($0) }
            stages[projectNumber] = stage
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }
}
