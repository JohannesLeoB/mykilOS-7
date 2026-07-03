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
        try Self.buildMigrator().migrate(queue)
    }

    /// Baut den vollständigen Migrator (v1…aktuell). `internal` statt `private`, damit
    /// Cold-Start-Tests (`@testable import MykilosServices`) eine ALTE Bestands-DB
    /// simulieren können: Migrator bis zu einer älteren Version laufen lassen
    /// (`migrator.migrate(queue, upTo:)`), Testdaten schreiben, dann eine echte
    /// `GRDBDatabase(url:)` auf derselben Datei öffnen — beweist, dass neue Migrationen
    /// gegen Bestandsdaten laufen (Wirbelsäule, Welle C, Block C — v21_workbasket-Gate).
    /// Reine Konstruktion, kein Seiteneffekt — sicher mehrfach aufrufbar.
    static func buildMigrator() -> DatabaseMigrator {
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

        // v12_write_shadow_log (mykilOS 8, Block A) — lokale, unverlierbare Kopie
        // JEDES externen Schreibvorgangs (Airtable/Drive/künftig Clockodo/ClickUp).
        // Gespiegelt nach Airtable-Base `mykilOS-Backup` (append-only, sobald angelegt) —
        // lokal ist die Tabelle hier IMMER die Wahrheit, der Airtable-Spiegel ist Komfort.
        // Gleiches Muster wie `dataFlowLog` (lokal zuerst, nicht-fataler externer Spiegel).
        migrator.registerMigration("v12_write_shadow_log") { db in
            try db.create(table: "writeShadowLog") { t in
                t.primaryKey("id", .text)
                t.column("timestamp",        .double).notNull().indexed()
                t.column("actorUserID",      .text).notNull()
                t.column("action",           .text).notNull()       // create/update
                t.column("targetSystem",     .text).notNull()       // airtable/drive/clockodo/clickup
                t.column("targetBase",       .text)
                t.column("targetTable",      .text)
                t.column("targetRecordID",   .text)
                t.column("payloadJSON",      .text).notNull()
                t.column("previousValueJSON", .text)
                t.column("mode",             .text).notNull()       // test/prod
                t.column("result",           .text).notNull()       // ok/error
                t.column("errorMessage",     .text)
                t.column("mirroredToBackupBase", .boolean).notNull().defaults(to: false)
            }
        }

        // v13_app_settings (mykilOS 8, Block A) — generische Key-Value-Tabelle für
        // App-weite Schalter. Erster Nutzer: `provisioningMode` (.test/.prod, Default
        // .test). Additiv, kein bestehender Code betroffen.
        migrator.registerMigration("v13_app_settings") { db in
            try db.create(table: "appSettings") { t in
                t.primaryKey("key", .text)
                t.column("value", .text).notNull()
                t.column("updatedAt", .double).notNull()
            }
        }

        // v14_project_number_bindings (mykilOS 8, Block A, Johannes-Entscheidung
        // 2026-06-30) — REIN LOKALE, redundante Brücke: solange Artikel-`Projekte` kein
        // `Projektnummer`-Feld hat, bindet diese Tabelle ein Geschäftsprojekt
        // (businessRecordID) an eine Projektnummer — NUR nach manueller Bestätigung
        // (Karte→Bestätigung→Audit). Rührt die Artikel-Base selbst nie an.
        migrator.registerMigration("v14_project_number_bindings") { db in
            try db.create(table: "projectNumberBindings") { t in
                t.primaryKey("businessRecordID", .text)
                t.column("projectNumber", .text).notNull().indexed()
                t.column("confirmedAt", .double).notNull()
                t.column("actorUserID", .text).notNull()
            }
        }

        // v15_time_tracking (mykilOS 8, Block B / S1) — lokales Zeit-Subsystem.
        // Drei Tabellen, alle rein lokal, kein externer Write:
        //   activeTimer        — Single-Row (id="singleton"), der EINE laufende Timer.
        //   timeSegmentDrafts  — abgeschlossene, noch nicht gebuchte Abschnitte des
        //                        aktuellen Laufs (Kostenstellen-/Projektwechsel + letzter
        //                        Abschnitt beim Stopp). Erst die Doppelbestätigung bucht sie.
        //   timeSegments       — gebuchte Abschnitte (append-only, echtes Buchungsergebnis).
        //   projectZielkontingente — Soll-Stunden je Projekt (Feldgerüst, S2 befüllt auto).
        migrator.registerMigration("v15_time_tracking") { db in
            try db.create(table: "activeTimer") { t in
                t.primaryKey("id", .text)                 // immer "singleton"
                t.column("projektNummer", .text).notNull()
                t.column("projektTitel",  .text).notNull()
                t.column("kostenstelle",  .text).notNull()
                t.column("runSince",      .double).notNull()
                t.column("pausedAccumulatedSeconds", .double).notNull().defaults(to: 0)
                t.column("isPaused",      .boolean).notNull().defaults(to: false)
                t.column("segmentStartedAt", .double).notNull()
            }
            try db.create(table: "timeSegmentDrafts") { t in
                t.primaryKey("id", .text)
                t.column("projektNummer", .text).notNull().indexed()
                t.column("projektTitel",  .text).notNull()
                t.column("kostenstelle",  .text).notNull()
                t.column("startedAt",     .double).notNull()
                t.column("endedAt",       .double).notNull()
                t.column("seconds",       .double).notNull()
            }
            try db.create(table: "timeSegments") { t in
                t.primaryKey("id", .text)
                t.column("projektNummer", .text).notNull().indexed()
                t.column("projektTitel",  .text).notNull()
                t.column("kostenstelle",  .text).notNull()
                t.column("startedAt",     .double).notNull()
                t.column("endedAt",       .double).notNull()
                t.column("seconds",       .double).notNull()
                t.column("bookedAt",      .double).notNull().indexed()
            }
            try db.create(table: "projectZielkontingente") { t in
                t.primaryKey("projektNummer", .text)
                t.column("zielStunden", .double).notNull()
                t.column("herkunft",    .text).notNull()
                t.column("updatedAt",   .double).notNull()
            }
        }

        // v16_nomenklatur (mykilOS 8, Block C / S2) — Identität + Nomenklatur, rein lokal.
        //   vergebeneNummern   — Nummern-Register der NumberAuthority (archiviert/reserviert/
        //                        extern gebunden). Aktive Nummern kommen live aus der Registry;
        //                        dieses Register hält, was NICHT mehr aktiv, aber nie wieder
        //                        vergebbar ist (Archiv) + Reservierungen. status: aktiv/archiviert/reserviert/extern.
        //   nomenklaturConfig  — Key-Value (aktive Schema-Version, NumberAuthorityMode).
        //   ordnerKonnektoren  — Slot → aktueller Ordnername (Re-Wiring ohne Code).
        //   projektKostenstellen — lokale Kostenstellen-Overrides je Projekt (bis Airtable-Feld).
        migrator.registerMigration("v16_nomenklatur") { db in
            try db.create(table: "vergebeneNummern") { t in
                t.primaryKey("appFormat", .text)            // "2026-030"
                t.column("jahr",           .integer).notNull().indexed()
                t.column("laufendeNummer", .integer).notNull()
                t.column("status",         .text).notNull()  // archiviert/reserviert/extern
                t.column("quelle",         .text)            // bei extern: woher
                t.column("updatedAt",      .double).notNull()
            }
            try db.create(table: "nomenklaturConfig") { t in
                t.primaryKey("key", .text)
                t.column("value", .text).notNull()
                t.column("updatedAt", .double).notNull()
            }
            try db.create(table: "ordnerKonnektoren") { t in
                t.primaryKey("slot", .text)
                t.column("ordnername",    .text).notNull()
                t.column("relativerPfad", .text).notNull()
                t.column("schemaVersion", .integer).notNull()
                t.column("updatedAt",     .double).notNull()
            }
            try db.create(table: "projektKostenstellen") { t in
                t.primaryKey("projektNummer", .text)
                t.column("namenJSON", .text).notNull()       // ["Planung","Beratung",…]
                t.column("updatedAt", .double).notNull()
            }
        }

        // v17_provisioning (mykilOS 8, Block D / S4) — der Idempotenz-/Wiederaufnahme-Ledger
        // der Projekt-Geburt. Schlüssel = Kdnr + Projektnummer. Hält die echten erzeugten IDs
        // (Drive-Ordner, Airtable-Record) + erledigte Schritte → ein zweiter Lauf dupliziert
        // nichts, ein Teilfehler ist sauber wiederaufnehmbar. clickUpRouting = Adapter-Gerüst (§9).
        migrator.registerMigration("v17_provisioning") { db in
            try db.create(table: "provisioningLedger") { t in
                t.primaryKey("idempotenzSchluessel", .text)
                t.column("projektnummer",        .text).notNull().indexed()
                t.column("kdnr",                 .text).notNull().indexed()
                t.column("status",               .text).notNull()
                t.column("erledigteSchritteJSON", .text).notNull()
                t.column("driveProjektOrdnerID", .text)
                t.column("driveUnterordnerJSON", .text).notNull()   // {relPfad: folderID}
                t.column("airtableRecordID",     .text)
                t.column("letzterFehler",        .text)
                t.column("updatedAt",            .double).notNull()
            }
            try db.create(table: "clickUpRouting") { t in
                t.primaryKey("routingID", .text)
                t.column("ebene",      .text).notNull()
                t.column("richtung",   .text).notNull()
                t.column("appObjekt",  .text).notNull()
                t.column("clickUpObjekt", .text).notNull()
                t.column("trigger",    .text).notNull()
                t.column("userScope",  .text).notNull()
                t.column("frequenz",   .text).notNull()
                t.column("noGo",       .text)
                t.column("clickUpRef", .text)
                t.column("aktiv",      .boolean).notNull().defaults(to: false)
                t.column("optin",      .boolean).notNull().defaults(to: false)
                t.column("updatedAt",  .double).notNull()
            }
        }

        // v18_chat_memory_summary — destilliertes Assistenten-Gedächtnis (Stufe 2,
        // API-Effizienz-Härtung 2026-07-01). Ein Row je Chat-Scope, überschreibend
        // (kein Verlauf) — siehe MykilosKit/Domain/ChatMemorySummary.swift.
        migrator.registerMigration("v18_chat_memory_summary") { db in
            try db.create(table: "chatMemorySummaries") { t in
                t.primaryKey("scopeKey", .text)
                t.column("summaryText",             .text).notNull()
                t.column("coveredThroughMessageID", .text).notNull()
                t.column("updatedAt",               .double).notNull()
            }
        }

        // v19_provisioning_clickup — Studio-OS-Rollout (2026-07-02): ClickUp-Liste als
        // dritter Provisioning-Schritt (siehe ProvisioningStep.clickUpStruktur). Additiv,
        // nullable — bestehende Ledger-Einträge decodieren unverändert (clickUpListID = nil).
        migrator.registerMigration("v19_provisioning_clickup") { db in
            try db.alter(table: "provisioningLedger") { t in
                t.add(column: "clickUpListID", .text)
            }
        }

        // v20 (2026-07-02): rein lokale Lebenszyklus-Stufe je Projekt. Die App kennt
        // sonst keine Stufe (phase = nur "Aktiv"/"Archiviert"). Startwert wird aus
        // echten Signalen abgeleitet (Zeit gebucht), aber der Nutzer besitzt die Wahrheit
        // und kann sie im Hero-Stepper setzen. Kein externer Write.
        migrator.registerMigration("v20_project_lifecycle_stage") { db in
            try db.create(table: "projectLifecycleStage") { t in
                t.primaryKey("projectNumber", .text)
                t.column("stageIndex", .integer).notNull()
                t.column("setAt", .double).notNull()
            }
        }

        // v21_workbasket (Wirbelsäule, Welle C / C3, docs/S10_WIRBELSAEULE.md §3) —
        // der verallgemeinerte WorkBasket-Speicher. Zwei Tabellen, rein lokal, kein
        // externer Write: workBaskets (Kopf: inhaltsArt, Projektbezug, Version,
        // Lebenszyklus-Status, Zeitstempel) + workBasketPicks (Positionen, geordnet,
        // matrix-agnostisch — kein Artikel-only-Hardwiring). Persistiert nur die
        // konstruier-/testbare BasicPick-Form der C1-Pick-Protokoll-Instanzen
        // (snapshot + resolved inhalt als JSON); Foreign-Key-Cascade räumt Positionen
        // beim Löschen eines Korbs mit auf (append-only Ersatz: Löschen kommt in der
        // App-Schicht ohnehin nicht vor — nur Status-Übergänge, §7).
        migrator.registerMigration("v21_workbasket") { db in
            try db.create(table: "workBaskets") { t in
                t.primaryKey("id", .text)
                t.column("projektNummer", .text).notNull().indexed()
                t.column("inhaltsArt", .text).notNull()
                t.column("version", .integer).notNull().defaults(to: 1)
                t.column("statusJSON", .text).notNull()
                t.column("erstellt", .double).notNull()
            }
            try db.create(table: "workBasketPicks") { t in
                t.primaryKey("id", .text)
                t.column("basketID", .text).notNull().indexed()
                    .references("workBaskets", column: "id", onDelete: .cascade)
                t.column("position", .integer).notNull()
                t.column("matrix", .text).notNull()
                t.column("objektID", .text).notNull()
                t.column("snapshotJSON", .text).notNull()
                t.column("inhaltJSON", .text).notNull()
            }
        }

        return migrator
    }

    // Interner init für Tests (ohne Migrations-Fehler)
    private init(queue: DatabaseQueue) { self.queue = queue }
}
