import Foundation

enum AirtableClockodoPostboxError: Error, LocalizedError {
    case keinZeitEintrag
    case ungueltigeURL
    case ungueltigeAntwort
    case serverFehler(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .keinZeitEintrag:
            return "Nur Zeit-Einträge lassen sich synchronisieren — für Ideen gibt's noch keine Ziel-Tabelle."
        case .ungueltigeURL:
            return "Ungültige Airtable-URL."
        case .ungueltigeAntwort:
            return "Ungültige Antwort von Airtable."
        case .serverFehler(let status, let body):
            return "Airtable-Fehler \(status): \(body)"
        }
    }
}

/// Der Motor. Startet den Propeller, aber die Räder sind blockiert, bis ein echter
/// Airtable-Token im Schlüsselbund liegt — kein Aufruf feuert von selbst, nur auf
/// expliziten Tippdruck (Karte→Bestätigung-Doktrin gilt auch hier).
struct AirtableClockodoPostboxClient {
    private let credentialsStore: AirtablePostboxCredentialsStoring
    private let session: URLSession
    private let apiBase = "https://api.airtable.com/v0"

    init(
        credentialsStore: AirtablePostboxCredentialsStoring = KeychainAirtablePostboxCredentialsStore(),
        session: URLSession = .shared
    ) {
        self.credentialsStore = credentialsStore
        self.session = session
    }

    @discardableResult
    func sync(_ item: PostboxItem) async throws -> String {
        guard let felder = AirtableClockodoPostbox.felder(fuer: item) else {
            throw AirtableClockodoPostboxError.keinZeitEintrag
        }
        let credentials = try credentialsStore.load()
        guard let url = URL(string: "\(apiBase)/\(AirtableClockodoPostbox.baseID)/\(AirtableClockodoPostbox.table)") else {
            throw AirtableClockodoPostboxError.ungueltigeURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(credentials.pat)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "records": [["fields": felder.mapValues(\.jsonValue)]],
            "typecast": true,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AirtableClockodoPostboxError.ungueltigeAntwort
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AirtableClockodoPostboxError.serverFehler(status: http.statusCode, body: body)
        }

        struct Antwort: Decodable {
            struct Record: Decodable { let id: String }
            let records: [Record]
        }
        let decoded = try? JSONDecoder().decode(Antwort.self, from: data)
        return decoded?.records.first?.id ?? ""
    }
}
