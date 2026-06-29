import Foundation
import GRDB
import MykilosKit

// MARK: - AssistantNoteRecord (GRDB)
struct AssistantNoteRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "assistantNotes" }
    var id: String
    var body: String
    var projectID: String?
    var createdAt: Double   // timeIntervalSince1970
    var updatedAt: Double

    init(from note: AssistantNote) {
        id = note.id
        body = note.body
        projectID = note.projectID
        createdAt = note.createdAt.timeIntervalSince1970
        updatedAt = note.updatedAt.timeIntervalSince1970
    }

    var toDomain: AssistantNote {
        AssistantNote(id: id, body: body, projectID: projectID,
                      createdAt: Date(timeIntervalSince1970: createdAt),
                      updatedAt: Date(timeIntervalSince1970: updatedAt))
    }
}

// MARK: - AssistantNotesStore (S4)
// Persistente, vom Assistenten verwaltete Notizen. Als `actor` ausgeführt, damit die
// (read-only-)Tools sie thread-sicher und ohne MainActor-Bindung aus ihrem async
// `run` aufrufen können. Jeder Schreibvorgang wirft; GRDB serialisiert atomar.
// Bewusst NUR lokale, nutzer-eigene Daten — kein externer Schreibzugriff.
public actor AssistantNotesStore {
    private let db: GRDBDatabase

    public init(db: GRDBDatabase) {
        self.db = db
    }

    /// Alle Notizen, neueste zuerst.
    public func all() throws -> [AssistantNote] {
        try db.read { conn in
            try AssistantNoteRecord
                .order(Column("updatedAt").desc)
                .fetchAll(conn)
        }.map(\.toDomain)
    }

    /// Notizen im Projekt-Bereich: ist `projectID` gesetzt, die Notizen dieses Projekts
    /// PLUS die globalen (projectID == nil); ist es nil, alle. Neueste zuerst.
    public func scoped(to projectID: String?) throws -> [AssistantNote] {
        let notes = try all()
        guard let projectID, projectID.isEmpty == false else { return notes }
        return notes.filter { $0.projectID == projectID || $0.projectID == nil }
    }

    /// Legt eine neue Notiz an und gibt sie zurück. `projectID` nil = global.
    @discardableResult
    public func create(_ body: String, projectID: String? = nil, now: Date = Date()) throws -> AssistantNote {
        let note = AssistantNote(body: body.trimmingCharacters(in: .whitespacesAndNewlines),
                                 projectID: projectID, createdAt: now, updatedAt: now)
        try db.write { conn in try AssistantNoteRecord(from: note).insert(conn) }
        return note
    }

    /// Ersetzt den Text einer Notiz (per ID oder ID-Präfix). nil, wenn nicht gefunden.
    @discardableResult
    public func update(matching query: String, newBody: String, now: Date = Date()) throws -> AssistantNote? {
        guard var note = try find(matching: query) else { return nil }
        note.body = newBody.trimmingCharacters(in: .whitespacesAndNewlines)
        note.updatedAt = now
        try db.write { conn in try AssistantNoteRecord(from: note).update(conn) }
        return note
    }

    /// Löscht eine Notiz (per ID/ID-Präfix oder Text-Teilstring). Gibt die gelöschte zurück.
    @discardableResult
    public func delete(matching query: String) throws -> AssistantNote? {
        guard let note = try find(matching: query) else { return nil }
        _ = try db.write { conn in try AssistantNoteRecord.deleteOne(conn, key: note.id) }
        return note
    }

    /// Findet die beste Notiz für eine Anfrage: exakte ID, dann ID-Präfix, dann Text-Teilstring.
    public func find(matching query: String) throws -> AssistantNote? {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard q.isEmpty == false else { return nil }
        let notes = try all()
        if let exact = notes.first(where: { $0.id.lowercased() == q }) { return exact }
        if let prefix = notes.first(where: { $0.id.lowercased().hasPrefix(q) }) { return prefix }
        return notes.first(where: { $0.body.lowercased().contains(q) })
    }
}
