import Foundation
import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign

// MARK: - MoodboardPort (Wirbelsäule C2, §4 „Erste native Ports")
//
// Zweiter nativer CheckoutPort: legt die aufgelösten Bild-Picks eines WorkBaskets
// in ein einfaches Grid und rendert es via SwiftUI `ImageRenderer` (macOS 13+)
// zu PNG-`Data`.
//
// SCOPE-GRENZE (C2, siehe HANDOFF §3):
//   - KEINE UI-Verdrahtung — die interne `MoodboardBoardView` ist NUR die
//     Render-Vorlage für `ImageRenderer`, kein Screen.
//   - KEIN externer Write. `execute()` liefert PNG-`Data` im
//     `CheckoutResult.nutzlast`; die Ablage ist ein separater Schritt.
//
// Design-Disziplin: nur `MykColor`/`MykSpace`/`Font.myk…`-Tokens, kein
// `Color(red:)`, kein `.font(.system(...))`.
public struct MoodboardPort: CheckoutPort {

    public let id: PortID
    public let name: String

    public init(id: PortID = PortID("moodboard"), name: String = "Moodboard (PNG)") {
        self.id = id
        self.name = name
    }

    public func erlaubteInhaltsArten() -> Set<InhaltsArt> {
        [.bilder, .material, .zeichnungen]
    }

    // MARK: - Vorschau

    public func preview(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutPreview {
        let anzahl = basket.picks.count
        let spalten = Self.spalten(fuer: anzahl)
        var warnungen: [String] = []
        if anzahl == 0 {
            warnungen.append("Keine Bilder im Korb — Board bleibt leer.")
        }
        let zusammenfassung =
            "Moodboard mit \(anzahl) Bild\(anzahl == 1 ? "" : "ern"), Layout \(spalten)-spaltig (PNG)."
        return CheckoutPreview(zusammenfassung: zusammenfassung, warnungen: warnungen)
    }

    // MARK: - Ausführung (rendert PNG-Data, schreibt NICHTS weg)

    public func execute(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutResult {
        // Picks materialisieren und in NSImages / Platzhalter-Kacheln übersetzen.
        var kacheln: [MoodboardKachel] = []
        for pick in basket.picks {
            let inhalt = try await pick.resolve()
            let bild = Self.bild(aus: inhalt)
            kacheln.append(
                MoodboardKachel(
                    titel: pick.snapshot.bezeichnung,
                    bild: bild
                )
            )
        }

        let titel = Self.titel(fuer: basket, ziel: ziel)
        let spalten = Self.spalten(fuer: kacheln.count)

        // ImageRenderer ist @MainActor — auf den MainActor hüpfen.
        let data = try await Self.renderPNG(
            titel: titel,
            projektNummer: basket.projektNummer,
            kacheln: kacheln,
            spalten: spalten
        )

        return CheckoutResult(
            erfolg: true,
            referenz: basket.id.description,
            meldung: "Moodboard „\(titel)“ gerendert (\(data.count) Bytes, \(kacheln.count) Kachel\(kacheln.count == 1 ? "" : "n")).",
            nutzlast: data
        )
    }

    // MARK: - Render (MainActor)

    @MainActor
    private static func renderPNG(
        titel: String,
        projektNummer: String,
        kacheln: [MoodboardKachel],
        spalten: Int
    ) throws -> Data {
        let view = MoodboardBoardView(
            titel: titel,
            projektNummer: projektNummer,
            kacheln: kacheln,
            spalten: spalten
        )
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        guard let nsImage = renderer.nsImage,
              let tiff = nsImage.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            throw MoodboardPortError.renderingFehlgeschlagen
        }
        return png
    }

    // MARK: - Helfer (rein)

    static func titel(fuer basket: WorkBasket, ziel: PortZiel) -> String {
        if let t = ziel.parameter["titel"], t.isEmpty == false {
            return t
        }
        return "Moodboard \(basket.projektNummer)"
    }

    /// Spaltenzahl abhängig von der Bildanzahl (1 → 1, 2–4 → 2, sonst 3).
    static func spalten(fuer anzahl: Int) -> Int {
        switch anzahl {
        case 0, 1: return 1
        case 2...4: return 2
        default: return 3
        }
    }

    /// Materialisiert ein NSImage aus dem aufgelösten Pick-Inhalt, falls möglich.
    static func bild(aus inhalt: PickContent) -> NSImage? {
        switch inhalt {
        case .bytes(let data, _):
            return NSImage(data: data)
        case .datei(let url):
            return NSImage(contentsOf: url)
        case .text, .kontaktkarte, .keiner:
            return nil
        }
    }
}

// MARK: - Fehler

public enum MoodboardPortError: Error, Equatable, Sendable {
    case renderingFehlgeschlagen
}

// MARK: - Interne Render-Modelle + View
// NUR Render-Vorlage für ImageRenderer — kein UI-Screen, keine Verdrahtung.

struct MoodboardKachel: Identifiable {
    let id = UUID()
    let titel: String
    let bild: NSImage?
}

struct MoodboardBoardView: View {
    let titel: String
    let projektNummer: String
    let kacheln: [MoodboardKachel]
    let spalten: Int

    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(220), spacing: MykSpace.s4), count: max(spalten, 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            VStack(alignment: .leading, spacing: MykSpace.s2) {
                Text(titel)
                    .font(.mykTitle)
                    .foregroundStyle(MykColor.brand.color)
                Text("Projekt \(projektNummer)")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            }

            if kacheln.isEmpty {
                Text("Keine Bilder im Korb")
                    .font(.mykBody)
                    .foregroundStyle(MykColor.muted.color)
                    .frame(width: 220, height: 160)
                    .background(MykColor.paper2.color)
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: MykSpace.s4) {
                    ForEach(kacheln) { kachel in
                        kachelView(kachel)
                    }
                }
            }
        }
        .padding(MykSpace.s6)
        .background(MykColor.paper.color)
    }

    @ViewBuilder
    private func kachelView(_ kachel: MoodboardKachel) -> some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Group {
                if let bild = kachel.bild {
                    Image(nsImage: bild)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        MykColor.bone.color
                        Text(kachel.titel)
                            .font(.mykCaption)
                            .foregroundStyle(MykColor.muted.color)
                            .padding(MykSpace.s2)
                    }
                }
            }
            .frame(width: 220, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))

            Text(kachel.titel)
                .font(.mykCaption)
                .foregroundStyle(MykColor.ink.color)
                .lineLimit(1)
        }
    }
}
