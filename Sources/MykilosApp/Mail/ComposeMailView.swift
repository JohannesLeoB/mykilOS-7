import SwiftUI
import UniformTypeIdentifiers
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - ComposeMailView
// Verfassen-UI → GoogleGmailClient.createDraft. KEIN Senden. Nur Entwurf anlegen.
// Anhänge per Finder-Drop (UniformTypeIdentifiers). Empfänger aus Airtable-Kontakten wählbar.
// Kontakt-Quelle: StudioContact aus Airtable Mastermind-Base (appuVMh3KDfKw4OoQ),
// Tabelle „Kontakte" (tblncfQzQa8TzCZQC) — vom App-Layer injiziert, kein direkter
// Airtable-Fetch hier (Widgets-Schicht kennt keinen Netzwerk-Client).
@MainActor
struct ComposeMailView: View {
    let contacts: [StudioContact]
    @Environment(\.dismiss) private var dismiss

    @State private var toField: String = ""
    @State private var subjectField: String = ""
    @State private var bodyText: String = ""
    @State private var attachments: [DraftAttachment] = []
    @State private var phase: ComposePhase = .idle
    @State private var showContactPicker = false
    @State private var isDropTargeted = false

    private enum ComposePhase: Equatable {
        case idle, saving, saved(String), failed(String)
    }

    private var draft: EmailDraft {
        EmailDraft(to: toField.isEmpty ? nil : toField, subject: subjectField, body: bodyText, attachments: attachments)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sheetHeader
            Divider().overlay(MykColor.line.color)
            fieldsArea
            Divider().overlay(MykColor.line.color)
            bodyArea
            Divider().overlay(MykColor.line.color)
            if !attachments.isEmpty { attachmentsList }
            dropZone
            statusBar
        }
        .frame(width: 640, height: 540)
        .background(MykColor.paper.color)
    }

    // MARK: Sheet Header

    private var sheetHeader: some View {
        HStack {
            Button("Abbrechen") { dismiss() }
                .font(.mykSmall)
                .buttonStyle(.plain)
                .foregroundStyle(MykColor.muted.color)
            Spacer()
            Text("Entwurf verfassen")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            Spacer()
            Button {
                Task { await saveDraft() }
            } label: {
                Label("Als Entwurf speichern", systemImage: "tray.and.arrow.down")
                    .font(.mykSmall)
            }
            .buttonStyle(.plain)
            .foregroundStyle(MykColor.personal.color)
            .disabled(subjectField.isEmpty || phase == .saving)
        }
        .padding(.horizontal, MykSpace.s6)
        .padding(.vertical, MykSpace.s4)
    }

    // MARK: Felder

    private var fieldsArea: some View {
        VStack(spacing: 0) {
            fieldRow(label: "An") {
                HStack {
                    TextField("empfaenger@beispiel.de", text: $toField)
                        .font(.mykBody)
                        .textFieldStyle(.plain)
                    if !contacts.isEmpty {
                        Button {
                            showContactPicker = true
                        } label: {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.mykCaption)
                                .foregroundStyle(MykColor.people.color)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showContactPicker) {
                            ContactPickerPopover(contacts: contacts) { contact in
                                if let email = contact.email {
                                    toField = toField.isEmpty ? email : "\(toField), \(email)"
                                }
                                showContactPicker = false
                            }
                        }
                    }
                }
            }
            Divider().overlay(MykColor.line.color.opacity(0.6))
            fieldRow(label: "Betreff") {
                TextField("Betreff", text: $subjectField)
                    .font(.mykBody)
                    .textFieldStyle(.plain)
            }
        }
    }

    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: MykSpace.s4) {
            Text(label)
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
                .frame(width: 60, alignment: .trailing)
            content()
        }
        .padding(.horizontal, MykSpace.s6)
        .padding(.vertical, MykSpace.s4)
    }

    // MARK: Body

    private var bodyArea: some View {
        TextEditor(text: $bodyText)
            .font(.mykBody)
            .foregroundStyle(MykColor.ink.color)
            .scrollContentBackground(.hidden)
            .background(MykColor.paper.color)
            .padding(.horizontal, MykSpace.s6)
            .padding(.vertical, MykSpace.s4)
            .frame(maxHeight: .infinity)
    }

    // MARK: Anhänge

    private var attachmentsList: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            Text("ANHÄNGE (\(attachments.count))")
                .font(.mykMono(9))
                .foregroundStyle(MykColor.muted.color)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MykSpace.s3) {
                    ForEach(attachments.indices, id: \.self) { i in
                        AttachmentChip(attachment: attachments[i]) {
                            attachments.remove(at: i)
                        }
                    }
                }
                .padding(.horizontal, MykSpace.s6)
            }
        }
        .padding(.vertical, MykSpace.s3)
        .background(MykColor.card.color)
    }

    // MARK: Drop-Zone

    private var dropZone: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: "arrow.down.doc")
                .foregroundStyle(isDropTargeted ? MykColor.personal.color : MykColor.faint.color)
            Text("Dateien hier ablegen")
                .font(.mykMono(9.5))
                .foregroundStyle(isDropTargeted ? MykColor.personal.color : MykColor.muted.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MykSpace.s4)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.sm)
                .strokeBorder(
                    isDropTargeted ? MykColor.personal.color : MykColor.line.color,
                    style: StrokeStyle(lineWidth: 1, dash: [4])
                )
        )
        .padding(.horizontal, MykSpace.s6)
        .padding(.vertical, MykSpace.s3)
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    // MARK: Status Bar

    private var statusBar: some View {
        HStack {
            switch phase {
            case .idle:
                Text("GMAIL  ·  NUR ENTWURF — kein Senden")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.faint.color)
            case .saving:
                ProgressView().scaleEffect(0.7)
                Text("Lege Entwurf in Gmail an …")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.muted.color)
            case .saved(let id):
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(MykColor.positive.color)
                Text("Entwurf angelegt (ID: \(id.prefix(8))…)")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.positive.color)
            case .failed(let msg):
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(MykColor.critical.color)
                Text("Fehler: \(msg)")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.critical.color)
            }
            Spacer()
        }
        .padding(.horizontal, MykSpace.s6)
        .padding(.vertical, MykSpace.s4)
    }

    // MARK: - Actions

    private func saveDraft() async {
        phase = .saving
        let client: any GoogleGmailWriting = GoogleGmailClient()
        do {
            let id = try await client.createDraft(draft)
            phase = .saved(id)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                let filename = url.lastPathComponent
                let mimeType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
                if let fileData = try? Data(contentsOf: url) {
                    let att = DraftAttachment(filename: filename, mimeType: mimeType, data: fileData)
                    DispatchQueue.main.async {
                        self.attachments.append(att)
                    }
                }
            }
        }
    }
}

// MARK: - AttachmentChip
private struct AttachmentChip: View {
    let attachment: DraftAttachment
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "paperclip")
                .font(.mykMono(9))
            Text(attachment.filename)
                .font(.mykMono(9.5))
                .lineLimit(1)
            Text("(\(attachment.humanSize))")
                .font(.mykMono(9))
                .foregroundStyle(MykColor.muted.color)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.mykMono(8))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(MykColor.personal.color)
        .padding(.horizontal, MykSpace.s3)
        .padding(.vertical, 4)
        .background(MykColor.personal.color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - ContactPickerPopover
// Zeigt Airtable-StudioContacts mit E-Mail-Adresse. Nur Kontakte mit gesetzter
// E-Mail sind wählbar (sinnlos ohne). Quelle: appuVMh3KDfKw4OoQ/tblncfQzQa8TzCZQC.
private struct ContactPickerPopover: View {
    let contacts: [StudioContact]
    let onSelect: (StudioContact) -> Void
    @State private var filter: String = ""

    private var filtered: [StudioContact] {
        let hasEmail = contacts.filter { $0.email?.isEmpty == false }
        guard !filter.isEmpty else { return hasEmail }
        return hasEmail.filter { $0.matches(filter) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "magnifyingglass")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.muted.color)
                TextField("Suchen …", text: $filter)
                    .font(.mykBody)
                    .textFieldStyle(.plain)
            }
            .padding(MykSpace.s4)
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if filtered.isEmpty {
                        Text("Keine Kontakte mit E-Mail")
                            .font(.mykMono(10))
                            .foregroundStyle(MykColor.muted.color)
                            .padding(MykSpace.s5)
                    }
                    ForEach(filtered) { contact in
                        Button {
                            onSelect(contact)
                        } label: {
                            HStack(spacing: MykSpace.s3) {
                                Image(systemName: "person.crop.circle")
                                    .foregroundStyle(MykColor.people.color)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.name)
                                        .font(.mykSmall)
                                        .foregroundStyle(MykColor.ink.color)
                                    if let email = contact.email {
                                        Text(email)
                                            .font(.mykMono(9.5))
                                            .foregroundStyle(MykColor.muted.color)
                                    }
                                    if let org = contact.organisation {
                                        Text(org)
                                            .font(.mykMono(9))
                                            .foregroundStyle(MykColor.faint.color)
                                    }
                                }
                            }
                            .padding(.horizontal, MykSpace.s4)
                            .padding(.vertical, MykSpace.s3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
        }
        .frame(width: 300, height: 340)
        .background(MykColor.paper.color)
    }
}
