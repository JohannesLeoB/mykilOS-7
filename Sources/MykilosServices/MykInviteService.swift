import Foundation
import MykilosKit

// MARK: - MykInviteService (Onboarding-Plan Ebene 2)
// Baut/verarbeitet .mykinvite-Dateien für geteilte Zugangsdaten. V1 (Claude-Entscheidung):
// nur Airtable-PAT + Base-ID — reine Orchestrierung über die bestehende
// AirtableCredentialsStoring/AirtableAuthService, kein neuer Speicherort für Secrets.
public enum MykInviteService {
    /// Generisch: baut eine .mykinvite-Datei aus einem fertig zusammengestellten Key-Value-
    /// Bündel + optionalen Metadaten (für wen). Rein: keine Store-Zugriffe, voll testbar. Das
    /// EINSAMMELN der Werte aus den einzelnen Auth-Services macht der Aufrufer (AppState),
    /// der die Stores kennt. Leeres Bündel → nichts zu teilen.
    public static func einladungErstellen(
        werte: [String: String],
        eingeladeneEmail: String? = nil,
        eingeladenerName: String? = nil,
        passwort: String,
        gueltigTage: Int? = 7
    ) throws -> Data {
        guard werte.isEmpty == false else { throw MykInviteError.keineZugangsdatenVerbunden }
        let ablauf = gueltigTage.map { Date().addingTimeInterval(TimeInterval($0 * 86_400)) }
        let payload = MykInvitePayload(
            werte: werte,
            ablaufAm: ablauf,
            eingeladeneEmail: eingeladeneEmail?.trimmingCharacters(in: .whitespacesAndNewlines),
            eingeladenerName: eingeladenerName?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        return try MykInviteCrypto.verschluesseln(payload, passwort: passwort)
    }

    /// Rein: entschlüsselt eine .mykinvite-Datei zum typisierten Payload (wirft bei falschem
    /// Passwort/kaputt/abgelaufen). Die VERTEILUNG der Keys in die einzelnen Stores macht der
    /// Aufrufer (AppState) — so bleibt die Krypto/Format-Schicht ohne Store-Kopplung testbar.
    public static func einladungLesen(daten: Data, passwort: String) throws -> MykInvitePayload {
        try MykInviteCrypto.entschluesseln(daten, passwort: passwort)
    }

    // MARK: - Airtable-Bequemlichkeit (Rückwärtskompatibilität)
    // Die bestehenden Airtable-only-Aufrufer (AirtableAuthService, Settings-UI, Tests) bleiben
    // unverändert nutzbar — sie delegieren jetzt an den generischen Pfad oben.

    /// Admin: baut eine .mykinvite-Datei aus den AKTUELL verbundenen Airtable-Zugangsdaten.
    public static func einladungErstellen(
        airtableCredentials: AirtableCredentialsStoring,
        passwort: String,
        gueltigTage: Int? = 7
    ) throws -> Data {
        guard let creds = try airtableCredentials.load() else {
            throw MykInviteError.keineZugangsdatenVerbunden
        }
        return try einladungErstellen(
            werte: [
                MykInvitePayload.Schluessel.airtablePAT: creds.pat,
                MykInvitePayload.Schluessel.airtableBaseID: creds.baseID
            ],
            passwort: passwort,
            gueltigTage: gueltigTage
        )
    }

    /// Neuer User: entschlüsselt eine .mykinvite-Datei und legt die Airtable-Keys in den Keychain.
    public static func einladungOeffnen(
        daten: Data,
        passwort: String,
        airtableCredentials: AirtableCredentialsStoring
    ) throws {
        let payload = try einladungLesen(daten: daten, passwort: passwort)
        guard let pat = payload.werte[MykInvitePayload.Schluessel.airtablePAT],
              let baseID = payload.werte[MykInvitePayload.Schluessel.airtableBaseID] else {
            throw MykInviteError.kaputteDatei
        }
        try airtableCredentials.store(AirtableCredentials(pat: pat, baseID: baseID))
    }
}
