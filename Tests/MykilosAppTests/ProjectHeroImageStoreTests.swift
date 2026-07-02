import Testing
import Foundation
import AppKit
@testable import MykilosApp

// Cold-Start-/Robustheitstests für das lokale Hero-Bild:
// (1) große Bilder werden beim Speichern gedeckelt (Layout-Schutz),
// (2) kleine Bilder bleiben unverändert (kein Hochskalieren),
// (3) Fokus-Punkt überlebt Neustart + wird auf 0…1 geklemmt.
@MainActor
struct ProjectHeroImageStoreTests {

    private func makeImage(width: Int, height: Int) -> NSImage {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        rep.size = NSSize(width: width, height: height)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSColor.orange.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        NSGraphicsContext.restoreGraphicsState()
        let img = NSImage(size: NSSize(width: width, height: height))
        img.addRepresentation(rep)
        return img
    }

    private func pixelSize(_ image: NSImage) -> (Int, Int)? {
        guard let rep = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first
            ?? image.tiffRepresentation.flatMap({ NSBitmapImageRep(data: $0) }) else { return nil }
        return (rep.pixelsWide, rep.pixelsHigh)
    }

    @Test func grossesBildWirdBeimSpeichernHeruntergerechnet() throws {
        let nr = "ZZ-TEST-HERO-DOWNSCALE"
        ProjectHeroImageStore.clear(for: nr)
        defer { ProjectHeroImageStore.clear(for: nr) }

        let big = makeImage(width: 4000, height: 3000)
        try ProjectHeroImageStore.save(big, for: nr)

        let loaded = try #require(ProjectHeroImageStore.image(for: nr))
        let (w, h) = try #require(pixelSize(loaded))
        #expect(max(w, h) == Int(ProjectHeroImageStore.maxPixelDimension))   // längere Kante am Deckel
        #expect(abs(Double(w) / Double(h) - 4.0 / 3.0) < 0.02)               // Seitenverhältnis erhalten
    }

    @Test func kleinesBildBleibtUnveraendert() throws {
        let nr = "ZZ-TEST-HERO-SMALL"
        ProjectHeroImageStore.clear(for: nr)
        defer { ProjectHeroImageStore.clear(for: nr) }

        let small = makeImage(width: 800, height: 600)
        try ProjectHeroImageStore.save(small, for: nr)

        let loaded = try #require(ProjectHeroImageStore.image(for: nr))
        let (w, h) = try #require(pixelSize(loaded))
        #expect(w == 800 && h == 600)
    }

    @Test func fokusPunktUeberlebtNeustartUndWirdGeklemmt() throws {
        let nr = "ZZ-TEST-HERO-FOCAL"
        ProjectHeroImageStore.clear(for: nr)
        defer { ProjectHeroImageStore.clear(for: nr) }

        // Ohne Datei → Mitte
        #expect(ProjectHeroImageStore.focalPoint(for: nr) == CGPoint(x: 0.5, y: 0.5))

        try ProjectHeroImageStore.setFocalPoint(CGPoint(x: 0.25, y: 0.8), for: nr)
        let p = ProjectHeroImageStore.focalPoint(for: nr)
        #expect(abs(p.x - 0.25) < 0.001)
        #expect(abs(p.y - 0.8) < 0.001)

        // Außerhalb 0…1 wird geklemmt
        try ProjectHeroImageStore.setFocalPoint(CGPoint(x: -1, y: 2), for: nr)
        let clamped = ProjectHeroImageStore.focalPoint(for: nr)
        #expect(clamped.x == 0.0 && clamped.y == 1.0)
    }
}
