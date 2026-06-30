import Foundation
import MykilosKit

// MARK: - LagerlisteStore
// Lädt die Airtable-Tabelle „Lagerliste" (tblh8j1Rykv12T2Dx, 151 Records) und
// stellt sie als lokalen In-Memory-Snapshot bereit.
//
// Read-only. Kein GRDB, kein lokaler Cache. @MainActor @Observable.
// Base: appdxTeT6bhSBmwx5 (Artikel & Einkauf — READ-ONLY, kein Schreiben).
@MainActor
@Observable
public final class LagerlisteStore {

    // MARK: - LoadState (alle Renderstates)
    public enum LoadState: Equatable {
        case idle
        case loading
        /// Erfolgreich geladen — N Artikel im Lager.
        case content([LagerItem])
        case empty
        case notConnected
        case error(String)
    }

    // MARK: - Properties

    public private(set) var state: LoadState = .idle

    /// Alle Lagerartikel aus dem letzten erfolgreichen Laden.
    public var items: [LagerItem] {
        if case .content(let items) = state { return items }
        return []
    }

    // MARK: - Konstanten (Airtable appdxTeT6bhSBmwx5)
    public static let baseID    = "appdxTeT6bhSBmwx5"
    public static let tableID   = "Lagerliste"
    public static let tableKey  = "tblh8j1Rykv12T2Dx"

    // Feld-IDs (für Mapping)
    static let feldBezeichnung   = "fldVBhI0ozPXh7XkE"
    static let feldKategorie     = "fldaqtdkWSgwiDZvL"
    static let feldHersteller    = "fldeOCaWqzojGUtd2"
    static let feldArtikelnummer = "fldKIAfFwuvRuDlnY"
    static let feldBestand       = "fldcSK7xsT896exNf"
    static let feldEKNetto       = "fldpqoXnOpKkluQC8"
    static let feldVKNetto       = "fld7OcmQ7ImmU47iT"
    static let feldQuelle        = "fldA8VVAdN9JrXxSh"
    static let feldNotiz         = "fldaR6YTb0601O3SX"

    // MARK: - Private

    private let client: AirtableFetching

    // MARK: - Init

    public init(client: AirtableFetching = AirtableClient()) {
        self.client = client
    }

    // MARK: - API

    /// Lädt alle Lagerartikel frisch aus Airtable. Setzt State durch alle Phasen.
    /// Mehrfachaufruf während laufendem Load wird durch `loading`-Guard verhindert.
    public func load() async {
        guard case .loading = state else {
            state = .loading
            await _fetchAndMap()
            return
        }
    }

    /// Erzwingt Reload (ignoriert laufenden Load). Für Refresh-Buttons.
    public func reload() async {
        state = .loading
        await _fetchAndMap()
    }

    // MARK: - Private Fetch

    private func _fetchAndMap() async {
        do {
            let records = try await client.fetchRecords(
                baseID: Self.baseID,
                table: Self.tableID
            )
            let mapped = Self.mapLagerItems(from: records)
            state = mapped.isEmpty ? .empty : .content(mapped)
        } catch AirtableError.notConnected {
            state = .notConnected
        } catch AirtableError.httpError(let code) {
            state = .error("HTTP \(code)")
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Reine Mapping-Funktion (testbar)

    /// Mappt rohe Airtable-Records auf `LagerItem`-Werte.
    /// Pflichtfeld ist `Bezeichnung` — Records ohne Bezeichnung werden übersprungen.
    public nonisolated static func mapLagerItems(
        from records: [[String: AirtableFieldValue]]
    ) -> [LagerItem] {
        records.compactMap { fields in
            guard let bezeichnung = fields[feldBezeichnung]?.stringValue,
                  !bezeichnung.trimmingCharacters(in: .whitespaces).isEmpty else {
                return nil
            }
            let recordID = fields["_airtableRecordID"]?.stringValue ?? bezeichnung
            let bestandRaw = fields[feldBestand]?.numberValue
            return LagerItem(
                id: recordID,
                bezeichnung: bezeichnung,
                kategorie: fields[feldKategorie]?.stringValue,
                hersteller: fields[feldHersteller]?.stringValue,
                artikelnummer: fields[feldArtikelnummer]?.stringValue,
                bestand: bestandRaw.map { Int($0) },
                ekNetto: fields[feldEKNetto]?.numberValue,
                vkNetto: fields[feldVKNetto]?.numberValue,
                quelle: fields[feldQuelle]?.stringValue,
                notiz: fields[feldNotiz]?.stringValue
            )
        }
    }
}
