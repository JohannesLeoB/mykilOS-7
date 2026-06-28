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
    let focusedDriveFolderID: String?
    let focusedClickUpListID: String?
    let profile: UserProfile?

    @Environment(StudioContext.self) private var context
    @State private var draft = ""
    @State private var showClearConfirm = false
    // Datenschutz-Opt-in: Tools (Gmail/Kalender lesen) gehen erst nach bewusster
    // Aktivierung an die Anthropic-API. Default AUS, persistent.
    @AppStorage("assistant.toolsEnabled") private var toolsEnabled = false
    // Schätzchat-Modus: nur schaetze_projekt aktiv, projektlose Eingabe erlaubt.
    @AppStorage("assistant.schaetzModus") private var schaetzModus = false

    public init(
        scope: ChatScope,
        chatStore: ChatStore,
        engine: ConversationEngine,
        isConnected: Bool,
        modelName: String,
        projects: [Project],
        focusedProjectID: String?,
        focusedDriveFolderID: String? = nil,
        focusedClickUpListID: String? = nil,
        profile: UserProfile? = nil
    ) {
        self.scope = scope
        self.chatStore = chatStore
        self.engine = engine
        self.isConnected = isConnected
        self.modelName = modelName
        self.projects = projects
        self.focusedProjectID = focusedProjectID
        self.focusedDriveFolderID = focusedDriveFolderID
        self.focusedClickUpListID = focusedClickUpListID
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
        // \u201D = schlie\u00DFendes deutsches Anf\u00FChrungszeichen
        if case .project(let nr) = scope,
           let project = projects.first(where: { $0.projectNumber == nr }) {
            // Projekt-spezifische Einstiegsfragen.
            if toolsEnabled {
                return [
                    "Was steht f\u{00FC}r \(project.title) diese Woche an?\u{201D}",
                    "Suche Mails zu \(project.title).\u{201D}",
                    "Lege einen Termin f\u{00FC}r das n\u{00E4}chste \(project.title)-Meeting an.\u{201D}",
                ]
            } else {
                return [
                    "Was sind die n\u{00E4}chsten Schritte f\u{00FC}r \(project.title)?\u{201D}",
                    "Welche offenen Signale gibt es f\u{00FC}r \(project.title)?\u{201D}",
                    "Worauf soll ich bei \(project.title) heute achten?\u{201D}",
                ]
            }
        }
        // Home-Scope: allgemeine Fragen.
        if toolsEnabled {
            return [
                "Was steht diese Woche im Kalender an?\u{201D}",
                "Erstelle einen Termin f\u{00FC}r das Teammeeting Montag.\u{201D}",
                "Suche Mails zum Thema Angebot.\u{201D}",
            ]
        } else {
            return [
                "Was steht diese Woche an?\u{201D}",
                "Fasse die offenen Signale zusammen.\u{201D}",
                "Worauf soll ich heute achten?\u{201D}",
            ]
        }
    }

    // MARK: Datenschutz-Opt-in für Live-Tools + Schätzchat-Toggle
    private var optInBar: some View {
        VStack(spacing: 0) {
            // Schätzchat-Modus
            HStack(spacing: MykSpace.s4) {
                Image(systemName: schaetzModus ? "function" : "function")
                    .font(.mykCaption)
                    .foregroundStyle(schaetzModus ? MykColor.tasks.color : MykColor.faint.color)
                VStack(alignment: .leading, spacing: 1) {
                    Text(schaetzModus ? "Schätzchat aktiv" : "Chat")
                        .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                    Text(schaetzModus
                         ? "Nur Kostenschätzung aktiv. Eingabe: z. B. '5m Eichenküche'. Kein Mail/Kalender/Drive."
                         : "Schätzchat aktivieren für projektlose Kostenschätzungen per KI.")
                        .font(.mykMono(9)).foregroundStyle(MykColor.faint.color).lineLimit(2)
                }
                Spacer()
                Toggle("", isOn: $schaetzModus).labelsHidden().toggleStyle(.switch).scaleEffect(0.8)
                    .tint(MykColor.tasks.color)
            }
            .padding(.horizontal, MykSpace.s9).padding(.vertical, MykSpace.s3)
            .overlay(alignment: .top) { Divider().overlay(MykColor.line.color) }

            // Live-Zugriffe (nur wenn nicht im Schätzchat-Modus)
            if !schaetzModus {
                HStack(spacing: MykSpace.s4) {
                    Image(systemName: toolsEnabled ? "bolt.fill" : "bolt.slash")
                        .font(.mykCaption)
                        .foregroundStyle(toolsEnabled ? MykColor.positive.color : MykColor.faint.color)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(toolsEnabled ? "Live-Zugriffe aktiv" : "Live-Zugriffe aus")
                            .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                        Text(toolsEnabled
                             ? "Mail, Kalender, Drive, Aufgaben, Kontakte & Studio-Wissen werden bei Bedarf gelesen und an Anthropic gesendet."
                             : "Aktivieren, damit der Assistent Mail, Kalender, Drive, Aufgaben & Kontakte lesen darf.")
                            .font(.mykMono(9)).foregroundStyle(MykColor.faint.color).lineLimit(2)
                    }
                    Spacer()
                    Toggle("", isOn: $toolsEnabled).labelsHidden().toggleStyle(.switch).scaleEffect(0.8)
                }
                .padding(.horizontal, MykSpace.s9).padding(.vertical, MykSpace.s3)
                .overlay(alignment: .top) { Divider().overlay(MykColor.line.color) }
            }
        }
    }

    // MARK: Eingabe
    private var composer: some View {
        let placeholder = schaetzModus
            ? "Schätze mir: z. B. '5m Eichenküche' ..."
            : "Nachricht an den Assistenten ..."
        return HStack(alignment: .bottom, spacing: MykSpace.s4) {
            TextField(placeholder, text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.mykBody)
                .lineLimit(1...5)
                .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s4)
                .background(
                    RoundedRectangle(cornerRadius: MykRadius.md)
                        .fill(schaetzModus ? MykColor.tasks.color.opacity(0.07) : MykColor.card.color)
                        .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(
                            schaetzModus ? MykColor.tasks.color.opacity(0.4) : MykColor.line.color,
                            lineWidth: 1))
                )
                .onSubmit { send(draft) }
            Button { send(draft) } label: {
                Image(systemName: engine.isResponding ? "ellipsis" : "arrow.up.circle.fill")
                    .font(.mykHeadline)
                    .foregroundStyle(canSend ? (schaetzModus ? MykColor.tasks.color : MykColor.ink.color) : MykColor.faint.color)
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
                focusedDriveFolderID: focusedDriveFolderID,
                focusedClickUpListID: focusedClickUpListID,
                signals: signals, projects: projects, toolsEnabled: toolsEnabled,
                schaetzModusEnabled: schaetzModus,
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
                // Tool-Spuren (Quelle sichtbar, L12: mit Zeitstempel) über der Antwort.
                ForEach(Array(toolActivities.enumerated()), id: \.offset) { _, activity in
                    ToolCallRow(label: activity.label, isError: activity.isError, timestamp: message.createdAt)
                }
                bubble
                // Kalender-Aktionskarten nach der Antwort.
                ForEach(Array(calendarActions.enumerated()), id: \.offset) { _, action in
                    CalendarActionCard(url: action.url, label: action.label)
                }
                // Kostenschätzungskarten nach der Antwort.
                ForEach(Array(kalkulationsSchaetzungen.enumerated()), id: \.offset) { _, s in
                    KalkulationsSchaetzungCard(
                        minNetto: s.minNetto, maxNetto: s.maxNetto, mitteNetto: s.mitteNetto,
                        confidence: s.confidence, evidenceCount: s.evidenceCount
                    )
                }
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

    private var calendarActions: [(url: String, label: String)] {
        message.blocks.compactMap {
            if case let .calendarAction(url, label) = $0 { (url, label) } else { nil }
        }
    }

    private struct SchaetzungData {
        let minNetto: Double; let maxNetto: Double; let mitteNetto: Double
        let confidence: Double; let evidenceCount: Int
    }
    private var kalkulationsSchaetzungen: [SchaetzungData] {
        message.blocks.compactMap {
            if case let .kalkulationsSchaetzung(_, _, min, max, mitte, conf, cnt) = $0 {
                SchaetzungData(minNetto: min, maxNetto: max, mitteNetto: mitte, confidence: conf, evidenceCount: cnt)
            } else { nil }
        }
    }

    @ViewBuilder
    private var bubble: some View {
        let isStreaming = message.role == .assistant && message.status == .streaming
        if isStreaming, message.text.isEmpty {
            HStack(spacing: 6) {
                ProgressView().scaleEffect(0.6).tint(MykColor.muted.color)
                Text("denkt nach …").font(.mykSmall).foregroundStyle(MykColor.muted.color)
            }
            .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s4)
            .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color))
        } else {
            let displayText = isStreaming ? message.text + "▌" : message.text
            Text(Self.rendered(displayText))
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

// MARK: - CalendarActionCard
// Aktionskarte für einen generierten Google-Kalender-Link (Phase 3).
// Öffnet den Link im Browser — schreibt NIE selbst in den Kalender.
struct CalendarActionCard: View {
    let url: String
    let label: String

    var body: some View {
        Button {
            if let u = URL(string: url) { NSWorkspace.shared.open(u) }
        } label: {
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "calendar.badge.plus")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.people.color)
                Text(label)
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.ink.color)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.faint.color)
            }
            .padding(.horizontal, MykSpace.s5)
            .padding(.vertical, MykSpace.s4)
            .background(
                RoundedRectangle(cornerRadius: MykRadius.md)
                    .fill(MykColor.card.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: MykRadius.md)
                            .stroke(MykColor.people.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 360)
    }
}

// MARK: - ToolCallRow
// Sichtbare Spur eines gelaufenen read-only Tools (L12: welches Tool, wann).
struct ToolCallRow: View {
    let label: String
    let isError: Bool
    var timestamp: Date? = nil

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isError ? "exclamationmark.magnifyingglass" : "magnifyingglass")
                .font(.mykMono(9.5))
            Text(label)
                .font(.mykMono(9.5))
                .lineLimit(1)
            if let ts = timestamp {
                Text(relativeTime(ts))
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.faint.color)
            }
        }
        .foregroundStyle(isError ? MykColor.critical.color : MykColor.muted.color)
        .padding(.horizontal, MykSpace.s4)
        .padding(.vertical, 3)
        .background(Capsule().fill(MykColor.card.color))
    }

    private func relativeTime(_ date: Date) -> String {
        let diff = -date.timeIntervalSinceNow
        if diff < 60   { return "gerade eben" }
        if diff < 3600 { return "vor \(Int(diff / 60)) min" }
        let h = Int(diff / 3600)
        return "vor \(h) \(h == 1 ? "Std" : "Std")"
    }
}

// MARK: - KalkulationsSchaetzungCard
// Kostenschätzungskarte (S18). Zeigt Min/Mitte/Max-Netto + Konfidenz.
// Öffnet keine URL — reine Anzeige der lokalen Engine-Ausgabe.
struct KalkulationsSchaetzungCard: View {
    let minNetto: Double
    let maxNetto: Double
    let mitteNetto: Double
    let confidence: Double
    let evidenceCount: Int

    private static let fmt: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "de_DE")
        f.maximumFractionDigits = 0
        return f
    }()

    private func euro(_ v: Double) -> String {
        (Self.fmt.string(from: NSNumber(value: v)) ?? "\(Int(v))") + " €"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "function")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.tasks.color)
                Text("KOSTENSCHÄTZUNG")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.tasks.color)
                Spacer()
                Text("\(Int(confidence * 100)) % Konfidenz")
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.muted.color)
            }
            HStack(spacing: 0) {
                priceColumn("MIN",   value: minNetto)
                Divider().frame(height: 28)
                priceColumn("MITTE", value: mitteNetto)
                Divider().frame(height: 28)
                priceColumn("MAX",   value: maxNetto)
            }
            Text("\(evidenceCount) Preisbelege · netto")
                .font(.mykMono(9))
                .foregroundStyle(MykColor.faint.color)
        }
        .padding(.horizontal, MykSpace.s5)
        .padding(.vertical, MykSpace.s4)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.md)
                .fill(MykColor.card.color)
                .overlay(
                    RoundedRectangle(cornerRadius: MykRadius.md)
                        .stroke(MykColor.tasks.color.opacity(0.3), lineWidth: 1)
                )
        )
        .frame(maxWidth: 360)
    }

    private func priceColumn(_ label: String, value: Double) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.mykMono(8))
                .foregroundStyle(MykColor.faint.color)
            Text(euro(value))
                .font(.mykBody)
                .foregroundStyle(MykColor.ink.color)
        }
        .frame(maxWidth: .infinity)
    }
}
