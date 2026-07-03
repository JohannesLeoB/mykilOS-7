import Foundation
import MykilosKit

// MARK: - ArtikelKatalogStore
// Lädt die Airtable-Tabelle „Artikel" (tbl3dAbQtbF51wb4a, ~13.419 Records) paginiert
// und cacht alle Einträge in-memory für clientseitiges Filtern/Suchen.
//
// Strategie: Beim ersten Laden werden alle Seiten (pageSize=100) sequenziell abgerufen
// und im State gespeichert. Danach: lokale Suche ohne Netzwerk.
// Base: appdxTeT6bhSBmwx5 (Artikel & Einkauf — READ-ONLY, kein Schreiben).
//
// @MainActor @Observable — kein GRDB.
@MainActor
@Observable
public final class ArtikelKatalogStore {

    // MARK: - LoadState (alle Renderstates)
    public enum LoadState: Equatable {
        case idle
        /// Wird geladen — mit Fortschritts-Info (Anzahl bereits geladener Records).
        case loading(Int)
        /// Vollständig geladen — N Artikel im Cache.
        case content([ArtikelItem])
        case empty
        case notConnected
        case error(String)
    }

    // MARK: - Properties

    public private(set) var state: LoadState = .idle

    /// Alle Artikel aus dem letzten erfolgreichen Laden.
    public var alleArtikel: [ArtikelItem] {
        if case .content(let items) = state { return items }
        return []
    }

    /// true, wenn der Katalog vollständig geladen ist.
    public var istGeladen: Bool {
        if case .content = state { return true }
        return false
    }

    // MARK: - Konstanten (Airtable appdxTeT6bhSBmwx5)
    public static let baseID  = "appdxTeT6bhSBmwx5"
    public static let tableID = "Artikel"
    public static let tableKey = "tbl3dAbQtbF51wb4a"

    // Feld-IDs
    static let feldArtikelnummer    = "Artikelnummer"
    static let feldHersteller       = "Hersteller"
    static let feldKategorie        = "Kategorie"
    static let feldBeschreibung     = "Artikelbeschreibung"
    static let feldEKNetto          = "Netto-Einkaufspreis (€)"
    static let feldVKNetto          = "Netto-Verkaufspreis MYKILOS (€)"
    static let feldProduktbild      = "Automatisches Produktbild (Web-Suche)"

    // MARK: - Private

    private let client: AirtableFetching
    // Härtung (2026-07-01, Johannes: "Preislisten dauern sehr lange zu laden"): ~13.419
    // Records über Airtables paginierte List-API sind ~135 sequenzielle Netzwerk-Roundtrips
    // — spürbar langsam bei JEDEM App-Start. Lokaler Datei-Cache (gleiches Muster wie
    // CachedProjectRegistry/CachedBusinessRegistry) zeigt sofort den letzten Stand, dann
    // wird im Hintergrund still von Airtable aktualisiert.
    private let cache: FileBackedRepository<ArtikelItem>?

    // MARK: - Init

    public init(client: AirtableFetching = AirtableClient(), cacheDirectory: URL? = nil) {
        self.client = client
        self.cache = try? FileBackedRepository<ArtikelItem>(filename: "artikel_katalog_cache", directory: cacheDirectory)
    }

    // MARK: - Laden

    /// Lädt den vollständigen Katalog. Bereits geladener In-Memory-Stand wird nicht erneut
    /// geladen — für Force-Refresh `reload()` verwenden. Gibt es einen lokalen Datei-Cache,
    /// wird dessen Stand SOFORT angezeigt (kein Warten auf Airtable), danach still im
    /// Hintergrund aktualisiert.
    public func load() async {
        switch state {
        case .content: return  // bereits gecacht (in-memory)
        case .loading: return  // läuft schon
        default: break
        }
        if let cached = try? cache?.loadAll(), !cached.isEmpty {
            state = .content(cached)
            await _fetchAll(showLoadingState: false)
        } else {
            state = .loading(0)
            await _fetchAll(showLoadingState: true)
        }
    }

    /// Erzwingt Reload — bestehenden Cache verwerfen. Für Refresh-Buttons.
    public func reload() async {
        state = .loading(0)
        await _fetchAll(showLoadingState: true)
    }

    // MARK: - Clientseitiges Filtern / Suchen

    /// Filtert den In-Memory-Cache nach Suchbegriff.
    /// Leerer/Whitespace-Term → gibt alle Artikel zurück.
    /// Sucht in: Artikelnummer, Hersteller, Artikelbeschreibung, Kategorie.
    /// Sortierung: nach Treffer-Score (absteigend), bei Gleichstand alphabetisch.
    public func suche(term: String) -> [ArtikelSuchergebnis] {
        let trimmed = term.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return alleArtikel.map { ArtikelSuchergebnis(artikel: $0, score: 0) }
        }
        return Self.filtere(artikel: alleArtikel, term: trimmed)
    }

    // MARK: - Reine Filter-Funktion (testbar ohne Netzwerk/State)

    /// Filtert Artikel nach Suchterm. Score = Anzahl matchender Tokens.
    /// Gibt nur Artikel zurück, bei denen mindestens 1 Token matcht.
    public nonisolated static func filtere(
        artikel: [ArtikelItem],
        term: String
    ) -> [ArtikelSuchergebnis] {
        let suchTokens = ArtikelItem.tokenize(term)
        guard !suchTokens.isEmpty else {
            return artikel.map { ArtikelSuchergebnis(artikel: $0, score: 0) }
        }
        let suchSet = Set(suchTokens)

        var ergebnisse: [ArtikelSuchergebnis] = []
        for a in artikel {
            let artikelSet = Set(a.suchTokens)
            let overlap = artikelSet.intersection(suchSet).count
            if overlap > 0 {
                ergebnisse.append(ArtikelSuchergebnis(artikel: a, score: overlap))
            }
        }
        // Sortierung: Score absteigend, dann Artikelnummer alphabetisch
        return ergebnisse.sorted {
            if $0.score != $1.score { return $0.score > $1.score }
            return $0.artikel.artikelnummer < $1.artikel.artikelnummer
        }
    }

    /// Filtert nach Kategorie — exakter, case-insensitiver Vergleich.
    public nonisolated static func filtereNachKategorie(
        artikel: [ArtikelItem],
        kategorie: String
    ) -> [ArtikelItem] {
        let lowerKat = kategorie.lowercased()
        return artikel.filter {
            $0.kategorie?.lowercased() == lowerKat
        }
    }

    /// Filtert nach Hersteller — exakter, case-insensitiver Vergleich.
    public nonisolated static func filtereNachHersteller(
        artikel: [ArtikelItem],
        hersteller: String
    ) -> [ArtikelItem] {
        let lower = hersteller.lowercased()
        return artikel.filter {
            $0.hersteller?.lowercased() == lower
        }
    }

    // MARK: - Private Fetch

    /// Lädt alle Records paginiert. Da der AirtableClient intern alle Seiten holt,
    /// gibt es einen einzigen Aufruf. Für sichtbaren Fortschritt: der State wechselt
    /// von .loading(0) → .loading(N nach Fetch) → .content oder .empty.
    /// Fehler werden sauber auf die passenden States gemappt — nie stilles Leer.
    /// `showLoadingState`: false beim stillen Hintergrund-Refresh (ein Cache-Stand hängt
    /// bereits sichtbar in `state`) — ein Fehler dabei fällt NICHT auf `.error`/`.notConnected`
    /// zurück (der alte Cache-Stand bleibt sichtbar), er wird nur nicht überschrieben.
    private func _fetchAll(showLoadingState: Bool) async {
        do {
            let records = try await client.fetchRecords(
                baseID: Self.baseID,
                table: Self.tableID
            )
            // Fortschritt sichtbar machen: kurze Zwischenstation mit Anzahl geladener Records
            if showLoadingState { state = .loading(records.count) }
            // Mapping auf Background-Thread auslagern (13k Records sind nicht trivial)
            let mapped = await Task.detached(priority: .userInitiated) {
                Self.mapArtikelItems(from: records)
            }.value
            if mapped.isEmpty {
                // Wenn wir Records hatten aber alle ausgefiltert wurden → Fehler-Hinweis,
                // nicht stilles .empty (wäre verwirrend bei 13k-Tabelle) — nur wenn kein
                // Cache-Stand bereits sichtbar ist (sonst bleibt der alte Stand stehen).
                if showLoadingState {
                    state = records.isEmpty ? .empty : .error("Keine Artikel mit Artikelnummer-Feld gemappt (\(records.count) Rohdaten). Feld-Namen prüfen.")
                }
            } else {
                state = .content(mapped)
                try? cache?.saveAll(mapped)
            }
        } catch AirtableError.notConnected {
            if showLoadingState { state = .notConnected }
        } catch AirtableError.httpError(let code) {
            if showLoadingState { state = .error("HTTP \(code) — Airtable nicht erreichbar oder Base-ID falsch.") }
        } catch AirtableError.decodingFailed {
            if showLoadingState { state = .error("Antwort konnte nicht dekodiert werden — API-Format geändert?") }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Reine Mapping-Funktion (testbar)

    /// Mappt rohe Airtable-Records auf `ArtikelItem`-Werte.
    /// Pflichtfeld: `Artikelnummer` — Records ohne Artikelnummer werden übersprungen.
    /// Wichtig: `anyStringValue` statt `stringValue` — Artikelnummern können in Airtable
    /// als Zahlenfeld formatiert sein (z. B. 12345 statt "12345").
    public nonisolated static func mapArtikelItems(
        from records: [[String: AirtableFieldValue]]
    ) -> [ArtikelItem] {
        records.compactMap { fields in
            // anyStringValue: auch numerische Artikelnummern (fld als Zahl) werden akzeptiert
            guard let artikelnummer = fields[feldArtikelnummer]?.anyStringValue,
                  !artikelnummer.trimmingCharacters(in: .whitespaces).isEmpty else {
                return nil
            }
            let recordID = fields["_airtableRecordID"]?.stringValue ?? artikelnummer
            // Produktbild: Airtable-Anhang → URL (array of attachment objects oder einfacher String)
            let bildURL = fields[feldProduktbild]?.firstArrayValue ?? fields[feldProduktbild]?.stringValue
            return ArtikelItem(
                id: recordID,
                artikelnummer: artikelnummer,
                hersteller: fields[feldHersteller]?.anyStringValue,
                kategorie: fields[feldKategorie]?.anyStringValue,
                artikelbeschreibung: fields[feldBeschreibung]?.anyStringValue,
                ekNetto: fields[feldEKNetto]?.numberValue,
                vkNetto: fields[feldVKNetto]?.numberValue,
                produktbildURL: bildURL
            )
        }
    }
}
