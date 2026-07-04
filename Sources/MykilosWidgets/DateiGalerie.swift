import SwiftUI
import AppKit
import MykilosDesign
import MykilosServices

// MARK: - DateiGalerie (Galerie-Flug · Akt 1)
//
// Finder-artige Kachel-Galerie für JEDE Datei-Sammlung der App: echte Mini-
// Inhalte (ThumbnailStore), Hover-Anheben mit Quick-Actions (MykMotion-Sprache),
// stufenlose Kachelgröße (Finder-Slider). Read-only; Aktionen kommen als
// Closures vom Aufrufer (Vorschau/Öffnen/optional Korb) — die Galerie selbst
// schreibt nie.

// MARK: DateiKachel

public struct DateiKachel: View {
    public let file: GoogleDriveFile
    public var subtitle: String? = nil
    public var localURL: URL? = nil
    public var side: CGFloat = 140
    public var onTap: () -> Void = {}
    public var onOpen: (() -> Void)? = nil

    public init(file: GoogleDriveFile, subtitle: String? = nil, localURL: URL? = nil,
                side: CGFloat = 140, onTap: @escaping () -> Void = {},
                onOpen: (() -> Void)? = nil) {
        self.file = file
        self.subtitle = subtitle
        self.localURL = localURL
        self.side = side
        self.onTap = onTap
        self.onOpen = onOpen
    }

    @State private var thumbnail: NSImage?
    @State private var isHovered = false

    public var body: some View {
        Button(action: onTap) {
            VStack(spacing: MykSpace.s2) {
                bildflaeche
                Text(file.name)
                    .font(.mykMono(side < 110 ? 8.5 : 9.5))
                    .foregroundStyle(MykColor.inkSoft.color)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: side)
                if let subtitle, side >= 130 {
                    Text(subtitle)
                        .font(.mykMono(8.5))
                        .foregroundStyle(MykColor.faint.color)
                        .lineLimit(1)
                        .frame(width: side)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? MykMotion.hoverScale : 1)
        .animation(MykMotion.hover, value: isHovered)
        .onHover { isHovered = $0 }
        .task(id: "\(file.id)#\(Int(side))") {
            thumbnail = await ThumbnailStore.shared.thumbnail(for: file, localURL: localURL, side: side)
        }
    }

    private var bildflaeche: some View {
        ZStack {
            RoundedRectangle(cornerRadius: MykRadius.md)
                .fill(MykColor.paper2.color)
            if let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: side, height: side)
                    .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
            } else {
                Image(systemName: file.iconName)
                    .font(.system(size: side * 0.3))   // skaliert mit Kachel — bewusste Token-Ausnahme (dokumentiert): dynamische Größe
                    .foregroundStyle(MykColor.faint.color)
            }
            // Hover: sanfte Abdunklung unten + Quick-Action.
            if isHovered, let onOpen {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            onOpen()
                        } label: {
                            Image(systemName: "arrow.up.right.square.fill")
                                .font(.mykHeadline)
                                .foregroundStyle(.white)
                                .shadow(radius: 3)
                        }
                        .buttonStyle(.plain)
                        .help("Öffnen")
                        .padding(MykSpace.s3)
                    }
                    Spacer()
                }
            }
        }
        .frame(width: side, height: side)
        .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1))
        .shadow(color: .black.opacity(isHovered ? MykMotion.hoverShadow.opacity : MykMotion.restShadow.opacity),
                radius: isHovered ? MykMotion.hoverShadow.radius : MykMotion.restShadow.radius,
                y: isHovered ? MykMotion.hoverShadow.y : MykMotion.restShadow.y)
    }
}

// MARK: - DateiGalerieGrid

public struct DateiGalerieGrid: View {
    public struct Eintrag: Identifiable {
        public let file: GoogleDriveFile
        public let subtitle: String?
        public let localURL: URL?
        public var id: String { file.id }
        public init(file: GoogleDriveFile, subtitle: String? = nil, localURL: URL? = nil) {
            self.file = file; self.subtitle = subtitle; self.localURL = localURL
        }
    }

    public let eintraege: [Eintrag]
    @Binding public var kachelSeite: CGFloat
    public var onTap: (Eintrag) -> Void
    public var onOpen: ((Eintrag) -> Void)? = nil

    public init(eintraege: [Eintrag], kachelSeite: Binding<CGFloat>,
                onTap: @escaping (Eintrag) -> Void, onOpen: ((Eintrag) -> Void)? = nil) {
        self.eintraege = eintraege
        self._kachelSeite = kachelSeite
        self.onTap = onTap
        self.onOpen = onOpen
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: kachelSeite, maximum: kachelSeite + 40),
                                         spacing: MykSpace.s5)],
                      spacing: MykSpace.s6) {
                ForEach(eintraege) { eintrag in
                    DateiKachel(
                        file: eintrag.file, subtitle: eintrag.subtitle,
                        localURL: eintrag.localURL, side: kachelSeite,
                        onTap: { onTap(eintrag) },
                        onOpen: onOpen.map { open in { open(eintrag) } })
                }
            }
            .padding(.vertical, MykSpace.s4)
            .animation(MykMotion.spring, value: kachelSeite)
        }
    }
}

// MARK: - KachelGroessenSlider (Finder-Stil, unten rechts)

public struct KachelGroessenSlider: View {
    @Binding public var kachelSeite: CGFloat

    public init(kachelSeite: Binding<CGFloat>) {
        self._kachelSeite = kachelSeite
    }

    public var body: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: "square.grid.3x3")
                .font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
            Slider(value: $kachelSeite, in: 90...240)
                .frame(width: 110)
                .controlSize(.mini)
            Image(systemName: "square")
                .font(.mykCaption).foregroundStyle(MykColor.faint.color)
        }
        .help("Kachelgröße")
        .accessibilityLabel("Kachelgröße")
    }
}
