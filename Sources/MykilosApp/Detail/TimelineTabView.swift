import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - TimelineTabView (L27)
// Eine chronologische Spine des Projekts: Drive-Dateien, Angebote, Kalendertermine
// und Audit-Aktionen zu EINER absteigend sortierten Ereignisliste verschmolzen.
// Read-only. Die reine Merge-Logik liegt testbar in MykilosServices (TimelineMerger);
// hier bleibt nur die UI + ein dünner Orchestrierungs-Loader.
struct TimelineTabView: View {
    let projectID: String
    let driveFolderID: String?
    let calendarQuery: String?
    let auditStore: AuditStore

    @State private var loader = TimelineLoader()

    var body: some View {
        WidgetContainer(
            kind: .drive,
            sourceLabel: sourceLabel,
            renderState: loader.renderState,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                header
                timelineList
            }
        }
        .task(id: driveFolderID) { await reload() }
        .padding(.horizontal, MykSpace.s9)
        .padding(.top, MykSpace.s7)
        .padding(.bottom, 64)
    }

    private func reload() async {
        try? auditStore.load()   // gesamtes Audit laden, dann projektweise filtern
        await loader.load(
            rootFolderID: driveFolderID,
            calendarQuery: calendarQuery,
            auditEntries: auditStore.entries(for: projectID)
        )
    }

    private var sourceLabel: String {
        switch loader.renderState {
        case .content: "VERLAUF  ·  \(loader.items.count) EREIGNISSE"
        default:       "VERLAUF"
        }
    }

    private var header: some View {
        HStack {
            SourceChip(kind: .drive)
            Text("Verlauf").mykWidgetTitle()
            Spacer()
            if case .content = loader.renderState { refreshButton }
            else if case .error = loader.renderState { retryButton }
            else if case .permissionRequired = loader.renderState { retryButton }
        }
    }

    private var refreshButton: some View {
        Button { Task { await reload() } } label: {
            Image(systemName: "arrow.clockwise")
                .font(.mykCaption)
                .foregroundStyle(MykColor.drive.color)
        }
        .buttonStyle(.plain)
        .help("Aktualisieren")
        .accessibilityLabel("Aktualisieren")
    }

    private var retryButton: some View {
        Button("Erneut versuchen") { Task { await reload() } }
            .font(.mykMono(9.5))
            .buttonStyle(.plain)
            .foregroundStyle(MykColor.drive.color)
    }

    private var timelineList: some View {
        VStack(spacing: 0) {
            ForEach(loader.items) { item in
                TimelineRow(item: item)
                if item.id != loader.items.last?.id {
                    Divider().overlay(MykColor.line.color.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - TimelineRow
private struct TimelineRow: View {
    let item: TimelineItem

    // Quelle → Farbe (Farbe ist Sprache). Mapping lebt in der View-Schicht,
    // nicht im Merger (Services importiert kein Design).
    private var color: Color {
        switch item.source {
        case .drive:    MykColor.drive.color
        case .offer:    MykColor.cash.color
        case .calendar: MykColor.people.color
        case .audit:    MykColor.personal.color
        }
    }

    private var icon: String {
        switch item.source {
        case .drive:    "doc"
        case .offer:    "eurosign.circle"
        case .calendar: "calendar"
        case .audit:    "checkmark.seal"
        }
    }

    @State private var showViewer = false

    // Vorschau nur für echte Dateien (Drive/Angebot), nicht für Google-Native-Formate.
    private var previewFile: GoogleDriveFile? {
        guard let f = item.driveFile, f.isFolder == false,
              f.mimeType.hasPrefix("application/vnd.google-apps") == false else { return nil }
        return f
    }

    private func remoteContent() -> (@Sendable () async -> Data?)? {
        guard let f = previewFile else { return nil }
        let fileID = f.id
        return { try? await GoogleDriveClient().downloadContent(fileID: fileID) }
    }

    private func openFallback() {
        if let link = item.webViewLink, let url = URL(string: link) {
            NSWorkspace.shared.open(url)
        }
    }

    var body: some View {
        Button {
            // Sammlungs-Ansicht-Standard: Datei-Ereignisse öffnen die In-App-
            // Vorschau; alles andere (Kalender/Audit/Google-native) den Link.
            if previewFile != nil { showViewer = true } else { openFallback() }
        } label: {
            HStack(alignment: .top, spacing: MykSpace.s4) {
                Image(systemName: icon)
                    .font(.mykCaption)
                    .foregroundStyle(color)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.ink.color)
                        .lineLimit(1)
                    HStack(spacing: MykSpace.s2) {
                        if let subtitle = item.subtitle, subtitle.isEmpty == false {
                            Text(subtitle)
                                .font(.mykMono(9.5))
                                .foregroundStyle(color)
                                .lineLimit(1)
                        }
                        Text(item.date.formatted(.relative(presentation: .named)))
                            .font(.mykMono(9.5))
                            .foregroundStyle(MykColor.muted.color)
                    }
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, MykSpace.s3)
        .contextMenu {
            if previewFile != nil { Button("Vorschau") { showViewer = true } }
            if item.webViewLink != nil { Button("Im Browser öffnen") { openFallback() } }
        }
        .sheet(isPresented: $showViewer) {
            if let f = previewFile {
                DocumentViewerView(file: f, localURL: nil, remoteContent: remoteContent(),
                                   onClose: { showViewer = false })
                    .frame(minWidth: 820, minHeight: 680)
            }
        }
    }
}

// MARK: - TimelineLoader
// Dünner Orchestrator: holt die vier Quellen (Drive/Angebote/Kalender/Audit),
// degradiert jede einzeln bei Fehler (eine kaputte Quelle leert nicht den Tab) und
// reicht alles an den reinen TimelineMerger. Testbare Logik steckt im Merger.
@MainActor
@Observable
private final class TimelineLoader {
    private(set) var items: [TimelineItem] = []
    private(set) var renderState: WidgetRenderState = .loading

    private let driveClient: GoogleDriveFetching
    private let calendarClient: GoogleCalendarFetching
    private var loadGeneration = 0

    init(driveClient: GoogleDriveFetching = GoogleDriveClient(),
         calendarClient: GoogleCalendarFetching = GoogleCalendarClient()) {
        self.driveClient = driveClient
        self.calendarClient = calendarClient
    }

    func load(rootFolderID: String?, calendarQuery: String?, auditEntries: [AuditEntry]) async {
        loadGeneration &+= 1
        let generation = loadGeneration
        renderState = .loading

        var driveFiles: [GoogleDriveFile] = []
        var offers = OffersCollector.Result(incoming: [], outgoing: [],
                                            incomingFolderFound: false, outgoingFolderFound: false)
        var events: [GoogleCalendarEvent] = []
        var sawNotConnected = false

        if let rootFolderID, rootFolderID.isEmpty == false {
            do { driveFiles = try await driveClient.listFolder(folderID: rootFolderID) }
            catch GoogleDriveError.notConnected { sawNotConnected = true }
            catch { /* eine Quelle darf scheitern, ohne den Tab zu leeren */ }

            do { offers = try await OffersCollector.load(rootFolderID: rootFolderID, client: driveClient) }
            catch GoogleDriveError.notConnected { sawNotConnected = true }
            catch { }
        }

        do { events = try await calendarClient.listUpcomingEvents(query: calendarQuery, withinDays: 30) }
        catch GoogleCalendarError.notConnected { sawNotConnected = true }
        catch { }

        guard generation == loadGeneration else { return }

        items = TimelineMerger.merge(
            driveFiles: driveFiles, offers: offers,
            calendarEvents: events, auditEntries: auditEntries)

        if items.isEmpty {
            // Nichts geladen UND eine Verbindung fehlte UND kein lokales Audit →
            // „Berechtigung nötig"; sonst echt leer.
            renderState = (sawNotConnected && auditEntries.isEmpty) ? .permissionRequired : .empty
        } else {
            renderState = .content
        }
    }
}
