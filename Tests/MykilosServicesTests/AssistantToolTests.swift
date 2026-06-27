import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

struct AssistantToolTests {

    // MARK: Whitelist enthält die erwarteten Tools, input_schema serialisiert
    @Test func standardRegistryHatErwarteteTools() throws {
        let registry = AssistantToolRegistry.standard()
        #expect(registry.toolNames.sorted() == ["list_calendar_events", "search_gmail"])

        let defs = registry.definitions()
        let json = try JSONEncoder().encode(defs)
        let arr = try JSONSerialization.jsonObject(with: json) as? [[String: Any]]
        let gmail = arr?.first { $0["name"] as? String == "search_gmail" }
        let schema = gmail?["input_schema"] as? [String: Any]
        #expect(schema?["type"] as? String == "object")
        let props = schema?["properties"] as? [String: Any]
        #expect(props?["query"] != nil)
        #expect((schema?["required"] as? [String])?.contains("query") == true)
    }

    // MARK: NO-GO — Sevdesk taucht NIRGENDS auf (Name/Definition/Run)
    @Test func keinSevdeskTool() async throws {
        let registry = AssistantToolRegistry.standard()
        #expect(registry.toolNames.contains { $0.localizedCaseInsensitiveContains("sevdesk") } == false)

        let json = String(data: try JSONEncoder().encode(registry.definitions()), encoding: .utf8) ?? ""
        #expect(json.localizedCaseInsensitiveContains("sevdesk") == false)

        let result = await registry.run(name: "sevdesk_invoices", inputJSON: Data("{}".utf8))
        #expect(result.isError == true)
        #expect(result.text.contains("nicht erlaubt"))
    }

    // MARK: SearchGmailTool — Formatierung + Query-Durchreichung
    @Test func gmailToolFormatiertTreffer() async {
        let fake = FakeGmail(messages: [
            GoogleGmailMessage(id: "1", subject: "Angebot Arbeitsplatte", from: "gesa@gesahansen.com",
                               snippet: "Hier das Angebot …", receivedAt: Date(timeIntervalSince1970: 1_800_000_000)),
        ])
        let registry = AssistantToolRegistry.standard(gmail: fake)
        let result = await registry.run(name: "search_gmail", inputJSON: Data(#"{"query":"from:gesa"}"#.utf8))
        #expect(result.isError == false)
        #expect(result.text.contains("Angebot Arbeitsplatte"))
        #expect(result.text.contains("gesa@gesahansen.com"))
        #expect(fake.lastQuery == "from:gesa")
    }

    @Test func gmailToolLeeresErgebnis() async {
        let registry = AssistantToolRegistry.standard(gmail: FakeGmail(messages: []))
        let result = await registry.run(name: "search_gmail", inputJSON: Data(#"{"query":"x"}"#.utf8))
        #expect(result.isError == false)
        #expect(result.text.contains("Keine Mails"))
    }

    @Test func gmailToolNichtVerbunden() async {
        let registry = AssistantToolRegistry.standard(gmail: FakeGmail(error: GoogleGmailError.notConnected))
        let result = await registry.run(name: "search_gmail", inputJSON: Data(#"{"query":"x"}"#.utf8))
        #expect(result.isError == true)
        #expect(result.text.contains("nicht verbunden"))
    }

    // MARK: ListCalendarTool
    @Test func calendarToolFormatiertTermine() async {
        let fake = FakeCalendar(events: [
            GoogleCalendarEvent(id: "e1", title: "Sync Gesa", startsAt: Date(timeIntervalSince1970: 1_800_000_000),
                                isAllDay: false, location: "Meet"),
        ])
        let registry = AssistantToolRegistry.standard(calendar: fake)
        let result = await registry.run(name: "list_calendar_events", inputJSON: Data("{}".utf8))
        #expect(result.isError == false)
        #expect(result.text.contains("Sync Gesa"))
    }

    // MARK: Unbekanntes Tool → Deny
    @Test func unbekanntesToolWirdAbgelehnt() async {
        let result = await AssistantToolRegistry.standard().run(name: "rm_rf", inputJSON: Data("{}".utf8))
        #expect(result.isError == true)
    }
}

// MARK: - Fakes
private final class FakeGmail: GoogleGmailFetching, @unchecked Sendable {
    let messages: [GoogleGmailMessage]
    let error: Error?
    private(set) var lastQuery: String?
    init(messages: [GoogleGmailMessage] = [], error: Error? = nil) { self.messages = messages; self.error = error }
    func searchMessages(query: String, maxResults: Int) async throws -> [GoogleGmailMessage] {
        lastQuery = query
        if let error { throw error }
        return messages
    }
}

private struct FakeCalendar: GoogleCalendarFetching {
    let events: [GoogleCalendarEvent]
    var error: Error?
    init(events: [GoogleCalendarEvent] = [], error: Error? = nil) { self.events = events; self.error = error }
    func listUpcomingEvents(query: String?, withinDays: Int) async throws -> [GoogleCalendarEvent] {
        if let error { throw error }
        return events
    }
}
