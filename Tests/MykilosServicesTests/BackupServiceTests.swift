import Testing
import Foundation
import GRDB
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

    // MARK: - ECHTER WAL-Round-Trip (Mandate G — ersetzt den früheren String-Copy-Fake)
    // Beweist gegen eine REALE on-disk GRDB-Datenbank im WAL-Modus: in die DB
    // geschriebene Daten überleben checkpoint → Backup → Dateiverlust → Restore →
    // erneutes Öffnen. Kein simulierter String, keine In-Memory-DB ohne WAL.

    @Test func echterWALRoundTripUeberlebtBackupVerlustUndRestore() throws {
        let tmp = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tmp.src) }
        let dbFile = tmp.src.appendingPathComponent("db.sqlite")
        let service = BackupService(appSupportDir: tmp.src, backupDir: tmp.backups)

        // 1. Reale DB anlegen (WAL-Modus), Zeile schreiben, OHNE manuellen Checkpoint.
        //    createConsistentBackup ERZWINGT den Checkpoint → Zeile landet in db.sqlite.
        let backupURL: URL
        do {
            let db1 = try GRDBDatabase(url: dbFile)
            try db1.write { d in
                try d.execute(sql: "CREATE TABLE IF NOT EXISTS probe(x INTEGER)")
                try d.execute(sql: "INSERT INTO probe VALUES (777)")
            }
            backupURL = try service.createConsistentBackup(
                db: db1, tag: "wal", appVersion: "6.0", gitCommit: "abc")
        }   // db1 wird hier freigegeben → Dateihandle geschlossen.

        // 2. Totalverlust simulieren: alle Live-DB-Dateien löschen.
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: dbFile.path + suffix))
        }
        #expect(FileManager.default.fileExists(atPath: dbFile.path) == false)

        // 3. Restore + DB neu öffnen → Zeile muss wieder da sein.
        try service.restore(from: backupURL, appVersion: "6.0", gitCommit: "abc")
        let db2 = try GRDBDatabase(url: dbFile)
        let value = try db2.read { d in try Int.fetchOne(d, sql: "SELECT x FROM probe") }
        #expect(value == 777)
    }

    @Test func sha256ImManifestIstKorrekterKnownVector() throws {
        // SHA-256("abc") = ba7816bf… (offizieller Testvektor) — beweist, dass die
        // Prüfsumme echt korrekt berechnet wird, nicht nur „64 Zeichen lang".
        let tmp = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tmp.src) }
        try "abc".write(to: tmp.src.appendingPathComponent("db.sqlite"), atomically: true, encoding: .utf8)

        let service = BackupService(appSupportDir: tmp.src, backupDir: tmp.backups)
        let dest = try service.createBackup(tag: "vec", appVersion: "6.0", gitCommit: "abc")
        let manifest = try JSONDecoder().decode(
            BackupManifest.self, from: Data(contentsOf: dest.appendingPathComponent("manifest.json")))
        let entry = manifest.files.first { $0.name == "db.sqlite" }
        #expect(entry?.sha256 == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    @Test func latestBackupFolderFindetEinBackup() throws {
        let tmp = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tmp.src) }
        try "db".write(to: tmp.src.appendingPathComponent("db.sqlite"), atomically: true, encoding: .utf8)
        let service = BackupService(appSupportDir: tmp.src, backupDir: tmp.backups)

        #expect(service.latestBackupFolder() == nil)   // noch keins
        let dest = try service.createBackup(tag: "x", appVersion: "6.0", gitCommit: "abc")
        let latest = service.latestBackupFolder()
        #expect(latest?.lastPathComponent == dest.lastPathComponent)
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
