import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - AssistantWidget
// Der Dolmetscher. Liest alle Signale des Projekts, formt einen Satz, schlägt vor.
// Dunkel, dominant, 3 Spalten breit. Schreibt NIE ohne Freigabe.
public struct AssistantWidget: View {
    public let projectID: String
    public init(projectID: String) { self.projectID = projectID }

    @Environment(StudioContext.self) private var context
    @State private var draftRequested = false

    private var activeSignals: [WidgetSignal] {
        context.signals(for: projectID)
    }

    public var body: some View {
        // Eigenes dunkles Styling — WidgetContainer mit Override
        VStack(alignment: .leading, spacing: 0) {
            content
            sourceLineAssistant
        }
        .background(
            LinearGradient(
                colors: [Color(hex: 0x1F1C17), Color(hex: 0x2C2620)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 4)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            HStack {
                SourceChip(kind: .assistant)
                Text("Assistent").mykWidgetTitle().foregroundStyle(.white.opacity(0.55))
                Spacer()
            }
            Text(summaryText)
                .font(.mykTitle)
                .foregroundStyle(.white.opacity(0.96))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            if !draftRequested {
                actionRow
            } else {
                draftConfirmation
            }
        }
        .padding(MykSpace.s6)
    }

    private var actionRow: some View {
        HStack(spacing: MykSpace.s4) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { draftRequested = true }
            } label: {
                Text("Entwurf vorbereiten")
                    .font(.mykSmall).fontWeight(.semibold)
                    .foregroundStyle(MykColor.ink.color)
                    .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s3)
                    .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(.white))
            }
            .buttonStyle(.plain)
            Button {} label: {
                Text("Später")
                    .font(.mykSmall)
                    .foregroundStyle(.white.opacity(0.55))
            }
            .buttonStyle(.plain)
        }
    }

    private var draftConfirmation: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.badge.clock")
                .foregroundStyle(MykColor.tasks.color)
            Text("Entwurf wird vorbereitet — erscheint zur Freigabe in Akt 4")
                .font(.mykCaption)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var sourceLineAssistant: some View {
        HStack(spacing: 8) {
            Circle().fill(MykColor.positive.color).frame(width: 5, height: 5)
            Text("LIEST: DRIVE · CASH · KALENDER · CLOCKODO  ·  SCHREIBT NICHTS OHNE FREIGABE")
                .font(.mykMono(9.5))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
        }
        .padding(.horizontal, MykSpace.s6).padding(.vertical, MykSpace.s4)
        .overlay(alignment: .top) {
            Divider().overlay(.white.opacity(0.1))
        }
    }

    // MARK: Dynamischer Summary-Text
    private var summaryText: String {
        let hasReview = activeSignals.contains {
            if case .reviewSuggested = $0 { return true }; return false
        }
        let hasBudget = activeSignals.contains {
            if case .budgetThresholdCrossed = $0 { return true }; return false
        }
        let hasDeadline = activeSignals.contains {
            if case .deadlineNear = $0 { return true }; return false
        }
        if hasReview && hasBudget && hasDeadline {
            return "Bei **Meyer** wird's eng — neues Angebot ungeprüft, Budget bei **72 %**, Abnahme in **2 Tagen**. Soll ich eine Antwort an die Tischlerei entwerfen?"
        } else if hasReview {
            return "**Drive** hat ein neues Eingangsangebot erkannt. Soll ich es für den Bieterspiegel vorbereiten?"
        } else {
            return "Alles ruhig bei **\(projectID)**. Wenn etwas aufläuft, melde ich mich hier."
        }
    }
}

private extension Color {
    init(hex: UInt32) { self.init(.sRGB, red: Double((hex >> 16) & 0xFF)/255, green: Double((hex >> 8) & 0xFF)/255, blue: Double(hex & 0xFF)/255, opacity: 1) }
}
