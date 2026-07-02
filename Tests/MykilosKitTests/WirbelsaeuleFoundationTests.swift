import Testing
import Foundation
@testable import MykilosKit

// MARK: - WirbelsaeuleFoundationTests
// C1-Fundament: Pick / WorkBasket / CheckoutPort / PortRegistry (S10-Blueprint §1–§4, §7).
// Rein in-memory — kein Netzwerk, kein Keychain, kein GRDB.

struct WirbelsaeuleFoundationTests {

    // MARK: - Test-Doubles

    /// Minimaler CheckoutPort für die Registry-Tests: deklariert seine erlaubten
    /// Inhalts-Arten und antwortet trivial auf preview/execute.
    ///
    /// `MykilosKit.CheckoutPort` ausgeschrieben, weil `Foundation` ein `NSPort` als
    /// `CheckoutPort` einblendet — sonst ist der Typname im Test mehrdeutig.
    private struct TestPort: MykilosKit.CheckoutPort {
        let id: PortID
        let name: String
        let arten: Set<InhaltsArt>

        func erlaubteInhaltsArten() -> Set<InhaltsArt> { arten }

        func preview(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutPreview {
            CheckoutPreview(zusammenfassung: "preview \(id.raw)")
        }

        func execute(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutResult {
            CheckoutResult(erfolg: true, referenz: id.raw)
        }
    }

    /// Rechte-Provider, der genau eine PortID verbietet (alles andere erlaubt).
    private struct VerbietetEinen: PortRightsProviding {
        let alle: Set<PortID>
        let verboten: PortID

        func erlaubtePorts(userID: String) -> Set<PortID> {
            alle.subtracting([verboten])
        }
    }

    // MARK: - 1. Inhalts-Art-Gate

    @Test func portRegistryFiltertNachInhaltsArt() {
        let bilderPort = TestPort(id: PortID("moodboard"), name: "Moodboard", arten: [.bilder])
        var registry = PortRegistry()
        registry.registriere(bilderPort)

        let rechte = AllowAllPortRights(alleBekanntenPorts: registry.alleBekanntenPortIDs)

        // Für .artikel darf der bilder-only CheckoutPort NICHT erscheinen.
        let fuerArtikel = registry.ports(fuer: .artikel, userID: "u1", rechte: rechte)
        #expect(fuerArtikel.isEmpty)

        // Für .bilder erscheint er.
        let fuerBilder = registry.ports(fuer: .bilder, userID: "u1", rechte: rechte)
        #expect(fuerBilder.count == 1)
        #expect(fuerBilder.first?.id == PortID("moodboard"))
    }

    // MARK: - 2. User-Recht-Gate

    @Test func portRegistryFiltertNachUserRecht() {
        let angebot = TestPort(id: PortID("angebot"), name: "Angebot", arten: [.artikel])
        let sevdesk = TestPort(id: PortID("sevdesk"), name: "sevDesk-Übergabe", arten: [.artikel])
        var registry = PortRegistry()
        registry.registriere(angebot)
        registry.registriere(sevdesk)

        // Rechte-Provider verbietet ausgerechnet den sevDesk-CheckoutPort.
        let rechte = VerbietetEinen(
            alle: registry.alleBekanntenPortIDs,
            verboten: PortID("sevdesk")
        )

        let verfuegbar = registry.ports(fuer: .artikel, userID: "u1", rechte: rechte)
        // Beide passen zur Inhalts-Art, aber sevDesk ist per Recht ausgeschlossen.
        #expect(verfuegbar.count == 1)
        #expect(verfuegbar.first?.id == PortID("angebot"))
        #expect(!verfuegbar.contains { $0.id == PortID("sevdesk") })
    }

    // MARK: - 3. WorkBasketStatus-Lebenszyklus (§7)

    @Test func lebenszyklusUebergaengeUndFreeze() {
        // kalkulation → bestaetigt ist erlaubt.
        #expect(WorkBasketStatus.kalkulation.darfWechselnZu(.bestaetigt))

        // bestaetigt → kalkulation ist NICHT erlaubt (kein Rückweg aus dem Freeze).
        #expect(!WorkBasketStatus.bestaetigt.darfWechselnZu(.kalkulation))

        // bestaetigt → nachtrag / gutschrift ist erlaubt (append-only Kette).
        let eltern = WorkBasketID("WK-2026-015-abc")
        #expect(WorkBasketStatus.bestaetigt.darfWechselnZu(.nachtrag(zu: eltern)))
        #expect(WorkBasketStatus.bestaetigt.darfWechselnZu(.gutschrift(zu: eltern)))

        // kalkulation darf NICHT direkt in einen Nachtrag springen.
        #expect(!WorkBasketStatus.kalkulation.darfWechselnZu(.nachtrag(zu: eltern)))

        // Nachtrag/Gutschrift referenzieren ihren Eltern-Korb.
        if case let .nachtrag(zu) = WorkBasketStatus.nachtrag(zu: eltern) {
            #expect(zu == eltern)
        } else {
            Issue.record("nachtrag sollte seinen Eltern-Korb tragen")
        }

        // istEingefroren: kalkulation frei, alles andere eingefroren.
        #expect(WorkBasketStatus.kalkulation.istEingefroren == false)
        #expect(WorkBasketStatus.bestaetigt.istEingefroren == true)
        #expect(WorkBasketStatus.nachtrag(zu: eltern).istEingefroren == true)
        #expect(WorkBasketStatus.gutschrift(zu: eltern).istEingefroren == true)
    }

    // MARK: - 4. BasicPick.resolve()

    @Test func basicPickResolvedGespeichertenInhalt() async throws {
        let snapshot = PickSnapshot(
            bezeichnung: "Spüle Blanco",
            menge: 2,
            ekEinzel: 120.0,
            vkEinzel: 240.0,
            attribute: ["farbe": "anthrazit"]
        )
        let pick = BasicPick(
            matrix: .artikel,
            objektID: CatalogObjectID("art-0001"),
            snapshot: snapshot,
            inhalt: .text("Blanco Subline 500-U")
        )

        #expect(pick.matrix == .artikel)
        #expect(pick.objektID == CatalogObjectID("art-0001"))
        #expect(pick.snapshot.bezeichnung == "Spüle Blanco")
        #expect(pick.snapshot.menge == 2)
        #expect(pick.snapshot.attribute["farbe"] == "anthrazit")

        let content = try await pick.resolve()
        #expect(content == .text("Blanco Subline 500-U"))
    }

    @Test func basicPickResolvedKeinerAlsDefault() async throws {
        let pick = BasicPick(
            matrix: .sonstige,
            objektID: CatalogObjectID("x"),
            snapshot: PickSnapshot(bezeichnung: "leer")
        )
        let content = try await pick.resolve()
        #expect(content == .keiner)
    }

    // MARK: - WorkBasket-Konstruktion (Rauchtest)

    @Test func workBasketTraegtGemischtePicks() {
        let bild = BasicPick(
            matrix: .bild,
            objektID: CatalogObjectID("img-1"),
            snapshot: PickSnapshot(bezeichnung: "Render"),
            inhalt: .bytes(Data([0x1]), mimeType: "image/png")
        )
        let notiz = BasicPick(
            matrix: .textblock,
            objektID: CatalogObjectID("txt-1"),
            snapshot: PickSnapshot(bezeichnung: "Hinweis"),
            inhalt: .text("bitte prüfen")
        )
        let basket = WorkBasket(
            id: WorkBasketID("WK-2026-015-0001"),
            projektNummer: "2026-015",
            inhaltsArt: .gemischt,
            picks: [bild, notiz]
        )

        #expect(basket.picks.count == 2)
        #expect(basket.inhaltsArt == .gemischt)
        #expect(basket.version == 1)
        #expect(basket.status == .kalkulation)
        #expect(basket.status.istEingefroren == false)
    }
}
