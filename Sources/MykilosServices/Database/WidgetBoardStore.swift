import Foundation
import Observation
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
        }
    }

    // MARK: Speichern — Der Vertrag (throws, SaveState sichtbar)
    public func save() throws {
        saveState = .saving
        do {
            try db.write { dbConn in
                // Atomic replace: erst löschen, dann neu schreiben
                try WidgetInstanceRecord
                    .filter(Column("boardID") == boardID)
                    .deleteAll(dbConn)
                for instance in instances {
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

    public init(boardID: String, db: GRDBDatabase) {
        self.boardID = boardID
        self.db      = db
    }

    public func load() throws {
        if let record = try db.read({ dbConn in
            try NoteRecord
                .filter(Column("boardID") == boardID)
                .fetchOne(dbConn)
        }) {
            body   = record.body
            noteID = UUID(uuidString: record.id) ?? UUID()
        }
    }

    public func update(_ newBody: String) {
        body      = newBody
        saveState = .idle
    }

    public func save() throws {
        saveState = .saving
        do {
            let record = NoteRecord(id: noteID, boardID: boardID, body: body)
            try db.write { dbConn in
                try record.save(dbConn)   // INSERT OR REPLACE
            }
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }
}
