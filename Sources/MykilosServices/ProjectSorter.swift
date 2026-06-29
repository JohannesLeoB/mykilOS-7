import Foundation
import MykilosKit

// MARK: - ProjectSort (S21)
// Sortier-Modi der Projektgalerie. `eigene` = frei per Drag&Drop. Reine Domain-Logik
// in Services, damit testbar (App-Target hat kein Test-Target). UI-Labels/Icons
// liegen als Extension im App-Layer.
public enum ProjectSort: String, CaseIterable, Sendable {
    case nummer, name, datum, kategorie, eigene
}

public enum ProjectSorter {
    /// Komma-getrennte projectNumber-Liste → Array (für die Eigene-Reihenfolge).
    public static func parseOrder(_ raw: String) -> [String] {
        raw.split(separator: ",").map(String.init).filter { $0.isEmpty == false }
    }

    /// Sortiert Projekte nach dem gewählten Modus. `customOrder` greift nur bei `.eigene`.
    public static func sorted(_ projects: [Project], by sort: ProjectSort, customOrder: [String]) -> [Project] {
        switch sort {
        case .name:
            return projects.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .nummer:
            return projects.sorted { $0.projectNumber.localizedStandardCompare($1.projectNumber) == .orderedAscending }
        case .datum:
            return projects.sorted { $0.updatedAt > $1.updatedAt }   // neueste zuerst
        case .kategorie:
            return projects.sorted {
                $0.kind.rawValue == $1.kind.rawValue
                    ? $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                    : $0.kind.rawValue < $1.kind.rawValue
            }
        case .eigene:
            // Gespeicherte Reihenfolge zuerst (in dieser Folge), Rest hinten nach Nummer.
            let rank = Dictionary(uniqueKeysWithValues: customOrder.enumerated().map { ($1, $0) })
            return projects.sorted { a, b in
                let ra = rank[a.projectNumber], rb = rank[b.projectNumber]
                switch (ra, rb) {
                case let (x?, y?): return x < y
                case (_?, nil):    return true
                case (nil, _?):    return false
                case (nil, nil):   return a.projectNumber.localizedStandardCompare(b.projectNumber) == .orderedAscending
                }
            }
        }
    }
}
