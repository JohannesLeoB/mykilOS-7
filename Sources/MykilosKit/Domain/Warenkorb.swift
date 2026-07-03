import Foundation
import CryptoKit

// MARK: - WarenkorbItem
// Eine Position im Warenkorb. Foundation-only — kein SwiftUI, kein GRDB.
// Entspricht einer Zeile in Airtable-Tabelle "Warenkörbe" (Positionen-JSON).
public struct WarenkorbItem: Codable, Sendable, Equatable, Identifiable {
    /// Optionale Airtable-Record-ID des Artikels (für Projektartikel-Link).
    public let artikelRecordID: String?
    /// Bezeichnung des Artikels (Pflichtfeld, sichtbar in der UI).
    public let bezeichnung: String
    /// Artikelnummer (z. B. Lieferantencode, Bestellnummer).
    public let artikelnummer: String
    /// Bestellmenge.
    public let menge: Int
    /// Einkaufspreis netto (optional, falls noch nicht bekannt).
    public let ekNetto: Double?
    /// Verkaufspreis netto (optional, falls noch nicht kalkuliert).
    public let vkNetto: Double?
    /// Herkunft der Position: "manuell", "katalog", "kalkulation", etc.
    public let quelle: String

    public var id: String { "\(artikelnummer)-\(menge)-\(bezeichnung)" }

    /// Konvertiert zu DevBasketExportPosition (Dev-Checkout-Exporter, lokal-only,
    /// siehe Sources/MykilosKit/Domain/DevExport/DevBasketExport.swift).
    public var devExportPosition: DevBasketExportPosition {
        DevBasketExportPosition(
            quelle: quelle,
            bezeichnung: bezeichnung,
            artikelnummer: artikelnummer,
            menge: menge,
            ekNetto: ekNetto,
            vkNetto: vkNetto
        )
    }

    public init(
        artikelRecordID: String? = nil,
        bezeichnung: String,
        artikelnummer: String,
        menge: Int,
        ekNetto: Double? = nil,
        vkNetto: Double? = nil,
        quelle: String
    ) {
        self.artikelRecordID = artikelRecordID
        self.bezeichnung = bezeichnung
        self.artikelnummer = artikelnummer
        self.menge = menge
        self.ekNetto = ekNetto
        self.vkNetto = vkNetto
        self.quelle = quelle
    }
}

// MARK: - Warenkorb
// Aggregat aller Positionen für ein optionales Projekt.
// Prüfsumme dient als stabiler Bezeichner über Versionen hinweg.
public struct Warenkorb: Sendable, Equatable {
    /// Positionen — append-only, nie direkt überschreiben.
    public let items: [WarenkorbItem]
    /// Optionale Airtable-Record-ID des verknüpften Projekts.
    public let projektRecordID: String?
    /// Menschenlesbarer Projektname (für Airtable-Bezeichnung-Feld).
    public let projektName: String?

    public init(
        items: [WarenkorbItem],
        projektRecordID: String? = nil,
        projektName: String? = nil
    ) {
        self.items = items
        self.projektRecordID = projektRecordID
        self.projektName = projektName
    }

    // MARK: - Berechnete Summen

    /// Gesamtsumme EK netto aller Positionen (Menge × ekNetto).
    public var gesamtEKNetto: Double {
        items.reduce(0.0) { sum, item in
            sum + (item.ekNetto ?? 0.0) * Double(item.menge)
        }
    }

    /// Gesamtsumme VK netto aller Positionen (Menge × vkNetto).
    public var gesamtVKNetto: Double {
        items.reduce(0.0) { sum, item in
            sum + (item.vkNetto ?? 0.0) * Double(item.menge)
        }
    }

    // MARK: - Prüfsumme

    /// Stabile Prüfsumme (SHA256) über sortierte Items + optionalen Projektnamen.
    ///
    /// Zweck: Identifiziert diesen Warenkorb inhaltlich über Versionen hinweg.
    /// Gleiche Prüfsumme = gleicher Inhalt → alte Version → Archiviert setzen.
    ///
    /// Input: sortierte Artikelnummern + Mengen + Bezeichnungen + projektName (falls vorhanden).
    /// Reine, deterministische Funktion — kein Datum, keine UUID.
    public var pruefsumme: String {
        let sortedItems = items.sorted {
            if $0.artikelnummer != $1.artikelnummer { return $0.artikelnummer < $1.artikelnummer }
            return $0.bezeichnung < $1.bezeichnung
        }
        let itemStrings = sortedItems.map { "\($0.artikelnummer):\($0.menge):\($0.bezeichnung)" }
        var input = itemStrings.joined(separator: "|")
        if let name = projektName { input += "@" + name }
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
