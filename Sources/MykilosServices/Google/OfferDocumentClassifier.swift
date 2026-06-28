import Foundation

// MARK: - OfferDocumentType
// Die Dokumenttypen, die im Angebote-Tab gruppiert angezeigt werden.
// Reihenfolge = Anzeigereihenfolge (rawValue als sortIndex).
public enum OfferDocumentType: Int, CaseIterable, Sendable {
    // Ausgehend (04 ausgehende Angebote)
    case angebot          = 0   // AN — unser Angebot an den Kunden
    case auftrag          = 1   // AB — Auftragsbestätigung
    case abschlagsrechnung = 2  // TR / ARE — Teil-/Abschlagsrechnung
    case schlussrechnung  = 3   // SR — Schlussrechnung
    // Eingehend (05 eingehende Angebote)
    case eingehendesAngebot = 4 // Lieferanten-Angebot (oft rein numerisch)
    case bestellung       = 5   // aus Unterordner "Bestellungen"
    // Fallback
    case sonstiges        = 99

    public var label: String {
        switch self {
        case .angebot:            "Angebote"
        case .auftrag:            "Aufträge"
        case .abschlagsrechnung:  "Abschlagsrechnungen"
        case .schlussrechnung:    "Schlussrechnungen"
        case .eingehendesAngebot: "Eingehende Angebote"
        case .bestellung:         "Bestellungen"
        case .sonstiges:          "Sonstige Dokumente"
        }
    }
}

// MARK: - ClassifiedOffer
// Ein Beleg mit erkanntem Typ + extrahierten Metadaten aus dem Dateinamen.
public struct ClassifiedOffer: Identifiable, Sendable, Equatable {
    public var file: GoogleDriveFile
    public var type: OfferDocumentType
    public var belegNummer: String?     // z.B. "2026-0151"
    public var kundenNummer: String?    // z.B. "12822"
    public var version: String?         // z.B. "v3"

    public var id: String { file.id }

    public init(file: GoogleDriveFile, type: OfferDocumentType,
                belegNummer: String? = nil, kundenNummer: String? = nil, version: String? = nil) {
        self.file = file
        self.type = type
        self.belegNummer = belegNummer
        self.kundenNummer = kundenNummer
        self.version = version
    }
}

// MARK: - OfferDocumentClassifier
// Klassifiziert einen Beleg anhand seines Dateinamen-Präfixes.
//
// Schema (aus realen MYKILOS-Dateinamen, Stand 2026-06):
//   AN-A_2026-0151-Kdnr-12822_v3.pdf   → Präfix "AN"  → Angebot
//   SR-SR_2026-0170-Kdnr-12822.pdf     → Präfix "SR"  → Schlussrechnung
//   TR-ARE_2026-0123-Kdnr-12822.pdf    → Präfix "TR"  → Abschlagsrechnung
//   202603971.pdf (rein numerisch)     → Eingehendes Lieferanten-Angebot
//
// Das Präfix-Lexikon ist datengetrieben — neue Präfixe einfach hier ergänzen.
// ⚠️ "TR"/"ARE" und "AB" sind Annahmen — beim Live-Test bestätigen/korrigieren.
public enum OfferDocumentClassifier {

    // Präfix (Großbuchstaben) → Typ. Erste Token des Dateinamens vor "-" oder "_".
    static let prefixLexicon: [String: OfferDocumentType] = [
        "AN":  .angebot,
        "AB":  .auftrag,            // ⚠️ Annahme: Auftragsbestätigung
        "TR":  .abschlagsrechnung,  // ⚠️ Annahme: Teil-/Abschlagsrechnung (TR-ARE)
        "ARE": .abschlagsrechnung,
        "SR":  .schlussrechnung,
        "BE":  .bestellung,
        "BS":  .bestellung,
    ]

    /// Klassifiziert einen Beleg. `isIncoming` = Datei stammt aus "05 eingehende Angebote".
    /// `folderName` = Name des unmittelbaren Eltern-Unterordners (z.B. "Rechnung",
    /// "Angebot", "Auftrag", "Bestellungen"). Dieser ist das SICHERSTE Signal —
    /// vom Team selbst angelegt — und hat Vorrang vor der Präfix-Vermutung.
    public static func classify(
        _ file: GoogleDriveFile,
        isIncoming: Bool,
        folderName: String? = nil
    ) -> ClassifiedOffer {
        let prefix = extractPrefix(from: file.name)
        let belegNummer = extractBelegNummer(from: file.name)
        let kundenNummer = extractKundenNummer(from: file.name)
        let version = extractVersion(from: file.name)
        let folder = (folderName ?? "").lowercased()

        let type = resolveType(isIncoming: isIncoming, folder: folder, prefix: prefix)
        return ClassifiedOffer(file: file, type: type,
                               belegNummer: belegNummer, kundenNummer: kundenNummer, version: version)
    }

    // Sichere Zuordnung: Unterordner-Name (#2) zuerst, Präfix (#4) nur zur
    // Verfeinerung. Erst wenn beide nichts liefern → .sonstiges.
    static func resolveType(isIncoming: Bool, folder: String, prefix: String) -> OfferDocumentType {
        if isIncoming {
            // Eingehend: "Bestellungen"-Ordner ist sicher; sonst Lieferanten-Angebot.
            if folder.contains("bestell") { return .bestellung }
            if prefixLexicon[prefix] == .bestellung { return .bestellung }
            return .eingehendesAngebot
        }

        // Ausgehend: Unterordner-Name ist team-kontrolliert → höchste Sicherheit.
        if folder.contains("rechnung") {
            // Innerhalb "Rechnung" verfeinert das Präfix Schluss- vs. Abschlagsrechnung.
            switch prefix {
            case "SR": return .schlussrechnung
            case "TR", "ARE": return .abschlagsrechnung
            default:   return .schlussrechnung   // Standard-Rechnung
            }
        }
        if folder.contains("angebot") { return .angebot }
        if folder.contains("auftrag") { return .auftrag }

        // Kein Unterordner-Hinweis (Datei liegt direkt in 04) → Präfix entscheidet.
        return prefixLexicon[prefix] ?? .sonstiges
    }

    // MARK: - Extraktion (rein, testbar)

    /// Erstes Token in Großbuchstaben vor "-" oder "_". "AN-A_…" → "AN".
    static func extractPrefix(from name: String) -> String {
        let base = name.split(separator: ".").first.map(String.init) ?? name
        // Trenne am ersten "-" oder "_"
        let firstToken = base.prefix { $0 != "-" && $0 != "_" }
        return String(firstToken).uppercased()
    }

    /// Belegnummer im Format JJJJ-NNNN (z.B. "2026-0151").
    /// Kein \b: "_" gilt in Regex als Wort-Zeichen, daher matcht \b nicht an "_2026".
    static func extractBelegNummer(from name: String) -> String? {
        firstMatch(in: name, pattern: #"(\d{4}-\d{3,4})(?!\d)"#)
    }

    /// Kundennummer nach "Kdnr-" (z.B. "Kdnr-12822" → "12822").
    static func extractKundenNummer(from name: String) -> String? {
        firstMatch(in: name, pattern: #"Kdnr-(\d+)"#, group: 1)
    }

    /// Version "_v3" → "v3".
    static func extractVersion(from name: String) -> String? {
        firstMatch(in: name, pattern: #"_(v\d+)"#, group: 1)
    }

    private static func firstMatch(in text: String, pattern: String, group: Int = 1) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > group,
              let r = Range(match.range(at: group), in: text) else { return nil }
        return String(text[r])
    }
}
