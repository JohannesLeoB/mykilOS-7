import Foundation

// MARK: - IntakeSchreibFehler
// Fehler-Enum für den gated Schreibpfad `AppState.erzeugeKundeUndProjekt`.
// Foundation-only, kein SwiftUI, kein GRDB.
public enum IntakeSchreibFehler: Error, LocalizedError, Sendable {
    case nichtVerbunden
    case whitelist(String)
    case http(Int)
    case allgemein(String)

    public var errorDescription: String? {
        switch self {
        case .nichtVerbunden:
            return "Airtable nicht verbunden — Personal Access Token in den Einstellungen eintragen."
        case .whitelist(let msg):
            return "Schreibschutz verletzt: \(msg)"
        case .http(let code) where code == 401 || code == 403:
            return "Airtable-Token hat keine Schreibrechte (Fehler \(code)). Token mit Scope data.records:write erstellen."
        case .http(let code):
            return "Airtable-Fehler HTTP \(code)"
        case .allgemein(let msg):
            return msg
        }
    }
}
