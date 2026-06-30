import Foundation
import MykilosKit

// MARK: - ExternalMappingRegistry
// mykilOS 8, Block A: DER einzige Resolver für „welches Projekt ist das echte" —
// löst die Split-Brain-Verletzung aus AIRTABLE_DATENFLUSS_AUDIT.md §3 auf.
//
// SoR-Karte (verbindlich, siehe HANDOFF_MYKILOS8_ROLLING_PLAN.md §0):
//   Routing (Drive/ClickUp/Suchstrings)      → Mastermind `Projekte`   (CachedProjectRegistry)
//   Geschäft (Status/Budget/Sevdesk-Ref)     → Artikel-Base `Projekte` (CachedBusinessRegistry)
//   Verbindungsschlüssel                     → Projektnummer (JJJJ-NR)
//
// Liest NIE direkt von Airtable für Resolve-Anfragen — nur aus den beiden lokalen
// Caches, die `sync(...)` befüllt. Kein Read darf an dieser Stelle vorbei.
public struct ExternalMappingRegistry: Sendable {
    private let routing: CachedProjectRegistry
    private let business: CachedBusinessRegistry

    public init(routing: CachedProjectRegistry, business: CachedBusinessRegistry) {
        self.routing = routing
        self.business = business
    }

    /// Synct die Geschäfts-Wahrheit (Artikel-Base `Kunden`/`Projekte`) in den
    /// dedizierten Business-Cache. Rührt NIE den Routing-Cache an (Mastermind) —
    /// getrennte Sync-Pfade für getrennte Wahrheiten.
    public func syncBusiness(client: AirtableFetching, baseID: String) async throws {
        let customerRecords = try await client.fetchRecords(baseID: baseID, table: "Kunden")
        let projectRecords  = try await client.fetchRecords(baseID: baseID, table: "Projekte")
        let customers = AirtableClient.mapBusinessCustomers(from: customerRecords)
        let projects  = AirtableClient.mapBusinessProjects(from: projectRecords)
        try business.replaceCustomers(customers)
        try business.replaceProjects(projects)
    }

    /// Löst eine Projektnummer zu Routing + Geschäft auf. Exakter Schlüssel-Join,
    /// NIE Namens-Fuzzy-Match — ein unsicherer Treffer ist schlimmer als kein Treffer.
    public func resolve(projectNumber: String) throws -> ResolvedProject {
        let routingProject = try routing.allProjects().first { $0.projectNumber == projectNumber }
        let businessProject = try business.allProjects().first { $0.projectNumber == projectNumber }
        let customer: BusinessCustomer?
        if let businessProject, let firstKundeID = businessProject.kundeRecordIDs.first {
            customer = try business.allCustomers().first { $0.airtableRecordID == firstKundeID }
        } else {
            customer = nil
        }

        let state: ProjectBindingState
        if routingProject != nil && businessProject != nil {
            state = .linked
        } else if routingProject != nil {
            state = .routingOnly
        } else {
            // Auch wenn weder noch existiert: businessOnlyUnbound ist die ehrliche
            // Aussage „kein verbundenes Routing gefunden", nicht „nichts existiert".
            state = .businessOnlyUnbound
        }

        return ResolvedProject(
            projectNumber: projectNumber, routing: routingProject, business: businessProject,
            customer: customer, bindingState: state
        )
    }

    /// Geschäftsprojekte, die heute keiner Projektnummer zugeordnet werden können
    /// (kein `Projektnummer`-Feld in Artikel-`Projekte`, Stand 2026-06-30) — macht
    /// die Lücke sichtbar statt sie zu verstecken.
    public func unboundBusinessProjects() throws -> [BusinessProject] {
        try business.unboundProjects()
    }
}
