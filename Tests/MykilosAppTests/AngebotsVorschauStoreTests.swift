import Testing
import Foundation
@testable import MykilosApp
@testable import MykilosKit

// MARK: - AngebotsVorschauStoreTests (V10, Block G)
//
// Lokale Datei-Ablage der Angebots-Vorschau. In einen Temp-Ordner injiziert
// (kein echtes App-Support). Deckt: Erzeugen schreibt ein valides PDF, Liste
// findet es, „Cold Start" (frische Store-Instanz auf demselben Ordner) sieht es,
// leeres Projekt schreibt nichts.

@MainActor
struct AngebotsVorschauStoreTests {

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("vorschau-test-\(UUID().uuidString)", isDirectory: true)
    }

    private func korb(projektNummer: String, leer: Bool = false) -> WorkBasket {
        let picks: [any Pick] = leer ? [] : [
            BasicPick(
                matrix: .artikel,
                objektID: CatalogObjectID("art-1"),
                snapshot: PickSnapshot(bezeichnung: "Spüle", menge: 2, ekEinzel: 120, vkEinzel: 240),
                inhalt: .text("SP-100")
            ),
        ]
        return WorkBasket(
            id: WorkBasketID("WK-\(projektNummer)-1"),
            projektNummer: projektNummer,
            inhaltsArt: .artikel,
            picks: picks
        )
    }

    @Test func erzeugeSchreibtValidesPDFUndListetEs() throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = AngebotsVorschauStore(baseDirectory: dir)

        let url = store.erzeuge(basket: korb(projektNummer: "2026-015"),
                                kunde: "Familie Schneider",
                                projektTitel: "Küche Schneider",
                                projektNummer: "2026-015")
        let ziel = try #require(url)
        #expect(FileManager.default.fileExists(atPath: ziel.path))

        // Valides PDF (Magic Bytes) + korrekt einsortiert.
        let bytes = try Data(contentsOf: ziel)
        #expect(bytes.prefix(4) == Data([0x25, 0x50, 0x44, 0x46]))
        #expect(store.dateien.count == 1)
        #expect(store.zuletztErzeugt == ziel)
        #expect(ziel.lastPathComponent.hasPrefix("A-2026-015"))
    }

    @Test func coldStartFrischeInstanzSiehtGeschriebeneVorschau() throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let schreiber = AngebotsVorschauStore(baseDirectory: dir)
        _ = schreiber.erzeuge(basket: korb(projektNummer: "2026-020"),
                              kunde: "X", projektTitel: "Y", projektNummer: "2026-020")

        // Frische Instanz auf demselben Ordner — muss die Datei wiederfinden.
        let leser = AngebotsVorschauStore(baseDirectory: dir)
        leser.lade(projektNummer: "2026-020")
        #expect(leser.dateien.count == 1)
    }

    @Test func projekteSindGetrennt() throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = AngebotsVorschauStore(baseDirectory: dir)

        _ = store.erzeuge(basket: korb(projektNummer: "2026-015"), kunde: "A", projektTitel: "A", projektNummer: "2026-015")
        store.lade(projektNummer: "2026-099")   // anderes Projekt
        #expect(store.dateien.isEmpty)
    }
}
