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

    // S26 — modellbewusste Varianten (Auto-Routing). Protokoll-Anforderungen, damit
    // `any AssistantConversing` dynamisch zur konkreten Impl (ClaudeChatClient) dispatcht.
    // Default-Impls unten ignorieren `model` → Test-Provider/ScriptedProvider unberührt.
    func respond(
        messages: [ChatMessage], system: String, tools: [ClaudeToolDefinition], maxTokens: Int, model: String?
    ) async throws -> ClaudeChatResponse
    func streamText(
        messages: [ChatMessage], system: String, tools: [ClaudeToolDefinition], maxTokens: Int, model: String?
    ) -> AsyncThrowingStream<String, Error>
}

extension AssistantConversing {
    /// Default für modellbewusstes respond(): ignoriert `model` (Provider ohne
    /// Modellwahl, z. B. Test-Doubles), ruft die Basis-Variante.
    public func respond(
        messages: [ChatMessage], system: String, tools: [ClaudeToolDefinition], maxTokens: Int, model: String?
    ) async throws -> ClaudeChatResponse {
        try await respond(messages: messages, system: system, tools: tools, maxTokens: maxTokens)
    }
    /// Default für modellbewusstes streamText(): ignoriert `model`.
    public func streamText(
        messages: [ChatMessage], system: String, tools: [ClaudeToolDefinition], maxTokens: Int, model: String?
    ) -> AsyncThrowingStream<String, Error> {
        streamText(messages: messages, system: system, tools: tools, maxTokens: maxTokens)
    }

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
    // Härtung 2026-07-01 (API-Effizienz Stufe 2): optional — nil lässt das
    // Verhalten exakt wie zuvor (volle Rohhistorie, kein Distillations-Overhead).
    private let memoryStore: ChatMemoryStore?

    /// Ersetzt die Tool-Registry — z. B. nachdem Kunden geladen/synchronisiert wurden,
    /// damit `lookup_kunde` mit frischen Daten arbeitet (L24). Rein additiv, kein State-Bruch.
    public func updateRegistry(_ newRegistry: AssistantToolRegistry) {
        self.registry = newRegistry
    }
    private static let maxToolRounds = 6
    // Härtung (2026-07-01, Loop-Effizienz): verhindert endloses/teures Weitersuchen.
    // toolTimeoutSeconds bricht einen einzelnen hängenden Tool-Call ab (z. B. Google/
    // Airtable/ClickUp ohne Antwort); turnDeadlineSeconds begrenzt die gesamte Runde
    // unabhängig von maxToolRounds (schützt vor vielen schnellen, aber in Summe
    // langen Runden). Instanz-Properties (statt static let) — Tests injizieren winzige
    // Werte, damit das Timeout-Verhalten geprüft werden kann, ohne real 15s zu warten.
    private let toolTimeoutSeconds: Double
    private let turnDeadlineSeconds: Double

    public private(set) var isResponding = false

    // S26 — das in der letzten Runde per Auto-Routing gewählte Modell (für die UI-Quellzeile).
    public private(set) var lastRoutedModel: String?

    // Härtung (2026-07-01, Loop-Effizienz): der laufende Antwort-Task, damit die UI
    // eine hängende/zu lange Anfrage wirklich abbrechen kann (nicht nur optisch).
    private var activeTask: Task<Void, Never>?

    /// Bricht die aktuell laufende Antwort ab (No-op, wenn gerade nichts läuft).
    /// Kooperative Swift-Cancellation propagiert bis in den laufenden Claude-HTTP-
    /// Call hinein (URLSession bricht bei Task-Cancellation selbst ab).
    public func cancel() {
        activeTask?.cancel()
    }

    public init(
        chatStore: ChatStore,
        provider: any AssistantConversing,
        registry: AssistantToolRegistry? = nil,
        dataFlowLogger: DataFlowLogger? = nil,
        memoryStore: ChatMemoryStore? = nil,
        toolTimeoutSeconds: Double = 15,
        turnDeadlineSeconds: Double = 45
    ) {
        self.chatStore = chatStore
        self.provider = provider
        self.registry = registry
        self.dataFlowLogger = dataFlowLogger
        self.memoryStore = memoryStore
        self.toolTimeoutSeconds = toolTimeoutSeconds
        self.turnDeadlineSeconds = turnDeadlineSeconds
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
        // Gedächtnis-Fenster: nur die letzten ~4 Wochen mitschicken (definierter
        // Erinnerungshorizont + Token-/Kostengrenze, statt endlos den ganzen Verlauf).
        let windowed = Self.memoryWindow(
            chatStore.messages(for: scope).filter { $0.id != placeholder.id },
            now: now
        )
        // Stufe 2 (Härtung 2026-07-01): alles jenseits der letzten paar Turns wird,
        // sobald genug angefallen ist, zu einer Zusammenfassung verdichtet statt roh
        // mitgeschickt — landet im System-Prompt (Cache-Breakpoint), nicht im
        // Nachrichten-Array. Ohne memoryStore (nil) exakt das alte Verhalten.
        let (distilledConvo, conversationSummary) = await applyMemoryDistillation(windowed: windowed, scope: scope)
        var convo = distilledConvo
        let effectiveToolsEnabled = toolsEnabled || schaetzModusEnabled
        // S26 — Auto-Routing: günstigstes Modell, das der Aufgabe gewachsen ist.
        let routedModel = AssistantModelRouter.model(
            latestUserText: trimmed, toolsEnabled: effectiveToolsEnabled, schaetzModus: schaetzModusEnabled
        )
        lastRoutedModel = routedModel
        let has: (String) -> Bool = { name in effectiveToolsEnabled && (self.registry?.toolNames.contains(name) == true) }
        let kalkulationsEnabled = has("schaetze_projekt")
        // Werkzeuge nennen wir dem Modell nur, wenn sie a) registriert UND b) im
        // aktuellen Scope sinnvoll sind (Drive/ClickUp brauchen eine Projekt-Handle).
        let driveEnabled      = !schaetzModusEnabled && has("list_drive_folder") && (focusedDriveFolderID?.isEmpty == false)
        let clickUpEnabled    = !schaetzModusEnabled && has("list_clickup_tasks") && (focusedClickUpListID?.isEmpty == false)
        let allClickUpEnabled = !schaetzModusEnabled && has("list_all_clickup_tasks")
        let contactsEnabled   = !schaetzModusEnabled && has("search_contacts")
        let contactsWriteEnabled = !schaetzModusEnabled && has("create_contact")
        let draftEnabled      = !schaetzModusEnabled && has("create_draft")
        let kontaktVerzeichnisEnabled = !schaetzModusEnabled && has("lookup_kontakt")
        let studioBrainEnabled = !schaetzModusEnabled && has("query_studio_knowledge")
        let katalogEnabled    = !schaetzModusEnabled && has("search_katalog")
        let notesEnabled      = !schaetzModusEnabled && has("create_note")
        let tasksEnabled      = !schaetzModusEnabled && has("create_task")
        let offersEnabled     = !schaetzModusEnabled && has("find_offers")
        let fileReadEnabled   = !schaetzModusEnabled && has("read_drive_file")
        let system = AssistantGrounding.systemPrompt(
            profile: profile, focusedProjectID: effectiveProjectID,
            conversationSummary: conversationSummary,
            signals: signals, projects: projects, now: now, toolsEnabled: effectiveToolsEnabled,
            kalkulationsEnabled: kalkulationsEnabled,
            driveEnabled: driveEnabled, contactsEnabled: contactsEnabled,
            clickUpEnabled: clickUpEnabled, allClickUpEnabled: allClickUpEnabled,
            draftEnabled: draftEnabled,
            contactsWriteEnabled: contactsWriteEnabled,
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

        // Als eigener, abbrechbarer Task geführt (statt inline try/await), damit
        // `cancel()` von außen wirklich eingreifen kann — nicht nur den UI-Zustand
        // umschaltet. `Task { }` ohne `.detached` erbt hier die @MainActor-Isolation
        // von `send(...)`, Zugriffe auf `chatStore`/`convo` bleiben unverändert sicher.
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                var activities: [ChatContentBlock] = []
                let placeholderID = placeholder.id
                let onTextDelta: (String) -> Void = { [chatStore] text in
                    chatStore.updateStreamingText(id: placeholderID, text: text, in: scope)
                }
                let finalText = try await self.runLoop(
                    convo: &convo, activities: &activities, system: system, tools: tools, model: routedModel,
                    focusedProjectID: effectiveProjectID, focusedDriveFolderID: focusedDriveFolderID,
                    focusedClickUpListID: focusedClickUpListID, onTextDelta: onTextDelta
                )
                // Tool-Spuren (Transparenz) vor die Antwort; nur Anzeige, nicht an die API.
                try chatStore.updateAssistantTurn(
                    id: placeholder.id, blocks: activities + [.text(finalText)], status: .complete, in: scope
                )
            } catch is CancellationError {
                try? chatStore.updateAssistantTurn(
                    id: placeholder.id, blocks: [.text("Abgebrochen.")], status: .complete, in: scope
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
        activeTask = task
        await task.value
        activeTask = nil
    }

    // MARK: - Gedächtnis-Fenster
    /// Anzahl Tage, die der Assistent als Gesprächsverlauf mitbekommt.
    public static let memoryWindowDays = 28
    /// Begrenzt den mitgeschickten Verlauf: nur Nachrichten der letzten
    /// `memoryWindowDays`, höchstens 120 Stück, und NIE mit einem assistant-/tool-
    /// Turn beginnend (sonst bricht ein verwaister tool_result die API). So bleibt
    /// das Gedächtnis bezahlbar und der Verlauf API-gültig.
    static func memoryWindow(_ messages: [ChatMessage], now: Date) -> [ChatMessage] {
        let cutoff = now.addingTimeInterval(-Double(memoryWindowDays) * 24 * 3600)
        var windowed = messages.filter { $0.createdAt >= cutoff }
        if windowed.count > 120 { windowed = Array(windowed.suffix(120)) }
        return trimToUserStart(windowed)
    }

    // Erste Nachricht muss role == .user sein (sonst bricht ein verwaister
    // assistant-/tool-Turn die API) — von memoryWindow UND der Distillations-
    // Tail-Bildung genutzt.
    static func trimToUserStart(_ messages: [ChatMessage]) -> [ChatMessage] {
        var trimmed = messages
        while let first = trimmed.first, first.role != .user { trimmed.removeFirst() }
        return trimmed
    }

    // MARK: - Gedächtnis-Distillation (Stufe 2, Härtung 2026-07-01)
    // Verdichtet alles jenseits der letzten `distillationTailSize` Turns zu einer
    // überschreibenden Zusammenfassung, sobald seit der letzten Verdichtung
    // mindestens `distillationMinBatch` neue (alte) Turns angefallen sind — batcht
    // die Kosten, statt bei jedem Turn neu zu verdichten. Nicht-fatal: jeder Fehler
    // (Store/Netzwerk) fällt zurück auf die volle Rohhistorie, der Chat-Turn läuft
    // unverändert weiter.
    private static let distillationTailSize = 8
    private static let distillationMinBatch = 12
    // Günstigstes Modell (siehe AssistantModelRouter.haiku) — eine Zusammenfassung
    // braucht kein teures Modell.
    private static let distillationModel = "claude-haiku-4-5-20251001"

    private func applyMemoryDistillation(
        windowed: [ChatMessage], scope: ChatScope
    ) async -> (convo: [ChatMessage], summary: String?) {
        guard let memoryStore, windowed.count > Self.distillationTailSize else {
            return (windowed, nil)
        }
        let tailStart = windowed.count - Self.distillationTailSize
        do {
            let existing = try memoryStore.summary(for: scope)
            let coveredIndex = existing.flatMap { summary in
                windowed.firstIndex { $0.id.uuidString == summary.coveredThroughMessageID }
            } ?? -1
            let newOldSlice = coveredIndex + 1 < tailStart ? Array(windowed[(coveredIndex + 1)..<tailStart]) : []

            if newOldSlice.count >= Self.distillationMinBatch {
                // Genug Neues seit der letzten Verdichtung — jetzt neu verdichten (überschreibt).
                let newSummaryText = try await distill(existingSummaryText: existing?.summaryText, newMessages: newOldSlice)
                try memoryStore.save(ChatMemorySummary(
                    scopeKey: scope.rawKey,
                    summaryText: newSummaryText,
                    coveredThroughMessageID: newOldSlice.last!.id.uuidString,
                    updatedAt: Date()
                ))
                return (Self.trimToUserStart(Array(windowed[tailStart...])), newSummaryText)
            }
            if let existing {
                // Zu wenig Neues für eine erneute Verdichtung — bisherige Zusammenfassung weiterverwenden.
                return (Self.trimToUserStart(Array(windowed[tailStart...])), existing.summaryText)
            }
            // Schwelle insgesamt noch nicht erreicht und noch nie verdichtet — volle Rohhistorie.
            return (windowed, nil)
        } catch {
            return (windowed, nil)
        }
    }

    // Ein günstiger, tool-loser Claude-Call, der eine bestehende Zusammenfassung
    // (kann leer sein) mit neuen Turns zu EINER neuen Fassung verschmilzt — nie
    // anhängt. Widersprüche löst der Prompt zugunsten der neueren Information auf.
    private func distill(existingSummaryText: String?, newMessages: [ChatMessage]) async throws -> String {
        let transcript = newMessages.map { m in
            "\(m.role == .user ? "Nutzer" : "Assistent"): \(m.text)"
        }.joined(separator: "\n")
        let system = """
        Du fasst einen Chatverlauf kompakt für ein Assistenten-Gedächtnis zusammen. Du bekommst eine \
        bisherige Zusammenfassung (kann leer sein) und neue Nachrichten seit der letzten Zusammenfassung. \
        Verschmelze beides zu EINER neuen, aktuellen Fassung — häufe nicht an. Widersprüche löst du \
        zugunsten der neueren Information auf. Halte Entscheidungen, offene Punkte, Nutzer-Präferenzen/ \
        -Korrekturen und projektrelevante Fakten fest. Antworte NUR mit der neuen Zusammenfassung als \
        Fließtext, maximal 400 Wörter, keine Meta-Kommentare, keine Überschriften.
        """
        let existingPart = (existingSummaryText?.isEmpty == false) ? existingSummaryText! : "(noch keine)"
        let userTurn = ChatMessage.text(
            "BISHERIGE ZUSAMMENFASSUNG:\n\(existingPart)\n\nNEUE NACHRICHTEN SEIT DER LETZTEN ZUSAMMENFASSUNG:\n\(transcript)",
            role: .user
        )
        let response = try await provider.respond(
            messages: [userTurn], system: system, tools: [], maxTokens: 600, model: Self.distillationModel
        )
        return response.text.trimmingCharacters(in: .whitespacesAndNewlines)
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
        model: String,
        focusedProjectID: String? = nil,
        focusedDriveFolderID: String? = nil,
        focusedClickUpListID: String? = nil,
        onTextDelta: ((String) -> Void)? = nil
    ) async throws -> String {
        // Tool-loses Streaming: Claude gibt garantiert keinen tool_use zurück →
        // direkt streamen, kein Round-Trip nötig.
        if tools.isEmpty, let onTextDelta {
            return try await streamingFinalAnswer(convo: convo, system: system, model: model, onTextDelta: onTextDelta)
        }

        let deadline = Date().addingTimeInterval(turnDeadlineSeconds)
        var rounds = 0
        // Härtung: identische Tool-Calls (Name+Argumente) innerhalb dieser einen
        // Turn-Ausführung nicht ein zweites Mal stellen — Claude, das dreimal dieselbe
        // leere Airtable-Query wiederholt, wird beim zweiten Versuch gestoppt statt
        // erst nach maxToolRounds.
        var seenToolCalls: Set<String> = []
        while true {
            rounds += 1
            if Date() >= deadline {
                return "Das dauert gerade zu lange — bitte versuche es erneut oder formuliere die Frage einfacher."
            }
            let response = try await provider.respond(messages: convo, system: system, tools: tools, maxTokens: 1024, model: model)

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
            var repeatDetected = false
            for toolUse in response.toolUses {
                let callKey = Self.callKey(name: toolUse.name, inputJSON: toolUse.inputJSON)
                let isRepeat = seenToolCalls.contains(callKey)
                seenToolCalls.insert(callKey)
                let result: ToolRunResult
                if isRepeat {
                    repeatDetected = true
                    result = ToolRunResult(
                        text: "Diese Anfrage wurde in diesem Gespräch bereits identisch gestellt — wird nicht wiederholt.",
                        isError: true
                    )
                } else {
                    result = await runToolWithTimeout(
                        name: toolUse.name, inputJSON: toolUse.inputJSON,
                        projektID: focusedProjectID, driveFolderID: focusedDriveFolderID, clickUpListID: focusedClickUpListID
                    )
                }
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
                if let mailDraft = result.emailDraft {
                    // Mail-Entwurf-Bestätigungskarte — legt erst auf Bestätigung in Gmail ab.
                    activities.append(.draftAction(draft: mailDraft))
                }
                if result.driveFiles.isEmpty == false {
                    // Anklickbare Datei-Ergebnisse (In-App-Vorschau) — nur Anzeige.
                    activities.append(.driveFiles(label: "Gefundene Dokumente", files: result.driveFiles))
                }
                if let airtableDraft = result.airtableContactDraft {
                    // Airtable-Kontakt-Bestätigungskarte (S19) — schreibt erst auf Bestätigung.
                    activities.append(.airtableContactAction(draft: airtableDraft))
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
            // Sofort ehrlich aufhören statt eine weitere (kostenpflichtige) Runde zu
            // riskieren, wenn Claude gerade nachweislich nichts Neues gefunden hat.
            if repeatDetected {
                return "Ich konnte dazu keine neuen Daten finden — magst du die Frage anders stellen oder mir mehr Kontext geben?"
            }
        }
    }

    // Führt einen einzelnen Tool-Call mit hartem Zeitlimit aus (Härtung 2026-07-01):
    // ein hängender Google/Airtable/ClickUp-Call darf nicht die ganze Runde blockieren.
    // `registry` wird als lokaler Sendable-Wert gebunden, damit der Timeout-Task ihn
    // ohne @MainActor-Capture von `self` ausführen kann.
    private func runToolWithTimeout(
        name: String, inputJSON: Data, projektID: String?, driveFolderID: String?, clickUpListID: String?
    ) async -> ToolRunResult {
        guard let registry else { return ToolRunResult(text: "Keine Tools verfügbar.", isError: true) }
        let timeout = toolTimeoutSeconds   // lokal gebunden, kein self-Capture im Kind-Task nötig
        return await withTaskGroup(of: ToolRunResult.self) { group in
            group.addTask {
                await registry.run(
                    name: name, inputJSON: inputJSON, projektID: projektID,
                    driveFolderID: driveFolderID, clickUpListID: clickUpListID
                )
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return ToolRunResult(text: "Zeitüberschreitung — das Tool hat nicht rechtzeitig geantwortet.", isError: true)
            }
            let first = await group.next() ?? ToolRunResult(text: "Keine Antwort erhalten.", isError: true)
            group.cancelAll()
            return first
        }
    }

    static func callKey(name: String, inputJSON: Data) -> String {
        "\(name)|\(String(data: inputJSON, encoding: .utf8) ?? "")"
    }

    // Streamt die finale Textantwort via SSE. Akkumuliert Deltas und ruft
    // onTextDelta mit dem jeweils gewachsenen Gesamttext auf (→ UI tippt mit).
    private func streamingFinalAnswer(
        convo: [ChatMessage], system: String, model: String, onTextDelta: (String) -> Void
    ) async throws -> String {
        let stream = provider.streamText(messages: convo, system: system, tools: [], maxTokens: 1024, model: model)
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
        case "read_email":                base = "Mail gelesen"
        case "create_draft":              base = "Mail-Entwurf vorbereitet"
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
