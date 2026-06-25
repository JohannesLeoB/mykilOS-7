import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - MailWidget
// E-Mails zum Projekt, gefiltert über Project.links.mailQuery (Gmail-Suche).
// Pflaume.
public struct MailWidget: View {
    public let projectID: String
    public let mailQuery: String?

    public init(projectID: String, mailQuery: String?) {
        self.projectID = projectID
        self.mailQuery = mailQuery
    }

    @State private var loader = MailLoader()

    public var body: some View {
        WidgetContainer(
            kind: .mail,
            sourceLabel: sourceLabel,
            renderState: loader.renderState,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                widgetHeader
                messageList
            }
        }
        .task(id: mailQuery) {
            await loader.load(query: mailQuery)
        }
    }

    private var sourceLabel: String {
        switch loader.renderState {
        case .content: "GMAIL  ·  \(loader.messages.count) E-MAILS"
        default:       "GMAIL"
        }
    }

    private var widgetHeader: some View {
        HStack {
            SourceChip(kind: .mail)
            Text("E-Mails").mykWidgetTitle()
            Spacer()
            if case .error = loader.renderState {
                retryButton
            } else if case .permissionRequired = loader.renderState {
                retryButton
            }
        }
    }

    private var retryButton: some View {
        Button("Erneut versuchen") {
            Task { await loader.load(query: mailQuery) }
        }
        .font(.mykMono(9.5))
        .buttonStyle(.plain)
        .foregroundStyle(MykColor.personal.color)
    }

    private var messageList: some View {
        VStack(spacing: 0) {
            ForEach(loader.messages) { message in
                MailRow(message: message)
                if message.id != loader.messages.last?.id {
                    Divider().overlay(MykColor.line.color.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - MailLoader
@MainActor
@Observable
private final class MailLoader {
    private(set) var messages: [GoogleGmailMessage] = []
    private(set) var renderState: WidgetRenderState = .loading

    private let client: GoogleGmailFetching

    init(client: GoogleGmailFetching = GoogleGmailClient()) {
        self.client = client
    }

    func load(query: String?) async {
        guard let query, query.isEmpty == false else {
            messages = []
            renderState = .empty
            return
        }
        renderState = .loading
        do {
            let result = try await client.searchMessages(query: query, maxResults: 10)
            messages = result
            renderState = result.isEmpty ? .empty : .content
        } catch GoogleGmailError.notConnected {
            messages = []
            renderState = .permissionRequired
        } catch {
            messages = []
            renderState = .error(String(describing: error))
        }
    }
}

// MARK: - MailRow
private struct MailRow: View {
    let message: GoogleGmailMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: MykSpace.s4) {
                Image(systemName: "envelope")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.personal.color)
                    .frame(width: 20)
                Text(message.from)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.ink.color)
                    .lineLimit(1)
                Spacer()
                if let receivedAt = message.receivedAt {
                    Text(receivedAt.formatted(.relative(presentation: .named)))
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.faint.color)
                }
            }
            Text(message.subject)
                .font(.mykSmall)
                .foregroundStyle(MykColor.ink.color)
                .lineLimit(1)
            Text(message.snippet)
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
                .lineLimit(2)
        }
        .padding(.vertical, MykSpace.s4)
    }
}
