import Foundation
import MykilosKit
import MykilosServices

// MARK: - FireflyPromptPort (Wirbelsäule C2, §4 „Erste native Ports")
//
// Dritter nativer CheckoutPort: baut aus Material-/Moodboard-Picks + Kontext
// einen Text-Prompt für Adobe Firefly. Nutzt den bestehenden Claude-Client
// (`AssistantConversing`, konkret `ClaudeChatClient` in MykilosServices).
//
// ⚠️ HART TEXT-ONLY (HANDOFF §2c, §5h): Dieser Port erzeugt AUSSCHLIESSLICH
// einen Prompt-TEXT (Copy), den ein Mensch später selbst in Firefly einfügt.
//   - KEINE Bilderzeugung.
//   - KEIN Adobe-/Firefly-API-Call.
//   - KEIN Bild-Payload — das Ergebnis landet als reiner Text in
//     `CheckoutResult.meldung`.
// Der Claude-Aufruf läuft über `respond(...)` MIT LEERER Tool-Liste, damit die
// Antwort garantiert nur Text ist (kein tool_use).
//
// Der Client wird injiziert → im automatisierten Test steckt ein Scripted-Double,
// kein echtes Netzwerk/Keychain (Muster wie ClaudeMessagesClientTests).
public struct FireflyPromptPort: CheckoutPort {

    public let id: PortID
    public let name: String
    private let client: any AssistantConversing
    private let maxTokens: Int

    public init(
        client: any AssistantConversing,
        id: PortID = PortID("firefly-prompt"),
        name: String = "Firefly-Prompt (Text)",
        maxTokens: Int = 600
    ) {
        self.client = client
        self.id = id
        self.name = name
        self.maxTokens = maxTokens
    }

    public func erlaubteInhaltsArten() -> Set<InhaltsArt> {
        [.bilder, .material, .zeichnungen]
    }

    // MARK: - Vorschau (kein Claude-Aufruf)

    public func preview(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutPreview {
        let anzahl = basket.picks.count
        let kontext = Self.kontext(aus: ziel)
        var warnungen: [String] = []
        if anzahl == 0 {
            warnungen.append("Keine Picks — der Prompt hätte keine Bildreferenzen.")
        }
        let kontextHinweis = kontext.isEmpty ? "" : " · Kontext: \(kontext)"
        let zusammenfassung =
            "Firefly-Prompt (Text) wird aus \(anzahl) Pick\(anzahl == 1 ? "" : "s")\(kontextHinweis) generiert. Kein Bild, kein Adobe-Call."
        return CheckoutPreview(zusammenfassung: zusammenfassung, warnungen: warnungen)
    }

    // MARK: - Ausführung (liefert NUR Text)

    public func execute(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutResult {
        // Picks materialisieren (Rückverfolgbarkeit) und zu Beschreibungszeilen verdichten.
        var zeilen: [String] = []
        for pick in basket.picks {
            _ = try await pick.resolve()
            zeilen.append(Self.beschreibe(pick: pick))
        }

        let kontext = Self.kontext(aus: ziel)
        let userText = Self.userPrompt(
            projektNummer: basket.projektNummer,
            kontext: kontext,
            pickZeilen: zeilen
        )

        // WICHTIG: tools: [] → die Antwort ist garantiert reiner Text (kein tool_use).
        let antwort = try await client.respond(
            messages: [.text(userText, role: .user)],
            system: Self.systemPrompt,
            tools: [],
            maxTokens: maxTokens
        )

        let prompt = antwort.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard prompt.isEmpty == false else {
            return CheckoutResult(
                erfolg: false,
                meldung: "Claude hat keinen Prompt-Text geliefert."
            )
        }

        return CheckoutResult(
            erfolg: true,
            referenz: basket.id.description,
            meldung: prompt   // reiner Text — kein Bild-Payload
        )
    }

    // MARK: - Prompt-Bausteine (rein, testbar)

    static let systemPrompt = """
    Du bist ein Prompt-Autor für Adobe Firefly (Bildgenerierung) im Kontext eines \
    Küchen-/Interior-Studios. Deine Aufgabe: aus den gelieferten Bild-/Material-Referenzen \
    einen EINZIGEN, präzisen englischsprachigen Firefly-Prompt formulieren (Stil, Material, \
    Licht, Stimmung, Komposition). Gib NUR den Prompt-Text zurück — keine Erklärung, keine \
    Aufzählung, kein Markdown. Erzeuge KEIN Bild und rufe keine Werkzeuge auf; du lieferst \
    ausschließlich Text.
    """

    static func userPrompt(projektNummer: String, kontext: String, pickZeilen: [String]) -> String {
        let referenzen = pickZeilen.isEmpty
            ? "- (keine Referenzen)"
            : pickZeilen.map { "- \($0)" }.joined(separator: "\n")
        let kontextBlock = kontext.isEmpty ? "" : "\nKontext: \(kontext)"
        return """
        Projekt: \(projektNummer)\(kontextBlock)

        Bild-/Material-Referenzen:
        \(referenzen)

        Formuliere daraus einen einzigen Firefly-Prompt (Englisch).
        """
    }

    static func beschreibe(pick: any Pick) -> String {
        let s = pick.snapshot
        let material = s.attribute["material"].map { " (\($0))" } ?? ""
        return "\(s.bezeichnung)\(material) [\(pick.matrix.rawValue)]"
    }

    /// Freitext-Kontext (Kundenname, Stilwunsch) aus dem Ziel-Parameter „kontext“.
    static func kontext(aus ziel: PortZiel) -> String {
        ziel.parameter["kontext"] ?? ""
    }
}
