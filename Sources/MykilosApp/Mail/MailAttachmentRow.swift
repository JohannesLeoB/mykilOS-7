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
    /// Alle Anhänge derselben Nachricht — ermöglicht ←/→ + Leertaste-Blättern im Viewer.
    /// Leer = nur dieser eine Anhang (Rückwärtskompatibilität).
    var siblings: [GmailAttachment] = []

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
            let msgID = messageID
            let atts = siblings.isEmpty ? [attachment] : siblings
            let items = atts.map { att -> DocumentViewerItem in
                let attID = att.attachmentID
                // Read-only Anhang-Bytes über die Gmail-API; Closure fängt nur lokale
                // Sendable-Werte (msgID/attID), nicht self → echt @Sendable.
                return DocumentViewerItem(
                    file: driveFile(for: att), localURL: nil,
                    remoteContent: { try? await GoogleGmailClient().downloadAttachment(messageID: msgID, attachmentID: attID) })
            }
            let startIndex = atts.firstIndex(where: { $0.attachmentID == attachment.attachmentID }) ?? 0
            DocumentViewerView(items: items, initialIndex: startIndex, onClose: { showPreview = false })
                .frame(minWidth: 820, minHeight: 680)
        }
        .sheet(isPresented: $showDriveSheet) {
            MailAttachmentDriveSheet(
                messageID: messageID,
                attachment: attachment,
                projects: appState.registry.projects,
                loadSubfolders: { await appState.listDriveSubfolders(parentFolderID: $0) },
                uploadToDrive: { await appState.uploadFileToDrive($0, parentFolderID: $1) },
                onClose: { showDriveSheet = false },
                konnektoren: appState.nomenklatur.konnektoren
            )
        }
    }

    /// Synthetischer GoogleDriveFile (nur Metadaten) für den geteilten DocumentViewerView.
    /// Kein Drive-Objekt — der Viewer klassifiziert nur nach MIME-Typ und lädt die Bytes
    /// über `remoteContent`.
    private func driveFile(for att: GmailAttachment) -> GoogleDriveFile {
        GoogleDriveFile(
            id: "gmail-\(messageID)-\(att.attachmentID)",
            name: att.filename,
            mimeType: att.mimeType,
            modifiedAt: nil,
            webViewLink: nil,
            fileSize: Int64(att.sizeBytes)
        )
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
