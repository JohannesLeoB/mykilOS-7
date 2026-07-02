import Foundation
import AppKit
import UniformTypeIdentifiers

// MARK: - ProjectHeroImageStore
// Lokales, nutzer-eigenes Hero-Bild je Projekt (Application Support/mykilOS6/hero-images/
// <projektnummer>.png). Rein lokal — kein Drive, kein Airtable, keine geteilten Daten.
// Jeder Nutzer wählt sein eigenes Projekt-Titelbild.
//
// Zwei Härtungen (2026-07-02): (1) Bilder werden beim Import auf eine hero-taugliche
// Kantenlänge heruntergerechnet — große Fotos sprengten sonst Layout + Speicher.
// (2) Fokus-Punkt (0…1) je Projekt als Sidecar, damit der Hero-Ausschnitt gezielt
// zentriert werden kann.
enum ProjectHeroImageStore {
    /// Obergrenze für die längere Bildkante beim Import (Pixel). Retina-scharf für den
    /// Hero, aber gedeckelt — verhindert 6000-px-Fotos in der Layout-/Speicherkette.
    static let maxPixelDimension: CGFloat = 2400

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
        try? FileManager.default.removeItem(at: focalURL(for: projectNumber))
    }

    // MARK: - Fokus-Punkt (0…1, Default Mitte)
    // Sidecar <projektnummer>.focal mit Inhalt "x,y". Bestimmt, welcher Bildpunkt beim
    // Fill-Zuschnitt in die Hero-Mitte rückt. Fehlt die Datei → Mitte (0.5, 0.5).

    static func focalURL(for projectNumber: String) -> URL {
        dir.appendingPathComponent("\(safeName(projectNumber)).focal")
    }

    static func focalPoint(for projectNumber: String) -> CGPoint {
        guard let raw = try? String(contentsOf: focalURL(for: projectNumber), encoding: .utf8) else {
            return CGPoint(x: 0.5, y: 0.5)
        }
        let parts = raw.split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 2, let x = parts[0], let y = parts[1] else {
            return CGPoint(x: 0.5, y: 0.5)
        }
        return CGPoint(x: min(max(x, 0), 1), y: min(max(y, 0), 1))
    }

    static func setFocalPoint(_ point: CGPoint, for projectNumber: String) throws {
        let x = min(max(point.x, 0), 1)
        let y = min(max(point.y, 0), 1)
        try "\(x),\(y)".write(to: focalURL(for: projectNumber), atomically: true, encoding: .utf8)
    }

    // MARK: - Skalierung
    /// Rechnet ein Bild auf `maxPixelDimension` (längere Kante) herunter. Kleinere Bilder
    /// werden unverändert zurückgegeben (kein Hochskalieren).
    static func downscaledIfNeeded(_ image: NSImage) -> NSImage {
        let sourceRep = image.representations.compactMap { $0 as? NSBitmapImageRep }.first
            ?? image.tiffRepresentation.flatMap { NSBitmapImageRep(data: $0) }
        guard let rep = sourceRep else { return image }
        let w = CGFloat(rep.pixelsWide)
        let h = CGFloat(rep.pixelsHigh)
        let maxSide = max(w, h)
        guard maxSide > maxPixelDimension, maxSide > 0 else { return image }

        let scale = maxPixelDimension / maxSide
        let newW = max(1, Int((w * scale).rounded()))
        let newH = max(1, Int((h * scale).rounded()))

        guard let out = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: newW, pixelsHigh: newH,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { return image }
        out.size = NSSize(width: newW, height: newH)

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: out)
        image.draw(in: NSRect(x: 0, y: 0, width: newW, height: newH),
                   from: .zero, operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        let result = NSImage(size: NSSize(width: newW, height: newH))
        result.addRepresentation(out)
        return result
    }

    /// Skaliert (falls nötig) und schreibt das Bild als PNG. `throws` — der Schreibpfad
    /// meldet Fehler sichtbar (kein stiller `try?`).
    static func save(_ image: NSImage, for projectNumber: String) throws {
        let scaled = downscaledIfNeeded(image)
        guard let tiff = scaled.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try png.write(to: url(for: projectNumber))
    }

    /// Öffnet einen Datei-Dialog, wählt ein Bild, skaliert + speichert es als PNG.
    /// true bei Erfolg. Ein fehlgeschlagener Schreibvorgang → false (UI aktualisiert nicht).
    @MainActor
    static func pickAndSave(for projectNumber: String) -> Bool {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "Als Hero-Bild"
        guard panel.runModal() == .OK, let src = panel.url,
              let img = NSImage(contentsOf: src) else { return false }
        do {
            try save(img, for: projectNumber)
            return true
        } catch {
            return false
        }
    }
}
