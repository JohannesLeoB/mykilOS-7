import Foundation
import MykilosKit

// MARK: - CachedBusinessRegistry
// Lokaler Cache für die GESCHÄFTS-Wahrheit (Artikel-Base `Kunden`/`Projekte`,
// appdxTeT6bhSBmwx5). Bewusst eine EIGENE Datei/Repository-Paarung neben
// `CachedProjectRegistry` (Mastermind-Routing) — niemals gemischt, das ist der
// Kern der Eine-Wahrheit-Trennung (siehe BusinessRecord.swift).
public struct CachedBusinessRegistry: Sendable {
    private let customers: FileBackedRepository<BusinessCustomer>
    private let projects: FileBackedRepository<BusinessProject>

    public init(directory: URL? = nil) throws {
        self.customers = try FileBackedRepository<BusinessCustomer>(filename: "business_customers", directory: directory)
        self.projects = try FileBackedRepository<BusinessProject>(filename: "business_projects", directory: directory)
    }

    public func allCustomers() throws -> [BusinessCustomer] { try customers.loadAll() }
    public func allProjects() throws -> [BusinessProject] { try projects.loadAll() }

    /// Geschäftsprojekte ohne Projektnummer — der sichtbare Beweis der heutigen
    /// Lücke (kein `Projektnummer`-Feld in Artikel-`Projekte`, Stand 2026-06-30).
    public func unboundProjects() throws -> [BusinessProject] {
        try projects.loadAll().filter { $0.projectNumber == nil || $0.projectNumber?.isEmpty == true }
    }

    public func replaceCustomers(_ list: [BusinessCustomer]) throws { try customers.saveAll(list) }
    public func replaceProjects(_ list: [BusinessProject]) throws { try projects.saveAll(list) }

    public func clearCache() throws {
        try customers.saveAll([])
        try projects.saveAll([])
    }
}
