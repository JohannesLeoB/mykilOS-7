import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - ProjectHeroView
// Der starke Anker oben. Großes Bild, Titel in Versalschrift, Eckdaten,
// Budget-Linie als feiner Strich. Bleibt oben, ankert dich im Projekt.
struct ProjectHeroView: View {
    let project:  Project
    let customer: Customer?
    let onBack:   () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            heroBackground
            // Dunkler Verlauf unten für Lesbarkeit
            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .center, endPoint: .bottom
            )
            // Inhalt
            VStack(alignment: .leading, spacing: 0) {
                // Back-Button + Breadcrumb oben
                header
                Spacer()
                // Titel + Meta unten
                heroContent
            }
            .padding(MykSpace.s8)
        }
        .frame(height: 280)
    }

    private var budget: Double? { project.links.budget }

    // MARK: Hintergrund
    private var heroBackground: some View {
        LinearGradient(
            colors: heroGradient,
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .overlay(GridTexture().opacity(0.4))
        .frame(maxWidth: .infinity)
    }

    // MARK: Back + Breadcrumb
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
            // Budget-Anzeige nur, wenn ein echtes Budget hinterlegt ist (Airtable
            // "Budget"-Feld) — kein Fake-Prozentwert ohne Datengrundlage.
            if budget != nil {
                budgetPill
            }
        }
    }

    // MARK: Held-Inhalt
    private var heroContent: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            Text(project.title.uppercased())
                .font(.mykHero)
                .foregroundStyle(.white)
                .lineLimit(2)
            metaRow
            if let budget {
                budgetLine(budget)
            }
        }
    }

    private var metaRow: some View {
        HStack(spacing: MykSpace.s8) {
            if let customer {
                metaItem(key: "Kunde", value: customer.name)
            }
            if let phase = project.phase {
                metaItem(key: "Phase", value: phase)
            }
            metaItem(key: "Nummer", value: project.projectNumber)
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
    private var heroGradient: [Color] {
        switch project.kind {
        case .kitchen:       [Color(hex: 0xD9B9A4), Color(hex: 0xC9A98F), Color(hex: 0x9A8F7E), Color(hex: 0x6F7A72)]
        case .lighting:      [Color(hex: 0xA8C4A8), Color(hex: 0x7A9A7A)]
        case .addendum:      [Color(hex: 0xA8B8C8), Color(hex: 0x6A7A8F)]
        case .lead, .quote:  [Color(hex: 0xC8BCA8), Color(hex: 0x8A7A6A)]
        case .studioInternal:[Color(hex: 0xC0C0C0), Color(hex: 0x808080)]
        }
    }
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
