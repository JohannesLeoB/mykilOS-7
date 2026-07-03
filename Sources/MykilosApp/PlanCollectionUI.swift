import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - PlanCollectionUI
// Geteilte UI-Bausteine der Zeichnungs-/Plan-Sammlungsansichten (globaler
// Katalog `AllPlansView` + Projekt-`MaterialTabView`). Setzt den
// „Sammlungs-Ansicht-Standard" um: dieselbe Toolbar-Beschriftung UND dieselbe
// preview-fähige Zeile in beiden Ansichten — ein Bedien-Muster, nicht zwei.

// MARK: Toolbar-Beschriftung (Logik bleibt testbar in MykilosServices)

extension PlanTypeFilter {
    var label: String {
        switch self {
        case .pdf:  "PDF"
        case .bild: "Bilder"
        }
    }
    var icon: String {
        switch self {
        case .pdf:  "doc.text"
        case .bild: "photo"
        }
    }
}

extension MaterialSort {
    var label: String {
        switch self {
        case .datum: "Datum"
        case .name:  "Name"
        }
    }
    var icon: String {
        switch self {
        case .datum: "calendar"
        case .name:  "textformat"
        }
    }
}

// MARK: - PlanFileRow
// Eine preview-fähige Zeile für eine Drive-Datei — dieselbe Mechanik wie
// `OfferRow` in den Angeboten: Icon öffnet die In-App-`FilePreviewView`
// (Popover), der Name öffnet die Datei lokal-zuerst (macOS-Vorschau), sonst
// Browser-Fallback. `contextLine` ist die optionale Kontextzeile vor dem Datum
// (z. B. "Projekt · Nr" im globalen Katalog; im Material-Tab leer).
// Read-only: nie Schreiben, keine Keychain-Daten.
struct PlanFileRow: View {
    let file: GoogleDriveFile
    var contextLine: String? = nil
    /// Drive-Ordner-ID des Projekts — für die lokale Pfadauflösung (Vorschau/Öffnen).
    var projectFolderID: String? = nil

    @State private var showPreview = false
    @State private var resolvedLocalURL: URL?

    // Lokaler Pfad im Projektbaum (xattr-/Namens-Auflösung). `nil` = nicht lokal
    // materialisiert → Remote-PDF-Fallback bzw. Browser greift.
    private func resolveLocalURL() -> URL? {
        guard let projectFolderID, projectFolderID.isEmpty == false else { return nil }
        return LocalDriveRootResolver.shared.localURL(
            forFileID: file.id, fileName: file.name,
            inProjectFolderID: projectFolderID, explicitProjectPath: nil
        )
    }

    // Read-only Remote-Fallback: Datei-Bytes aus Drive (kein Schreiben), damit die
    // Vorschau auch nicht-materialisierte Dateien echt rendert statt Safari zu öffnen.
    private func remoteContent() -> (@Sendable () async -> Data?)? {
        let fileID = file.id
        return { try? await GoogleDriveClient().downloadContent(fileID: fileID) }
    }

    var body: some View {
        HStack(spacing: MykSpace.s4) {
            Button {
                resolvedLocalURL = resolveLocalURL()
                showPreview.toggle()
            } label: {
                Image(systemName: file.iconName)
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.drive.color)
                    .frame(width: 20)
            }
            .buttonStyle(.plain)
            .help("Vorschau")
            .accessibilityLabel("Vorschau von \(file.name)")
            .popover(isPresented: $showPreview, arrowEdge: .trailing) {
                FilePreviewView(file: file, localURL: resolvedLocalURL, remoteContent: remoteContent())
                    .frame(width: 300)
                    .padding(MykSpace.s2)
            }

            Button {
                let local = resolveLocalURL()
                let fallback = file.webViewLink.flatMap { URL(string: $0) }
                LocalDriveRootResolver.shared.openFile(localURL: local, fallbackURL: fallback)
            } label: {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.name)
                            .font(.mykSmall)
                            .foregroundStyle(MykColor.ink.color)
                            .lineLimit(1)
                        HStack(spacing: MykSpace.s3) {
                            if let contextLine {
                                Text(contextLine)
                                    .font(.mykMono(9.5))
                                    .foregroundStyle(MykColor.muted.color)
                            }
                            if let modifiedAt = file.modifiedAt {
                                Text(modifiedAt.formatted(.relative(presentation: .named)))
                                    .font(.mykMono(9.5))
                                    .foregroundStyle(MykColor.faint.color)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.faint.color)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, MykSpace.s3)
        .contextMenu {
            Button("Vorschau") {
                resolvedLocalURL = resolveLocalURL()
                showPreview = true
            }
            Button("Im Finder zeigen") {
                if let local = resolveLocalURL() {
                    LocalDriveRootResolver.shared.revealInFinder(localURL: local)
                } else if let link = file.webViewLink, let url = URL(string: link) {
                    NSWorkspace.shared.open(url)
                }
            }
            if let link = file.webViewLink, let url = URL(string: link) {
                Button("Im Browser öffnen") { NSWorkspace.shared.open(url) }
            }
        }
    }
}
