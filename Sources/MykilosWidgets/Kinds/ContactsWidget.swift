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
    /// Klick auf eine Mail-Adresse (2026-07-04) — der App-Layer öffnet ComposeMailView mit
    /// vorausgefülltem Empfänger. `nil` = Klick tut nichts (Callback nicht injiziert).
    public var onMailContact: ((String) -> Void)? = nil

    public init(projectID: String, contactsQuery: String?, onMailContact: ((String) -> Void)? = nil) {
        self.projectID = projectID
        self.contactsQuery = contactsQuery
        self.onMailContact = onMailContact
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
                ContactRow(contact: contact, onMailContact: onMailContact)
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
    // Generation-Token: nur das jüngste load() committet (Projektwechsel/Retry).
    private var loadGeneration = 0

    init(client: GoogleContactsFetching = GoogleContactsClient()) {
        self.client = client
    }

    func load(query: String?) async {
        loadGeneration &+= 1
        let generation = loadGeneration
        guard let query, query.isEmpty == false else {
            contacts = []
            renderState = .empty
            return
        }
        renderState = .loading
        do {
            let result = try await client.searchContacts(query: query)
            guard generation == loadGeneration else { return }
            contacts = result
            renderState = result.isEmpty ? .empty : .content
        } catch GoogleContactsError.notConnected {
            guard generation == loadGeneration else { return }
            contacts = []
            renderState = .permissionRequired
        } catch {
            guard generation == loadGeneration else { return }
            contacts = []
            renderState = .error(String(describing: error))
        }
    }
}

// MARK: - ContactRow
private struct ContactRow: View {
    let contact: GoogleContact
    var onMailContact: ((String) -> Void)? = nil
    @State private var isHoveredOnEmail = false

    var body: some View {
        HStack(spacing: MykSpace.s4) {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [MykColor.people.color, MykColor.people.color.opacity(0.7)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 36, height: 36)
                .overlay(Text(initials).font(.mykMono(11)).foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.displayName).font(.mykSmall).foregroundStyle(MykColor.ink.color)
                subtitleView
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

    // Mail-Adresse klickbar (2026-07-04): eigenes Element statt Teil eines Textstrings,
    // damit sie einzeln antippbar ist. Organisation bleibt Klartext daneben.
    @ViewBuilder
    private var subtitleView: some View {
        HStack(spacing: 4) {
            if let org = contact.organization {
                Text(org.uppercased()).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
            if let email = contact.email {
                if contact.organization != nil {
                    Text("·").font(.mykMono(9.5)).foregroundStyle(MykColor.faint.color)
                }
                if let onMailContact {
                    Button { onMailContact(email) } label: {
                        Text(email.uppercased())
                            .font(.mykMono(9.5))
                            .foregroundStyle(MykColor.people.color)
                            .underline(isHoveredOnEmail)
                    }
                    .buttonStyle(.plain)
                    .onHover { isHoveredOnEmail = $0 }
                    .help("Mail schreiben")
                } else {
                    Text(email.uppercased()).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                }
            }
            if contact.organization == nil && contact.email == nil {
                Text("—").font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
        }
    }
}
