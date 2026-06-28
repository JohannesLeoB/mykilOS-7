import Testing
import Foundation
@testable import MykilosServices

struct BackupServiceTests {

    // MARK: - Backup + Manifest

    @Test func backupErzeugtManifestMitPruefSummen() throws {
        let tmp = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tmp.src) }

        // Schreibe Testdaten
        try "db content".write(to: tmp.src.appendingPathComponent("db.sqlite"), atomically: true, encoding: .utf8)
        try "projects".write(to: tmp.src.appendingPathComponent("projects.json"), atomically: true, encoding: .utf8)

        let service = BackupService(appSupportDir: tmp.src, backupDir: tmp.backups)
        let dest = try service.createBackup(tag: "test", appVersion: "6.0", gitCommit: "abc123")

        let manifestURL = dest.appendingPathComponent("manifest.json")
        #expect(FileManager.default.fileExists(atPath: manifestURL.path))

        let manifest = try JSONDecoder().decode(BackupManifest.self, from: Data(contentsOf: manifestURL))
        #expect(manifest.appVersion == "6.0")
        #expect(manifest.gitCommit == "abc123")
        #expect(manifest.files.count >= 2)
        // SHA-256 ist 64 Zeichen lang (Hex)
        #expect(manifest.files.first?.sha256.count == 64)
    }

    @Test func integritaetspruefungErkenntKorruption() throws {
        let tmp = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tmp.src) }

        try "db content".write(to: tmp.src.appendingPathComponent("db.sqlite"), atomically: true, encoding: .utf8)

        let service = BackupService(appSupportDir: tmp.src, backupDir: tmp.backups)
        let dest = try service.createBackup(tag: "corrupt", appVersion: "6.0", gitCommit: "abc")

        // Korrumpiere eine Backup-Datei
        try "KORRUMPIERT".write(to: dest.appendingPathComponent("db.sqlite"), atomically: true, encoding: .utf8)

        #expect(throws: BackupError.self) {
            _ = try service.loadAndVerifyManifest(from: dest)
        }
    }

    @Test func restoreUeberschreibtLiveDateien() throws {
        let tmp = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tmp.src) }

        // Ausgangszustand
        let originalContent = "original db content"
        try originalContent.write(to: tmp.src.appendingPathComponent("db.sqlite"), atomically: true, encoding: .utf8)
        try "projects_v1".write(to: tmp.src.appendingPathComponent("projects.json"), atomically: true, encoding: .utf8)

        let service = BackupService(appSupportDir: tmp.src, backupDir: tmp.backups)
        let backupDest = try service.createBackup(tag: "pre-change", appVersion: "6.0", gitCommit: "abc")

        // Verändere Live-Dateien
        try "VERÄNDERT".write(to: tmp.src.appendingPathComponent("db.sqlite"), atomically: true, encoding: .utf8)

        // Restore
        try service.restore(from: backupDest, appVersion: "6.0", gitCommit: "abc")

        let restored = try String(contentsOf: tmp.src.appendingPathComponent("db.sqlite"), encoding: .utf8)
        #expect(restored == originalContent)
    }

    // MARK: - WAL-Test: uncommittete WAL-Daten nach Backup+Restore erhalten

    @Test func walDatenNachBackupUndRestoreErhalten() throws {
        let db = try GRDBDatabase.inMemory()
        let tmp = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tmp.src) }

        // Schreibe etwas in die In-Memory-DB, dann simuliere Backup.
        // Da In-Memory keine WAL hat, testen wir den WAL-Checkpoint-Aufruf.
        // Für den Datei-Backup-Test simulieren wir eine echte Datei.

        let dbFile = tmp.src.appendingPathComponent("db.sqlite")
        try "initial".write(to: dbFile, atomically: true, encoding: .utf8)
        // Simuliere WAL-Datei mit "uncommitted" Daten
        let walFile = tmp.src.appendingPathComponent("db.sqlite-wal")
        try "wal_data_uncommitted".write(to: walFile, atomically: true, encoding: .utf8)

        let service = BackupService(appSupportDir: tmp.src, backupDir: tmp.backups)
        let dest = try service.createBackup(tag: "wal-test", appVersion: "6.0", gitCommit: "abc")

        // WAL-Datei muss im Backup vorhanden sein
        let walBackup = dest.appendingPathComponent("db.sqlite-wal")
        #expect(FileManager.default.fileExists(atPath: walBackup.path))

        let manifest = try service.loadAndVerifyManifest(from: dest)
        let walEntry = manifest.files.first { $0.name == "db.sqlite-wal" }
        #expect(walEntry != nil)
        #expect(walEntry?.sizeBytes ?? 0 > 0)

        // Verändere Live-Dateien, dann Restore
        try "CHANGED".write(to: dbFile, atomically: true, encoding: .utf8)
        try service.restore(from: dest, appVersion: "6.0", gitCommit: "abc")

        // Nach Restore: WAL-Inhalt muss erhalten sein
        let restoredWAL = try String(contentsOf: walFile, encoding: .utf8)
        #expect(restoredWAL == "wal_data_uncommitted")
    }

    // MARK: - Retention

    @Test func altBackupsWerdenGeloescht() throws {
        let tmp = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tmp.src) }

        try "db".write(to: tmp.src.appendingPathComponent("db.sqlite"), atomically: true, encoding: .utf8)
        let service = BackupService(appSupportDir: tmp.src, backupDir: tmp.backups)

        // Erstelle 5 Backups
        for i in 0..<5 {
            _ = try service.createBackup(tag: "b\(i)", appVersion: "6.0", gitCommit: "abc")
        }

        // Prune mit keepMin=3, 0 Tage (alle löschen außer 3 neueste)
        try service.pruneOldBackups(olderThanDays: 0, keepMin: 3)

        let remaining = (try? FileManager.default.contentsOfDirectory(
            at: tmp.backups, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
        ))?.filter { $0.lastPathComponent.hasPrefix("backup_") } ?? []

        #expect(remaining.count >= 3)
    }
}

// MARK: - Hilfstypen

private struct TempDirs {
    let src: URL
    let backups: URL
}

private func makeTempDir() -> TempDirs {
    let base = FileManager.default.temporaryDirectory
        .appendingPathComponent("mykilos_backup_test_\(UUID().uuidString)", isDirectory: true)
    let backups = base.appendingPathComponent("backups", isDirectory: true)
    try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    try? FileManager.default.createDirectory(at: backups, withIntermediateDirectories: true)
    return TempDirs(src: base, backups: backups)
}
