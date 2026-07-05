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
    /// Name des unmittelbaren Eltern-Ordners (Herkunft, D3). `nil` → keine Marke.
    public var herkunftOrdner: String?
    public var side: CGFloat = 140
    public var isSelected: Bool = false
    public var onSelect: () -> Void = {}      // Einfachklick → anwählen
    public var onPreview: () -> Void = {}     // Doppelklick / Leertaste → Vollvorschau
    public var onOpen: (() -> Void)? = nil    // Hover-Button → extern öffnen

    public init(file: GoogleDriveFile, subtitle: String? = nil, localURL: URL? = nil,
                herkunftOrdner: String? = nil,
                side: CGFloat = 140, isSelected: Bool = false,
                onSelect: @escaping () -> Void = {}, onPreview: @escaping () -> Void = {},
                onOpen: (() -> Void)? = nil) {
        self.file = file
        self.subtitle = subtitle
        self.localURL = localURL
        self.herkunftOrdner = herkunftOrdner
        self.side = side
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onPreview = onPreview
        self.onOpen = onOpen
    }

    @State private var thumbnail: NSImage?
    @State private var isHovered = false

    public var body: some View {
        Button(action: onSelect) {
            VStack(spacing: MykSpace.s2) {
                bildflaeche
                Text(file.name)
                    .font(.mykMono(side < 110 ? 8.5 : 9.5))
                    .foregroundStyle(MykColor.inkSoft.color)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: side)
                // Herkunft (D3): Farbpunkt je Ordner-Kategorie + Ordnername als
                // muted Mono-Chip (VERSAL). In engen Kacheln nur der Farbpunkt.
                if herkunftOrdner != nil {
                    HerkunftMarke(folderName: herkunftOrdner, punktNur: side < 130)
                        .frame(width: side)
                }
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
        .simultaneousGesture(TapGesture(count: 2).onEnded { onPreview() })
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
        .overlay(RoundedRectangle(cornerRadius: MykRadius.md)
            .stroke(isSelected ? MykColor.brand.color : MykColor.line.color,
                    lineWidth: isSelected ? 2.5 : 1))
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
        /// Name des unmittelbaren Eltern-Ordners (Herkunft, D3). `nil` → keine Marke.
        public let herkunftOrdner: String?
        public var id: String { file.id }
        public init(file: GoogleDriveFile, subtitle: String? = nil, localURL: URL? = nil,
                    herkunftOrdner: String? = nil) {
            self.file = file; self.subtitle = subtitle; self.localURL = localURL
            self.herkunftOrdner = herkunftOrdner
        }
    }

    public let eintraege: [Eintrag]
    @Binding public var kachelSeite: CGFloat
    public var onPreview: (Eintrag) -> Void          // Vollvorschau (Leertaste/Doppelklick)
    public var onOpen: ((Eintrag) -> Void)? = nil    // extern öffnen (Hover-Button)
    public var onSelect: ((Eintrag) -> Void)? = nil  // optionaler Anwahl-Hook

    @State private var selektiert: String?

    public init(eintraege: [Eintrag], kachelSeite: Binding<CGFloat>,
                onPreview: @escaping (Eintrag) -> Void,
                onOpen: ((Eintrag) -> Void)? = nil,
                onSelect: ((Eintrag) -> Void)? = nil) {
        self.eintraege = eintraege
        self._kachelSeite = kachelSeite
        self.onPreview = onPreview
        self.onOpen = onOpen
        self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: kachelSeite, maximum: kachelSeite + 40),
                                         spacing: MykSpace.s5)],
                      spacing: MykSpace.s6) {
                ForEach(eintraege) { eintrag in
                    DateiKachel(
                        file: eintrag.file, subtitle: eintrag.subtitle,
                        localURL: eintrag.localURL, herkunftOrdner: eintrag.herkunftOrdner,
                        side: kachelSeite,
                        isSelected: selektiert == eintrag.id,
                        onSelect: { selektiert = eintrag.id; onSelect?(eintrag) },
                        onPreview: { selektiert = eintrag.id; onPreview(eintrag) },
                        onOpen: onOpen.map { open in { open(eintrag) } })
                }
            }
            .padding(.vertical, MykSpace.s4)
            .animation(MykMotion.spring, value: kachelSeite)
        }
        .focusable()
        // Finder-Muster: angewählte Datei + Leertaste → volle Fenster-Vorschau.
        .onKeyPress(.space) {
            guard let selektiert, let e = eintraege.first(where: { $0.id == selektiert })
            else { return .ignored }
            onPreview(e)
            return .handled
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
