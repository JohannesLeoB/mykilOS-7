import Testing
import Foundation
@testable import MykilosServices

// MARK: - AllPlansCollectorTests (globale Plan-Aggregation)
// Testet die nebenläufige Aggregations-Logik gegen Fake-Drive-Clients:
// Aggregation über mehrere Projekte, Pro-Projekt-Fehler überspringen,
// notConnected durchreichen, Präsentations-Ausschluss im globalen Bestand,
// stabile IDs sowie Sortier-/Filterlogik.

struct AllPlansCollectorTests {

    @Test func aggregiertKategorienUeberMehrereProjekte() async throws {
        let client = PlansMultiFakeClient(tree: [
            // Projekt A: Pläne unter 01 INFOS + Renderings direkt
            "A":        [folder("01 INFOS", "A_infos"), folder("Renderings", "A_rend")],
            "A_infos":  [folder("01 Pläne", "A_plaene")],
            "A_plaene": [pdf("Grundriss.pdf", "A_f1")],
            "A_rend":   [image("Kueche_final.jpg", "A_f2")],
            // Projekt B: nur Werkszeichnung
            "B":        [folder("08 Werkszeichnung", "B_wz")],
            "B_wz":     [pdf("Detail_Insel.pdf", "B_f1")],
        ])

        let outcome = try await AllPlansCollector.collectAll(
            projects: [
                .init(projectNumber: "2026-001", title: "Alpha", driveFolderID: "A"),
                .init(projectNumber: "2026-002", title: "Beta", driveFolderID: "B"),
            ],
            client: client)

        #expect(outcome.projectsScanned == 2)
        #expect(outcome.projectsFailed == 0)
        #expect(outcome.plans.count == 3)

        let alpha = outcome.plans.filter { $0.projectNumber == "2026-001" }
        #expect(alpha.contains { $0.category == .plaene && $0.file.name == "Grundriss.pdf" })
        #expect(alpha.contains { $0.category == .renderings })

        let beta = outcome.plans.filter { $0.projectNumber == "2026-002" }
        #expect(beta.count == 1)
        #expect(beta.first?.category == .werkszeichnung)
        #expect(beta.first?.projectTitle == "Beta")
    }

    // Präsentationsmaterial gehört in den Material-Tab, NICHT in den globalen Katalog.
    @Test func praesentationBleibtAusGlobalemBestandDraussen() async throws {
        let client = PlansMultiFakeClient(tree: [
            "A":       [folder("03 PRÄSENTATION", "A_praes"), folder("Layouts", "A_lay")],
            "A_praes": [pdf("Moodboard.pdf", "A_f1")],
            "A_lay":   [pdf("Layout_EG.pdf", "A_f2")],
        ])
        let outcome = try await AllPlansCollector.collectAll(
            projects: [.init(projectNumber: "2026-001", title: "Alpha", driveFolderID: "A")],
            client: client)
        #expect(outcome.plans.count == 1)
        #expect(outcome.plans.first?.category == .layouts)
    }

    @Test func ueberspringtFehlerhaftesProjektOhneAbbruch() async throws {
        let client = PlansMultiFakeClient(
            tree: [
                "GOOD":  [folder("Renderings", "G_r")],
                "G_r":   [pdf("ok.pdf", "g1")],
            ],
            throwingTransient: ["BROKEN"])
        let outcome = try await AllPlansCollector.collectAll(
            projects: [
                .init(projectNumber: "2026-001", title: "Gut", driveFolderID: "GOOD"),
                .init(projectNumber: "2026-002", title: "Kaputt", driveFolderID: "BROKEN"),
            ],
            client: client)
        #expect(outcome.projectsScanned == 2)
        #expect(outcome.projectsFailed == 1)
        #expect(outcome.plans.count == 1)
    }

    @Test func reichtNotConnectedDurch() async throws {
        let client = PlansMultiFakeClient(tree: [:], throwingNotConnected: true)
        await #expect(throws: GoogleDriveError.self) {
            _ = try await AllPlansCollector.collectAll(
                projects: [.init(projectNumber: "2026-001", title: "X", driveFolderID: "A")],
                client: client)
        }
    }

    @Test func leereProjektlisteLiefertLeeresOutcome() async throws {
        let client = PlansMultiFakeClient(tree: [:])
        let outcome = try await AllPlansCollector.collectAll(projects: [], client: client)
        #expect(outcome.plans.isEmpty)
        #expect(outcome.projectsScanned == 0)
    }

    @Test func idsSindStabilUndEindeutig() async throws {
        let client = PlansMultiFakeClient(tree: [
            "A":     [folder("Layouts", "A_l")],
            "A_l":   [pdf("x.pdf", "f1"), pdf("y.pdf", "f2")],
        ])
        let outcome = try await AllPlansCollector.collectAll(
            projects: [.init(projectNumber: "2026-001", title: "Alpha", driveFolderID: "A")],
            client: client)
        let ids = outcome.plans.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(ids.contains("2026-001|layouts|f1"))
    }
}

// MARK: - AllPlansSorterTests

struct AllPlansSorterTests {

    private func sample() -> [AllPlansCollector.AggregatedPlan] {
        let old = pdf("alt.pdf", "1", at: Date(timeIntervalSince1970: 1_000))
        let new = pdf("neu.pdf", "2", at: Date(timeIntervalSince1970: 9_000))
        return [
            .init(projectNumber: "2026-002", projectTitle: "Beta", projectFolderID: "B",
                  category: .werkszeichnung, file: old),
            .init(projectNumber: "2026-001", projectTitle: "Alpha", projectFolderID: "A",
                  category: .plaene, file: new),
        ]
    }

    @Test func sortNachDatumNeuesteZuerst() {
        let sorted = AllPlansSorter.sorted(sample(), by: .datum)
        #expect(sorted.first?.file.name == "neu.pdf")
    }

    @Test func sortNachProjektNumerischAufsteigend() {
        let sorted = AllPlansSorter.sorted(sample(), by: .projekt)
        #expect(sorted.first?.projectNumber == "2026-001")
    }

    @Test func sortNachKategorieFolgtEnumReihenfolge() {
        // plaene steht im Enum vor werkszeichnung.
        let sorted = AllPlansSorter.sorted(sample(), by: .kategorie)
        #expect(sorted.first?.category == .plaene)
    }

    @Test func filterUeberKategorieQueryUndLeereQuery() {
        #expect(AllPlansSorter.filtered(sample(), category: .plaene).count == 1)
        #expect(AllPlansSorter.filtered(sample(), category: nil).count == 2)
        #expect(AllPlansSorter.filtered(sample(), query: "Alpha").count == 1)
        #expect(AllPlansSorter.filtered(sample(), query: "alt").count == 1)
        #expect(AllPlansSorter.filtered(sample(), query: "2026-002").count == 1)
        #expect(AllPlansSorter.filtered(sample(), query: "zzz").isEmpty)
        #expect(AllPlansSorter.filtered(sample(), query: "").count == 2)
    }
}

// MARK: - Hilfen

private func folder(_ name: String, _ id: String) -> GoogleDriveFile {
    GoogleDriveFile(id: id, name: name, mimeType: "application/vnd.google-apps.folder",
                    modifiedAt: nil, webViewLink: nil)
}

private func pdf(_ name: String, _ id: String, at date: Date? = nil) -> GoogleDriveFile {
    GoogleDriveFile(id: id, name: name, mimeType: "application/pdf",
                    modifiedAt: date, webViewLink: nil)
}

private func image(_ name: String, _ id: String) -> GoogleDriveFile {
    GoogleDriveFile(id: id, name: name, mimeType: "image/jpeg",
                    modifiedAt: nil, webViewLink: nil)
}

private final class PlansMultiFakeClient: GoogleDriveFetching, @unchecked Sendable {
    private let tree: [String: [GoogleDriveFile]]
    private let throwingTransient: Set<String>
    private let throwingNotConnected: Bool
    init(tree: [String: [GoogleDriveFile]],
         throwingTransient: Set<String> = [],
         throwingNotConnected: Bool = false) {
        self.tree = tree
        self.throwingTransient = throwingTransient
        self.throwingNotConnected = throwingNotConnected
    }
    func listFolder(folderID: String) async throws -> [GoogleDriveFile] {
        if throwingNotConnected { throw GoogleDriveError.notConnected }
        if throwingTransient.contains(folderID) { throw NSError(domain: "test", code: 1) }
        return tree[folderID] ?? []
    }
    func getFileName(folderID: String) async throws -> String { folderID }
    func downloadContent(fileID: String) async throws -> Data { Data() }
}
