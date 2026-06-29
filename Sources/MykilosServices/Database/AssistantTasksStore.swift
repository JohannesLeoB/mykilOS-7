import Foundation
import GRDB
import MykilosKit

// MARK: - AssistantTaskRecord (GRDB)
struct AssistantTaskRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "assistantTasks" }
    var id: String
    var title: String
    var done: Bool
    var dueDate: Double?    // timeIntervalSince1970, optional
    var projectID: String?
    var createdAt: Double
    var updatedAt: Double

    init(from task: AssistantTask) {
        id = task.id
        title = task.title
        done = task.done
        dueDate = task.dueDate?.timeIntervalSince1970
        projectID = task.projectID
        createdAt = task.createdAt.timeIntervalSince1970
        updatedAt = task.updatedAt.timeIntervalSince1970
    }

    var toDomain: AssistantTask {
        AssistantTask(id: id, title: title, done: done,
                      dueDate: dueDate.map { Date(timeIntervalSince1970: $0) },
                      projectID: projectID,
                      createdAt: Date(timeIntervalSince1970: createdAt),
                      updatedAt: Date(timeIntervalSince1970: updatedAt))
    }
}

// MARK: - AssistantTasksStore (S6)
// Persistente, vom Assistenten verwaltete Aufgaben (Memos/Erinnerungen). Als `actor`
// ausgeführt, damit die Tools sie thread-sicher und ohne MainActor-Bindung aus ihrem
// async `run` aufrufen können. Jeder Schreibvorgang wirft; GRDB serialisiert atomar.
// Bewusst NUR lokale, nutzer-eigene Daten — kein externer Schreibzugriff.
public actor AssistantTasksStore {
    private let db: GRDBDatabase

    public init(db: GRDBDatabase) {
        self.db = db
    }

    /// Alle Aufgaben: offene zuerst (nach Fälligkeit/Anlage), erledigte danach.
    public func all() throws -> [AssistantTask] {
        let tasks = try db.read { conn in
            try AssistantTaskRecord
                .order(Column("updatedAt").desc)
                .fetchAll(conn)
        }.map(\.toDomain)
        return tasks.sorted { lhs, rhs in
            if lhs.done != rhs.done { return !lhs.done }              // offene zuerst
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?): return l < r                            // frühere Fälligkeit zuerst
            case (nil, _?):    return false                            // mit Fälligkeit vor ohne
            case (_?, nil):    return true
            case (nil, nil):   return lhs.updatedAt > rhs.updatedAt    // sonst neueste zuerst
            }
        }
    }

    /// Nur offene Aufgaben.
    public func open() throws -> [AssistantTask] {
        try all().filter { !$0.done }
    }

    /// Aufgaben im Projekt-Bereich: ist `projectID` gesetzt, die Aufgaben dieses Projekts
    /// PLUS die globalen (projectID == nil); ist es nil, alle. Gleiche Sortierung wie all().
    public func scoped(to projectID: String?) throws -> [AssistantTask] {
        let tasks = try all()
        guard let projectID, projectID.isEmpty == false else { return tasks }
        return tasks.filter { $0.projectID == projectID || $0.projectID == nil }
    }

    /// Legt eine neue Aufgabe an und gibt sie zurück. `projectID` nil = global.
    @discardableResult
    public func create(_ title: String, dueDate: Date? = nil, projectID: String? = nil, now: Date = Date()) throws -> AssistantTask {
        let task = AssistantTask(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                 dueDate: dueDate, projectID: projectID, createdAt: now, updatedAt: now)
        try db.write { conn in try AssistantTaskRecord(from: task).insert(conn) }
        return task
    }

    /// Markiert eine Aufgabe als erledigt (oder wieder offen). nil, wenn nicht gefunden.
    @discardableResult
    public func setDone(matching query: String, done: Bool = true, now: Date = Date()) throws -> AssistantTask? {
        guard var task = try find(matching: query) else { return nil }
        task.done = done
        task.updatedAt = now
        try db.write { conn in try AssistantTaskRecord(from: task).update(conn) }
        return task
    }

    /// Löscht eine Aufgabe (per ID/ID-Präfix oder Titel-Teilstring). Gibt die gelöschte zurück.
    @discardableResult
    public func delete(matching query: String) throws -> AssistantTask? {
        guard let task = try find(matching: query) else { return nil }
        _ = try db.write { conn in try AssistantTaskRecord.deleteOne(conn, key: task.id) }
        return task
    }

    /// Findet die beste Aufgabe: exakte ID, dann ID-Präfix, dann Titel-Teilstring (offene bevorzugt).
    public func find(matching query: String) throws -> AssistantTask? {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard q.isEmpty == false else { return nil }
        let tasks = try all()
        if let exact = tasks.first(where: { $0.id.lowercased() == q }) { return exact }
        if let prefix = tasks.first(where: { $0.id.lowercased().hasPrefix(q) }) { return prefix }
        return tasks.first(where: { $0.title.lowercased().contains(q) })
    }
}
