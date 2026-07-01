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
        // Stufe-2-Tests: Nachrichtenlänge je respond()-Aufruf, um zu beweisen, dass
        // die Distillation den an die API gesendeten Verlauf wirklich verkürzt.
        private(set) var messageCounts: [Int] = []
        init(responses: [ClaudeChatResponse] = [], error: Error? = nil) { self.responses = responses; self.error = error }
        func respond(messages: [ChatMessage], system: String, tools: [ClaudeToolDefinition], maxTokens: Int) async throws -> ClaudeChatResponse {
            lastTools = tools; callCount += 1; messageCounts.append(messages.count)
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

    // MARK: L2 — Schätzchat-Modus GATE
    @Test func schaetzchatToolNichtImNormalModus() async throws {
        let store = ChatStore(db: try GRDBDatabase.inMemory())
        let engine = FakeKalkulationsEngine()
        let registry = AssistantToolRegistry.standard(kalkulationsEngine: engine)
        let provider = ScriptedProvider(responses: [textResponse("Ich kalkule nicht.")])
        let conv = ConversationEngine(chatStore: store, provider: provider, registry: registry)
        // Normal-Modus, toolsEnabled = false → schaetze_projekt NICHT in Tools
        let noSignals: [WidgetSignal] = []
        let noProjects: [Project] = []
        await conv.send("frage", scope: ChatScope.home, focusedProjectID: nil, signals: noSignals, projects: noProjects,
                        toolsEnabled: false, schaetzModusEnabled: false)
        let names = provider.lastTools.map(\.name)
        #expect(names.contains("schaetze_projekt") == false)
    }

    @Test func schaetzchatToolNurImSchaetzModus() async throws {
        let store = ChatStore(db: try GRDBDatabase.inMemory())
        let engine = FakeKalkulationsEngine()
        let registry = AssistantToolRegistry.standard(kalkulationsEngine: engine)
        let provider = ScriptedProvider(responses: [textResponse("Schätzung folgt.")])
        let conv = ConversationEngine(chatStore: store, provider: provider, registry: registry)
        // Schätz-Modus → schaetze_projekt in Tools; KEIN anderes Tool
        let noSignals: [WidgetSignal] = []
        let noProjects: [Project] = []
        await conv.send("4m Eichenschränke", scope: ChatScope.home, focusedProjectID: nil, signals: noSignals, projects: noProjects,
                        toolsEnabled: false, schaetzModusEnabled: true)
        let names = provider.lastTools.map(\.name)
        #expect(names.contains("schaetze_projekt"))
        // Nur schaetze_projekt — kein Mail/Kalender/Drive
        #expect(names.allSatisfy { $0 == "schaetze_projekt" })
    }

    // MARK: L5 — DataFlowLogger instrumentiert Tool-Calls
    @Test @MainActor func dataFlowLoggerLogtJedesToolRun() async throws {
        let db = try GRDBDatabase.inMemory()
        let logger = DataFlowLogger(db: db, airtable: nil)
        let kalk = FakeKalkulationsEngine()
        let registry = AssistantToolRegistry.standard(kalkulationsEngine: kalk)

        // Provider simuliert: erst tool_use (schaetze_projekt), dann Textantwort.
        let toolInput = Data(#"{"beschreibung":"5 lfm Unterschränke"}"#.utf8)
        let toolUse = ClaudeToolUse(id: "tu_l5", name: "schaetze_projekt", inputJSON: toolInput)
        let provider = ScriptedProvider(responses: [
            ClaudeChatResponse(text: "", toolUses: [toolUse], stopReason: "tool_use"),
            textResponse("Die Schätzung liegt bei ca. 15.000 €."),
        ])

        let conv = ConversationEngine(
            chatStore: ChatStore(db: db),
            provider: provider,
            registry: registry,
            dataFlowLogger: logger
        )
        await conv.send("Schätz mal", scope: .home, focusedProjectID: "P-L5",
                        signals: [], projects: [], toolsEnabled: true, schaetzModusEnabled: false)

        // GATE: Logger hat genau einen Eintrag für das schaetze_projekt-Tool.
        // Mandate E: protokolliert wird die kanonische Manifest-ID (KALKULATION_LOCAL),
        // NICHT mehr der rohe Tool-Name — sonst zeigt das Schaltzentrum 0 Handshakes.
        #expect(logger.entries.count == 1)
        #expect(logger.entries.first?.integrationID == "KALKULATION_LOCAL")
        #expect(logger.entries.first?.actorUserID == "assistant")
        #expect(logger.entries.first?.action == .success)
    }

    // MARK: Härtung 2026-07-01 — Loop-Effizienz (Wiederholungs-Erkennung + Timeout)
    // Claude fragt fünfmal identisch nach demselben (leeren) Ergebnis. Die Schleife
    // muss das nach der zweiten identischen Runde erkennen und sofort abbrechen,
    // statt bis maxToolRounds (6) durchzulaufen — sonst würde jede Wiederholung
    // eine volle, kostenpflichtige Claude-Runde kosten.
    @Test func toolSchleifeBrichtBeiWiederholtemIdentischenAufrufAb() async throws {
        let store = ChatStore(db: try GRDBDatabase.inMemory())
        let fakeGmail = FakeGmailForEngine(messages: [])
        let registry = AssistantToolRegistry.standard(gmail: fakeGmail)
        let toolUse = ClaudeToolUse(id: "tu_1", name: "search_gmail", inputJSON: Data(#"{"query":"from:nobody"}"#.utf8))
        let repeated = ClaudeChatResponse(text: "", toolUses: [toolUse], stopReason: "tool_use")
        let provider = ScriptedProvider(responses: Array(repeating: repeated, count: 6))
        let engine = ConversationEngine(chatStore: store, provider: provider, registry: registry)

        await engine.send("Suche nach nichts", scope: .home, focusedProjectID: nil, signals: [], projects: [], toolsEnabled: true)

        // Bricht nach der zweiten (wiederholten) Runde ab — nicht erst bei maxToolRounds=6.
        #expect(provider.callCount == 2)
        let last = store.messages(for: .home).last
        #expect(last?.status == .complete)
        #expect(last?.text.contains("keine neuen Daten") == true)
    }

    // Ein hängendes Tool darf die Runde nicht blockieren — winzig injiziertes Timeout
    // (statt der Produktions-15s) hält den Test schnell, prüft aber denselben Pfad.
    @Test func toolSchleifeBrichtHaengendenToolCallPerTimeoutAb() async throws {
        let store = ChatStore(db: try GRDBDatabase.inMemory())
        let slowTool = SlowAssistantTool()
        let registry = AssistantToolRegistry(tools: [slowTool])
        let toolUse = ClaudeToolUse(id: "tu_slow", name: "slow_tool", inputJSON: Data("{}".utf8))
        let provider = ScriptedProvider(responses: [
            ClaudeChatResponse(text: "", toolUses: [toolUse], stopReason: "tool_use"),
            textResponse("Fertig trotz Zeitüberschreitung."),
        ])
        let engine = ConversationEngine(
            chatStore: store, provider: provider, registry: registry, toolTimeoutSeconds: 0.05
        )

        await engine.send("Frag das langsame Tool", scope: .home, focusedProjectID: nil, signals: [], projects: [], toolsEnabled: true)

        let last = store.messages(for: .home).last
        #expect(last?.status == .complete)
        #expect(last?.text == "Fertig trotz Zeitüberschreitung.")
        // Tool-Spur zeigt einen Fehler (Zeitüberschreitung), nicht das eigentliche Ergebnis.
        let hasErrorActivity = last?.blocks.contains {
            if case .toolActivity(_, let isError) = $0 { isError } else { false }
        } == true
        #expect(hasErrorActivity)
    }

    // MARK: Stufe 2 (Härtung 2026-07-01) — Gedächtnis-Distillation
    // Baut `count` alternierende user/assistant-Turns in den Verlauf, chronologisch
    // aufsteigend (älteste zuerst), damit windowed die reale Append-Reihenfolge widerspiegelt.
    private func seedHistory(_ store: ChatStore, scope: ChatScope, count: Int, endingBefore now: Date) throws {
        for i in 0..<count {
            let t = now.addingTimeInterval(Double(i - count - 1) * 60)
            try store.append(ChatMessage(role: .user, blocks: [.text("Alte Frage \(i)")], status: .complete, createdAt: t), to: scope)
            try store.append(ChatMessage(role: .assistant, blocks: [.text("Alte Antwort \(i)")], status: .complete, createdAt: t.addingTimeInterval(5)), to: scope)
        }
    }

    @Test func distillationBleibtUnterhalbDerSchwelleAus() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = ChatStore(db: db)
        let memory = ChatMemoryStore(db: db)
        let scope = ChatScope.home
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        try seedHistory(store, scope: scope, count: 3, endingBefore: now)   // 6 alte Nachrichten — weit unter der Schwelle

        let provider = ScriptedProvider(responses: [textResponse("Finale Antwort")])
        let engine = ConversationEngine(chatStore: store, provider: provider, memoryStore: memory)
        await engine.send("Neue Frage", scope: scope, focusedProjectID: nil, signals: [], projects: [], now: now)

        #expect(provider.callCount == 1)   // kein zusätzlicher Distillations-Call
        #expect(try memory.summary(for: scope) == nil)
    }

    @Test func distillationVerdichtetAbSchwelleUndVerkuerztDenGesendetenVerlauf() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = ChatStore(db: db)
        let memory = ChatMemoryStore(db: db)
        let scope = ChatScope.home
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        try seedHistory(store, scope: scope, count: 11, endingBefore: now)   // 22 alte Nachrichten — über der Schwelle

        let provider = ScriptedProvider(responses: [
            textResponse("Zusammenfassung X"),   // Distillations-Call (1. respond())
            textResponse("Finale Antwort"),       // eigentlicher Turn (2. respond(), via streamText-Default)
        ])
        let engine = ConversationEngine(chatStore: store, provider: provider, memoryStore: memory)
        await engine.send("Neue Frage", scope: scope, focusedProjectID: nil, signals: [], projects: [], now: now)

        #expect(provider.callCount == 2)
        #expect(provider.messageCounts.first == 1)   // Distillations-Call: nur der Verdichtungs-Prompt
        // Der eigentliche Turn bekommt NICHT die volle Historie (23 inkl. neuer Frage) — deutlich weniger.
        #expect((provider.messageCounts.last ?? .max) < 23)
        #expect(try memory.summary(for: scope)?.summaryText == "Zusammenfassung X")

        let last = store.messages(for: scope).last
        #expect(last?.status == .complete && last?.text == "Finale Antwort")
    }

    @Test func distillationUeberschreibtStattAnzuhaeufen() async throws {
        let db = try GRDBDatabase.inMemory()
        let memory = ChatMemoryStore(db: db)
        let scope = ChatScope.home
        try memory.save(ChatMemorySummary(scopeKey: scope.rawKey, summaryText: "Version 1", coveredThroughMessageID: "a", updatedAt: Date()))
        try memory.save(ChatMemorySummary(scopeKey: scope.rawKey, summaryText: "Version 2", coveredThroughMessageID: "b", updatedAt: Date()))

        // EINE Zeile je Scope, nicht angehäuft — die neueste Fassung gewinnt vollständig.
        let saved = try memory.summary(for: scope)
        #expect(saved?.summaryText == "Version 2")
        #expect(saved?.summaryText.contains("Version 1") == false)
    }

    @Test func distillationIstScopeSauber() async throws {
        let db = try GRDBDatabase.inMemory()
        let memory = ChatMemoryStore(db: db)
        try memory.save(ChatMemorySummary(scopeKey: ChatScope.home.rawKey, summaryText: "Home-Summary", coveredThroughMessageID: "a", updatedAt: Date()))

        #expect(try memory.summary(for: .home)?.summaryText == "Home-Summary")
        #expect(try memory.summary(for: .project("2026-001")) == nil)   // kein Leck zwischen Scopes
    }

    // MARK: Mandate E — search_gmail loggt unter GMAIL_SEARCH (Hustadt-Gate)
    // Beweist genau die Schaltzentrum-Bedingung: nach einem echten search_gmail-
    // Tool-Lauf existiert ein DataFlow-Eintrag mit integrationID == "GMAIL_SEARCH"
    // (= die Manifest-ID, auf die das SchaltzentrumView matcht).
    @Test @MainActor func gmailToolLoggtUnterManifestIDGmailSearch() async throws {
        let db = try GRDBDatabase.inMemory()
        let logger = DataFlowLogger(db: db, airtable: nil)
        let fakeGmail = FakeGmailForEngine(messages: [
            GoogleGmailMessage(id: "1", subject: "Angebot", from: "gesa@example.com",
                               snippet: "…", receivedAt: nil),
        ])
        let registry = AssistantToolRegistry.standard(gmail: fakeGmail)

        let toolInput = Data(#"{"query":"from:gesa"}"#.utf8)
        let toolUse = ClaudeToolUse(id: "tu_gmail", name: "search_gmail", inputJSON: toolInput)
        let provider = ScriptedProvider(responses: [
            ClaudeChatResponse(text: "", toolUses: [toolUse], stopReason: "tool_use"),
            textResponse("Hier ist die Mail."),
        ])

        let conv = ConversationEngine(
            chatStore: ChatStore(db: db),
            provider: provider,
            registry: registry,
            dataFlowLogger: logger
        )
        await conv.send("Wo ist die Mail von Gesa?", scope: .home, focusedProjectID: nil,
                        signals: [], projects: [], toolsEnabled: true, schaetzModusEnabled: false)

        // GATE: genau die Schaltzentrum-Bedingung „GMAIL_SEARCH > 0 Handshakes".
        #expect(logger.entries.contains { $0.integrationID == "GMAIL_SEARCH" })
        #expect(logger.entries.contains { $0.integrationID == "search_gmail" } == false)
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

// Härtung 2026-07-01: simuliert einen hängenden Tool-Call (z. B. ein Google-Client
// ohne Antwort). Nutzt Task.sleep statt Thread.sleep, damit Task-Cancellation
// (via runToolWithTimeout's group.cancelAll()) den Test nicht ausbremst.
private final class SlowAssistantTool: AssistantTool, @unchecked Sendable {
    let name = "slow_tool"
    let description = "Testtool, das absichtlich hängt (Timeout-Test)."
    let parameters: [ToolParameter] = []
    func run(input: [String: String]) async -> ToolRunResult {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        return ToolRunResult(text: "Doch noch fertig geworden.")
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

private final class FakeKalkulationsEngine: KalkulationsEngineProviding, @unchecked Sendable {
    func schaetze(projektID: String, freitext: String) async throws -> KostenSchaetzung {
        KostenSchaetzung(schaetzungsID: "fake-id", projektID: projektID,
                         minNetto: 1000, maxNetto: 2000, mitteNetto: 1500,
                         confidence: 0.7, evidenceCount: 3,
                         kostenboden: 800, kostenbodenRatio: 0.5, topEvidences: [])
    }
    func geraetepreis(suchbegriff: String) async -> Double? { nil }
    func importPDF(driveFileID: String, projektID: String) async throws {}
    func recordAdjustment(schaetzungsID: String, faktor: Double, grund: String, lernen: Bool) async throws {}
    func lernUebersicht() async throws -> KalkulationsLernStand {
        KalkulationsLernStand(sessions: 0, adjustments: 0, outliers: 0, aktiveFaktoren: [], kandidaten: [])
    }
    func promote(candidateID: String) async throws {}
}
