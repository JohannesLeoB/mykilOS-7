import Foundation
import MykilosKit
import MykilosServices
import MykilosWidgets

// MARK: - OffersLoader
// Dünner @Observable-Wrapper um die testbare Sammel-/Klassifikationslogik in
// `OffersCollector` (MykilosServices). Hier bleiben nur die UI-nahen Belange:
// Render-State, Generations-Guard gegen Lade-Races, Fehler-Mapping.
// Die fachliche Logik (Unterordner-Auflösung, Rekursion, Klassifikation) ist
// jetzt echt testbar (siehe OffersCollectorTests) — Forensik F7.
@MainActor
@Observable
final class OffersLoader {
    private(set) var incoming: [ClassifiedOffer] = []
    private(set) var outgoing: [ClassifiedOffer] = []
    private(set) var incomingFolderFound = true
    private(set) var outgoingFolderFound = true
    private(set) var renderState: WidgetRenderState = .loading

    private let client: GoogleDriveFetching
    private var loadGeneration = 0

    init(client: GoogleDriveFetching = GoogleDriveClient()) {
        self.client = client
    }

    func load(rootFolderID: String?) async {
        loadGeneration &+= 1
        let generation = loadGeneration
        guard let rootFolderID, rootFolderID.isEmpty == false else {
            incoming = []; outgoing = []
            renderState = .empty
            return
        }
        renderState = .loading
        do {
            let result = try await OffersCollector.load(rootFolderID: rootFolderID, client: client)
            guard generation == loadGeneration else { return }
            incoming = result.incoming
            outgoing = result.outgoing
            incomingFolderFound = result.incomingFolderFound
            outgoingFolderFound = result.outgoingFolderFound
            renderState = (incoming.isEmpty && outgoing.isEmpty) ? .empty : .content
        } catch GoogleDriveError.notConnected {
            guard generation == loadGeneration else { return }
            incoming = []; outgoing = []
            renderState = .permissionRequired
        } catch {
            guard generation == loadGeneration else { return }
            incoming = []; outgoing = []
            renderState = .error(String(describing: error))
        }
    }
}
