import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - MailClientView
// 3-Spalten-Mail-Reader: Suchleiste + Nachrichtenliste (links) + Volltext (rechts).
// Nutzt GoogleGmailClient.searchMessages + fetchBody. KEIN Senden — nur Lesen + Entwurf.
// Kontakt-Brücke (Phase 3): Airtable Mastermind-Base appuVMh3KDfKw4OoQ,
// Tabelle Kontakte (tblncfQzQa8TzCZQC) → StudioContact → Empfänger-Picker.
@MainActor
struct MailClientView: View {
    // Eingebettet im Assistenten-Toggle bringt die Seite ihren Titel schon mit —
    // dann KEINEN eigenen „Mail"-Kopf rendern (sonst steht „Mail" doppelt).
    var showsOwnHeader: Bool = true
    // „Verfassen" wird vom Seiten-Header (neben dem Toggle) gesteuert — NICHT mehr
    // über ein Fenster-Toolbar-Item, das beim Tab-Wechsel auftauchte/verschwand und
    // dabei den ganzen Inhalt verschob.
    @Binding var showCompose: Bool
    @State private var store = MailClientStore()
    @State private var airtableContacts: [StudioContact] = []

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
        .sheet(isPresented: $showCompose) {
            ComposeMailView(contacts: airtableContacts)
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
    }

    // MARK: - Linke Spalte: Suche + Nachrichtenliste

    private var messageListPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsOwnHeader { header }
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
                    Task { await store.search() }
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
                // Falls doch (kein Netz), zeigen wir eine Mini-Erklärnote.
                hintText("Posteingang wird geladen …")
            case .loading:
                VStack { Spacer(); ProgressView("Lade …").font(.mykSmall); Spacer() }
                    .frame(maxWidth: .infinity)
            case .notConnected:
                hintText("Google nicht verbunden. Bitte in den Einstellungen verbinden.")
            case .empty:
                hintText("Keine Treffer für \"\(store.query)\".")
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
                )
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                // Header
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
                    if !message.labels.filter({ !["INBOX", "UNREAD", "SENT"].contains($0) }).isEmpty {
                        HStack {
                            ForEach(message.labels.filter { !["INBOX", "UNREAD", "SENT"].contains($0) }, id: \.self) { label in
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
                Divider().overlay(MykColor.line.color)
                // Body
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
                // Attachments
                if !message.attachments.isEmpty {
                    Divider().overlay(MykColor.line.color)
                    VStack(alignment: .leading, spacing: MykSpace.s3) {
                        Text("ANHÄNGE")
                            .font(.mykMono(9))
                            .foregroundStyle(MykColor.muted.color)
                        ForEach(message.attachments, id: \.attachmentID) { att in
                            AttachmentRow(attachment: att)
                        }
                    }
                }
                // Quellenzeile
                Divider().overlay(MykColor.line.color)
                Text("GMAIL  ·  LESEN")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.faint.color)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(MykSpace.s7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

    /// Lädt den Posteingang (in:inbox) beim ersten Öffnen automatisch,
    /// sofern noch kein Suchergebnis vorliegt.
    func loadInboxIfNeeded() async {
        guard phase == .idle else { return }
        await fetchMessages(query: "in:inbox")
    }

    func search() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        // Leere Suche → zurück zum Posteingang
        guard !q.isEmpty else {
            await fetchMessages(query: "in:inbox")
            return
        }
        await fetchMessages(query: q)
    }

    /// Gemeinsamer Kern für Inbox-Load + freie Suche.
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
