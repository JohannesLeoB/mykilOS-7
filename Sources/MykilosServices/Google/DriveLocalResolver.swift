import Foundation

// MARK: - DriveLocalResolver (Mandate B — lokales Drive-Routing, Foundation-only)
//
// Löst Google-Drive-Item-IDs auf lokal materialisierte Pfade des Google-Drive-
// File-Providers auf, indem es das erweiterte Attribut `com.google.drivefs.item-id#S`
// liest (jede von Drive heruntergeladene Datei/jeder Ordner trägt es).
//
// Bewusst Foundation-only (kein AppKit, kein Netzwerk) → in MykilosServices testbar:
// die Tests setzen das xattr mit `setxattr` auf einem Temp-Baum und beweisen die
// Auflösungslogik real (statt sie nur als Proof-of-Existence stehen zu lassen).
//
// AppKit-Teile (Finder öffnen/zeigen) und die CloudStorage-Root-Suche leben in
// `LocalDriveRootResolver` (MykilosApp), das diese Primitive nutzt.
public enum DriveLocalResolver {

    /// xattr-Name des Google-Drive-File-Stream. `#S` = String-typisiertes Attribut.
    public static let xattrName = "com.google.drivefs.item-id#S"

    /// Liest die Drive-Item-ID aus dem xattr. `nil`, wenn nicht vorhanden.
    public static func driveItemID(at url: URL) -> String? {
        let path = url.path
        let size = getxattr(path, xattrName, nil, 0, 0, 0)
        guard size > 0 else { return nil }
        var buffer = [UInt8](repeating: 0, count: size)
        let read = getxattr(path, xattrName, &buffer, size, 0, 0)
        guard read == size else { return nil }
        return String(bytes: buffer, encoding: .utf8)?
            .trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
    }

    /// Erstes DIREKTES Kind von `directory`, dessen Drive-Item-ID == `itemID`.
    /// Eine Ebene tief — für Projektordner (direkte Kinder von PROJEKTE) ausreichend.
    public static func firstChild(of directory: URL, withItemID itemID: String) -> URL? {
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return nil }
        return items.first { driveItemID(at: $0) == itemID }
    }

    /// Sucht rekursiv (bis `maxDepth`) innerhalb `root` nach einem Item mit passender
    /// Drive-Item-ID. Findet kein xattr-Treffer, greift — falls `fileName` gesetzt —
    /// ein Namens-Fallback (exakter `lastPathComponent`). `nil`, wenn nichts passt.
    ///
    /// Auf den Projektordner als `root` begrenzt, damit die Suche klein bleibt
    /// (kein Scan über alle Projekte). Bricht beim ersten Treffer ab.
    public static func find(itemID: String,
                            in root: URL,
                            fileName: String? = nil,
                            maxDepth: Int = 6) -> URL? {
        var nameFallback: URL?

        func walk(_ directory: URL, depth: Int) -> URL? {
            guard depth <= maxDepth,
                  let items = try? FileManager.default.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: .skipsHiddenFiles
                  ) else { return nil }
            for item in items {
                if driveItemID(at: item) == itemID { return item }      // bester Treffer
                if let fileName, nameFallback == nil,
                   item.lastPathComponent == fileName { nameFallback = item }
            }
            // erst Breite (alle Treffer dieser Ebene), dann Tiefe
            for item in items {
                let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                if isDir, let hit = walk(item, depth: depth + 1) { return hit }
            }
            return nil
        }

        return walk(root, depth: 0) ?? nameFallback
    }
}
