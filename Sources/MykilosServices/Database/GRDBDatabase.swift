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

    // In-Memory für Tests — kein Disk-I/O, schnell, isoliert.
    // Kein try! mehr (Mandate F): Fehler propagieren regulär.
    public static func inMemory() throws -> GRDBDatabase {
        let db = GRDBDatabase(queue: try DatabaseQueue())
        try db.runMigrations()
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

    /// WAL-Checkpoint: schreibt alle ausstehenden WAL-Transaktionen in die Hauptdatei.
    /// Muss vor einem konsistenten Backup aufgerufen werden.
    /// Nach dem Checkpoint ist db.sqlite allein ein gültiges Backup (db.sqlite-wal ist leer/klein).
    public func checkpoint() throws {
        try queue.write { db in
            try db.execute(sql: "PRAGMA wal_checkpoint(TRUNCATE)")
        }
    }

    /// Gibt den Dateipfad der Hauptdatenbank zurück (für Backup-Service).
    public var dbPath: String { queue.path }

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

        // v4_reconciled_boards — merkt sich je boardID, ob der einmalige
        // canonicalLayout-Reconcile bereits gelaufen ist. Danach respektiert
        // der Store User-Entscheidungen (Widget entfernen bleibt permanent).
        migrator.registerMigration("v4_reconciled_boards") { db in
            try db.create(table: "reconciledBoards") { t in
                t.primaryKey("boardID", .text)
            }
        }

        // v5_profile_identity — nutzer-spezifische Identitätsfelder (Private Area).
        // Nullable ALTER COLUMNs: bestehende Zeilen bekommen NULL — kein Datenverlust.
        migrator.registerMigration("v5_profile_identity") { db in
            try db.alter(table: "userProfile") { t in
                t.add(column: "clockodoUserID", .text)
                t.add(column: "googleDomain",   .text)
            }
        }

        // v6_dataflow_log — Schaltzentrum-Logbuch. Jeder externe Datensync
        // schreibt hier einen Handshake (lokale Wahrheit; Airtable spiegelt nicht-fatal).
        migrator.registerMigration("v6_dataflow_log") { db in
            try db.create(table: "dataFlowLog") { t in
                t.primaryKey("id", .text)
                t.column("timestamp",      .double).notNull().indexed()
                t.column("integrationID",  .text).notNull().indexed()
                t.column("actorUserID",    .text).notNull()
                t.column("action",         .text).notNull()
                t.column("recordsRead",    .integer).notNull().defaults(to: 0)
                t.column("recordsWritten", .integer).notNull().defaults(to: 0)
                t.column("httpStatus",     .integer)
                t.column("errorMessage",   .text)
                t.column("durationMs",     .integer).notNull().defaults(to: 0)
                t.column("summary",        .text).notNull()
            }
        }

        // v7_project_favorites (L25) — angepinnte Projekte. Schlüssel = projectNumber
        // (Business-Schlüssel, kein UUID), damit Favoriten Airtable-Re-Syncs überleben.
        migrator.registerMigration("v7_project_favorites") { db in
            try db.create(table: "projectFavorites") { t in
                t.primaryKey("projectNumber", .text)
                t.column("addedAt", .double).notNull()
            }
        }

        // v8_assistant_notes (S4) — vom Assistenten verwaltete Notizen/Erinnerungen.
        migrator.registerMigration("v8_assistant_notes") { db in
            try db.create(table: "assistantNotes") { t in
                t.primaryKey("id", .text)
                t.column("body",      .text).notNull()
                t.column("createdAt", .double).notNull()
                t.column("updatedAt", .double).notNull().indexed()
            }
        }

        // v9_assistant_tasks (S6) — vom Assistenten verwaltete Aufgaben (Memos/Erinnerungen).
        migrator.registerMigration("v9_assistant_tasks") { db in
            try db.create(table: "assistantTasks") { t in
                t.primaryKey("id", .text)
                t.column("title",     .text).notNull()
                t.column("done",      .boolean).notNull().defaults(to: false)
                t.column("dueDate",   .double)            // optional
                t.column("createdAt", .double).notNull()
                t.column("updatedAt", .double).notNull().indexed()
            }
        }

        // v10_assistant_project_scope — Notizen/Aufgaben pro Projekt (Memo-Wunsch).
        // projectID = Projektnummer (z. B. „2026-015"); NULL = projektübergreifend/global.
        // Additiv: bestehende Einträge bleiben global (NULL), kein Datenverlust.
        migrator.registerMigration("v10_assistant_project_scope") { db in
            try db.alter(table: "assistantNotes") { t in
                t.add(column: "projectID", .text).indexed()
            }
            try db.alter(table: "assistantTasks") { t in
                t.add(column: "projectID", .text).indexed()
            }
        }

        // v11_assistant_note_color (S20) — optionaler Farb-Schlüssel je Notiz (Zettel-Wand).
        // Additiv: bestehende Notizen bleiben ohne Farbe (NULL → Auto-Farbe).
        migrator.registerMigration("v11_assistant_note_color") { db in
            try db.alter(table: "assistantNotes") { t in
                t.add(column: "color", .text)
            }
        }

        try migrator.migrate(queue)
    }

    // Interner init für Tests (ohne Migrations-Fehler)
    private init(queue: DatabaseQueue) { self.queue = queue }
}
