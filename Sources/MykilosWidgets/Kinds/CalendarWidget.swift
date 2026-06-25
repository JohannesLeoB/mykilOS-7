import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - CalendarWidget
// Termine vom primären Google-Kalender, gefiltert über Project.links.calendarQuery.
// Salbei.
public struct CalendarWidget: View {
    public let projectID: String
    public let calendarQuery: String?

    public init(projectID: String, calendarQuery: String?) {
        self.projectID = projectID
        self.calendarQuery = calendarQuery
    }

    @State private var loader = CalendarEventLoader()

    public var body: some View {
        WidgetContainer(
            kind: .calendar,
            sourceLabel: "KALENDER  ·  GOOGLE",
            renderState: loader.renderState,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                widgetHeader
                eventList
            }
        }
        .task(id: calendarQuery) {
            await loader.load(query: calendarQuery)
        }
    }

    private var widgetHeader: some View {
        HStack {
            SourceChip(kind: .calendar)
            Text("Termine").mykWidgetTitle()
            Spacer()
            if case .error = loader.renderState {
                retryButton
            } else if case .permissionRequired = loader.renderState {
                retryButton
            }
        }
    }

    private var retryButton: some View {
        Button("Erneut versuchen") {
            Task { await loader.load(query: calendarQuery) }
        }
        .font(.mykMono(9.5))
        .buttonStyle(.plain)
        .foregroundStyle(MykColor.people.color)
    }

    private var eventList: some View {
        VStack(spacing: 0) {
            ForEach(loader.events) { event in
                EventRow(event: event)
                if event.id != loader.events.last?.id {
                    Divider().overlay(MykColor.line.color.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - CalendarEventLoader
// Pro Widget-Instanz, kein geteilter Zustand — reine Lesefetches, kein
// Speichern-Vertrag wie bei NoteStore/WidgetBoardStore.
@MainActor
@Observable
private final class CalendarEventLoader {
    private(set) var events: [GoogleCalendarEvent] = []
    private(set) var renderState: WidgetRenderState = .loading

    private let client: GoogleCalendarFetching

    init(client: GoogleCalendarFetching = GoogleCalendarClient()) {
        self.client = client
    }

    func load(query: String?) async {
        guard let query, query.isEmpty == false else {
            events = []
            renderState = .empty
            return
        }
        renderState = .loading
        do {
            let result = try await client.listUpcomingEvents(query: query, withinDays: 14)
            events = result
            renderState = result.isEmpty ? .empty : .content
        } catch GoogleCalendarError.notConnected {
            events = []
            renderState = .permissionRequired
        } catch {
            events = []
            renderState = .error(String(describing: error))
        }
    }
}

// MARK: - EventRow
private struct EventRow: View {
    let event: GoogleCalendarEvent

    var body: some View {
        HStack(spacing: MykSpace.s4) {
            RoundedRectangle(cornerRadius: 4)
                .stroke(MykColor.people.color, lineWidth: 1.5)
                .frame(width: 14, height: 14).padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title).font(.mykSmall).foregroundStyle(MykColor.ink.color)
                Text(subtitle).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
            Spacer()
        }
        .padding(.vertical, MykSpace.s4)
    }

    private var subtitle: String {
        var parts: [String] = []
        if let startsAt = event.startsAt {
            parts.append(
                event.isAllDay
                    ? startsAt.formatted(.dateTime.day().month())
                    : startsAt.formatted(.dateTime.weekday(.abbreviated).hour().minute())
            )
        }
        if let location = event.location { parts.append(location) }
        return parts.joined(separator: "  ·  ").uppercased()
    }
}
