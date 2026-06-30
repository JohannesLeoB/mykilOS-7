import Foundation

// MARK: - AirtableContactDraft (S19)
// Entwurf für einen neuen oder geänderten Airtable-Kontakt. Bewusst nur ein
// ENTWURF — er wird NIE automatisch geschrieben. Erst eine ausdrückliche
// Bestätigung über die Action-Card legt ihn via AirtableClient.createRecord /
// updateRecord an (+ Audit-Eintrag). KEIN Delete — existiert nicht.
public struct AirtableContactDraft: Codable, Sendable, Equatable {
    public enum Intent: String, Codable, Sendable, Equatable {
        case create  // neuer Kontakt → POST
        case update  // Felder ändern → PATCH (braucht recordID)
    }

    public var intent: Intent
    /// Airtable-Record-ID — nur bei `.update` gesetzt.
    public var recordID: String?
    public var name: String
    public var organisation: String?
    public var email: String?
    public var telefon: String?
    public var adresse: String?
    public var kategorie: String?

    public init(intent: Intent, recordID: String? = nil, name: String,
                organisation: String? = nil, email: String? = nil,
                telefon: String? = nil, adresse: String? = nil,
                kategorie: String? = nil) {
        self.intent = intent
        self.recordID = recordID
        self.name = name
        self.organisation = organisation
        self.email = email
        self.telefon = telefon
        self.adresse = adresse
        self.kategorie = kategorie
    }

    /// Anzeigename für Karten/Logs.
    public var displayName: String { name }

    /// Felder für den Airtable-Write-Payload (nur nicht-nil Felder).
    public var airtableFields: [String: String] {
        var f: [String: String] = ["Name": name]
        if let v = organisation { f["Organisation"] = v }
        if let v = email        { f["E-Mail"] = v }
        if let v = telefon      { f["Telefon"] = v }
        if let v = adresse      { f["Adresse"] = v }
        if let v = kategorie    { f["Kategorie"] = v }
        return f
    }
}

// MARK: - AirtableContactWriteOutcome (S19)
// Ergebnis einer bestätigten Kontaktoperation. Bewusst kein Result<…, Error>
// (Karte muss Sendable bleiben, kein Error-Typ über Module).
public enum AirtableContactWriteOutcome: Sendable, Equatable {
    case created(String)   // Anzeigename des angelegten Kontakts
    case updated(String)   // Anzeigename des aktualisierten Kontakts
    case failed(String)    // menschenlesbare Fehlermeldung
}
