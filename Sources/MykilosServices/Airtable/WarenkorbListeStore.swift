import Foundation
import MykilosKit

// MARK: - WarenkorbListeStore
// Lädt die Airtable-Tabelle „Warenkörbe" (tblhZujm3Ig6hlafX, Base appdxTeT6bhSBmwx5)
// als read-only Liste — alle Versionen, sortiert nach Erstelldatum absteigend.
//
// Kein GRDB, kein lokaler Cache. @MainActor @Observable.
// Schreiben nur über CartStore (append-only, gated).
// Feld-NAMEN (nicht IDs) für Lesen — exakt wie LagerlisteStore.
@MainActor
@Observable
public final class WarenkorbListeStore {

    // MARK: - LoadState
    public enum LoadState: Equatable {
        case idle
        case loading
        case content([WarenkorbEintrag])
        case empty
        case notConnected
        case error(String)
    }

    // MARK: - Properties

    public private(set) var state: LoadState = .idle

    public var eintraege: [WarenkorbEintrag] {
        if case .content(let items) = state { return items }
        return []
    }

    // MARK: - Konstanten
    public static let baseID    = "appdxTeT6bhSBmwx5"
    public static let tableID   = "Warenkörbe"
    public static let tableKey  = "tblhZujm3Ig6hlafX"

    // Feld-NAMEN (READ, nicht IDs)
    static let feldBezeichnung      = "Bezeichnung"
    static let feldProjekt          = "Projekt"
    static let feldStatus           = "Status"
    static let feldVersion          = "Version"
    static let feldErstelltAm       = "Erstellt-am"
    static let feldAnzahlPositionen = "Anzahl Positionen"
    static let feldGesamtEK         = "Gesamt EK (€)"
    static let feldGesamtVK         = "Gesamt VK (€)"
    static let feldPositionenJSON   = "Positionen (JSON)"

    // MARK: - Private
    private let client: AirtableFetching

    // MARK: - Init
    public init(client: AirtableFetching = AirtableClient()) {
        self.client = client
    }

    // MARK: - API

    public func load() async {
        guard case .loading = state else {
            state = .loading
            await _fetchAndMap()
            return
        }
    }

    public func reload() async {
        state = .loading
        await _fetchAndMap()
    }

    // MARK: - Private

    private func _fetchAndMap() async {
        do {
            let records = try await client.fetchRecords(
                baseID: Self.baseID,
                table: Self.tableID
            )
            let mapped = Self.mapEintraege(from: records)
                .sorted { lhs, rhs in
                    // Neueste zuerst: nach erstelltAm absteigend, dann nach Version
                    if let l = lhs.erstelltAm, let r = rhs.erstelltAm {
                        return l > r
                    }
                    return lhs.version > rhs.version
                }
            state = mapped.isEmpty ? .empty : .content(mapped)
        } catch AirtableError.notConnected {
            state = .notConnected
        } catch AirtableError.httpError(let code) {
            state = .error("HTTP \(code)")
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Mapping (testbar, nonisolated)

    /// ISO-8601-Datumsformater (Thread-safe: neue Instanz pro Aufruf vermeiden → static let).
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoFormatterShort: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    public nonisolated static func mapEintraege(
        from records: [[String: AirtableFieldValue]]
    ) -> [WarenkorbEintrag] {
        records.compactMap { fields in
            // Pflichtfeld: Bezeichnung
            guard let bezeichnung = fields[feldBezeichnung]?.anyStringValue,
                  !bezeichnung.trimmingCharacters(in: .whitespaces).isEmpty else {
                return nil
            }
            let recordID = fields["_airtableRecordID"]?.stringValue ?? bezeichnung

            // Datum parsen — Airtable sendet ISO-8601 mit oder ohne Millisekunden
            let erstelltAm: Date? = {
                guard let dateStr = fields[feldErstelltAm]?.stringValue else { return nil }
                return isoFormatter.date(from: dateStr)
                    ?? isoFormatterShort.date(from: dateStr)
            }()

            // Projekt: kann ein Lookup-Array oder ein String sein
            let projekt = fields[feldProjekt]?.firstArrayValue
                ?? fields[feldProjekt]?.anyStringValue

            let version = fields[feldVersion]?.numberValue.map { Int($0) } ?? 1

            return WarenkorbEintrag(
                id: recordID,
                bezeichnung: bezeichnung,
                projekt: projekt,
                status: fields[feldStatus]?.stringValue ?? "Aktuell",
                version: version,
                erstelltAm: erstelltAm,
                anzahlPositionen: fields[feldAnzahlPositionen]?.numberValue.map { Int($0) },
                gesamtEK: fields[feldGesamtEK]?.numberValue,
                gesamtVK: fields[feldGesamtVK]?.numberValue,
                positionenJSON: fields[feldPositionenJSON]?.stringValue
            )
        }
    }
}
