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

    // Protokoll-Anforderung (kein Extension-only) damit Dynamic Dispatch über
    // `any AssistantConversing` die konkrete Implementierung aufruft.
    func streamText(
        messages: [ChatMessage], system: String, tools: [ClaudeToolDefinition], maxTokens: Int
    ) -> AsyncThrowingStream<String, Error>
}

extension AssistantConversing {
    /// Default: respond() als Einzel-Delta-Stream (ScriptedProvider/Fallback ohne Netz).
    /// ClaudeChatClient überschreibt das mit echtem SSE.
    public func streamText(
        messages: [ChatMessage], system: String, tools: [ClaudeToolDefinition], maxTokens: Int
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let r = try await respond(messages: messages, system: system, tools: tools, maxTokens: maxTokens)
                    if r.text.isEmpty == false { continuation.yield(r.text) }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
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
    private var registry: AssistantToolRegistry?
    private let dataFlowLogger: DataFlowLogger?

    /// Ersetzt die Tool-Registry — z. B. nachdem Kunden geladen/synchronisiert wurden,
    /// damit `lookup_kunde` mit frischen Daten arbeitet (L24). Rein additiv, kein State-Bruch.
    public func updateRegistry(_ newRegistry: AssistantToolRegistry) {
        self.registry = newRegistry
    }
    private static let maxToolRounds = 6

    public private(set) var isResponding = false

    public init(
        chatStore: ChatStore,
        provider: any AssistantConversing,
        registry: AssistantToolRegistry? = nil,
        dataFlowLogger: DataFlowLogger? = nil
    ) {
        self.chatStore = chatStore
        self.provider = provider
        self.registry = registry
        self.dataFlowLogger = dataFlowLogger
    }

    public func send(
        _ text: String,
        scope: ChatScope,
        focusedProjectID: String?,
        focusedDriveFolderID: String? = nil,
        focusedClickUpListID: String? = nil,
        signals: [WidgetSignal],
        projects: [Project],
        toolsEnabled: Bool = false,
        schaetzModusEnabled: Bool = false,
        now: Date = Date(),
        profile: UserProfile? = nil
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

        // Schätzchat: nur schaetze_projekt, projektlose Eingabe erlaubt.
        let effectiveProjectID = focusedProjectID ?? (schaetzModusEnabled ? "schaetzung" : nil)

        // API-Konversation: persistierter Verlauf (ohne den leeren Platzhalter),
        // plus die transienten tool_use/tool_result-Turns dieser Runde.
        var convo = chatStore.messages(for: scope).filter { $0.id != placeholder.id }
        let effectiveToolsEnabled = toolsEnabled || schaetzModusEnabled
        let has: (String) -> Bool = { name in effectiveToolsEnabled && (self.registry?.toolNames.contains(name) == true) }
        let kalkulationsEnabled = has("schaetze_projekt")
        // Werkzeuge nennen wir dem Modell nur, wenn sie a) registriert UND b) im
        // aktuellen Scope sinnvoll sind (Drive/ClickUp brauchen eine Projekt-Handle).
        let driveEnabled      = !schaetzModusEnabled && has("list_drive_folder") && (focusedDriveFolderID?.isEmpty == false)
        let clickUpEnabled    = !schaetzModusEnabled && has("list_clickup_tasks") && (focusedClickUpListID?.isEmpty == false)
        let contactsEnabled   = !schaetzModusEnabled && has("search_contacts")
        let contactsWriteEnabled = !schaetzModusEnabled && has("create_contact")
        let kontaktVerzeichnisEnabled = !schaetzModusEnabled && has("lookup_kontakt")
        let studioBrainEnabled = !schaetzModusEnabled && has("query_studio_knowledge")
        let katalogEnabled    = !schaetzModusEnabled && has("search_katalog")
        let notesEnabled      = !schaetzModusEnabled && has("create_note")
        let tasksEnabled      = !schaetzModusEnabled && has("create_task")
        let offersEnabled     = !schaetzModusEnabled && has("find_offers")
        let fileReadEnabled   = !schaetzModusEnabled && has("read_drive_file")
        let system = AssistantGrounding.systemPrompt(
            profile: profile, focusedProjectID: effectiveProjectID,
            signals: signals, projects: projects, now: now, toolsEnabled: effectiveToolsEnabled,
            kalkulationsEnabled: kalkulationsEnabled,
            driveEnabled: driveEnabled, contactsEnabled: contactsEnabled,
            clickUpEnabled: clickUpEnabled, contactsWriteEnabled: contactsWriteEnabled,
            kontaktVerzeichnisEnabled: kontaktVerzeichnisEnabled,
            studioBrainEnabled: studioBrainEnabled,
            katalogEnabled: katalogEnabled, notesEnabled: notesEnabled,
            tasksEnabled: tasksEnabled,
            offersEnabled: offersEnabled, fileReadEnabled: fileReadEnabled
        )
        // Schätzchat bekommt NUR schaetze_projekt — kein Mail/Kalender/Drive-Leak.
        let tools: [ClaudeToolDefinition]
        if schaetzModusEnabled {
            tools = registry?.schaetzDefinitions() ?? []
        } else {
            tools = (toolsEnabled ? registry?.definitions() : nil) ?? []
        }

        do {
            var activities: [ChatContentBlock] = []
            let placeholderID = placeholder.id
            let onTextDelta: (String) -> Void = { [chatStore] text in
                chatStore.updateStreamingText(id: placeholderID, text: text, in: scope)
            }
            let finalText = try await runLoop(convo: &convo, activities: &activities, system: system, tools: tools, focusedProjectID: effectiveProjectID, focusedDriveFolderID: focusedDriveFolderID, focusedClickUpListID: focusedClickUpListID, onTextDelta: onTextDelta)
            // Tool-Spuren (Transparenz) vor die Antwort; nur Anzeige, nicht an die API.
            try chatStore.updateAssistantTurn(
                id: placeholder.id, blocks: activities + [.text(finalText)], status: .complete, in: scope
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

    // Agentische Schleife. Sammelt nebenbei sichtbare Tool-Spuren (activities)
    // und gibt den finalen Antworttext zurück. Bei leerer Tools-Liste (kein Opt-in
    // oder keine Tools) wird direkt gestreamt — onTextDelta liefert Akkumulierungs-
    // zwischenstände für inkrementelle UI-Updates.
    private func runLoop(
        convo: inout [ChatMessage],
        activities: inout [ChatContentBlock],
        system: String,
        tools: [ClaudeToolDefinition],
        focusedProjectID: String? = nil,
        focusedDriveFolderID: String? = nil,
        focusedClickUpListID: String? = nil,
        onTextDelta: ((String) -> Void)? = nil
    ) async throws -> String {
        // Tool-loses Streaming: Claude gibt garantiert keinen tool_use zurück →
        // direkt streamen, kein Round-Trip nötig.
        if tools.isEmpty, let onTextDelta {
            return try await streamingFinalAnswer(convo: convo, system: system, onTextDelta: onTextDelta)
        }

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

            // Tools ausführen → tool_result-Turn (role user) anhängen + Anzeige-Spur.
            var resultBlocks: [ChatContentBlock] = []
            for toolUse in response.toolUses {
                let result = await (registry?.run(name: toolUse.name, inputJSON: toolUse.inputJSON, projektID: focusedProjectID, driveFolderID: focusedDriveFolderID, clickUpListID: focusedClickUpListID)
                    ?? ToolRunResult(text: "Keine Tools verfügbar.", isError: true))
                // Mandate E / Forensik F12: die kanonische Manifest-ID loggen, nicht
                // den rohen Tool-Namen — sonst findet das SchaltzentrumView nie einen
                // Handshake (es matcht auf integrationID aus dem Manifest).
                dataFlowLogger?.log(
                    integrationID: AssistantToolManifest.manifestID(forTool: toolUse.name),
                    actorUserID: "assistant",
                    action: result.isError ? .error : .success,
                    errorMessage: result.isError ? result.text : nil,
                    summary: "Tool-Call: \(toolUse.name)"
                )
                resultBlocks.append(.toolResult(toolUseID: toolUse.id, summary: result.text, isError: result.isError))
                activities.append(.toolActivity(
                    label: Self.activityLabel(name: toolUse.name, inputJSON: toolUse.inputJSON),
                    isError: result.isError
                ))
                if let url = result.actionURL {
                    // Aktionskarte als sichtbarer Block — nie an die API gesendet.
                    activities.append(.calendarAction(url: url, label: "Im Kalender öffnen"))
                }
                if let draft = result.contactDraft {
                    // Kontakt-Bestätigungskarte — schreibt erst auf ausdrückliche Bestätigung.
                    activities.append(.contactAction(draft: draft))
                }
                if let s = result.schaetzung {
                    // Schätzungskarte — nur Anzeige, nie an die API gesendet.
                    activities.append(.kalkulationsSchaetzung(
                        schaetzungsID: s.schaetzungsID,
                        projektID: s.projektID,
                        minNetto: s.minNetto,
                        maxNetto: s.maxNetto,
                        mitteNetto: s.mitteNetto,
                        confidence: s.confidence,
                        evidenceCount: s.evidenceCount
                    ))
                }
            }
            convo.append(ChatMessage(role: .user, blocks: resultBlocks, status: .complete))
        }
    }

    // Streamt die finale Textantwort via SSE. Akkumuliert Deltas und ruft
    // onTextDelta mit dem jeweils gewachsenen Gesamttext auf (→ UI tippt mit).
    private func streamingFinalAnswer(
        convo: [ChatMessage], system: String, onTextDelta: (String) -> Void
    ) async throws -> String {
        let stream = provider.streamText(messages: convo, system: system, tools: [], maxTokens: 1024)
        var accumulated = ""
        for try await delta in stream {
            accumulated += delta
            onTextDelta(accumulated)
        }
        let trimmed = accumulated.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Ich konnte gerade keine Antwort bilden." : accumulated
    }

    // Menschliche Spur eines Tool-Aufrufs (Quelle sichtbar). Zeigt die Quelle +
    // ggf. die Suchabfrage — keine sensiblen Ergebnisinhalte.
    static func activityLabel(name: String, inputJSON: Data) -> String {
        let input = Self.stringDict(from: inputJSON)
        let query = input["query"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let base: String
        switch name {
        case "search_gmail":              base = "Gmail durchsucht"
        case "list_calendar_events":      base = "Kalender gelesen"
        case "suggest_calendar_event":    base = "Kalender-Link generiert"
        case "schaetze_projekt":          base = "Kostenschätzung erstellt"
        case "list_drive_folder":         base = "Drive-Ordner gelesen"
        case "search_contacts":           base = "Kontakte durchsucht"
        case "create_contact":            base = "Kontakt-Entwurf erstellt"
        case "list_clickup_tasks":        base = "ClickUp gelesen"
        case "query_studio_knowledge":    base = "Wissensbasis durchsucht"
        case "search_katalog":            base = "Katalog durchsucht"
        default:                          base = name
        }
        if let query, query.isEmpty == false { return "\(base) · \(query)" }
        return base
    }

    // Claude kann integer-Parameter (z. B. within_days) als JSON-Number senden.
    // JSONDecoder().decode([String:String].self …) wirft dann typeMismatch.
    // JSONSerialization + compactMapValues fängt beides ab.
    static func stringDict(from data: Data) -> [String: String] {
        guard let raw = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return [:] }
        return raw.compactMapValues { v in
            if let s = v as? String { return s }
            if let n = v as? NSNumber { return n.stringValue }
            return nil
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
        case ClaudeClientError.streamInterrupted:
            "Die Verbindung wurde unterbrochen — bitte erneut versuchen."
        default:
            "Es ist ein Fehler aufgetreten. Bitte erneut versuchen."
        }
    }
}
