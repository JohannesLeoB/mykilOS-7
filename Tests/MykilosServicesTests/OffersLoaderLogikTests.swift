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

// MARK: - Pagination (Fake-Ebene)
// Hinweis: Die ECHTE nextPageToken-Schleife von GoogleDriveClient.listFolder wird in
// GoogleDriveClientTests.listFolderFolgtNextPageTokenUeberZweiSeiten() gegen eine
// gestubbte URLSession getestet. Dieser Fake-Test prüft nur, dass der Collector mit
// einem mehrseitig befüllten Ordner alle Treffer sieht.

struct DriveClientPaginierungTests {

    @Test func fakeClientLiefertAlleSeitenkombiniert() async throws {
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

// MARK: - RekursionTest (jetzt gegen die ECHTE OffersCollector-Logik, Mandate C/F7)

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

        let eingehendFolderObj = OffersCollector.subfolder(
            in: try await client.listFolder(folderID: "root"), matching: "eingehende")
        #expect(eingehendFolderObj != nil)

        // ECHTE Produktionslogik (kein nachgebauter Klon).
        let files = try await OffersCollector.collect(in: eingehendFolderObj, client: client, depth: 0)
        #expect(files.count == 2)
        #expect(files.map(\.file.name).contains("Kostenschätzung_2026.pdf"))
        #expect(files.map(\.file.name).contains("direkt.pdf"))
        // Sicheres Signal: die geschachtelte Datei trägt den Unterordnernamen.
        #expect(files.first { $0.file.name == "Kostenschätzung_2026.pdf" }?.parentName == "Vorplanung")
        #expect(files.first { $0.file.name == "direkt.pdf" }?.parentName == nil)
    }

    @Test func tiefenbegrenzungBeiDreiEbenen() async throws {
        // 4 Ebenen tief — Ebene 4 darf nicht geladen werden.
        let client = DeepTreeFakeDriveClient(depth: 4)
        let root = try await client.listFolder(folderID: "root")
        let folder = root.first { $0.isFolder }
        let files = try await OffersCollector.collect(in: folder, client: client, depth: 0)
        // depth=0 Startpunkt → max. 3 Levels tiefer (Depth 0,1,2) = 3 PDFs
        #expect(files.count <= 3)
    }

    @Test func fehlendeIncomingFolderLiefertLeereArray() async throws {
        let client = TreeFakeDriveClient(tree: ["root": []])
        let result = try await OffersCollector.collect(in: nil, client: client, depth: 0)
        #expect(result.isEmpty)
    }
}

// MARK: - OffersCollector end-to-end (Mandate C — die echte Lade+Klassifikations-Kette)

struct OffersCollectorLoadTests {

    @Test func loadKlassifiziertEingehendUndAusgehendMitOrdnerSignal() async throws {
        // root → "05 eingehende Angebote"/Vorplanung/202603971.pdf  (Lieferanten-Angebot)
        //      → "04 ausgehende Angebote"/Rechnung/SR-SR_2026-0170-Kdnr-12822.pdf (Schlussrechnung)
        let lieferant = makePDF("202603971.pdf", id: "f1")
        let schluss   = makePDF("SR-SR_2026-0170-Kdnr-12822.pdf", id: "f2")
        let client = TreeFakeDriveClient(tree: [
            "root": [makeFolder("05 eingehende Angebote", id: "ein"),
                     makeFolder("04 ausgehende Angebote", id: "aus")],
            "ein":  [makeFolder("Vorplanung", id: "vp")],
            "vp":   [lieferant],
            "aus":  [makeFolder("Rechnung", id: "re")],
            "re":   [schluss],
        ])

        let result = try await OffersCollector.load(rootFolderID: "root", client: client)
        #expect(result.incomingFolderFound)
        #expect(result.outgoingFolderFound)
        // Eingehend: rein numerischer Lieferanten-Beleg → eingehendesAngebot.
        #expect(result.incoming.count == 1)
        #expect(result.incoming.first?.type == .eingehendesAngebot)
        // Ausgehend: Ordnername „Rechnung" (sicher) + Präfix „SR" → Schlussrechnung,
        // Belegnummer extrahiert.
        #expect(result.outgoing.count == 1)
        #expect(result.outgoing.first?.type == .schlussrechnung)
        #expect(result.outgoing.first?.belegNummer == "2026-0170")
    }

    @Test func loadOhneAngebotsOrdnerMeldetNichtGefunden() async throws {
        let client = TreeFakeDriveClient(tree: ["root": [makeFolder("01 INFOS", id: "x")]])
        let result = try await OffersCollector.load(rootFolderID: "root", client: client)
        #expect(result.incomingFolderFound == false)
        #expect(result.outgoingFolderFound == false)
        #expect(result.incoming.isEmpty)
        #expect(result.outgoing.isEmpty)
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
