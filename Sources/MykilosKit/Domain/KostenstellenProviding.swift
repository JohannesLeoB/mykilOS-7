import Foundation

// MARK: - KostenstellenProviding
// mykilOS 8, Block C (S2): Abstraktion über die Kostenstellen-Quelle eines Projekts.
// Der Block-C-Vertrag will sie „live aus dem Airtable-Projektfeld" — dieses Feld
// existiert heute aber noch nicht. Johannes' Entscheidung (2026-07-01): Provider-
// Abstraktion + Default jetzt, Airtable-Quelle fertig verdrahtet, sobald Daniel ein Feld
// anlegt. Kein Drängen, kein Blocker. So tauscht S2 später nur die Implementierung.
public protocol KostenstellenProviding: Sendable {
    /// Kostenstellen für ein Projekt. `projektNummer` erlaubt projektabhängige Quellen.
    func kostenstellen(fuer projektNummer: String) -> [Kostenstelle]
}

// MARK: - DefaultKostenstellenProvider
// Liefert die Default-Liste (aus S1) — plus optionale, lokal pro Projekt gesetzte
// Overrides. Das ist die aktive Quelle, bis ein Airtable-Projektfeld existiert.
public struct DefaultKostenstellenProvider: KostenstellenProviding {
    private let overrides: [String: [Kostenstelle]]
    public init(overrides: [String: [Kostenstelle]] = [:]) {
        self.overrides = overrides
    }
    public func kostenstellen(fuer projektNummer: String) -> [Kostenstelle] {
        // Eine LEERE Override-Liste ist semantisch „kein Override" — sonst stünde der
        // Timer ohne jede Kostenstelle da (keine Buchung möglich). Fällt auf Defaults zurück.
        if let o = overrides[projektNummer], o.isEmpty == false { return o }
        return Kostenstelle.defaults
    }
}
