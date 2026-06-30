import Foundation
import MykilosKit

// MARK: - AirtableContactsLoader (S19)
// Lädt ALLE Kontakte aus der Airtable-Tabelle „Kontakte" (tblncfQzQa8TzCZQC) und
// stellt sie als lokalen Snapshot bereit. @MainActor @Observable — kein GRDB, kein
// lokaler Cache (rein in-memory). Sichtbarer LoadState für alle Renderstates.
// Read-only. Schreibpfad geht über AirtableContactWriteTool → Bestätigungskarte → Audit.
@MainActor
@Observable
public final class AirtableContactsLoader {

    // MARK: - LoadState (alle Renderstates)
    public enum LoadState: Equatable {
        case idle
        case loading
        case content([StudioContact])
        case empty
        case notConnected
        case error(String)
    }

    // MARK: - Properties

    public private(set) var state: LoadState = .idle

    /// Alle Kontakte aus dem letzten erfolgreichen Laden.
    public var contacts: [StudioContact] {
        if case .content(let c) = state { return c }
        return []
    }

    // MARK: - Private

    private let baseID: String
    private let tableID: String
    private let client: AirtableFetching

    // MARK: - Init

    public init(
        baseID: String = "appuVMh3KDfKw4OoQ",
        tableID: String = "Kontakte",
        client: AirtableFetching = AirtableClient()
    ) {
        self.baseID = baseID
        self.tableID = tableID
        self.client = client
    }

    // MARK: - API

    /// Lädt alle Kontakte frisch aus Airtable. Setzt den LoadState durch alle Phasen.
    public func load() async {
        state = .loading
        do {
            let records = try await client.fetchRecords(baseID: baseID, table: tableID)
            let mapped = AirtableClient.mapContacts(from: records)
            if mapped.isEmpty {
                state = .empty
            } else {
                state = .content(mapped)
            }
        } catch AirtableError.notConnected {
            state = .notConnected
        } catch AirtableError.httpError(let code) {
            state = .error("HTTP \(code)")
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
