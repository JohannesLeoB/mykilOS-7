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
    // S9: ausdrückliche Bestätigung legt einen Kontakt an. Wird vom App-Layer
    // injiziert (People-API + Audit dort), damit der Widgets-Layer keinen
    // Schreib-Client kennt. Erfolg → Anzeigename, Fehler → Meldung.
    let onCreateContact: ((ContactDraft) async -> ContactCreateOutcome)?
    // S14: Bestätigung legt einen Gmail-ENTWURF an (App-Layer: Gmail-API + Audit).
    let onCreateDraft: ((EmailDraft) async -> DraftCreateOutcome)?

    @Environment(StudioContext.self) private var context
    @State private var draft = ""
    @State private var showClearConfirm = false
    // S27: Assistent ist immer live (Tools an) — kein Opt-in-Toggle, kein
    // Schätzchat-Modus mehr. Live-Zugriffe + Kostenschätzung sind fester Teil des Chats.
    private let toolsEnabled = true

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
        profile: UserProfile? = nil,
        onCreateContact: ((ContactDraft) async -> ContactCreateOutcome)? = nil,
        onCreateDraft: ((EmailDraft) async -> DraftCreateOutcome)? = nil
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
        self.onCreateContact = onCreateContact
        self.onCreateDraft = onCreateDraft
    }

    private var messages: [ChatMessage] { chatStore.messages(for: scope) }

    public var body: some View {
        VStack(spacing: 0) {
            if isConnected {
                conversation
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
                    ForEach(messages) { ChatMessageBubble(message: $0, onCreateContact: onCreateContact, onCreateDraft: onCreateDraft).id($0.id) }
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

    // MARK: Eingabe
    private var composer: some View {
        return HStack(alignment: .bottom, spacing: MykSpace.s4) {
            TextField("Nachricht an den Assistenten ...", text: $draft, axis: .vertical)
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
                focusedDriveFolderID: focusedDriveFolderID,
                focusedClickUpListID: focusedClickUpListID,
                signals: signals, projects: projects, toolsEnabled: true,
                schaetzModusEnabled: false,
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
            Text(isConnected ? "CLAUDE  ·  AUTO  ·  \(AssistantModelRouter.tierLabel(engine.lastRoutedModel ?? modelName))" : "CLAUDE  ·  NICHT VERBUNDEN")
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
    var onCreateContact: ((ContactDraft) async -> ContactCreateOutcome)? = nil
    var onCreateDraft: ((EmailDraft) async -> DraftCreateOutcome)? = nil
    @State private var cursorVisible = true
    @State private var previewFile: DriveFileRef?

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
                // Kontakt-Bestätigungskarten nach der Antwort (S9).
                ForEach(Array(contactDrafts.enumerated()), id: \.offset) { _, draft in
                    ContactActionCard(draft: draft, onConfirm: onCreateContact)
                }
                // Mail-Entwurf-Bestätigungskarten nach der Antwort (S14).
                ForEach(Array(emailDrafts.enumerated()), id: \.offset) { _, draft in
                    DraftActionCard(draft: draft, onConfirm: onCreateDraft)
                }
                // Anklickbare Datei-Ergebnisse mit In-App-Vorschau (S22).
                ForEach(Array(driveFileBlocks.enumerated()), id: \.offset) { _, block in
                    DriveFilesCard(label: block.label, files: block.files,
                                   onOpen: { previewFile = $0 })
                }
                if case .failed = message.status {
                    Label("Erneut versuchen über erneutes Senden", systemImage: "exclamationmark.triangle")
                        .font(.mykMono(9.5)).foregroundStyle(MykColor.critical.color)
                }
            }
            if message.role == .assistant { Spacer(minLength: 40) }
        }
        .sheet(item: $previewFile) { ref in
            DocumentViewerView(
                file: GoogleDriveFile(id: ref.id, name: ref.name, mimeType: ref.mimeType,
                                      modifiedAt: nil, webViewLink: ref.webViewLink),
                remoteContent: { let id = ref.id; return try? await GoogleDriveClient().downloadContent(fileID: id) },
                onClose: { previewFile = nil })
        }
    }

    private var driveFileBlocks: [(label: String, files: [DriveFileRef])] {
        message.blocks.compactMap {
            if case let .driveFiles(label, files) = $0 { (label, files) } else { nil }
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

    private var contactDrafts: [ContactDraft] {
        message.blocks.compactMap {
            if case let .contactAction(draft) = $0 { draft } else { nil }
        }
    }

    private var emailDrafts: [EmailDraft] {
        message.blocks.compactMap {
            if case let .draftAction(draft) = $0 { draft } else { nil }
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
            ThinkingIndicator()
        } else {
            let cursor: String = (isStreaming && cursorVisible) ? "\u{2588}" : ""
            let displayText = isStreaming ? message.text + cursor : message.text
            Text(Self.rendered(displayText))
                .font(.mykBody)
                .foregroundStyle(message.role == .user ? MykColor.paper.color : MykColor.ink.color)
                .textSelection(.enabled)
                .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s4)
                .background(
                    RoundedRectangle(cornerRadius: MykRadius.md)
                        .fill(message.role == .user ? MykColor.ink.color : MykColor.card.color)
                )
                .onAppear {
                    guard isStreaming else { return }
                    withAnimation(.easeInOut(duration: 0.5).repeatForever()) { cursorVisible.toggle() }
                }
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

// MARK: - ContactActionCard (S9)
// Bestätigungskarte für einen vom Assistenten vorgeschlagenen NEUEN Kontakt.
// Schreibt nichts, bis der Nutzer „Kontakt anlegen" drückt — dann ruft sie die
// injizierte Aktion (People-API + Audit im App-Layer) und zeigt Erfolg/Fehler.
struct ContactActionCard: View {
    let draft: ContactDraft
    var onConfirm: ((ContactDraft) async -> ContactCreateOutcome)?

    private enum CardPhase: Equatable { case idle, saving, done(String), failed(String) }
    @State private var phase: CardPhase = .idle

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.mykCaption).foregroundStyle(MykColor.people.color)
                Text("Neuer Kontakt").font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
            }
            Text(draft.displayName).font(.mykBody).foregroundStyle(MykColor.ink.color)
            ForEach(detailLines, id: \.self) { line in
                Text(line).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
            actionRow
        }
        .padding(.horizontal, MykSpace.s5)
        .padding(.vertical, MykSpace.s4)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.md)
                .fill(MykColor.card.color)
                .overlay(RoundedRectangle(cornerRadius: MykRadius.md)
                    .stroke(MykColor.people.color.opacity(0.3), lineWidth: 1))
        )
        .frame(maxWidth: 360)
    }

    private var detailLines: [String] {
        var lines: [String] = []
        if let mail = draft.email { lines.append("✉︎ \(mail)") }
        if let phone = draft.phone { lines.append("☎ \(phone)") }
        if let org = draft.organization { lines.append("⌂ \(org)") }
        return lines
    }

    @ViewBuilder
    private var actionRow: some View {
        switch phase {
        case .idle:
            Button {
                guard let onConfirm else { phase = .failed("Anlegen hier nicht verfügbar."); return }
                phase = .saving
                Task {
                    let outcome = await onConfirm(draft)
                    switch outcome {
                    case .created(let name): phase = .done(name)
                    case .failed(let msg):   phase = .failed(msg)
                    }
                }
            } label: {
                Text("Kontakt anlegen")
                    .font(.mykMono(10)).foregroundStyle(MykColor.paper.color)
                    .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s2)
                    .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.people.color))
            }
            .buttonStyle(.plain)
            .disabled(onConfirm == nil)
        case .saving:
            HStack(spacing: MykSpace.s2) {
                ProgressView().controlSize(.small)
                Text("Lege an …").font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
        case .done(let name):
            Label("Angelegt: \(name)", systemImage: "checkmark.circle.fill")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.positive.color)
        case .failed(let msg):
            Label(msg, systemImage: "exclamationmark.triangle")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.critical.color)
        }
    }
}

// MARK: - DraftActionCard (S14)
// Bestätigungskarte für einen vom Assistenten vorgeschlagenen Mail-ENTWURF. Schreibt
// nichts, bis der Nutzer „Entwurf anlegen" drückt — dann legt der App-Layer einen
// Gmail-Entwurf an (erscheint auch in Apple Mail). Versendet NIE.
struct DraftActionCard: View {
    let draft: EmailDraft
    var onConfirm: ((EmailDraft) async -> DraftCreateOutcome)?

    private enum CardPhase: Equatable { case idle, saving, done(String), failed(String) }
    @State private var phase: CardPhase = .idle

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "envelope.badge")
                    .font(.mykCaption).foregroundStyle(MykColor.drive.color)
                Text("Mail-Entwurf").font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
            }
            if let to = draft.to, to.isEmpty == false {
                Text("An: \(to)").font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
            }
            Text(draft.subject.isEmpty ? "(kein Betreff)" : draft.subject)
                .font(.mykBody).foregroundStyle(MykColor.ink.color)
            Text(draft.body)
                .font(.mykSmall).foregroundStyle(MykColor.muted.color)
                .lineLimit(6)
            actionRow
        }
        .padding(.horizontal, MykSpace.s5)
        .padding(.vertical, MykSpace.s4)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.md)
                .fill(MykColor.card.color)
                .overlay(RoundedRectangle(cornerRadius: MykRadius.md)
                    .stroke(MykColor.drive.color.opacity(0.3), lineWidth: 1))
        )
        .frame(maxWidth: 420)
    }

    @ViewBuilder
    private var actionRow: some View {
        switch phase {
        case .idle:
            Button {
                guard let onConfirm else { phase = .failed("Ablegen hier nicht verfügbar."); return }
                phase = .saving
                Task {
                    switch await onConfirm(draft) {
                    case .created(let info): phase = .done(info)
                    case .failed(let msg):   phase = .failed(msg)
                    }
                }
            } label: {
                Text("Entwurf anlegen")
                    .font(.mykMono(10)).foregroundStyle(MykColor.paper.color)
                    .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s2)
                    .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.drive.color))
            }
            .buttonStyle(.plain)
            .disabled(onConfirm == nil)
        case .saving:
            HStack(spacing: MykSpace.s2) {
                ProgressView().controlSize(.small)
                Text("Lege Entwurf an …").font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
        case .done(let info):
            Label(info, systemImage: "checkmark.circle.fill")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.positive.color)
        case .failed(let msg):
            Label(msg, systemImage: "exclamationmark.triangle")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.critical.color)
        }
    }
}

// MARK: - DriveFilesCard (S22) — anklickbare Datei-Ergebnisse mit In-App-Vorschau
struct DriveFilesCard: View {
    let label: String
    let files: [DriveFileRef]
    var onOpen: (DriveFileRef) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "folder").font(.mykCaption).foregroundStyle(MykColor.drive.color)
                Text("\(label) (\(files.count))").font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
            }
            ForEach(files) { file in
                Button { onOpen(file) } label: {
                    HStack(spacing: MykSpace.s3) {
                        Image(systemName: icon(for: file.mimeType))
                            .font(.mykSmall).foregroundStyle(MykColor.drive.color).frame(width: 18)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(file.name).font(.mykSmall).foregroundStyle(MykColor.ink.color).lineLimit(1)
                            if let sub = file.subtitle {
                                Text(sub).font(.mykMono(8.5)).foregroundStyle(MykColor.faint.color)
                            }
                        }
                        Spacer()
                        Image(systemName: "eye").font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                    }
                    .padding(.horizontal, MykSpace.s3).padding(.vertical, MykSpace.s2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MykSpace.s4)
        .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color)
            .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.drive.color.opacity(0.3), lineWidth: 1)))
        .frame(maxWidth: 460)
    }

    private func icon(for mimeType: String) -> String {
        if mimeType == "application/pdf" { return "doc.richtext" }
        if mimeType.hasPrefix("image/") { return "photo" }
        if mimeType.hasPrefix("application/vnd.google-apps") { return "globe" }
        return "doc"
    }
}

// MARK: - ThinkingIndicator (L14)
// Animierte 3-Punkt-Ladeanzeige während Claude denkt (keine Antwort-Tokens bisher).
struct ThinkingIndicator: View {
    @State private var phase: Int = 0
    private let timer = Timer.publish(every: 0.42, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(MykColor.muted.color)
                    .frame(width: 6, height: 6)
                    .scaleEffect(phase == i ? 1.35 : 0.85)
                    .animation(.easeInOut(duration: 0.38), value: phase)
            }
        }
        .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s4)
        .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color))
        .onReceive(timer) { _ in phase = (phase + 1) % 3 }
    }
}

// MARK: - AssistantCapability + AssistantCapabilityChip (L15)
// Zeigt welche Live-Tools verfügbar sind — sichtbare Capability-Chips im optInBar.
enum AssistantCapability: CaseIterable {
    case gmail, kalender, drive, aufgaben, kontakte, studio, kalkulation

    var label: String {
        switch self {
        case .gmail:       "Gmail"
        case .kalender:    "Kalender"
        case .drive:       "Drive"
        case .aufgaben:    "Aufgaben"
        case .kontakte:    "Kontakte"
        case .studio:      "Studio-Wissen"
        case .kalkulation: "Kalkulation"
        }
    }

    var icon: String {
        switch self {
        case .gmail:       "envelope"
        case .kalender:    "calendar"
        case .drive:       "folder"
        case .aufgaben:    "checkmark.square"
        case .kontakte:    "person.2"
        case .studio:      "building.2"
        case .kalkulation: "eurosign.square"
        }
    }

    var color: MykColor {
        switch self {
        case .gmail, .kalender, .kontakte: .people
        case .drive:       .drive
        case .aufgaben:    .tasks
        case .studio:      .brand
        case .kalkulation: .tasks
        }
    }
}

struct AssistantCapabilityChip: View {
    let cap: AssistantCapability
    let active: Bool

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: cap.icon)
            Text(cap.label)
        }
        .font(.mykMono(8.5))
        .foregroundStyle(active ? cap.color.color : MykColor.faint.color)
        .padding(.horizontal, MykSpace.s3)
        .padding(.vertical, 3)
        .background(Capsule().fill(active ? cap.color.color.opacity(0.1) : MykColor.faint.color.opacity(0.06)))
        .overlay(Capsule().stroke(active ? cap.color.color.opacity(0.25) : MykColor.line.color, lineWidth: 1))
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
