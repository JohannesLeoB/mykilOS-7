import Foundation

// MARK: - PlanTypeFilter (Datei-Typ-Filter über Plan-/Material-Ansichten)
//
// Gemeinsamer, reiner Datei-Typ-Filter ("nur PDFs" / "nur Bilder") für JEDE
// Sammlungs-Ansicht der Zeichnungs-/Plan-Familie (globaler Katalog + Material-Tab).
// Bewusst in Services (kein SwiftUI) → testbar, von beiden Views geteilt.
// Anzeige-Beschriftung (`label`/`icon`) hängt als View-seitige Extension im App-Target.
public enum PlanTypeFilter: String, CaseIterable, Sendable {
    case pdf, bild

    /// Ob eine Datei zum Typ-Filter passt. `pdf` = echtes PDF (Endung oder MIME),
    /// `bild` = gängige Rasterformate (aber nie PDF).
    public func matches(_ file: GoogleDriveFile) -> Bool {
        let ext = (file.name as NSString).pathExtension.lowercased()
        switch self {
        case .pdf:
            return ext == "pdf" || file.mimeType == "application/pdf"
        case .bild:
            return ext != "pdf" && (file.mimeType.hasPrefix("image/")
                || ["jpg", "jpeg", "png", "heic", "heif", "tiff", "tif", "webp"].contains(ext))
        }
    }
}

// MARK: - MaterialSort + MaterialSorter (Ein-Projekt-Dateiliste, testbar)
//
// Sortier-/Filterlogik für den Projekt-Material-Tab. Anders als `AllPlansSorter`
// (global, über Projekte) arbeitet das hier auf einer flachen `[GoogleDriveFile]`
// EINES Projekts — deshalb nur Datum/Name als Sortierung (Projekt/Kategorie sind
// im Projekt-Kontext bedeutungslos bzw. bilden die Spalten-Achse).
public enum MaterialSort: String, CaseIterable, Sendable {
    case datum, name
}

public enum MaterialSorter {

    /// Volltext-Filter über den Dateinamen. Leere Query = keine Einschränkung.
    public static func filtered(_ files: [GoogleDriveFile], query: String) -> [GoogleDriveFile] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.isEmpty == false else { return files }
        return files.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    /// Datei-Typ-Filter. `nil` = alle Typen.
    public static func filtered(_ files: [GoogleDriveFile], type: PlanTypeFilter?) -> [GoogleDriveFile] {
        guard let type else { return files }
        return files.filter { type.matches($0) }
    }

    public static func sorted(_ files: [GoogleDriveFile], by sort: MaterialSort) -> [GoogleDriveFile] {
        switch sort {
        case .datum:
            return files.sorted {
                ($0.modifiedAt ?? .distantPast) > ($1.modifiedAt ?? .distantPast)
            }
        case .name:
            return files.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
    }
}
