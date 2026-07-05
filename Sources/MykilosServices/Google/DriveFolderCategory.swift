import Foundation

// MARK: - DriveFolderCategory (D3 — Parent-Ordner-Herkunft)
//
// Leichte, testbare Klassifikation eines Datei-Eltern-Ordnernamens auf eine
// grobe Herkunfts-Kategorie. Rein für die Sichtbarmachung der Ordner-Herkunft
// je Datei in der Dateien-Ansicht („Farbe ist Sprache") — KEINE Persistenz,
// KEIN Schreibvorgang, kein Ersatz für den Zeichnungs-/Angebote-Katalog.
//
// Baugleich zur tolerant-faltenden Erkennung in `PlanCollector`/`OffersCollector`
// (Diakritik-/Groß-Klein-unabhängig, Substring). Ein Ordnername bekommt maximal
// EINE Kategorie (erster Treffer in `matchOrder` gewinnt). Kein Treffer → `nil`
// (die UI zeigt dann keinen Farbpunkt, keine Sackgasse).
//
// Farbzuordnung selbst lebt in der Widget-/Design-Schicht (MykColor), NICHT hier
// — MykilosServices importiert bewusst kein SwiftUI/MykilosDesign.
public enum DriveFolderCategory: String, CaseIterable, Sendable, Identifiable, Hashable {
    case angebote       // Angebote / Rechnungen        → cash (Tiefblau)
    case zeichnungen    // Pläne / Werkszeichnung / CAD  → drive (Terrakotta)
    case praesentation  // Präsentation / Renderings     → people (Salbei)
    case infos          // Infos / Schriftverkehr        → tasks (Ocker)

    public var id: String { rawValue }

    /// Kurzes VERSAL-Label für den Herkunfts-Chip.
    public var chipLabel: String {
        switch self {
        case .angebote:      "ANGEBOTE"
        case .zeichnungen:   "ZEICHNUNGEN"
        case .praesentation: "PRÄSENTATION"
        case .infos:         "INFOS"
        }
    }

    /// Erkennungs-Schlüsselwörter — bereits diakritik-gefaltet + kleingeschrieben
    /// (Vergleich läuft über `folded(_:)`), plus ASCII-Transliteration der Umlaut-
    /// Formen ("praesentation"), die die Faltung nicht auf die Umlaut-Form reduziert.
    var keywords: [String] {
        switch self {
        case .angebote:      ["angebot", "rechnung", "kostenvoranschlag", "offer", "invoice"]
        case .zeichnungen:   ["plan", "plane", "plaene", "werkszeichnung", "werkzeichnung",
                              "zeichnung", "cad", "layout"]
        case .praesentation: ["prasentation", "praesentation", "presentation",
                              "rendering", "moodboard", "moodbord"]
        case .infos:         ["info", "schriftverkehr", "korrespondenz", "vorplanung"]
        }
    }

    /// Prüf-Reihenfolge: spezifischste Signale zuerst. "info" ist das generischste
    /// Substring-Signal und wird zuletzt geprüft, damit ein „01 INFOS/Angebote"-
    /// Ordner zuerst als Angebote erkannt wird.
    static let matchOrder: [DriveFolderCategory] = [
        .angebote, .zeichnungen, .praesentation, .infos
    ]

    /// Diakritik- und Groß/Klein-unabhängige Faltung ("PLÄNE" → "plane").
    static func folded(_ name: String) -> String {
        name.folding(options: [.diacriticInsensitive, .caseInsensitive],
                     locale: Locale(identifier: "de_DE"))
    }

    /// Ordnet einen Ordnernamen maximal EINER Kategorie zu. `nil` = keine bekannte
    /// Herkunftskategorie (die UI zeigt dann keinen Farbpunkt).
    public static func category(forFolderName name: String?) -> DriveFolderCategory? {
        guard let name, name.isEmpty == false else { return nil }
        let folded = folded(name)
        for candidate in matchOrder
        where candidate.keywords.contains(where: { folded.contains($0) }) {
            return candidate
        }
        return nil
    }
}
