import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - ProjectCard
// Die Projektkachel in der Galerie. Image-led: Projekte sind Bildflächen,
// keine Tabellenzeilen. Hero-Gradient aus dem Projekt-Archetyp.
struct ProjectCard: View {
    let project: Project
    let customer: Customer?
    let action: () -> Void

    @Environment(StudioContext.self) private var context
    @Environment(AppState.self) private var appState
    @State private var isHovered = false
    // Fix 2026-07-03 (Live-Fund Johannes): Hero-Bild-Upload lebte bisher nur auf der
    // Detailseite (ProjectHeroView) — die Galerie-Karte zeigte immer nur den Standard-
    // Gradient. Gleicher Store, gleiche Fokus-Offset-Logik wie dort, nur kleiner.
    @State private var heroImage: NSImage?
    @State private var focalPoint = CGPoint(x: 0.5, y: 0.5)

    private var isFavorite: Bool { appState.favorites.isFavorite(project.projectNumber) }

    private var signalCount: Int { context.signals(for: project.projectNumber).count }
    private var hasCriticalSignal: Bool {
        context.signals(for: project.projectNumber).contains {
            if case .deadlineNear = $0 { return true }
            if case .budgetThresholdCrossed(_, let r) = $0 { return r >= 0.9 }
            return false
        }
    }

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
        .task(id: project.projectNumber) {
            heroImage = ProjectHeroImageStore.image(for: project.projectNumber)
            focalPoint = ProjectHeroImageStore.focalPoint(for: project.projectNumber)
        }
    }

    // MARK: Hero-Bereich (image-led)
    private var heroArea: some View {
        ZStack(alignment: .bottomLeading) {
            // Eigenes Hero-Bild (falls hochgeladen) — sonst Gradient aus Projekt-Archetyp.
            // Gleiche Fokus-Fill-Logik wie ProjectHeroView, nur in Kartengröße.
            GeometryReader { geo in
                Group {
                    if let heroImage {
                        focalImage(heroImage, in: geo.size)
                    } else {
                        LinearGradient(
                            colors: heroGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .overlay(GridTexture().opacity(0.35))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
            }
            .frame(height: 140)
            // Projekt-Kürzel oben rechts + Signal-Badge oben links
            VStack {
                HStack {
                    starButton
                    // Signal-Badge: nur wenn aktive Sitzungs-Signale vorhanden
                    if signalCount > 0 {
                        Text("\(signalCount)")
                            .font(.mykMono(9.5))
                            .foregroundStyle(.white)
                            .padding(.horizontal, MykSpace.s3)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(hasCriticalSignal ? MykColor.critical.color : MykColor.tasks.color)
                            )
                            .padding(MykSpace.s4)
                    }
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

    // Kundenname nur zeigen, wenn er echten Zusatz-Info liefert (Polish 2026-07-04:
    // vorher „Neuhaus / Neuhaus", weil Titel oft = Kundenname). Vergleich tolerant.
    private var distinctCustomerName: String? {
        guard let name = customer?.name.trimmingCharacters(in: .whitespaces), name.isEmpty == false,
              name.compare(project.title.trimmingCharacters(in: .whitespaces),
                           options: [.caseInsensitive, .diacriticInsensitive]) != .orderedSame
        else { return nil }
        return name
    }

    // MARK: Info-Bereich
    private var infoArea: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            HStack {
                if let name = distinctCustomerName {
                    Text(name)
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.inkSoft.color)
                        .lineLimit(1)
                }
                Spacer()
                kindChip
            }
            lifecycleRow
        }
        .padding(MykSpace.s5)
    }

    // MARK: Lebenszyklus-Mini (2026-07-02) — zeigt auf einen Blick, wo das Projekt steht.
    // Nutzt die lokal gesetzte Stufe (ProjectLifecycleStore) bzw. die ehrlich abgeleitete
    // Startstufe. Ersetzt das nutzlose „Aktiv"-Phasenfeld (bei allen Projekten gleich).
    private var lifecycleStage: ProjectLifecycleStage {
        appState.projectLifecycle.stage(for: project.projectNumber)
            ?? ProjectLifecycleDeriver.derive(
                timeBookedHours: appState.timer.gebuchteStunden(for: project.projectNumber),
                isArchived: project.phase == "Archiviert")
    }

    private var lifecycleRow: some View {
        HStack(spacing: MykSpace.s3) {
            HStack(spacing: 3) {
                ForEach(ProjectLifecycleStage.allCases) { s in
                    Capsule()
                        .fill(s.rawValue <= lifecycleStage.rawValue ? MykColor.brand.color : MykColor.line.color)
                        .frame(width: s.rawValue == lifecycleStage.rawValue ? 13 : 7, height: 3)
                }
            }
            Text(lifecycleStage.label)
                .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color).tracking(0.3)
            Spacer()
        }
    }

    // Stern-Toggle (L25). Eigener Plain-Button im Hero — macOS leitet den inneren
    // Button-Tap, der Kartentap bleibt fürs Öffnen. try? ist hier vertretbar: der
    // Store macht Fehler über saveState sichtbar, die View bleibt fehlerfrei.
    private var starButton: some View {
        Button {
            try? appState.favorites.toggle(projectNumber: project.projectNumber)
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.mykSmall)
                .foregroundStyle(isFavorite ? MykColor.tasks.color : .white.opacity(0.85))
                .padding(6)
                .background(Circle().fill(.black.opacity(0.22)))
                .padding(MykSpace.s4)
        }
        .buttonStyle(.plain)
        .help(isFavorite ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen")
        .accessibilityLabel(isFavorite ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen")
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

    // Fokus-zentrierter Fill-Zuschnitt — identische Logik wie ProjectHeroView.focalImage,
    // nur für die kleine Kartengröße. Fixer Rahmen, keine Layout-Rückwirkung.
    private func focalImage(_ image: NSImage, in frame: CGSize) -> some View {
        let iw = max(image.size.width, 1)
        let ih = max(image.size.height, 1)
        let scale = max(frame.width / iw, frame.height / ih)
        let sw = iw * scale
        let sh = ih * scale
        let offsetX = min(0, max(frame.width - sw, frame.width / 2 - focalPoint.x * sw))
        let offsetY = min(0, max(frame.height - sh, frame.height / 2 - focalPoint.y * sh))
        return Color.clear
            .overlay(alignment: .topLeading) {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: sw, height: sh)
                    .offset(x: offsetX, y: offsetY)
            }
            .frame(width: frame.width, height: frame.height)
    }

    private var heroGradient: [Color] { project.kind.heroGradient }

    private var kindColor: Color { project.kind.accentColor }
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

    // L26: token-basierter Hero-Verlauf aus der Quellen-Palette (adaptiv, dark-safe) —
    // ersetzt die hartkodierten Color(hex:)-Verläufe. Geteilt von Galerie-Karte,
    // Detail-Hero und Mini-Karte. Farbe bleibt Quellen-Sprache.
    var heroGradient: [Color] {
        switch self {
        case .kitchen:       [MykColor.drive.color.opacity(0.85), MykColor.drive.color.opacity(0.45)]
        case .lighting:      [MykColor.people.color.opacity(0.85), MykColor.people.color.opacity(0.45)]
        case .addendum:      [MykColor.cash.color.opacity(0.85), MykColor.cash.color.opacity(0.45)]
        case .lead:          [MykColor.muted.color.opacity(0.85), MykColor.muted.color.opacity(0.45)]
        case .quote:         [MykColor.tasks.color.opacity(0.85), MykColor.tasks.color.opacity(0.45)]
        case .studioInternal:[MykColor.faint.color, MykColor.bone.color]
        }
    }
}
