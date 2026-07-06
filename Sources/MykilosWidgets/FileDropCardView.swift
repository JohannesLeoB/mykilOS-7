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
    let rootFolder: DriveFolderChoice?
    let loadSubfolders: ((String) async -> [DriveFolderChoice])?
    let onUploadToDrive: ((DroppedFile, String) async -> DriveUploadOutcome)?
    let onAttachToMailDraft: (([DroppedFile]) async -> DraftCreateOutcome)?
    let onRemove: (DroppedFile) -> Void
    let onDismiss: () -> Void
    /// Ordner-Schema-Konnektoren fürs Marker→Slot-Vorschlagen (Ordner-Schema-Editor-Plan,
    /// "Mail-Anhang → Marker → Unterordner"). Leer (Default) → keine Marker-Zeile, unverändertes
    /// Verhalten für alle bestehenden Aufrufer (z. B. AssistantChatView).
    let konnektoren: [OrdnerSlot: OrdnerKonnektor]
    let markerRoutes: MailMarkerRouteRegistry

    // Ziel-Ordner-Auswahl: default = Projektordner-Wurzel; Unterordner werden lazy geladen.
    @State private var target: DriveFolderChoice?
    // Navigations-Pfad zum Reinklicken in Unterordner (Ordner-Schema-Editor-Plan, "Mail-Anhang
    // → Marker → Unterordner"): leer = auf der Wurzel; jede Ebene wird erst beim Betreten geladen
    // (lazy, ein API-Ruf pro Navigationsschritt — kein eifriges Vorabladen des ganzen Baums).
    @State private var browsePfad: [DriveFolderChoice] = []
    @State private var browseChildren: [DriveFolderChoice] = []
    @State private var selectedMarker: MailAnhangMarker?

    public init(
        files: [DroppedFile],
        rootFolder: DriveFolderChoice? = nil,
        loadSubfolders: ((String) async -> [DriveFolderChoice])? = nil,
        onUploadToDrive: ((DroppedFile, String) async -> DriveUploadOutcome)? = nil,
        onAttachToMailDraft: (([DroppedFile]) async -> DraftCreateOutcome)? = nil,
        onRemove: @escaping (DroppedFile) -> Void = { _ in },
        onDismiss: @escaping () -> Void,
        konnektoren: [OrdnerSlot: OrdnerKonnektor] = [:],
        markerRoutes: MailMarkerRouteRegistry = .default
    ) {
        self.files = files
        self.rootFolder = rootFolder
        self.loadSubfolders = loadSubfolders
        self.onUploadToDrive = onUploadToDrive
        self.onAttachToMailDraft = onAttachToMailDraft
        self.onRemove = onRemove
        self.onDismiss = onDismiss
        self.konnektoren = konnektoren
        self.markerRoutes = markerRoutes
        _target = State(initialValue: rootFolder)
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

            markerPicker

            // Ziel-Ordner-Auswahl (nur wenn ein Projektordner bekannt ist).
            if rootFolder != nil {
                zielOrdnerPicker
            }

            Divider().overlay(MykColor.line.color)

            HStack(spacing: MykSpace.s4) {
                DriveUploadAllButton(
                    files: files,
                    folderName: target?.name,
                    targetFolderID: target?.id ?? rootFolder?.id,
                    onUpload: onUploadToDrive
                )
                // Mail-Entwurf-Aktion nur zeigen, wenn ein Callback existiert. So kann die
                // Karte auch dort wiederverwendet werden, wo NUR die Drive-Ablage sinnvoll
                // ist (z. B. Mail-Anhang → Drive-Projektordner) — ohne toten Button.
                if onAttachToMailDraft != nil {
                    MailAttachAllButton(files: files, onAttach: onAttachToMailDraft)
                }
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
        .task(id: browseFolder?.id) {
            // Nur die AKTUELL durchsuchte Ebene laden (read-only, ein Ruf pro Navigationsschritt).
            guard let folder = browseFolder, let loader = loadSubfolders else { browseChildren = []; return }
            browseChildren = await loader(folder.id)
        }
    }

    /// Der Ordner, dessen Inhalt gerade im Picker angezeigt wird (Wurzel, falls noch nicht reingeklickt).
    private var browseFolder: DriveFolderChoice? { browsePfad.last ?? rootFolder }

    // Marker → Ziel-Slot (Vorschlag, kein Auto-Move) — ausgelagert in FileDropMarkerPicker.swift.
    private var markerPicker: some View {
        FileDropMarkerPicker(
            konnektoren: konnektoren,
            markerRoutes: markerRoutes,
            rootFolder: rootFolder,
            browseChildren: browseChildren,
            selectedMarker: $selectedMarker,
            onResolvedTarget: { target = $0 }
        )
    }

    // Ziel-Ordner-Menü: Finder-artiges Reinklicken. Jede Zeile im gerade durchsuchten Ordner
    // navigiert EINE Ebene tiefer (lazy nachgeladen); "Diesen Ordner wählen" markiert die
    // aktuell durchsuchte Ebene als Ablageziel — Auswahl und Navigation sind bewusst getrennt,
    // damit ein Klick auf einen Unterordner nie versehentlich das Ziel ändert.
    private var zielOrdnerPicker: some View {
        HStack(spacing: MykSpace.s2) {
            Image(systemName: "folder")
                .font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
            Text("Ziel").font(.mykMono(9.5)).foregroundStyle(MykColor.faint.color)
            Menu {
                if let folder = browseFolder {
                    Button {
                        target = folder
                    } label: {
                        if target?.id == folder.id {
                            Label("Diesen Ordner wählen: \(folder.name)", systemImage: "checkmark")
                        } else {
                            Text("Diesen Ordner wählen: \(folder.name)")
                        }
                    }
                }
                if browsePfad.isEmpty == false {
                    Button {
                        browsePfad.removeLast()
                    } label: {
                        Label("Zurück", systemImage: "arrow.up.left")
                    }
                }
                if browseChildren.isEmpty == false {
                    Divider()
                    ForEach(browseChildren) { folder in
                        Button {
                            browsePfad.append(folder)
                        } label: {
                            Label(folder.name, systemImage: "folder")
                        }
                    }
                }
            } label: {
                HStack(spacing: MykSpace.s2) {
                    Text(target?.name ?? rootFolder?.name ?? "Projektordner")
                        .font(.mykMono(10)).foregroundStyle(MykColor.drive.color).lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.mykMono(8)).foregroundStyle(MykColor.muted.color)
                }
                .padding(.horizontal, MykSpace.s3)
                .padding(.vertical, MykSpace.s2)
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            if browsePfad.isEmpty == false {
                Text(browsePfad.map(\.name).joined(separator: " / "))
                    .font(.mykMono(9)).foregroundStyle(MykColor.faint.color).lineLimit(1)
            }
            Spacer()
        }
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
    let targetFolderID: String?
    let onUpload: ((DroppedFile, String) async -> DriveUploadOutcome)?

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
                guard let targetFolderID, !targetFolderID.isEmpty else {
                    phase = .failed("Kein Ziel-Ordner gewählt."); return
                }
                Task {
                    var ok = 0
                    for (i, file) in files.enumerated() {
                        phase = .uploading(i + 1, files.count)
                        switch await onUpload(file, targetFolderID) {
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
