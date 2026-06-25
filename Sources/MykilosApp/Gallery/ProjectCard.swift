import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - ProjectCard
// Die Projektkachel in der Galerie. Image-led: Projekte sind Bildflächen,
// keine Tabellenzeilen. Hero-Gradient aus dem Projekt-Archetyp.
struct ProjectCard: View {
    let project: Project
    let customer: Customer?
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                heroArea
                infoArea
            }
            .background(MykColor.card.color)
            .clipShape(RoundedRectangle(cornerRadius: MykRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MykRadius.lg)
                    .stroke(MykColor.line.color, lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(isHovered ? 0.1 : 0.04),
                radius: isHovered ? 20 : 6,
                x: 0, y: isHovered ? 8 : 2
            )
            .scaleEffect(isHovered ? 1.015 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    // MARK: Hero-Bereich (image-led)
    private var heroArea: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient aus Projekt-Archetyp
            LinearGradient(
                colors: heroGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 140)
            // Feine Raster-Textur
            .overlay(
                GridTexture()
                    .opacity(0.35)
            )
            // Projekt-Kürzel oben rechts
            VStack {
                HStack {
                    Spacer()
                    Text(project.projectNumber)
                        .font(.mykMono(10))
                        .foregroundStyle(.white.opacity(0.82))
                        .padding(.horizontal, MykSpace.s4)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(.black.opacity(0.22)))
                        .padding(MykSpace.s4)
                }
                Spacer()
            }
            // Titel und Kind
            VStack(alignment: .leading, spacing: 4) {
                if project.isAddendum {
                    addendumBadge
                }
                Text(project.title)
                    .font(.mykHeadline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(MykSpace.s5)
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .top, endPoint: .bottom
                )
            )
        }
        .frame(height: 140)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: MykRadius.lg, bottomLeadingRadius: 0,
            bottomTrailingRadius: 0, topTrailingRadius: MykRadius.lg
        ))
    }

    // MARK: Info-Bereich
    private var infoArea: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            HStack {
                if let customer {
                    Text(customer.name)
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.inkSoft.color)
                }
                Spacer()
                kindChip
            }
            if let phase = project.phase {
                Text(phase)
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.muted.color)
                    .tracking(0.5)
            }
        }
        .padding(MykSpace.s5)
    }

    // MARK: Helfer
    private var addendumBadge: some View {
        Text("Nachtrag")
            .font(.mykMono(9))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(.black.opacity(0.3)))
    }

    private var kindChip: some View {
        Text(project.kind.displayLabel)
            .font(.mykMono(9.5))
            .foregroundStyle(kindColor)
            .padding(.horizontal, MykSpace.s3).padding(.vertical, 4)
            .background(
                Capsule().fill(kindColor.opacity(0.12))
            )
    }

    private var heroGradient: [Color] {
        switch project.kind {
        case .kitchen:      [Color(hex: 0xD9B9A4), Color(hex: 0x9A8F7E)]
        case .lighting:     [Color(hex: 0xB8C4A8), Color(hex: 0x7A8F6A)]
        case .addendum:     [Color(hex: 0xB8C4D4), Color(hex: 0x6A7A8F)]
        case .lead:         [Color(hex: 0xD4C4B8), Color(hex: 0x9A8A7A)]
        case .quote:        [Color(hex: 0xC4B8D4), Color(hex: 0x8A7A9A)]
        case .studioInternal:[Color(hex: 0xC4C4C4), Color(hex: 0x8A8A8A)]
        }
    }

    private var kindColor: Color { project.kind.accentColor }
}

// MARK: - Raster-Textur (dekorativ, kein Text)
private struct GridTexture: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 48
            ctx.stroke(
                { () -> Path in
                    var p = Path()
                    var x: CGFloat = 0
                    while x <= size.width {
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: size.height))
                        x += step
                    }
                    var y: CGFloat = 0
                    while y <= size.height {
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: size.width, y: y))
                        y += step
                    }
                    return p
                }(),
                with: .color(.white.opacity(0.3)),
                lineWidth: 0.5
            )
        }
    }
}

// MARK: - ProjectKind Extensions (Display)
extension ProjectKind {
    var displayLabel: String {
        switch self {
        case .kitchen:       "Küche"
        case .lighting:      "Licht"
        case .addendum:      "Nachtrag"
        case .lead:          "Lead"
        case .quote:         "Angebot"
        case .studioInternal:"Intern"
        }
    }

    var accentColor: Color {
        switch self {
        case .kitchen:       MykColor.drive.color    // Terrakotta
        case .lighting:      MykColor.people.color   // Salbei
        case .addendum:      MykColor.cash.color     // Tiefblau
        case .lead:          MykColor.muted.color
        case .quote:         MykColor.tasks.color    // Ocker
        case .studioInternal:MykColor.faint.color
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
