import Contacts

enum KontaktFehler: Error, LocalizedError {
    case keineBerechtigung
    case speichernFehlgeschlagen(String)

    var errorDescription: String? {
        switch self {
        case .keineBerechtigung: return "Keine Berechtigung für Kontakte erteilt."
        case .speichernFehlgeschlagen(let text): return "Kontakt nicht anlegbar: \(text)"
        }
    }
}

/// Schreibt EINEN neuen Kontakt in die iOS-Kontakte — reine on-device
/// Berechtigung (Contacts-Framework), kein externes Konto, kein OAuth.
/// Kein Auto-Write: nur nach expliziter Bestätigung in der Karte.
enum KontaktSchreiber {
    static func berechtigungAnfragen() async -> Bool {
        await withCheckedContinuation { continuation in
            CNContactStore().requestAccess(for: .contacts) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    static func anlegen(vorname: String, nachname: String, firma: String, telefon: String, email: String) throws {
        let kontakt = CNMutableContact()
        kontakt.givenName = vorname
        kontakt.familyName = nachname
        if !firma.isEmpty {
            kontakt.organizationName = firma
        }
        if !telefon.isEmpty {
            kontakt.phoneNumbers = [CNLabeledValue(label: CNLabelWork, value: CNPhoneNumber(stringValue: telefon))]
        }
        if !email.isEmpty {
            kontakt.emailAddresses = [CNLabeledValue(label: CNLabelWork, value: email as NSString)]
        }

        let saveRequest = CNSaveRequest()
        saveRequest.add(kontakt, toContainerWithIdentifier: nil)
        do {
            try CNContactStore().execute(saveRequest)
        } catch {
            throw KontaktFehler.speichernFehlgeschlagen(error.localizedDescription)
        }
    }
}
