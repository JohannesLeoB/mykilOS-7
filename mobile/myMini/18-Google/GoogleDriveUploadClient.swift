import Foundation

enum GoogleDriveError: Error, LocalizedError {
    case ungueltigeURL
    case serverFehler(status: Int, body: String)
    case bildNichtLesbar

    var errorDescription: String? {
        switch self {
        case .ungueltigeURL: return "Ungültige Drive-URL."
        case .serverFehler(let status, let body): return "Drive-Fehler \(status): \(body)"
        case .bildNichtLesbar: return "Bilddatei nicht lesbar."
        }
    }
}

/// Schreibt ein Feld-Foto in den Kanon-Zielordner eines Projekts — erst
/// Unterordner suchen/anlegen, dann Datei per multipart-Upload hinein.
/// Gleiche Form wie `GoogleDriveClient.swift` im Mothership (nur gelesen,
/// nie verändert). **Hier zum ersten Mal live getestet** — im Mothership
/// selbst war genau dieser Pfad nie live bestätigt (siehe
/// playbooks/03_feld-foto-verraeumen.md). Erwarte einen möglichen 403 beim
/// ersten echten Versuch und behandle ihn als Befund, nicht als Bug.
struct GoogleDriveUploadClient {
    private let tokenProvider: GoogleAccessTokenProvider
    private let session: URLSession
    private let apiBase = "https://www.googleapis.com/drive/v3"
    private let uploadBase = "https://www.googleapis.com/upload/drive/v3/files"

    init(tokenProvider: GoogleAccessTokenProvider = GoogleAccessTokenProvider(), session: URLSession = .shared) {
        self.tokenProvider = tokenProvider
        self.session = session
    }

    @discardableResult
    func hochladen(foto: FeldFoto, bildURL: URL, projektDriveOrdnerID: String) async throws -> String {
        let token = try await tokenProvider.validAccessToken()
        let zielOrdnerID = try await findeOderErstelleUnterordner(
            name: foto.kanonZiel.ordner, elternID: projektDriveOrdnerID, token: token
        )
        return try await ladeHoch(bildURL: bildURL, dateiname: foto.dateiname, elternID: zielOrdnerID, token: token)
    }

    private func findeOderErstelleUnterordner(name: String, elternID: String, token: String) async throws -> String {
        if let gefundenID = try await sucheUnterordner(name: name, elternID: elternID, token: token) {
            return gefundenID
        }
        return try await erstelleUnterordner(name: name, elternID: elternID, token: token)
    }

    private func sucheUnterordner(name: String, elternID: String, token: String) async throws -> String? {
        let bereinigterName = name.replacingOccurrences(of: "'", with: "\\'")
        let query = "name = '\(bereinigterName)' and '\(elternID)' in parents "
            + "and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
        guard var components = URLComponents(string: "\(apiBase)/files") else {
            throw GoogleDriveError.ungueltigeURL
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fields", value: "files(id,name)"),
            URLQueryItem(name: "supportsAllDrives", value: "true"),
            URLQueryItem(name: "includeItemsFromAllDrives", value: "true"),
        ]
        guard let url = components.url else { throw GoogleDriveError.ungueltigeURL }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        try Self.pruefeAntwort(response, data: data)

        struct Antwort: Decodable {
            struct Datei: Decodable { let id: String }
            let files: [Datei]
        }
        return try JSONDecoder().decode(Antwort.self, from: data).files.first?.id
    }

    private func erstelleUnterordner(name: String, elternID: String, token: String) async throws -> String {
        guard let url = URL(string: "\(apiBase)/files?fields=id&supportsAllDrives=true") else {
            throw GoogleDriveError.ungueltigeURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "name": name,
            "mimeType": "application/vnd.google-apps.folder",
            "parents": [elternID],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        try Self.pruefeAntwort(response, data: data)

        struct Antwort: Decodable { let id: String }
        return try JSONDecoder().decode(Antwort.self, from: data).id
    }

    private func ladeHoch(bildURL: URL, dateiname: String, elternID: String, token: String) async throws -> String {
        guard let bildDaten = try? Data(contentsOf: bildURL) else {
            throw GoogleDriveError.bildNichtLesbar
        }
        guard var components = URLComponents(string: uploadBase) else { throw GoogleDriveError.ungueltigeURL }
        components.queryItems = [
            URLQueryItem(name: "uploadType", value: "multipart"),
            URLQueryItem(name: "fields", value: "id,name,webViewLink"),
            URLQueryItem(name: "supportsAllDrives", value: "true"),
        ]
        guard let url = components.url else { throw GoogleDriveError.ungueltigeURL }

        let boundary = "mykilOSMobile-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let metadata: [String: Any] = ["name": dateiname, "parents": [elternID]]
        let metadataData = try JSONSerialization.data(withJSONObject: metadata)

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(metadataData)
        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(bildDaten)
        body.append("\r\n--\(boundary)--".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        try Self.pruefeAntwort(response, data: data)

        struct Antwort: Decodable { let id: String }
        return try JSONDecoder().decode(Antwort.self, from: data).id
    }

    private static func pruefeAntwort(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw GoogleDriveError.ungueltigeURL }
        guard (200...299).contains(http.statusCode) else {
            throw GoogleDriveError.serverFehler(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
    }
}
