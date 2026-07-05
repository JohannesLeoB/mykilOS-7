import Foundation

/// Ein Projekt aus der mykilOS-Registry (Graph, siehe System-Matrix §3).
/// Bewusst additiv/tolerant dekodiert — Milchstraßen-Prinzip: neue Felder
/// dürfen jederzeit dazukommen, ohne bestehende Rundgänge zu brechen.
struct Project: Identifiable, Codable, Hashable {
    var id: String { projectNumber }

    let projectNumber: String
    let title: String
    let kind: String
    let customerNumber: String
    let driveFolderID: String

    // MARK: - Mothership-Antenne (optional, vom Schiff geliefert)
    //
    // Diese Felder fuellt der Satellit NICHT selbst — sie kommen aus dem
    // Registry-Schnappschuss (`projekte.json`), sobald die Mothership sie
    // exportiert. Alle optional: bestehende Schnappschuesse ohne diese
    // Schluessel dekodieren weiter (synthetisierter Decoder -> nil).
    // Format-Vertrag: docs/23_MOTHERSHIP_ANTENNE.md.

    /// Klartext-Art, falls das Schiff sie liefert (sonst aus `kind` abgeleitet).
    var art: String?
    /// Auftragsvolumen / Budget netto in Euro.
    var volumen: Double?
    /// Letztes Angebot / letzte AB als fertiger Anzeigetext
    /// (z. B. "AB-2026-015 vom 12.06. - 42.500 EUR").
    var letztesAngebot: String?
    /// Geraete-/Artikelliste aus dem Projekt-Warenkorb.
    var warenkorb: [WarenkorbPosition]?

    /// Deep-Link auf den echten Drive-Ordner — Springen, nicht rendern (05_DEEPLINK_MATRIX).
    var driveURL: URL? {
        URL(string: "https://drive.google.com/drive/folders/\(driveFolderID)")
    }

    var volumenText: String? {
        guard let volumen else { return nil }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        let zahl = f.string(from: NSNumber(value: volumen)) ?? "\(Int(volumen))"
        return "\(zahl) EUR"
    }
}

/// Eine Position im Projekt-Warenkorb — Geraet oder Artikel. Kommt vom
/// Schiff (WorkBasket), der Satellit zeigt sie nur an. `Hashable` fuer
/// stabile `ForEach(..., id: \.self)`-Nutzung ohne erfundene UUID.
struct WarenkorbPosition: Codable, Hashable {
    let name: String
    var artikelnummer: String?
    var menge: Int?
    var einzelpreis: Double?
    var kategorie: String?

    var untertitel: String? {
        var teile: [String] = []
        if let menge { teile.append("\(menge)x") }
        if let artikelnummer, !artikelnummer.isEmpty { teile.append(artikelnummer) }
        return teile.isEmpty ? nil : teile.joined(separator: " - ")
    }
}

/// Ein einzelner Drive-Unterordner-Sprung (z. B. „05 eingehende Angebote").
/// Aktuell nur für Schmidt live erhoben (Live-Beweis ①) — Platzhalter für
/// die generelle Kanon-Navigation (01 INFOS/02 CAD/03 PRÄSENTATION …).
struct DriveShortcut: Identifiable, Hashable {
    var id: String { folderID }
    let label: String
    let folderID: String

    var url: URL? {
        URL(string: "https://drive.google.com/drive/folders/\(folderID)")
    }
}

/// „Gerade heiß" — ein Projekt mit einem Aktivitäts-Zeitstempel aus Drive
/// (`modifiedTime`, siehe Star Map: Registry = Graph, Drive = Puls).
struct HotProject: Identifiable, Hashable {
    var id: String { project.id }
    let project: Project
    let movedAt: Date

    var relativeLabel: String {
        let hours = Date().timeIntervalSince(movedAt) / 3600
        if hours < 1 { return "gerade eben" }
        if hours < 24 { return "vor \(Int(hours)) Std" }
        return "vor \(Int(hours / 24)) Tg"
    }
}
