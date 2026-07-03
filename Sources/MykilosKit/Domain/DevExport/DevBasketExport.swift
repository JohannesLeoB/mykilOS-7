import Foundation

// MARK: - DevBasketExport (Dev-Checkout-Exporter — lokaler Sandbox-Export)
//
// Pragmatischer, LOCAL-ONLY Export-Schnappschuss eines Warenkorbs (session-lokal oder
// ein bereits gespeicherter `WarenkorbEintrag`), gedacht für Johannes' Live-Test von
// Checkout-Formen VOR der vollständigen Wirbelsäule-Pipeline (siehe docs/S10_WIRBELSAEULE.md).
//
// Bewusst KEIN Bestandteil der zukünftigen `CheckoutPort`/`WorkBasket`-Protokolle (C1) —
// eigenständiger, leichter Dev-Sandbox-Typ, der diese spätere Arbeit nicht blockiert.
// Foundation-only: kein SwiftUI, kein GRDB. `exportID` wird bei JEDEM Export frisch
// vergeben (nie wiederverwendet) — reine Nachvollziehbarkeit, kein Persistenz-Schlüssel.
public struct DevBasketExport: Codable, Sendable, Equatable {
    /// Frisch generierte UUID-Zeichenkette — pro Export neu, nie wiederverwendet.
    public let exportID: String
    public let erzeugtAm: Date
    /// "session" | "gespeicherter-warenkorb:<WarenkorbEintragID>"
    public let quelle: String
    public let bezeichnung: String?
    public let projekt: String?
    public let positionen: [DevBasketExportPosition]
    public let summeEKNetto: Double?
    public let summeVKNetto: Double?
    public let anzahlPositionen: Int

    public init(
        exportID: String = UUID().uuidString,
        erzeugtAm: Date = Date(),
        quelle: String,
        bezeichnung: String? = nil,
        projekt: String? = nil,
        positionen: [DevBasketExportPosition],
        summeEKNetto: Double? = nil,
        summeVKNetto: Double? = nil,
        anzahlPositionen: Int? = nil
    ) {
        self.exportID = exportID
        // Auf Millisekunden gerundet: ISO8601-mit-Sekundenbruchteilen kodiert nur bis
        // Millisekunden, `Date` selbst hat Sub-Millisekunden-Präzision. Ohne diese Rundung
        // im Init würde encode→decode nicht bitgenau zum Original zurückkommen (verletzt
        // die Cold-Start-Rundtrip-Regel aus CLAUDE.md).
        self.erzeugtAm = Date(timeIntervalSince1970: (erzeugtAm.timeIntervalSince1970 * 1000).rounded() / 1000)
        self.quelle = quelle
        self.bezeichnung = bezeichnung
        self.projekt = projekt
        self.positionen = positionen
        self.summeEKNetto = summeEKNetto
        self.summeVKNetto = summeVKNetto
        self.anzahlPositionen = anzahlPositionen ?? positionen.count
    }
}

// MARK: - DevBasketExportPosition
public struct DevBasketExportPosition: Codable, Sendable, Equatable {
    /// Herkunfts-String aus WarenkorbState.Position.source:
    /// "katalog" | "lager" | "angebot-eingehend" | "angebot-ausgehend"
    public let quelle: String
    public let bezeichnung: String
    public let artikelnummer: String?
    public let menge: Int
    public let ekNetto: Double?
    public let vkNetto: Double?

    public init(
        quelle: String,
        bezeichnung: String,
        artikelnummer: String? = nil,
        menge: Int,
        ekNetto: Double? = nil,
        vkNetto: Double? = nil
    ) {
        self.quelle = quelle
        self.bezeichnung = bezeichnung
        self.artikelnummer = artikelnummer
        self.menge = menge
        self.ekNetto = ekNetto
        self.vkNetto = vkNetto
    }
}

// MARK: - DevBasketExportError
public enum DevBasketExportError: Error, Sendable, Equatable {
    case serializationFailed
}

// MARK: - Pretty-JSON-Encoding (rein, testbar)
extension DevBasketExport {
    /// ISO8601 mit Sekundenbruchteilen — Standard-`.iso8601`-Strategie rundet auf ganze
    /// Sekunden, was den Encode→Decode-Rundtrip verlustbehaftet macht (Cold-Start-Prinzip:
    /// nur bitgenaue Rundtrips sind zulässig, siehe CLAUDE.md Persistenz-Regel).
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        enc.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(iso8601Formatter.string(from: date))
        }
        return enc
    }()

    private static let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = iso8601Formatter.date(from: string) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Ungültiges ISO8601-Datum: \(string)"
                )
            }
            return date
        }
        return dec
    }()

    /// Formatiertes JSON (sortierte Keys, ISO8601-Datum) — reine, deterministische Funktion.
    public func prettyJSON() throws -> String {
        let data = try Self.encoder.encode(self)
        guard let string = String(data: data, encoding: .utf8) else {
            throw DevBasketExportError.serializationFailed
        }
        return string
    }

    /// Rundtrip-Hilfsmethode (Tests + Vorschau-Diagnose).
    public static func decode(fromJSON json: String) throws -> DevBasketExport {
        guard let data = json.data(using: .utf8) else {
            throw DevBasketExportError.serializationFailed
        }
        return try decoder.decode(DevBasketExport.self, from: data)
    }
}

// MARK: - DevExportZiel (Port-Picker — bewusst leichtgewichtig, kein C1-CheckoutPort)
//
// Beide Fälle erzeugen aktuell dieselbe DevBasketExport-JSON-Form. Das
// sevDesk-Postbox-Format existiert nur als beschriftete Vorschau, damit Johannes die
// Form gegen das künftige echte Schema (docs/WARENKORB_CHECKOUT.md §5i) vergleichen kann —
// es schreibt NIRGENDS live.
public enum DevExportZiel: String, CaseIterable, Identifiable, Sendable {
    case sevdeskPostboxFormat = "sevDesk-Postbox-Format (lokal, Vorschau)"
    case freierExport = "Freier Export"
    public var id: String { rawValue }

    /// Kurzer Hinweistext, der auf dem Sheet sichtbar bleibt — keine stille Erwartungshaltung.
    public var vorschauHinweis: String {
        switch self {
        case .sevdeskPostboxFormat:
            "Vorschau — noch keine Live-Anbindung. Vergleicht die Form gegen das künftige sevDesk-Postbox-Schema."
        case .freierExport:
            "Vorschau — noch keine Live-Anbindung. Freies JSON ohne Ziel-Schema-Bindung."
        }
    }
}

// MARK: - DevExportModus (Output-Modus-Picker)
public enum DevExportModus: String, CaseIterable, Identifiable, Sendable {
    case zwischenablage = "Copy-Paste-Vorschau"
    case notiz = "Notiz"
    case zip = "ZIP-Export"
    public var id: String { rawValue }
}
