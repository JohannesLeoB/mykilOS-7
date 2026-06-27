import Foundation
import Observation
import MykilosKit
import MykilosServices

// MARK: - RegistryStore
// @Observable Wrapper um CachedProjectRegistry. Lädt lokal, zeigt
// Ladezustand sauber, exponiert keine Exceptions nach außen — sie landen
// in `errorMessage` und können in der UI angezeigt werden.
// @MainActor: load()/seedIfEmpty()/syncFromAirtable() mutieren @Observable-Zustand,
// den SwiftUI auf dem Main-Thread liest. Ohne MainActor liefen die async-Methoden
// auf dem generischen Executor → isLoading/projects wurden OFF-MAIN geschrieben,
// SwiftUI verpasste das Update → Galerie hing (sporadisch) auf „Lade Projekte…".
@MainActor
@Observable
public final class RegistryStore {
    public var projects:  [Project]  = []
    public var customers: [Customer] = []
    public var isLoading:    Bool   = false
    public var errorMessage: String? = nil

    private var registry: CachedProjectRegistry?

    public init() {
        // Einmalige justified try?: Registry-Init-Fehler = leeres Array, nicht Absturz.
        // Der echte Fehler wird beim ersten `load()` geworfen.
        self.registry = try? CachedProjectRegistry()
    }

    // MARK: Laden
    public func load() async {
        guard !isLoading else { return }
        isLoading = true; defer { isLoading = false }
        do {
            let p = try registry?.allProjects()  ?? []
            let c = try registry?.allCustomers() ?? []
            projects  = p.sorted { $0.updatedAt > $1.updatedAt }
            customers = c
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Filter-Helfer
    public func activeProjects() -> [Project] {
        projects.filter { $0.phase != "Archiviert" }
    }

    public func customer(for project: Project) -> Customer? {
        customers.first { $0.customerNumber == project.customerNumber }
    }

    public func addenda(of project: Project) -> [Project] {
        projects.filter { $0.parentProjectNumber == project.projectNumber }
    }

    // MARK: Airtable-Sync
    public func syncFromAirtable(baseID: String, auth: AirtableAuthService) async {
        guard !isLoading, let reg = registry else { return }
        isLoading = true
        auth.setSyncing()
        do {
            let airtable = AirtableRegistry()
            try await airtable.sync(baseID: baseID, into: reg)
            auth.setSynced()
            // Flag VOR load() freigeben, sonst kehrt dessen `guard !isLoading`
            // sofort um → isLoading bliebe ewig true (Galerie hängt auf „Lade
            // Projekte…") und die frisch gesyncten Projekte würden nie geladen.
            isLoading = false
            await load()
        } catch {
            auth.setError(String(describing: error))
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: Initiale Live-Daten-Einstiegspunkt
    public func seedIfEmpty() async {
        guard let reg = registry else { return }
        do {
            if try reg.allProjects().isEmpty {
                try InitialProjectSeed.inject(into: reg)
                await load()
            }
        } catch { errorMessage = error.localizedDescription }
    }
}
