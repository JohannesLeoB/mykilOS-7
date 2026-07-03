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
    var clockodoUserID: String?
    var googleDomain: String?
    // V10 Folge-Block A, Vorab (v22_user_identity): additiv, alte Zeilen
    // haben NULL — AppState.ensureUserID() erzeugt + speichert einmalig nach.
    var userID: String?

    init(from profile: UserProfile) {
        self.id = Self.localID
        self.displayName = profile.displayName
        self.role = profile.role
        self.updatedAt = profile.updatedAt.timeIntervalSince1970
        self.clockodoUserID = profile.clockodoUserID
        self.googleDomain = profile.googleDomain
        self.userID = profile.userID
    }

    /// Reine Value-Kopie mit neuer userID — vermeidet `var`-Closure-Captures
    /// in ProfileStore.ensureUserID() (Swift 6 Sendable-Closure-Regel).
    func withUserID(_ newUserID: String) -> ProfileRecord {
        var copy = self
        copy.userID = newUserID
        return copy
    }

    func toDomain() -> UserProfile {
        UserProfile(
            displayName: displayName,
            role: role,
            updatedAt: Date(timeIntervalSince1970: updatedAt),
            clockodoUserID: clockodoUserID,
            googleDomain: googleDomain,
            userID: userID
        )
    }
}
