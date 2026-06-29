import Testing
import Foundation
@testable import MykilosServices

// MARK: - DriveFileReader / read_drive_file (S5)

struct DriveFileReaderTests {
    private func folder(_ id: String, _ name: String) -> GoogleDriveFile {
        GoogleDriveFile(id: id, name: name, mimeType: "application/vnd.google-apps.folder", modifiedAt: nil, webViewLink: nil)
    }
    private func txt(_ id: String, _ name: String) -> GoogleDriveFile {
        GoogleDriveFile(id: id, name: name, mimeType: "text/plain", modifiedAt: nil, webViewLink: nil)
    }

    @Test func findetUndLiestVerschachtelteTextdatei() async throws {
        // root → 01 INFOS → 07 Fragebogen → Fragebogen.txt (Inhalt: Kundenname)
        let client = ContentFakeDrive(
            tree: [
                "root":  [folder("infos", "01 INFOS")],
                "infos": [folder("fb", "07 Fragebogen")],
                "fb":    [txt("f1", "Fragebogen Cirnavuk.txt")],
            ],
            content: ["f1": Data("Kunde: Sinem Cirnavuk\nAdresse: Siebenbrüderweide 9".utf8)])

        let file = try await DriveFileReader.findFile(named: "fragebogen", in: "root", client: client)
        #expect(file?.id == "f1")
        let text = try await DriveFileReader.text(of: file!, client: client)
        #expect(text?.contains("Sinem Cirnavuk") == true)
    }

    @Test func toolLiestInhaltImProjektChat() async {
        let client = ContentFakeDrive(
            tree: ["root": [txt("f1", "Notiz.txt")]],
            content: ["f1": Data("Brüheinheit prüfen".utf8)])
        let reg = AssistantToolRegistry.standard(drive: client)
        let r = await reg.run(name: "read_drive_file", inputJSON: Data(#"{"datei":"Notiz"}"#.utf8), driveFolderID: "root")
        #expect(r.isError == false)
        #expect(r.text.contains("Brüheinheit prüfen"))
    }

    @Test func toolMeldetNichtGefunden() async {
        let client = ContentFakeDrive(tree: ["root": []], content: [:])
        let reg = AssistantToolRegistry.standard(drive: client)
        let r = await reg.run(name: "read_drive_file", inputJSON: Data(#"{"datei":"x"}"#.utf8), driveFolderID: "root")
        #expect(r.isError == true)
    }
}

private final class ContentFakeDrive: GoogleDriveFetching, @unchecked Sendable {
    private let tree: [String: [GoogleDriveFile]]
    private let content: [String: Data]
    init(tree: [String: [GoogleDriveFile]], content: [String: Data]) { self.tree = tree; self.content = content }
    func listFolder(folderID: String) async throws -> [GoogleDriveFile] { tree[folderID] ?? [] }
    func getFileName(folderID: String) async throws -> String { folderID }
    func downloadContent(fileID: String) async throws -> Data { content[fileID] ?? Data() }
}
