import Foundation

// MARK: - GoogleDriveFile
public struct GoogleDriveFile: Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var mimeType: String
    public var modifiedAt: Date?
    public var webViewLink: String?
    /// Dateigröße in Bytes (nil für Ordner oder wenn nicht vorhanden).
    public var fileSize: Int64?
    /// Vorschau-Thumbnail-URL (nur wenn drive.readonly-Scope erteilt, sonst nil).
    public var thumbnailLink: String?

    public init(id: String, name: String, mimeType: String, modifiedAt: Date?, webViewLink: String?, fileSize: Int64? = nil, thumbnailLink: String? = nil) {
        self.id = id
        self.name = name
        self.mimeType = mimeType
        self.modifiedAt = modifiedAt
        self.webViewLink = webViewLink
        self.fileSize = fileSize
        self.thumbnailLink = thumbnailLink
    }

    public var isFolder: Bool { mimeType == "application/vnd.google-apps.folder" }

    public var iconName: String {
        switch mimeType {
        case "application/vnd.google-apps.folder": "folder"
        case "application/pdf": "doc.richtext"
        case "application/vnd.google-apps.spreadsheet": "tablecells"
        case "application/vnd.google-apps.document": "doc.text"
        case "application/vnd.google-apps.presentation": "rectangle.on.rectangle"
        default:
            mimeType.hasPrefix("image/") ? "photo" : "doc"
        }
    }

    public var typeLabel: String {
        switch mimeType {
        case "application/vnd.google-apps.folder":       "Ordner"
        case "application/pdf":                          "PDF-Dokument"
        case "application/vnd.google-apps.spreadsheet":  "Google Sheets"
        case "application/vnd.google-apps.document":     "Google Doc"
        case "application/vnd.google-apps.presentation": "Google Slides"
        default:
            mimeType.hasPrefix("image/") ? "Bild"
            : mimeType.components(separatedBy: "/").last?.uppercased() ?? "Datei"
        }
    }

    public var fileSizeLabel: String {
        guard let bytes = fileSize else { return "—" }
        let kb = Double(bytes) / 1024
        if kb < 1024 {
            return String(format: "%.0f KB", kb < 1 ? 1 : kb)
        }
        return String(format: "%.1f MB", kb / 1024)
    }
}

// MARK: - GoogleDriveError
public enum GoogleDriveError: Error, Sendable, Equatable {
    case notConnected
    case invalidResponse
    case httpError(Int)
    case decodingFailed
    /// Upload-Ziel ist ein explizit verbotener Ordner (NO-GO-Guard).
    case uploadDestinationForbidden(String)
}

// MARK: - GoogleDriveFetching
public protocol GoogleDriveFetching: Sendable {
    func listFolder(folderID: String) async throws -> [GoogleDriveFile]
    func getFileName(folderID: String) async throws -> String
    /// Lädt Dateiinhalt als rohe Bytes (erfordert drive.readonly-Scope — M5).
    /// Für Google-native Formate (Docs/Sheets) nicht nutzbar — nur binäre Dateien (PDF, Bilder).
    func downloadContent(fileID: String) async throws -> Data
    /// Exportiert ein Google-natives Format (Docs/Sheets/Slides) in ein Zielformat
    /// (z. B. text/plain, text/csv). Erfordert drive.readonly.
    func exportFile(fileID: String, exportMimeType: String) async throws -> Data
}

// Default, damit bestehende Fakes/Conformer nicht brechen (nur GoogleDriveClient
// implementiert den echten Export).
public extension GoogleDriveFetching {
    func exportFile(fileID: String, exportMimeType: String) async throws -> Data {
        throw GoogleDriveError.invalidResponse
    }
}

// MARK: - GoogleDriveClient
// Liest nur Metadaten (Name, Typ, Änderungszeit, Web-Link) — nie Dateiinhalte.
public struct GoogleDriveClient: GoogleDriveFetching {
    private let tokenProvider: GoogleAccessTokenProviding
    private let session: URLSession
    private let baseURL = "https://www.googleapis.com/drive/v3/files"

    public init(
        tokenProvider: GoogleAccessTokenProviding = GoogleAccessTokenProvider(),
        session: URLSession = .shared
    ) {
        self.tokenProvider = tokenProvider
        self.session = session
    }

    public func listFolder(folderID: String) async throws -> [GoogleDriveFile] {
        // Provider-Fehler sind immer Auth-Zustand (nicht verbunden, Refresh
        // fehlgeschlagen), nie Drive-API-Zustand — daher einheitlich auf
        // .notConnected gemappt, statt den Fehlertyp durchzureichen.
        guard let accessToken = try? await tokenProvider.validAccessToken() else {
            throw GoogleDriveError.notConnected
        }
        var allFiles: [GoogleDriveFile] = []
        var pageToken: String? = nil
        // Sicherheitsgrenze: maximal 20 Seiten (2.000 Einträge) pro Ordner.
        for _ in 0..<20 {
            guard let url = Self.buildListFolderURL(folderID: folderID, pageToken: pageToken, baseURL: baseURL) else {
                throw GoogleDriveError.invalidResponse
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw GoogleDriveError.invalidResponse }
            guard (200...299).contains(http.statusCode) else { throw GoogleDriveError.httpError(http.statusCode) }
            let page = try Self.parseFilesPage(from: data)
            allFiles.append(contentsOf: page.files)
            guard let next = page.nextPageToken else { break }
            pageToken = next
        }
        return allFiles
    }

    /// Lädt rohe Bytes einer binären Datei (PDF, Bild) — erfordert drive.readonly-Scope.
    public func downloadContent(fileID: String) async throws -> Data {
        guard let accessToken = try? await tokenProvider.validAccessToken() else {
            throw GoogleDriveError.notConnected
        }
        guard let url = URL(string: "\(baseURL)/\(fileID)?alt=media&supportsAllDrives=true") else {
            throw GoogleDriveError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw GoogleDriveError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return data
    }

    /// Exportiert ein Google-natives Format in z. B. text/plain oder text/csv.
    public func exportFile(fileID: String, exportMimeType: String) async throws -> Data {
        guard let accessToken = try? await tokenProvider.validAccessToken() else {
            throw GoogleDriveError.notConnected
        }
        var comps = URLComponents(string: "\(baseURL)/\(fileID)/export")
        comps?.queryItems = [URLQueryItem(name: "mimeType", value: exportMimeType)]
        guard let url = comps?.url else { throw GoogleDriveError.invalidResponse }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw GoogleDriveError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return data
    }

    /// Holt nur den Namen einer Datei/eines Ordners (für den Breadcrumb-Header).
    public func getFileName(folderID: String) async throws -> String {
        guard let accessToken = try? await tokenProvider.validAccessToken() else {
            throw GoogleDriveError.notConnected
        }
        guard let url = URL(string: "\(baseURL)/\(folderID)?fields=name&supportsAllDrives=true") else {
            throw GoogleDriveError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else { throw GoogleDriveError.invalidResponse }
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = obj["name"] as? String else { throw GoogleDriveError.decodingFailed }
        return name
    }

    // MARK: - Reine, testbare Bausteine (kein Netzwerk/Keychain)

    static func buildListFolderURL(folderID: String, pageToken: String? = nil, baseURL: String) -> URL? {
        var components = URLComponents(string: baseURL)
        var items: [URLQueryItem] = [
            URLQueryItem(name: "q", value: "'\(folderID)' in parents and trashed=false"),
            URLQueryItem(name: "fields", value: "nextPageToken,files(id,name,mimeType,modifiedTime,webViewLink,size,thumbnailLink)"),
            URLQueryItem(name: "pageSize", value: "100"),
            URLQueryItem(name: "orderBy", value: "folder,name"),
            // Shared Drive (Team Drive) Support — ohne diese zwei Parameter liefert
            // die API bei geteilten Laufwerken ein leeres Ergebnis ohne Fehler.
            URLQueryItem(name: "supportsAllDrives", value: "true"),
            URLQueryItem(name: "includeItemsFromAllDrives", value: "true"),
        ]
        if let token = pageToken {
            items.append(URLQueryItem(name: "pageToken", value: token))
        }
        components?.queryItems = items
        return components?.url
    }

    // Gibt Dateien + optionalen nextPageToken zurück.
    static func parseFilesPage(from data: Data) throws -> (files: [GoogleDriveFile], nextPageToken: String?) {
        do {
            let decoded = try JSONDecoder().decode(GoogleDriveListResponse.self, from: data)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let files = decoded.files.map { entry in
                GoogleDriveFile(
                    id: entry.id,
                    name: entry.name,
                    mimeType: entry.mimeType,
                    modifiedAt: entry.modifiedTime.flatMap { isoFormatter.date(from: $0) },
                    webViewLink: entry.webViewLink,
                    fileSize: entry.size.flatMap { Int64($0) },
                    thumbnailLink: entry.thumbnailLink
                )
            }
            return (files, decoded.nextPageToken)
        } catch {
            throw GoogleDriveError.decodingFailed
        }
    }

    // Rückwärtskompatibel: gibt nur Dateien zurück (ignoriert nextPageToken).
    static func parseFiles(from data: Data) throws -> [GoogleDriveFile] {
        try parseFilesPage(from: data).files
    }

    // MARK: - Upload (drive.file-Scope, feat/assistant-write-tier)

    /// NO-GO-Ordner: Diese IDs dürfen NIEMALS Upload-Ziel sein.
    /// `0AOeReQBQKkKBUk9PVA` = geteilter Drive-Root (read-only lt. CLAUDE.md).
    static let forbiddenParentFolderIDs: Set<String> = [
        "0AOeReQBQKkKBUk9PVA",
    ]

    /// Lädt eine Datei per `files.create` (`uploadType=multipart`) in Drive hoch.
    /// Erfordert `drive.file`-Scope (NICHT in Standard-Scopes — Re-Consent nötig).
    /// Wirft `.uploadDestinationForbidden` wenn `parentFolderID` auf der NO-GO-Liste steht.
    public func uploadFile(
        name: String,
        mimeType: String,
        data: Data,
        parentFolderID: String
    ) async throws -> GoogleDriveFile {
        // HARTE NO-GO-Grenze — nie in verbotene Ordner schreiben.
        guard !Self.forbiddenParentFolderIDs.contains(parentFolderID) else {
            throw GoogleDriveError.uploadDestinationForbidden(parentFolderID)
        }
        guard let accessToken = try? await tokenProvider.validAccessToken() else {
            throw GoogleDriveError.notConnected
        }
        guard let url = Self.buildUploadURL(baseURL: baseURL) else {
            throw GoogleDriveError.invalidResponse
        }
        let boundary = "mykilos_boundary_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        let body = Self.buildMultipartBody(
            boundary: boundary,
            metadata: ["name": name, "parents": [parentFolderID]],
            mimeType: mimeType,
            data: data
        )
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        let (responseData, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw GoogleDriveError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return try Self.parseUploadedFile(from: responseData)
    }

    // MARK: - Reine, testbare Upload-Bausteine (kein Netzwerk/Keychain)

    /// Baut die Upload-URL für `uploadType=multipart`.
    static func buildUploadURL(baseURL: String) -> URL? {
        var components = URLComponents(string: "https://www.googleapis.com/upload/drive/v3/files")
        components?.queryItems = [
            URLQueryItem(name: "uploadType", value: "multipart"),
            URLQueryItem(name: "fields", value: "id,name,mimeType,webViewLink"),
            URLQueryItem(name: "supportsAllDrives", value: "true"),
        ]
        return components?.url
    }

    /// Baut den `multipart/related`-Body aus Metadaten-JSON + Mediendaten.
    /// Rein synchron, testbar ohne Netzwerk.
    static func buildMultipartBody(
        boundary: String,
        metadata: [String: Any],
        mimeType: String,
        data: Data
    ) -> Data {
        var body = Data()
        let crlf = "\r\n"
        let dash = "--"

        // Metadaten-Part
        body.append(contentsOf: "\(dash)\(boundary)\(crlf)".utf8)
        body.append(contentsOf: "Content-Type: application/json; charset=UTF-8\(crlf)\(crlf)".utf8)
        if let json = try? JSONSerialization.data(withJSONObject: metadata) {
            body.append(json)
        }
        body.append(contentsOf: crlf.utf8)

        // Medien-Part
        body.append(contentsOf: "\(dash)\(boundary)\(crlf)".utf8)
        body.append(contentsOf: "Content-Type: \(mimeType)\(crlf)\(crlf)".utf8)
        body.append(data)
        body.append(contentsOf: crlf.utf8)

        // Epilog
        body.append(contentsOf: "\(dash)\(boundary)\(dash)\(crlf)".utf8)
        return body
    }

    /// Parst die `files.create`-Antwort in ein `GoogleDriveFile`.
    static func parseUploadedFile(from data: Data) throws -> GoogleDriveFile {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = obj["id"] as? String,
              let name = obj["name"] as? String,
              let mime = obj["mimeType"] as? String else {
            throw GoogleDriveError.decodingFailed
        }
        return GoogleDriveFile(
            id: id,
            name: name,
            mimeType: mime,
            modifiedAt: nil,
            webViewLink: obj["webViewLink"] as? String
        )
    }
}

private struct GoogleDriveListResponse: Decodable {
    var files: [GoogleDriveFileEntry]
    var nextPageToken: String?
}

private struct GoogleDriveFileEntry: Decodable {
    var id: String
    var name: String
    var mimeType: String
    var modifiedTime: String?
    var webViewLink: String?
    var size: String?
    var thumbnailLink: String?
}
