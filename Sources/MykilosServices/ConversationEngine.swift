import Foundation
import MykilosKit

// MARK: - AssistantConversing
// Tool-aware Chat-Aufruf, abstrahiert für Tests (ohne Netz/Keychain).
// (ClaudeChatClient erklärt die Konformität in seiner eigenen Datei — sonst wäre
// die Sendable-Konformität „retroactive" → Swift-6-Fehler.)
public protocol AssistantConversing: Sendable {
    func respond(
        messages: [ChatMessage], system: String, tools: [ClaudeToolDefinition], maxTokens: Int
    ) async throws -> ClaudeChatResponse
}

// MARK: - ConversationEngine
// Orchestriert einen Chat-Turn inkl. agentischer Tool-Schleife:
// User-Turn → .streaming-Platzhalter → Claude. Liefert Claude tool_use, werden
// die (read-only, gewhitelisteten) Tools ausgeführt, die Ergebnisse als
// tool_result zurückgespielt und erneut gefragt — bis end_turn oder maxToolRounds.
// Tool-Ergebnisse sind DATEN, nie Instruktionen. Persistiert wird nur der finale
// Antworttext (ein Platzhalter, ein Commit). Tools nur, wenn toolsEnabled (Opt-in).
@MainActor
public final class ConversationEngine {
    private let chatStore: ChatStore
    private let provider: any AssistantConversing
    private let registry: AssistantToolRegistry?
    private static let maxToolRounds = 6

    public private(set) var isResponding = false

    public init(
        chatStore: ChatStore,
        provider: any AssistantConversing,
        registry: AssistantToolRegistry? = nil
    ) {
        self.chatStore = chatStore
        self.provider = provider
        self.registry = registry
    }

    public func send(
        _ text: String,
        scope: ChatScope,
        focusedProjectID: String?,
        signals: [WidgetSignal],
        projects: [Project],
        toolsEnabled: Bool = false,
        now: Date = Date()
    ) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false, isResponding == false else { return }
        isResponding = true
        defer { isResponding = false }

        let user = ChatMessage.text(trimmed, role: .user)
        let placeholder = ChatMessage(role: .assistant, blocks: [.text("")], status: .streaming)
        do {
            try chatStore.append(user, to: scope)
            try chatStore.append(placeholder, to: scope)
        } catch {
            return   // Persistenzfehler ist über chatStore.saveState sichtbar.
        }

        // API-Konversation: persistierter Verlauf (ohne den leeren Platzhalter),
        // plus die transienten tool_use/tool_result-Turns dieser Runde.
        var convo = chatStore.messages(for: scope).filter { $0.id != placeholder.id }
        let system = AssistantGrounding.systemPrompt(
            focusedProjectID: focusedProjectID, signals: signals, projects: projects, now: now
        )
        let tools = (toolsEnabled ? registry?.definitions() : nil) ?? []

        do {
            let finalText = try await runLoop(convo: &convo, system: system, tools: tools)
            try chatStore.updateAssistantTurn(
                id: placeholder.id, blocks: [.text(finalText)], status: .complete, in: scope
            )
        } catch {
            let message = Self.describe(error)
            // try? begründet: scheitert sogar das Finalisieren, ist der Fehler über
            // chatStore.saveState sichtbar; ein erneuter Wurf verpufft im UI-.task.
            try? chatStore.updateAssistantTurn(
                id: placeholder.id, blocks: [.text(message)], status: .failed(message), in: scope
            )
        }
    }

    // Agentische Schleife. Gibt den finalen Antworttext zurück.
    private func runLoop(convo: inout [ChatMessage], system: String, tools: [ClaudeToolDefinition]) async throws -> String {
        var rounds = 0
        while true {
            rounds += 1
            let response = try await provider.respond(messages: convo, system: system, tools: tools, maxTokens: 1024)

            if response.toolUses.isEmpty || rounds >= Self.maxToolRounds {
                let text = response.text.trimmingCharacters(in: .whitespacesAndNewlines)
                return text.isEmpty ? "Ich konnte gerade keine Antwort bilden." : response.text
            }

            // Assistenten-Turn mit tool_use anhängen (API-Kontinuität).
            var assistantBlocks: [ChatContentBlock] = response.text.isEmpty ? [] : [.text(response.text)]
            assistantBlocks += response.toolUses.map { .toolUse(id: $0.id, name: $0.name, inputJSON: $0.inputJSON) }
            convo.append(ChatMessage(role: .assistant, blocks: assistantBlocks, status: .complete))

            // Tools ausführen → tool_result-Turn (role user) anhängen.
            var resultBlocks: [ChatContentBlock] = []
            for toolUse in response.toolUses {
                let result = await (registry?.run(name: toolUse.name, inputJSON: toolUse.inputJSON)
                    ?? ToolRunResult(text: "Keine Tools verfügbar.", isError: true))
                resultBlocks.append(.toolResult(toolUseID: toolUse.id, summary: result.text, isError: result.isError))
            }
            convo.append(ChatMessage(role: .user, blocks: resultBlocks, status: .complete))
        }
    }

    static func describe(_ error: Error) -> String {
        switch error {
        case ClaudeClientError.notConnected:
            "Claude ist nicht verbunden — bitte in den Einstellungen einen API-Key hinterlegen."
        case ClaudeClientError.rateLimited:
            "Zu viele Anfragen — bitte kurz warten und erneut versuchen."
        case ClaudeClientError.overloaded:
            "Der Dienst ist gerade überlastet — bitte gleich erneut versuchen."
        case ClaudeClientError.httpError(let code):
            "Die Anfrage ist fehlgeschlagen (Fehler \(code))."
        default:
            "Es ist ein Fehler aufgetreten. Bitte erneut versuchen."
        }
    }
}
