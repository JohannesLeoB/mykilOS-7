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
        /// Volle Daten-Fidelität (Johannes-Grundsatz, EISERN): freie Zusatzfelder, die das
        /// schlanke Kernmodell strukturell nicht trägt — bei aus einem Angebots-PDF
        /// herausgelösten Positionen der Originaltext, Seite, Richtung, Konfidenz-Ampel,
        /// Einzel-/Gesamt-/Listenpreis und die Quell-Datei. Additiv (default leer), wandert
        /// über `warenkorbItem.attribute` bis in den Checkout/`PickSnapshot.attribute`.
        public let attribute: [String: String]

        public init(
            id: String,
            source: String,
            artikelRecordID: String? = nil,
            bezeichnung: String,
            artikelnummer: String,
            menge: Int = 1,
            ekNetto: Double? = nil,
            vkNetto: Double? = nil,
            attribute: [String: String] = [:]
        ) {
            self.id = id
            self.source = source
            self.artikelRecordID = artikelRecordID
            self.bezeichnung = bezeichnung
            self.artikelnummer = artikelnummer
            self.menge = menge
            self.ekNetto = ekNetto
            self.vkNetto = vkNetto
            self.attribute = attribute
        }

        /// Konvertiert zu WarenkorbItem für CartStore. Trägt die vollen Zusatzfelder mit,
        /// damit beim Checkout nichts abgeschnitten wird.
        public var warenkorbItem: WarenkorbItem {
            WarenkorbItem(
                artikelRecordID: artikelRecordID,
                bezeichnung: bezeichnung,
                artikelnummer: artikelnummer,
                menge: menge,
                ekNetto: ekNetto,
                vkNetto: vkNetto,
                quelle: source,
                attribute: attribute
            )
        }

        /// Konvertiert zu DevBasketExportPosition (Dev-Checkout-Exporter, lokal-only).
        public var devExportPosition: DevBasketExportPosition {
            DevBasketExportPosition(
                quelle: source,
                bezeichnung: bezeichnung,
                artikelnummer: artikelnummer,
                menge: menge,
                ekNetto: ekNetto,
                vkNetto: vkNetto
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

    /// Angebots-/Rechnungs-Beleg (Task A, Dev-Checkout-Exporter) hinzufügen (oder Menge
    /// erhöhen). `eingehend` steuert das source-Präfix — Angebote haben kein EK/VK
    /// (keine erfundenen Zahlen), Artikelnummer ist die Belegnummer oder der Dateiname.
    public func addAngebot(
        fileID: String,
        bezeichnung: String,
        belegNummer: String?,
        eingehend: Bool
    ) {
        let quelle = eingehend ? "angebot-eingehend" : "angebot-ausgehend"
        let posID = "\(quelle)-\(fileID)"
        if let idx = positionen.firstIndex(where: { $0.id == posID }) {
            positionen[idx].menge += 1
        } else {
            positionen.append(Position(
                id: posID,
                source: quelle,
                artikelRecordID: nil,
                bezeichnung: bezeichnung,
                artikelnummer: belegNummer ?? fileID,
                menge: 1,
                ekNetto: nil,
                vkNetto: nil
            ))
        }
    }

    /// Aus einem `WarenkorbItem` (z. B. wiederhergestellt aus JSON) eine Position anlegen.
    /// Bestehende Positionen mit gleicher Artikelnummer bekommen die Menge addiert.
    public func addWarenkorbItem(_ item: WarenkorbItem) {
        let posID = "\(item.quelle)-\(item.artikelnummer)"
        if let idx = positionen.firstIndex(where: { $0.id == posID }) {
            positionen[idx].menge += item.menge
        } else {
            positionen.append(Position(
                id: posID,
                source: item.quelle,
                artikelRecordID: item.artikelRecordID,
                bezeichnung: item.bezeichnung,
                artikelnummer: item.artikelnummer,
                menge: item.menge,
                ekNetto: item.ekNetto,
                vkNetto: item.vkNetto,
                attribute: item.attribute
            ))
        }
    }

    /// Eine aus einem Angebots-PDF herausgelöste Position (PDF-Positions v1) in den
    /// Warenkorb übernehmen — mit VOLLER Daten-Fidelität (Johannes-Grundsatz, EISERN):
    /// Menge, EK/VK, Kategorie, Originaltext, Seite, Status/Konfidenz, Quell-PDF und die
    /// eindeutige Positions-ID wandern über `attribute` mit. Gleiche `objektID` →
    /// idempotent Menge erhöhen (statt Duplikat), analog zum WorkBasketStore-Pfad.
    ///
    /// `eingehend` steuert, ob der Preis EK (eingehendes Angebot) oder VK (ausgehend) ist
    /// — es werden keine Zahlen erfunden, das jeweils andere Feld bleibt `nil`.
    public func addPosition(
        objektID: String,
        bezeichnung: String,
        menge: Int,
        preisNetto: Double?,
        eingehend: Bool,
        attribute: [String: String]
    ) {
        let quelle = eingehend ? "angebot-eingehend" : "angebot-ausgehend"
        let posID = "\(quelle)-\(objektID)"
        if let idx = positionen.firstIndex(where: { $0.id == posID }) {
            positionen[idx].menge += max(1, menge)
        } else {
            positionen.append(Position(
                id: posID,
                source: quelle,
                artikelRecordID: nil,
                bezeichnung: bezeichnung,
                artikelnummer: attribute["artikelnummer"] ?? objektID,
                menge: max(1, menge),
                ekNetto: eingehend ? preisNetto : nil,
                vkNetto: eingehend ? nil : preisNetto,
                attribute: attribute
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
