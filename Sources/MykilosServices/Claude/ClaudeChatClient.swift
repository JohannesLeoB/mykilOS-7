import Foundation
import MykilosKit

// MARK: - Antwort-Modell (tool-aware)
public struct ClaudeToolUse: Sendable, Equatable {
    public let id: String
    public let name: String
    public let inputJSON: Data      // rohes Input-Objekt aus der tool_use-Antwort
}

public struct ClaudeChatResponse: Sendable, Equatable {
    public let text: String
    public let toolUses: [ClaudeToolUse]
    public let stopReason: String?
}

// MARK: - Wire-Blöcke (API-Form). Phase 1 = Text, Phase 2 = tool_use/tool_result.
enum ClaudeWireBlock: Encodable, Equatable {
    case text(String)
    case toolUse(id: String, name: String, input: [String: String])
    case toolResult(toolUseID: String, content: String, isError: Bool)

    enum CodingKeys: String, CodingKey {
        case type, text, id, name, input
        case toolUseID = "tool_use_id", content, isError = "is_error"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let t):
            try c.encode("text", forKey: .type); try c.encode(t, forKey: .text)
        case .toolUse(let id, let name, let input):
            try c.encode("tool_use", forKey: .type)
            try c.encode(id, forKey: .id); try c.encode(name, forKey: .name); try c.encode(input, forKey: .input)
        case .toolResult(let tid, let content, let isError):
            try c.encode("tool_result", forKey: .type)
            try c.encode(tid, forKey: .toolUseID); try c.encode(content, forKey: .content); try c.encode(isError, forKey: .isError)
        }
    }
}

struct ClaudeWireMessage: Encodable, Equatable {
    var role: String
    var content: [ClaudeWireBlock]
}

struct ClaudeChatRequestPayload: Encodable {
    var model: String
    var maxTokens: Int
    var system: String
    var messages: [ClaudeWireMessage]
    var tools: [ClaudeToolDefinition]?

    enum CodingKeys: String, CodingKey {
        case model, maxTokens = "max_tokens", system, messages, tools
    }
}

// MARK: - ClaudeChatClient
// Multi-Turn-Chat mit Tool-Use über die Anthropic Messages API. Parallel zum
// bestehenden ClaudeMessagesClient (Einmal-Summary bleibt unangetastet). Teilt
// Keychain-Credentials + injizierbaren HTTP-Client → testbar ohne Netz/Keychain.
public struct ClaudeChatClient: AssistantConversing {
    private let credentialsStore: ClaudeCredentialsStoring
    private let httpClient: ClaudeHTTPClient
    private let baseURL: URL

    public init(
        credentialsStore: ClaudeCredentialsStoring = KeychainClaudeCredentialsStore(),
        httpClient: ClaudeHTTPClient = URLSession.shared,
        baseURL: URL = URL(string: "https://api.anthropic.com/v1/messages")!
    ) {
        self.credentialsStore = credentialsStore
        self.httpClient = httpClient
        self.baseURL = baseURL
    }

    public func respond(
        messages: [ChatMessage], system: String, tools: [ClaudeToolDefinition], maxTokens: Int
    ) async throws -> ClaudeChatResponse {
        guard let credentials = try credentialsStore.load() else { throw ClaudeClientError.notConnected }
        let request = try Self.buildRequest(
            url: baseURL, credentials: credentials, messages: messages, system: system, tools: tools, maxTokens: maxTokens
        )
        let (data, response) = try await httpClient.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClaudeClientError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw Self.mapHTTPError(status: http.statusCode, response: http) }
        return try Self.parseResponse(from: data)
    }

    /// Bequemer Text-Only-Aufruf (keine Tools).
    public func chat(messages: [ChatMessage], system: String, maxTokens: Int = 1024) async throws -> String {
        let response = try await respond(messages: messages, system: system, tools: [], maxTokens: maxTokens)
        guard response.text.isEmpty == false else { throw ClaudeClientError.emptyResponse }
        return response.text
    }

    // MARK: - Reine, testbare Bausteine (kein Netz/Keychain)

    static func buildRequest(
        url: URL, credentials: ClaudeCredentials, messages: [ChatMessage],
        system: String, tools: [ClaudeToolDefinition], maxTokens: Int
    ) throws -> URLRequest {
        let payload = ClaudeChatRequestPayload(
            model: credentials.model, maxTokens: maxTokens, system: system,
            messages: messages.map(wire(from:)),
            tools: tools.isEmpty ? nil : tools
        )
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(credentials.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(payload)
        return request
    }

    // Domäne → Wire. Text, tool_use, tool_result; image/document folgen in Phase 3.
    static func wire(from message: ChatMessage) -> ClaudeWireMessage {
        var blocks: [ClaudeWireBlock] = []
        for block in message.blocks {
            switch block {
            case .text(let t):
                blocks.append(.text(t))
            case .toolUse(let id, let name, let inputJSON):
                let input = (try? JSONDecoder().decode([String: String].self, from: inputJSON)) ?? [:]
                blocks.append(.toolUse(id: id, name: name, input: input))
            case .toolResult(let tid, let summary, let isError):
                blocks.append(.toolResult(toolUseID: tid, content: summary, isError: isError))
            case .image, .document:
                break   // Phase 3
            }
        }
        if blocks.isEmpty { blocks = [.text(" ")] }   // API lehnt leere content-Blöcke ab
        return ClaudeWireMessage(role: message.role.rawValue, content: blocks)
    }

    // Tool-aware Parsing über JSONSerialization (tool_use.input ist beliebiges Objekt).
    static func parseResponse(from data: Data) throws -> ClaudeChatResponse {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ClaudeClientError.decodingFailed
        }
        let stopReason = obj["stop_reason"] as? String
        let content = obj["content"] as? [[String: Any]] ?? []
        var texts: [String] = []
        var toolUses: [ClaudeToolUse] = []
        for block in content {
            switch block["type"] as? String {
            case "text":
                if let t = (block["text"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), t.isEmpty == false {
                    texts.append(t)
                }
            case "tool_use":
                let id = block["id"] as? String ?? ""
                let name = block["name"] as? String ?? ""
                let input = block["input"] as? [String: Any] ?? [:]
                let inputData = (try? JSONSerialization.data(withJSONObject: input)) ?? Data("{}".utf8)
                toolUses.append(ClaudeToolUse(id: id, name: name, inputJSON: inputData))
            default:
                break
            }
        }
        return ClaudeChatResponse(text: texts.joined(separator: "\n\n"), toolUses: toolUses, stopReason: stopReason)
    }

    static func mapHTTPError(status: Int, response: HTTPURLResponse) -> ClaudeClientError {
        switch status {
        case 429:
            let retry = response.value(forHTTPHeaderField: "retry-after").flatMap { Int($0) }
            return .rateLimited(retryAfter: retry)
        case 529:
            return .overloaded
        default:
            return .httpError(status)
        }
    }
}
