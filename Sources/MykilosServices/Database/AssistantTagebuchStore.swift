import Foundation
import Observation
import GRDB
import MykilosKit

// MARK: - AssistantTagebuchStore
// Persistente, append-only Protokollierung von Assistent-Friktionspunkten (S10_
// WIRBELSAEULE.md §9). Gleiches Muster wie AuditStore: Schreiben ausschließlich über
// append(_:), wirft Fehler sichtbar weiter statt sie stumm zu verschlucken.
@MainActor
@Observable
public final class AssistantTagebuchStore {
    public private(set) var eintraege: [AssistantTagebuchEintrag] = []
    public private(set) var saveState: SaveState = .idle

    private let database: GRDBDatabase

    public init(db: GRDBDatabase) {
        self.database = db
    }

    public func load(projectID: String? = nil) throws {
        do {
            let records = try database.read { dbConn in
                var request = AssistantTagebuchRecord.order(Column("timestamp").desc)
                if let projectID {
                    request = request.filter(Column("projectID") == projectID)
                }
                return try request.fetchAll(dbConn)
            }
            eintraege = records.compactMap(\.toDomain)
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }

    @discardableResult
    public func append(_ eintrag: AssistantTagebuchEintrag) throws -> AssistantTagebuchEintrag {
        saveState = .saving
        do {
            try database.write { dbConn in
                try AssistantTagebuchRecord(from: eintrag).insert(dbConn)
            }
            eintraege.insert(eintrag, at: 0)
            saveState = .saved(Date())
            return eintrag
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }
}

// MARK: - AssistantTagebuchRecord (GRDB-Spiegel)
struct AssistantTagebuchRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "assistantTagebuch" }

    var id: String
    var timestamp: Double
    var projectID: String?
    var art: String
    var text: String

    init(from eintrag: AssistantTagebuchEintrag) {
        self.id = eintrag.id.uuidString
        self.timestamp = eintrag.timestamp.timeIntervalSince1970
        self.projectID = eintrag.projectID
        self.art = eintrag.art.rawValue
        self.text = eintrag.text
    }

    var toDomain: AssistantTagebuchEintrag? {
        guard let id = UUID(uuidString: id),
              let art = AssistantTagebuchEintrag.Art(rawValue: art) else { return nil }
        return AssistantTagebuchEintrag(
            id: id,
            timestamp: Date(timeIntervalSince1970: timestamp),
            projectID: projectID,
            art: art,
            text: text
        )
    }
}
