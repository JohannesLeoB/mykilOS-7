import Foundation
import GRDB
import MykilosKit

// MARK: - ResidentIdentityRecord
// GRDB-Persistenz des Personalausweises (ResidentIdentity). Mail-indiziert:
// googleEmail ist der Primary Key (kanonischer Anker für den Orphan-
// Wiederanker). Datum als timeIntervalSince1970 (Double), konsistent mit
// ProfileRecord/notes/auditEntries.
//
// TRÄGT NIE EIN SECRET — nur Handles/IDs (siehe ResidentIdentity).
struct ResidentIdentityRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "residentIdentity"

    var googleEmail: String
    var userID: String
    var displayName: String?
    var clockodoUserID: String?
    var clockodoEntwurfsTabelle: String?
    var clickUpMemberID: String?
    var airtableRecordID: String?
    var updatedAt: Double

    init(from identity: ResidentIdentity) {
        self.googleEmail = identity.googleEmail
        self.userID = identity.userID
        self.displayName = identity.displayName
        self.clockodoUserID = identity.clockodoUserID
        self.clockodoEntwurfsTabelle = identity.clockodoEntwurfsTabelle
        self.clickUpMemberID = identity.clickUpMemberID
        self.airtableRecordID = identity.airtableRecordID
        self.updatedAt = identity.updatedAt.timeIntervalSince1970
    }

    func toDomain() -> ResidentIdentity {
        ResidentIdentity(
            googleEmail: googleEmail,
            userID: userID,
            displayName: displayName,
            clockodoUserID: clockodoUserID,
            clockodoEntwurfsTabelle: clockodoEntwurfsTabelle,
            clickUpMemberID: clickUpMemberID,
            airtableRecordID: airtableRecordID,
            updatedAt: Date(timeIntervalSince1970: updatedAt)
        )
    }
}
