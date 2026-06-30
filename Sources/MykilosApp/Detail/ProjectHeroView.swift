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
    var isFavorite: Bool = false
    var onToggleFavorite: () -> Void = {}

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
        .frame(maxWidth: .infinity)
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
            favoriteButton
            // Budget-Anzeige nur, wenn ein echtes Budget hinterlegt ist (Airtable
            // "Budget"-Feld) — kein Fake-Prozentwert ohne Datengrundlage.
            if budget != nil {
                budgetPill
            }
        }
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
