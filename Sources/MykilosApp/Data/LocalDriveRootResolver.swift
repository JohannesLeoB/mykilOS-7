import Foundation
import AppKit

// MARK: - LocalDriveRootResolver
// Löst eine Google-Drive-Ordner-ID (z.B. "13ITPqAMdz6JrS13u8y7JvkTVXAWznA_S")
// auf einen lokal materialisierten Pfad im Google-Drive-File-Provider auf.
//
// Strategie (in Reihenfolge):
// 1. Alle Google-Drive-Roots unter ~/Library/CloudStorage/ scannen
//    (ein Account = ein Root-Ordner "GoogleDrive-<email>").
// 2. In PROJEKTE-Unterordner des Roots xattr `com.google.drivefs.item-id#S` lesen.
// 3. Ersten Treffer mit passender ID zurückgeben.
//
// Keine Security-Scoped Bookmarks nötig: CloudStorage-Ordner sind für die App ohne
// Sandbox-Ausnahmen direkt lesbar (kein Scoping, da sie unter dem Heimverzeichnis liegen).
//
// Einschränkungen:
// - Ordner muss lokal materialisiert sein (nicht nur in Drive, sondern heruntergeladen).
// - Zwei Drive-Accounts: beide Roots werden geprüft, der neuere gewinnt bei Namensgleichheit.
// - Alter Root mit Datum-Suffix (z.B. "(18.06.26 13:37)") wird ebenfalls gescannt.
@MainActor
public final class LocalDriveRootResolver {
    public static let shared = LocalDriveRootResolver()
    private init() {}

    // MARK: - Public API

    /// Gibt den lokalen URL für einen Projektordner zurück, identifiziert via xattr Drive-ID.
    /// Gibt `nil` zurück wenn der Ordner nicht lokal materialisiert ist.
    public func localURL(forDriveFolderID folderID: String) -> URL? {
        for root in googleDriveRoots() {
            if let url = scan(root: root, lookingFor: folderID) {
                return url
            }
        }
        return nil
    }

    /// Öffnet den lokalen Ordner im Finder (selektiert ihn). Fällt auf webViewLink-Öffnung zurück.
    public func revealInFinder(driveFolderID: String, fallbackURL: URL?) {
        if let local = localURL(forDriveFolderID: driveFolderID) {
            NSWorkspace.shared.selectFile(local.path, inFileViewerRootedAtPath: local.deletingLastPathComponent().path)
        } else if let url = fallbackURL {
            NSWorkspace.shared.open(url)
        }
    }

    /// Öffnet eine einzelne lokale Datei. Fällt auf webViewLink zurück.
    public func openFile(localURL url: URL?, fallbackURL: URL?) {
        if let local = url, FileManager.default.fileExists(atPath: local.path) {
            NSWorkspace.shared.open(local)
        } else if let fallback = fallbackURL {
            NSWorkspace.shared.open(fallback)
        }
    }

    // MARK: - Drive Roots

    /// Alle Google-Drive-File-Provider-Roots unter ~/Library/CloudStorage/.
    /// Neuere kommen zuerst (kein Datum-Suffix = aktuell, Datum-Suffix = veraltet).
    public func googleDriveRoots() -> [URL] {
        let cloudStorage = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/CloudStorage", isDirectory: true)
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: cloudStorage,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ) else { return [] }
        // Alle Ordner, die mit "GoogleDrive-" beginnen; aktueller Root zuerst.
        return contents
            .filter { $0.lastPathComponent.hasPrefix("GoogleDrive-") }
            .sorted { a, _ in !a.lastPathComponent.contains("(") }
    }

    // MARK: - xattr-Scan

    /// Scannt `root` auf Unterordner, deren xattr com.google.drivefs.item-id#S == folderID.
    /// Sucht in bekannten Subdirs (Geteilte Ablagen/MYKILOS Team/PROJEKTE und Meine Ablage).
    func scan(root: URL, lookingFor folderID: String) -> URL? {
        let candidates: [URL] = [
            root.appendingPathComponent("Geteilte Ablagen/MYKILOS Team/PROJEKTE", isDirectory: true),
            root.appendingPathComponent("MYKILOS Team/PROJEKTE", isDirectory: true),
            root.appendingPathComponent("Meine Ablage", isDirectory: true),
        ]
        for candidate in candidates {
            if let found = scanDirectory(candidate, lookingFor: folderID) {
                return found
            }
        }
        return nil
    }

    func scanDirectory(_ directory: URL, lookingFor folderID: String) -> URL? {
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ) else { return nil }
        for item in items {
            if xattrDriveID(at: item) == folderID {
                return item
            }
        }
        return nil
    }

    // MARK: - xattr-Lesehilfe

    public func xattrDriveID(at url: URL) -> String? {
        let attrName = "com.google.drivefs.item-id#S"
        let path = url.path
        let size = getxattr(path, attrName, nil, 0, 0, 0)
        guard size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size + 1)
        let result = getxattr(path, attrName, &buffer, size, 0, 0)
        guard result == size else { return nil }
        return String(bytes: buffer.prefix(size).map { UInt8(bitPattern: $0) }, encoding: .utf8)
    }
}
