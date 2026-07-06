import Foundation
import Observation
import GRDB
import MykilosKit

// MARK: - DatenschutzPraeferenzenRecord
private struct DatenschutzPraeferenzenRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "datenschutzPraeferenzen"
    static let localID = "local"

    var id: String
    var teileMailMitAssistent: Bool
    var teileNotizenMitAssistent: Bool
    var teileChatMitAssistent: Bool
    var teileClockodoMitAssistent: Bool
    var kiKomplettAus: Bool
    var updatedAt: Double

    init(from praeferenzen: DatenschutzPraeferenzen) {
        self.id = Self.localID
        self.teileMailMitAssistent = praeferenzen.teileMailMitAssistent
        self.teileNotizenMitAssistent = praeferenzen.teileNotizenMitAssistent
        self.teileChatMitAssistent = praeferenzen.teileChatMitAssistent
        self.teileClockodoMitAssistent = praeferenzen.teileClockodoMitAssistent
        self.kiKomplettAus = praeferenzen.kiKomplettAus
        self.updatedAt = praeferenzen.updatedAt.timeIntervalSince1970
    }

    var toDomain: DatenschutzPraeferenzen {
        DatenschutzPraeferenzen(
            teileMailMitAssistent: teileMailMitAssistent,
            teileNotizenMitAssistent: teileNotizenMitAssistent,
            teileChatMitAssistent: teileChatMitAssistent,
            teileClockodoMitAssistent: teileClockodoMitAssistent,
            kiKomplettAus: kiKomplettAus,
            updatedAt: Date(timeIntervalSince1970: updatedAt)
        )
    }
}

// MARK: - DatenschutzPraeferenzenStore
// Vision-Doku "Nutzerprofil & Datenschutz", Stufe 3 (UI-Gerüst). GRDB-backed, @MainActor
// @Observable, Single-Row id="local" — Form analog ProfileStore. Jeder Schreibvorgang throws,
// SaveState ist sichtbar, jeder Fehler im Schreibpfad wird geworfen statt verschluckt.
@MainActor
@Observable
public final class DatenschutzPraeferenzenStore {
    public private(set) var praeferenzen: DatenschutzPraeferenzen = .standard
    public private(set) var saveState: SaveState = .idle

    private let db: GRDBDatabase

    public init(db: GRDBDatabase) {
        self.db = db
    }

    /// Lädt die Single-Row. Leere DB → Standard-Präferenzen (alles freigegeben, KI-aus false).
    public func load() throws {
        let record = try db.read { dbConn in
            try DatenschutzPraeferenzenRecord.fetchOne(dbConn, key: DatenschutzPraeferenzenRecord.localID)
        }
        praeferenzen = record?.toDomain ?? .standard
    }

    /// Upsert auf id="local".
    public func speichere(_ neu: DatenschutzPraeferenzen) throws {
        saveState = .saving
        do {
            let record = DatenschutzPraeferenzenRecord(from: neu)
            try db.write { dbConn in try record.save(dbConn) }
            praeferenzen = neu
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }
}
