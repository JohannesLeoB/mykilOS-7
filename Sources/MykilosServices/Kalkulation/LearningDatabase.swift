import Foundation
import GRDB

// MARK: - LearningDatabase
// Die produktive append-only Working-Copy-Datenbank für Learning & Review.
// Eine SQLite-Datei in der Working Copy (Application Support), eine serialisierte
// Queue — alle Schreibvorgänge laufen atomar und serialisiert durch sie. Das ist
// der "actor-isolierte Writer": GRDBs DatabaseQueue serialisiert jeden write{}.
//
// Muster bewusst an mykilOS 6 (MykilosServices/GRDBDatabase) angelehnt:
// WAL, foreign_keys ON, DatabaseMigrator mit ausschließlich additiven Stufen.
//
// No-delete: Es gibt keine Delete-/Update-API. Statusänderungen sind neue Zeilen
// (append-only); "aktuell" = höchste pk je record_id. Der Bundle-Seed wird hier
// nie berührt — diese DB hält nur Nutzer-Writes.
public final class LearningDatabase: Sendable {
    /// Aktuelle Schemaversion (entspricht der höchsten registrierten Migration).
    public static let schemaVersion = 4

    private let queue: DatabaseQueue

    /// Pfad der DB-Datei (leer bei In-Memory).
    public let fileURL: URL?

    // MARK: Lifecycle

    /// Öffnet (oder erzeugt) die Working-Copy-DB an `url`, sichert vor einer
    /// ausstehenden Migration und wendet dann additive Migrationen an.
    public init(url: URL) throws {
        self.fileURL = url
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        var config = Configuration()
        config.label = "mykilo-learning"
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
        let queue = try DatabaseQueue(path: url.path, configuration: config)
        self.queue = queue

        // Backup vor jeder Migration: wenn die Datei bereits Nutzerdaten trägt und
        // noch Migrationen ausstehen, zuerst eine unveränderte Kopie ablegen.
        try Self.backupBeforePendingMigration(queue: queue, fileURL: url)
        try Self.makeMigrator().migrate(queue)
        try recordMetadata()
    }

    /// In-Memory-DB für Tests — kein Disk-I/O, isoliert.
    public static func inMemory() throws -> LearningDatabase {
        try LearningDatabase(inMemoryQueue: DatabaseQueue())
    }

    private init(inMemoryQueue: DatabaseQueue) throws {
        self.fileURL = nil
        self.queue = inMemoryQueue
        try Self.makeMigrator().migrate(inMemoryQueue)
        try recordMetadata()
    }

    // MARK: Öffentliche Lese-/Schreib-API (serialisiert)

    public func read<T>(_ block: (Database) throws -> T) throws -> T {
        try queue.read(block)
    }

    @discardableResult
    public func write<T>(_ block: (Database) throws -> T) throws -> T {
        try queue.write(block)
    }

    // MARK: Migrationen (niemals ändern, nur anhängen)

    private static func makeMigrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()

        // v1 — Learning- und Review-Tabellen (die sieben Learning-Tabellen,
        // review_actions, Audit, plus Metadaten und Importprotokoll).
        migrator.registerMigration("v1_learning_review") { db in
            try db.create(table: "estimate_sessions") { t in
                t.autoIncrementedPrimaryKey("pk")
                t.column("recordID", .text).notNull().indexed()
                t.column("createdAt", .text).notNull()
                t.column("requestText", .text).notNull()
                t.column("baseLowNet", .text).notNull()
                t.column("baseMidNet", .text).notNull()
                t.column("baseHighNet", .text).notNull()
                t.column("laborValueNet", .text).notNull()
                t.column("evidenceIDs", .text).notNull()
                t.column("status", .text).notNull()
            }
            try db.create(table: "estimate_session_components") { t in
                t.autoIncrementedPrimaryKey("pk")
                t.column("recordID", .text).notNull().indexed()
                t.column("sessionID", .text).notNull().indexed()
                t.column("componentIndex", .integer).notNull()
                t.column("componentClass", .text).notNull()
                t.column("componentType", .text).notNull()
                t.column("adjustmentTarget", .text).notNull()
                t.column("baseLowNet", .text).notNull()
                t.column("baseMidNet", .text).notNull()
                t.column("baseHighNet", .text).notNull()
                t.column("evidenceIDs", .text).notNull()
            }
            try db.create(table: "estimate_adjustments") { t in
                t.autoIncrementedPrimaryKey("pk")
                t.column("recordID", .text).notNull().indexed()
                t.column("sessionID", .text).notNull().indexed()
                t.column("createdAt", .text).notNull()
                t.column("percentDelta", .double).notNull()
                t.column("euroDelta", .text)
                t.column("adjustedMidNet", .text).notNull()
                t.column("reason", .text).notNull()
                t.column("target", .text).notNull()
                t.column("status", .text).notNull()
                t.column("note", .text).notNull()
            }
            try db.create(table: "estimate_adjustment_component_targets") { t in
                t.autoIncrementedPrimaryKey("pk")
                t.column("recordID", .text).notNull().indexed()
                t.column("adjustmentID", .text).notNull().indexed()
                t.column("sessionComponentID", .text)
                t.column("target", .text).notNull()
                t.column("percentDelta", .double).notNull()
                t.column("status", .text).notNull()
            }
            try db.create(table: "calibration_factor_candidates") { t in
                t.autoIncrementedPrimaryKey("pk")
                t.column("recordID", .text).notNull().indexed()
                t.column("createdAt", .text).notNull()
                t.column("reason", .text).notNull()
                t.column("target", .text).notNull()
                t.column("sampleCount", .integer).notNull()
                t.column("weightedPercentDelta", .double).notNull()
                t.column("multiplier", .text).notNull()
                t.column("adjustmentIDs", .text).notNull()
                t.column("status", .text).notNull()
                t.column("note", .text).notNull()
            }
            try db.create(table: "active_calibration_factors") { t in
                t.autoIncrementedPrimaryKey("pk")
                t.column("recordID", .text).notNull().indexed()
                t.column("candidateID", .text).notNull()
                t.column("createdAt", .text).notNull()
                t.column("reason", .text).notNull()
                t.column("target", .text).notNull()
                t.column("multiplier", .text).notNull()
                t.column("weightedPercentDelta", .double).notNull()
                t.column("sampleCount", .integer).notNull()
                t.column("status", .text).notNull()
            }
            try db.create(table: "learning_audit_log") { t in
                t.autoIncrementedPrimaryKey("pk")
                t.column("recordID", .text).notNull()
                t.column("createdAt", .text).notNull()
                t.column("entityID", .text).notNull().indexed()
                t.column("entityTable", .text).notNull()
                t.column("action", .text).notNull()
                t.column("message", .text).notNull()
            }
            try db.create(table: "review_actions") { t in
                t.autoIncrementedPrimaryKey("pk")
                t.column("recordID", .text).notNull()
                t.column("createdAt", .text).notNull()
                t.column("candidateID", .text).notNull().indexed()
                t.column("kind", .text).notNull()
                t.column("note", .text).notNull()
                t.column("correctedPrice", .text)
                t.column("supersededBy", .text)
            }
            // Metadaten: Schema- und Seed-Version, Erstellungszeit.
            try db.create(table: "learning_metadata") { t in
                t.primaryKey("key", .text)
                t.column("value", .text).notNull()
            }
            // Importprotokoll: macht den JSONL-Import idempotent.
            try db.create(table: "learning_import_log") { t in
                t.autoIncrementedPrimaryKey("pk")
                t.column("sourceFile", .text).notNull()
                t.column("fingerprint", .text).notNull().unique()
                t.column("recordCount", .integer).notNull()
                t.column("importedAt", .text).notNull()
            }
        }

        // v2 — Dokument-Import (Akt 4D): append-only Protokoll jedes Importversuchs.
        // Niemals automatische Preiswahrheit — nur Dedup, Archiv und Kandidaten-Shell.
        migrator.registerMigration("v2_document_imports") { db in
            try db.create(table: "document_imports") { t in
                t.autoIncrementedPrimaryKey("pk")
                t.column("recordID", .text).notNull()
                t.column("fileName", .text).notNull()
                t.column("sha256", .text).notNull().indexed()
                t.column("sizeBytes", .integer).notNull()
                t.column("isDuplicate", .boolean).notNull()
                t.column("duplicateOf", .text)
                t.column("archivedPath", .text)
                t.column("importedAt", .text).notNull()
                t.column("note", .text).notNull()
            }
        }

        // v3 — Airtable Angebote Registry (Akt 4E): append-only Sync-Log für eingehende
        // und ausgehende Angebote. Jeder Record hält den Airtable-Primärschlüssel (UNIQUE),
        // den Lernwert und einen optionalen FK zur review_actions-Tabelle.
        // No-delete: syncStatus-Änderungen werden als neue Zeile geschrieben.
        migrator.registerMigration("v3_airtable_offer_sync") { db in
            try db.create(table: "airtable_offer_sync") { t in
                t.autoIncrementedPrimaryKey("pk")
                t.column("recordID", .text).notNull()
                t.column("airtableRecordID", .text).notNull().unique()
                t.column("offerKind", .text).notNull()      // eingehend | ausgehend
                t.column("nettoEur", .text).notNull()        // Decimal als TEXT
                t.column("offerStatus", .text).notNull()
                t.column("partner", .text).notNull()
                t.column("docSHA256", .text)                 // NULL wenn kein PDF geladen
                t.column("importedAt", .text).notNull()
                t.column("reviewActionID", .text)            // FK → review_actions.recordID
                t.column("syncStatus", .text).notNull().defaults(to: "imported")
            }
        }

        // v4 — Angebots-Datum am Sync-Record (feat/tischler-predictor, Phase 1).
        // Trägt das ORIGINAL-Angebotsdatum mit, damit der LearnedAnchorProvider den
        // Preis inflationssicher auf Gegenwartswert hebt (Zeitgewichtung gegen die
        // Teuerung 2021–23). `importedAt` allein genügt nicht — das ist der Sync-,
        // nicht der Angebotszeitpunkt. Additiv, nullable (Altbestand bleibt gültig).
        migrator.registerMigration("v4_offer_date") { db in
            try db.alter(table: "airtable_offer_sync") { t in
                t.add(column: "offerDate", .text)   // ISO/Freitext-Datum aus Airtable, NULL erlaubt
            }
        }

        return migrator
    }

    /// Liste der angewandten Migrationen (zur Sichtbarkeit / Diagnose).
    public func appliedMigrations() throws -> [String] {
        try read { db in Array(try Self.makeMigrator().appliedMigrations(db)) }
    }

    private func recordMetadata() throws {
        try write { db in
            try db.execute(
                sql: "INSERT OR IGNORE INTO learning_metadata(key, value) VALUES (?, ?)",
                arguments: ["created_at", LearningCodec.string(from: Date())]
            )
            try db.execute(
                sql: "INSERT OR REPLACE INTO learning_metadata(key, value) VALUES (?, ?)",
                arguments: ["schema_version", String(Self.schemaVersion)]
            )
        }
    }

    public func metadata(_ key: String) throws -> String? {
        try read { db in
            try String.fetchOne(db, sql: "SELECT value FROM learning_metadata WHERE key = ?", arguments: [key])
        }
    }

    public func setMetadata(_ key: String, _ value: String) throws {
        try write { db in
            try db.execute(
                sql: "INSERT OR REPLACE INTO learning_metadata(key, value) VALUES (?, ?)",
                arguments: [key, value]
            )
        }
    }

    // MARK: Backup & Recovery

    /// Online-Backup der gesamten DB an `destination` (verlustfrei, konsistent).
    public func backup(to destination: URL) throws {
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let target = try DatabaseQueue(path: destination.path)
        try queue.backup(to: target)
    }

    /// SQLite-Integritätsprüfung. `true` = "ok".
    public func integrityCheckPassed() throws -> Bool {
        try read { db in
            let result = try String.fetchOne(db, sql: "PRAGMA integrity_check")
            return result == "ok"
        }
    }

    /// Ob eine Tabelle existiert (für Schema-Tests, ohne GRDB im Testtarget zu importieren).
    public func tableExists(_ name: String) throws -> Bool {
        try read { try $0.tableExists(name) }
    }

    private static func backupBeforePendingMigration(queue: DatabaseQueue, fileURL: URL) throws {
        // Nur sichern, wenn die Datei bereits ein Schema trägt UND noch Migrationen
        // ausstehen — also eine Migration auf vorhandene Nutzerdaten läuft.
        let hasSchema = try queue.read { db in
            try db.tableExists("learning_metadata")
        }
        guard hasSchema else { return }
        let migrator = makeMigrator()
        let pending = try queue.read { db in
            try migrator.hasCompletedMigrations(db) == false
        }
        guard pending else { return }

        try queue.writeWithoutTransaction { db in
            try db.execute(sql: "PRAGMA wal_checkpoint(TRUNCATE)")
        }
        let backupDir = fileURL.deletingLastPathComponent().appendingPathComponent("Backups", isDirectory: true)
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        let stamp = LearningCodec.fileStamp(from: Date())
        let backupURL = backupDir.appendingPathComponent("learning-premigration-\(stamp).sqlite")
        if !FileManager.default.fileExists(atPath: backupURL.path) {
            let target = try DatabaseQueue(path: backupURL.path)
            try queue.backup(to: target)
        }
    }
}
