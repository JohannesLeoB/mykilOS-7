import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - Heute anstehend (vereinte Termine-Ansicht, 2026-07-02)
// Ein Block auf der Heute-Seite, der drei Quellen in EINER Tagesliste bündelt:
//   • Google-Kalender-Termine (heute)
//   • ClickUp-Fälligkeiten (heute fällig ODER überfällig)
//   • lokale Zeitblöcke (heute gebucht, aus dem Timer-Subsystem)
// Toggle „Gesamt / ClickUp / Projekt": „Projekt" = nur projektgebundene Einträge
// (ClickUp + Zeit; Kalendertermine tragen im Datenmodell keine Projektnummer und
// fallen in diesem Filter bewusst raus). Farbe ist Sprache — jede Quelle ihr Ton.
// Rein lesend/vorschlagend: nichts wird hier geschrieben.

enum ScheduleScope: String, CaseIterable, Identifiable {
    case gesamt, clickup, projekt
    var id: String { rawValue }
    var label: String {
        switch self {
        case .gesamt:  "Gesamt"
        case .clickup: "ClickUp"
        case .projekt: "Projekt"
        }
    }
}

enum ScheduleKind {
    case termin   // Kalender
    case aufgabe  // ClickUp-Fälligkeit
    case zeit     // lokaler Zeitblock
}

struct ScheduleItem: Identifiable {
    let id: String
    let kind: ScheduleKind
    let time: Date?          // nil = ganztägig / ohne Uhrzeit
    let isOverdue: Bool
    let title: String
    let subtitle: String?
    let projektNummer: String?

    var isProjectBound: Bool { projektNummer?.isEmpty == false || kind == .aufgabe }

    var color: Color {
        if isOverdue { return MykColor.critical.color }
        switch kind {
        case .termin:  return MykColor.people.color    // Salbei
        case .aufgabe: return MykColor.tasks.color     // Ocker
        case .zeit:    return MykColor.personal.color  // Pflaume
        }
    }

    var kindLabel: String {
        switch kind {
        case .termin:  return "Termin"
        case .aufgabe: return isOverdue ? "Überfällig" : "Fällig"
        case .zeit:    return "Zeit"
        }
    }
}

// MARK: - ScheduleLoader
@MainActor
@Observable
final class ScheduleLoader {
    private(set) var items: [ScheduleItem] = []
    private(set) var isLoading = false
    private(set) var loaded = false
    private(set) var calendarConnected = true

    private let calendar: GoogleCalendarFetching
    private let clickUp: ClickUpFetching
    private var gen = 0

    init(calendar: GoogleCalendarFetching = GoogleCalendarClient(),
         clickUp: ClickUpFetching = ClickUpClient()) {
        self.calendar = calendar
        self.clickUp = clickUp
    }

    func load(projects: [Project], bookedSegments: [TimeSegment], now: Date) async {
        gen &+= 1
        let mine = gen
        isLoading = true

        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: now)
        guard let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        var collected: [ScheduleItem] = []

        // 1) Lokale Zeitblöcke (heute) — kein Netzwerk, immer verfügbar.
        for seg in bookedSegments where seg.startedAt >= startOfDay && seg.startedAt < endOfDay {
            let mins = Int((seg.seconds / 60).rounded())
            collected.append(ScheduleItem(
                id: "zeit-\(seg.id.uuidString)", kind: .zeit, time: seg.startedAt, isOverdue: false,
                title: seg.projektTitel.isEmpty ? seg.projektNummer : seg.projektTitel,
                subtitle: "\(seg.kostenstelle) · \(mins) min", projektNummer: seg.projektNummer))
        }

        // 2) Kalender (heute) — still übersprungen, wenn nicht verbunden.
        do {
            let events = try await calendar.listUpcomingEvents(query: nil, withinDays: 1)
            calendarConnected = true
            for e in events {
                guard let start = e.startsAt, start >= startOfDay, start < endOfDay else { continue }
                collected.append(ScheduleItem(
                    id: "cal-\(e.id)", kind: .termin, time: e.isAllDay ? nil : start, isOverdue: false,
                    title: e.title, subtitle: e.location, projektNummer: nil))
            }
        } catch {
            calendarConnected = false
        }

        // 3) ClickUp-Fälligkeiten (heute fällig oder überfällig), projektübergreifend.
        let refs: [ProjectClickUpRef] = projects.compactMap { p in
            guard let listID = p.links.clickUpListID, listID.isEmpty == false else { return nil }
            return ProjectClickUpRef(projectNumber: p.projectNumber, title: p.title, listID: listID)
        }
        if refs.isEmpty == false {
            let clickUp = self.clickUp
            let clickUpItems = await withTaskGroup(of: [ScheduleItem].self) { group in
                for ref in refs {
                    group.addTask {
                        guard let tasks = try? await clickUp.tasks(listID: ref.listID) else { return [] }
                        return tasks.compactMap { t -> ScheduleItem? in
                            guard let due = t.dueDate, due < endOfDay else { return nil }
                            // Erledigte Custom-Status rausfiltern: ClickUps
                            // `include_closed=false` filtert nur den Status-TYP
                            // "closed" — Custom-Status wie "complete" rutschen
                            // durch und fluteten die Liste als "überfällig".
                            guard Self.istErledigt(t.status) == false else { return nil }
                            return ScheduleItem(
                                id: "cu-\(t.id)", kind: .aufgabe, time: due, isOverdue: due < now,
                                title: t.name, subtitle: "\(ref.title) · \(t.status)",
                                projektNummer: ref.projectNumber)
                        }
                    }
                }
                var out: [ScheduleItem] = []
                for await part in group { out.append(contentsOf: part) }
                return out
            }
            collected.append(contentsOf: clickUpItems)
        }

        guard mine == gen else { return }
        // Überfällige zuerst (Zeit in der Vergangenheit), dann chronologisch; ganztägig an den Tagesanfang.
        items = collected.sorted { ($0.time ?? startOfDay) < ($1.time ?? startOfDay) }
        isLoading = false
        loaded = true
    }

    /// Erledigt-Erkennung über gängige (Custom-)Status-Namen, case-insensitiv.
    nonisolated static func istErledigt(_ status: String) -> Bool {
        let done: Set<String> = ["complete", "completed", "done", "closed",
                                 "erledigt", "abgeschlossen", "fertig"]
        return done.contains(status.trimmingCharacters(in: .whitespaces).lowercased())
    }
}

// MARK: - HeuteAnstehendView
struct HeuteAnstehendView: View {
    @Environment(AppState.self) private var appState
    @State private var loader = ScheduleLoader()
    @State private var scope: ScheduleScope = .gesamt
    @State private var expanded = false

    /// Kompakt-Limit (Johannes, 2026-07-04: Block war "viel zu lang") — mehr nur auf Klick.
    private static let kompaktLimit = 6

    private var scopedItems: [ScheduleItem] {
        switch scope {
        case .gesamt:  return loader.items
        case .clickup: return loader.items.filter { $0.kind == .aufgabe }
        case .projekt: return loader.items.filter { $0.isProjectBound }
        }
    }

    private var visibleItems: [ScheduleItem] {
        expanded ? scopedItems : Array(scopedItems.prefix(Self.kompaktLimit))
    }

    private var hiddenCount: Int { max(0, scopedItems.count - Self.kompaktLimit) }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            header
            content
            sourceLine
        }
        .padding(MykSpace.s5)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.lg)
                .fill(MykColor.card.color)
                .overlay(RoundedRectangle(cornerRadius: MykRadius.lg).stroke(MykColor.line.color, lineWidth: 1))
        )
        .task(id: appState.registry.projects.count) {
            await loader.load(
                projects: appState.registry.activeProjects(),
                bookedSegments: appState.timer.bookedSegments,
                now: Date())
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Heute anstehend").mykWidgetTitle()
            Spacer()
            ScopeToggle(scope: $scope)
        }
    }

    @ViewBuilder private var content: some View {
        if loader.isLoading && loader.loaded == false {
            Text("Lädt …")
                .font(.mykMono(11)).foregroundStyle(MykColor.muted.color)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, MykSpace.s4)
        } else if visibleItems.isEmpty {
            Text(scope == .gesamt ? "Nichts für heute anstehend." : "Nichts in dieser Ansicht.")
                .font(.mykBody).foregroundStyle(MykColor.muted.color)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, MykSpace.s4)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                    if index > 0 { Divider().overlay(MykColor.line.color.opacity(0.5)) }
                    ScheduleRow(item: item)
                }
                if hiddenCount > 0 || expanded {
                    Divider().overlay(MykColor.line.color.opacity(0.5))
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() }
                    } label: {
                        Text(expanded ? "Weniger anzeigen" : "+\(hiddenCount) weitere anzeigen")
                            .font(.mykMono(10)).tracking(0.5)
                            .foregroundStyle(MykColor.muted.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, MykSpace.s3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(expanded ? "Weniger anzeigen" : "\(hiddenCount) weitere Einträge anzeigen")
                }
            }
        }
    }

    private var sourceLine: some View {
        let terminN  = loader.items.filter { $0.kind == .termin }.count
        let aufgabeN = loader.items.filter { $0.kind == .aufgabe }.count
        let zeitN    = loader.items.filter { $0.kind == .zeit }.count
        var parts: [String] = []
        if loader.calendarConnected { parts.append("KALENDER \(terminN)") } else { parts.append("KALENDER —") }
        parts.append("CLICKUP \(aufgabeN)")
        parts.append("ZEIT \(zeitN)")
        return Text(parts.joined(separator: "  ·  "))
            .font(.mykMono(9)).tracking(0.5)
            .foregroundStyle(MykColor.faint.color)
    }
}

// MARK: - ScopeToggle
private struct ScopeToggle: View {
    @Binding var scope: ScheduleScope

    var body: some View {
        HStack(spacing: 2) {
            ForEach(ScheduleScope.allCases) { s in
                Button { scope = s } label: {
                    Text(s.label)
                        .font(.mykMono(10)).tracking(0.5)
                        .padding(.horizontal, MykSpace.s4).padding(.vertical, 5)
                        .foregroundStyle(scope == s ? MykColor.paper.color : MykColor.muted.color)
                        .background(Capsule().fill(scope == s ? MykColor.ink.color : Color.clear))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ansicht: \(s.label)")
            }
        }
        .padding(3)
        .background(Capsule().fill(MykColor.paper2.color))
    }
}

// MARK: - ScheduleRow
private struct ScheduleRow: View {
    let item: ScheduleItem

    var body: some View {
        HStack(spacing: MykSpace.s4) {
            Text(timeText)
                .font(.mykMono(11)).foregroundStyle(item.isOverdue ? MykColor.critical.color : MykColor.muted.color)
                .frame(width: 48, alignment: .leading)
            Circle().fill(item.color).frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title).font(.mykBody).foregroundStyle(MykColor.ink.color).lineLimit(1)
                if let sub = item.subtitle, sub.isEmpty == false {
                    Text(sub).font(.mykMono(10)).foregroundStyle(MykColor.muted.color).lineLimit(1)
                }
            }
            Spacer()
            Text(item.kindLabel)
                .font(.mykMono(9)).tracking(0.5).textCase(.uppercase)
                .foregroundStyle(item.color)
        }
        .padding(.vertical, MykSpace.s3)
    }

    private var timeText: String {
        if item.kind == .aufgabe && item.isOverdue { return "fällig" }
        guard let t = item.time else { return "ganztg" }
        return t.formatted(.dateTime.hour().minute())
    }
}
