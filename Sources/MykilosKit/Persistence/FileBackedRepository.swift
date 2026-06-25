import Foundation

// MARK: - FileBackedRepository
// Akt-0-Implementierung: echte, atomare Datei-Persistenz auf der Platte.
// NICHT UserDefaults. Atomares Schreiben (write-to-temp-then-rename) schützt
// vor Korruption bei Absturz. Jeder Fehler wird geworfen, nie verschluckt.
//
// Wachstumspfad: Sobald relationale Daten kommen (z. B. Nachträge, die auf ihr
// Eltern-Projekt verweisen), tritt GRDB/SQLite hinter dieselbe `Repository`-
// Schnittstelle. Der aufrufende Code ändert sich dabei nicht.
//
// `@unchecked Sendable`: der Zustand ist über `NSLock` serialisiert.
public final class FileBackedRepository<Entity: Codable & Identifiable & Sendable>: Repository, @unchecked Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let lock = NSLock()

    public init(filename: String, directory: URL? = nil) throws {
        let base: URL
        if let directory {
            base = directory
        } else {
            guard let appSupport = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                throw PersistenceError.directoryUnavailable
            }
            base = appSupport.appendingPathComponent("mykilOS6", isDirectory: true)
        }
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        self.fileURL = base.appendingPathComponent(filename).appendingPathExtension("json")

        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        self.encoder = e
        self.decoder = d
    }

    public func loadAll() throws -> [Entity] {
        lock.lock(); defer { lock.unlock() }
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data: Data
        do { data = try Data(contentsOf: fileURL) }
        catch { throw PersistenceError.decodeFailed }
        do { return try decoder.decode([Entity].self, from: data) }
        catch { throw PersistenceError.decodeFailed }
    }

    public func saveAll(_ entities: [Entity]) throws {
        lock.lock(); defer { lock.unlock() }
        let data: Data
        do { data = try encoder.encode(entities) }
        catch { throw PersistenceError.encodeFailed }
        do { try data.write(to: fileURL, options: [.atomic]) }   // atomar: temp + rename
        catch { throw PersistenceError.writeFailed }
    }
}
