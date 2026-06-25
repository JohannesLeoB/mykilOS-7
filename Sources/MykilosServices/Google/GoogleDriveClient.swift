import Foundation

// MARK: - GoogleDriveFile
public struct GoogleDriveFile: Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var mimeType: String
    public var modifiedAt: Date?
    public var webViewLink: String?

    public init(id: String, name: String, mimeType: String, modifiedAt: Date?, webViewLink: String?) {
        self.id = id
        self.name = name
        self.mimeType = mimeType
        self.modifiedAt = modifiedAt
        self.webViewLink = webViewLink
    }

    public var iconName: String {
        switch mimeType {
        case "application/vnd.google-apps.folder": "folder"
        case "application/pdf": "doc.richtext"
        case "application/vnd.google-apps.spreadsheet": "tablecells"
        case "application/vnd.google-apps.document": "doc.text"
        default:
            mimeType.hasPrefix("image/") ? "photo" : "doc"
        }
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

    // MARK: - Reine, testbare Bausteine (kein Netzwerk/Keychain)

    static func buildListFolderURL(folderID: String, baseURL: String) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: "'\(folderID)' in parents and trashed=false"),
            URLQueryItem(name: "fields", value: "files(id,name,mimeType,modifiedTime,webViewLink)"),
            URLQueryItem(name: "pageSize", value: "50"),
            URLQueryItem(name: "orderBy", value: "modifiedTime desc"),
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
                    webViewLink: entry.webViewLink
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
}
