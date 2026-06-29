import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

struct ClaudeChatClientTests {

    private let creds = ClaudeCredentials(apiKey: "sk-ant-test", model: "claude-sonnet-4-6")
    private let url = URL(string: "https://api.anthropic.com/v1/messages")!

    private func toolDef() -> ClaudeToolDefinition {
        ClaudeToolDefinition(
            name: "search_gmail", description: "sucht mail",
            inputSchema: .init(properties: ["query": .init(type: "string", description: "q")], required: ["query"])
        )
    }

    // MARK: Request: System + Turns + tools[]
    @Test func buildRequestEnthaeltSystemTurnsUndTools() throws {
        let messages: [ChatMessage] = [.text("Hallo", role: .user), .text("Hi", role: .assistant), .text("Suche Mail von Gesa", role: .user)]
        let request = try ClaudeChatClient.buildRequest(
            url: url, credentials: creds, messages: messages, system: "Du bist der Assistent.", tools: [toolDef()], maxTokens: 512
        )
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "sk-ant-test")
        let json = try JSONSerialization.jsonObject(with: #require(request.httpBody)) as? [String: Any]
        #expect(json?["model"] as? String == "claude-sonnet-4-6")
        #expect(json?["system"] as? String == "Du bist der Assistent.")
        #expect((json?["messages"] as? [[String: Any]])?.count == 3)
        let tools = json?["tools"] as? [[String: Any]]
        #expect(tools?.first?["name"] as? String == "search_gmail")
        #expect((tools?.first?["input_schema"] as? [String: Any])?["type"] as? String == "object")
    }

    @Test func buildRequestOhneToolsLaesstToolsWeg() throws {
        let request = try ClaudeChatClient.buildRequest(
            url: url, credentials: creds, messages: [.text("hi", role: .user)], system: "s", tools: [], maxTokens: 100
        )
        let json = try JSONSerialization.jsonObject(with: #require(request.httpBody)) as? [String: Any]
        #expect(json?["tools"] == nil)
    }

    // MARK: tool_use-Turn als Wire (Domäne → API)
    @Test func toolUseUndResultWerdenAlsWireKodiert() throws {
        let assistant = ChatMessage(role: .assistant, blocks: [
            .text("Ich schaue nach."),
            .toolUse(id: "tu_1", name: "search_gmail", inputJSON: Data(#"{"query":"from:gesa"}"#.utf8)),
        ])
        let toolResult = ChatMessage(role: .user, blocks: [.toolResult(toolUseID: "tu_1", summary: "1 Treffer", isError: false)])
        let request = try ClaudeChatClient.buildRequest(
            url: url, credentials: creds, messages: [assistant, toolResult], system: "s", tools: [], maxTokens: 100
        )
        let json = try JSONSerialization.jsonObject(with: #require(request.httpBody)) as? [String: Any]
        let msgs = json?["messages"] as? [[String: Any]]
        let aBlocks = msgs?[0]["content"] as? [[String: Any]]
        #expect(aBlocks?[1]["type"] as? String == "tool_use")
        #expect(aBlocks?[1]["name"] as? String == "search_gmail")
        #expect((aBlocks?[1]["input"] as? [String: Any])?["query"] as? String == "from:gesa")
        let rBlocks = msgs?[1]["content"] as? [[String: Any]]
        #expect(rBlocks?[0]["type"] as? String == "tool_result")
        #expect(rBlocks?[0]["tool_use_id"] as? String == "tu_1")
        // S24-Regression: eine Tool-Use-Nachricht als erste Nachricht wird NICHT
        // als „führende Begrüßung" verworfen (Tool-Semantik bleibt intakt).
        #expect(msgs?.count == 2)
        #expect(msgs?[0]["role"] as? String == "assistant")
    }

    // MARK: S24 — sanitize() hält die messages[]-Liste API-gültig (Anti-400)
    private func messages(of request: URLRequest) throws -> [[String: Any]] {
        let json = try JSONSerialization.jsonObject(with: #require(request.httpBody)) as? [String: Any]
        return (json?["messages"] as? [[String: Any]]) ?? []
    }

    @Test func sanitizeVerwirftLeereTextNachrichtUndFusioniertRest() throws {
        // Ein leerer/Whitespace-Assistenten-Turn (z.B. ein Fehl-Turn) darf nie an die API:
        // er wird verworfen, die umgebenden user-Turns werden zu einem fusioniert.
        let msgs = try messages(of: try ClaudeChatClient.buildRequest(
            url: url, credentials: creds,
            messages: [.text("hi", role: .user), .text("   ", role: .assistant), .text("weiter", role: .user)],
            system: "s", tools: [], maxTokens: 100))
        #expect(msgs.count == 1)
        #expect(msgs[0]["role"] as? String == "user")
        #expect((msgs[0]["content"] as? [[String: Any]])?.count == 2)
    }

    @Test func sanitizeVerwirftFuehrendeAssistentenBegruessung() throws {
        let msgs = try messages(of: try ClaudeChatClient.buildRequest(
            url: url, credentials: creds,
            messages: [.text("Willkommen!", role: .assistant), .text("meine frage", role: .user)],
            system: "s", tools: [], maxTokens: 100))
        #expect(msgs.count == 1)
        #expect(msgs[0]["role"] as? String == "user")
    }

    @Test func sanitizeFusioniertAufeinanderfolgendeGleicheRollen() throws {
        let msgs = try messages(of: try ClaudeChatClient.buildRequest(
            url: url, credentials: creds,
            messages: [.text("a", role: .user), .text("b", role: .user)],
            system: "s", tools: [], maxTokens: 100))
        #expect(msgs.count == 1)
        #expect((msgs[0]["content"] as? [[String: Any]])?.count == 2)
    }

    @Test func sanitizeNotfallLiefertGueltigeUserNachricht() {
        // Alles leer → genau eine gültige (nicht-leere) user-Nachricht, nie ein leeres Array.
        let result = ClaudeChatClient.sanitize([])
        #expect(result.count == 1)
        #expect(result[0].role == "user")
    }

    // MARK: Response-Parsing (Text + tool_use + stop_reason)
    @Test func parseResponseLiestTextUndToolUse() throws {
        let data = #"""
        {"stop_reason":"tool_use","content":[
          {"type":"text","text":"Ich suche."},
          {"type":"tool_use","id":"tu_1","name":"search_gmail","input":{"query":"from:gesa"}}
        ]}
        """#.data(using: .utf8)!
        let response = try ClaudeChatClient.parseResponse(from: data)
        #expect(response.text == "Ich suche.")
        #expect(response.stopReason == "tool_use")
        #expect(response.toolUses.count == 1)
        #expect(response.toolUses[0].name == "search_gmail")
        let input = try JSONSerialization.jsonObject(with: response.toolUses[0].inputJSON) as? [String: Any]
        #expect(input?["query"] as? String == "from:gesa")
    }

    @Test func parseResponseReinerText() throws {
        let data = #"{"stop_reason":"end_turn","content":[{"type":"text","text":"Antwort A."},{"type":"text","text":"Antwort B."}]}"#.data(using: .utf8)!
        let response = try ClaudeChatClient.parseResponse(from: data)
        #expect(response.text == "Antwort A.\n\nAntwort B.")
        #expect(response.toolUses.isEmpty)
    }

    // MARK: HTTP-Fehler-Mapping
    @Test func httpFehlerWerdenGemappt() {
        let r429 = HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: ["retry-after": "30"])!
        let r529 = HTTPURLResponse(url: url, statusCode: 529, httpVersion: nil, headerFields: nil)!
        #expect(ClaudeChatClient.mapHTTPError(status: 429, response: r429) == .rateLimited(retryAfter: 30))
        #expect(ClaudeChatClient.mapHTTPError(status: 529, response: r529) == .overloaded)
        #expect(ClaudeChatClient.mapHTTPError(status: 500, response: HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!) == .httpError(500))
    }

    // MARK: respond()/chat() über Fake-HTTP
    @Test func respondOhneVerbindungWirftNotConnected() async {
        let client = ClaudeChatClient(credentialsStore: FakeChatCredentials(stored: nil), httpClient: FakeChatHTTP(result: .success((Data(), HTTPURLResponse()))), baseURL: url)
        await #expect(throws: ClaudeClientError.notConnected) {
            _ = try await client.respond(messages: [.text("hi", role: .user)], system: "s", tools: [], maxTokens: 100)
        }
    }

    @Test func chatGibtTextZurueck() async throws {
        let body = #"{"stop_reason":"end_turn","content":[{"type":"text","text":"Live-Antwort."}]}"#.data(using: .utf8)!
        let ok = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let client = ClaudeChatClient(credentialsStore: FakeChatCredentials(stored: creds), httpClient: FakeChatHTTP(result: .success((body, ok))), baseURL: url)
        #expect(try await client.chat(messages: [.text("hi", role: .user)], system: "s") == "Live-Antwort.")
    }

    @Test func respondMapptRateLimit() async {
        let r429 = HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: ["retry-after": "12"])!
        let client = ClaudeChatClient(credentialsStore: FakeChatCredentials(stored: creds), httpClient: FakeChatHTTP(result: .success((Data(), r429))), baseURL: url)
        await #expect(throws: ClaudeClientError.rateLimited(retryAfter: 12)) {
            _ = try await client.respond(messages: [.text("hi", role: .user)], system: "s", tools: [], maxTokens: 100)
        }
    }
}

// MARK: - Fakes
private struct FakeChatCredentials: ClaudeCredentialsStoring {
    let stored: ClaudeCredentials?
    func store(_ credentials: ClaudeCredentials) throws {}
    func load() throws -> ClaudeCredentials? { stored }
    func clear() throws {}
}

private struct FakeChatHTTP: ClaudeHTTPClient {
    let result: Result<(Data, URLResponse), Error>
    func data(for request: URLRequest) async throws -> (Data, URLResponse) { try result.get() }
}
