import SwiftUI
import AppKit
import QuickLookThumbnailing
import MykilosServices

// MARK: - ThumbnailStore (Galerie-Flug · echte Mini-Inhalte für jede Datei)
//
// Liefert für eine Drive-Datei ein echtes Inhalts-Thumbnail — nie nur ein Typ-Icon:
//   1. LOKAL materialisiert → QuickLook (`QLThumbnailGenerator`, dieselbe Engine wie
//      der Finder; kann PDF, Bilder, .numbers, Video …).
//   2. Sonst REMOTE → Drive `thumbnailLink` (kurzlebige, authfreie Vorschau-URL).
// Ergebnisse landen in einem NSCache (Schlüssel: fileID + Kachelseite) — Lean-Regel:
// beim Scrollen wird nie neu generiert/gefetcht. Read-only, kein Schreiben.
@MainActor
public final class ThumbnailStore {
    public static let shared = ThumbnailStore()

    private let cache = NSCache<NSString, NSImage>()
    /// Negativ-Merker: Dateien ohne beschaffbares Thumbnail nicht endlos neu versuchen.
    private var misses = Set<String>()

    private init() {
        cache.countLimit = 600
    }

    public func thumbnail(for file: GoogleDriveFile, localURL: URL?, side: CGFloat) async -> NSImage? {
        // Größen-Stufe (128er-Raster), damit Slider-Zwischenwerte den Cache nicht sprengen.
        let bucket = max(128, Int((side * 2 / 128).rounded(.up)) * 128)
        let key = "\(file.id)#\(bucket)" as NSString
        if let hit = cache.object(forKey: key) { return hit }
        guard misses.contains(key as String) == false else { return nil }

        var image: NSImage?
        if let localURL, FileManager.default.fileExists(atPath: localURL.path) {
            image = await Self.quickLookThumbnail(url: localURL, side: CGFloat(bucket))
        }
        if image == nil, let link = file.thumbnailLink, let url = URL(string: link) {
            image = await Self.remoteThumbnail(url: url)
        }
        if let image {
            cache.setObject(image, forKey: key)
        } else {
            misses.insert(key as String)
        }
        return image
    }

    // MARK: Quellen (nonisolated — Arbeit läuft off-MainActor)

    private nonisolated static func quickLookThumbnail(url: URL, side: CGFloat) async -> NSImage? {
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: side, height: side),
            scale: 2,
            representationTypes: .thumbnail)
        let rep = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
        return rep?.nsImage
    }

    private nonisolated static func remoteThumbnail(url: URL) async -> NSImage? {
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? true
        else { return nil }
        return NSImage(data: data)
    }
}
