import Testing
import Foundation
@testable import MykilosServices

// MARK: - DriveProjectFolderResolverTests
// Testet ohne echtes Netzwerk/Keychain via FakeDriveClientForResolver.
// findOrCreateSubfolder: URL-Builder + Idempotenz-Semantik.
// DriveProjectFolderResolver: Traversal 01 INFOS → 07 Fragebogen.

struct DriveProjectFolderResolverTests {

    // MARK: - buildFindSubfolderURL

    @Test func findSubfolderURLEnthaeltParentUndName() {
        let url = GoogleDriveClient.buildFindSubfolderURL(
            parentID: "PARENT_123",
            name: "01 INFOS",
            baseURL: "https://www.googleapis.com/drive/v3/files"
        )
        let comps = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(
            uniqueKeysWithValues: (comps?.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )
        #expect(items["q"]?.contains("PARENT_123") == true)
        #expect(items["q"]?.contains("01 INFOS") == true)
        #expect(items["q"]?.contains("application/vnd.google-apps.folder") == true)
        #expect(items["q"]?.contains("trashed=false") == true)
        #expect(items["supportsAllDrives"] == "true")
        #expect(items["includeItemsFromAllDrives"] == "true")
    }

    @Test func findSubfolderURLNutztPageSizeEins() {
        let url = GoogleDriveClient.buildFindSubfolderURL(
            parentID: "X",
            name: "Y",
            baseURL: "https://www.googleapis.com/drive/v3/files"
        )
        let comps = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(
            uniqueKeysWithValues: (comps?.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )
        #expect(items["pageSize"] == "1")
    }

    // MARK: - DriveProjectFolderResolver – Traversal

    @Test func resolveFragebogenOrdnerTraversiertZweiStufen() async throws {
        // Fake: liefert feste IDs für zwei findOrCreateSubfolder-Aufrufe.
        // Aufruf 1 (01 INFOS unter Projekt-ID) → "INFOS_ID"
        // Aufruf 2 (07 Fragebogen unter INFOS_ID) → "FRAGBG_ID"
        let fake = FakeDriveClientForResolver(folderIDByName: [
            "01 INFOS":      "INFOS_ID",
            "07 Fragebogen": "FRAGBG_ID",
        ])
        let resolver = DriveProjectFolderResolver(client: fake)
        let id = try await resolver.resolveFragebogenOrdner(projektDriveOrdnerID: "PROJEKT_ROOT")
        #expect(id == "FRAGBG_ID")
        // Beide Unterordner wurden tatsächlich abgefragt.
        #expect(fake.calledNames == ["01 INFOS", "07 Fragebogen"])
        // Zweiter Aufruf nutzte die ID aus dem ersten Schritt.
        #expect(fake.calledParents == ["PROJEKT_ROOT", "INFOS_ID"])
    }

    @Test func resolveFragebogenOrdnerWirftNotConnectedOhneToken() async {
        let fake = ThrowingDriveClientForResolver()
        let resolver = DriveProjectFolderResolver(client: fake)
        do {
            _ = try await resolver.resolveFragebogenOrdner(projektDriveOrdnerID: "X")
            Issue.record("Erwartete GoogleDriveError.notConnected")
        } catch {
            #expect(error as? GoogleDriveError == .notConnected)
        }
    }
}

// MARK: - Fake-Implementierungen

/// Liefert feste Ordner-IDs nach Namen; merkt sich die Aufruf-Reihenfolge.
final class FakeDriveClientForResolver: GoogleDriveFetching, @unchecked Sendable {
    let folderIDByName: [String: String]
    private(set) var calledNames:   [String] = []
    private(set) var calledParents: [String] = []

    init(folderIDByName: [String: String]) {
        self.folderIDByName = folderIDByName
    }

    func findOrCreateSubfolder(parentID: String, name: String) async throws -> String {
        calledParents.append(parentID)
        calledNames.append(name)
        guard let id = folderIDByName[name] else {
            throw GoogleDriveError.decodingFailed
        }
        return id
    }

    // Pflicht-Stubs — nicht genutzt in diesen Tests.
    func listFolder(folderID: String) async throws -> [GoogleDriveFile] { [] }
    func getFileName(folderID: String) async throws -> String { "" }
    func downloadContent(fileID: String) async throws -> Data { Data() }
}

/// Wirft sofort notConnected für alle Methoden.
struct ThrowingDriveClientForResolver: GoogleDriveFetching {
    func findOrCreateSubfolder(parentID: String, name: String) async throws -> String {
        throw GoogleDriveError.notConnected
    }
    func listFolder(folderID: String) async throws -> [GoogleDriveFile] {
        throw GoogleDriveError.notConnected
    }
    func getFileName(folderID: String) async throws -> String {
        throw GoogleDriveError.notConnected
    }
    func downloadContent(fileID: String) async throws -> Data {
        throw GoogleDriveError.notConnected
    }
}
