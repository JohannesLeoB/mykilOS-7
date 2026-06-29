import Testing
@testable import MykilosServices

struct AssistantModelRouterTests {

    // MARK: Schätzung/Kalkulation → Opus (bestes Reasoning, Geld)
    @Test func schaetzModusWaehltOpus() {
        #expect(AssistantModelRouter.model(latestUserText: "irgendwas", toolsEnabled: true, schaetzModus: true)
                == AssistantModelRouter.opus)
    }

    @Test func kostenfrageWaehltOpus() {
        #expect(AssistantModelRouter.model(latestUserText: "Was kostet eine 4,5m Küche mit Eichenfronten?",
                                           toolsEnabled: false, schaetzModus: false) == AssistantModelRouter.opus)
        #expect(AssistantModelRouter.model(latestUserText: "Schätz mir mal die Tischlerkosten",
                                           toolsEnabled: false, schaetzModus: false) == AssistantModelRouter.opus)
        #expect(AssistantModelRouter.model(latestUserText: "Wie hoch ist die Marge noch?",
                                           toolsEnabled: false, schaetzModus: false) == AssistantModelRouter.opus)
    }

    // MARK: Tool-Use → Sonnet
    @Test func toolUseWaehltSonnet() {
        #expect(AssistantModelRouter.model(latestUserText: "Suche Mails von Frau Jacob",
                                           toolsEnabled: true, schaetzModus: false) == AssistantModelRouter.sonnet)
    }

    // MARK: Komplexe Freitext-Aufgabe ohne Tools → Sonnet
    @Test func komplexeFrageWaehltSonnet() {
        #expect(AssistantModelRouter.model(latestUserText: "Erkläre mir den Unterschied zwischen den Optionen",
                                           toolsEnabled: false, schaetzModus: false) == AssistantModelRouter.sonnet)
        let lang = String(repeating: "wort ", count: 50)
        #expect(AssistantModelRouter.model(latestUserText: lang, toolsEnabled: false, schaetzModus: false)
                == AssistantModelRouter.sonnet)
    }

    // MARK: Einfache, kurze Konversation → Haiku (günstigste)
    @Test func einfacheFrageWaehltHaiku() {
        #expect(AssistantModelRouter.model(latestUserText: "Hallo, wie geht's?",
                                           toolsEnabled: false, schaetzModus: false) == AssistantModelRouter.haiku)
        #expect(AssistantModelRouter.model(latestUserText: "Danke!",
                                           toolsEnabled: false, schaetzModus: false) == AssistantModelRouter.haiku)
    }

    // MARK: tierLabel
    @Test func tierLabelKuerzelt() {
        #expect(AssistantModelRouter.tierLabel(AssistantModelRouter.haiku) == "HAIKU")
        #expect(AssistantModelRouter.tierLabel(AssistantModelRouter.sonnet) == "SONNET")
        #expect(AssistantModelRouter.tierLabel(AssistantModelRouter.opus) == "OPUS")
    }
}
