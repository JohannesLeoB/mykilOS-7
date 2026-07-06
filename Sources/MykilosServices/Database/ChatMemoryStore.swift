import Foundation
import GRDB
import MykilosKit

// MARK: - ChatMemorySummaryRecord
// GRDB-Persistenz für ChatMemorySummary. Upsert-only (save() überschreibt die
// Zeile je scopeKey) — es gibt bewusst keine Historie/Versionierung.
struct ChatMemorySummaryRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "chatMemorySummaries"

    var scopeKey: String
    var summaryText: String
    var coveredThroughMessageID: String
    var updatedAt: Double

    enum Columns {
        static let scopeKey = Column(CodingKeys.scopeKey)
    }
}

// MARK: - ChatMemoryStore
// @MainActor, GRDB-backed. Ein Row je Scope, IMMER überschrieben (nie
// angehängt) — das destillierte Gedächtnis soll den aktuellen Stand spiegeln,
// nicht Vergangenheit anhäufen. Gleiches Muster wie ChatStore (load-if-needed,
// throws, SaveState sichtbar), aber ohne @Observable — wird nicht direkt in
// der UI gebunden, nur von ConversationEngine gelesen/geschrieben.
//
// MULTI-USER-ISOLATION (2026-07-06, Nacht-Session): die destillierte
// Zusammenfassung ist PRIVAT (abgeleitet aus dem bereits isolierten
// ChatStore — Rohchat ist nie kreuzlesbar, die Verdichtung darf es dann auch
// nicht sein). `ChatScope.rawKey` ist projekt-/board-basiert (z. B.
// "project:2026-042") und damit zwischen Bewohnern IDENTISCH — ohne
// Trennung würde Bewohner B beim ersten Chat über dasselbe Projekt die
// Zusammenfassung von Bewohner A lesen ODER überschreiben (die Tabelle hat
// `scopeKey` als Primärschlüssel, kein separates userID-Feld, kein
// Tabellen-Rebuild in dieser Codebase vorhanden). Fix additiv, ohne Migration:
// die Bewohner-ID wird in den PERSISTIERTEN Storage-Key eingebettet
// ("<userID>::<scopeKey>") — gleiches Prinzip wie TimerStore.activeTimer, das
// seine `id`-Spalte doppelt als Bewohner-Schlüssel nutzt. Der DOMAIN-Wert
// `ChatMemorySummary.scopeKey` bleibt für Aufrufer (ConversationEngine)
// unverändert der reine Scope-Key — nur die Storage-Schicht hier kennt den
// Präfix. Alt-Zeilen (vor diesem Fix, unpräfigiert) werden von
// `MultiUserBackfill` dem Erst-Bewohner zugeordnet (Rename, kein Duplikat).
@MainActor
public final class ChatMemoryStore {
    public private(set) var saveState: SaveState = .idle

    private let db: GRDBDatabase
    // Der aktive Bewohner — geht in den Storage-Key ein (siehe storageKey(_:)).
    private let userID: String?
    private var cache: [String: ChatMemorySummary] = [:]
    private var loadedScopes: Set<String> = []

    public init(db: GRDBDatabase, userID: String? = CurrentUserContext.current) {
        self.db = db
        self.userID = userID
    }

    /// Bewohner-präfigierter Persistenz-Schlüssel. "shared" als Fallback nur,
    /// falls userID fehlt (z. B. sehr früher Boot-Zustand) — bewusst kein `nil`/
    /// leerer String, damit der Schlüssel immer eindeutig bleibt.
    private func storageKey(_ scopeKey: String) -> String {
        "\(userID ?? "shared")::\(scopeKey)"
    }

    /// Liest die aktuelle Zusammenfassung eines Scopes (nil = noch nie verdichtet).
    public func summary(for scope: ChatScope) throws -> ChatMemorySummary? {
        let domainKey = scope.rawKey
        let key = storageKey(domainKey)
        if loadedScopes.contains(key) == false {
            let record = try db.read { dbConn in
                try ChatMemorySummaryRecord.fetchOne(dbConn, key: key)
            }
            if let record {
                // Domain-Objekt bekommt den REINEN Scope-Key zurück (nicht den
                // präfigierten Storage-Key) — für Aufrufer bleibt scopeKey unverändert.
                cache[key] = ChatMemorySummary(
                    scopeKey: domainKey,
                    summaryText: record.summaryText,
                    coveredThroughMessageID: record.coveredThroughMessageID,
                    updatedAt: Date(timeIntervalSince1970: record.updatedAt)
                )
            } else {
                cache[key] = nil
            }
            loadedScopes.insert(key)
        }
        return cache[key]
    }

    /// Überschreibt die Zusammenfassung eines Scopes (upsert — kein Verlauf).
    public func save(_ summary: ChatMemorySummary) throws {
        saveState = .saving
        do {
            let key = storageKey(summary.scopeKey)
            let record = ChatMemorySummaryRecord(
                scopeKey: key,
                summaryText: summary.summaryText,
                coveredThroughMessageID: summary.coveredThroughMessageID,
                updatedAt: summary.updatedAt.timeIntervalSince1970
            )
            try db.write { dbConn in
                try record.save(dbConn)
            }
            cache[key] = summary
            loadedScopes.insert(key)
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }
}
