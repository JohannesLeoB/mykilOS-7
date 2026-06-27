import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

@MainActor
struct ConversationEngineTests {

    // Skript-Provider: liefert nacheinander vordefinierte Antworten, merkt sich Args.
    final class ScriptedProvider: AssistantConversing, @unchecked Sendable {
        var responses: [ClaudeChatResponse]
        var error: Error?
        private(set) var callCount = 0
        private(set) var lastTools: [ClaudeToolDefinition] = []
        init(responses: [ClaudeChatResponse] = [], error: Error? = nil) { self.responses = responses; self.error = error }
        func respond(messages: [ChatMessage], system: String, tools: [ClaudeToolDefinition], maxTokens: Int) async throws -> ClaudeChatResponse {
            lastTools = tools; callCount += 1
            if let error { throw error }
            return responses[min(callCount - 1, responses.count - 1)]
        }
    }

    private func textResponse(_ t: String) -> ClaudeChatResponse {
        ClaudeChatResponse(text: t, toolUses: [], stopReason: "end_turn")
    }

    @Test func sendHaengtUserUndAssistentAn() async throws {
        let store = ChatStore(db: try GRDBDatabase.inMemory())
        let provider = ScriptedProvider(responses: [textResponse("Drei Punkte für Montag.")])
        let engine = ConversationEngine(chatStore: store, provider: provider)
        await engine.send("Was ist Montag?", scope: .home, focusedProjectID: nil, signals: [], projects: [], now: Date(timeIntervalSince1970: 1_800_000_000))

        let msgs = store.messages(for: .home)
        #expect(msgs.count == 2)
        #expect(msgs[0].role == .user && msgs[0].text == "Was ist Montag?")
        #expect(msgs[1].role == .assistant && msgs[1].status == .complete && msgs[1].text == "Drei Punkte für Montag.")
        #expect(provider.lastTools.isEmpty)   // toolsEnabled default false → keine Tools
    }

    @Test func sendMarkiertTurnBeiFehlerAlsFailed() async throws {
        let store = ChatStore(db: try GRDBDatabase.inMemory())
        let engine = ConversationEngine(chatStore: store, provider: ScriptedProvider(error: ClaudeClientError.notConnected))
        await engine.send("hallo", scope: .home, focusedProjectID: nil, signals: [], projects: [], now: Date())
        let last = store.messages(for: .home).last
        if case .failed = last?.status { } else { Issue.record("Erwarte .failed") }
        #expect(last?.text.contains("nicht verbunden") == true)
    }

    @Test func leereEingabeSendetNicht() async throws {
        let store = ChatStore(db: try GRDBDatabase.inMemory())
        let engine = ConversationEngine(chatStore: store, provider: ScriptedProvider(responses: [textResponse("x")]))
        await engine.send("   ", scope: .home, focusedProjectID: nil, signals: [], projects: [], now: Date())
        #expect(store.messages(for: .home).isEmpty)
    }

    // MARK: Agentische Tool-Schleife — tool_use → Tool ausführen → finale Antwort
    @Test func toolSchleifeFuehrtToolAusUndAntwortet() async throws {
        let store = ChatStore(db: try GRDBDatabase.inMemory())
        let fakeGmail = FakeGmailForEngine(messages: [
            GoogleGmailMessage(id: "1", subject: "Angebot", from: "gesa@gesahansen.com", snippet: "…", receivedAt: nil),
        ])
        let registry = AssistantToolRegistry.standard(gmail: fakeGmail)
        let toolUse = ClaudeToolUse(id: "tu_1", name: "search_gmail", inputJSON: Data(#"{"query":"from:gesa"}"#.utf8))
        let provider = ScriptedProvider(responses: [
            ClaudeChatResponse(text: "", toolUses: [toolUse], stopReason: "tool_use"),
            textResponse("Ich habe 1 Mail von Gesa gefunden."),
        ])
        let engine = ConversationEngine(chatStore: store, provider: provider, registry: registry)

        await engine.send("Wo ist die Mail an Gesa?", scope: .home, focusedProjectID: nil, signals: [], projects: [], toolsEnabled: true)

        #expect(provider.callCount == 2)            // Tool-Runde + finale Runde
        #expect(provider.lastTools.isEmpty == false) // Tools wurden mitgeschickt
        #expect(fakeGmail.lastQuery == "from:gesa")  // Tool tatsächlich ausgeführt
        let last = store.messages(for: .home).last
        #expect(last?.role == .assistant && last?.status == .complete)
        #expect(last?.text == "Ich habe 1 Mail von Gesa gefunden.")
        // Persistiert wird nur der finale Antwort-Turn (kein tool_use-Rauschen im Verlauf).
        #expect(store.messages(for: .home).count == 2)
        // Tool-Spur (Transparenz) ist im finalen Turn als reine Anzeige enthalten.
        #expect(last?.blocks.contains { if case .toolActivity = $0 { true } else { false } } == true)
    }

    // MARK: Streaming-Pfad (toolsEnabled: false → streamText-Fallback via Default-Extension)
    @Test func sendStreamtTextInkrementiell() async throws {
        let store = ChatStore(db: try GRDBDatabase.inMemory())
        // MultiDeltaProvider gibt 3 Deltas über streamText zurück.
        let provider = MultiDeltaProvider(deltas: ["Hallo", " Welt", "!"])
        let engine = ConversationEngine(chatStore: store, provider: provider)
        await engine.send("hi", scope: .home, focusedProjectID: nil, signals: [], projects: [], toolsEnabled: false)
        let msgs = store.messages(for: .home)
        #expect(msgs.count == 2)
        // Finaler Text ist die Summe aller Deltas.
        #expect(msgs[1].text == "Hallo Welt!")
        #expect(msgs[1].status == .complete)
        // Provider.respond() darf NICHT aufgerufen werden — Streaming nutzt streamText().
        #expect(provider.respondCallCount == 0)
    }

    // MARK: CalendarAction-Block wird injiziert wenn Tool actionURL zurückgibt
    @Test func calendarToolInjiziertAktionsBlock() async throws {
        let store = ChatStore(db: try GRDBDatabase.inMemory())
        let calendarTool = SuggestCalendarEventTool()
        let registry = AssistantToolRegistry(tools: [calendarTool])
        let toolUse = ClaudeToolUse(id: "tu_cal", name: "suggest_calendar_event",
                                    inputJSON: Data(#"{"title":"Kundentermin"}"#.utf8))
        let provider = ScriptedProvider(responses: [
            ClaudeChatResponse(text: "", toolUses: [toolUse], stopReason: "tool_use"),
            textResponse("Ich habe einen Kalender-Link für den Kundentermin erstellt."),
        ])
        let engine = ConversationEngine(chatStore: store, provider: provider, registry: registry)

        await engine.send("Termin anlegen", scope: .home, focusedProjectID: nil, signals: [], projects: [], toolsEnabled: true)

        let last = store.messages(for: .home).last
        let hasCalendarAction = last?.blocks.contains {
            if case .calendarAction = $0 { true } else { false }
        } == true
        #expect(hasCalendarAction, "Engine muss .calendarAction-Block speichern wenn Tool actionURL zurückgibt")
    }

    @Test func toolSchleifeRespektiertOptInAus() async throws {
        let store = ChatStore(db: try GRDBDatabase.inMemory())
        let registry = AssistantToolRegistry.standard(gmail: FakeGmailForEngine(messages: []))
        let provider = ScriptedProvider(responses: [textResponse("Antwort ohne Tools.")])
        let engine = ConversationEngine(chatStore: store, provider: provider, registry: registry)
        await engine.send("frage", scope: .home, focusedProjectID: nil, signals: [], projects: [], toolsEnabled: false)
        #expect(provider.lastTools.isEmpty)   // Opt-in aus → keine Tools an die API
    }
}

// Provider, der streamText mit mehreren Deltas simuliert (kein respond()-Aufruf).
private final class MultiDeltaProvider: AssistantConversing, @unchecked Sendable {
    let deltas: [String]
    private(set) var respondCallCount = 0
    init(deltas: [String]) { self.deltas = deltas }

    func respond(messages: [ChatMessage], system: String, tools: [ClaudeToolDefinition], maxTokens: Int) async throws -> ClaudeChatResponse {
        respondCallCount += 1
        return ClaudeChatResponse(text: deltas.joined(), toolUses: [], stopReason: "end_turn")
    }

    func streamText(messages: [ChatMessage], system: String, tools: [ClaudeToolDefinition], maxTokens: Int) -> AsyncThrowingStream<String, Error> {
        let d = deltas
        return AsyncThrowingStream { continuation in
            Task {
                for delta in d { continuation.yield(delta) }
                continuation.finish()
            }
        }
    }
}

private final class FakeGmailForEngine: GoogleGmailFetching, @unchecked Sendable {
    let messages: [GoogleGmailMessage]
    private(set) var lastQuery: String?
    init(messages: [GoogleGmailMessage]) { self.messages = messages }
    func searchMessages(query: String, maxResults: Int) async throws -> [GoogleGmailMessage] {
        lastQuery = query; return messages
    }
}
