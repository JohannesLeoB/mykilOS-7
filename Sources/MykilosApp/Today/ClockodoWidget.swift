import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - ClockodoWidget
// Zeitstatus für Heute. Akt 2: Demo-Daten. Akt 3: echte Clockodo-API.
// ZEITEN-Regel: mykilOS ist Mapping-Layer — niemals zweite Zeit-Wahrheit.
struct ClockodoWidget: View {
    var body: some View {
        WidgetContainer(
            kind: .clockodo,
            sourceLabel: "CLOCKODO  ·  HEUTE  ·  DEMO",
            renderState: .content,
            projectID: "home"
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                HStack {
                    SourceChip(kind: .clockodo)
                    Text("Zeit · Heute").mykWidgetTitle()
                    Spacer()
                }
                // Gesamt-Stunden
                VStack(alignment: .leading, spacing: 2) {
                    Text("6,5 h")
                        .font(.mykDisplay)
                        .foregroundStyle(MykColor.ink.color)
                    Text("heute gebucht")
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.muted.color)
                }
                Divider().overlay(MykColor.line.color)
                // Aufteilung
                VStack(spacing: MykSpace.s3) {
                    TimeBar(label: "MEYER",  value: 4.0, total: 8.0, color: MykColor.drive.color)
                    TimeBar(label: "LOFT",   value: 2.5, total: 8.0, color: MykColor.people.color)
                }
                Text("Quelle: Clockodo · Nur Anzeige, keine Buchung hier")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.faint.color)
            }
        }
    }
}

private struct TimeBar: View {
    let label: String
    let value: Double
    let total: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                Spacer()
                Text(String(format: "%.1f h", value)).font(.mykMono(9.5)).foregroundStyle(MykColor.ink.color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(MykColor.bone.color).frame(height: 4)
                    Capsule().fill(color).frame(width: geo.size.width * (value / total), height: 4)
                }
            }.frame(height: 4)
        }
    }
}

// MARK: - RecentActivityWidget
struct RecentActivityWidget: View {
    var body: some View {
        WidgetContainer(
            kind: .recentActivity,
            sourceLabel: "DRIVE + CLICKUP  ·  LETZTE AKTIVITÄT",
            renderState: .content,
            projectID: "home"
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                HStack {
                    SourceChip(kind: .recentActivity)
                    Text("Letzte Aktivität").mykWidgetTitle()
                    Spacer()
                }
                VStack(spacing: 0) {
                    ForEach(demoActivity, id: \.title) { item in
                        ActivityRow(item: item)
                        if item.title != demoActivity.last?.title {
                            Divider().overlay(MykColor.line.color.opacity(0.5))
                        }
                    }
                }
            }
        }
    }

    struct ActivityItem { let icon: String; let title: String; let sub: String; let color: Color }
    var demoActivity: [ActivityItem] {[
        ActivityItem(icon: "folder",    title: "Zeichnung Bartresen_v3.pdf", sub: "DRIVE · MEYER · vor 2 Std", color: MykColor.drive.color),
        ActivityItem(icon: "checklist", title: "Korpusmaße an Tischlerei",   sub: "CLICKUP · MEYER · vor 4 Std", color: MykColor.tasks.color),
        ActivityItem(icon: "folder",    title: "Moodboard Loft Küche.pdf",   sub: "DRIVE · LOFT · gestern",     color: MykColor.drive.color),
    ]}
}

private struct ActivityRow: View {
    let item: RecentActivityWidget.ActivityItem
    var body: some View {
        HStack(spacing: MykSpace.s4) {
            Image(systemName: item.icon)
                .font(.mykCaption)
                .foregroundStyle(item.color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).font(.mykSmall).foregroundStyle(MykColor.ink.color).lineLimit(1)
                Text(item.sub).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
        }
        .padding(.vertical, MykSpace.s3)
    }
}
