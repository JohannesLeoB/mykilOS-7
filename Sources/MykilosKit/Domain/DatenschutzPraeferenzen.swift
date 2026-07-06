import Foundation

// MARK: - DatenschutzPraeferenzen (Vision-Doku "Nutzerprofil & Datenschutz", Stufe 3)
// Was ein Bewohner mit dem Assistenten teilt — einzeln toggelbar (opt-in/opt-out, kein
// Blanko-Konsens laut Backlog) + ein globaler "KI komplett aus"-Schalter. Diese Werte sind
// eine ERKLÄRTE PRÄFERENZ, die AppState beim Aufbau des Assistenten-Kontexts respektiert
// (AssistantGrounding lässt abgeschaltete Kategorien aus) — kein Ersatz für die technische
// Per-User-Isolation (die gilt immer, unabhängig von diesen Schaltern).
public struct DatenschutzPraeferenzen: Codable, Equatable, Sendable {
    public var teileMailMitAssistent: Bool
    public var teileNotizenMitAssistent: Bool
    public var teileChatMitAssistent: Bool
    public var teileClockodoMitAssistent: Bool
    public var kiKomplettAus: Bool
    public var updatedAt: Date

    public init(
        teileMailMitAssistent: Bool = true,
        teileNotizenMitAssistent: Bool = true,
        teileChatMitAssistent: Bool = true,
        teileClockodoMitAssistent: Bool = true,
        kiKomplettAus: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.teileMailMitAssistent = teileMailMitAssistent
        self.teileNotizenMitAssistent = teileNotizenMitAssistent
        self.teileChatMitAssistent = teileChatMitAssistent
        self.teileClockodoMitAssistent = teileClockodoMitAssistent
        self.kiKomplettAus = kiKomplettAus
        self.updatedAt = updatedAt
    }

    public static let standard = DatenschutzPraeferenzen()
}
