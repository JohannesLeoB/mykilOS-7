import Foundation
import os
import MykilosServices

// MARK: - AppDatabase (Mandate F — wiederherstellbarer DB-Start, kein try!)
//
// Früher: `static let production = try! GRDBDatabase(url:)` — schlug das Öffnen fehl
// (gesperrte/korrupte sqlite, nicht beschreibbares Application Support), crashte die
// App noch VOR dem ersten View, ohne jede Diagnose. Jetzt liefert `boot()` einen
// expliziten Erfolg/Fehler-Zustand, den `MykilOS6App` konsumiert: bei Fehler erscheint
// eine Wiederherstellungs-Ansicht (Pfad sichtbar + „Datenbank zurücksetzen") statt eines Absturzes.
public enum AppDatabase {

    /// Pfad der Produktions-DB. EINE Quelle der Wahrheit, damit die Diagnose
    /// (`AppIdentity.dbPath`) garantiert exakt den Pfad zeigt, der real geöffnet wird.
    public static var productionURL: URL {
        let dir: URL
        if let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            dir = appSupport.appendingPathComponent("mykilOS6", isDirectory: true)
        } else {
            dir = FileManager.default.temporaryDirectory
                .appendingPathComponent("mykilOS6", isDirectory: true)
        }
        return dir.appendingPathComponent("db.sqlite")
    }

    public enum Boot {
        case ready(GRDBDatabase)
        case failed(message: String, dbPath: String)
    }

    /// Marker-Datei für eine vom Nutzer vorgemerkte Wiederherstellung. Enthält den
    /// Ordnerpfad des gewählten Backups. Wird beim nächsten Start angewandt — sicher,
    /// weil die DB dann noch NICHT geöffnet ist (kein Überschreiben offener Handles).
    public static var restoreMarkerURL: URL {
        productionURL.deletingLastPathComponent().appendingPathComponent("restore-pending.txt")
    }

    /// Merkt ein Backup zur Wiederherstellung beim nächsten Start vor (schreibt den Marker).
    public static func stageRestore(from folderURL: URL) {
        try? folderURL.path.write(to: restoreMarkerURL, atomically: true, encoding: .utf8)
    }

    /// Wendet eine vorgemerkte Wiederherstellung an, falls vorhanden. Der Marker wird
    /// VOR dem Versuch gelöscht — ein fehlgeschlagenes Restore darf keinen Start-Loop erzeugen.
    private static func applyPendingRestoreIfAny() {
        let marker = restoreMarkerURL
        guard let folderPath = try? String(contentsOf: marker, encoding: .utf8),
              !folderPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        try? FileManager.default.removeItem(at: marker)
        let folderURL = URL(fileURLWithPath: folderPath.trimmingCharacters(in: .whitespacesAndNewlines))
        let service = BackupService(appSupportDir: productionURL.deletingLastPathComponent())
        do {
            try service.restore(from: folderURL, appVersion: AppIdentity.version, gitCommit: AppIdentity.gitCommit)
            MykLog.backup.notice("Vorgemerkte Wiederherstellung angewandt: \(folderURL.lastPathComponent, privacy: .public)")
        } catch {
            MykLog.backup.error("Vorgemerkte Wiederherstellung fehlgeschlagen: \(String(describing: error), privacy: .public)")
        }
    }

    /// Öffnet die Produktions-DB wiederherstellbar — wirft nie, crasht nie.
    public static func boot() -> Boot {
        applyPendingRestoreIfAny()   // vor dem Öffnen: ausstehendes Restore anwenden
        let dbURL = productionURL
        do {
            try FileManager.default.createDirectory(
                at: dbURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let db = try GRDBDatabase(url: dbURL)
            MykLog.db.notice("DB geöffnet: \(dbURL.path, privacy: .public)")
            return .ready(db)
        } catch {
            MykLog.db.error("DB-Öffnen fehlgeschlagen: \(String(describing: error), privacy: .public)")
            return .failed(message: String(describing: error), dbPath: dbURL.path)
        }
    }

    /// Letzte Rettung: korrupte DB-Dateien (+ WAL/SHM) beiseiteschieben und neu anlegen.
    /// Die Quarantäne bleibt erhalten (kein Datenverlust durch Löschen) — der Nutzer
    /// kann sie später inspizieren/per Backup wiederherstellen.
    public static func recoverByResettingDatabase(now: Date = Date()) -> Boot {
        let dbURL = productionURL
        let stamp = Int(now.timeIntervalSinceReferenceDate)
        for suffix in ["", "-wal", "-shm"] {
            let live = URL(fileURLWithPath: dbURL.path + suffix)
            let quarantine = URL(fileURLWithPath: dbURL.path + ".corrupt-\(stamp)" + suffix)
            try? FileManager.default.moveItem(at: live, to: quarantine)
        }
        MykLog.db.notice("DB zurückgesetzt (Quarantäne-Stempel \(stamp))")
        return boot()
    }

    /// Stellt das jüngste Backup wieder her und öffnet die DB neu. SICHER nur, weil
    /// dies aus dem Fehler-Zustand (DB nicht geöffnet) aufgerufen wird — kein offenes
    /// Handle auf die live-Datei. `BackupService.restore` ist atomar + prüft Prüfsummen
    /// und legt vorher selbst ein Rettungsbackup an.
    public static func restoreLatestBackupThenBoot() -> Boot {
        let appSupportDir = productionURL.deletingLastPathComponent()
        let service = BackupService(appSupportDir: appSupportDir)
        guard let latest = service.latestBackupFolder() else {
            return .failed(message: "Kein Backup gefunden, das wiederhergestellt werden könnte.",
                           dbPath: productionURL.path)
        }
        do {
            try service.restore(from: latest, appVersion: AppIdentity.version, gitCommit: AppIdentity.gitCommit)
            MykLog.backup.notice("Backup wiederhergestellt: \(latest.lastPathComponent, privacy: .public)")
            return boot()
        } catch {
            MykLog.backup.error("Wiederherstellung fehlgeschlagen: \(String(describing: error), privacy: .public)")
            return .failed(message: "Wiederherstellung fehlgeschlagen: \(error)", dbPath: productionURL.path)
        }
    }
}
