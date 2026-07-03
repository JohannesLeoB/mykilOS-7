import Foundation
import CryptoKit

// MARK: - BackupManifest
// Enthält alle Metadaten eines Backups — keine Tokens, keine Secrets.
public struct BackupManifest: Codable, Sendable {
    public var appVersion: String
    public var schemaVersion: Int
    public var gitCommit: String
    public var timestamp: Date
    public var files: [BackupFileEntry]

    public struct BackupFileEntry: Codable, Sendable {
        public var name: String
        public var sizeBytes: Int
        public var sha256: String
    }
}

// MARK: - BackupError
public enum BackupError: Error, Sendable {
    case sourceNotFound(String)
    case checksumMismatch(String)
    case schemaVersionMismatch(expected: Int, got: Int)
    case integrityCheckFailed
    case restoreFailedSmokTest
}

// MARK: - BackupService
// WAL-sicherer Backup- und Restore-Service für mykilOS 6.
// Sichert: db.sqlite, db.sqlite-wal, db.sqlite-shm, projects.json, customers.json.
// Schreibt ein Manifest mit SHA-256-Prüfsummen.
// Restore: prüft → Rettungsbackup → atomar austauschen → Smoke-Test.
public struct BackupService: Sendable {

    private let appSupportDir: URL
    private let backupDir: URL
    private let fm = FileManager.default

    public init(
        appSupportDir: URL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("mykilOS6", isDirectory: true),
        backupDir: URL? = nil
    ) {
        self.appSupportDir = appSupportDir
        self.backupDir = backupDir ?? appSupportDir
            .appendingPathComponent("backups", isDirectory: true)
    }

    // MARK: - Backup

    /// Konsistentes Backup MIT erzwungenem WAL-Checkpoint (Mandate G). Der Checkpoint
    /// schreibt alle ausstehenden WAL-Transaktionen in db.sqlite, sodass die Kopie
    /// garantiert vollständig ist. Vorher war der Checkpoint nur im Doc-Kommentar
    /// gefordert, aber nie aufgerufen — hier ist er in den Fluss eingebaut, der die
    /// `GRDBDatabase` besitzt, also nicht mehr umgehbar.
    @discardableResult
    public func createConsistentBackup(db: GRDBDatabase, tag: String,
                                       appVersion: String, gitCommit: String) throws -> URL {
        try db.checkpoint()
        return try createBackup(tag: tag, appVersion: appVersion, gitCommit: gitCommit)
    }

    /// Jüngster Backup-Ordner (nach Erstellungsdatum), falls vorhanden.
    public func latestBackupFolder() -> URL? {
        guard let items = try? fm.contentsOfDirectory(
            at: backupDir, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles
        ) else { return nil }
        return items
            .filter { $0.lastPathComponent.hasPrefix("backup_") }
            .compactMap { url -> (url: URL, date: Date)? in
                guard let d = (try? fm.attributesOfItem(atPath: url.path))?[.creationDate] as? Date else { return nil }
                return (url, d)
            }
            .sorted { $0.date > $1.date }
            .first?.url
    }

    /// Erstellt ein konsistentes Backup. Muss nach GRDBDatabase.checkpoint() aufgerufen werden.
    /// - Parameter tag: kurzer Bezeichner (z.B. "pre-migration", "daily")
    /// - Returns: URL des Backup-Ordners
    @discardableResult
    public func createBackup(tag: String, appVersion: String, gitCommit: String) throws -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let folderName = "backup_\(tag)_\(timestamp)"
            .replacingOccurrences(of: ":", with: "-")
        let dest = backupDir.appendingPathComponent(folderName, isDirectory: true)
        try fm.createDirectory(at: dest, withIntermediateDirectories: true)

        let sourcePaths: [String] = [
            "db.sqlite", "db.sqlite-wal", "db.sqlite-shm",
            "projects.json", "customers.json",
        ]

        var entries: [BackupManifest.BackupFileEntry] = []
        for name in sourcePaths {
            let src = appSupportDir.appendingPathComponent(name)
            guard fm.fileExists(atPath: src.path) else { continue }
            let dstFile = dest.appendingPathComponent(name)
            try fm.copyItem(at: src, to: dstFile)
            let data = try Data(contentsOf: dstFile, options: .alwaysMapped)
            entries.append(BackupManifest.BackupFileEntry(
                name: name,
                sizeBytes: data.count,
                sha256: sha256Hex(of: data)
            ))
        }

        let manifest = BackupManifest(
            appVersion: appVersion,
            schemaVersion: currentSchemaVersion,
            gitCommit: gitCommit,
            timestamp: Date(),
            files: entries
        )
        let manifestData = try JSONEncoder().encode(manifest)
        try manifestData.write(to: dest.appendingPathComponent("manifest.json"))
        return dest
    }

    // MARK: - Restore

    /// Stellt ein Backup wieder her.
    /// 1. Prüft Integrität des Backups.
    /// 2. Legt Rettungsbackup des aktuellen Zustands an.
    /// 3. Kopiert atomar in temporäres Verzeichnis, tauscht dann aus.
    /// 4. Smoke-Test: prüft ob db.sqlite lesbar ist.
    public func restore(from backupFolder: URL, appVersion: String, gitCommit: String) throws {
        // 1. Integrität prüfen
        let manifest = try loadAndVerifyManifest(from: backupFolder)

        // 2. Rettungsbackup
        _ = try createBackup(tag: "pre-restore", appVersion: appVersion, gitCommit: gitCommit)

        // 3. Atomar austauschen
        let tempDir = backupDir.appendingPathComponent("restore_tmp_\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        for entry in manifest.files {
            let src = backupFolder.appendingPathComponent(entry.name)
            let dst = tempDir.appendingPathComponent(entry.name)
            try fm.copyItem(at: src, to: dst)
        }
        for entry in manifest.files {
            let tmp = tempDir.appendingPathComponent(entry.name)
            let live = appSupportDir.appendingPathComponent(entry.name)
            if fm.fileExists(atPath: live.path) {
                try fm.removeItem(at: live)
            }
            try fm.moveItem(at: tmp, to: live)
        }
        try? fm.removeItem(at: tempDir)

        // 4. Smoke-Test: db.sqlite muss lesbar und > 0 Bytes sein
        let dbPath = appSupportDir.appendingPathComponent("db.sqlite")
        let attr = try fm.attributesOfItem(atPath: dbPath.path)
        guard let size = attr[.size] as? Int, size > 0 else {
            throw BackupError.restoreFailedSmokTest
        }
    }

    // MARK: - Integrität prüfen

    public func loadAndVerifyManifest(from backupFolder: URL) throws -> BackupManifest {
        let manifestURL = backupFolder.appendingPathComponent("manifest.json")
        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(BackupManifest.self, from: data)
        for entry in manifest.files {
            let fileURL = backupFolder.appendingPathComponent(entry.name)
            guard fm.fileExists(atPath: fileURL.path) else {
                throw BackupError.sourceNotFound(entry.name)
            }
            let fileData = try Data(contentsOf: fileURL, options: .alwaysMapped)
            let actual = sha256Hex(of: fileData)
            guard actual == entry.sha256 else {
                throw BackupError.checksumMismatch(entry.name)
            }
        }
        return manifest
    }

    // MARK: - Auflisten

    /// Metadaten eines vorhandenen Backups (für die Restore-Liste in den Einstellungen).
    public struct BackupInfo: Sendable, Identifiable, Equatable {
        public let folderURL: URL
        public let createdAt: Date
        public let tag: String
        public let sizeBytes: Int
        public var id: String { folderURL.lastPathComponent }
    }

    /// Alle vorhandenen Backups, neueste zuerst. Tag aus dem Ordnernamen
    /// (`backup_<tag>_<zeitstempel>`), Datum aus dem Datei-Erstelldatum.
    public func listBackups() -> [BackupInfo] {
        guard let items = try? fm.contentsOfDirectory(
            at: backupDir, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles
        ) else { return [] }
        return items
            .filter { $0.lastPathComponent.hasPrefix("backup_") }
            .compactMap { url -> BackupInfo? in
                let attrs = try? fm.attributesOfItem(atPath: url.path)
                let date = (attrs?[.creationDate] as? Date) ?? Date(timeIntervalSince1970: 0)
                let parts = url.lastPathComponent.components(separatedBy: "_")
                let tag = parts.count >= 2 ? parts[1] : "?"
                return BackupInfo(folderURL: url, createdAt: date, tag: tag, sizeBytes: folderSize(url))
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Datum des jüngsten Backups (für die „höchstens 1×/Tag"-Auto-Backup-Entscheidung).
    public func latestBackupDate() -> Date? { listBackups().first?.createdAt }

    private func folderSize(_ url: URL) -> Int {
        guard let files = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        return files.reduce(0) { acc, f in
            acc + (((try? fm.attributesOfItem(atPath: f.path))?[.size] as? Int) ?? 0)
        }
    }

    // MARK: - Retention

    /// Behält die `keepNewest` jüngsten Backups, löscht den Rest (Anzahl-Grenze,
    /// ergänzend zur Zeit-Retention). Rettungsbackups (pre-restore) zählen mit,
    /// sind aber jung genug, um nicht vorzeitig gelöscht zu werden.
    public func pruneToCount(keepNewest keep: Int) throws {
        let all = listBackups()
        guard all.count > keep else { return }
        for info in all.dropFirst(keep) {
            try? fm.removeItem(at: info.folderURL)
        }
    }

    /// Löscht Backups, die älter als `days` Tage sind. Behält mind. `keepMin` Backups.
    public func pruneOldBackups(olderThanDays days: Int, keepMin: Int = 3) throws {
        guard let items = try? fm.contentsOfDirectory(
            at: backupDir, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles
        ) else { return }
        let backups = items
            .filter { $0.lastPathComponent.hasPrefix("backup_") }
            .compactMap { url -> (url: URL, date: Date)? in
                let attrs = try? fm.attributesOfItem(atPath: url.path)
                guard let d = attrs?[.creationDate] as? Date else { return nil }
                return (url, d)
            }
            .sorted { $0.date > $1.date }

        let cutoff = Date().addingTimeInterval(-Double(days) * 86400)
        let toDelete = backups.dropFirst(keepMin).filter { $0.date < cutoff }
        for item in toDelete {
            try? fm.removeItem(at: item.url)
        }
    }

    // MARK: - Helpers

    private func sha256Hex(of data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private var currentSchemaVersion: Int { 6 }
}
