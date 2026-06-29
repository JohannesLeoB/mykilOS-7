import Testing
import Foundation
@testable import MykilosServices

// MARK: - AllOffersCollectorTests (S23 — globale Angebots-Aggregation)
// Testet die reine, nebenläufige Aggregations-Logik gegen Fake-Drive-Clients:
// Aggregation über mehrere Projekte, Pro-Projekt-Fehler überspringen,
// notConnected durchreichen, leere Liste, sowie Sortier-/Filterlogik.

struct AllOffersCollectorTests {

    @Test func aggregiertBeideRichtungenUeberMehrereProjekte() async throws {
        let client = MultiProjectFakeClient(tree: [
            // Projekt A
            "A":      [folder("05 eingehende Angebote", "A_ein"),
                       folder("04 ausgehende Angebote", "A_aus")],
            "A_ein":  [pdf("202603971.pdf", "A_f1")],
            "A_aus":  [folder("Rechnung", "A_re")],
            "A_re":   [pdf("SR-SR_2026-0170-Kdnr-12822.pdf", "A_f2")],
            // Projekt B
            "B":      [folder("04 ausgehende Angebote", "B_aus")],
            "B_aus":  [folder("Angebot", "B_an")],
            "B_an":   [pdf("AN-A_2026-0189-Kdnr-555.pdf", "B_f1")],
        ])

        let outcome = try await AllOffersCollector.collectAll(
            projects: [
                .init(projectNumber: "2026-001", title: "Alpha", driveFolderID: "A"),
                .init(projectNumber: "2026-002", title: "Beta", driveFolderID: "B"),
            ],
            client: client)

        #expect(outcome.projectsScanned == 2)
        #expect(outcome.projectsFailed == 0)
        #expect(outcome.offers.count == 3)

        let alpha = outcome.offers.filter { $0.projectNumber == "2026-001" }
        #expect(alpha.count == 2)
        #expect(alpha.contains { $0.direction == .incoming && $0.offer.type == .eingehendesAngebot })
        #expect(alpha.contains { $0.direction == .outgoing && $0.offer.type == .schlussrechnung })

        let beta = outcome.offers.filter { $0.projectNumber == "2026-002" }
        #expect(beta.count == 1)
        #expect(beta.first?.direction == .outgoing)
        #expect(beta.first?.projectTitle == "Beta")
        #expect(beta.first?.projectFolderID == "B")
    }

    @Test func ueberspringtFehlerhaftesProjektOhneAbbruch() async throws {
        let client = MultiProjectFakeClient(
            tree: [
                "GOOD":     [folder("04 ausgehende Angebote", "G_aus")],
                "G_aus":    [pdf("AN-A_2026-1-Kdnr-1.pdf", "g1")],
            ],
            throwingTransient: ["BROKEN"])   // dieser Projektordner wirft (kein notConnected)

        let outcome = try await AllOffersCollector.collectAll(
            projects: [
                .init(projectNumber: "2026-001", title: "Gut", driveFolderID: "GOOD"),
                .init(projectNumber: "2026-002", title: "Kaputt", driveFolderID: "BROKEN"),
            ],
            client: client)

        #expect(outcome.projectsScanned == 2)
        #expect(outcome.projectsFailed == 1)
        #expect(outcome.offers.count == 1)
        #expect(outcome.offers.first?.projectNumber == "2026-001")
    }

    @Test func reichtNotConnectedDurch() async throws {
        let client = MultiProjectFakeClient(tree: [:], throwingNotConnected: true)
        await #expect(throws: GoogleDriveError.self) {
            _ = try await AllOffersCollector.collectAll(
                projects: [.init(projectNumber: "2026-001", title: "X", driveFolderID: "A")],
                client: client)
        }
    }

    @Test func leereProjektlisteLiefertLeeresOutcome() async throws {
        let client = MultiProjectFakeClient(tree: [:])
        let outcome = try await AllOffersCollector.collectAll(projects: [], client: client)
        #expect(outcome.offers.isEmpty)
        #expect(outcome.projectsScanned == 0)
    }

    @Test func serielleNebenlaeufigkeitLiefertGleichesErgebnis() async throws {
        let client = MultiProjectFakeClient(tree: [
            "A":     [folder("04 ausgehende Angebote", "A_aus")],
            "A_aus": [pdf("AN-A_2026-1-Kdnr-1.pdf", "a1")],
            "B":     [folder("04 ausgehende Angebote", "B_aus")],
            "B_aus": [pdf("AN-A_2026-2-Kdnr-2.pdf", "b1")],
        ])
        let outcome = try await AllOffersCollector.collectAll(
            projects: [
                .init(projectNumber: "2026-001", title: "A", driveFolderID: "A"),
                .init(projectNumber: "2026-002", title: "B", driveFolderID: "B"),
            ],
            client: client, maxConcurrent: 1)
        #expect(outcome.offers.count == 2)
    }
}

// MARK: - AllOffersSorterTests

struct AllOffersSorterTests {

    private func sample() -> [AllOffersCollector.AggregatedOffer] {
        let old = pdf("alt.pdf", "1", at: Date(timeIntervalSince1970: 1_000))
        let new = pdf("neu.pdf", "2", at: Date(timeIntervalSince1970: 9_000))
        return [
            .init(projectNumber: "2026-002", projectTitle: "Beta", projectFolderID: "B",
                  direction: .outgoing,
                  offer: ClassifiedOffer(file: old, type: .angebot, belegNummer: "2026-0002")),
            .init(projectNumber: "2026-001", projectTitle: "Alpha", projectFolderID: "A",
                  direction: .incoming,
                  offer: ClassifiedOffer(file: new, type: .eingehendesAngebot, belegNummer: "2026-0001")),
        ]
    }

    @Test func sortNachDatumNeuesteZuerst() {
        let sorted = AllOffersSorter.sorted(sample(), by: .datum)
        #expect(sorted.first?.offer.file.name == "neu.pdf")
    }

    @Test func sortNachProjektNumerischAufsteigend() {
        let sorted = AllOffersSorter.sorted(sample(), by: .projekt)
        #expect(sorted.first?.projectNumber == "2026-001")
    }

    @Test func filterFindetUeberProjektTitelUndDateiname() {
        #expect(AllOffersSorter.filtered(sample(), query: "Alpha").count == 1)
        #expect(AllOffersSorter.filtered(sample(), query: "neu").count == 1)
        #expect(AllOffersSorter.filtered(sample(), query: "2026-0002").count == 1)
        #expect(AllOffersSorter.filtered(sample(), query: "zzz").isEmpty)
        #expect(AllOffersSorter.filtered(sample(), query: "").count == 2)
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

// Baum über mehrere Projekte; optional wirft er für bestimmte Wurzeln.
private final class MultiProjectFakeClient: GoogleDriveFetching, @unchecked Sendable {
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
        if throwingTransient.contains(folderID) {
            throw NSError(domain: "test", code: 1)
        }
        return tree[folderID] ?? []
    }
    func getFileName(folderID: String) async throws -> String { folderID }
    func downloadContent(fileID: String) async throws -> Data { Data() }
}
