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
        #expect(items["fields"] == "files(id,name,mimeType,modifiedTime,webViewLink)")
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

    @Test func iconNameMapptMimeTypes() {
        #expect(GoogleDriveFile(id: "1", name: "a", mimeType: "application/vnd.google-apps.folder", modifiedAt: nil, webViewLink: nil).iconName == "folder")
        #expect(GoogleDriveFile(id: "2", name: "b", mimeType: "application/pdf", modifiedAt: nil, webViewLink: nil).iconName == "doc.richtext")
        #expect(GoogleDriveFile(id: "3", name: "c", mimeType: "application/vnd.google-apps.spreadsheet", modifiedAt: nil, webViewLink: nil).iconName == "tablecells")
        #expect(GoogleDriveFile(id: "4", name: "d", mimeType: "application/vnd.google-apps.document", modifiedAt: nil, webViewLink: nil).iconName == "doc.text")
        #expect(GoogleDriveFile(id: "5", name: "e", mimeType: "image/png", modifiedAt: nil, webViewLink: nil).iconName == "photo")
        #expect(GoogleDriveFile(id: "6", name: "f", mimeType: "application/octet-stream", modifiedAt: nil, webViewLink: nil).iconName == "doc")
    }
}
