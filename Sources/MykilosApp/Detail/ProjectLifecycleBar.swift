import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - ProjectLifecycleBar (2026-07-02)
// Schmaler Band unter dem Hero: ein antippbarer Lebenszyklus-Stepper (Akquise →
// Abschluss) plus eine kompakte KPI-Zeile. Die Stufe ist rein lokal und gehört dem
// Nutzer — Startwert wird aus echten Signalen abgeleitet (gebuchte Zeit / Archiv-
// Status), aber nichts wird behauptet, was nicht belegt ist. Tippen setzt die Stufe.
// KPIs sind echte Daten: Zeit (lokal, sofort), Nachträge (lokal), offene Aufgaben
// (ClickUp, nur wenn eine Liste verknüpft ist; sonst ausgeblendet).
struct ProjectLifecycleBar: View {
    let project: Project
    @Environment(AppState.self) private var appState
    @State private var openTaskCount: Int?
    // ClickUp-Phasen-Abgleich (2026-07-04, docs/CLICKUP_PROJEKT_MAPPING.md §2): read-only
    // Signal aus dem Custom Field `project_phase` — nie Auto-Write in eine Richtung, der
    // Nutzer setzt seine Stufe weiterhin selbst im Stepper.
    @State private var clickUpPhase: ClickUpProjectPhase?

    private var currentStage: ProjectLifecycleStage {
        appState.projectLifecycle.stage(for: project.projectNumber)
            ?? ProjectLifecycleDeriver.derive(
                timeBookedHours: appState.timer.gebuchteStunden(for: project.projectNumber),
                isArchived: project.phase == "Archiviert")
    }

    private var isUserSet: Bool { appState.projectLifecycle.stage(for: project.projectNumber) != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            stepper
            kpiRow
        }
        .padding(.horizontal, MykSpace.s8)
        .padding(.vertical, MykSpace.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MykColor.paper.color)
        .task(id: project.projectNumber) { await loadOpenTasks() }
    }

    // MARK: Stepper
    private var stepper: some View {
        HStack(spacing: 0) {
            ForEach(ProjectLifecycleStage.allCases) { stage in
                stageColumn(stage)
            }
        }
    }

    private func stageColumn(_ stage: ProjectLifecycleStage) -> some View {
        let idx = stage.rawValue
        let current = currentStage.rawValue
        let isReached = idx <= current
        let isCurrent = idx == current
        let last = ProjectLifecycleStage.allCases.count - 1

        return VStack(spacing: 6) {
            ZStack {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(idx > 0 ? connectorColor(reached: idx <= current) : Color.clear)
                        .frame(height: 2)
                    Rectangle()
                        .fill(idx < last ? connectorColor(reached: idx < current) : Color.clear)
                        .frame(height: 2)
                }
                node(isReached: isReached, isCurrent: isCurrent)
            }
            Text(stage.label)
                .font(.mykMono(9)).tracking(0.3)
                .foregroundStyle(isCurrent ? MykColor.ink.color : MykColor.muted.color)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { setStage(stage) }
        .help("Stufe setzen: \(stage.label)")
        .accessibilityLabel("Lebenszyklus-Stufe \(stage.label)\(isCurrent ? ", aktuell" : "")")
    }

    private func node(isReached: Bool, isCurrent: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isReached ? MykColor.brand.color : MykColor.card.color)
                .frame(width: isCurrent ? 15 : 11, height: isCurrent ? 15 : 11)
            Circle()
                .stroke(isReached ? MykColor.brand.color : MykColor.line.color, lineWidth: 1.5)
                .frame(width: isCurrent ? 15 : 11, height: isCurrent ? 15 : 11)
            if isCurrent {
                Circle().fill(MykColor.paper.color).frame(width: 5, height: 5)
            }
        }
    }

    private func connectorColor(reached: Bool) -> Color {
        reached ? MykColor.brand.color.opacity(0.55) : MykColor.line.color
    }

    // MARK: KPI-Zeile
    private var kpiRow: some View {
        HStack(spacing: MykSpace.s6) {
            // ZEIT nur wenn aussagekräftig (Polish 2026-07-04: „ZEIT 0 h" wirkte
            // unfertig) — gebuchte Stunden > 0 ODER ein Zielkontingent gesetzt.
            if let z = zeitText { kpi("ZEIT", z) }
            if addendaCount > 0 { kpi("NACHTRÄGE", "\(addendaCount)") }
            if let n = openTaskCount { kpi("AUFGABEN", "\(n)") }
            if isUserSet == false {
                Text("Stufe abgeleitet · tippen zum Setzen")
                    .font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
            }
            if let clickUpPhase, clickUpPhase.mykilosStage != currentStage {
                Text("ClickUp sagt: \(clickUpPhase.label)")
                    .font(.mykMono(9)).foregroundStyle(MykColor.tasks.color)
                    .help("Custom Field project_phase aus der verknüpften ClickUp-Liste weicht ab — mykilOS schreibt nicht automatisch, tippe selbst auf die passende Stufe.")
            }
            Spacer()
        }
    }

    private func kpi(_ key: String, _ value: String) -> some View {
        HStack(spacing: 5) {
            Text(key).font(.mykMono(9)).tracking(0.5).foregroundStyle(MykColor.faint.color)
            Text(value).font(.mykMono(11)).foregroundStyle(MykColor.inkSoft.color)
        }
    }

    private var addendaCount: Int { appState.registry.addenda(of: project).count }

    /// `nil`, wenn weder Zeit gebucht noch ein Ziel gesetzt ist → KPI entfällt ganz.
    private var zeitText: String? {
        let gebucht = appState.timer.gebuchteStunden(for: project.projectNumber)
        let ziel = appState.timer.zielkontingent(for: project.projectNumber)?.zielStunden
        let g = gebucht.formatted(.number.precision(.fractionLength(0...1)))
        if let ziel, ziel > 0 {
            let z = ziel.formatted(.number.precision(.fractionLength(0...1)))
            return "\(g)/\(z) h"
        }
        return gebucht > 0 ? "\(g) h" : nil
    }

    // MARK: Aktionen
    private func setStage(_ stage: ProjectLifecycleStage) {
        try? appState.projectLifecycle.setStage(stage, for: project.projectNumber)
    }

    private func loadOpenTasks() async {
        guard let listID = project.links.clickUpListID, listID.isEmpty == false else {
            openTaskCount = nil
            clickUpPhase = nil
            return
        }
        let client = ClickUpClient()
        if let tasks = try? await client.tasks(listID: listID) {
            openTaskCount = tasks.count
            clickUpPhase = ClickUpClient.projectPhase(from: tasks)
        }
    }
}
