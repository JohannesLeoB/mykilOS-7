import Foundation
import Observation

/// Lädt den Projekt-Graphen (v0: gebündeltes JSON-Snapshot der Registry —
/// v1 wird das aus Airtable live synchronisieren, Schema bleibt gleich).
/// Reine Lesequelle: der Satellit schreibt hier nichts (Zwei-Tank-Doktrin).
@Observable
final class ProjectStore {
    private(set) var projects: [Project] = []
    private(set) var loadError: String?

    /// Live erhoben in Live-Beweis ① (Schmidt, 2026-016) — bewusst hartkodiert,
    /// bis die generelle Kanon-Navigation gebaut ist.
    let schmidtShortcuts: [DriveShortcut] = [
        DriveShortcut(label: "05 eingehende Angebote", folderID: "1WM5-IQrD12PTJWXm5pSCDroD5YvitSiL"),
        DriveShortcut(label: "07 Fragebogen", folderID: "1JbnYI7Grs55QmH0DOyZ6feqxNR0kGTLr"),
        DriveShortcut(label: "Präsentations-PDF", folderID: "1_ZPazAXYTxE3CyP7XVC4jP8JTgWYh7Fs"),
    ]

    /// Aus der Root-Peilung vom 03.07. spät — echte `modifiedTime`-Werte.
    /// v1 liest das live aus Drive; hier als eingefrorener Beweis-Schnappschuss.
    private let hotSnapshot: [(projectNumber: String, isoDate: String)] = [
        ("2026-038", "2026-07-03T09:48:23Z"),
        ("2026-037", "2026-07-03T08:42:15Z"),
        ("2024-007", "2026-07-03T00:30:08Z"),
        ("2026-026", "2026-07-02T11:07:11Z"),
        ("2026-020", "2026-07-02T11:04:48Z"),
        ("2025-021", "2026-07-01T22:25:34Z"),
    ]

    init() {
        load()
    }

    func load() {
        guard let url = Bundle.main.url(forResource: "projekte", withExtension: "json") else {
            loadError = "projekte.json fehlt im Bundle — Datei in Xcode hinzugefügt?"
            return
        }
        do {
            let data = try Data(contentsOf: url)
            projects = try JSONDecoder().decode([Project].self, from: data)
            loadError = nil
        } catch {
            loadError = "Registry nicht lesbar: \(error.localizedDescription)"
        }
    }

    /// „Gerade heiß" — Registry-Projekte, angereichert mit dem Drive-Puls-Schnappschuss.
    var hotProjects: [HotProject] {
        let formatter = ISO8601DateFormatter()
        let byNumber = Dictionary(uniqueKeysWithValues: projects.map { ($0.projectNumber, $0) })
        return hotSnapshot.compactMap { entry in
            guard let project = byNumber[entry.projectNumber],
                  let date = formatter.date(from: entry.isoDate) else { return nil }
            return HotProject(project: project, movedAt: date)
        }
        .sorted { $0.movedAt > $1.movedAt }
    }

    func matching(_ query: String) -> [Project] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return projects }
        return projects.filter {
            $0.title.lowercased().contains(q) || $0.projectNumber.contains(q)
        }
    }
}
