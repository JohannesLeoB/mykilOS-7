import Testing
import Foundation
@testable import MykilosServices

struct GoogleDriveClientTests {

    @Test func urlEnthaeltOrdnerIDUndFelder() {
        let url = GoogleDriveClient.buildListFolderURL(
            folderID: "ABC123",
            baseURL: "https://www.googleapis.com/drive/v3/files"
        )
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(items["q"] == "'ABC123' in parents and trashed=false")
        // fields muss nextPageToken enthalten (Pagination-Fix)
        #expect(items["fields"]?.contains("nextPageToken") == true)
        #expect(items["fields"]?.contains("files(id") == true)
        #expect(items["supportsAllDrives"] == "true")
        #expect(items["includeItemsFromAllDrives"] == "true")
        #expect(items["pageToken"] == nil)
    }

    @Test func urlEnthaeltPageTokenWennGesetzt() {
        let url = GoogleDriveClient.buildListFolderURL(
            folderID: "ABC123",
            pageToken: "TOKEN_XYZ",
            baseURL: "https://www.googleapis.com/drive/v3/files"
        )
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        #expect(items["pageToken"] == "TOKEN_XYZ")
    }

    @Test func parseFilesPageDekodiertNextPageToken() throws {
        let json = """
        {
          "nextPageToken": "NEXT_TOKEN_ABC",
          "files": [
            { "id": "1", "name": "A.pdf", "mimeType": "application/pdf" }
          ]
        }
        """
        let page = try GoogleDriveClient.parseFilesPage(from: Data(json.utf8))
        #expect(page.files.count == 1)
        #expect(page.nextPageToken == "NEXT_TOKEN_ABC")
    }

    @Test func parseFilesPageOhneNextPageTokenLiefertNil() throws {
        let json = """
        { "files": [{ "id": "1", "name": "A.pdf", "mimeType": "application/pdf" }] }
        """
        let page = try GoogleDriveClient.parseFilesPage(from: Data(json.utf8))
        #expect(page.nextPageToken == nil)
    }

    @Test func parseFilesDekodiertResponse() throws {
        let json = """
        {
          "files": [
            { "id": "1", "name": "Bartresen.pdf", "mimeType": "application/pdf",
              "modifiedTime": "2026-06-20T10:00:00.000Z", "webViewLink": "https://drive.google.com/1" },
            { "id": "2", "name": "Ordner ohne Zeit", "mimeType": "application/vnd.google-apps.folder" }
          ]
        }
        """
        let files = try GoogleDriveClient.parseFiles(from: Data(json.utf8))

        #expect(files.count == 2)
        #expect(files[0].name == "Bartresen.pdf")
        #expect(files[0].webViewLink == "https://drive.google.com/1")
        #expect(files[0].modifiedAt != nil)
        #expect(files[1].modifiedAt == nil)
        #expect(files[1].webViewLink == nil)
    }

    @Test func parseFilesWirftBeiKaputtemJSON() {
        #expect(throws: GoogleDriveError.decodingFailed) {
            _ = try GoogleDriveClient.parseFiles(from: Data("nicht json".utf8))
        }
    }

    @Test func listFolderWirftNotConnectedOhneToken() async {
        let store = InMemoryGoogleTokenStore()
        let client = GoogleDriveClient(tokenProvider: GoogleAccessTokenProvider(tokenStore: store))

        do {
            _ = try await client.listFolder(folderID: "ABC123")
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? GoogleDriveError == .notConnected)
        }
    }

    @Test func listFolderMapptRefreshFehlerAufNotConnected() async {
        // Widerrufenes Refresh-Token → Provider wirft httpError(400). Der Client
        // darf das nicht als generischen Fehler durchreichen, sondern als
        // .notConnected (→ Widget zeigt „Berechtigung nötig").
        let client = GoogleDriveClient(tokenProvider: ThrowingTokenProvider(error: GoogleOAuthError.httpError(400)))

        do {
            _ = try await client.listFolder(folderID: "ABC123")
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? GoogleDriveError == .notConnected)
        }
    }

    @Test func downloadContentURLEnthaeltAltMedia() {
        let base = "https://www.googleapis.com/drive/v3/files"
        let fileID = "pdf_123"
        let url = URL(string: "\(base)/\(fileID)?alt=media&supportsAllDrives=true")
        #expect(url != nil)
        #expect(url?.absoluteString.contains("alt=media") == true)
        #expect(url?.absoluteString.contains(fileID) == true)
    }

    @Test func parseDateiEnthaeltThumbnailLink() throws {
        let json = """
        {"files":[{"id":"f1","name":"Plan.pdf","mimeType":"application/pdf","webViewLink":"https://drive.google.com/x","thumbnailLink":"https://lh3.google.com/thumb"}]}
        """.data(using: .utf8)!
        let files = try GoogleDriveClient.parseFiles(from: json)
        #expect(files.first?.thumbnailLink == "https://lh3.google.com/thumb")
    }

    @Test func parseOhneThumbNilBleibt() throws {
        let json = """
        {"files":[{"id":"f2","name":"Kein.pdf","mimeType":"application/pdf"}]}
        """.data(using: .utf8)!
        let files = try GoogleDriveClient.parseFiles(from: json)
        #expect(files.first?.thumbnailLink == nil)
    }

    @Test func iconNameMapptMimeTypes() {
        #expect(GoogleDriveFile(id: "1", name: "a", mimeType: "application/vnd.google-apps.folder", modifiedAt: nil, webViewLink: nil).iconName == "folder")
        #expect(GoogleDriveFile(id: "2", name: "b", mimeType: "application/pdf", modifiedAt: nil, webViewLink: nil).iconName == "doc.richtext")
        #expect(GoogleDriveFile(id: "3", name: "c", mimeType: "application/vnd.google-apps.spreadsheet", modifiedAt: nil, webViewLink: nil).iconName == "tablecells")
        #expect(GoogleDriveFile(id: "4", name: "d", mimeType: "application/vnd.google-apps.document", modifiedAt: nil, webViewLink: nil).iconName == "doc.text")
        #expect(GoogleDriveFile(id: "5", name: "e", mimeType: "image/png", modifiedAt: nil, webViewLink: nil).iconName == "photo")
        #expect(GoogleDriveFile(id: "6", name: "f", mimeType: "application/octet-stream", modifiedAt: nil, webViewLink: nil).iconName == "doc")
    }

    // MARK: - Mandate C — die ECHTE nextPageToken-Schleife (gestubbte URLSession)

    @Test func listFolderFolgtNextPageTokenUeberZweiSeiten() async throws {
        // Seite 1 trägt nextPageToken → der Client MUSS eine zweite Anfrage
        // (pageToken=PAGE2) stellen und beide Seiten zusammenführen — echte Schleife.
        let page1 = #"{"nextPageToken":"PAGE2","files":[{"id":"1","name":"A.pdf","mimeType":"application/pdf"},{"id":"2","name":"B.pdf","mimeType":"application/pdf"}]}"#
        let page2 = #"{"files":[{"id":"3","name":"C.pdf","mimeType":"application/pdf"}]}"#
        StubURLProtocol.reset(responses: [(200, Data(page1.utf8)), (200, Data(page2.utf8))])

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = GoogleDriveClient(tokenProvider: StubReturningTokenProvider(token: "tok"), session: session)

        let files = try await client.listFolder(folderID: "root")
        #expect(files.map(\.name) == ["A.pdf", "B.pdf", "C.pdf"])
        #expect(StubURLProtocol.requestedURLs.count == 2)
        #expect(StubURLProtocol.requestedURLs.last?.absoluteString.contains("pageToken=PAGE2") == true)
    }
}

    // MARK: - Upload-Tests (feat/assistant-write-tier)

    @Test func uploadURLEnthaeltUploadTypeMultipart() {
        let url = GoogleDriveClient.buildUploadURL(baseURL: "https://www.googleapis.com/drive/v3/files")
        let comps = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(uniqueKeysWithValues: (comps?.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        #expect(items["uploadType"] == "multipart")
        #expect(items["supportsAllDrives"] == "true")
        #expect(items["fields"]?.contains("id") == true)
    }

    @Test func multipartBodyEnthaeltBoundaryUndMimeType() {
        let boundary = "TEST_BOUNDARY"
        let data = Data("Hallo Welt".utf8)
        let body = GoogleDriveClient.buildMultipartBody(
            boundary: boundary,
            metadata: ["name": "test.pdf"],
            mimeType: "application/pdf",
            data: data
        )
        let bodyString = String(decoding: body, as: UTF8.self)
        #expect(bodyString.contains("--\(boundary)"))
        #expect(bodyString.contains("application/json"))
        #expect(bodyString.contains("application/pdf"))
        #expect(bodyString.contains("test.pdf"))
        #expect(bodyString.contains("Hallo Welt"))
        // Epilog
        #expect(bodyString.contains("--\(boundary)--"))
    }

    @Test func parseUploadedFileDekodiertAntwort() throws {
        let json = #"{"id":"fileXYZ","name":"Rechnung.pdf","mimeType":"application/pdf","webViewLink":"https://drive.google.com/r"}"#
        let file = try GoogleDriveClient.parseUploadedFile(from: Data(json.utf8))
        #expect(file.id == "fileXYZ")
        #expect(file.name == "Rechnung.pdf")
        #expect(file.mimeType == "application/pdf")
        #expect(file.webViewLink == "https://drive.google.com/r")
    }

    @Test func parseUploadedFileWirftBeiKaputtemJSON() {
        #expect(throws: GoogleDriveError.decodingFailed) {
            _ = try GoogleDriveClient.parseUploadedFile(from: Data("{}".utf8))
        }
    }

    @Test func uploadFileWirftBeiVerbotenemOrdner() async {
        // Der NO-GO-Root-Ordner darf NIEMALS Upload-Ziel sein — Guard wirft sofort.
        let client = GoogleDriveClient(tokenProvider: StubReturningTokenProvider(token: "tok"))
        let forbiddenID = "0AOeReQBQKkKBUk9PVA"
        do {
            _ = try await client.uploadFile(
                name: "test.pdf",
                mimeType: "application/pdf",
                data: Data("x".utf8),
                parentFolderID: forbiddenID
            )
            Issue.record("hätte .uploadDestinationForbidden werfen sollen")
        } catch let err as GoogleDriveError {
            #expect(err == .uploadDestinationForbidden(forbiddenID))
        } catch {
            Issue.record("falscher Fehlertyp: \(error)")
        }
    }

    @Test func forbiddenFolderIDsEnthaeltNOGORoot() {
        #expect(GoogleDriveClient.forbiddenParentFolderIDs.contains("0AOeReQBQKkKBUk9PVA"))
    }

// MARK: - Test-Stubs für die echte Pagination

private struct StubReturningTokenProvider: GoogleAccessTokenProviding {
    let token: String
    func validAccessToken() async throws -> String { token }
}

// URLSession-Stub: liefert eine Queue von (Status, Body) der Reihe nach; merkt sich
// die angefragten URLs. Nur dieser eine Test registriert ihn (eigene ephemere Session),
// die Aufrufe innerhalb listFolder sind seriell — Zugriff zusätzlich per Lock geschützt.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) private static var queue: [(Int, Data)] = []
    nonisolated(unsafe) private(set) static var requestedURLs: [URL] = []
    nonisolated(unsafe) private static var index = 0
    private static let lock = NSLock()

    static func reset(responses: [(Int, Data)]) {
        lock.lock(); defer { lock.unlock() }
        queue = responses; requestedURLs = []; index = 0
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        Self.lock.lock()
        if let url = request.url { Self.requestedURLs.append(url) }
        let pair: (Int, Data) = Self.queue.isEmpty
            ? (200, Data())
            : Self.queue[min(Self.index, Self.queue.count - 1)]
        Self.index += 1
        Self.lock.unlock()

        let resp = HTTPURLResponse(url: request.url!, statusCode: pair.0, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: pair.1)
        client?.urlProtocolDidFinishLoading(self)
    }
}
