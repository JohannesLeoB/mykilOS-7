import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - MailFolder
// Ordner/Ansichten-Auswahl — dezente mykilOS-Segment-Reihe (kein Apple-Mail-Klon).
// Jeder Ordner hat eine Gmail-Query, ein SF-Symbol und einen kurzen Label.
enum MailFolder: CaseIterable, Identifiable {
    case inbox, starred, sent, drafts

    var id: Self { self }

    var label: String {
        switch self {
        case .inbox:   return "Eingang"
        case .starred: return "Markiert"
        case .sent:    return "Gesendet"
        case .drafts:  return "Entwürfe"
        }
    }

    var icon: String {
        switch self {
        case .inbox:   return "tray"
        case .starred: return "flag"
        case .sent:    return "paperplane"
        case .drafts:  return "doc.text"
        }
    }

    /// Gmail-Query für diesen Ordner.
    var gmailQuery: String {
        switch self {
        case .inbox:   return "in:inbox"
        // Apple-Mail-Flags syncen zu Gmail-Sternen → is:starred
        case .starred: return "is:starred"
        case .sent:    return "in:sent"
        // Härtung (2026-07-01, Johannes): "Entwürfe"-Ordner fehlte im Mail-Modus.
        // Nutzt dieselbe generische searchMessages(query:)-Infrastruktur wie die
        // anderen drei Ordner — Gmails messages.list-Suche versteht "in:drafts" genauso.
        case .drafts:  return "in:drafts"
        }
    }
}

// MARK: - MailClientView
// 3-Spalten-Mail-Reader: Ordnerauswahl + Suchleiste + Nachrichtenliste (links) + Volltext (rechts).
// Nutzt GoogleGmailClient.searchMessages + fetchBody. KEIN Senden — nur Lesen + Entwurf.
// Kontakt-Brücke (Phase 3): Airtable Mastermind-Base appuVMh3KDfKw4OoQ,
// Tabelle Kontakte (tblncfQzQa8TzCZQC) → StudioContact → Empfänger-Picker.
@MainActor
struct MailClientView: View {
    @Environment(AppState.self) private var appState
    // Eingebettet im Assistenten-Toggle bringt die Seite ihren Titel schon mit —
    // dann KEINEN eigenen „Mail"-Kopf rendern (sonst steht „Mail" doppelt).
    var showsOwnHeader: Bool = true
    // „Verfassen" wird vom Seiten-Header (neben dem Toggle) gesteuert — NICHT mehr
    // über ein Fenster-Toolbar-Item, das beim Tab-Wechsel auftauchte/verschwand und
    // dabei den ganzen Inhalt verschob.
    @Binding var showCompose: Bool
    @State private var store = MailClientStore()
    @State private var airtableContacts: [StudioContact] = []
    @State private var composeConfig: ComposeConfig? = nil

    /// Konfiguration für den Compose-Sheet (Reply/Forward/Neu).
    struct ComposeConfig: Identifiable {
        var id: UUID = UUID()
        var to: String? = nil
        var cc: String? = nil
        var subject: String? = nil
        var body: String? = nil
    }

    var body: some View {
        HStack(spacing: 0) {
            messageListPane
            Divider()
            detailPane
        }
        // Füllt den verfügbaren Raum vollständig — sonst dimensioniert sich die
        // Höhe nach Inhalt und das Fenster verspringt beim Toggle Assistent⇄Mail.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MykColor.paper.color)
        // Neuer Sheet: via composeConfig identifiable (ersetzt alten showCompose-Bool).
        .sheet(item: $composeConfig) { config in
            ComposeMailView(
                contacts: airtableContacts,
                prefilledTo: config.to,
                prefilledCc: config.cc,
                prefilledSubject: config.subject,
                prefilledBody: config.body
            )
        }
        // Externer Trigger von außen (z. B. Header-Button "Verfassen").
        .onChange(of: showCompose) { _, newValue in
            if newValue {
                composeConfig = ComposeConfig()
                showCompose = false
            }
        }
        .task {
            // Auto-Posteingang: beim ersten Erscheinen sofort die Inbox laden,
            // sofern noch kein Suchergebnis vorliegt (store.phase == .idle).
            await store.loadInboxIfNeeded()
            await loadAirtableContacts()
        }
    }

    /// Lädt Kontakte aus Airtable Mastermind-Base (appuVMh3KDfKw4OoQ).
    /// Fehler werden still geschluckt — fehlende Kontakte = leere Picker-Liste, kein Crash.
    private func loadAirtableContacts() async {
        let client = AirtableClient()
        let baseID = "appuVMh3KDfKw4OoQ"
        let tableID = "tblncfQzQa8TzCZQC"
        guard let records = try? await client.fetchRecords(baseID: baseID, table: tableID) else { return }
        airtableContacts = AirtableClient.mapContacts(from: records)
        // Härtung (2026-07-01, Audit): dritter, unabhängiger Reader derselben Kontakte-Tabelle
        // (neben AppState.syncKontakte + AirtableContactsLoader) — bisher ohne jedes
        // dataFlow.log. Nutzt dieselbe Manifest-ID wie AppState.syncKontakte, da es
        // semantisch derselbe Lookup ist.
        appState.dataFlow.log(integrationID: "AIRTABLE_KONTAKTE_LOOKUP", actorUserID: appState.actorUserID,
                               action: .success, recordsRead: airtableContacts.count,
                               summary: "Mail-Compose: Kontakte für Empfänger-Picker geladen")
    }

    // MARK: - Linke Spalte: Ordner + Suche + Nachrichtenliste

    private var messageListPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsOwnHeader { header }
            folderBar
            Divider().overlay(MykColor.line.color)
            searchBar
            Divider().overlay(MykColor.line.color)
            messageList
        }
        .frame(width: 320)
        .background(MykColor.paper.color)
    }

    private var header: some View {
        HStack {
            Image(systemName: "envelope")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.personal.color)
            Text("Mail")
                .font(.mykDisplay)
                .foregroundStyle(MykColor.ink.color)
            Spacer()
            if store.isLoading {
                ProgressView().scaleEffect(0.7)
            }
        }
        .padding(.horizontal, MykSpace.s6)
        .padding(.top, MykSpace.s6)
        .padding(.bottom, MykSpace.s3)
    }

    // MARK: Ordner-Leiste (dezent, mykilOS-Stil — kein Apple-Mail-Klon)

    private var folderBar: some View {
        HStack(spacing: MykSpace.s2) {
            ForEach(MailFolder.allCases) { folder in
                folderButton(folder)
            }
            Spacer()
        }
        .padding(.horizontal, MykSpace.s5)
        .padding(.vertical, MykSpace.s3)
        .background(MykColor.paper.color)
    }

    private func folderButton(_ folder: MailFolder) -> some View {
        let isActive = store.activeFolder == folder
        return Button {
            guard store.activeFolder != folder else { return }
            store.switchFolder(folder)
            Task { await store.loadFolder() }
        } label: {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: folder.icon)
                    .font(.mykMono(10))
                Text(folder.label)
                    .font(.mykMono(10))
            }
            .foregroundStyle(isActive ? MykColor.personal.color : MykColor.muted.color)
            .padding(.horizontal, MykSpace.s3)
            .padding(.vertical, 4)
            .background(
                isActive
                    ? MykColor.personal.color.opacity(0.1)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: MykRadius.sm)
                    .stroke(
                        isActive ? MykColor.personal.color.opacity(0.25) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var searchBar: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: "magnifyingglass")
                .font(.mykCaption)
                .foregroundStyle(MykColor.muted.color)
            TextField("Suchen …", text: $store.query)
                .font(.mykBody)
                .textFieldStyle(.plain)
                .onSubmit { Task { await store.search() } }
            if !store.query.isEmpty {
                Button {
                    store.query = ""
                    Task { await store.loadFolder() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.mykCaption)
                        .foregroundStyle(MykColor.muted.color)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MykSpace.s4)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
        .padding(.horizontal, MykSpace.s5)
        .padding(.vertical, MykSpace.s3)
    }

    private var messageList: some View {
        Group {
            switch store.phase {
            case .idle:
                // Sollte nach dem Auto-Inbox-Load nie dauerhaft zu sehen sein.
                hintText("Posteingang wird geladen …")
            case .loading:
                VStack { Spacer(); ProgressView("Lade …").font(.mykSmall); Spacer() }
                    .frame(maxWidth: .infinity)
            case .notConnected:
                hintText("Google nicht verbunden. Bitte in den Einstellungen verbinden.")
            case .empty:
                let label = store.query.isEmpty ? store.activeFolder.label : store.query
                hintText("Keine Treffer in \"\(label)\".")
            case .error(let msg):
                hintText("Fehler: \(msg)")
            case .loaded:
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.messages) { msg in
                            MailListRow(
                                message: msg,
                                isSelected: store.selectedID == msg.id
                            ) {
                                store.select(msg)
                                Task { await store.loadBody(for: msg) }
                            }
                            Divider().overlay(MykColor.line.color.opacity(0.5))
                        }
                    }
                }
            }
        }
    }

    private func hintText(_ text: String) -> some View {
        Text(text)
            .font(.mykMono(10))
            .foregroundStyle(MykColor.muted.color)
            .padding(MykSpace.s6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Rechte Spalte: Volltext

    private var detailPane: some View {
        Group {
            if let selected = store.selectedMessage {
                MailDetailView(
                    message: selected,
                    mailBody: store.selectedBody,
                    isLoadingBody: store.isLoadingBody
                ) { action in
                    handleDetailAction(action, message: selected)
                }
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "envelope.open")
                        .font(.largeTitle)
                        .foregroundStyle(MykColor.faint.color)
                    Text("Nachricht auswählen")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.muted.color)
                        .padding(.top, MykSpace.s3)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Detail-Aktionen (Reply / ReplyAll / Forward)

    private func handleDetailAction(_ action: MailDetailAction, message: GoogleGmailMessage) {
        let body = store.selectedBody.isEmpty ? message.snippet : store.selectedBody
        let quoted = message.quotedBody(body)
        switch action {
        case .reply:
            composeConfig = ComposeConfig(
                to: message.senderEmail,
                subject: message.replySubject,
                body: quoted
            )
        case .replyAll:
            // To = Absender, CC = restliche Empfänger (original To + CC, ohne eigene Adresse)
            let others = buildReplyAllCC(message: message)
            composeConfig = ComposeConfig(
                to: message.senderEmail,
                cc: others.isEmpty ? nil : others,
                subject: message.replySubject,
                body: quoted
            )
        case .forward:
            composeConfig = ComposeConfig(
                subject: message.forwardSubject,
                body: quoted
            )
        }
    }

    /// Baut die CC-Zeile für Reply-All: original To + Cc, Absender herausgefiltert.
    private func buildReplyAllCC(message: GoogleGmailMessage) -> String {
        var addresses: [String] = []
        if !message.toRaw.isEmpty { addresses.append(message.toRaw) }
        if !message.ccRaw.isEmpty { addresses.append(message.ccRaw) }
        let senderEmail = message.senderEmail.lowercased()
        // Komma-getrennte Adressen einzeln filtern
        let filtered = addresses
            .flatMap { $0.components(separatedBy: ",") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { GoogleGmailMessage.extractEmail(from: $0).lowercased() != senderEmail }
        return filtered.joined(separator: ", ")
    }
}

// MARK: - MailDetailAction
enum MailDetailAction {
    case reply, replyAll, forward
}

// MARK: - MailListRow
private struct MailListRow: View {
    let message: GoogleGmailMessage
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: MykSpace.s4) {
                Image(systemName: "envelope")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.personal.color)
                    .frame(width: 18)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(message.from)
                            .font(.mykSmall)
                            .foregroundStyle(MykColor.ink.color)
                            .lineLimit(1)
                        Spacer()
                        if let date = message.receivedAt {
                            Text(date.formatted(.relative(presentation: .named)))
                                .font(.mykMono(9))
                                .foregroundStyle(MykColor.faint.color)
                        }
                    }
                    Text(message.subject)
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.inkSoft.color)
                        .lineLimit(1)
                    Text(message.snippet)
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.muted.color)
                        .lineLimit(2)
                    if !message.attachments.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "paperclip")
                                .font(.mykMono(9))
                            Text("\(message.attachments.count) Anhang\(message.attachments.count == 1 ? "" : "hänge")")
                                .font(.mykMono(9))
                        }
                        .foregroundStyle(MykColor.muted.color)
                    }
                }
            }
            .padding(.horizontal, MykSpace.s5)
            .padding(.vertical, MykSpace.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? MykColor.personal.color.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MailDetailView
private struct MailDetailView: View {
    let message: GoogleGmailMessage
    let mailBody: String
    let isLoadingBody: Bool
    let onAction: (MailDetailAction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Aktionsleiste (Reply / ReplyAll / Forward)
            actionBar
            Divider().overlay(MykColor.line.color)
            // Nachrichteninhalt
            ScrollView {
                VStack(alignment: .leading, spacing: MykSpace.s5) {
                    messageHeader
                    Divider().overlay(MykColor.line.color)
                    messageBody
                    if !message.attachments.isEmpty { attachmentsSection }
                    sourceFooter
                }
                .padding(MykSpace.s7)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: Aktionsleiste

    private var actionBar: some View {
        HStack(spacing: MykSpace.s4) {
            actionButton(
                icon: "arrowshape.turn.up.left",
                label: "Antworten",
                action: .reply
            )
            actionButton(
                icon: "arrowshape.turn.up.left.2",
                label: "Allen antworten",
                action: .replyAll
            )
            actionButton(
                icon: "arrowshape.turn.up.right",
                label: "Weiterleiten",
                action: .forward
            )
            Spacer()
            Text("GMAIL  ·  LESEN")
                .font(.mykMono(9))
                .foregroundStyle(MykColor.faint.color)
        }
        .padding(.horizontal, MykSpace.s6)
        .padding(.vertical, MykSpace.s4)
        .background(MykColor.card.color)
    }

    private func actionButton(icon: String, label: String, action: MailDetailAction) -> some View {
        Button {
            onAction(action)
        } label: {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: icon)
                    .font(.mykMono(10))
                Text(label)
                    .font(.mykMono(10))
            }
            .foregroundStyle(MykColor.personal.color)
            .padding(.horizontal, MykSpace.s3)
            .padding(.vertical, 4)
            .background(MykColor.personal.color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        }
        .buttonStyle(.plain)
        .help(label)
    }

    // MARK: Nachrichten-Header

    private var messageHeader: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            Text(message.subject)
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "person.circle")
                    .foregroundStyle(MykColor.personal.color)
                Text(message.from)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.inkSoft.color)
                Spacer()
                if let date = message.receivedAt {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.faint.color)
                }
            }
            // Labels
            let visibleLabels = message.labels.filter { !["INBOX", "UNREAD", "SENT"].contains($0) }
            if !visibleLabels.isEmpty {
                HStack {
                    ForEach(visibleLabels, id: \.self) { label in
                        Text(label)
                            .font(.mykMono(9))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(MykColor.personal.color.opacity(0.15))
                            .clipShape(Capsule())
                            .foregroundStyle(MykColor.personal.color)
                    }
                }
            }
        }
        .padding(.bottom, MykSpace.s3)
    }

    // MARK: Body

    private var messageBody: some View {
        Group {
            if isLoadingBody {
                HStack { Spacer(); ProgressView("Lade Mail …").font(.mykSmall); Spacer() }
                    .padding(.vertical, MykSpace.s6)
            } else if mailBody.isEmpty {
                Text(message.snippet)
                    .font(.mykBody)
                    .foregroundStyle(MykColor.inkSoft.color)
            } else {
                Text(mailBody)
                    .font(.mykBody)
                    .foregroundStyle(MykColor.ink.color)
                    .textSelection(.enabled)
            }
        }
    }

    // MARK: Anhänge

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            Divider().overlay(MykColor.line.color)
            Text("ANHÄNGE")
                .font(.mykMono(9))
                .foregroundStyle(MykColor.muted.color)
            ForEach(message.attachments, id: \.attachmentID) { att in
                AttachmentRow(attachment: att)
            }
        }
    }

    // MARK: Quellenzeile

    private var sourceFooter: some View {
        Group {
            Divider().overlay(MykColor.line.color)
            // Quellenzeile unten rechts
            Color.clear.frame(height: 0) // Spacer-Ersatz ohne Padding-Interferenz
        }
    }
}

// MARK: - AttachmentRow
private struct AttachmentRow: View {
    let attachment: GmailAttachment

    var body: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: iconName(for: attachment.mimeType))
                .foregroundStyle(MykColor.personal.color)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.filename)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.ink.color)
                Text(humanSize(attachment.sizeBytes))
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.muted.color)
            }
            Spacer()
        }
        .padding(MykSpace.s4)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
    }

    private func iconName(for mimeType: String) -> String {
        if mimeType.hasPrefix("image/") { return "photo" }
        if mimeType == "application/pdf" { return "doc.richtext" }
        if mimeType.hasPrefix("text/") { return "doc.text" }
        return "paperclip"
    }

    private func humanSize(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1_048_576 { return "\(bytes / 1024) KB" }
        return String(format: "%.1f MB", Double(bytes) / 1_048_576)
    }
}

// MARK: - MailClientStore
@MainActor
@Observable
final class MailClientStore {
    enum Phase: Equatable {
        case idle, loading, loaded, empty, notConnected, error(String)
    }

    var query: String = ""
    private(set) var activeFolder: MailFolder = .inbox
    private(set) var messages: [GoogleGmailMessage] = []
    private(set) var phase: Phase = .idle
    private(set) var selectedID: String? = nil
    private(set) var selectedMessage: GoogleGmailMessage? = nil
    private(set) var selectedBody: String = ""
    private(set) var isLoading = false
    private(set) var isLoadingBody = false

    private let client: any GoogleGmailFetching
    private var searchGen = 0
    private var bodyGen = 0

    init(client: any GoogleGmailFetching = GoogleGmailClient()) {
        self.client = client
    }

    /// Ordner wechseln (setzt Suche zurück).
    func switchFolder(_ folder: MailFolder) {
        activeFolder = folder
        query = ""
        selectedID = nil
        selectedMessage = nil
        selectedBody = ""
        messages = []
        phase = .idle
    }

    /// Lädt den aktiven Ordner (wird nach switchFolder() und bei Pull-to-Refresh aufgerufen).
    func loadFolder() async {
        await fetchMessages(query: activeFolder.gmailQuery)
    }

    /// Lädt den Posteingang (in:inbox) beim ersten Öffnen automatisch,
    /// sofern noch kein Suchergebnis vorliegt.
    func loadInboxIfNeeded() async {
        guard phase == .idle else { return }
        await fetchMessages(query: activeFolder.gmailQuery)
    }

    func search() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        // Leere Suche → zurück zum aktiven Ordner
        guard !q.isEmpty else {
            await loadFolder()
            return
        }
        await fetchMessages(query: q)
    }

    /// Gemeinsamer Kern für Inbox-Load + Ordner-Wechsel + freie Suche.
    private func fetchMessages(query q: String) async {
        searchGen &+= 1
        let gen = searchGen
        phase = .loading
        isLoading = true
        do {
            let result = try await client.searchMessages(query: q, maxResults: 25)
            guard gen == searchGen else { return }
            messages = result
            phase = result.isEmpty ? .empty : .loaded
        } catch GoogleGmailError.notConnected {
            guard gen == searchGen else { return }
            phase = .notConnected; messages = []
        } catch {
            guard gen == searchGen else { return }
            phase = .error(error.localizedDescription); messages = []
        }
        isLoading = false
    }

    func select(_ message: GoogleGmailMessage) {
        selectedID = message.id
        selectedMessage = message
        selectedBody = ""
    }

    func loadBody(for message: GoogleGmailMessage) async {
        bodyGen &+= 1
        let gen = bodyGen
        isLoadingBody = true
        do {
            let text = try await client.fetchBody(messageID: message.id)
            guard gen == bodyGen else { return }
            selectedBody = text
        } catch {
            guard gen == bodyGen else { return }
            selectedBody = message.snippet
        }
        isLoadingBody = false
    }
}
