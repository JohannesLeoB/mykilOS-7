import Foundation
import MykilosKit

// MARK: - AirtableRegistry
// Das System-of-Record für Kunden & Projekte.
//
// Airtable hält: Kundennummer, Projektnummer/Kürzel, Links & Pfade, und über
// verknüpfte Datensätze die Beziehung Nachtrag → Eltern-Projekt.
//
// Akt 0: BEWUSST nicht implementiert. Hier steht kein Fake, der Erfolg
// vortäuscht — das war eine V5-Sünde. Der echte API-Sync (read-first) kommt in
// Akt 3. Der Airtable-PAT liegt dann im Keychain, NIE in Code, Dateien oder im
// Repo, und der Sync füllt nur den lokalen Cache (CachedProjectRegistry).
public struct AirtableRegistry {
    public enum State: Error { case implementedInAkt3 }

    public let baseID: String
    public init(baseID: String) { self.baseID = baseID }

    /// Akt 3: holt Kunden/Projekte aus Airtable und füllt den lokalen Cache.
    public func sync(into cache: CachedProjectRegistry) throws {
        throw State.implementedInAkt3
    }
}
