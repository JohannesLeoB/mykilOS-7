import Foundation
import Observation
import GRDB
import MykilosKit

// MARK: - ResidentIdentityStore
// Persistenz des Personalausweises (ResidentIdentity), GRDB-backed,
// @MainActor @Observable. Mail-indiziert (googleEmail = Primary Key).
// Jeder Schreibvorgang throws, SaveState ist in der UI sichtbar — kein try?
// im Schreibpfad (harte Persistenz-Regel). Form analog ProfileStore.
//
// EISERNE NICHT-LEER-INVARIANTE: googleEmail wird NIEMALS als "" (oder nur
// Whitespace) geschrieben und in keinem Lookup als Schlüssel akzeptiert. Ein
// leerer Primary Key wäre ein geteilter Anker (Namespace-Kollaps wie der
// "local"-Fallback). Wird an BEIDEN Stellen erzwungen (save + Lookup).
@MainActor
@Observable
public final class ResidentIdentityStore {
    public private(set) var identity: ResidentIdentity?
    public private(set) var saveState: SaveState = .idle

    private let db: GRDBDatabase

    public init(db: GRDBDatabase) {
        self.db = db
    }

    /// Lädt den Ausweis zur gegebenen Mail. Leere/ungültige Mail oder keine
    /// Zeile → identity = nil (kein Fehler).
    public func loadByEmail(_ email: String) throws {
        let key = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard key.isEmpty == false else {
            identity = nil
            return
        }
        let record = try db.read { dbConn in
            try ResidentIdentityRecord.fetchOne(dbConn, key: key)
        }
        identity = record?.toDomain()
    }

    /// Upsert auf googleEmail. throws + sichtbarer SaveState. EINZIGER
    /// Schreibweg. Verweigert einen leeren kanonischen Schlüssel hart.
    public func save(_ identity: ResidentIdentity) throws {
        saveState = .saving
        do {
            guard identity.hasValidKey else {
                throw ResidentIdentityError.emptyEmailKey
            }
            let record = ResidentIdentityRecord(from: identity)
            try db.write { dbConn in
                try record.save(dbConn)
            }
            self.identity = identity
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Best-effort Lookup (Orphan-Wiederanker-Baustein)
    // Findet die stabile userID zu einer verifizierten Mail, wenn ein Ausweis
    // existiert. Best-effort: DB-Fehler/keine Zeile → nil (kein Absturz). Ein
    // leerer/ungültiger Mail-Schlüssel liefert IMMER nil (Nicht-Leer-Invariante),
    // damit ein leerer Schlüssel nie zum geteilten Rebind-Magneten wird.
    public static func userID(forEmail email: String, db: GRDBDatabase) -> String? {
        let key = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard key.isEmpty == false else { return nil }
        do {
            let record = try db.read { dbConn in
                try ResidentIdentityRecord.fetchOne(dbConn, key: key)
            }
            guard let userID = record?.userID,
                  userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                return nil
            }
            return userID
        } catch {
            return nil
        }
    }
}

// MARK: - ResidentIdentityError
public enum ResidentIdentityError: Error, Equatable {
    /// Der kanonische Schlüssel googleEmail war leer/nur Whitespace — ein
    /// leerer Primary Key ist verboten (geteilter Anker-Kollaps).
    case emptyEmailKey
}
