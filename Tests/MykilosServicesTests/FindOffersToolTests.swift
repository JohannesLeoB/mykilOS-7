import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

// MARK: - FindOffersTool (S2)

struct FindOffersToolTests {
    private func pdf(_ id: String, _ name: String) -> GoogleDriveFile {
        GoogleDriveFile(id: id, name: name, mimeType: "application/pdf",
                        modifiedAt: Date(timeIntervalSince1970: 1_800_000_000), webViewLink: nil)
    }
    private func folder(_ id: String, _ name: String) -> GoogleDriveFile {
        GoogleDriveFile(id: id, name: name, mimeType: "application/vnd.google-apps.folder",
                        modifiedAt: nil, webViewLink: nil)
    }

    // Reale Struktur: 04/05 verschachtelt in "01 INFOS".
    private func hustadtClient() -> FakeOffersDrive {
        FakeOffersDrive(tree: [
            "hustadt": [folder("infos", "01 INFOS")],
            "infos":   [folder("aus", "04 ausgehende Angebote"), folder("ein", "05 eingehende Angebote")],
            "aus":     [pdf("o1", "AN-A_2026-0189-Hauptküche.pdf")],
            "ein":     [pdf("i1", "Kostenschätzung 260512.pdf")],
        ])
    }

    @Test func findetAngeboteImProjektChatPerInjizierterFolderID() async throws {
        let reg = AssistantToolRegistry.standard(drive: hustadtClient())
        // _driveFolderID wie im Projekt-Chat injiziert.
        let r = await reg.run(name: "find_offers", inputJSON: Data("{}".utf8), driveFolderID: "hustadt")
        #expect(r.isError == false)
        #expect(r.text.contains("AN-A_2026-0189-Hauptküche.pdf"))
        #expect(r.text.contains("Kostenschätzung 260512.pdf"))
    }

    @Test func globalLoestProjektPerNamenAuf() async throws {
        let dir = ProjectDirectory(entries: [
            .init(projectNumber: "2026-015", title: "Hustadt", customerName: "Hustadt", driveFolderID: "hustadt"),
        ])
        let reg = AssistantToolRegistry.standard(drive: hustadtClient(), projectDirectory: dir)
        // Kein _driveFolderID (globaler Chat) → über 'projekt' auflösen.
        let r = await reg.run(name: "find_offers", inputJSON: Data(#"{"projekt":"hustadt"}"#.utf8))
        #expect(r.isError == false)
        #expect(r.text.contains("AN-A_2026-0189-Hauptküche.pdf"))
    }

    @Test func ohneProjektUndOhneFolderFragtNach() async throws {
        let reg = AssistantToolRegistry.standard(drive: hustadtClient())
        let r = await reg.run(name: "find_offers", inputJSON: Data("{}".utf8))
        #expect(r.isError == true)
        #expect(r.text.contains("Projekt"))
    }
}

private final class FakeOffersDrive: GoogleDriveFetching, @unchecked Sendable {
    private let tree: [String: [GoogleDriveFile]]
    init(tree: [String: [GoogleDriveFile]]) { self.tree = tree }
    func listFolder(folderID: String) async throws -> [GoogleDriveFile] { tree[folderID] ?? [] }
    func getFileName(folderID: String) async throws -> String { folderID }
    func downloadContent(fileID: String) async throws -> Data { Data() }
}
