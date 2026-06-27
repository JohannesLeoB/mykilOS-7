import Foundation
import GRDB
import MykilosKit

// MARK: - GRDBDatabase
// Die eine Datenbank. Eine Datei in Application Support. Eine Queue.
// Alle Schreibvorgänge gehen durch sie — atomic, serialisiert, sicher.
//
// Wachstumspfad: neue Migrations-Stufen einfach anhängen (niemals bestehende ändern).
public final class GRDBDatabase: Sendable {
    private let queue: DatabaseQueue

    public init(url: URL) throws {
        var config = Configuration()
        config.label = "mykilOS6"
        config.prepareDatabase { db in
            // WAL-Mode: Reads blockieren Writes nicht — performant für unsere Nutzung
            try db.execute(sql: "PRAGMA journal_mode = WAL")
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
        queue = try DatabaseQueue(path: url.path, configuration: config)
        try runMigrations()
    }

    // In-Memory für Tests — kein Disk-I/O, schnell, isoliert
    public static func inMemory() throws -> GRDBDatabase {
        let db = GRDBDatabase.__inMemory()
        return db
    }

    // MARK: - Öffentliche Lese-/Schreib-API
    public func read<T: Sendable>(_ block: @Sendable (Database) throws -> T) throws -> T {
        try queue.read(block)
    }

    @discardableResult
    public func write<T: Sendable>(_ block: @Sendable (Database) throws -> T) throws -> T {
        try queue.write(block)
    }

    // MARK: - Migrations (niemals ändern, nur anhängen)
    private func runMigrations() throws {
        var migrator = DatabaseMigrator()

        // v1 — Widget-Boards + Notes
        migrator.registerMigration("v1_widgets_notes") { db in
            // Widget-Instances persistiert nach BoardID
            try db.create(table: "widgetInstances") { t in
                t.primaryKey("id", .text)
                t.column("boardID",   .text).notNull().indexed()
                t.column("kind",      .text).notNull()
                t.column("size",      .text).notNull()
                t.column("position",  .integer).notNull()
                t.column("isVisible", .boolean).notNull().defaults(to: true)
                t.column("isPinned",  .boolean).notNull().defaults(to: false)
            }
            // Notizen je Board/Projekt
            try db.create(table: "notes") { t in
                t.primaryKey("id", .text)
                t.column("boardID",   .text).notNull().indexed()
                t.column("body",      .text).notNull()
                t.column("updatedAt", .double).notNull()
            }
            // Audit-Einträge (Modell aus Akt 1 jetzt in DB)
            try db.create(table: "auditEntries") { t in
                t.primaryKey("id", .text)
                t.column("timestamp",   .double).notNull()
                t.column("actorUserID", .text).notNull()
                t.column("projectID",   .text).notNull().indexed()
                t.column("action",      .text).notNull()
                t.column("summary",     .text).notNull()
            }
        }

        // v2 — Projekte + Kunden aus Airtable-Cache in DB (Akt 3)
        // migrator.registerMigration("v2_projects_customers") { db in ... }

        // v2_chat — Assistenten-Chat-Verlauf (Phase 0). Ein Thread je Scope
        // (home + je Projektnummer), Nachrichten als JSON-BLOB (blocks/status).
        migrator.registerMigration("v2_chat") { db in
            try db.create(table: "chatMessages") { t in
                t.primaryKey("id", .text)
                t.column("threadScopeKey", .text).notNull().indexed()
                t.column("role",       .text).notNull()
                t.column("blocksJSON",  .blob).notNull()
                t.column("statusJSON",  .blob).notNull()
                t.column("sequence",    .integer).notNull()
                t.column("createdAt",   .double).notNull()
            }
        }

        // v3_profile — lokales Nutzerprofil (Onboarding). Single-Row id="local".
        migrator.registerMigration("v3_profile") { db in
            try db.create(table: "userProfile") { t in
                t.primaryKey("id", .text)
                t.column("displayName", .text).notNull()
                t.column("role",        .text).notNull()
                t.column("updatedAt",   .double).notNull()
            }
        }

        try migrator.migrate(queue)
    }

    // Interner init für Tests (ohne Migrations-Fehler)
    private init(queue: DatabaseQueue) { self.queue = queue }

    private static func __inMemory() -> GRDBDatabase {
        let db = GRDBDatabase(queue: try! DatabaseQueue())
        try! db.runMigrations()
        return db
    }
}
