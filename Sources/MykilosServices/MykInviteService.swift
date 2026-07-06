import Foundation
import MykilosKit

// MARK: - MykInviteService (Onboarding-Plan Ebene 2)
// Baut/verarbeitet .mykinvite-Dateien für geteilte Zugangsdaten. V1 (Claude-Entscheidung):
// nur Airtable-PAT + Base-ID — reine Orchestrierung über die bestehende
// AirtableCredentialsStoring/AirtableAuthService, kein neuer Speicherort für Secrets.
public enum MykInviteService {
    /// Admin: baut eine .mykinvite-Datei aus den AKTUELL verbundenen Airtable-Zugangsdaten.
    public static func einladungErstellen(
        airtableCredentials: AirtableCredentialsStoring,
        passwort: String,
        gueltigTage: Int? = 7
    ) throws -> Data {
        guard let creds = try airtableCredentials.load() else {
            throw MykInviteError.keineZugangsdatenVerbunden
        }
        let ablauf = gueltigTage.map { Date().addingTimeInterval(TimeInterval($0 * 86_400)) }
        let payload = MykInvitePayload(
            werte: [
                MykInvitePayload.Schluessel.airtablePAT: creds.pat,
                MykInvitePayload.Schluessel.airtableBaseID: creds.baseID
            ],
            ablaufAm: ablauf
        )
        return try MykInviteCrypto.verschluesseln(payload, passwort: passwort)
    }

    /// Neuer User: entschlüsselt eine .mykinvite-Datei und legt die Keys in den Keychain
    /// (über denselben Store, den auch das Settings-Formular befüllt).
    public static func einladungOeffnen(
        daten: Data,
        passwort: String,
        airtableCredentials: AirtableCredentialsStoring
    ) throws {
        let payload = try MykInviteCrypto.entschluesseln(daten, passwort: passwort)
        guard let pat = payload.werte[MykInvitePayload.Schluessel.airtablePAT],
              let baseID = payload.werte[MykInvitePayload.Schluessel.airtableBaseID] else {
            throw MykInviteError.kaputteDatei
        }
        try airtableCredentials.store(AirtableCredentials(pat: pat, baseID: baseID))
    }
}
