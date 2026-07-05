import Foundation
import MykilosKit

// MARK: - ClockodoNutzerLoader (Personalausweis-Anreicherung)
// Lädt die Airtable-Tabelle „Clockodo-Nutzer" (tblPbly2br8mR2kaU) und löst zu
// einer verifizierten Google-Mail die reinen Handles/IDs auf (read-only).
// @MainActor @Observable — kein GRDB, kein lokaler Cache (rein in-memory).
// Sichtbarer LoadState für alle Renderstates. Read-only: kein Schreibpfad.
//
// Weg A (kein Client-Umbau): nutzt das BESTEHENDE
// AirtableFetching.fetchRecords(baseID:table:) — keine neue Protokoll-Methode,
// kein filterByFormula (die Tabelle hat nur wenige Zeilen), damit alle
// Fake-Clients grün bleiben.
@MainActor
@Observable
public final class ClockodoNutzerLoader {

    // MARK: - LoadState (alle Renderstates)
    public enum LoadState: Equatable {
        case idle
        case loading
        case content(ResidentIdentityHandles)
        case empty          // verbunden, aber keine Zeile passt zur Mail
        case notConnected
        case error(String)
    }

    // MARK: - Properties

    public private(set) var state: LoadState = .idle

    /// Die aufgelösten Handles aus dem letzten erfolgreichen Treffer, sonst nil.
    public var handles: ResidentIdentityHandles? {
        if case .content(let h) = state { return h }
        return nil
    }

    // MARK: - Private

    private let baseID: String
    private let tableID: String
    private let client: AirtableFetching

    // MARK: - Init

    public init(
        baseID: String = "appuVMh3KDfKw4OoQ",
        tableID: String = "tblPbly2br8mR2kaU",
        client: AirtableFetching = AirtableClient()
    ) {
        self.baseID = baseID
        self.tableID = tableID
        self.client = client
    }

    // MARK: - API

    /// Lädt die Clockodo-Nutzer frisch und löst zur gegebenen Mail auf. Setzt
    /// den LoadState durch alle Phasen. Kein Treffer → .empty.
    public func load(matchingEmail email: String) async {
        state = .loading
        do {
            let records = try await client.fetchRecords(baseID: baseID, table: tableID)
            if let handles = AirtableClient.mapResidentIdentity(from: records, matchingEmail: email) {
                state = .content(handles)
            } else {
                state = .empty
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
