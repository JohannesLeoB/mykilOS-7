import Foundation
import MykilosKit

// MARK: - ContactImportPlanner (Google→Airtable-Import, 2026-07-04)
// Reine, testbare Entscheidungslogik für den Kontakte-Import — kein Netzwerk, kein Airtable-
// Write hier. Entschieden (Johannes 2026-07-02): Airtable wird die Wahrheit für Projekt-
// Kontakte; Google-Kontakte ohne Mail/Telefon werden verworfen (kein Wert ohne Kontaktweg),
// Dubletten (Mail ODER Telefon stimmt mit einem bestehenden Airtable-Kontakt überein) werden
// übersprungen statt dupliziert. Der eigentliche Write läuft — wie jeder Airtable-Schreibpfad
// in dieser App — über eine Bestätigungskarte (`AppState.writeAirtableContact`, `.create`),
// NIE automatisch aus dieser Funktion heraus.
public enum ContactImportDecision: Sendable, Equatable {
    case create
    case duplicate(existingRecordID: String)
    case skipIncomplete
}

public struct ContactImportCandidate: Sendable, Equatable, Identifiable {
    public let id: String
    public let googleContact: GoogleContact
    public let decision: ContactImportDecision

    public init(googleContact: GoogleContact, decision: ContactImportDecision) {
        self.id = googleContact.id
        self.googleContact = googleContact
        self.decision = decision
    }
}

public enum ContactImportPlanner {
    /// Plant den Import: jeder Google-Kontakt bekommt genau eine Entscheidung.
    /// Reihenfolge der Prüfung: unvollständig (weder Mail noch Telefon) → Dublette
    /// (Mail- oder Telefon-Treffer gegen `existing`) → sonst neu anlegen.
    public static func plan(googleContacts: [GoogleContact], existing: [StudioContact]) -> [ContactImportCandidate] {
        var emailIndex: [String: String] = [:]   // normalisierte Mail → Airtable-Record-ID
        var phoneIndex: [String: String] = [:]   // normalisierte Ziffernfolge → Airtable-Record-ID
        for contact in existing {
            if let mail = normalizedEmail(contact.email) { emailIndex[mail] = contact.id }
            if let phone = normalizedPhone(contact.telefon) { phoneIndex[phone] = contact.id }
        }

        return googleContacts.map { contact in
            let mail = normalizedEmail(contact.email)
            let phone = normalizedPhone(contact.phone)

            guard mail != nil || phone != nil else {
                return ContactImportCandidate(googleContact: contact, decision: .skipIncomplete)
            }
            if let mail, let recordID = emailIndex[mail] {
                return ContactImportCandidate(googleContact: contact, decision: .duplicate(existingRecordID: recordID))
            }
            if let phone, let recordID = phoneIndex[phone] {
                return ContactImportCandidate(googleContact: contact, decision: .duplicate(existingRecordID: recordID))
            }
            return ContactImportCandidate(googleContact: contact, decision: .create)
        }
    }

    /// Entwurf für einen bestätigten Neu-Kandidaten. `nil` für Dubletten/Unvollständige —
    /// die werden nie geschrieben.
    public static func draft(for candidate: ContactImportCandidate) -> AirtableContactDraft? {
        guard candidate.decision == .create else { return nil }
        let c = candidate.googleContact
        return AirtableContactDraft(
            intent: .create,
            name: c.displayName,
            organisation: c.organization,
            email: c.email,
            telefon: c.phone
        )
    }

    static func normalizedEmail(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.isEmpty ? nil : trimmed
    }

    static func normalizedPhone(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let digits = raw.filter(\.isNumber)
        return digits.isEmpty ? nil : digits
    }
}
