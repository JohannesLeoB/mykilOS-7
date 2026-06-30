import Foundation
import SwiftUI
import MykilosKit
import MykilosServices

// MARK: - WarenkorbState
// Listenübergreifender Warenkorb-UI-State (lokal, in-session).
// Sammelt Positionen aus Artikel-Tab + Lager-Tab. Menge editierbar.
// @MainActor @Observable — kein GRDB, kein Airtable-Schreiben direkt hier.
// Schreiben nur über WarenkorbVersandView → CartStore.sendWarenkorbToAirtable (gated).
@MainActor
@Observable
public final class WarenkorbState {

    // MARK: - Mutable Position (für UI-Editierung)
    public struct Position: Identifiable, Sendable, Equatable {
        public let id: String          // stabil: source + artikelnummer
        public let source: String      // "katalog" | "lager"
        public let artikelRecordID: String?
        public let bezeichnung: String
        public let artikelnummer: String
        public var menge: Int
        public let ekNetto: Double?
        public let vkNetto: Double?

        public init(
            id: String,
            source: String,
            artikelRecordID: String? = nil,
            bezeichnung: String,
            artikelnummer: String,
            menge: Int = 1,
            ekNetto: Double? = nil,
            vkNetto: Double? = nil
        ) {
            self.id = id
            self.source = source
            self.artikelRecordID = artikelRecordID
            self.bezeichnung = bezeichnung
            self.artikelnummer = artikelnummer
            self.menge = menge
            self.ekNetto = ekNetto
            self.vkNetto = vkNetto
        }

        /// Konvertiert zu WarenkorbItem für CartStore.
        public var warenkorbItem: WarenkorbItem {
            WarenkorbItem(
                artikelRecordID: artikelRecordID,
                bezeichnung: bezeichnung,
                artikelnummer: artikelnummer,
                menge: menge,
                ekNetto: ekNetto,
                vkNetto: vkNetto,
                quelle: source
            )
        }
    }

    // MARK: - State
    public private(set) var positionen: [Position] = []
    public var showPanel: Bool = false

    // MARK: - Berechnungen

    public var anzahl: Int { positionen.reduce(0) { $0 + $1.menge } }

    public var gesamtEK: Double {
        positionen.reduce(0.0) { $0 + ($1.ekNetto ?? 0.0) * Double($1.menge) }
    }

    public var gesamtVK: Double {
        positionen.reduce(0.0) { $0 + ($1.vkNetto ?? 0.0) * Double($1.menge) }
    }

    public var istLeer: Bool { positionen.isEmpty }

    // MARK: - Mutationen

    /// Artikel aus dem Katalog-Tab hinzufügen (oder Menge erhöhen).
    public func addArtikel(_ artikel: ArtikelItem) {
        let posID = "katalog-\(artikel.artikelnummer)"
        if let idx = positionen.firstIndex(where: { $0.id == posID }) {
            positionen[idx].menge += 1
        } else {
            positionen.append(Position(
                id: posID,
                source: "katalog",
                artikelRecordID: artikel.id,
                bezeichnung: artikel.artikelbeschreibung ?? artikel.artikelnummer,
                artikelnummer: artikel.artikelnummer,
                menge: 1,
                ekNetto: artikel.ekNetto,
                vkNetto: artikel.vkNetto
            ))
        }
    }

    /// Lager-Position hinzufügen (oder Menge erhöhen).
    public func addLagerItem(_ item: LagerItem) {
        let posID = "lager-\(item.id)"
        if let idx = positionen.firstIndex(where: { $0.id == posID }) {
            positionen[idx].menge += 1
        } else {
            positionen.append(Position(
                id: posID,
                source: "lager",
                artikelRecordID: item.id,
                bezeichnung: item.bezeichnung,
                artikelnummer: item.artikelnummer ?? item.id,
                menge: 1,
                ekNetto: item.ekNetto,
                vkNetto: item.vkNetto
            ))
        }
    }

    /// Menge setzen (0 = entfernen).
    public func setMenge(_ menge: Int, forID id: String) {
        if menge <= 0 {
            positionen.removeAll { $0.id == id }
        } else if let idx = positionen.firstIndex(where: { $0.id == id }) {
            positionen[idx].menge = menge
        }
    }

    /// Position entfernen.
    public func remove(id: String) {
        positionen.removeAll { $0.id == id }
    }

    /// Warenkorb leeren.
    public func leeren() {
        positionen.removeAll()
    }

    /// Snapshot für CartStore.
    public func makeWarenkorb(projektRecordID: String?, projektName: String?) -> Warenkorb {
        Warenkorb(
            items: positionen.map(\.warenkorbItem),
            projektRecordID: projektRecordID,
            projektName: projektName
        )
    }
}
