import Testing
import Foundation
@testable import MykilosKit

// MARK: - Cold-Start-Test
// Die wichtigste Testkategorie von mykilOS 6. Sie beweist: was gespeichert
// wurde, überlebt den App-Neustart. Eine NEUE Repository-Instanz auf demselben
// Speicherort = ein frisch gestarteter Rechner. Dieser eine Test hätte die
// gesamte Persistenzwunde von V5 nie zugelassen.
struct ColdStartTests {

    struct Demo: Codable, Identifiable, Equatable, Sendable {
        let id: UUID
        var title: String
        var updatedAt: Date
    }

    @Test func datenUeberlebenColdStart() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mykilos6-cold-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let items = [
            Demo(id: UUID(), title: "Küche Meyer", updatedAt: Date()),
            Demo(id: UUID(), title: "Lichtplanung Loft", updatedAt: Date())
        ]

        // Sitzung A: schreiben
        let repoA = try FileBackedRepository<Demo>(filename: "demo", directory: dir)
        try repoA.saveAll(items)

        // App "neu gestartet": komplett neue Instanz, selber Ort
        let repoB = try FileBackedRepository<Demo>(filename: "demo", directory: dir)
        let geladen = try repoB.loadAll()

        #expect(geladen == items)
    }

    @Test func leererSpeicherGibtLeerNichtFehler() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mykilos6-empty-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let repo = try FileBackedRepository<Demo>(filename: "nichtda", directory: dir)
        #expect(try repo.loadAll().isEmpty)
    }

    @Test func zweitesSpeichernUeberschreibtSauber() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mykilos6-over-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let repo = try FileBackedRepository<Demo>(filename: "demo", directory: dir)
        try repo.saveAll([Demo(id: UUID(), title: "Erst", updatedAt: Date())])
        let zweite = [Demo(id: UUID(), title: "Zweit", updatedAt: Date())]
        try repo.saveAll(zweite)

        #expect(try repo.loadAll() == zweite)
    }
}
