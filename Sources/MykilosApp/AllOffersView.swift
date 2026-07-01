import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - AllOffersLoader (S23)
// Dünner @Observable-Wrapper um die testbare `AllOffersCollector`-Logik (Services).
// Hält nur UI-Belange: Render-State, Generations-Guard, Lade-Fortschritt.
@MainActor
@Observable
final class AllOffersLoader {
    private(set) var offers: [AllOffersCollector.AggregatedOffer] = []
    private(set) var renderState: WidgetRenderState = .loading
    private(set) var projectsScanned = 0
    private(set) var projectsTotal = 0
    private(set) var projectsFailed = 0

    private let client: GoogleDriveFetching
    private var generation = 0

    init(client: GoogleDriveFetching = GoogleDriveClient()) {
        self.client = client
    }

    func load(projects: [AllOffersCollector.ProjectRef]) async {
        generation &+= 1
        let gen = generation
        projectsScanned = 0
        projectsTotal = projects.count
        projectsFailed = 0
        guard projects.isEmpty == false else {
            offers = []; renderState = .empty
            return
        }
        renderState = .loading
        do {
            let outcome = try await AllOffersCollector.collectAll(
                projects: projects, client: client,
                onProgress: { [weak self] done, total in
                    Task { @MainActor [weak self] in
                        guard let self, gen == self.generation else { return }
                        self.projectsScanned = done
                        self.projectsTotal = total
                    }
                })
            guard gen == generation else { return }
            offers = outcome.offers
            projectsFailed = outcome.projectsFailed
            projectsScanned = outcome.projectsScanned
            renderState = offers.isEmpty ? .empty : .content
        } catch GoogleDriveError.notConnected {
            guard gen == generation else { return }
            offers = []; renderState = .permissionRequired
        } catch {
            guard gen == generation else { return }
            offers = []; renderState = .error(String(describing: error))
        }
    }
}

// MARK: - AllOffersSort UI-Beschriftung (Logik testbar in MykilosServices.AllOffersSorter)
extension AllOffersSort {
    var label: String {
        switch self {
        case .datum:    "Datum"
        case .projekt:  "Projekt"
        case .richtung: "Richtung"
        case .typ:      "Typ"
        case .name:     "Name"
        }
    }
    var icon: String {
        switch self {
        case .datum:    "calendar"
        case .projekt:  "folder"
        case .richtung: "arrow.left.arrow.right"
        case .typ:      "tag"
        case .name:     "textformat"
        }
    }
}

// MARK: - AllOffersView (S23 — „Alle Angebote")
// Aggregiert die 04/05-Belege ALLER Projekte mit Drive-Ordner in eine flache,
// sortier- und durchsuchbare Liste. Read-only; Klick = In-App-Vorschau.
struct AllOffersView: View {
    let projects: [AllOffersCollector.ProjectRef]

    @Environment(AppState.self) private var appState
    @State private var loader = AllOffersLoader()
    @State private var searchText = ""
    @State private var reloadToken = 0
    @AppStorage("angebote.alle.sort") private var sortRaw = AllOffersSort.datum.rawValue

    private var sort: AllOffersSort { AllOffersSort(rawValue: sortRaw) ?? .datum }

    private var visible: [AllOffersCollector.AggregatedOffer] {
        AllOffersSorter.sorted(
            AllOffersSorter.filtered(loader.offers, query: searchText),
            by: sort)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            header
            if case .content = loader.renderState { toolbar }
            content
            Spacer(minLength: 0)
            sourceLine
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.top, MykSpace.s7)
        .padding(.bottom, MykSpace.s7)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task(id: reloadToken) {
            await loader.load(projects: projects)
            // Härtung (2026-07-01, Audit): DRIVE_ALL_OFFERS war zwar im Benutzerhandbuch
            // dokumentiert, hatte aber weder einen Manifest-Eintrag noch einen echten
            // dataFlow.log-Aufruf — in der Schaltzentrale unsichtbar.
            switch loader.renderState {
            case .content, .empty:
                appState.dataFlow.log(integrationID: "DRIVE_ALL_OFFERS", actorUserID: appState.actorUserID,
                                       action: .success, recordsRead: loader.offers.count,
                                       summary: "Alle Angebote geladen (\(loader.offers.count) über \(projects.count) Projekte)")
            case .error(let msg):
                appState.dataFlow.log(integrationID: "DRIVE_ALL_OFFERS", actorUserID: appState.actorUserID,
                                       action: .error, errorMessage: msg, summary: "Alle Angebote: Laden fehlgeschlagen")
            case .loading, .permissionRequired, .offline:
                break
            }
        }
    }

    // MARK: Kopf

    private var header: some View {
        HStack(spacing: MykSpace.s4) {
            SourceChip(kind: .drive)
            Text("Alle Angebote").mykWidgetTitle()
            Spacer()
            Button {
                reloadToken &+= 1
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.drive.color)
            }
            .buttonStyle(.plain)
            .help("Alle Projektordner neu durchsuchen")
        }
    }

    private var toolbar: some View {
        HStack(spacing: MykSpace.s4) {
            sortMenu
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "magnifyingglass")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.muted.color)
                TextField("Datei, Projekt oder Belegnummer suchen…", text: $searchText)
                    .font(.mykSmall)
                    .textFieldStyle(.plain)
                    .frame(minWidth: 220)
            }
            .padding(.horizontal, MykSpace.s4)
            .padding(.vertical, MykSpace.s3)
            .background(RoundedRectangle(cornerRadius: MykRadius.sm)
                .fill(MykColor.card.color)
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1)))
            Spacer()
            Text("\(visible.count) Belege")
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(AllOffersSort.allCases, id: \.self) { option in
                Button { sortRaw = option.rawValue } label: {
                    Label(option.label, systemImage: sort == option ? "checkmark" : option.icon)
                }
            }
        } label: {
            Label("Sortieren: \(sort.label)", systemImage: "arrow.up.arrow.down")
                .font(.mykSmall).foregroundStyle(MykColor.muted.color)
                .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s3)
                .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.card.color)
                    .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1)))
        }
        .menuStyle(.borderlessButton).fixedSize()
    }

    // MARK: Inhalt / Zustände

    @ViewBuilder
    private var content: some View {
        switch loader.renderState {
        case .loading:
            loadingState
        case .content:
            offerList
        case .empty:
            hint(icon: "tray", text: "Keine Angebote/Rechnungen in den 04/05-Ordnern gefunden.")
        case .permissionRequired:
            hint(icon: "lock.circle",
                 text: "Google Drive nicht verbunden. In den Einstellungen verbinden, dann erneut versuchen.",
                 retry: true)
        case .offline:
            hint(icon: "wifi.slash", text: "Offline — keine Verbindung zu Google Drive.", retry: true)
        case .error(let msg):
            hint(icon: "exclamationmark.triangle", text: "Fehler: \(msg)", retry: true, critical: true)
        }
    }

    private var loadingState: some View {
        VStack(spacing: MykSpace.s4) {
            ProgressView()
            Text(loader.projectsTotal > 0
                 ? "Durchsuche alle Projektordner … \(loader.projectsScanned)/\(loader.projectsTotal)"
                 : "Durchsuche alle Projektordner …")
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var offerList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(visible) { item in
                    AllOfferRow(item: item)
                    Divider().overlay(MykColor.line.color.opacity(0.5))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func hint(icon: String, text: String, retry: Bool = false, critical: Bool = false) -> some View {
        VStack(spacing: MykSpace.s4) {
            Image(systemName: icon)
                .font(.mykHeadline)
                .foregroundStyle(critical ? MykColor.critical.color : MykColor.faint.color)
            Text(text)
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            if retry {
                Button("Erneut versuchen") { reloadToken &+= 1 }
                    .font(.mykMono(9.5))
                    .buttonStyle(.plain)
                    .foregroundStyle(MykColor.drive.color)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sourceLine: some View {
        HStack(spacing: MykSpace.s3) {
            Circle().fill(MykColor.drive.color).frame(width: 5, height: 5)
            Text(sourceText)
                .font(.mykMono(9))
                .foregroundStyle(MykColor.muted.color)
        }
    }

    private var sourceText: String {
        switch loader.renderState {
        case .content:
            var s = "GOOGLE DRIVE · \(loader.offers.count) BELEGE · \(loader.projectsScanned) PROJEKTE"
            if loader.projectsFailed > 0 { s += " · \(loader.projectsFailed) ÜBERSPRUNGEN" }
            return s
        default:
            return "GOOGLE DRIVE"
        }
    }
}

// MARK: - AllOfferRow
// Spiegelt OfferRow (Projekt-Tab): lokale Vorschau zuerst, sonst Drive-Bytes,
// Klick → FilePreviewView-Popover (mit Vollvorschau-Button), Kontextmenü.
private struct AllOfferRow: View {
    let item: AllOffersCollector.AggregatedOffer

    @State private var showPreview = false
    @State private var resolvedLocalURL: URL?

    private var file: GoogleDriveFile { item.offer.file }

    private var metaLine: String {
        var parts: [String] = [item.projectTitle, item.projectNumber, item.direction.label, item.offer.type.label]
        if let nr = item.offer.belegNummer { parts.append(nr) }
        if let v = item.offer.version { parts.append(v) }
        if let modifiedAt = file.modifiedAt {
            parts.append(modifiedAt.formatted(.relative(presentation: .named)))
        }
        return parts.joined(separator: " · ")
    }

    private func resolveLocalURL() -> URL? {
        guard item.projectFolderID.isEmpty == false else { return nil }
        return LocalDriveRootResolver.shared.localURL(
            forFileID: file.id, fileName: file.name,
            inProjectFolderID: item.projectFolderID, explicitProjectPath: nil)
    }

    private func remoteContent() -> (@Sendable () async -> Data?)? {
        let fileID = file.id
        return { try? await GoogleDriveClient().downloadContent(fileID: fileID) }
    }

    var body: some View {
        Button {
            resolvedLocalURL = resolveLocalURL()
            showPreview.toggle()
        } label: {
            HStack(spacing: MykSpace.s4) {
                Image(systemName: file.iconName)
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.cash.color)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.ink.color)
                        .lineLimit(1)
                    Text(metaLine)
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.muted.color)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "eye")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.faint.color)
            }
            .padding(.vertical, MykSpace.s3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPreview, arrowEdge: .trailing) {
            FilePreviewView(file: file, localURL: resolvedLocalURL, remoteContent: remoteContent())
                .frame(width: 320)
                .padding(MykSpace.s2)
        }
        .contextMenu {
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
