import Foundation

/// Ein Kunde aus der Airtable-Mastermind-Base — read-only gespiegelt,
/// neustart-fest gecacht. Airtable bleibt System-of-Record; die App zeigt
/// nur an und verbindet (Anruf/Mail/Karte), sie schreibt NIE zurueck.
struct KundenKontakt: Identifiable, Codable, Hashable {
    let id: String          // Airtable-Record-ID (Referenz, nie Primaerschluessel-Ersatz)
    let name: String
    let telefon: String?
    let email: String?
    let adresse: String?

    var telefonURL: URL? {
        guard let telefon else { return nil }
        let nummer = telefon.filter { "+0123456789".contains($0) }
        guard !nummer.isEmpty else { return nil }
        return URL(string: "tel://\(nummer)")
    }

    var mailURL: URL? {
        guard let email, email.contains("@") else { return nil }
        return URL(string: "mailto:\(email)")
    }

    var kartenURL: URL? {
        guard let adresse,
              let encoded = adresse.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: "https://maps.apple.com/?q=\(encoded)")
    }
}
