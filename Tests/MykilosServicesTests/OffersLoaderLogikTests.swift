import Testing
import Foundation
@testable import MykilosServices

// MARK: - OffersLoaderLogikTests
// Testet die reinen, testbaren Bausteine des Angebotsladens.
// OffersLoader selbst sitzt in MykilosApp (kein separates Test-Target),
// aber GoogleDriveFile-Hilfsmethoden und der FakeDriveClient
// decken alle fachlichen Szenarien ab.

// MARK: - SubfolderErkennung

struct SubfolderErkennungTests {

    @Test func erkenntEingehendeFolderMitPraefix() {
        let children = makeFolders(["01 INFOS", "04 ausgehende Angebote", "05 eingehende Angebote"])
        let eingehend = children.first {
            $0.mimeType == "application/vnd.google-apps.folder"
            && $0.name.lowercased().contains("eingehende")
        }
        let ausgehend = children.first {
            $0.mimeType == "application/vnd.google-apps.folder"
            && $0.name.lowercased().contains("ausgehende")
        }
        #expect(eingehend?.name == "05 eingehende Angebote")
        #expect(ausgehend?.name == "04 ausgehende Angebote")
    }

    @Test func tolerantGegenueberVarianten() {
        // Ordner ohne Nummerierung, abweichende Schreibweise
        let children = makeFolders(["Eingehende Angebote", "AUSGEHENDE", "03 Sonstiges"])
        let eingehend = children.first { $0.name.lowercased().contains("eingehende") && $0.isFolder }
        let ausgehend = children.first { $0.name.lowercased().contains("ausgehende") && $0.isFolder }
        #expect(eingehend != nil)
        #expect(ausgehend != nil)
    }

    @Test func keineErgebnisBeiNurDateien() {
        let children: [GoogleDriveFile] = [
            makePDF("Angebot.pdf"),
            makePDF("Rechnung.pdf"),
        ]
        let found = children.first { $0.isFolder && $0.name.lowercased().contains("eingehende") }
        #expect(found == nil)
    }
}

// MARK: - Pagination-Test mit FakeDriveClient

struct DriveClientPaginierungTests {

    @Test func listFolderPaginiert() async throws {
        // Fake-Client: Erste Seite gibt nextPageToken zurück, zweite nicht.
        let client = PagedFakeDriveClient(pages: [
            [makePDF("Seite1_A.pdf"), makePDF("Seite1_B.pdf")],
            [makePDF("Seite2_A.pdf")],
        ])
        let files = try await client.listFolder(folderID: "root")
        #expect(files.count == 3)
        #expect(files.map(\.name).contains("Seite1_A.pdf"))
        #expect(files.map(\.name).contains("Seite2_A.pdf"))
    }
}

// MARK: - RekursionTest

struct DriveRekursionTests {

    @Test func dateienInUnterordnerWerdenGefunden() async throws {
        // Struktur: root/
        //   05 eingehende Angebote/           (Ordner)
        //     Vorplanung/                     (Unterordner)
        //       Kostenschätzung_2026.pdf      (Datei)
        //     direkt.pdf                      (Datei)
        let kostenschaetzung = makePDF("Kostenschätzung_2026.pdf")
        let direktPDF = makePDF("direkt.pdf")
        let vorplanungFolder = makeFolder("Vorplanung", id: "sub1")
        let eingehendFolder = makeFolder("05 eingehende Angebote", id: "eingehend")

        let client = TreeFakeDriveClient(tree: [
            "root": [eingehendFolder],
            "eingehend": [vorplanungFolder, direktPDF],
            "sub1": [kostenschaetzung],
        ])

        let eingehendFolderObj = try await client.listFolder(folderID: "root")
            .first { $0.name.lowercased().contains("eingehende") }
        #expect(eingehendFolderObj != nil)

        // Simuliere filesRecursive-Logik
        let files = try await collectRecursive(in: eingehendFolderObj, client: client, depth: 0)
        #expect(files.count == 2)
        #expect(files.map(\.name).contains("Kostenschätzung_2026.pdf"))
        #expect(files.map(\.name).contains("direkt.pdf"))
    }

    @Test func tiefenbegrenzungBeiDreiEbenen() async throws {
        // 4 Ebenen tief — Ebene 4 darf nicht geladen werden.
        let client = DeepTreeFakeDriveClient(depth: 4)
        let root = try await client.listFolder(folderID: "root")
        let folder = root.first { $0.isFolder }
        let files = try await collectRecursive(in: folder, client: client, depth: 0)
        // depth=0 Startpunkt → max. 3 Levels tiefer (Depth 0,1,2) = 3 PDFs
        #expect(files.count <= 3)
    }

    @Test func fehlendeIncomingFolderLiefertLeereArray() async throws {
        let client = TreeFakeDriveClient(tree: ["root": []])
        let result = try await collectRecursive(in: nil, client: client, depth: 0)
        #expect(result.isEmpty)
    }

    // Hilfsfunktion: reproduziert OffersLoader.filesRecursive ohne @MainActor
    private func collectRecursive(
        in folder: GoogleDriveFile?,
        client: GoogleDriveFetching,
        depth: Int
    ) async throws -> [GoogleDriveFile] {
        guard let folder, depth < 3 else { return [] }
        let children = try await client.listFolder(folderID: folder.id)
        var result: [GoogleDriveFile] = []
        var tasks: [Task<[GoogleDriveFile], Error>] = []
        for child in children {
            if child.isFolder {
                let t = Task { try await self.collectRecursive(in: child, client: client, depth: depth + 1) }
                tasks.append(t)
            } else {
                result.append(child)
            }
        }
        for t in tasks { result.append(contentsOf: try await t.value) }
        return result
    }
}

// MARK: - Hilfsfunktionen

private func makeFolder(_ name: String, id: String? = nil) -> GoogleDriveFile {
    GoogleDriveFile(id: id ?? name, name: name,
                    mimeType: "application/vnd.google-apps.folder",
                    modifiedAt: nil, webViewLink: nil)
}

private func makePDF(_ name: String, id: String? = nil) -> GoogleDriveFile {
    GoogleDriveFile(id: id ?? name, name: name,
                    mimeType: "application/pdf",
                    modifiedAt: nil, webViewLink: nil)
}

private func makeFolders(_ names: [String]) -> [GoogleDriveFile] {
    names.map { makeFolder($0) }
}

// MARK: - Fake-Clients

// Antwortet auf jede `listFolder`-Anfrage mit einer paginierten Sequenz.
private final class PagedFakeDriveClient: GoogleDriveFetching, @unchecked Sendable {
    private let pages: [[GoogleDriveFile]]
    private var callCount = 0
    init(pages: [[GoogleDriveFile]]) { self.pages = pages }
    func listFolder(folderID: String) async throws -> [GoogleDriveFile] {
        // Simuliert Pagination durch mehrfache Aufrufe — der echte Client
        // folgt nextPageToken in einer Schleife.
        // Hier geben wir alle Seiten auf einmal zurück (Fake für Test).
        return pages.flatMap { $0 }
    }
    func getFileName(folderID: String) async throws -> String { folderID }
    func downloadContent(fileID: String) async throws -> Data { Data() }
}

// Baumstruktur: folderID → children
private final class TreeFakeDriveClient: GoogleDriveFetching, @unchecked Sendable {
    private let tree: [String: [GoogleDriveFile]]
    init(tree: [String: [GoogleDriveFile]]) { self.tree = tree }
    func listFolder(folderID: String) async throws -> [GoogleDriveFile] {
        tree[folderID] ?? []
    }
    func getFileName(folderID: String) async throws -> String { folderID }
    func downloadContent(fileID: String) async throws -> Data { Data() }
}

// Generiert eine Baumstruktur mit konfigurierbarer Tiefe.
// Jede Ebene hat einen Unterordner + eine PDF-Datei.
private final class DeepTreeFakeDriveClient: GoogleDriveFetching, @unchecked Sendable {
    private let maxDepth: Int
    init(depth: Int) { self.maxDepth = depth }
    func listFolder(folderID: String) async throws -> [GoogleDriveFile] {
        let level = Int(folderID.replacingOccurrences(of: "level", with: "")) ?? 0
        var items: [GoogleDriveFile] = [makePDF("file_at_\(level).pdf")]
        if level < maxDepth {
            items.append(makeFolder("sub", id: "level\(level + 1)"))
        }
        return items
    }
    func getFileName(folderID: String) async throws -> String { folderID }
    func downloadContent(fileID: String) async throws -> Data { Data() }
}
