import Foundation
import MykilosKit

// MARK: - CachedProjectRegistry
// Liest die Registry aus dem lokalen Cache: überlebt den Neustart, funktioniert
// offline. Wird vom Airtable-Sync gefüllt. Das ist der erste echte Kunde der
// Persistenzschicht aus Akt 0.
public struct CachedProjectRegistry: ProjectRegistry {
    private let customers: FileBackedRepository<Customer>
    private let projects: FileBackedRepository<Project>

    public init(directory: URL? = nil) throws {
        self.customers = try FileBackedRepository<Customer>(filename: "customers", directory: directory)
        self.projects = try FileBackedRepository<Project>(filename: "projects", directory: directory)
    }

    public func allCustomers() throws -> [Customer] { try customers.loadAll() }
    public func allProjects() throws -> [Project] { try projects.loadAll() }

    public func projects(forCustomer customerNumber: String) throws -> [Project] {
        try projects.loadAll().filter { $0.customerNumber == customerNumber }
    }

    public func addenda(ofParent projectNumber: String) throws -> [Project] {
        try projects.loadAll().filter { $0.parentProjectNumber == projectNumber }
    }

    // Vom Airtable-Sync aufgerufen (Akt 3):
    public func replaceCustomers(_ list: [Customer]) throws { try customers.saveAll(list) }
    public func replaceProjects(_ list: [Project]) throws { try projects.saveAll(list) }
}
