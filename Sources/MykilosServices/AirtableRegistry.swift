import Foundation
import MykilosKit

// MARK: - AirtableRegistry
// Das System-of-Record für Kunden & Projekte. Liest aus Airtable und
// schreibt in den lokalen Cache (CachedProjectRegistry).
// PAT liegt im Keychain, NIE in Code, Dateien oder im Repo.
public struct AirtableRegistry {
    private let client: AirtableFetching
    public let customersTable: String
    public let projectsTable: String

    public init(
        client: AirtableFetching = AirtableClient(),
        customersTable: String = "Kunden",
        projectsTable: String = "Projekte"
    ) {
        self.client = client
        self.customersTable = customersTable
        self.projectsTable = projectsTable
    }

    public func sync(baseID: String, into cache: CachedProjectRegistry) async throws {
        let customerRecords = try await client.fetchRecords(baseID: baseID, table: customersTable)
        let projectRecords = try await client.fetchRecords(baseID: baseID, table: projectsTable)

        let customers = AirtableClient.mapCustomers(from: customerRecords)
        let projects = AirtableClient.mapProjects(from: projectRecords)

        try cache.replaceCustomers(customers)
        try cache.replaceProjects(projects)
    }
}
