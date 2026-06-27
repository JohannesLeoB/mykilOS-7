import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - AssistantChatView (Phase 1 — konversationeller Assistent)
// Messenger-Chat über die Claude-API. Verlauf aus dem ChatStore (persistent),
// Senden über die ConversationEngine. Alle Zustände: nicht verbunden →
// „Claude verbinden", leer, Antwort läuft, Fehler. Quelle bleibt sichtbar.
public struct AssistantChatView: View {
    let scope: ChatScope
    let chatStore: ChatStore
    let engine: ConversationEngine
    let isConnected: Bool
    let modelName: String
    let projects: [Project]
    let focusedProjectID: String?
    let profile: UserProfile?

    @Environment(StudioContext.self) private var context
    @State private var draft = ""
    @State private var showClearConfirm = false
    // Datenschutz-Opt-in: Tools (Gmail/Kalender lesen) gehen erst nach bewusster
    // Aktivierung an die Anthropic-API. Default AUS, persistent.
    @AppStorage("assistant.toolsEnabled") private var toolsEnabled = false

    public init(
        scope: ChatScope,
        chatStore: ChatStore,
        engine: ConversationEngine,
        isConnected: Bool,
        modelName: String,
        projects: [Project],
        focusedProjectID: String?,
        profile: UserProfile? = nil
    ) {
        self.scope = scope
        self.chatStore = chatStore
        self.engine = engine
        self.isConnected = isConnected
        self.modelName = modelName
        self.projects = projects
        self.focusedProjectID = focusedProjectID
        self.profile = profile
    }

    private var messages: [ChatMessage] { chatStore.messages(for: scope) }

    public var body: some View {
        VStack(spacing: 0) {
            if isConnected {
                conversation
                optInBar
                composer
            } else {
                notConnected
            }
            sourceLine
        }
        .task(id: scope.rawKey) { try? chatStore.loadIfNeeded(scope) }
        .alert("Verlauf löschen?", isPresented: $showClearConfirm) {
            Button("Löschen", role: .destructive) { try? chatStore.clear(scope) }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Der gesamte Chat-Verlauf dieses Threads wird unwiderruflich gelöscht.")
        }
    }

    // MARK: Verlauf
    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: MykSpace.s5) {
                    if messages.isEmpty { emptyState }
                    ForEach(messages) { ChatMessageBubble(message: $0).id($0.id) }
                }
                .padding(.horizontal, MykSpace.s9)
                .padding(.vertical, MykSpace.s7)
            }
            .overlay(alignment: .topTrailing) {
                if messages.isEmpty == false {
                    Button { showClearConfirm = true } label: {
                        Image(systemName: "trash")
                            .font(.mykCaption)
                            .foregroundStyle(MykColor.faint.color)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, MykSpace.s5)
                    .padding(.trailing, MykSpace.s9)
                    .help("Verlauf löschen")
                }
            }
            .onChange(of: messages.last?.id) { _, last in
                guard let last else { return }
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(last, anchor: .bottom) }
            }
            .onChange(of: messages.last?.text) { _, _ in
                guard let last = messages.last?.id else { return }
                proxy.scrollTo(last, anchor: .bottom)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            Text("Frag den Assistenten").mykWidgetTitle()
            Text("Er kennt deine Projekte und offenen Signale. Beispiele:")
                .font(.mykSmall).foregroundStyle(MykColor.muted.color)
            ForEach(exampleQuestions, id: \.self) { q in
                Button { send(q) } label: {
                    Text("„\(q)")
                        .font(.mykSmall).foregroundStyle(MykColor.ink.color)
                        .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s3)
                        .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.card.color))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, MykSpace.s7)
    }

    private var exampleQuestions: [String] {
        ["Was steht diese Woche an?“", "Fasse die offenen Signale zusammen.“", "Worauf soll ich heute achten?“"]
    }

    // MARK: Datenschutz-Opt-in für Live-Tools
    private var optInBar: some View {
        HStack(spacing: MykSpace.s4) {
            Image(systemName: toolsEnabled ? "bolt.fill" : "bolt.slash")
                .font(.mykCaption)
                .foregroundStyle(toolsEnabled ? MykColor.positive.color : MykColor.faint.color)
            VStack(alignment: .leading, spacing: 1) {
                Text(toolsEnabled ? "Live-Zugriffe aktiv" : "Live-Zugriffe aus")
                    .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                Text(toolsEnabled
                     ? "Mail/Kalender werden bei Bedarf gelesen und an Anthropic gesendet."
                     : "Aktivieren, damit der Assistent deine Mail/Kalender lesen darf.")
                    .font(.mykMono(9)).foregroundStyle(MykColor.faint.color).lineLimit(1)
            }
            Spacer()
            Toggle("", isOn: $toolsEnabled).labelsHidden().toggleStyle(.switch).scaleEffect(0.8)
        }
        .padding(.horizontal, MykSpace.s9).padding(.vertical, MykSpace.s3)
        .overlay(alignment: .top) { Divider().overlay(MykColor.line.color) }
    }

    // MARK: Eingabe
    private var composer: some View {
        HStack(alignment: .bottom, spacing: MykSpace.s4) {
            TextField("Nachricht an den Assistenten …", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.mykBody)
                .lineLimit(1...5)
                .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s4)
                .background(
                    RoundedRectangle(cornerRadius: MykRadius.md)
                        .fill(MykColor.card.color)
                        .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1))
                )
                .onSubmit { send(draft) }
            Button { send(draft) } label: {
                Image(systemName: engine.isResponding ? "ellipsis" : "arrow.up.circle.fill")
                    .font(.mykHeadline)
                    .foregroundStyle(canSend ? MykColor.ink.color : MykColor.faint.color)
            }
            .buttonStyle(.plain)
            .disabled(canSend == false)
        }
        .padding(.horizontal, MykSpace.s9).padding(.vertical, MykSpace.s5)
        .overlay(alignment: .top) { Divider().overlay(MykColor.line.color) }
    }

    private var canSend: Bool {
        engine.isResponding == false && draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private func send(_ text: String) {
        let toSend = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard toSend.isEmpty == false, engine.isResponding == false else { return }
        draft = ""
        let signals = focusedProjectID.map { context.signals(for: $0) } ?? []
        Task {
            await engine.send(
                toSend, scope: scope, focusedProjectID: focusedProjectID,
                signals: signals, projects: projects, toolsEnabled: toolsEnabled,
                profile: profile
            )
        }
    }

    // MARK: Nicht verbunden
    private var notConnected: some View {
        VStack(spacing: MykSpace.s4) {
            Spacer()
            Image(systemName: "lock").font(.mykHeadline).foregroundStyle(MykColor.faint.color)
            Text("Claude nicht verbunden").font(.mykBody).foregroundStyle(MykColor.muted.color)
            Text("In den Einstellungen einen Anthropic API-Key hinterlegen.")
                .font(.mykMono(10)).foregroundStyle(MykColor.faint.color)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Quellenzeile
    private var sourceLine: some View {
        HStack(spacing: 8) {
            Circle().fill(isConnected ? MykColor.positive.color : MykColor.faint.color).frame(width: 5, height: 5)
            Text(isConnected ? "CLAUDE  ·  \(modelName.uppercased())" : "CLAUDE  ·  NICHT VERBUNDEN")
                .font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
            Spacer()
        }
        .padding(.horizontal, MykSpace.s9).padding(.vertical, MykSpace.s4)
        .overlay(alignment: .top) { Divider().overlay(MykColor.line.color) }
    }
}

// MARK: - ChatMessageBubble
struct ChatMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: MykSpace.s2) {
                // Tool-Spuren (Quelle sichtbar) über der Antwort.
                ForEach(Array(toolActivities.enumerated()), id: \.offset) { _, activity in
                    ToolCallRow(label: activity.label, isError: activity.isError)
                }
                bubble
                if case .failed = message.status {
                    Label("Erneut versuchen über erneutes Senden", systemImage: "exclamationmark.triangle")
                        .font(.mykMono(9.5)).foregroundStyle(MykColor.critical.color)
                }
            }
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private var toolActivities: [(label: String, isError: Bool)] {
        message.blocks.compactMap {
            if case let .toolActivity(label, isError) = $0 { (label, isError) } else { nil }
        }
    }

    @ViewBuilder
    private var bubble: some View {
        if message.role == .assistant, message.status == .streaming, message.text.isEmpty {
            HStack(spacing: 6) {
                ProgressView().scaleEffect(0.6).tint(MykColor.muted.color)
                Text("denkt nach …").font(.mykSmall).foregroundStyle(MykColor.muted.color)
            }
            .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s4)
            .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color))
        } else {
            Text(Self.rendered(message.text))
                .font(.mykBody)
                .foregroundStyle(message.role == .user ? MykColor.paper.color : MykColor.ink.color)
                .textSelection(.enabled)
                .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s4)
                .background(
                    RoundedRectangle(cornerRadius: MykRadius.md)
                        .fill(message.role == .user ? MykColor.ink.color : MykColor.card.color)
                )
        }
    }

    // Markdown des Assistenten interpretieren (fett/kursiv/Code/Links), Zeilen-
    // umbrüche erhalten. Block-Elemente (Tabellen/Überschriften) bleiben als Text
    // lesbar — kein Roh-`**`/`|` mehr.
    static func rendered(_ raw: String) -> AttributedString {
        (try? AttributedString(
            markdown: raw,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(raw)
    }
}

// MARK: - ToolCallRow
// Sichtbare Spur eines gelaufenen read-only Tools („Quelle ist immer sichtbar").
struct ToolCallRow: View {
    let label: String
    let isError: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isError ? "exclamationmark.magnifyingglass" : "magnifyingglass")
                .font(.mykMono(9.5))
            Text(label)
                .font(.mykMono(9.5))
                .lineLimit(1)
        }
        .foregroundStyle(isError ? MykColor.critical.color : MykColor.muted.color)
        .padding(.horizontal, MykSpace.s4)
        .padding(.vertical, 3)
        .background(Capsule().fill(MykColor.card.color))
    }
}
