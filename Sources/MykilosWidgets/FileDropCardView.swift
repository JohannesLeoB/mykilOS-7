import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - FileDropCardView
// Kontext-Karte unterhalb des Composers, sobald Dateien in den Chat gedroppt wurden.
// 2026-07-02: sammelt MEHRERE Dateien (auch aus gedropten Ordnern; ZIPs bleiben als
// eine Datei). Zwei Sammelaktionen:
//   1. „Alle in Drive ablegen" — lädt jede Datei in den vorgeschlagenen Ordner hoch.
//   2. „Alle an Mail-Entwurf" — hängt ALLE Dateien an EINEN Gmail-ENTWURF an (kein Senden).
// Beide sind Bestätigungs-Gates — kein Auto-Write.
public struct FileDropCardView: View {
    let files: [DroppedFile]
    let suggestedFolderID: String?
    let suggestedFolderName: String?
    let onUploadToDrive: ((DroppedFile) async -> DriveUploadOutcome)?
    let onAttachToMailDraft: (([DroppedFile]) async -> DraftCreateOutcome)?
    let onRemove: (DroppedFile) -> Void
    let onDismiss: () -> Void

    public init(
        files: [DroppedFile],
        suggestedFolderID: String? = nil,
        suggestedFolderName: String? = nil,
        onUploadToDrive: ((DroppedFile) async -> DriveUploadOutcome)? = nil,
        onAttachToMailDraft: (([DroppedFile]) async -> DraftCreateOutcome)? = nil,
        onRemove: @escaping (DroppedFile) -> Void = { _ in },
        onDismiss: @escaping () -> Void
    ) {
        self.files = files
        self.suggestedFolderID = suggestedFolderID
        self.suggestedFolderName = suggestedFolderName
        self.onUploadToDrive = onUploadToDrive
        self.onAttachToMailDraft = onAttachToMailDraft
        self.onRemove = onRemove
        self.onDismiss = onDismiss
    }

    private var gesamtBytes: Int { files.reduce(0) { $0 + $1.data.count } }
    private var gesamtGroesse: String {
        ByteCountFormatter.string(fromByteCount: Int64(gesamtBytes), countStyle: .file)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "arrow.down.doc")
                    .font(.mykCaption).foregroundStyle(MykColor.drive.color)
                Text(files.count == 1 ? "DATEI ABGELEGT" : "\(files.count) DATEIEN · \(gesamtGroesse)")
                    .font(.mykMono(10)).foregroundStyle(MykColor.drive.color)
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark").font(.mykMono(9.5)).foregroundStyle(MykColor.faint.color)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Alle abgelegten Dateien verwerfen")
            }

            // Datei-Liste mit Einzel-Entfernen (bei mehr als einer Datei).
            VStack(spacing: MykSpace.s2) {
                ForEach(files) { file in
                    HStack(spacing: MykSpace.s3) {
                        FileDropPreviewRow(file: file)
                        Spacer(minLength: 0)
                        if files.count > 1 {
                            Button { onRemove(file) } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.mykMono(11)).foregroundStyle(MykColor.faint.color)
                            }
                            .buttonStyle(.plain)
                            .help("Diese Datei entfernen")
                            .accessibilityLabel("\(file.fileName) entfernen")
                        }
                    }
                }
            }

            Divider().overlay(MykColor.line.color)

            HStack(spacing: MykSpace.s4) {
                DriveUploadAllButton(files: files, folderName: suggestedFolderName, onUpload: onUploadToDrive)
                MailAttachAllButton(files: files, onAttach: onAttachToMailDraft)
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

// MARK: - FileDropPreviewRow (Anzeige einer Datei)
struct FileDropPreviewRow: View {
    let file: DroppedFile

    var body: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: file.iconName)
                .font(.mykHeadline).foregroundStyle(MykColor.drive.color).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(file.fileName).font(.mykBody).foregroundStyle(MykColor.ink.color).lineLimit(1)
                Text("\(mimeLabel(file.mimeType)) · \(file.humanSize)")
                    .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
        }
    }

    private func mimeLabel(_ mime: String) -> String {
        switch mime {
        case "application/pdf": return "PDF"
        case "image/jpeg": return "JPEG"
        case "image/png": return "PNG"
        case "image/heic": return "HEIC"
        case "application/zip", "application/x-zip-compressed": return "ZIP"
        default:
            if mime.hasPrefix("image/") { return "Bild" }
            if mime.hasPrefix("text/") { return "Text" }
            return mime.components(separatedBy: "/").last?.uppercased() ?? "Datei"
        }
    }
}

// MARK: - DriveUploadAllButton
// Lädt alle Dateien nacheinander in den vorgeschlagenen Ordner (loopt den Einzel-Callback).
private struct DriveUploadAllButton: View {
    let files: [DroppedFile]
    let folderName: String?
    let onUpload: ((DroppedFile) async -> DriveUploadOutcome)?

    private enum Phase: Equatable { case idle, uploading(Int, Int), done(Int), failed(String), permissionRequired }
    @State private var phase: Phase = .idle

    var body: some View {
        phaseView.frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var phaseView: some View {
        switch phase {
        case .idle:
            Button {
                guard let onUpload else { phase = .failed("Drive-Ablage hier nicht verfügbar."); return }
                Task {
                    var ok = 0
                    for (i, file) in files.enumerated() {
                        phase = .uploading(i + 1, files.count)
                        switch await onUpload(file) {
                        case .uploaded:           ok += 1
                        case .permissionRequired: phase = .permissionRequired; return
                        case .failed(let msg):    phase = .failed(msg); return
                        }
                    }
                    phase = .done(ok)
                }
            } label: {
                Label(folderLabel, systemImage: "folder.badge.plus")
                    .font(.mykMono(10)).foregroundStyle(MykColor.paper.color)
                    .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s3)
                    .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.drive.color))
            }
            .buttonStyle(.plain).disabled(onUpload == nil)

        case .uploading(let i, let n):
            HStack(spacing: MykSpace.s2) {
                ProgressView().controlSize(.small)
                Text("Lade hoch … \(i)/\(n)").font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }

        case .done(let n):
            Label(n == 1 ? "In Drive abgelegt" : "\(n) in Drive abgelegt", systemImage: "checkmark.circle.fill")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.positive.color)

        case .failed(let msg):
            Label(msg, systemImage: "exclamationmark.triangle")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.critical.color).lineLimit(3)

        case .permissionRequired:
            VStack(alignment: .leading, spacing: MykSpace.s2) {
                Label("Drive-Schreibzugriff nötig", systemImage: "lock")
                    .font(.mykMono(9.5)).foregroundStyle(MykColor.tasks.color)
                Text("In Einstellungen → Verbindungen → Google neu verbinden (drive.file-Scope).")
                    .font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
            }
        }
    }

    private var folderLabel: String {
        let prefix = files.count > 1 ? "Alle" : "In Drive"
        if let name = folderName { return "\(prefix) → \(name)" }
        return files.count > 1 ? "Alle in Drive ablegen" : "In Drive ablegen"
    }
}

// MARK: - MailAttachAllButton
// Hängt ALLE Dateien an EINEN Gmail-ENTWURF an (kein Senden). Array-Callback.
private struct MailAttachAllButton: View {
    let files: [DroppedFile]
    let onAttach: (([DroppedFile]) async -> DraftCreateOutcome)?

    private enum Phase: Equatable { case idle, attaching, done(String), failed(String) }
    @State private var phase: Phase = .idle

    var body: some View {
        phaseView.frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var phaseView: some View {
        switch phase {
        case .idle:
            Button {
                guard let onAttach else { phase = .failed("Mail-Ablage hier nicht verfügbar."); return }
                phase = .attaching
                Task {
                    switch await onAttach(files) {
                    case .created(let info): phase = .done(info)
                    case .failed(let msg):   phase = .failed(msg)
                    }
                }
            } label: {
                Label(files.count > 1 ? "Alle an Mail-Entwurf" : "Per Mail senden", systemImage: "envelope.badge.plus")
                    .font(.mykMono(10)).foregroundStyle(MykColor.drive.color)
                    .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s3)
                    .background(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.drive.color, lineWidth: 1))
            }
            .buttonStyle(.plain).disabled(onAttach == nil)

        case .attaching:
            HStack(spacing: MykSpace.s2) {
                ProgressView().controlSize(.small)
                Text("Entwurf anlegen …").font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }

        case .done(let info):
            Label(info, systemImage: "checkmark.circle.fill")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.positive.color)

        case .failed(let msg):
            Label(msg, systemImage: "exclamationmark.triangle")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.critical.color).lineLimit(3)
        }
    }
}
