import Foundation

// MARK: - AllPlansCollector (Zeichnungs-/Planstand-Katalog, global)
//
// Sammelt die Schema-Ordner-Dateien (Pläne/Werkszeichnungen/Renderings/…)
// ALLER übergebenen Projekte in EINE flache Liste — baugleich zum bewährten
// `AllOffersCollector` (eine Quelle der Wahrheit pro Projekt: `PlanCollector`).
// Read-only.
//
// Robustheit (wie beim Vorbild):
//  • Pro-Projekt-Fehler werden übersprungen (`projectsFailed`), killen nicht alles.
//  • `GoogleDriveError.notConnected` = globales Auth-Problem → durchgereicht,
//    damit die UI `permissionRequired` zeigt.
//  • Nebenläufigkeit begrenzt (`maxConcurrent`), schont das Drive-Rate-Limit.
//
// Reine Logik in MykilosServices → echt testbar mit Fake-`GoogleDriveFetching`.
public enum AllPlansCollector {

    /// Wiederverwendete leichtgewichtige Projekt-Referenz des Angebote-Vorbilds.
    public typealias ProjectRef = AllOffersCollector.ProjectRef

    /// Eine Plan-Datei mit Projekt-Kontext + Kategorie — die Zeile der globalen Liste.
    public struct AggregatedPlan: Identifiable, Sendable, Equatable {
        public let projectNumber: String
        public let projectTitle: String
        public let projectFolderID: String
        public let category: PlanCategory
        public let file: GoogleDriveFile

        public var id: String { "\(projectNumber)|\(category.rawValue)|\(file.id)" }

        public init(projectNumber: String, projectTitle: String, projectFolderID: String,
                    category: PlanCategory, file: GoogleDriveFile) {
            self.projectNumber = projectNumber
            self.projectTitle = projectTitle
            self.projectFolderID = projectFolderID
            self.category = category
            self.file = file
        }
    }

    public struct Outcome: Sendable, Equatable {
        public let plans: [AggregatedPlan]
        public let projectsScanned: Int
        public let projectsFailed: Int
        public init(plans: [AggregatedPlan], projectsScanned: Int, projectsFailed: Int) {
            self.plans = plans
            self.projectsScanned = projectsScanned
            self.projectsFailed = projectsFailed
        }
    }

    private enum ProjectResult: Sendable {
        case ok([AggregatedPlan])
        case failed
    }

    /// Sammelt nebenläufig (begrenzt) die Plan-Dateien aller Projekte.
    /// Nur Kategorien mit `inGlobalKatalog == true` landen im globalen Bestand
    /// (Präsentationsmaterial bleibt dem Material-Tab vorbehalten).
    /// `onProgress(done, total)` wird seriell nach jedem fertigen Projekt gerufen.
    public static func collectAll(
        projects: [ProjectRef],
        client: GoogleDriveFetching,
        maxConcurrent: Int = 5,
        maxDepth: Int = PlanCollector.maxDepthDefault,
        onProgress: (@Sendable (Int, Int) -> Void)? = nil
    ) async throws -> Outcome {
        guard projects.isEmpty == false else {
            return Outcome(plans: [], projectsScanned: 0, projectsFailed: 0)
        }
        let total = projects.count
        let window = max(1, maxConcurrent)

        var plans: [AggregatedPlan] = []
        var scanned = 0
        var failed = 0

        try await withThrowingTaskGroup(of: ProjectResult.self) { group in
            var iterator = projects.makeIterator()
            var inFlight = 0

            for _ in 0..<window {
                guard let ref = iterator.next() else { break }
                group.addTask { try await scanProject(ref, client: client, maxDepth: maxDepth) }
                inFlight += 1
            }

            while inFlight > 0 {
                let result = try await group.next()!   // reicht notConnected durch
                inFlight -= 1
                scanned += 1
                switch result {
                case .ok(let p): plans.append(contentsOf: p)
                case .failed:    failed += 1
                }
                onProgress?(scanned, total)
                if let ref = iterator.next() {
                    group.addTask { try await scanProject(ref, client: client, maxDepth: maxDepth) }
                    inFlight += 1
                }
            }
        }

        return Outcome(plans: plans, projectsScanned: scanned, projectsFailed: failed)
    }

    private static func scanProject(
        _ ref: ProjectRef, client: GoogleDriveFetching, maxDepth: Int
    ) async throws -> ProjectResult {
        do {
            let result = try await PlanCollector.load(
                rootFolderID: ref.driveFolderID, client: client, maxDepth: maxDepth)
            var plans: [AggregatedPlan] = []
            for (category, files) in result.filesByCategory where category.inGlobalKatalog {
                plans.append(contentsOf: files.map {
                    AggregatedPlan(projectNumber: ref.projectNumber, projectTitle: ref.title,
                                   projectFolderID: ref.driveFolderID, category: category, file: $0)
                })
            }
            return .ok(plans)
        } catch GoogleDriveError.notConnected {
            throw GoogleDriveError.notConnected   // globales Auth-Problem → hoch
        } catch {
            return .failed                          // transient/Ordner fehlt → überspringen
        }
    }
}

// MARK: - AllPlansSort + AllPlansSorter (testbare Sortier-/Filterlogik)
public enum AllPlansSort: String, CaseIterable, Sendable {
    case datum, projekt, kategorie, name
}

public enum AllPlansSorter {
    public typealias Plan = AllPlansCollector.AggregatedPlan

    /// Kategorie-Filter. `nil` = keine Einschränkung.
    public static func filtered(_ plans: [Plan], category: PlanCategory?) -> [Plan] {
        guard let category else { return plans }
        return plans.filter { $0.category == category }
    }

    /// Volltext-Filter über Dateiname und Projekt-Titel/-Nummer.
    public static func filtered(_ plans: [Plan], query: String) -> [Plan] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.isEmpty == false else { return plans }
        return plans.filter {
            $0.file.name.localizedCaseInsensitiveContains(q)
                || $0.projectTitle.localizedCaseInsensitiveContains(q)
                || $0.projectNumber.localizedCaseInsensitiveContains(q)
        }
    }

    public static func sorted(_ plans: [Plan], by sort: AllPlansSort) -> [Plan] {
        switch sort {
        case .datum:
            return plans.sorted {
                ($0.file.modifiedAt ?? .distantPast) > ($1.file.modifiedAt ?? .distantPast)
            }
        case .name:
            return plans.sorted {
                $0.file.name.localizedCaseInsensitiveCompare($1.file.name) == .orderedAscending
            }
        case .projekt:
            return plans.sorted {
                $0.projectNumber == $1.projectNumber
                    ? $0.file.name.localizedCaseInsensitiveCompare($1.file.name) == .orderedAscending
                    : $0.projectNumber.localizedStandardCompare($1.projectNumber) == .orderedAscending
            }
        case .kategorie:
            return plans.sorted {
                $0.category == $1.category
                    ? $0.file.name.localizedCaseInsensitiveCompare($1.file.name) == .orderedAscending
                    : categoryRank($0.category) < categoryRank($1.category)
            }
        }
    }

    /// Anzeige-Reihenfolge der Kategorien = Deklarationsreihenfolge im Enum.
    private static func categoryRank(_ category: PlanCategory) -> Int {
        PlanCategory.allCases.firstIndex(of: category) ?? .max
    }
}
