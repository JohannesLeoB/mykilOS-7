import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - MailAttachmentDriveSheet
// Teil B (Johannes-Wunsch 2026-07-02): einen Mail-Anhang per BESTÄTIGTER Aktion in einen
// Drive-Projektordner ablegen. Muster: Karte → Bestätigung → Audit.
//
// Ablauf:
//   1. Anhang-Bytes read-only über GoogleGmailClient.downloadAttachment laden (Gmail-Scope).
//   2. Projekt wählen (nur Projekte mit verknüpftem Drive-Ordner).
//   3. Zielordner (Projektordner oder Unterordner) über die geteilte FileDropCardView wählen
//      und den Upload BESTÄTIGEN → appState.uploadFileToDrive schreibt den AuditEntry(.driveFileUploaded).
//
// NIE automatisch: ohne Projektwahl und ohne Klick auf „In Drive" wird nichts geschrieben.
// Upload braucht drive.file (M1) — fehlt der Scope, meldet die Karte „Drive-Schreibzugriff nötig".
@MainActor
struct MailAttachmentDriveSheet: View {
    let messageID: String
    let attachment: GmailAttachment
    /// Projekte für den Zielordner-Picker (i. d. R. appState.registry.projects).
    let projects: [Project]
    /// Read-only Unterordner-Auflösung (appState.listDriveSubfolders).
    let loadSubfolders: (String) async -> [DriveFolderChoice]
    /// Bestätigter Upload (appState.uploadFileToDrive) — schreibt Audit + dataFlow.
    let uploadToDrive: (DroppedFile, String) async -> DriveUploadOutcome
    let onClose: () -> Void
    /// Ordner-Schema-Konnektoren fürs Marker→Slot-Vorschlagen (appState.nomenklatur.konnektoren).
    /// Leer, solange kein Nomenklatur-Store übergeben wird — dann bleibt die Marker-Zeile aus.
    var konnektoren: [OrdnerSlot: OrdnerKonnektor] = [:]

    private enum LoadPhase: Equatable {
        case loading
        case ready(DroppedFile)
        case failed(String)
    }
    @State private var phase: LoadPhase = .loading
    @State private var selectedProject: Project?

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            header
            Divider().overlay(MykColor.line.color)
            projektPicker
            content
        }
        .padding(MykSpace.s6)
        .frame(width: 520)
        .background(MykColor.paper.color)
        .task(id: attachment.attachmentID) { await loadBytes() }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: "folder.badge.plus")
                .font(.mykHeadline).foregroundStyle(MykColor.drive.color)
            VStack(alignment: .leading, spacing: 1) {
                Text("Anhang in Drive-Projekt ablegen")
                    .font(.mykHeadline).foregroundStyle(MykColor.ink.color)
                Text(attachment.filename)
                    .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color).lineLimit(1)
            }
            Spacer()
            Button { onClose() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.mykHeadline).foregroundStyle(MykColor.faint.color)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Schließen")
        }
    }

    // MARK: Projekt-Picker (nur Projekte mit Drive-Ordner)

    private var projekteMitOrdner: [Project] {
        projects
            .filter { ($0.links.driveFolderID?.isEmpty == false) }
            .sorted { $0.projectNumber > $1.projectNumber }
    }

    private var projektPicker: some View {
        HStack(spacing: MykSpace.s2) {
            Image(systemName: "square.grid.2x2")
                .font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
            Text("Projekt").font(.mykMono(9.5)).foregroundStyle(MykColor.faint.color)
            Menu {
                if projekteMitOrdner.isEmpty {
                    Text("Kein Projekt mit Drive-Ordner")
                }
                ForEach(projekteMitOrdner) { project in
                    Button {
                        selectedProject = project
                    } label: {
                        if selectedProject?.id == project.id {
                            Label("\(project.projectNumber) · \(project.title)", systemImage: "checkmark")
                        } else {
                            Text("\(project.projectNumber) · \(project.title)")
                        }
                    }
                }
            } label: {
                HStack(spacing: MykSpace.s2) {
                    Text(selectedProject.map { "\($0.projectNumber) · \($0.title)" } ?? "Projekt wählen …")
                        .font(.mykMono(10)).foregroundStyle(MykColor.drive.color).lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.mykMono(8)).foregroundStyle(MykColor.muted.color)
                }
                .padding(.horizontal, MykSpace.s3).padding(.vertical, MykSpace.s2)
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
            }
            .menuStyle(.borderlessButton).fixedSize()
            Spacer()
        }
    }

    // MARK: Inhalt (Lade-/Fehler-/Bereit-Zustand)

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            HStack(spacing: MykSpace.s3) {
                ProgressView().controlSize(.small)
                Text("Anhang wird geladen …").font(.mykSmall).foregroundStyle(MykColor.muted.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, MykSpace.s4)

        case .failed(let msg):
            VStack(alignment: .leading, spacing: MykSpace.s3) {
                Label(msg, systemImage: "exclamationmark.triangle")
                    .font(.mykSmall).foregroundStyle(MykColor.critical.color)
                Button("Erneut laden") { Task { await loadBytes() } }
                    .font(.mykSmall).foregroundStyle(MykColor.drive.color).buttonStyle(.plain)
            }
            .padding(.vertical, MykSpace.s3)

        case .ready(let file):
            if let project = selectedProject, let folderID = project.links.driveFolderID {
                // Geteilte Ablage-Karte (Ordner/Unterordner-Picker + Bestätigungs-Upload + Audit).
                // .id(project.id) erzwingt bei Projektwechsel eine frische Karte (Ziel-State reset).
                FileDropCardView(
                    files: [file],
                    rootFolder: DriveFolderChoice(id: folderID, name: project.title),
                    loadSubfolders: loadSubfolders,
                    onUploadToDrive: uploadToDrive,
                    onAttachToMailDraft: nil,
                    onDismiss: { onClose() },
                    konnektoren: konnektoren
                )
                .id(project.id)
            } else {
                Text("Projekt wählen, um die Datei abzulegen.")
                    .font(.mykSmall).foregroundStyle(MykColor.muted.color)
                    .padding(.vertical, MykSpace.s4)
            }
        }
    }

    // MARK: Laden (read-only)

    private func loadBytes() async {
        phase = .loading
        do {
            let data = try await GoogleGmailClient().downloadAttachment(
                messageID: messageID, attachmentID: attachment.attachmentID)
            guard data.isEmpty == false else {
                phase = .failed("Anhang ist leer oder konnte nicht geladen werden.")
                return
            }
            phase = .ready(DroppedFile(fileName: attachment.filename, mimeType: attachment.mimeType, data: data))
        } catch GoogleGmailError.notConnected {
            phase = .failed("Google nicht verbunden. Bitte in den Einstellungen verbinden.")
        } catch {
            phase = .failed("Laden fehlgeschlagen: \(error.localizedDescription)")
        }
    }
}
