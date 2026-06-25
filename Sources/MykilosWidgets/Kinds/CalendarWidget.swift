import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - CalendarWidget. Termine. Salbei.
public struct CalendarWidget: View {
    public let projectID: String
    public init(projectID: String) { self.projectID = projectID }

    public var body: some View {
        WidgetContainer(
            kind: .calendar,
            sourceLabel: "KALENDER  ·  GOOGLE  ·  2 TERMINE",
            renderState: .content,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                HStack { SourceChip(kind: .calendar); Text("Termine").mykWidgetTitle(); Spacer() }
                VStack(spacing: 0) {
                    ForEach(demoEvents, id: \.title) { event in
                        EventRow(event: event)
                        if event.title != demoEvents.last?.title {
                            Divider().overlay(MykColor.line.color.opacity(0.6))
                        }
                    }
                }
            }
        }
    }

    struct DemoEvent { let title: String; let sub: String; let isCritical: Bool }
    var demoEvents: [DemoEvent] {[
        DemoEvent(title: "Aufmaß vor Ort",   sub: "MO 09:00  ·  MEYER",  isCritical: false),
        DemoEvent(title: "Abnahme Küche",    sub: "DO 14:00  ·  MEYER",  isCritical: true),
    ]}
}

private struct EventRow: View {
    let event: CalendarWidget.DemoEvent
    var body: some View {
        HStack(spacing: MykSpace.s4) {
            RoundedRectangle(cornerRadius: 4)
                .stroke(event.isCritical ? MykColor.critical.color : MykColor.people.color, lineWidth: 1.5)
                .frame(width: 14, height: 14).padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title).font(.mykSmall).foregroundStyle(MykColor.ink.color)
                Text(event.sub).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
            Spacer()
        }
        .padding(.vertical, MykSpace.s4)
    }
}
