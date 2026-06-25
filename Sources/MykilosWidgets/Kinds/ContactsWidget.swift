import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - ContactsWidget
// Kontakte aus dem verbundenen Google-Account, gefiltert über
// Project.links.contactsQuery. Salbei.
public struct ContactsWidget: View {
    public let projectID: String
    public let contactsQuery: String?

    public init(projectID: String, contactsQuery: String?) {
        self.projectID = projectID
        self.contactsQuery = contactsQuery
    }

    @State private var loader = ContactsLoader()

    public var body: some View {
        WidgetContainer(
            kind: .contacts,
            sourceLabel: "KONTAKTE  ·  GOOGLE",
            renderState: loader.renderState,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                widgetHeader
                contactList
            }
        }
        .task(id: contactsQuery) {
            await loader.load(query: contactsQuery)
        }
    }

    private var widgetHeader: some View {
        HStack {
            SourceChip(kind: .contacts)
            Text("Kontakte").mykWidgetTitle()
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
            Task { await loader.load(query: contactsQuery) }
        }
        .font(.mykMono(9.5))
        .buttonStyle(.plain)
        .foregroundStyle(MykColor.people.color)
    }

    private var contactList: some View {
        VStack(spacing: 0) {
            ForEach(loader.contacts) { contact in
                ContactRow(contact: contact)
                if contact.id != loader.contacts.last?.id {
                    Divider().overlay(MykColor.line.color.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - ContactsLoader
// Pro Widget-Instanz, kein geteilter Zustand — reine Lesefetches, kein
// Speichern-Vertrag wie bei NoteStore/WidgetBoardStore.
@MainActor
@Observable
private final class ContactsLoader {
    private(set) var contacts: [GoogleContact] = []
    private(set) var renderState: WidgetRenderState = .loading

    private let client: GoogleContactsFetching

    init(client: GoogleContactsFetching = GoogleContactsClient()) {
        self.client = client
    }

    func load(query: String?) async {
        guard let query, query.isEmpty == false else {
            contacts = []
            renderState = .empty
            return
        }
        renderState = .loading
        do {
            let result = try await client.searchContacts(query: query)
            contacts = result
            renderState = result.isEmpty ? .empty : .content
        } catch GoogleContactsError.notConnected {
            contacts = []
            renderState = .permissionRequired
        } catch {
            contacts = []
            renderState = .error(String(describing: error))
        }
    }
}

// MARK: - ContactRow
private struct ContactRow: View {
    let contact: GoogleContact

    var body: some View {
        HStack(spacing: MykSpace.s4) {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [MykColor.people.color, MykColor.people.color.opacity(0.7)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 36, height: 36)
                .overlay(Text(initials).font(.mykMono(11)).foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.displayName).font(.mykSmall).foregroundStyle(MykColor.ink.color)
                Text(subtitle).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
            Spacer()
        }
        .padding(.vertical, MykSpace.s3)
    }

    private var initials: String {
        let parts = contact.displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    private var subtitle: String {
        let parts = [contact.organization, contact.email].compactMap { $0 }
        return parts.isEmpty ? "—" : parts.joined(separator: "  ·  ").uppercased()
    }
}
