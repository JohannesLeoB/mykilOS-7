import Foundation

// MARK: - NumberAuthority
// mykilOS 8, Block C (S2): der Adapter-Seam für die Projektnummern-Vergabe
// (HANDOFF_PROVISIONING_NOMENKLATUR §8). Nummernvergabe läuft NIE über fest verdrahtete
// Logik, sondern über diese austauschbare Autorität — so kann Sevdesk später „die Wahrheit"
// werden (via Airtable/Make, nie direkt), ohne dass Vergabe-Aufrufer angefasst werden.
//
// Implementierungen (per Config umschaltbar, nicht per Codeänderung):
//   · LocalSequentialAuthority   — max+1 aus aktiven PROJEKTE + Archiv (heute, aktiv)
//   · AirtableAuthority          — Nummernkreis/Reservierung in Airtable (optional, später)
//   · SevdeskPrescribedAuthority — Sevdesk-vorgegeben via Airtable-Feld (Zukunft, vorgesehen)
public protocol NumberAuthority: Sendable {
    /// Nächste freie Projektnummer für das Jahr (max+1 über aktiv + archiviert).
    func nextProjektnummer(jahr: Int) async throws -> Projektnummer
    /// Reserviert eine Nummer (markiert sie als vergeben, damit kein zweiter Aufruf sie zieht).
    func reserve(_ nummer: Projektnummer) async throws
    /// Ist die Nummer vergeben? Prüft AKTIVE und ARCHIVIERTE Nummern (nie wiederverwenden).
    func isVergeben(_ nummer: Projektnummer) async throws -> Bool
    /// Bindet eine extern vorgegebene Nummer (z. B. künftig aus Sevdesk via Airtable/Make).
    func bindFromExternal(quelle: String, nummer: Projektnummer) async throws
}

// MARK: - NumberAuthorityMode
// Per-Config-Umschaltung (HANDOFF_PROVISIONING_NOMENKLATUR §8) — nicht per Codeänderung.
public enum NumberAuthorityMode: String, Codable, Sendable, CaseIterable {
    case local      // LocalSequentialAuthority (aktiv)
    case airtable   // AirtableAuthority (optional)
    case sevdesk    // SevdeskPrescribedAuthority (Zukunft, via Airtable/Make)
}

// MARK: - NumberAuthorityError
public enum NumberAuthorityError: Error, Sendable, Equatable {
    case bereitsVergeben(Projektnummer)   // Kollision aktiv/archiviert
    case unsupported(NumberAuthorityMode) // Implementierung noch nicht verfügbar
    // Härtung (2026-07-01): externer Kollisions-Check (z. B. echter Drive-Ordnerinhalt)
    // fand nach `versuche` Läufen immer noch eine belegte Nummer — echtes Datenproblem,
    // kein Retry-Loop-Bug (siehe LocalSequentialAuthority.nextAndReserveKollisionsfrei).
    case keineKollisionsfreieNummerGefunden(jahr: Int, versuche: Int)
}
