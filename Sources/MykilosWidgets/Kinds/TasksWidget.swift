import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - TasksWidget
// Aufgaben aus ClickUp. Fokus-Auswahl, nicht das ganze Board. Ocker.
public struct TasksWidget: View {
    public let projectID: String
    public init(projectID: String) { self.projectID = projectID }

    public var body: some View {
        WidgetContainer(
            kind: .tasks,
            sourceLabel: "CLICKUP  ·  KÜCHE MEYER  ·  4 OFFEN",
            renderState: .content,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                HStack { SourceChip(kind: .tasks); Text("Aufgaben · Fokus").mykWidgetTitle(); Spacer() }
                VStack(spacing: 0) {
                    ForEach(demoTasks, id: \.title) { task in
                        TaskRow(task: task)
                        if task.title != demoTasks.last?.title {
                            Divider().overlay(MykColor.line.color.opacity(0.6))
                        }
                    }
                }
            }
        }
    }

    private struct DemoTask { let title: String; let sub: String; let isCritical: Bool }
    private var demoTasks: [DemoTask] {[
        DemoTask(title: "Bartresen-Detail freigeben", sub: "FÄLLIG HEUTE  ·  J. BERGER", isCritical: true),
        DemoTask(title: "Korpusmaße an Tischlerei",   sub: "MORGEN  ·  S. ADLER",       isCritical: false),
        DemoTask(title: "Griffmuster bestätigen",     sub: "DO  ·  FAM. MEYER",          isCritical: false),
        DemoTask(title: "Arbeitsplatte avisieren",    sub: "FR  ·  H. THIEL",            isCritical: false),
    ]}
}

private struct TaskRow: View {
    let task: TasksWidget.DemoTask
    var body: some View {
        HStack(alignment: .top, spacing: MykSpace.s4) {
            RoundedRectangle(cornerRadius: 4)
                .stroke(task.isCritical ? MykColor.critical.color : MykColor.faint.color, lineWidth: 1.5)
                .background(
                    task.isCritical
                        ? RoundedRectangle(cornerRadius: 4).fill(MykColor.critical.color.opacity(0.12))
                        : nil
                )
                .frame(width: 14, height: 14)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title).font(.mykSmall).foregroundStyle(MykColor.ink.color)
                Text(task.sub).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
        }
        .padding(.vertical, MykSpace.s4)
    }
}
