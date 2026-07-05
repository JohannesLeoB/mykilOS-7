import Foundation
import Observation
import MykilosKit

// MARK: - NutzerProvisioningService
// Bewohner-Oberfläche: die idempotente Anlage eines Menschen-/Team-Records in Airtable
// (find-or-create über die E-Mail). Analoges Muster zu `ProjektProvisioningService`,
// aber bewusst SCHLANKER — nur ein Airtable-Schritt, kein Drive, kein ClickUp, kein
// Ledger (ein einziger Find-or-Create-Aufruf braucht keine Teilfehler-Wiederaufnahme).
//
// Garantien:
//  · IDEMPOTENT (Schlüssel E-Mail, case-insensitiv getrimmt): ein zweiter Aufruf mit
//    derselben Mail findet den nun existierenden Record — KEIN Duplikat.
//  · APPEND-ONLY: nur CREATE bei Nicht-Fund. NIEMALS Update, NIEMALS Delete.
//  · NUR die Base `appuVMh3KDfKw4OoQ` / Tabelle `tblPbly2br8mR2kaU` (Clockodo-Nutzer).
//    Fix referenziert — kein Aufrufer kann versehentlich eine andere Base/Tabelle einspeisen.
@MainActor
@Observable
public final class NutzerProvisioningService {
    /// Fixe Ziel-Base (Mastermind-Schaltzentrale) — nicht parametrisierbar.
    public static let baseID = "appuVMh3KDfKw4OoQ"
    /// Fixe Ziel-Tabelle (Clockodo-Nutzer) — nicht parametrisierbar.
    public static let tabelle = "Clockodo-Nutzer"

    public private(set) var saveState: SaveState = .idle

    private let airtableFetch: any AirtableFetching
    private let airtableCreate: any AirtableRecordCreating
    // Review-Fix-Muster wie ProjektProvisioningService: austauschbar für Tests
    // (Fakes kennen keine echte Base/Tabelle), im Live-Betrieb IMMER die echte,
    // unveränderliche `AirtableClient.writableMap`.
    private let isWritable: (String, String) -> Bool

    public init(
        airtableFetch: any AirtableFetching,
        airtableCreate: any AirtableRecordCreating,
        isWritable: @escaping (String, String) -> Bool = AirtableClient.isWritable
    ) {
        self.airtableFetch = airtableFetch
        self.airtableCreate = airtableCreate
        self.isWritable = isWritable
    }

    /// Findet den Nutzer-Record per `E-Mail` (case-insensitiv getrimmt) oder legt GENAU
    /// EINEN neuen an (`Name`=displayName, `E-Mail`=googleEmail, `Aktiv`=true). Gibt die
    /// Airtable-Record-ID zurück. Idempotent: ein zweiter Aufruf mit derselben Mail
    /// erzeugt kein Duplikat, sondern liefert dieselbe ID.
    @discardableResult
    public func findOrCreate(googleEmail: String, displayName: String) async throws -> String {
        guard isWritable(Self.baseID, Self.tabelle) else {
            throw ProvisioningError.schrittFehlgeschlagen(
                .airtableRecord,
                "Tabelle \(Self.tabelle)@\(Self.baseID) ist nicht schreibbar — "
                + "zuerst mit Johannes auf die Airtable-Schreib-Freigabeliste setzen lassen.")
        }

        saveState = .saving
        do {
            if let bestehendeID = try await findeBestehendenRecord(email: googleEmail) {
                saveState = .saved(Date())
                return bestehendeID
            }

            let felder: [String: AirtableFieldValue] = [
                "Name": .string(displayName),
                "E-Mail": .string(googleEmail),
                "Aktiv": .string("true")
            ]
            let recordID = try await airtableCreate.createRecord(baseID: Self.baseID, table: Self.tabelle, fields: felder)
            saveState = .saved(Date())
            return recordID
        } catch {
            saveState = .failed(String(describing: error))
            throw error
        }
    }

    /// Sucht einen bestehenden Nutzer-Record per `E-Mail` (case-insensitiv getrimmt).
    /// Read-only — ein Fehler hier ist NICHT nicht-fatal geschluckt, sondern wird
    /// weitergereicht (anders als ProjektProvisioningService: hier gibt es keinen
    /// zweiten Fallback-Pfad, ein stiller Schluck-Fehler würde ein Duplikat riskieren).
    private func findeBestehendenRecord(email: String) async throws -> String? {
        let needle = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let records = try await airtableFetch.fetchRecords(baseID: Self.baseID, table: Self.tabelle)
        let treffer = records.first { fields in
            let rowEmail = (fields["E-Mail"]?.stringValue ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return rowEmail.isEmpty == false && rowEmail == needle
        }
        return treffer?["_airtableRecordID"]?.stringValue
    }
}
