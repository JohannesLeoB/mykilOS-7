import Testing
import Foundation
@testable import MykilosServices

// MARK: - DriveLocalResolver GATE-Tests (Mandate B)
// Beweist die lokale Drive-Auflösung REAL: setzt das Google-Drive-File-Stream-xattr
// (`com.google.drivefs.item-id#S`) auf einem Temp-Baum und prüft, dass der Resolver
// Dateien/Unterordner über die Drive-Item-ID findet — inklusive der verschachtelten
// Hustadt-Struktur „05 eingehende Angebote/Vorplanung/angebot.pdf".
// Kein Proof-of-Existence: hier läuft die echte xattr-Logik gegen das Dateisystem.
struct DriveLocalResolverTests {

    // Hilfsfunktion: setzt das Drive-Item-ID-xattr auf eine Datei/einen Ordner.
    private func setDriveID(_ id: String, on url: URL) throws {
        let bytes = Array(id.utf8)
        let rc = bytes.withUnsafeBufferPointer {
            setxattr(url.path, DriveLocalResolver.xattrName, $0.baseAddress, bytes.count, 0, 0)
        }
        #expect(rc == 0, "setxattr fehlgeschlagen (rc=\(rc)) für \(url.path)")
    }

    private func tempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("drivelocaltest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test func liestDriveItemIDAusXattr() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("angebot.pdf")
        try Data("x".utf8).write(to: file)
        try setDriveID("ITEM-123", on: file)

        #expect(DriveLocalResolver.driveItemID(at: file) == "ITEM-123")
        let ohne = dir.appendingPathComponent("ohne.txt")
        try Data("y".utf8).write(to: ohne)
        #expect(DriveLocalResolver.driveItemID(at: ohne) == nil)
    }

    @Test func firstChildFindetDirektesKind() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let projektOrdner = dir.appendingPathComponent("2026_Hustadt", isDirectory: true)
        try FileManager.default.createDirectory(at: projektOrdner, withIntermediateDirectories: true)
        try setDriveID("13ITPqAMdz6JrS13u8y7JvkTVXAWznA_S", on: projektOrdner)

        let hit = DriveLocalResolver.firstChild(of: dir, withItemID: "13ITPqAMdz6JrS13u8y7JvkTVXAWznA_S")
        #expect(hit?.lastPathComponent == "2026_Hustadt")
        #expect(DriveLocalResolver.firstChild(of: dir, withItemID: "FEHLT") == nil)
    }

    @Test func findFindetVerschachteltePDFUeberItemID() throws {
        // Hustadt-Struktur: Projektordner/05 eingehende Angebote/Vorplanung/angebot.pdf
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let eingehende = dir.appendingPathComponent("05 eingehende Angebote", isDirectory: true)
        let vorplanung = eingehende.appendingPathComponent("Vorplanung Stein", isDirectory: true)
        try FileManager.default.createDirectory(at: vorplanung, withIntermediateDirectories: true)
        let pdf = vorplanung.appendingPathComponent("angebot_stein.pdf")
        try Data("%PDF".utf8).write(to: pdf)
        try setDriveID("PDF-DEEP-9", on: pdf)

        let hit = DriveLocalResolver.find(itemID: "PDF-DEEP-9", in: dir, fileName: "angebot_stein.pdf")
        // /var ↔ /private/var: symlink-aufgelöst vergleichen (gleiche Datei).
        #expect(hit?.resolvingSymlinksInPath().path == pdf.resolvingSymlinksInPath().path)
    }

    @Test func findNutztNamensFallbackOhneXattr() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let sub = dir.appendingPathComponent("Unterordner", isDirectory: true)
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let pdf = sub.appendingPathComponent("rechnung.pdf")
        try Data("%PDF".utf8).write(to: pdf)   // KEIN xattr gesetzt

        // Item-ID nicht auffindbar → Namens-Fallback greift.
        let hit = DriveLocalResolver.find(itemID: "GIBT-ES-NICHT", in: dir, fileName: "rechnung.pdf")
        #expect(hit?.lastPathComponent == "rechnung.pdf")
        // Ohne Namens-Hinweis: nil.
        #expect(DriveLocalResolver.find(itemID: "GIBT-ES-NICHT", in: dir, fileName: nil) == nil)
    }

    @Test func findRespektiertMaxDepth() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        // Zu tief: a/b/c/ziel.pdf bei maxDepth 1 → nicht gefunden.
        let deep = dir.appendingPathComponent("a/b/c", isDirectory: true)
        try FileManager.default.createDirectory(at: deep, withIntermediateDirectories: true)
        let pdf = deep.appendingPathComponent("ziel.pdf")
        try Data("%PDF".utf8).write(to: pdf)
        try setDriveID("TIEF-1", on: pdf)

        #expect(DriveLocalResolver.find(itemID: "TIEF-1", in: dir, fileName: nil, maxDepth: 1) == nil)
        let deepHit = DriveLocalResolver.find(itemID: "TIEF-1", in: dir, fileName: nil, maxDepth: 5)
        #expect(deepHit?.resolvingSymlinksInPath().path == pdf.resolvingSymlinksInPath().path)
    }
}
