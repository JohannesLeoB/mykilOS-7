import Foundation

// MARK: - ClickUpWriteGate (ClickUp-Vollintegration, S4+S10, 2026-07-07)
// Die technische Grenze hinter JEDEM interaktiven ClickUp-Schreibpfad (Status ändern,
// Aufgabe anlegen). Fail-closed: eine unbekannte/nicht auflösbare Space-ID (`nil`) wird
// GENAUSO abgelehnt wie eine fremde Space-ID — es gibt keinen impliziten Vertrauensfall.
// Der Aufrufer löst `spaceID` LIVE über ClickUp auf (nicht aus einer lokalen Vermutung),
// damit die Grenze auch dann hält, wenn eine Projekt-Liste später versehentlich eine echte
// Produktivliste referenziert.
//
// Go-Live (S10) ist eine WHITELIST konkreter Listen-IDs, KEIN Bool-Toggle — jede einzelne
// Liste wird admin-only + einzeln auditiert freigeschaltet (`ClickUpGoLiveWhitelistStore`),
// nie pauschal "alles live". Das ist die technische Umsetzung von "kein Nebeneffekt-Kippen":
// eine allgemeine Bau-Ansage ("weiter") schaltet nie automatisch eine echte Liste frei — nur
// ein expliziter Admin-Akt an genau dieser Liste tut das.
public enum ClickUpWriteGateError: Error, Sendable, Equatable, LocalizedError {
    case nichtErlaubt(listID: String)

    public var errorDescription: String? {
        switch self {
        case .nichtErlaubt(let listID):
            return "🔒 Liste \(listID) ist weder Testspace noch Go-Live-freigegeben. Schreiben gesperrt."
        }
    }
}

public enum ClickUpWriteGate {
    /// "MYKILOS API TESTSPACE" — Zone, in die mykilOS immer interaktiv schreiben darf.
    public static let testspaceID = "90128024109"

    /// Erlaubt, wenn (a) die Liste im Testspace liegt, ODER (b) sie explizit auf der
    /// admin-verwalteten Go-Live-Whitelist steht. Fail-closed sonst (inkl. `spaceID == nil`).
    public static func assertSchreibErlaubt(
        spaceID: String?, listID: String, goLiveWhitelist: Set<String> = []
    ) throws {
        guard spaceID == testspaceID || goLiveWhitelist.contains(listID) else {
            throw ClickUpWriteGateError.nichtErlaubt(listID: listID)
        }
    }
}
