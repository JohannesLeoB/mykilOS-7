import Foundation
import MykilosServices

// MARK: - AppDatabase
// Einmalige Erzeugung der Produktions-Datenbank.
// `try!` ist hier justified: wenn Application Support nicht erreichbar ist,
// kann die App nicht arbeiten und soll mit einem klaren Crash enden —
// nicht still mit leeren Listen.
public enum AppDatabase {
    public static let production: GRDBDatabase = {
        let dir: URL
        if let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            dir = appSupport.appendingPathComponent("mykilOS6", isDirectory: true)
        } else {
            dir = FileManager.default.temporaryDirectory
                .appendingPathComponent("mykilOS6", isDirectory: true)
        }
        // swiftlint:disable:next force_try
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let dbURL = dir.appendingPathComponent("db.sqlite")
        // swiftlint:disable:next force_try
        return try! GRDBDatabase(url: dbURL)
    }()
}
