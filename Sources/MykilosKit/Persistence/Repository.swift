import Foundation

// MARK: - Repository
// Die EINE Persistenz-Abstraktion. Jeder Schreibvorgang `throws`.
// Es gibt kein `try?`-Schlucken mehr — ein Fehler beim Speichern wird sichtbar.
public protocol Repository: Sendable {
    associatedtype Entity: Codable & Identifiable & Sendable
    func loadAll() throws -> [Entity]
    func saveAll(_ entities: [Entity]) throws
}
