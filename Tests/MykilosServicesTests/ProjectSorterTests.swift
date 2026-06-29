import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

// MARK: - S21: ProjectSorter

struct ProjectSorterTests {
    private func p(_ number: String, _ title: String, _ kind: ProjectKind = .kitchen, _ updated: TimeInterval = 0) -> Project {
        Project(projectNumber: number, title: title, kind: kind, customerNumber: "K",
                updatedAt: Date(timeIntervalSince1970: updated))
    }

    private var sample: [Project] {
        [p("2026-002", "Bellavance", .kitchen, 100),
         p("2026-010", "Adickes", .lighting, 300),
         p("2025-001", "Zander", .kitchen, 200)]
    }

    @Test func sortNachName() {
        let r = ProjectSorter.sorted(sample, by: .name, customOrder: [])
        #expect(r.map(\.title) == ["Adickes", "Bellavance", "Zander"])
    }

    @Test func sortNachNummerNatuerlich() {
        let r = ProjectSorter.sorted(sample, by: .nummer, customOrder: [])
        #expect(r.map(\.projectNumber) == ["2025-001", "2026-002", "2026-010"])
    }

    @Test func sortNachDatumNeuesteZuerst() {
        let r = ProjectSorter.sorted(sample, by: .datum, customOrder: [])
        #expect(r.first?.title == "Adickes")   // updated 300 = neueste
        #expect(r.last?.title == "Bellavance") // updated 100
    }

    @Test func sortNachKategorie() {
        let r = ProjectSorter.sorted(sample, by: .kategorie, customOrder: [])
        // kitchen < lighting (rawValue) → Küchen zuerst, darin alphabetisch
        #expect(r.map(\.kind) == [.kitchen, .kitchen, .lighting])
        #expect(r.first?.title == "Bellavance")  // kitchen, alphabetisch vor Zander
    }

    @Test func sortEigeneFolgtCustomOrderDannRest() {
        let order = ["2026-010", "2025-001"]   // Adickes, Zander zuerst; Bellavance fehlt → hinten
        let r = ProjectSorter.sorted(sample, by: .eigene, customOrder: order)
        #expect(r.map(\.projectNumber) == ["2026-010", "2025-001", "2026-002"])
    }

    @Test func parseOrderFiltertLeere() {
        #expect(ProjectSorter.parseOrder("a,b,,c") == ["a", "b", "c"])
        #expect(ProjectSorter.parseOrder("").isEmpty)
    }
}
