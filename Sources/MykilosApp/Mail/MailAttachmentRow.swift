import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - AttachmentRow
// Anhänge sind klickbar: Klick auf die Zeile öffnet die In-App-Vorschau (derselbe geteilte
// DocumentViewerView wie „Dateien"/„Angebote": PDF/Bild/QuickLook). Der „In Drive"-Knopf legt
// den Anhang per Bestätigungs-Gate in einen Drive-Projektordner. Beide laden die Bytes read-only
// über GoogleGmailClient.downloadAttachment (Gmail-Scope reicht — kein drive.readonly nötig).
struct AttachmentRow: View {
    @Environment(AppState.self) private var appState

    let messageID: String
    let attachment: GmailAttachment

    @State private var showPreview = false
    @State private var showDriveSheet = false

    var body: some View {
        HStack(spacing: MykSpace.s3) {
            // Klickbarer Hauptbereich → In-App-Vorschau.
            Button { showPreview = true } label: {
                HStack(spacing: MykSpace.s3) {
                    Image(systemName: iconName(for: attachment.mimeType))
                        .foregroundStyle(MykColor.personal.color)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(attachment.filename)
                            .font(.mykSmall)
                            .foregroundStyle(MykColor.ink.color)
                            .lineLimit(1)
                        Text(humanSize(attachment.sizeBytes))
                            .font(.mykMono(9))
                            .foregroundStyle(MykColor.muted.color)
                    }
                    Spacer(minLength: MykSpace.s3)
                    Image(systemName: "eye")
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.muted.color)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Vorschau öffnen")
            .accessibilityLabel("\(attachment.filename) — Vorschau öffnen")

            // In Drive-Projektordner ablegen (Bestätigungs-Gate, kein Auto-Write).
            Button { showDriveSheet = true } label: {
                Image(systemName: "folder.badge.plus")
                    .font(.mykMono(12))
                    .foregroundStyle(MykColor.drive.color)
                    .padding(.horizontal, MykSpace.s2)
                    .padding(.vertical, MykSpace.s2)
                    .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.drive.color.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("In Drive-Projektordner ablegen")
            .accessibilityLabel("\(attachment.filename) in Drive ablegen")
        }
        .padding(MykSpace.s4)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
        .sheet(isPresented: $showPreview) {
            DocumentViewerView(
                file: driveFileForPreview,
                remoteContent: remoteContent(),
                onClose: { showPreview = false }
            )
            .frame(minWidth: 820, minHeight: 680)
        }
        .sheet(isPresented: $showDriveSheet) {
            MailAttachmentDriveSheet(
                messageID: messageID,
                attachment: attachment,
                projects: appState.registry.projects,
                loadSubfolders: { await appState.listDriveSubfolders(parentFolderID: $0) },
                uploadToDrive: { await appState.uploadFileToDrive($0, parentFolderID: $1) },
                onClose: { showDriveSheet = false }
            )
        }
    }

    /// Synthetischer GoogleDriveFile (nur Metadaten) für den geteilten DocumentViewerView.
    /// Kein Drive-Objekt — der Viewer klassifiziert nur nach MIME-Typ und lädt die Bytes
    /// über `remoteContent`.
    private var driveFileForPreview: GoogleDriveFile {
        GoogleDriveFile(
            id: "gmail-\(messageID)-\(attachment.attachmentID)",
            name: attachment.filename,
            mimeType: attachment.mimeType,
            modifiedAt: nil,
            webViewLink: nil,
            fileSize: Int64(attachment.sizeBytes)
        )
    }

    /// Read-only Anhang-Bytes über die Gmail-API (kein drive.readonly nötig).
    private func remoteContent() -> (@Sendable () async -> Data?)? {
        let msgID = messageID
        let attID = attachment.attachmentID
        return { try? await GoogleGmailClient().downloadAttachment(messageID: msgID, attachmentID: attID) }
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
