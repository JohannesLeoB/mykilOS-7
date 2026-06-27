import Foundation
import GRDB
import MykilosKit

// MARK: - ProfileRecord
// GRDB-Persistenz des lokalen Nutzerprofils. Genau EINE Zeile mit fixer
// id = "local" — bewusste V1-Vereinfachung gegenüber dem Team-Identitätsmodell.
// Datum als timeIntervalSince1970 (Double), konsistent mit notes/auditEntries.
struct ProfileRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "userProfile"
    static let localID = "local"

    var id: String
    var displayName: String
    var role: String
    var updatedAt: Double

    init(from profile: UserProfile) {
        self.id = Self.localID
        self.displayName = profile.displayName
        self.role = profile.role
        self.updatedAt = profile.updatedAt.timeIntervalSince1970
    }

    func toDomain() -> UserProfile {
        UserProfile(
            displayName: displayName,
            role: role,
            updatedAt: Date(timeIntervalSince1970: updatedAt)
        )
    }
}
