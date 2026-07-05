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
    //
    // ORPHAN-REBIND (Teil A, 2026-07-05): mit bekannter `googleEmail` (nach der
    // Google-Hydration) wird ZUERST versucht, an die ALTE stabile userID zu
    // rebinden statt bei einem DB-Reset/Neuinstallation eine frische UUID zu
    // vergeben (die alle per-User-Keychain-Einträge des Nutzers verwaisen ließe).
    // Anker-Quellen in Reihenfolge:
    //   1. DB-Anker: ResidentIdentityStore.userID(forEmail:db:) (Personalausweis).
    //   2. Keychain-Anker: KeychainIdentityAnchorStore (überlebt db.sqlite-Löschung).
    // Nicht-Leer-Invariante HART: eine leere/whitespace-Mail führt NIE zu einem
    // Rebind (ein leerer Anker wäre ein geteilter Rebind-Magnet). Volle Mail, nie
    // die Domain. Der `googleEmail`-Default `nil` hält AppState.swift (Boden-Aufruf)
    // + alle bestehenden Test-Call-Sites verhaltensidentisch.
    public static func ensureUserID(
        db: GRDBDatabase,
        googleEmail: String? = nil,
        anchorStore: any IdentityAnchorStoring = KeychainIdentityAnchorStore()
    ) -> String {
        do {
            // Rebind-Zweig GANZ AM ANFANG — nur mit nicht-leerer Mail.
            if let email = googleEmail,
               email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                // 1. DB-Anker, 2. bei Miss Keychain-Anker (überlebt db.sqlite-Verlust).
                // `try?` liefert String?? — mit flatMap auf String? geglättet.
                let keychainAnchor = (try? anchorStore.userID(forEmail: email)).flatMap { $0 }
                let anchoredUserID = ResidentIdentityStore.userID(forEmail: email, db: db)
                    ?? keychainAnchor
                if let alteUUID = anchoredUserID,
                   alteUUID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    // Single-Row id="local" auf die alte UUID rebinden — nur schreiben,
                    // wenn sie abweicht (kein unnötiger Write, keine neue Zeile).
                    let existing = try db.read { dbConn in
                        try ProfileRecord.fetchOne(dbConn, key: ProfileRecord.localID)
                    }
                    if existing?.userID != alteUUID {
                        let base = existing ?? ProfileRecord(from: UserProfile.empty)
                        let rebound = base.withUserID(alteUUID)
                        try db.write { dbConn in try rebound.save(dbConn) }
                    }
                    return alteUUID
                }
            }
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
