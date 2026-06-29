import Foundation
import AppKit
import MykilosServices

// MARK: - LocalDriveRootResolver
// Löst eine Google-Drive-Ordner-ID (z.B. "13ITPqAMdz6JrS13u8y7JvkTVXAWznA_S")
// auf einen lokal materialisierten Pfad im Google-Drive-File-Provider auf und öffnet
// Dateien/Ordner lokal im Finder/in der Vorschau (statt im Browser).
//
// Strategie für einen Ordner (in Reihenfolge):
// 1. Expliziter Pfad-Hinweis (Airtable `driveFolderPath`), falls gesetzt & vorhanden.
// 2. Alle Google-Drive-Roots unter ~/Library/CloudStorage/ scannen
//    (ein Account = ein Root-Ordner "GoogleDrive-<email>").
// 3. In bekannten PROJEKTE-Unterordnern des Roots das xattr
//    `com.google.drivefs.item-id#S` lesen (via DriveLocalResolver) und ersten
//    Treffer mit passender ID zurückgeben.
//
// Strategie für eine Datei: erst den Projektordner auflösen (oben), dann innerhalb
// dieses Teilbaums per Drive-Item-ID (xattr) bzw. Namens-Fallback suchen.
//
// Keine Security-Scoped Bookmarks nötig: CloudStorage-Ordner liegen unterm
// Heimverzeichnis und sind für die (nicht-sandboxed) App direkt lesbar.
//
// Einschränkungen:
// - Ordner/Datei müssen lokal materialisiert sein (heruntergeladen, nicht nur online).
// - Zwei Drive-Accounts: beide Roots werden geprüft; der aktuelle (ohne Datum-Suffix)
//   gewinnt bei Namensgleichheit.
@MainActor
public final class LocalDriveRootResolver {
    public static let shared = LocalDriveRootResolver()
    private init() {}

    // MARK: - Ordner-Auflösung

    /// Lokaler URL für einen Projektordner. `explicitPath` (Airtable `driveFolderPath`)
    /// hat Vorrang, falls gesetzt und tatsächlich vorhanden. Sonst xattr-Auflösung.
    /// `nil`, wenn nichts lokal materialisiert ist.
    public func localURL(forDriveFolderID folderID: String, explicitPath: String? = nil) -> URL? {
        if let explicitPath, explicitPath.isEmpty == false {
            let url = URL(fileURLWithPath: explicitPath)
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        for root in googleDriveRoots() {
            if let url = scan(root: root, lookingFor: folderID) { return url }
        }
        return nil
    }

    // MARK: - Datei-Auflösung

    /// Lokaler URL einer Datei innerhalb eines Projektordners. Löst zuerst den
    /// Projektordner auf, sucht dann im Teilbaum nach der Drive-Item-ID (xattr),
    /// Namens-Fallback `fileName`. `nil`, wenn nicht lokal vorhanden.
    public func localURL(forFileID fileID: String,
                         fileName: String?,
                         inProjectFolderID projectFolderID: String,
                         explicitProjectPath: String? = nil) -> URL? {
        guard let projectRoot = localURL(forDriveFolderID: projectFolderID,
                                         explicitPath: explicitProjectPath) else { return nil }
        return DriveLocalResolver.find(itemID: fileID, in: projectRoot, fileName: fileName)
    }

    // MARK: - Öffnen / Zeigen

    /// Zeigt einen lokal aufgelösten Ordner/eine Datei im Finder (selektiert).
    /// Fällt — wenn nicht lokal vorhanden — auf `fallbackURL` (z. B. webViewLink) zurück.
    public func revealInFinder(driveFolderID: String, explicitPath: String? = nil, fallbackURL: URL?) {
        if let local = localURL(forDriveFolderID: driveFolderID, explicitPath: explicitPath) {
            NSWorkspace.shared.selectFile(local.path,
                                          inFileViewerRootedAtPath: local.deletingLastPathComponent().path)
        } else if let url = fallbackURL {
            NSWorkspace.shared.open(url)
        }
    }

    /// Zeigt einen bereits aufgelösten lokalen Pfad im Finder (selektiert).
    public func revealInFinder(localURL url: URL) {
        NSWorkspace.shared.selectFile(url.path,
                                      inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
    }

    /// Öffnet eine einzelne lokale Datei (Standard-App, z. B. Vorschau).
    /// Fällt auf `fallbackURL` (webViewLink → Browser) zurück.
    public func openFile(localURL url: URL?, fallbackURL: URL?) {
        if let local = url, FileManager.default.fileExists(atPath: local.path) {
            NSWorkspace.shared.open(local)
        } else if let fallback = fallbackURL {
            NSWorkspace.shared.open(fallback)
        }
    }

    // MARK: - Drive Roots

    /// Alle Google-Drive-File-Provider-Roots unter ~/Library/CloudStorage/.
    /// Aktueller Root zuerst (kein Datum-Suffix = aktuell, "(…)"-Suffix = veraltet).
    public func googleDriveRoots() -> [URL] {
        let cloudStorage = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/CloudStorage", isDirectory: true)
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: cloudStorage,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ) else { return [] }
        return contents
            .filter { $0.lastPathComponent.hasPrefix("GoogleDrive-") }
            .sorted { a, _ in !a.lastPathComponent.contains("(") }
    }

    // MARK: - Ordner-Scan (delegiert ans Foundation-only DriveLocalResolver)

    /// Sucht in den bekannten PROJEKTE-Containern eines Roots nach einem direkten
    /// Kind mit passender Drive-Item-ID.
    func scan(root: URL, lookingFor folderID: String) -> URL? {
        let candidates: [URL] = [
            root.appendingPathComponent("Geteilte Ablagen/MYKILOS Team/PROJEKTE", isDirectory: true),
            root.appendingPathComponent("MYKILOS Team/PROJEKTE", isDirectory: true),
            root.appendingPathComponent("Meine Ablage", isDirectory: true),
        ]
        for candidate in candidates {
            if let found = DriveLocalResolver.firstChild(of: candidate, withItemID: folderID) {
                return found
            }
        }
        return nil
    }
}
