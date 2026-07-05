import Foundation

enum AirtableKundenFehler: Error, LocalizedError {
    case nichtVerbunden
    case httpFehler(Int)

    var errorDescription: String? {
        switch self {
        case .nichtVerbunden:
            return "Kein Airtable-Zugang hinterlegt - in der Postbox verbinden."
        case .httpFehler(let code):
            return code == 403 || code == 404
                ? "Airtable meldet \(code) - der hinterlegte Token braucht Lesezugriff auf die Mastermind-Base."
                : "Airtable meldet Fehler \(code)."
        }
    }
}

/// Liest die Kunden-Tabelle der Mastermind-Base — strikt READ-ONLY
/// (NO-GO-Doktrin: Airtable-Eintraege werden von mobile NIE geschrieben,
/// geaendert oder geloescht; es gibt hier schlicht keine Schreibmethode).
/// Feldnamen werden tolerant gesucht (mehrere Kandidaten je Feld), weil
/// die exakten Spaltennamen der Base von hier nicht verifizierbar sind —
/// fehlt ein Feld, bleibt es leer statt zu raten.
struct AirtableKundenClient {
    static let baseID = "appuVMh3KDfKw4OoQ"   // mykilOS Mastermind (Johannes' eigene Base)
    static let tabelle = "Kunden"

    private let credentialsStore: AirtablePostboxCredentialsStoring

    init(credentialsStore: AirtablePostboxCredentialsStoring = KeychainAirtablePostboxCredentialsStore()) {
        self.credentialsStore = credentialsStore
    }

    func ladeAlle() async throws -> [KundenKontakt] {
        guard let credentials = try? credentialsStore.load() else {
            throw AirtableKundenFehler.nichtVerbunden
        }

        var ergebnis: [KundenKontakt] = []
        var offset: String?
        repeat {
            var komponenten = URLComponents(string: "https://api.airtable.com/v0/\(Self.baseID)/\(Self.tabelle)")!
            var query = [URLQueryItem(name: "pageSize", value: "100")]
            if let offset { query.append(URLQueryItem(name: "offset", value: offset)) }
            komponenten.queryItems = query

            var request = URLRequest(url: komponenten.url!)
            request.setValue("Bearer \(credentials.pat)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw AirtableKundenFehler.httpFehler(http.statusCode)
            }

            let seite = try JSONDecoder().decode(KundenSeite.self, from: data)
            ergebnis.append(contentsOf: seite.records.compactMap { $0.alsKontakt })
            offset = seite.offset
        } while offset != nil

        return ergebnis.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

private struct KundenSeite: Decodable {
    let records: [KundenRecord]
    let offset: String?
}

private struct KundenRecord: Decodable {
    let id: String
    let fields: [String: LeseWert]

    var alsKontakt: KundenKontakt? {
        func erster(_ kandidaten: [String]) -> String? {
            for name in kandidaten {
                if let wert = fields[name]?.text, !wert.isEmpty { return wert }
            }
            return nil
        }
        guard let name = erster(["Name", "Kunde", "Kundenname"]) else { return nil }
        return KundenKontakt(
            id: id,
            name: name,
            telefon: erster(["Telefon", "Telefonnummer", "Handy", "Mobil", "Phone"]),
            email: erster(["E-Mail", "Email", "Mail", "E-Mail-Adresse"]),
            adresse: erster(["Adresse", "Anschrift", "Address", "Ort"])
        )
    }
}

/// Toleranter Lese-Wert: Airtable-Felder koennen String/Zahl/Bool/Listen
/// sein — alles wird auf einen anzeigbaren Text reduziert, nichts wirft.
private enum LeseWert: Decodable {
    case text(String)
    case zahl(Double)
    case wahrheit(Bool)
    case liste([String])
    case unbekannt

    init(from decoder: Decoder) throws {
        let einzel = try decoder.singleValueContainer()
        if let s = try? einzel.decode(String.self) { self = .text(s); return }
        if let d = try? einzel.decode(Double.self) { self = .zahl(d); return }
        if let b = try? einzel.decode(Bool.self) { self = .wahrheit(b); return }
        if let l = try? einzel.decode([String].self) { self = .liste(l); return }
        self = .unbekannt
    }

    var text: String? {
        switch self {
        case .text(let s): return s
        case .zahl(let d): return String(d)
        case .wahrheit(let b): return b ? "ja" : "nein"
        case .liste(let l): return l.joined(separator: ", ")
        case .unbekannt: return nil
        }
    }
}
