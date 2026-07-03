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

    // MARK: - Stabile lokale userID (V10 Folge-Block A, Vorab)
    // AppState.init() ruft dies SYNCHRON vor jeder Keychain-Store-Konstruktion
    // auf (nicht über die Instanzmethoden load()/save() — die sind für den
    // späteren async bootstrap()-Fluss gedacht und laufen zu spät für die
    // Store-Konstruktion in init()). Liest/schreibt direkt gegen ProfileRecord,
    // da der Typ intern zu MykilosServices ist und AppState (MykilosApp) ihn
    // nicht direkt sehen kann.
    //
    // Fälle:
    //  - Keine Zeile "local" → Platzhalterprofil mit frischer UUID anlegen.
    //    displayName/role bleiben leer; der Onboarding-Wizard füllt sie später
    //    über eine normale ProfileStore.save()-Instanz nach (Upsert auf
    //    dieselbe Zeile — UserProfile.userID wird dabei mitgeführt, nicht
    //    überschrieben, siehe SettingsView/OnboardingWizardView).
    //  - Zeile vorhanden, userID NULL (Bestandsprofil vor v22_user_identity)
    //    → UUID erzeugen und einmalig nachziehen (additiv, kein Datenverlust
    //    an displayName/role/clockodoUserID/googleDomain).
    //  - Zeile vorhanden, userID gesetzt → unverändert zurückgeben, NIE neu
    //    erzeugen (sonst verliert der Nutzer bei jedem Start seine Keychain-
    //    Zuordnung).
    // Best-effort: schlägt die DB hier fehl, fällt auf "local" zurück statt
    // abzustürzen — Keychain-Services bekommen dann den bekannten Fallback-Suffix.
    public static func ensureUserID(db: GRDBDatabase) -> String {
        do {
            if let existing = try db.read({ dbConn in
                try ProfileRecord.fetchOne(dbConn, key: ProfileRecord.localID)
            }) {
                if let userID = existing.userID,
                   userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    return userID
                }
                let freshID = UUID().uuidString
                let updated = existing.withUserID(freshID)
                try db.write { dbConn in try updated.save(dbConn) }
                return freshID
            }
            let freshID = UUID().uuidString
            let placeholder = ProfileRecord(from: UserProfile.empty).withUserID(freshID)
            try db.write { dbConn in try placeholder.save(dbConn) }
            return freshID
        } catch {
            return "local"
        }
    }
}
