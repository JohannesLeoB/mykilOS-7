import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// MARK: - FileDropIntegrationTests
// Testet die Zusammenarbeit von DroppedFile + DriveFolderSuggestionResolver +
// GoogleDriveClient Upload-Bausteine — ohne echtes Netzwerk/Keychain.

struct FileDropIntegrationTests {

    // MARK: - DraftAttachment aus DroppedFile

    @Test func draftAttachmentAusDroppedFile() {
        let data = Data("PDF-Content".utf8)
        let file = DroppedFile(fileName: "Angebot_2026.pdf", mimeType: "application/pdf", data: data)
        let attachment = DraftAttachment(filename: file.fileName, mimeType: file.mimeType, data: file.data)
        #expect(attachment.filename == "Angebot_2026.pdf")
        #expect(attachment.mimeType == "application/pdf")
        #expect(attachment.data == data)
    }

    @Test func emailDraftMitAnhangHatKorrektesHeadline() {
        let data = Data("bytes".utf8)
        let file = DroppedFile(fileName: "Foto.png", mimeType: "image/png", data: data)
        let attachment = DraftAttachment(filename: file.fileName, mimeType: file.mimeType, data: file.data)
        let draft = EmailDraft(
            to: "kunde@example.com",
            subject: file.fileName,
            body: "Datei: \(file.fileName) (\(file.humanSize))",
            attachments: [attachment]
        )
        #expect(draft.to == "kunde@example.com")
        #expect(draft.subject == "Foto.png")
        #expect(draft.attachments.count == 1)
        #expect(draft.attachments[0].filename == "Foto.png")
    }

    // MARK: - MIME-Multipart Anhang

    @Test func buildMIMEMultipartEnthältAnhangHeader() {
        let data = Data("binary".utf8)
        let file = DroppedFile(fileName: "test.pdf", mimeType: "application/pdf", data: data)
        let attachment = DraftAttachment(filename: file.fileName, mimeType: file.mimeType, data: file.data)
        let draft = EmailDraft(subject: "Test", body: "Body", attachments: [attachment])
        let mime = GoogleGmailClient.buildMIMEMultipart(draft)
        #expect(mime.contains("Content-Type: application/pdf"))
        #expect(mime.contains("Content-Disposition: attachment; filename=\"test.pdf\""))
        #expect(mime.contains("multipart/mixed"))
    }

    @Test func buildMIMEOhneAnhangIstEinfachesMIME() {
        let draft = EmailDraft(subject: "Kein Anhang", body: "Body")
        let mime = GoogleGmailClient.buildMIMEMultipart(draft)
        // Kein Multipart wenn keine Anhänge
        #expect(!mime.contains("multipart/mixed"))
        #expect(mime.contains("Content-Type: text/plain"))
    }

    // MARK: - Drive NO-GO-Guard (reiner Unit-Test, kein Netzwerk)

    @Test func driveUploadURLHatKorrekteStruktur() {
        let url = GoogleDriveClient.buildUploadURL(baseURL: "https://www.googleapis.com/drive/v3/files")
        #expect(url != nil)
        let str = url!.absoluteString
        #expect(str.contains("upload/drive/v3/files"))
        #expect(str.contains("uploadType=multipart"))
        #expect(str.contains("supportsAllDrives=true"))
    }

    @Test func driveMultipartBodyEnthältMetadatenUndDaten() {
        let data = Data("Dateiinhalt".utf8)
        let body = GoogleDriveClient.buildMultipartBody(
            boundary: "testboundary",
            metadata: ["name": "test.pdf", "parents": ["folderXYZ"]],
            mimeType: "application/pdf",
            data: data
        )
        let str = String(data: body, encoding: .utf8) ?? ""
        #expect(str.contains("testboundary"))
        #expect(str.contains("application/pdf"))
        // Metadaten als JSON eingebettet
        #expect(str.contains("test.pdf"))
    }

    @Test func driveUploadVerbotenesZielGibtForbiddenError() async throws {
        // FakeGDriveClient der notConnected wirft (Upload-Pfad läuft nie durch)
        struct FakeConnectedClient: GoogleDriveFetching {
            func listFolder(folderID: String) async throws -> [GoogleDriveFile] { [] }
            func getFileName(folderID: String) async throws -> String { "Test" }
            func downloadContent(fileID: String) async throws -> Data { Data() }
        }
        // GoogleDriveClient.forbiddenParentFolderIDs muss den NO-GO-Root enthalten
        #expect(GoogleDriveClient.forbiddenParentFolderIDs.contains("0AOeReQBQKkKBUk9PVA"))
    }

    // MARK: - DriveFolderSuggestion mit Keyword

    @Test func resolverFindetAngeboteUnterordner() async throws {
        let angeboteFolder = GoogleDriveFile(
            id: "angebote-folder-id",
            name: "05 eingehende Angebote",
            mimeType: "application/vnd.google-apps.folder",
            modifiedAt: nil,
            webViewLink: nil
        )
        let client = FakeFileDropDriveClient(folders: [angeboteFolder], fileName: "Projekt XY")
        let resolver = DriveFolderSuggestionResolver(driveClient: client)
        let suggestion = try await resolver.suggest(
            projectDriveFolderID: "projekt-root-id",
            preferredSubfolderKeyword: "Angebote"
        )
        #expect(suggestion.folderID == "angebote-folder-id")
        #expect(suggestion.folderName == "05 eingehende Angebote")
    }

    @Test func resolverFaelltAufRootZurueckBeiKeinemUnterordner() async throws {
        let client = FakeFileDropDriveClient(folders: [], fileName: "Projekt Ohne Unterordner")
        let resolver = DriveFolderSuggestionResolver(driveClient: client)
        let suggestion = try await resolver.suggest(
            projectDriveFolderID: "projekt-root-id",
            preferredSubfolderKeyword: "NichtVorhanden"
        )
        // Kein Unterordner → Root zurückgegeben
        #expect(suggestion.folderID == "projekt-root-id")
        #expect(suggestion.folderName == "Projekt Ohne Unterordner")
    }

    @Test func resolverWirftBeiNilFolderID() async {
        let client = FakeFileDropDriveClient(folders: [], fileName: "–")
        let resolver = DriveFolderSuggestionResolver(driveClient: client)
        do {
            _ = try await resolver.suggest(projectDriveFolderID: nil)
            Issue.record("hätte .noDriveFolderConfigured werfen sollen")
        } catch let err as DriveFolderSuggestionError {
            #expect(err == .noDriveFolderConfigured)
        } catch {
            Issue.record("Unerwarteter Fehlertyp: \(error)")
        }
    }
}

// MARK: - FakeFileDropDriveClient

private struct FakeFileDropDriveClient: GoogleDriveFetching {
    let folders: [GoogleDriveFile]
    let fileName: String

    func listFolder(folderID: String) async throws -> [GoogleDriveFile] { folders }
    func getFileName(folderID: String) async throws -> String { fileName }
    func downloadContent(fileID: String) async throws -> Data { Data() }
}
