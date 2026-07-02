import Foundation
import Observation
import SwiftUI
import GRDB
import MykilosKit

// MARK: - WidgetBoardStore
// @Observable, @MainActor, GRDB-backed.
// Der eine Speicher für Widget-Layouts. Jeder Schreibvorgang `throws`.
// SaveState ist in der UI sichtbar — das ist der Speichern-Vertrag.
@MainActor
@Observable
public final class WidgetBoardStore {
    // MARK: Öffentlicher Zustand
    public let boardID: String
    public private(set) var instances: [WidgetInstance] = []
    public private(set) var saveState: SaveState = .idle

    private let db: GRDBDatabase
    private let defaultLayout: () -> [WidgetInstance]

    public init(
        boardID: String,
        db: GRDBDatabase,
        defaultLayout: @escaping () -> [WidgetInstance] = { [] }
    ) {
        self.boardID       = boardID
        self.db            = db
        self.defaultLayout = defaultLayout
    }

    // MARK: Laden — Cold-Start-safe
    public func load() throws {
        let records = try db.read { dbConn in
            try WidgetInstanceRecord
                .filter(Column("boardID") == boardID)
                .order(Column("position"))
                .fetchAll(dbConn)
        }
        if records.isEmpty {
            // Erstmals geöffnet: Default-Layout einpflanzen und sofort speichern
            instances = defaultLayout()
            try save()
        } else {
            instances = records.map(\.toDomain)
            // Einmalige Migration: fehlende kanonische Widgets anhängen.
            // Nach dem ersten Lauf ist boardID in reconciledBoards; danach
            // respektiert der Store User-Entscheidungen (entfernte Widgets
            // kommen nicht zurück).
            try reconcileCanonicalWidgetsOnce()
            // Nachzügler-Migration (2026-07-02): das Warenkorb-Widget kam NACH dem
            // ersten canonicalLayout-Reconcile hinzu. Boards, die schon reconciled
            // waren, hätten es sonst nie bekommen. Eigener, einmaliger Marker je
            // Board — respektiert spätere User-Entfernung (Marker bleibt gesetzt).
            try ensureWidgetOnce(.warenkorb, size: .wide)
        }
    }

    // Ergänzt EIN bestimmtes Widget genau einmal je Board (eigener Marker
    // "<boardID>#<kind>" in reconciledBoards). Für Widget-Arten, die nach dem
    // initialen canonicalLayout-Reconcile dazukamen. Append-only, kein Schema-Umbau.
    private func ensureWidgetOnce(_ kind: WidgetKind, size: WidgetSize) throws {
        // Nur für Boards, deren EIGENES Default-Set dieses Widget vorsieht:
        // Projekt-Boards (canonicalLayout enthält .warenkorb) bekommen es, das
        // Home-Board (homeLayout ohne .warenkorb) NICHT. Kein Cross-Layer-Wissen nötig.
        guard defaultLayout().contains(where: { $0.kind == kind }) else { return }
        let marker = "\(boardID)#\(kind.rawValue)"
        let alreadyDone = try db.read { dbConn in
            try Row.fetchOne(dbConn,
                sql: "SELECT 1 FROM reconciledBoards WHERE boardID = ?",
                arguments: [marker]) != nil
        }
        guard !alreadyDone else { return }
        if !instances.contains(where: { $0.kind == kind }) {
            let next = (instances.map(\.position).max() ?? -1) + 1
            instances.append(WidgetInstance(kind: kind, size: size, position: next))
            try save()
        }
        try db.write { dbConn in
            try dbConn.execute(
                sql: "INSERT OR IGNORE INTO reconciledBoards (boardID) VALUES (?)",
                arguments: [marker])
        }
    }

    // Läuft genau einmal je boardID. Danach ist boardID in `reconciledBoards`
    // gespeichert und User-Entscheidungen (Widget entfernt) bleiben permanent.
    private func reconcileCanonicalWidgetsOnce() throws {
        let alreadyDone = try db.read { dbConn in
            try Row.fetchOne(dbConn,
                sql: "SELECT 1 FROM reconciledBoards WHERE boardID = ?",
                arguments: [boardID]) != nil
        }
        guard !alreadyDone else { return }
        let presentKinds = Set(instances.map(\.kind))
        let missing = defaultLayout().filter { !presentKinds.contains($0.kind) }
        if !missing.isEmpty {
            var nextPosition = (instances.map(\.position).max() ?? -1) + 1
            for template in missing {
                instances.append(WidgetInstance(kind: template.kind, size: template.size, position: nextPosition))
                nextPosition += 1
            }
            try save()
        }
        try db.write { dbConn in
            try dbConn.execute(
                sql: "INSERT OR IGNORE INTO reconciledBoards (boardID) VALUES (?)",
                arguments: [boardID])
        }
    }

    // MARK: Speichern — Der Vertrag (throws, SaveState sichtbar)
    public func save() throws {
        saveState = .saving
        let boardID = self.boardID
        let snapshot = instances
        do {
            try db.write { dbConn in
                // Atomic replace: erst löschen, dann neu schreiben
                try WidgetInstanceRecord
                    .filter(Column("boardID") == boardID)
                    .deleteAll(dbConn)
                for instance in snapshot {
                    try WidgetInstanceRecord(from: instance, boardID: boardID)
                        .insert(dbConn)
                }
            }
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error     // weiter nach oben — kein stilles Schlucken
        }
    }

    // MARK: Layout-Operationen (je nach Aktion speichern)
    public func move(fromOffsets: IndexSet, toOffset: Int) throws {
        instances.move(fromOffsets: fromOffsets, toOffset: toOffset)
        reindex()
        try save()
    }

    public func remove(id: UUID) throws {
        instances.removeAll { $0.id == id }
        reindex()
        try save()
    }

    public func add(kind: WidgetKind, size: WidgetSize = .medium) throws {
        let next = (instances.map(\.position).max() ?? -1) + 1
        instances.append(WidgetInstance(kind: kind, size: size, position: next))
        try save()
    }

    public func toggle(id: UUID) throws {
        guard let i = instances.firstIndex(where: { $0.id == id }) else { return }
        instances[i].isVisible.toggle()
        try save()
    }

    public func resize(id: UUID, to size: WidgetSize) throws {
        guard let i = instances.firstIndex(where: { $0.id == id }) else { return }
        instances[i].size = size
        try save()
    }

    // MARK: Helfer
    private func reindex() {
        for i in instances.indices { instances[i].position = i }
    }
}

// MARK: - NoteStore
// Persistente Notizen je Board. SaveState sichtbar in NotesWidget.
@MainActor
@Observable
public final class NoteStore {
    public let boardID: String
    public private(set) var body: String = ""
    public private(set) var saveState: SaveState = .idle

    private let db: GRDBDatabase
    private var noteID: UUID = UUID()
    private var hasLoaded = false
    private var dirty = false

    /// Gibt es ungespeicherte Änderungen? Für günstige, idempotente Flushes.
    public var hasUnsavedChanges: Bool { dirty }

    public init(boardID: String, db: GRDBDatabase) {
        self.boardID = boardID
        self.db      = db
    }

    public func load() throws {
        // Nur EINMAL aus der DB laden. Sonst überschreibt ein erneutes load()
        // (onAppear/.task feuern wiederholt) die noch nicht gespeicherte
        // Eingabe mit dem alten DB-Stand → stiller Datenverlust. Lokal,
        // Single-Writer → ein Reload bringt ohnehin nichts Neues.
        guard !hasLoaded else { return }
        if let record = try db.read({ dbConn in
            try NoteRecord
                .filter(Column("boardID") == boardID)
                .fetchOne(dbConn)
        }) {
            body   = record.body
            noteID = UUID(uuidString: record.id) ?? UUID()
        }
        hasLoaded = true
    }

    public func update(_ newBody: String) {
        body      = newBody
        saveState = .idle
        dirty     = true
    }

    public func save() throws {
        saveState = .saving
        do {
            let record = NoteRecord(id: noteID, boardID: boardID, body: body)
            try db.write { dbConn in
                try record.save(dbConn)   // INSERT OR REPLACE
            }
            saveState = .saved(Date())
            dirty = false
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }
}
