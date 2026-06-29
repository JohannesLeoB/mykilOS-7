import Foundation

// MARK: - AssistantModelRouter (S26)
// Wählt pro Anfrage das GÜNSTIGSTE Claude-Modell, das der Aufgabe gewachsen ist —
// statt fix das in den Credentials gespeicherte. Reine, testbare Logik (kein Netz,
// kein Keychain). Drei Stufen, von günstig nach teuer:
//   • Haiku  — einfache, kurze Konversation (Default, günstigste).
//   • Sonnet — Tool-Use (mehrstufige Datenabrufe) oder komplexe Freitext-Aufgaben.
//   • Opus   — Kostenschätzung/Kalkulation (Geld, mehrstufig, teuer wenn falsch).
public enum AssistantModelRouter {
    public static let haiku  = "claude-haiku-4-5-20251001"
    public static let sonnet = "claude-sonnet-4-6"
    public static let opus   = "claude-opus-4-8"

    /// Günstigstes Modell für diese Runde.
    public static func model(latestUserText: String, toolsEnabled: Bool, schaetzModus: Bool) -> String {
        let text = latestUserText.lowercased()
        if schaetzModus || mentionsEstimation(text) { return opus }   // Geld/Kalkulation → bestes Reasoning
        if toolsEnabled { return sonnet }                             // mehrstufige Tool-Schleifen
        if isComplex(text) { return sonnet }                          // lange/komplexe Freitext-Aufgabe
        return haiku                                                  // einfache, kurze Konversation
    }

    /// Kurzes, anzeigbares Kürzel (HAIKU/SONNET/OPUS) für die UI-Quellzeile.
    public static func tierLabel(_ model: String) -> String {
        let lower = model.lowercased()
        if lower.contains("haiku")  { return "HAIKU" }
        if lower.contains("opus")   { return "OPUS" }
        if lower.contains("sonnet") { return "SONNET" }
        return model.uppercased()
    }

    // Kostenschätzungs-Signale (bewusst eng — reine Tool-Suche nach „Angeboten" soll
    // NICHT auf Opus eskalieren, das ist Sonnet-Arbeit).
    static func mentionsEstimation(_ text: String) -> Bool {
        let keywords = ["schätz", "schaetz", "kalkul", "budget", "marge", "kostenvoranschlag",
                        "was kostet", "wieviel kostet", "kosten für", "preis pro", "€", "euro"]
        return keywords.contains { text.contains($0) }
    }

    static func isComplex(_ text: String) -> Bool {
        if text.split(whereSeparator: { $0 == " " || $0 == "\n" }).count > 40 { return true }
        let hard = ["warum", "erkläre", "erklär", "vergleich", "analys",
                    "strategie", "begründ", "schritt für schritt", "plane "]
        return hard.contains { text.contains($0) }
    }
}
