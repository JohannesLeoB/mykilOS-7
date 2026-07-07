import Testing
import Foundation
import AppKit
@testable import MykilosApp
@testable import MykilosKit
@testable import MykilosServices

// MARK: - WirbelsaeulePortsTests (Wirbelsäule C2)
// Die drei ersten nativen CheckoutPorts: DokumentPort (PDF), MoodboardPort (PNG),
// FireflyPromptPort (Text via Claude-Double).
//
// Rein lokal — kein Netzwerk, kein Keychain. Der Claude-Port bekommt einen
// injizierten Scripted-Double (Muster wie ClaudeMessagesClientTests), damit der
// automatisierte Lauf nie eine echte API kontaktiert.

struct WirbelsaeulePortsTests {

    // MARK: - Test-Bausteine

    /// Kleines PNG (1×1) als echte Bytes für Bild-Picks.
    private static func einPixelPNG() -> Data {
        let image = NSImage(size: NSSize(width: 1, height: 1))
        image.lockFocus()
        NSColor.orange.setFill()
        NSRect(x: 0, y: 0, width: 1, height: 1).fill()
        image.unlockFocus()
        let tiff = image.tiffRepresentation!
        let rep = NSBitmapImageRep(data: tiff)!
        return rep.representation(using: .png, properties: [:])!
    }

    private func artikelKorb() -> WorkBasket {
        let a = BasicPick(
            matrix: .artikel,
            objektID: CatalogObjectID("art-1"),
            snapshot: PickSnapshot(bezeichnung: "Blanco Spüle", menge: 2, ekEinzel: 120, vkEinzel: 240),
            inhalt: .text("Blanco Subline 500-U")
        )
        let b = BasicPick(
            matrix: .artikel,
            objektID: CatalogObjectID("art-2"),
            snapshot: PickSnapshot(bezeichnung: "Backofen Bosch", menge: 1, ekEinzel: 600, vkEinzel: 950)
        )
        return WorkBasket(
            id: WorkBasketID("WK-2026-015-0001"),
            projektNummer: "2026-015",
            inhaltsArt: .artikel,
            picks: [a, b]
        )
    }

    private func bildKorb() -> WorkBasket {
        let png = Self.einPixelPNG()
        let bild = BasicPick(
            matrix: .bild,
            objektID: CatalogObjectID("img-1"),
            snapshot: PickSnapshot(bezeichnung: "Küche Referenz"),
            inhalt: .bytes(png, mimeType: "image/png")
        )
        let ohneBytes = BasicPick(
            matrix: .material,
            objektID: CatalogObjectID("mat-1"),
            snapshot: PickSnapshot(bezeichnung: "Eiche geölt", attribute: ["material": "Eiche"]),
            inhalt: .keiner
        )
        return WorkBasket(
            id: WorkBasketID("WK-2026-015-0002"),
            projektNummer: "2026-015",
            inhaltsArt: .bilder,
            picks: [bild, ohneBytes]
        )
    }

    // MARK: - Scripted Claude-Double (kein Netz)

    /// Gibt einen fest verdrahteten Text zurück und merkt sich, dass die Tool-Liste
    /// leer war (Text-Only-Garantie).
    private final class ScriptedConversing: AssistantConversing, @unchecked Sendable {
        let antwortText: String
        private(set) var letzteToolAnzahl: Int = -1
        private(set) var wurdeAufgerufen = false

        init(antwortText: String) { self.antwortText = antwortText }

        func respond(
            messages: [ChatMessage], system: String, tools: [ClaudeToolDefinition], maxTokens: Int
        ) async throws -> ClaudeChatResponse {
            wurdeAufgerufen = true
            letzteToolAnzahl = tools.count
            return ClaudeChatResponse(text: antwortText, toolUses: [], stopReason: "end_turn")
        }

        func streamText(
            messages: [ChatMessage], system: String, tools: [ClaudeToolDefinition], maxTokens: Int
        ) -> AsyncThrowingStream<String, Error> {
            AsyncThrowingStream { $0.finish() }
        }
    }

    // MARK: - 1. DokumentPort

    @Test func dokumentPortErlaubteArten() {
        let port = DokumentPort()
        #expect(port.erlaubteInhaltsArten() == [.dokumente, .artikel])
    }

    @Test func dokumentPortPreviewFasstPositionenZusammen() async throws {
        let port = DokumentPort()
        let preview = try await port.preview(
            basket: artikelKorb(),
            ziel: PortZiel(kind: "download", parameter: ["titel": "Geräteliste Test"])
        )
        #expect(preview.zusammenfassung.contains("Geräteliste Test"))
        #expect(preview.zusammenfassung.contains("2 Position"))
        #expect(preview.warnungen.isEmpty)
    }

    @Test func dokumentPortPreviewWarntBeiLeeremKorb() async throws {
        let port = DokumentPort()
        let leer = WorkBasket(id: WorkBasketID("WK-x"), projektNummer: "2026-000", inhaltsArt: .dokumente)
        let preview = try await port.preview(basket: leer, ziel: PortZiel(kind: "download"))
        #expect(preview.warnungen.isEmpty == false)
    }

    @Test func dokumentPortExecuteRendertPDF() async throws {
        let port = DokumentPort()
        let result = try await port.execute(basket: artikelKorb(), ziel: PortZiel(kind: "download"))
        #expect(result.erfolg)
        let data = try #require(result.nutzlast)
        #expect(data.isEmpty == false)
        // Echtes PDF → Magic-Bytes "%PDF".
        #expect(data.prefix(4) == Data([0x25, 0x50, 0x44, 0x46]))
        #expect(result.referenz == "WK-2026-015-0001")
    }

    // MARK: - 2. MoodboardPort

    @Test func moodboardPortErlaubteArten() {
        let port = MoodboardPort()
        #expect(port.erlaubteInhaltsArten() == [.bilder, .material, .zeichnungen])
    }

    @Test func moodboardPortPreviewNenntLayout() async throws {
        let port = MoodboardPort()
        let preview = try await port.preview(basket: bildKorb(), ziel: PortZiel(kind: "download"))
        #expect(preview.zusammenfassung.contains("2 Bild"))
        #expect(preview.zusammenfassung.contains("Layout 2"))
    }

    @Test func moodboardPortExecuteRendertPNG() async throws {
        let port = MoodboardPort()
        let result = try await port.execute(basket: bildKorb(), ziel: PortZiel(kind: "download"))
        #expect(result.erfolg)
        let data = try #require(result.nutzlast)
        #expect(data.isEmpty == false)
        // Echtes PNG → Magic-Bytes 0x89 P N G.
        #expect(data.prefix(4) == Data([0x89, 0x50, 0x4E, 0x47]))
    }

    // MARK: - 3. FireflyPromptPort

    @Test func fireflyPromptPortErlaubteArten() {
        let port = FireflyPromptPort(client: ScriptedConversing(antwortText: "x"))
        #expect(port.erlaubteInhaltsArten() == [.bilder, .material, .zeichnungen])
    }

    @Test func fireflyPromptPortPreviewOhneClaudeAufruf() async throws {
        let double = ScriptedConversing(antwortText: "sollte nie kommen")
        let port = FireflyPromptPort(client: double)
        let preview = try await port.preview(
            basket: bildKorb(),
            ziel: PortZiel(kind: "prompt", parameter: ["kontext": "Skandinavisch, hell"])
        )
        #expect(preview.zusammenfassung.contains("2 Pick"))
        #expect(preview.zusammenfassung.contains("Skandinavisch, hell"))
        // Vorschau darf den Client NICHT bemühen.
        #expect(double.wurdeAufgerufen == false)
    }

    @Test func fireflyPromptPortExecuteLiefertNurText() async throws {
        let double = ScriptedConversing(
            antwortText: "A bright Scandinavian kitchen, oak counters, soft morning light."
        )
        let port = FireflyPromptPort(client: double)
        let result = try await port.execute(
            basket: bildKorb(),
            ziel: PortZiel(kind: "prompt", parameter: ["kontext": "Skandinavisch"])
        )
        #expect(result.erfolg)
        // Text steckt in meldung — KEIN Bild-Payload.
        #expect(result.meldung == "A bright Scandinavian kitchen, oak counters, soft morning light.")
        #expect(result.nutzlast == nil)
        // Text-Only-Garantie: der Claude-Aufruf ging MIT LEERER Tool-Liste raus.
        #expect(double.wurdeAufgerufen)
        #expect(double.letzteToolAnzahl == 0)
    }

    @Test func fireflyPromptPortUserPromptEnthaeltPicksUndKontext() {
        let text = FireflyPromptPort.userPrompt(
            projektNummer: "2026-015",
            kontext: "Skandinavisch",
            pickZeilen: ["Küche Referenz [bild]", "Eiche geölt (Eiche) [material]"]
        )
        #expect(text.contains("2026-015"))
        #expect(text.contains("Skandinavisch"))
        #expect(text.contains("Küche Referenz"))
        #expect(text.contains("Eiche geölt"))
    }

    @Test func fireflyPromptPortLeererTextIstMisserfolg() async throws {
        let double = ScriptedConversing(antwortText: "   ")
        let port = FireflyPromptPort(client: double)
        let result = try await port.execute(basket: bildKorb(), ziel: PortZiel(kind: "prompt"))
        #expect(result.erfolg == false)
        #expect(result.nutzlast == nil)
    }

    // MARK: - 4. PortRegistry-Integration (Inhalts-Art-Gate mit echten Ports)

    // MARK: - VWPlankopfPort (Johannes-Auftrag 2026-07-07)

    private func plankopfKorb() -> WorkBasket {
        let kunde = BasicPick(
            matrix: .kunde,
            objektID: CatalogObjectID("kunde-1"),
            snapshot: PickSnapshot(bezeichnung: "Familie Cirnavuk")
        )
        let projekt = BasicPick(
            matrix: .projekt,
            objektID: CatalogObjectID("proj-1"),
            snapshot: PickSnapshot(bezeichnung: "Küche Neubau")
        )
        let material = BasicPick(
            matrix: .material,
            objektID: CatalogObjectID("mat-1"),
            snapshot: PickSnapshot(bezeichnung: "Eiche geölt")
        )
        let geraet = BasicPick(
            matrix: .artikel,
            objektID: CatalogObjectID("art-geraet"),
            snapshot: PickSnapshot(bezeichnung: "Backofen Bosch", menge: 1, attribute: ["kategorie": "geraet"])
        )
        let ausstattung = BasicPick(
            matrix: .artikel,
            objektID: CatalogObjectID("art-ausstattung"),
            snapshot: PickSnapshot(bezeichnung: "LED-Lichtband", menge: 3, attribute: ["kategorie": "ausstattung"])
        )
        let beschlag = BasicPick(
            matrix: .artikel,
            objektID: CatalogObjectID("art-beschlag"),
            snapshot: PickSnapshot(bezeichnung: "Blum Legrabox", menge: 4, attribute: ["kategorie": "beschlag"])
        )
        let unkategorisiert = BasicPick(
            matrix: .artikel,
            objektID: CatalogObjectID("art-sonstige"),
            snapshot: PickSnapshot(bezeichnung: "Kleinteile")
        )
        return WorkBasket(
            id: WorkBasketID("WK-2026-015-0003"),
            projektNummer: "2026-015",
            inhaltsArt: .gemischt,
            picks: [kunde, projekt, material, geraet, ausstattung, beschlag, unkategorisiert]
        )
    }

    @Test func plankopfPortErlaubteArten() {
        let port = VWPlankopfPort()
        #expect(port.erlaubteInhaltsArten() == [.gemischt, .material, .artikel])
    }

    @Test func plankopfPortGruppiertNachMatrixUndKategorie() async throws {
        let gruppen = try await VWPlankopfPort.gruppiere(plankopfKorb().picks)
        #expect(gruppen.kunde.map(\.bezeichnung) == ["Familie Cirnavuk"])
        #expect(gruppen.projekt.map(\.bezeichnung) == ["Küche Neubau"])
        #expect(gruppen.material.map(\.bezeichnung) == ["Eiche geölt"])
        #expect(gruppen.geraete.map(\.bezeichnung) == ["Backofen Bosch"])
        #expect(gruppen.ausstattung.map(\.bezeichnung) == ["LED-Lichtband"])
        #expect(gruppen.beschlaege.map(\.bezeichnung) == ["Blum Legrabox"])
        #expect(gruppen.sonstigeArtikel.map(\.bezeichnung) == ["Kleinteile"])
    }

    @Test func plankopfPortPreviewNenntSektionenUndWarntEntwurf() async throws {
        let port = VWPlankopfPort()
        let preview = try await port.preview(basket: plankopfKorb(), ziel: PortZiel(kind: "download"))
        #expect(preview.zusammenfassung.contains("2026-015"))
        #expect(preview.zusammenfassung.contains("7 Positionen"))
        #expect(preview.zusammenfassung.contains("Geräte"))
        #expect(preview.warnungen.contains { $0.contains("noch nicht verifiziert") })
    }

    @Test func plankopfPortPreviewWarntZusaetzlichBeiLeeremKorb() async throws {
        let port = VWPlankopfPort()
        let leer = WorkBasket(id: WorkBasketID("WK-x"), projektNummer: "2026-000", inhaltsArt: .gemischt)
        let preview = try await port.preview(basket: leer, ziel: PortZiel(kind: "download"))
        #expect(preview.warnungen.count == 2)
    }

    @Test func plankopfPortExecuteLiefertStrukturiertenTextExport() async throws {
        let port = VWPlankopfPort()
        let result = try await port.execute(basket: plankopfKorb(), ziel: PortZiel(kind: "download"))
        #expect(result.erfolg)
        let data = try #require(result.nutzlast)
        let text = try #require(String(data: data, encoding: .utf8))
        #expect(text.contains("Projekt-Nr.: 2026-015"))
        #expect(text.contains("KUNDE:"))
        #expect(text.contains("Familie Cirnavuk"))
        #expect(text.contains("GERÄTE:"))
        #expect(text.contains("Backofen Bosch"))
        #expect(text.contains("AUSSTATTUNG:"))
        #expect(text.contains("LED-Lichtband"))
        #expect(text.contains("BESCHLÄGE:"))
        #expect(text.contains("Blum Legrabox"))
        #expect(text.contains("SONSTIGE ARTIKEL:"))
        #expect(text.contains("Kleinteile"))
        // Tabellen-Kopfzeile im Vokabular der echten Häfele-Beschläge-Exporte.
        #expect(text.contains("Pos. | Artikel | Bezeichnung | Lieferant | Menge | Einzelpreis | Gesamtpreis"))
        #expect(result.referenz == "WK-2026-015-0003")
    }

    @Test func plankopfPortExecuteFehlendeArtikelAttributeZeigenGedankenstrich() async throws {
        // Kein "artikelnummer"/"lieferant"-Attribut gesetzt -> ehrlich "—" statt Erfindung.
        let port = VWPlankopfPort()
        let ohneAttribute = BasicPick(
            matrix: .artikel,
            objektID: CatalogObjectID("art-x"),
            snapshot: PickSnapshot(bezeichnung: "Sockelleiste", menge: 2, vkEinzel: 10, attribute: ["kategorie": "geraet"])
        )
        let basket = WorkBasket(id: WorkBasketID("WK-attr"), projektNummer: "2026-020", inhaltsArt: .artikel, picks: [ohneAttribute])
        let result = try await port.execute(basket: basket, ziel: PortZiel(kind: "download"))
        let data = try #require(result.nutzlast)
        let text = try #require(String(data: data, encoding: .utf8))
        #expect(text.contains("1 | — | Sockelleiste | — | 2 | 10.00 € | 20.00 €"))
    }

    @Test func plankopfPortExecuteBauvorhabenUndKommissionAusZielParametern() async throws {
        let port = VWPlankopfPort()
        let ziel = PortZiel(kind: "download", parameter: ["bauvorhaben": "Küche Neubau Cirnavuk", "kommission": "KOM-4711"])
        let result = try await port.execute(basket: plankopfKorb(), ziel: ziel)
        let data = try #require(result.nutzlast)
        let text = try #require(String(data: data, encoding: .utf8))
        #expect(text.contains("Bauvorhaben: Küche Neubau Cirnavuk"))
        #expect(text.contains("Kommission: KOM-4711"))
    }

    @Test func plankopfPortExecuteOhneBauvorhabenUndKommissionBleibenWeg() async throws {
        let port = VWPlankopfPort()
        let result = try await port.execute(basket: plankopfKorb(), ziel: PortZiel(kind: "download"))
        let data = try #require(result.nutzlast)
        let text = try #require(String(data: data, encoding: .utf8))
        #expect(text.contains("Bauvorhaben:") == false)
        #expect(text.contains("Kommission:") == false)
    }

    @Test func plankopfPortExecuteLeererKorbNurProjektzeile() async throws {
        let port = VWPlankopfPort()
        let leer = WorkBasket(id: WorkBasketID("WK-leer"), projektNummer: "2026-000", inhaltsArt: .gemischt)
        let result = try await port.execute(basket: leer, ziel: PortZiel(kind: "download"))
        #expect(result.erfolg)
        let data = try #require(result.nutzlast)
        let text = try #require(String(data: data, encoding: .utf8))
        #expect(text.contains("Projekt-Nr.: 2026-000"))
        #expect(text.contains("KUNDE:") == false)
    }

    @Test func registryFiltertEchteC2Ports() {
        var registry = PortRegistry()
        registry.registriere(DokumentPort())
        registry.registriere(MoodboardPort())
        registry.registriere(FireflyPromptPort(client: ScriptedConversing(antwortText: "x")))
        let rechte = AllowAllPortRights(alleBekanntenPorts: registry.alleBekanntenPortIDs)

        // .artikel → nur DokumentPort.
        let fuerArtikel = registry.ports(fuer: .artikel, userID: "u1", rechte: rechte)
        #expect(fuerArtikel.map { $0.id } == [PortID("dokument")])

        // .bilder → Moodboard + Firefly (nicht Dokument).
        let fuerBilder = Set(registry.ports(fuer: .bilder, userID: "u1", rechte: rechte).map { $0.id })
        #expect(fuerBilder == [PortID("moodboard"), PortID("firefly-prompt")])
    }
}
