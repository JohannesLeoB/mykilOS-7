import Testing
import Foundation
@testable import MykilosServices

struct GoogleCalendarClientTests {

    private let baseURL = "https://www.googleapis.com/calendar/v3/calendars/primary/events"

    @Test func urlEnthaeltZeitfensterUndQuery() {
        let now = Date(timeIntervalSinceReferenceDate: 0)
        let url = GoogleCalendarClient.buildListEventsURL(query: "ME-24", withinDays: 14, baseURL: baseURL, now: now)
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(items["singleEvents"] == "true")
        #expect(items["orderBy"] == "startTime")
        #expect(items["q"] == "ME-24")
        #expect(items["timeMin"] != nil)
        #expect(items["timeMax"] != nil)
        #expect(items["timeMin"] != items["timeMax"])
    }

    @Test func keinQParameterOhneQuery() {
        let url = GoogleCalendarClient.buildListEventsURL(query: nil, withinDays: 14, baseURL: baseURL, now: Date())
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        #expect((components?.queryItems ?? []).contains { $0.name == "q" } == false)
    }

    @Test func parseEventsDekodiertGetimteUndAllDayEvents() throws {
        let json = """
        {
          "items": [
            { "id": "1", "summary": "Aufmaß vor Ort", "location": "Musterstr. 1",
              "start": { "dateTime": "2026-06-29T09:00:00+02:00" } },
            { "id": "2", "summary": "Messetag",
              "start": { "date": "2026-07-01" } },
            { "id": "3" }
          ]
        }
        """
        let events = try GoogleCalendarClient.parseEvents(from: Data(json.utf8))

        #expect(events.count == 3)
        #expect(events[0].title == "Aufmaß vor Ort")
        #expect(events[0].isAllDay == false)
        #expect(events[0].startsAt != nil)
        #expect(events[0].location == "Musterstr. 1")
        #expect(events[1].isAllDay == true)
        #expect(events[1].startsAt != nil)
        #expect(events[2].title == "(ohne Titel)")
        #expect(events[2].startsAt == nil)
    }

    @Test func parseEventsWirftBeiKaputtemJSON() {
        #expect(throws: GoogleCalendarError.decodingFailed) {
            _ = try GoogleCalendarClient.parseEvents(from: Data("nicht json".utf8))
        }
    }

    @Test func listUpcomingEventsWirftNotConnectedOhneToken() async {
        let store = InMemoryGoogleTokenStore()
        let client = GoogleCalendarClient(tokenProvider: GoogleAccessTokenProvider(tokenStore: store))

        do {
            _ = try await client.listUpcomingEvents(query: "ME-24", withinDays: 14)
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? GoogleCalendarError == .notConnected)
        }
    }
}
