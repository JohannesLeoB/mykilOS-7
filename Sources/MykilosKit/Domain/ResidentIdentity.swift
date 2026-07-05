import Foundation

// MARK: - ResidentIdentity ("Personalausweis")
// Der lokale, local-first Identitäts-Anker eines/einer Nutzer:in. Anders als
// UserProfile (Anzeigename + Rolle, das was der Mensch tippt) trägt der
// Personalausweis das, was extern verifiziert/aufgelöst ist: die verifizierte
// Google-Mail als KANONISCHER Schlüssel plus reine Handles/IDs zu den
// externen Systemen (Clockodo, ClickUp, Airtable).
//
// EISERNE REGEL: Der Ausweis trägt NIEMALS ein Secret (kein Token, PAT,
// apiKey). Tokens bleiben ausschließlich im per-User-Keychain. Hier stehen
// nur Referenzen/Handles.
//
// Reine Domäne: Foundation-only, kein SwiftUI, kein GRDB.
public struct ResidentIdentity: Equatable, Sendable, Codable {
    // KANONISCHER SCHLÜSSEL: die volle verifizierte Google-Mail
    // (z. B. "johannes@mykilos.com" — NIE nur die Domain). Nicht optional:
    // der Ausweis existiert nur, wenn eine verifizierte Mail vorliegt. Ein
    // leerer Schlüssel ("") ist verboten (geteilter Anker-Kollaps) — die
    // Nicht-Leer-Invariante wird im Store hart erzwungen.
    public var googleEmail: String
    // Brücke zur bestehenden First-Run-UUID/Keychain-Suffixen. Nicht optional:
    // ein Ausweis ohne userID kann keine Keychain-Suffixe verankern.
    public var userID: String
    // Anzeigename aus Airtable Clockodo-Nutzer (optional, tolerant).
    public var displayName: String?
    // Handle (heute manuell abgetippt; künftig read-only aus Airtable aufgelöst).
    public var clockodoUserID: String?
    // Airtable-Entwurf-Tabellen-ID (persönliche EW-Tabelle des Users).
    public var clockodoEntwurfsTabelle: String?
    // Optional, read-only; für V1 leer lassbar (keine Quelle verdrahtet).
    public var clickUpMemberID: String?
    // Clockodo-Nutzer-Record-ID (aus _airtableRecordID).
    public var airtableRecordID: String?
    public var updatedAt: Date

    public init(
        googleEmail: String,
        userID: String,
        displayName: String? = nil,
        clockodoUserID: String? = nil,
        clockodoEntwurfsTabelle: String? = nil,
        clickUpMemberID: String? = nil,
        airtableRecordID: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.googleEmail = googleEmail
        self.userID = userID
        self.displayName = displayName
        self.clockodoUserID = clockodoUserID
        self.clockodoEntwurfsTabelle = clockodoEntwurfsTabelle
        self.clickUpMemberID = clickUpMemberID
        self.airtableRecordID = airtableRecordID
        self.updatedAt = updatedAt
    }

    /// Nicht-Leer-Invariante für den kanonischen Schlüssel: ein leerer/nur-
    /// Whitespace Primary Key wäre ein geteilter Anker (derselbe Namespace-
    /// Kollaps wie der "local"-Fallback). Store + Lookups erzwingen das.
    public var hasValidKey: Bool {
        googleEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}
