import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - OffersTabView (Post-Akt 5, Aufgabe 10)
// Die „Angebote"-Tab der Projekt-Detailseite. Bisher nur ein „in Vorbereitung"-
// Platzhalter; zeigt jetzt die Angebots-/Rechnungs-PDFs aus dem verlinkten
// Drive-Ordner. Erkannt wird mit derselben Logik, die der `DriveOfferWatcher`
// fürs `offerDetected`-Signal nutzt (`DriveOfferWatcher.detectOffers`) — eine
// Quelle der Wahrheit, keine zweite Heuristik in der UI.
//
// Read-only: nur Metadaten + Link zum Öffnen im Browser, nie Schreiben. Alle
// Renderstates über den geteilten `WidgetContainer`; Quelle bleibt sichtbar.
struct OffersTabView: View {
    let projectID: String
    let driveFolderID: String?

    @State private var loader = OffersLoader()

    var body: some View {
        WidgetContainer(
            kind: .drive,
            sourceLabel: sourceLabel,
            renderState: loader.renderState,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                header
                offerList
            }
        }
        .task(id: driveFolderID) {
            await loader.load(folderID: driveFolderID)
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.top, MykSpace.s7)
        .padding(.bottom, 64)   // Platz für SaveStateBar
    }

    private var sourceLabel: String {
        switch loader.renderState {
        case .content: "GOOGLE DRIVE  ·  \(loader.offers.count) BELEGE"
        default:       "GOOGLE DRIVE"
        }
    }

    private var header: some View {
        HStack {
            SourceChip(kind: .drive)
            Text("Angebote & Rechnungen").mykWidgetTitle()
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
            Task { await loader.load(folderID: driveFolderID) }
        }
        .font(.mykMono(9.5))
        .buttonStyle(.plain)
        .foregroundStyle(MykColor.drive.color)
    }

    private var offerList: some View {
        VStack(spacing: 0) {
            ForEach(loader.offers) { file in
                OfferRow(file: file)
                if file.id != loader.offers.last?.id {
                    Divider().overlay(MykColor.line.color.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - OffersLoader
// Pro Tab-Instanz, reiner Lesefetch. Holt den ganzen Ordner über den
// bestehenden read-only `GoogleDriveClient` und filtert auf Belege.
@MainActor
@Observable
private final class OffersLoader {
    private(set) var offers: [GoogleDriveFile] = []
    private(set) var renderState: WidgetRenderState = .loading

    private let client: GoogleDriveFetching

    init(client: GoogleDriveFetching = GoogleDriveClient()) {
        self.client = client
    }

    func load(folderID: String?) async {
        guard let folderID, folderID.isEmpty == false else {
            offers = []
            renderState = .empty
            return
        }
        renderState = .loading
        do {
            let files = try await client.listFolder(folderID: folderID)
            offers = DriveOfferWatcher.detectOffers(in: files)
            renderState = offers.isEmpty ? .empty : .content
        } catch GoogleDriveError.notConnected {
            offers = []
            renderState = .permissionRequired
        } catch {
            offers = []
            renderState = .error(String(describing: error))
        }
    }
}

// MARK: - OfferRow
private struct OfferRow: View {
    let file: GoogleDriveFile

    var body: some View {
        Button {
            if let link = file.webViewLink, let url = URL(string: link) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: MykSpace.s4) {
                Image(systemName: "doc.text")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.cash.color)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.ink.color)
                        .lineLimit(1)
                    if let modifiedAt = file.modifiedAt {
                        Text(modifiedAt.formatted(.relative(presentation: .named)))
                            .font(.mykMono(9.5))
                            .foregroundStyle(MykColor.muted.color)
                    }
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.faint.color)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, MykSpace.s3)
    }
}
