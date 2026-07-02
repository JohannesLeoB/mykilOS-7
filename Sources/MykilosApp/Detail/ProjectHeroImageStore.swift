import Foundation
import AppKit
import UniformTypeIdentifiers

// MARK: - ProjectHeroImageStore
// Lokales, nutzer-eigenes Hero-Bild je Projekt (Application Support/mykilOS6/hero-images/
// <projektnummer>.png). Rein lokal — kein Drive, kein Airtable, keine geteilten Daten.
// Jeder Nutzer wählt sein eigenes Projekt-Titelbild.
enum ProjectHeroImageStore {
    private static var dir: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let d = base.appendingPathComponent("mykilOS6/hero-images", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    private static func safeName(_ s: String) -> String {
        let ok = s.map { ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") ? $0 : "_" }
        return String(ok)
    }

    static func url(for projectNumber: String) -> URL {
        dir.appendingPathComponent("\(safeName(projectNumber)).png")
    }

    static func image(for projectNumber: String) -> NSImage? {
        let u = url(for: projectNumber)
        guard FileManager.default.fileExists(atPath: u.path) else { return nil }
        return NSImage(contentsOf: u)
    }

    static func hasImage(for projectNumber: String) -> Bool {
        FileManager.default.fileExists(atPath: url(for: projectNumber).path)
    }

    static func clear(for projectNumber: String) {
        try? FileManager.default.removeItem(at: url(for: projectNumber))
    }

    /// Öffnet einen Datei-Dialog, wählt ein Bild, speichert es als PNG. true bei Erfolg.
    @MainActor
    static func pickAndSave(for projectNumber: String) -> Bool {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "Als Hero-Bild"
        guard panel.runModal() == .OK, let src = panel.url,
              let img = NSImage(contentsOf: src),
              let tiff = img.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return false }
        try? png.write(to: url(for: projectNumber))
        return true
    }
}
