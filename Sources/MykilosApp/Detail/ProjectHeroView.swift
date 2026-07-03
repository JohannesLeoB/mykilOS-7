import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign

// MARK: - ProjectHeroView
// Der starke Anker oben. Großes Bild, Titel in Versalschrift, Eckdaten,
// Budget-Linie als feiner Strich. Bleibt oben, ankert dich im Projekt.
struct ProjectHeroView: View {
    let project:  Project
    let customer: Customer?
    let onBack:   () -> Void
    var isFavorite: Bool = false
    var onToggleFavorite: () -> Void = {}

    // Nutzer-eigenes Hero-Bild (lokal, je Projekt). Nil = Gradient.
    @State private var heroImage: NSImage?
    // Fokus-Punkt (0…1) für den Fill-Zuschnitt. Default Mitte.
    @State private var focalPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
    // Fadenkreuz-Modus: Nutzer zieht/tippt auf dem Hero, um den Fokus-Punkt zu setzen.
    @State private var focusEditing: Bool = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            heroBackground
            // Dunkler Verlauf unten für Lesbarkeit
            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .center, endPoint: .bottom
            )
            if focusEditing {
                focusPickerOverlay
            }
            // Inhalt
            VStack(alignment: .leading, spacing: 0) {
                // Back-Button + Breadcrumb oben
                header
                Spacer()
                // Titel + Meta unten
                if focusEditing == false {
                    heroContent
                }
            }
            .padding(MykSpace.s8)
        }
        // Höhe von 280 → 190 (2026-07-02, Johannes: Hero nahm zu viel Fenster ohne viel
        // Funktion; ~33% weniger zugunsten des Inhalts). Inhalt bleibt unten verankert
        // (Titel/Meta), Back/Aktionen oben — Muster unverändert, nur weniger Leerraum.
        .frame(height: 190)
        .frame(maxWidth: .infinity)
        .task(id: project.projectNumber) {
            heroImage = ProjectHeroImageStore.image(for: project.projectNumber)
            focalPoint = ProjectHeroImageStore.focalPoint(for: project.projectNumber)
        }
    }

    private var budget: Double? { project.links.budget }

    // MARK: Hintergrund — eigenes Bild wenn vorhanden, sonst Kind-Gradient.
    // Harte Grenze via GeometryReader: das Bild ist eine geclippte Overlay mit fester
    // Rahmengröße und kann NIE das Layout treiben (früherer „Bild sprengt Pane"-Bug).
    private var heroBackground: some View {
        GeometryReader { geo in
            Group {
                if let heroImage {
                    focalImage(heroImage, in: geo.size)
                } else {
                    LinearGradient(
                        colors: heroGradient,
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .overlay(GridTexture().opacity(0.4))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }

    // Fokus-zentrierter Fill-Zuschnitt: das (evtl. übergroße) Bild liegt als Overlay in
    // einem fixen Rahmen und wird nur per Offset verschoben + geclippt — keine
    // Layout-Rückwirkung. `focalPoint` (0…1) bestimmt, welcher Bildpunkt zur Mitte rückt.
    private func focalImage(_ image: NSImage, in frame: CGSize) -> some View {
        let iw = max(image.size.width, 1)
        let ih = max(image.size.height, 1)
        let scale = max(frame.width / iw, frame.height / ih)   // Fill: größere Skala
        let sw = iw * scale
        let sh = ih * scale
        // Offset so, dass der Fokus zur Mitte rückt — geklemmt, damit keine leeren Ränder.
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
            .clipped()
    }

    // Bild ändern/entfernen (lokal, je Projekt).
    private var heroImageButton: some View {
        Menu {
            Button("Bild wählen …", systemImage: "photo") {
                if ProjectHeroImageStore.pickAndSave(for: project.projectNumber) {
                    heroImage = ProjectHeroImageStore.image(for: project.projectNumber)
                }
            }
            if heroImage != nil {
                Button("Fokus-Punkt setzen …", systemImage: "scope") {
                    focusEditing = true
                }
                Button("Bild entfernen", systemImage: "trash", role: .destructive) {
                    ProjectHeroImageStore.clear(for: project.projectNumber)
                    heroImage = nil
                }
            }
        } label: {
            Image(systemName: "photo")
                .font(.mykSmall)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, MykSpace.s4).padding(.vertical, 7)
                .background(Capsule().fill(.black.opacity(0.22)))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Projekt-Titelbild ändern")
        .accessibilityLabel("Projekt-Titelbild ändern")
    }

    // MARK: Back + Breadcrumb
    // Während des Fokus-Punkt-Modus ausgeblendet, damit Klicks/Drags eindeutig dem
    // Fadenkreuz gehören und nicht mit Back/Favorit/Bildmenü kollidieren.
    private var header: some View {
        HStack(spacing: MykSpace.s4) {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.mykCaption)
                    Text("Projekte")
                        .font(.mykSmall)
                }
                .foregroundStyle(.white.opacity(0.82))
                .padding(.horizontal, MykSpace.s4)
                .padding(.vertical, 7)
                .background(Capsule().fill(.black.opacity(0.22)))
            }
            .buttonStyle(.plain)
            Spacer()
            heroImageButton
            favoriteButton
            // Budget-Anzeige nur, wenn ein echtes Budget hinterlegt ist (Airtable
            // "Budget"-Feld) — kein Fake-Prozentwert ohne Datengrundlage.
            if budget != nil {
                budgetPill
            }
        }
        .opacity(focusEditing ? 0 : 1)
        .allowsHitTesting(focusEditing == false)
    }

    // MARK: Fokus-Punkt-Picker (Fadenkreuz-Modus)
    // Scrim + Fadenkreuz + Hinweistext + „Fertig"-Button. Tap/Drag irgendwo auf dem Hero
    // setzt live den Fokus-Punkt (0…1); focalImage crop reagiert sofort. Persistiert wird
    // laufend während des Ziehens sowie beim Beenden — beides über setFocalPoint (Sidecar).
    private var focusPickerOverlay: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Color.black.opacity(0.28)
                    .contentShape(Rectangle())
                    .gesture(focusDragGesture(in: size))

                crosshair
                    .position(x: focalPoint.x * size.width, y: focalPoint.y * size.height)
                    .allowsHitTesting(false)

                VStack {
                    Spacer()
                    HStack {
                        Text("Tippen oder ziehen, um den Bildfokus zu setzen")
                            .font(.mykSmall)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, MykSpace.s4)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(.black.opacity(0.35)))
                        Spacer()
                        Button("Fertig") {
                            finishFocusEditing()
                        }
                        .buttonStyle(.plain)
                        .font(.mykSmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, MykSpace.s4)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(MykColor.brand.color))
                    }
                }
                .padding(MykSpace.s8)
            }
            .frame(width: size.width, height: size.height)
        }
    }

    private var crosshair: some View {
        ZStack {
            Circle()
                .stroke(.white, lineWidth: 2)
                .frame(width: 28, height: 28)
            Circle()
                .fill(MykColor.brand.color)
                .frame(width: 8, height: 8)
            Rectangle().fill(.white.opacity(0.9)).frame(width: 1, height: 14).offset(y: -21)
            Rectangle().fill(.white.opacity(0.9)).frame(width: 1, height: 14).offset(y: 21)
            Rectangle().fill(.white.opacity(0.9)).frame(width: 14, height: 1).offset(x: -21)
            Rectangle().fill(.white.opacity(0.9)).frame(width: 14, height: 1).offset(x: 21)
        }
        .shadow(color: .black.opacity(0.4), radius: 3)
    }

    private func focusDragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                updateFocalPoint(from: value.location, in: size)
            }
            .onEnded { value in
                updateFocalPoint(from: value.location, in: size)
                persistFocalPoint()
            }
    }

    private func updateFocalPoint(from location: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let x = min(max(location.x / size.width, 0), 1)
        let y = min(max(location.y / size.height, 0), 1)
        focalPoint = CGPoint(x: x, y: y)
    }

    private func persistFocalPoint() {
        try? ProjectHeroImageStore.setFocalPoint(focalPoint, for: project.projectNumber)
    }

    private func finishFocusEditing() {
        persistFocalPoint()
        focusEditing = false
    }

    // Stern-Toggle im Detail-Header (L25).
    private var favoriteButton: some View {
        Button(action: onToggleFavorite) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.mykSmall)
                .foregroundStyle(isFavorite ? MykColor.tasks.color : .white.opacity(0.85))
                .padding(.horizontal, MykSpace.s4).padding(.vertical, 7)
                .background(Capsule().fill(.black.opacity(0.22)))
        }
        .buttonStyle(.plain)
        .help(isFavorite ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen")
        .accessibilityLabel(isFavorite ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen")
    }

    // MARK: Held-Inhalt
    private var heroContent: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            Text(project.title.uppercased())
                .font(.mykHero)
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.5)   // SCHMIDT→DT-Fix: lange Titel skalieren statt abschneiden
            metaRow
            // Budget steht bereits als Pille oben rechts — keine zweite Zeile hier
            // (Redundanz raubte dem Hero Ruhe).
        }
    }

    private var metaRow: some View {
        HStack(spacing: MykSpace.s8) {
            if let customer {
                metaItem(key: "Kunde", value: customer.name)
                // mykilOS 8, Block C (S2): Kdnr neben der Projektnummer (Vertrag §1).
                // Kdnr ≠ Projektnr — eigener Kundenschlüssel, getrennt geführt.
                if customer.customerNumber.trimmingCharacters(in: .whitespaces).isEmpty == false {
                    metaItem(key: "Kdnr", value: customer.customerNumber)
                }
            }
            if let phase = project.phase {
                metaItem(key: "Phase", value: phase)
            }
            metaItem(key: "Projektnr", value: project.projectNumber)
            if project.isAddendum, let parent = project.parentProjectNumber {
                metaItem(key: "Nachtrag zu", value: parent)
            }
        }
    }

    private func metaItem(key: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(key.uppercased())
                .font(.mykMono(9))
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.mykSmall)
                .foregroundStyle(.white.opacity(0.92))
        }
    }

    // MARK: Budget-Zeile
    // Zeigt das echte Airtable-Budget (project.links.budget). Kein Ist-Umsatz-
    // Vergleich hier — der lebt bereits live im CashWidget (Sevdesk-Abgleich).
    // Ohne echtes Budget wird diese Zeile gar nicht angezeigt (kein Fake-Wert).
    private func budgetLine(_ budget: Double) -> some View {
        Text("BUDGET \(Self.budgetFormatter.string(from: budget as NSNumber) ?? "—")")
            .font(.mykMono(9.5))
            .foregroundStyle(.white.opacity(0.72))
    }

    // MARK: Budget-Pille (oben rechts)
    private var budgetPill: some View {
        Text(Self.budgetFormatter.string(from: (budget ?? 0) as NSNumber) ?? "—")
            .font(.mykSmall)
            .foregroundStyle(.white)
            .fontWeight(.semibold)
            .padding(.horizontal, MykSpace.s4)
            .padding(.vertical, 7)
            .background(Capsule().fill(.white.opacity(0.15)))
    }

    private static let budgetFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    // MARK: Helfer
    // L26: token-basiert + adaptiv (siehe ProjectKind.heroGradient) — ersetzt die
    // hartkodierten Color(hex:)-Verläufe, dark-mode-sicher.
    private var heroGradient: [Color] { project.kind.heroGradient }
}

// Raster-Textur (geteilt zwischen Card und Hero)
struct GridTexture: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 54
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width { path.move(to: .init(x: x, y: 0)); path.addLine(to: .init(x: x, y: size.height)); x += step }
            var y: CGFloat = 0
            while y <= size.height { path.move(to: .init(x: 0, y: y)); path.addLine(to: .init(x: size.width, y: y)); y += step }
            ctx.stroke(path, with: .color(.white.opacity(0.25)), lineWidth: 0.5)
        }
    }
}
