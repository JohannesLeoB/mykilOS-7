import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - FileDropCardView
// Wird in AssistantChatView als Kontext-Karte unterhalb des Composers gezeigt,
// sobald der Nutzer eine Datei in den Chat gedroppt hat.
// Bietet zwei Aktionen:
//   1. „In Drive ablegen" — schlägt einen Ordner vor, lädt nach Bestätigung hoch.
//   2. „Per Mail senden" — hängt die Datei an einen Gmail-ENTWURF an (kein Senden!).
// Beide Pfade sind Bestätigungs-Gates — kein Auto-Write.
public struct FileDropCardView: View {
    let file: DroppedFile
    let suggestedFolderID: String?
    let suggestedFolderName: String?
    let onUploadToDrive: ((DroppedFile) async -> DriveUploadOutcome)?
    let onAttachToMailDraft: ((DroppedFile) async -> DraftCreateOutcome)?
    let onDismiss: () -> Void

    public init(
        file: DroppedFile,
        suggestedFolderID: String? = nil,
        suggestedFolderName: String? = nil,
        onUploadToDrive: ((DroppedFile) async -> DriveUploadOutcome)? = nil,
        onAttachToMailDraft: ((DroppedFile) async -> DraftCreateOutcome)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.file = file
        self.suggestedFolderID = suggestedFolderID
        self.suggestedFolderName = suggestedFolderName
        self.onUploadToDrive = onUploadToDrive
        self.onAttachToMailDraft = onAttachToMailDraft
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            // Header
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "arrow.down.doc")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.drive.color)
                Text("DATEI ABGELEGT")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.drive.color)
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.faint.color)
                }
                .buttonStyle(.plain)
            }

            // Datei-Preview
            FileDropPreviewRow(file: file)

            Divider().overlay(MykColor.line.color)

            // Aktionen
            HStack(spacing: MykSpace.s4) {
                DriveUploadButton(
                    file: file,
                    folderName: suggestedFolderName,
                    onUpload: onUploadToDrive
                )
                MailAttachButton(
                    file: file,
                    onAttach: onAttachToMailDraft
                )
            }
        }
        .padding(.horizontal, MykSpace.s5)
        .padding(.vertical, MykSpace.s4)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.md)
                .fill(MykColor.card.color)
                .overlay(
                    RoundedRectangle(cornerRadius: MykRadius.md)
                        .stroke(MykColor.drive.color.opacity(0.3), lineWidth: 1)
                )
        )
        .frame(maxWidth: 460)
    }
}

// MARK: - FileDropPreviewRow
// Zeigt Dateiname, Typ und Größe — reine Anzeige.
struct FileDropPreviewRow: View {
    let file: DroppedFile

    var body: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: file.iconName)
                .font(.mykHeadline)
                .foregroundStyle(MykColor.drive.color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(file.fileName)
                    .font(.mykBody)
                    .foregroundStyle(MykColor.ink.color)
                    .lineLimit(1)
                Text("\(mimeLabel(file.mimeType)) · \(file.humanSize)")
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.muted.color)
            }
        }
    }

    private func mimeLabel(_ mime: String) -> String {
        switch mime {
        case "application/pdf": return "PDF"
        case "image/jpeg": return "JPEG"
        case "image/png": return "PNG"
        case "image/heic": return "HEIC"
        default:
            if mime.hasPrefix("image/") { return "Bild" }
            if mime.hasPrefix("text/") { return "Text" }
            return mime.components(separatedBy: "/").last?.uppercased() ?? "Datei"
        }
    }
}

// MARK: - DriveUploadButton
// Inline-Button (nicht eigene Karte) mit Phasen: idle → uploading → done / error / permissionRequired.
private struct DriveUploadButton: View {
    let file: DroppedFile
    let folderName: String?
    let onUpload: ((DroppedFile) async -> DriveUploadOutcome)?

    private enum Phase: Equatable {
        case idle, uploading, done(String?), failed(String), permissionRequired
    }
    @State private var phase: Phase = .idle

    var body: some View {
        phaseView
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var phaseView: some View {
        switch phase {
        case .idle:
            Button {
                guard let onUpload else {
                    phase = .failed("Drive-Ablage hier nicht verfügbar.")
                    return
                }
                phase = .uploading
                Task {
                    let outcome = await onUpload(file)
                    switch outcome {
                    case .uploaded(let link):    phase = .done(link)
                    case .failed(let msg):       phase = .failed(msg)
                    case .permissionRequired:    phase = .permissionRequired
                    }
                }
            } label: {
                Label(folderLabel, systemImage: "folder.badge.plus")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.paper.color)
                    .padding(.horizontal, MykSpace.s4)
                    .padding(.vertical, MykSpace.s3)
                    .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.drive.color))
            }
            .buttonStyle(.plain)
            .disabled(onUpload == nil)

        case .uploading:
            HStack(spacing: MykSpace.s2) {
                ProgressView().controlSize(.small)
                Text("Lade hoch …").font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }

        case .done(let link):
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(MykColor.positive.color)
                if let link, let url = URL(string: link) {
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        Text("In Drive ansehen")
                            .font(.mykMono(9.5))
                            .foregroundStyle(MykColor.drive.color)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("In Drive abgelegt")
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.positive.color)
                }
            }

        case .failed(let msg):
            Label(msg, systemImage: "exclamationmark.triangle")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.critical.color)
                .lineLimit(3)

        case .permissionRequired:
            VStack(alignment: .leading, spacing: MykSpace.s2) {
                Label("Drive-Schreibzugriff nötig", systemImage: "lock")
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.tasks.color)
                Text("In Einstellungen → Google → neu verbinden (drive.file-Scope).")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.muted.color)
            }
        }
    }

    private var folderLabel: String {
        if let name = folderName { return "→ \(name)" }
        return "In Drive ablegen"
    }
}

// MARK: - MailAttachButton
// Inline-Button: hängt die Datei an einen Gmail-ENTWURF ohne Betreff/Empfänger an.
// Der App-Layer öffnet dann den Gmail-Entwurf — Versenden ist ein hartes NO-GO.
private struct MailAttachButton: View {
    let file: DroppedFile
    let onAttach: ((DroppedFile) async -> DraftCreateOutcome)?

    private enum Phase: Equatable {
        case idle, attaching, done(String), failed(String)
    }
    @State private var phase: Phase = .idle

    var body: some View {
        phaseView
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var phaseView: some View {
        switch phase {
        case .idle:
            Button {
                guard let onAttach else {
                    phase = .failed("Mail-Ablage hier nicht verfügbar.")
                    return
                }
                phase = .attaching
                Task {
                    let outcome = await onAttach(file)
                    switch outcome {
                    case .created(let info): phase = .done(info)
                    case .failed(let msg):   phase = .failed(msg)
                    }
                }
            } label: {
                Label("Per Mail senden", systemImage: "envelope.badge.plus")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.drive.color)
                    .padding(.horizontal, MykSpace.s4)
                    .padding(.vertical, MykSpace.s3)
                    .background(
                        RoundedRectangle(cornerRadius: MykRadius.sm)
                            .stroke(MykColor.drive.color, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(onAttach == nil)

        case .attaching:
            HStack(spacing: MykSpace.s2) {
                ProgressView().controlSize(.small)
                Text("Entwurf anlegen …").font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }

        case .done(let info):
            Label(info, systemImage: "checkmark.circle.fill")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.positive.color)

        case .failed(let msg):
            Label(msg, systemImage: "exclamationmark.triangle")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.critical.color)
                .lineLimit(3)
        }
    }
}
