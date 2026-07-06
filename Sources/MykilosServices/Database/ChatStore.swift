import Foundation
import Observation
import GRDB
import MykilosKit

// MARK: - ChatStoreError
public enum ChatStoreError: Error, Equatable {
    case corruptRecord(String)
}

// MARK: - ChatStore
// @Observable, @MainActor, GRDB-backed. EINE globale Instanz; der Scope ist
// Parameter (so überlebt jeder Thread die Navigation, ohne pro View neu zu
// entstehen). Jeder Schreibvorgang `throws`, SaveState ist in der UI sichtbar.
// V1: ein Thread je Scope (home + je Projektnummer); Multi-Thread kommt als
// spätere Migration.
@MainActor
@Observable
public final class ChatStore {
    public private(set) var saveState: SaveState = .idle

    private let db: GRDBDatabase
    // Multi-User: der aktive Bewohner. Alle Reads/Writes sind auf ihn gefiltert,
    // damit auf einem geteilten Mac kein Bewohner die (privaten) Chats eines
    // anderen sieht. Neustart-basiert: der Store wird beim Bewohner-Wechsel neu
    // gebaut (AppState.init), daher ist auch der In-Memory-Cache byScope implizit
    // je userID frisch — kein Cross-User-Cache-Leak.
    private let userID: String?
    // Geladene Slices je Scope (rawKey → Nachrichten in Sequenz-Reihenfolge).
    private var byScope: [String: [ChatMessage]] = [:]
    private var loadedScopes: Set<String> = []

    public init(db: GRDBDatabase, userID: String? = CurrentUserContext.current) {
        self.db = db
        self.userID = userID
    }

    // MARK: Lesen
    public func messages(for scope: ChatScope) -> [ChatMessage] {
        byScope[scope.rawKey] ?? []
    }

    /// Lädt den Verlauf eines Scopes EINMAL aus der DB (idempotent).
    public func loadIfNeeded(_ scope: ChatScope) throws {
        let key = scope.rawKey
        guard loadedScopes.contains(key) == false else { return }
        let records = try db.read { dbConn in
            try ChatMessageRecord
                .filter(ChatMessageRecord.Columns.threadScopeKey == key)
                .filter(ChatMessageRecord.Columns.userID == userID)
                .order(ChatMessageRecord.Columns.sequence)
                .fetchAll(dbConn)
        }
        // Ausfallsicher mappen: ein einzelner undekodierbarer Block darf nie das
        // ganze Archiv eines Scopes verschlucken (siehe toDomainResilient).
        byScope[key] = records.map { $0.toDomainResilient() }
        loadedScopes.insert(key)
    }

    // MARK: Schreiben — Der Vertrag (throws, SaveState sichtbar)
    /// Hängt eine Nachricht ans Ende des Scope-Threads an.
    public func append(_ message: ChatMessage, to scope: ChatScope) throws {
        try loadIfNeeded(scope)
        let key = scope.rawKey
        var list = byScope[key] ?? []
        let sequence = list.count   // append-only → count ist die nächste Sequenz
        saveState = .saving
        do {
            let record = try ChatMessageRecord(from: message, scopeKey: key, sequence: sequence, userID: userID)
            try db.write { dbConn in
                try record.insert(dbConn)
            }
            list.append(message)
            byScope[key] = list
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }

    /// Aktualisiert den Text eines Assistenten-Turns OHNE DB-Write (Streaming-Delta).
    /// @Observable löst den UI-Update aus; updateAssistantTurn schreibt am Ende in die DB.
    public func updateStreamingText(id: UUID, text: String, in scope: ChatScope) {
        let key = scope.rawKey
        guard var list = byScope[key],
              let index = list.firstIndex(where: { $0.id == id }) else { return }
        var updated = list[index]
        var blocks = updated.blocks
        if let ti = blocks.firstIndex(where: { if case .text = $0 { true } else { false } }) {
            blocks[ti] = .text(text)
        } else {
            blocks.insert(.text(text), at: 0)
        }
        updated.blocks = blocks
        list[index] = updated
        byScope[key] = list
    }

    /// Aktualisiert einen bestehenden Assistenten-Turn (Streaming-Abschluss).
    public func updateAssistantTurn(
        id: UUID,
        blocks: [ChatContentBlock],
        status: ChatTurnStatus,
        in scope: ChatScope
    ) throws {
        let key = scope.rawKey
        guard var list = byScope[key], let index = list.firstIndex(where: { $0.id == id }) else { return }
        var updated = list[index]
        updated.blocks = blocks
        updated.status = status
        saveState = .saving
        do {
            // index == gespeicherte Sequenz (append-only, in Reihenfolge geladen).
            let record = try ChatMessageRecord(from: updated, scopeKey: key, sequence: index, userID: userID)
            try db.write { dbConn in
                try record.update(dbConn)
            }
            list[index] = updated
            byScope[key] = list
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }

    /// Löscht den gesamten Verlauf eines Scopes.
    public func clear(_ scope: ChatScope) throws {
        let key = scope.rawKey
        saveState = .saving
        do {
            try db.write { dbConn in
                try ChatMessageRecord
                    .filter(ChatMessageRecord.Columns.threadScopeKey == key)
                    .filter(ChatMessageRecord.Columns.userID == userID)
                    .deleteAll(dbConn)
            }
            byScope[key] = []
            loadedScopes.insert(key)
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }
}
