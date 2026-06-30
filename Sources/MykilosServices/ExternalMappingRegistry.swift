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

    /// Löst eine Projektnummer zu Routing + Geschäft auf. Primärer Schlüssel ist immer
    /// das echte `Projektnummer`-Feld — NIE Namens-Fuzzy-Match. `confirmedBindings`
    /// (businessRecordID → projectNumber aus `ProjectNumberBindingStore`) ist NUR ein
    /// zusätzlicher, manuell bestätigter Fallback für Geschäftsprojekte ohne das Feld;
    /// existiert ein echter Feld-Match, gewinnt der IMMER (`.linked` vor
    /// `.linkedViaLocalBinding` — „aktueller Datenstand als Safety", Johannes 2026-06-30).
    public func resolve(projectNumber: String, confirmedBindings: [String: String] = [:]) throws -> ResolvedProject {
        let routingProject = try routing.allProjects().first { $0.projectNumber == projectNumber }
        let allBusiness = try business.allProjects()
        let directMatch = allBusiness.first { $0.projectNumber == projectNumber }
        let bridgedMatch = directMatch == nil
            ? allBusiness.first { confirmedBindings[$0.airtableRecordID] == projectNumber }
            : nil
        let businessProject = directMatch ?? bridgedMatch

        let customer: BusinessCustomer?
        if let businessProject, let firstKundeID = businessProject.kundeRecordIDs.first {
            customer = try business.allCustomers().first { $0.airtableRecordID == firstKundeID }
        } else {
            customer = nil
        }

        let state: ProjectBindingState
        if routingProject != nil && directMatch != nil {
            state = .linked
        } else if routingProject != nil && bridgedMatch != nil {
            state = .linkedViaLocalBinding
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
    /// die Lücke sichtbar statt sie zu verstecken. `excluding` nimmt bereits bestätigte
    /// businessRecordIDs raus (die haben schon eine lokale Bindung, auch wenn das echte
    /// Feld weiter fehlt).
    public func unboundBusinessProjects(excluding confirmed: Set<String> = []) throws -> [BusinessProject] {
        try business.unboundProjects().filter { !confirmed.contains($0.airtableRecordID) }
    }

    /// Bindungs-Kandidaten: Geschäftsprojekte ohne Projektnummer, die per EXAKTEM
    /// (getrimmtem, case-insensitivem) Titel-Match genau EINEM Mastermind-Routing-
    /// Projekt zugeordnet werden könnten. Mehrdeutige Treffer (>1 Routing-Projekt mit
    /// demselben Titel) werden NIE vorgeschlagen — lieber kein Kandidat als ein falscher.
    /// Automatisch erkannt, aber NICHT automatisch verbindlich — erst eine Bestätigung
    /// (`ProjectNumberBindingStore.confirm`) macht daraus eine geltende Bindung.
    public func candidateBindings(excluding confirmed: Set<String> = []) throws -> [ProjectNumberBindingCandidate] {
        let routingProjects = try routing.allProjects()
        let unbound = try unboundBusinessProjects(excluding: confirmed)

        func normalized(_ s: String) -> String {
            s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        var candidates: [ProjectNumberBindingCandidate] = []
        for biz in unbound {
            let name = normalized(biz.projektname)
            guard !name.isEmpty else { continue }
            let matches = routingProjects.filter { normalized($0.title) == name }
            guard matches.count == 1, let match = matches.first else { continue }
            candidates.append(ProjectNumberBindingCandidate(
                businessRecordID: biz.airtableRecordID, businessProjektname: biz.projektname,
                projectNumber: match.projectNumber, routingTitle: match.title))
        }
        return candidates
    }

    // MARK: - Identitäts-Lookups (mykilOS 8, Block C / S2)
    // Die Registry wird „voll": Kundennummer (Kdnr) und Projektnummer sind GETRENNTE
    // kanonische Schlüssel (Kdnr ≠ Projektnr, HANDOFF_PROVISIONING_NOMENKLATUR §1).
    // Kdnr identifiziert den KUNDEN, Projektnummer das PROJEKT. Ein Freitext-Token kann
    // beides oder ein Name sein — `resolveToken` löst es eindeutig auf.

    /// Kunde per Kundennummer (Kdnr). Exakt, case-insensitiv.
    public func customer(kdnr: String) throws -> Customer? {
        let key = kdnr.trimmingCharacters(in: .whitespacesAndNewlines)
        guard key.isEmpty == false else { return nil }
        return try routing.allCustomers().first { $0.customerNumber.caseInsensitiveCompare(key) == .orderedSame }
    }

    /// Projekt per Projektnummer (Routing-Wahrheit). Exakt, case-insensitiv.
    public func project(projektnummer: String) throws -> Project? {
        let key = projektnummer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard key.isEmpty == false else { return nil }
        return try routing.allProjects().first { $0.projectNumber.caseInsensitiveCompare(key) == .orderedSame }
    }

    /// Alle Projekte eines Kunden (über `customerNumber`-Verknüpfung).
    public func projects(kdnr: String) throws -> [Project] {
        let key = kdnr.trimmingCharacters(in: .whitespacesAndNewlines)
        guard key.isEmpty == false else { return [] }
        return try routing.allProjects().filter { $0.customerNumber.caseInsensitiveCompare(key) == .orderedSame }
    }

    /// Löst ein Freitext-Token eindeutig auf: erst Projektnummer, dann Kdnr, dann Name.
    /// `Kdnr ≠ Projektnr` bleibt gewahrt — ein Projektnummer-Treffer gewinnt nie über eine
    /// Kdnr, weil die Formate sich nicht überschneiden (Projektnr ist `JJJJ-NNN`).
    public func resolveToken(_ token: String) throws -> TokenAufloesung {
        let key = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard key.isEmpty == false else { return .unbekannt }
        if let p = try project(projektnummer: key) { return .projekt(p) }
        if let c = try customer(kdnr: key) { return .kunde(c) }
        // Name-Fallback (schwächer): exakter, normalisierter Kunden-/Projekttitel.
        func norm(_ s: String) -> String { s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).trimmingCharacters(in: .whitespacesAndNewlines) }
        let nk = norm(key)
        if let c = try routing.allCustomers().first(where: { norm($0.name) == nk }) { return .kunde(c) }
        if let p = try routing.allProjects().first(where: { norm($0.title) == nk }) { return .projekt(p) }
        return .unbekannt
    }
}

// MARK: - TokenAufloesung
public enum TokenAufloesung: Sendable, Equatable {
    case kunde(Customer)
    case projekt(Project)
    case unbekannt
}
