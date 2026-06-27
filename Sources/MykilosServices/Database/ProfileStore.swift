import Foundation
import Observation
import GRDB
import MykilosKit

// MARK: - ProfileStore
// Lokales Nutzerprofil, GRDB-backed, @MainActor @Observable. Single-Row id="local".
// Jeder Schreibvorgang throws, SaveState ist in der UI sichtbar — kein try? im
// Schreibpfad (harte Persistenz-Regel). Form analog AuditStore.
@MainActor
@Observable
public final class ProfileStore {
    public private(set) var profile: UserProfile?
    public private(set) var saveState: SaveState = .idle

    private let db: GRDBDatabase

    public init(db: GRDBDatabase) {
        self.db = db
    }

    /// Lädt die Single-Row. Leere DB → profile = nil (kein Fehler).
    public func load() throws {
        let record = try db.read { dbConn in
            try ProfileRecord.fetchOne(dbConn, key: ProfileRecord.localID)
        }
        profile = record?.toDomain()
    }

    /// Upsert auf id="local". throws + sichtbarer SaveState.
    public func save(_ profile: UserProfile) throws {
        saveState = .saving
        do {
            let record = ProfileRecord(from: profile)
            try db.write { dbConn in
                try record.save(dbConn)
            }
            self.profile = profile
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }

    /// Noch kein eingerichtetes Profil (kein Name).
    public var isEmpty: Bool {
        profile?.isComplete != true
    }
}
