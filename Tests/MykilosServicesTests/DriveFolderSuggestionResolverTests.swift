import Testing
import Foundation
@testable import MykilosServices

// MARK: - DriveFolderSuggestionResolverTests

struct DriveFolderSuggestionResolverTests {

    // MARK: - NO-GO-Guard

    @Test func assertNotForbiddenWirftFuerNOGORoot() {
        #expect(throws: DriveFolderSuggestionError.uploadDestinationForbidden("0AOeReQBQKkKBUk9PVA")) {
            try DriveFolderSuggestionResolver.assertNotForbidden("0AOeReQBQKkKBUk9PVA")
        }
    }

    @Test func assertNotForbiddenPassiertFuerNormalenOrdner() throws {
        // Kein Fehler erwartet
        try DriveFolderSuggestionResolver.assertNotForbidden("1Q-H_3JsZfiXosFmxtNgoy0hI3cvZLgST")
    }

    @Test func suggestWirftBeiNOGORootOrdner() async {
        let client = FakeResolverDriveClient(folders: [], fileName: "Root")
        let resolver = DriveFolderSuggestionResolver(driveClient: client)
        do {
            _ = try await resolver.suggest(projectDriveFolderID: "0AOeReQBQKkKBUk9PVA")
            Issue.record("hätte .uploadDestinationForbidden werfen sollen")
        } catch let err as DriveFolderSuggestionError {
            #expect(err == .uploadDestinationForbidden("0AOeReQBQKkKBUk9PVA"))
        } catch {
            Issue.record("falscher Fehlertyp: \(error)")
        }
    }

    // MARK: - Kein Ordner konfiguriert

    @Test func suggestWirftWennKeinOrdnerKonfiguriert() async {
        let client = FakeResolverDriveClient(folders: [], fileName: "X")
        let resolver = DriveFolderSuggestionResolver(driveClient: client)
        do {
            _ = try await resolver.suggest(projectDriveFolderID: nil)
            Issue.record("hätte .noDriveFolderConfigured werfen sollen")
        } catch let err as DriveFolderSuggestionError {
            #expect(err == .noDriveFolderConfigured)
        } catch {
            Issue.record("falscher Fehlertyp: \(error)")
        }
    }

    @Test func suggestWirftFuerLeereOrdnerID() async {
        let client = FakeResolverDriveClient(folders: [], fileName: "X")
        let resolver = DriveFolderSuggestionResolver(driveClient: client)
        do {
            _ = try await resolver.suggest(projectDriveFolderID: "")
            Issue.record("hätte .noDriveFolderConfigured werfen sollen")
        } catch let err as DriveFolderSuggestionError {
            #expect(err == .noDriveFolderConfigured)
        } catch {
            Issue.record("falscher Fehlertyp: \(error)")
        }
    }

    // MARK: - Unterordner-Matching

    @Test func suggestFindetUnterordnerNachKeyword() async throws {
        let subfolders = [
            makeFolder(id: "sub_angebote", name: "05 eingehende Angebote"),
            makeFolder(id: "sub_pläne", name: "03 Pläne"),
        ]
        let client = FakeResolverDriveClient(folders: subfolders, fileName: "2026-015 Schmidt")
        let resolver = DriveFolderSuggestionResolver(driveClient: client)

        let suggestion = try await resolver.suggest(
            projectDriveFolderID: "projekt_root_id",
            preferredSubfolderKeyword: "Angebote"
        )
        #expect(suggestion.folderID == "sub_angebote")
        #expect(suggestion.folderName == "05 eingehende Angebote")
    }

    @Test func suggestKeywordIstCaseInsensitiv() async throws {
        let subfolders = [makeFolder(id: "sf1", name: "05 ANGEBOTE")]
        let client = FakeResolverDriveClient(folders: subfolders, fileName: "Projekt")
        let resolver = DriveFolderSuggestionResolver(driveClient: client)

        let suggestion = try await resolver.suggest(
            projectDriveFolderID: "root_id",
            preferredSubfolderKeyword: "angebote"
        )
        #expect(suggestion.folderID == "sf1")
    }

    @Test func suggestFaelltAufWurzelzurueckWennKeinUnterordnerPasst() async throws {
        let subfolders = [makeFolder(id: "sf1", name: "03 Pläne")]
        let client = FakeResolverDriveClient(folders: subfolders, fileName: "2026-015 Projekt")
        let resolver = DriveFolderSuggestionResolver(driveClient: client)

        let suggestion = try await resolver.suggest(
            projectDriveFolderID: "root_id",
            preferredSubfolderKeyword: "Angebote"
        )
        // Kein Match → Fallback auf Wurzelordner
        #expect(suggestion.folderID == "root_id")
        #expect(suggestion.folderName == "2026-015 Projekt")
        #expect(suggestion.reason == "Projekt-Ordner")
    }

    @Test func suggestOhneKeywordGibtWurzelzurueck() async throws {
        let client = FakeResolverDriveClient(folders: [], fileName: "2026-001 Muster")
        let resolver = DriveFolderSuggestionResolver(driveClient: client)

        let suggestion = try await resolver.suggest(projectDriveFolderID: "root_42")
        #expect(suggestion.folderID == "root_42")
        #expect(suggestion.reason == "Projekt-Ordner")
    }

    @Test func suggestIgnoriertVerbotenenUnterordner() async throws {
        // Ein Unterordner dessen ID auf der NO-GO-Liste steht wird übersprungen.
        let subfolders = [makeFolder(id: "0AOeReQBQKkKBUk9PVA", name: "Verbotener Ordner")]
        let client = FakeResolverDriveClient(folders: subfolders, fileName: "Root")
        let resolver = DriveFolderSuggestionResolver(driveClient: client)

        // Keyword passt, aber der Treffer ist NO-GO → Fallback auf Root
        let suggestion = try await resolver.suggest(
            projectDriveFolderID: "safe_root",
            preferredSubfolderKeyword: "Verboten"
        )
        #expect(suggestion.folderID == "safe_root")
    }
}

// MARK: - Fake Drive Client

private final class FakeResolverDriveClient: GoogleDriveFetching, @unchecked Sendable {
    let folders: [GoogleDriveFile]
    let fileName: String

    init(folders: [GoogleDriveFile], fileName: String) {
        self.folders = folders
        self.fileName = fileName
    }

    func listFolder(folderID: String) async throws -> [GoogleDriveFile] { folders }
    func getFileName(folderID: String) async throws -> String { fileName }
    func downloadContent(fileID: String) async throws -> Data { Data() }
}

// MARK: - Hilfsfunktionen

private func makeFolder(id: String, name: String) -> GoogleDriveFile {
    GoogleDriveFile(
        id: id,
        name: name,
        mimeType: "application/vnd.google-apps.folder",
        modifiedAt: nil,
        webViewLink: nil
    )
}
