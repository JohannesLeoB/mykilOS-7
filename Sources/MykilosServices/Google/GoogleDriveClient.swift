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

    public init(id: String, name: String, mimeType: String, modifiedAt: Date?, webViewLink: String?, fileSize: Int64? = nil) {
        self.id = id
        self.name = name
        self.mimeType = mimeType
        self.modifiedAt = modifiedAt
        self.webViewLink = webViewLink
        self.fileSize = fileSize
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
}

// MARK: - GoogleDriveFetching
public protocol GoogleDriveFetching: Sendable {
    func listFolder(folderID: String) async throws -> [GoogleDriveFile]
    func getFileName(folderID: String) async throws -> String
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
        guard let url = Self.buildListFolderURL(folderID: folderID, baseURL: baseURL) else {
            throw GoogleDriveError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GoogleDriveError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw GoogleDriveError.httpError(http.statusCode) }

        return try Self.parseFiles(from: data)
    }

    /// Holt nur den Namen einer Datei/eines Ordners (für den Breadcrumb-Header).
    public func getFileName(folderID: String) async throws -> String {
        guard let accessToken = try? await tokenProvider.validAccessToken() else {
            throw GoogleDriveError.notConnected
        }
        guard let url = URL(string: "\(baseURL)/\(folderID)?fields=name") else {
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

    static func buildListFolderURL(folderID: String, baseURL: String) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: "'\(folderID)' in parents and trashed=false"),
            URLQueryItem(name: "fields", value: "files(id,name,mimeType,modifiedTime,webViewLink,size)"),
            URLQueryItem(name: "pageSize", value: "100"),
            URLQueryItem(name: "orderBy", value: "folder,name"),
        ]
        return components?.url
    }

    static func parseFiles(from data: Data) throws -> [GoogleDriveFile] {
        do {
            let decoded = try JSONDecoder().decode(GoogleDriveListResponse.self, from: data)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return decoded.files.map { entry in
                GoogleDriveFile(
                    id: entry.id,
                    name: entry.name,
                    mimeType: entry.mimeType,
                    modifiedAt: entry.modifiedTime.flatMap { isoFormatter.date(from: $0) },
                    webViewLink: entry.webViewLink,
                    fileSize: entry.size.flatMap { Int64($0) }
                )
            }
        } catch {
            throw GoogleDriveError.decodingFailed
        }
    }
}

private struct GoogleDriveListResponse: Decodable {
    var files: [GoogleDriveFileEntry]
}

private struct GoogleDriveFileEntry: Decodable {
    var id: String
    var name: String
    var mimeType: String
    var modifiedTime: String?
    var webViewLink: String?
    var size: String?
}
