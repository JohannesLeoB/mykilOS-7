import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - ProjectPipelineView (S6)
// Kanban-Vogelperspektive über alle Projekte, gruppiert nach Lebenszyklus-Stufe.
// Drag eine Karte in eine andere Spalte → Stufe setzen (lokal, ProjectLifecycleStore,
// reversibel). Forecast-Leiste: Budget × stufen-gewichtete Wahrscheinlichkeit.
// Read-only auf Projektdaten; der einzige Schreibvorgang ist die lokale Stufe.
struct ProjectPipelineView: View {
    let projects: [Project]
    let stageFor: (Project) -> ProjectLifecycleStage
    let customerFor: (Project) -> Customer?
    let budgetFor: (Project) -> Double?
    let onMove: (Project, ProjectLifecycleStage) -> Void
    let onOpen: (Project) -> Void

    @State private var dropTarget: ProjectLifecycleStage?

    private static let preisFormatter: NumberFormatter = {
        let f = NumberFormatter(); f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE"); f.maximumFractionDigits = 0
        return f
    }()

    // Gewichtung je Stufe für den Forecast (grobe, ehrliche Heuristik).
    private func probability(_ s: ProjectLifecycleStage) -> Double {
        switch s {
        case .akquise:     0.10
        case .planung:     0.30
        case .angebot:     0.60
        case .ausfuehrung: 0.90
        case .abschluss:   1.00
        }
    }

    private func projects(in stage: ProjectLifecycleStage) -> [Project] {
        projects.filter { stageFor($0) == stage }
            .sorted { $0.projectNumber > $1.projectNumber }
    }

    private var weightedForecast: Double {
        projects.reduce(0) { sum, p in
            sum + (budgetFor(p) ?? 0) * probability(stageFor(p))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            forecastBar
            Divider().overlay(MykColor.line.color.opacity(0.4))
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: MykSpace.s5) {
                    ForEach(ProjectLifecycleStage.allCases) { stage in
                        column(stage)
                    }
                }
                .padding(MykSpace.s9)
            }
        }
    }

    // MARK: Forecast-Leiste
    private var forecastBar: some View {
        HStack(spacing: MykSpace.s5) {
            Label("Gewichtete Pipeline", systemImage: "chart.line.uptrend.xyaxis")
                .font(.mykSmall).foregroundStyle(MykColor.muted.color)
            Text(Self.preisFormatter.string(from: NSNumber(value: weightedForecast)) ?? "–")
                .font(.mykHeadline).foregroundStyle(MykColor.cash.color)
            Spacer()
            Text("\(projects.count) Projekte · Budget × Stufen-Wahrscheinlichkeit")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.faint.color)
        }
        .padding(.horizontal, MykSpace.s9).padding(.vertical, MykSpace.s4)
    }

    // MARK: Spalte je Stufe
    private func column(_ stage: ProjectLifecycleStage) -> some View {
        let items = projects(in: stage)
        return VStack(alignment: .leading, spacing: MykSpace.s4) {
            HStack(spacing: MykSpace.s2) {
                Circle().fill(stageColor(stage)).frame(width: 8, height: 8)
                Text(stage.label).font(.mykHeadline).foregroundStyle(MykColor.ink.color)
                Text("\(items.count)").font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
                Spacer()
            }
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MykSpace.s3) {
                    ForEach(items) { project in
                        card(project)
                            .draggable(project.projectNumber) {
                                Text(project.title).font(.mykSmall).padding(MykSpace.s3)
                                    .background(MykColor.card.color)
                            }
                    }
                    if items.isEmpty {
                        Text("—").font(.mykMono(11)).foregroundStyle(MykColor.faint.color)
                            .frame(maxWidth: .infinity).padding(.vertical, MykSpace.s6)
                    }
                }
                .padding(.bottom, MykSpace.s5)
            }
        }
        .padding(MykSpace.s4)
        .frame(width: 240)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.md)
                .fill(dropTarget == stage ? stageColor(stage).opacity(0.08) : MykColor.paper2.color.opacity(0.4))
                .overlay(RoundedRectangle(cornerRadius: MykRadius.md)
                    .stroke(dropTarget == stage ? stageColor(stage) : MykColor.line.color.opacity(0.6),
                            lineWidth: dropTarget == stage ? 2 : 1))
        )
        .dropDestination(for: String.self) { items, _ in
            defer { dropTarget = nil }
            guard let number = items.first,
                  let project = projects.first(where: { $0.projectNumber == number }),
                  stageFor(project) != stage else { return false }
            onMove(project, stage)
            return true
        } isTargeted: { targeted in
            dropTarget = targeted ? stage : nil
        }
    }

    // MARK: Projektkarte
    private func card(_ project: Project) -> some View {
        Button { onOpen(project) } label: {
            VStack(alignment: .leading, spacing: MykSpace.s2) {
                Text(project.projectNumber).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                Text(project.title).font(.mykSmall).foregroundStyle(MykColor.ink.color).lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                if let customer = customerFor(project)?.name {
                    Text(customer).font(.mykMono(9)).foregroundStyle(MykColor.people.color).lineLimit(1)
                }
                if let budget = budgetFor(project) {
                    Text(Self.preisFormatter.string(from: NSNumber(value: budget)) ?? "")
                        .font(.mykMono(9)).foregroundStyle(MykColor.cash.color)
                }
            }
            .padding(MykSpace.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.card.color)
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }

    private func stageColor(_ s: ProjectLifecycleStage) -> Color {
        switch s {
        case .akquise:     MykColor.faint.color
        case .planung:     MykColor.people.color
        case .angebot:     MykColor.tasks.color
        case .ausfuehrung: MykColor.drive.color
        case .abschluss:   MykColor.positive.color
        }
    }
}
