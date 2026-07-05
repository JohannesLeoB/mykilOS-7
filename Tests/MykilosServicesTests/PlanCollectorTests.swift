import Testing
import Foundation
@testable import MykilosServices

// MARK: - PlanCollectorTests (Zeichnungs-/Planstand-Katalog)
// Testet die reine Sammel-/Kategorisierungs-Logik gegen einen Fake-Drive-Client
// (Muster AllOffersCollectorTests): verschachtelte Schema-Ordner, Diakritik-
// Toleranz, Prioritäts-Eindeutigkeit, fehlende Ordner, Typ-Whitelist, maxDepth,
// Präsentations-Regressionsschutz (alter Material-Tab-Umfang bleibt erhalten).

struct PlanCollectorTests {

    // (a) "01 Pläne" liegt live unter "01 INFOS/" — muss auf Tiefe 2 gefunden werden.
    @Test func findetVerschachteltePlaeneUnterInfos() async throws {
        let client = PlanFakeClient(tree: [
            "ROOT":   [folder("01 INFOS", "infos"), folder("02 Fotos Bestand", "fotos")],
            "infos":  [folder("01 Pläne", "plaene")],
            "plaene": [pdf("Grundriss_EG.pdf", "p1")],
        ])
        let result = try await PlanCollector.load(rootFolderID: "ROOT", client: client)
        #expect(result.foundCategories.contains(.plaene))
        #expect(result.filesByCategory[.plaene]?.map(\.name) == ["Grundriss_EG.pdf"])
    }

    // (b) Diakritik-/Groß-Klein-Toleranz: "Plaene", "PLÄNE", "pläne" treffen alle.
    @Test func matchtDiakritikTolerant() {
        #expect(PlanCollector.category(forFolderName: "01 Pläne") == .plaene)
        #expect(PlanCollector.category(forFolderName: "Plaene") == .plaene)
        #expect(PlanCollector.category(forFolderName: "PLÄNE ALT") == .plaene)
        #expect(PlanCollector.category(forFolderName: "08 Werkszeichnung") == .werkszeichnung)
        #expect(PlanCollector.category(forFolderName: "Werkzeichnungen") == .werkszeichnung)
        #expect(PlanCollector.category(forFolderName: "RENDERINGS") == .renderings)
        #expect(PlanCollector.category(forFolderName: "03 PRÄSENTATION") == .praesentation)
        #expect(PlanCollector.category(forFolderName: "presentation") == .praesentation)
        #expect(PlanCollector.category(forFolderName: "02 Fotos Bestand") == nil)
    }

    // (c) Prioritäts-Eindeutigkeit: ein Ordner bekommt maximal EINE Kategorie,
    // spezifische Signale schlagen das generische "plane"-Substring.
    @Test func prioritaetVerhindertDoppelzuordnung() {
        #expect(PlanCollector.category(forFolderName: "Vorplanung | Screenshots") == .vorplanung)
        #expect(PlanCollector.category(forFolderName: "Layoutpläne") == .layouts)
        #expect(PlanCollector.category(forFolderName: "Werkszeichnungspläne") == .werkszeichnung)
    }

    // (c2) Im Baum: "Vorplanung | Screenshots" darf NICHT zusätzlich als plaene zählen.
    @Test func vorplanungLandetNichtInPlaene() async throws {
        let client = PlanFakeClient(tree: [
            "ROOT": [folder("Vorplanung | Screenshots", "vp")],
            "vp":   [image("Screenshot_Kueche.png", "s1")],
        ])
        let result = try await PlanCollector.load(rootFolderID: "ROOT", client: client)
        #expect(result.foundCategories == [.vorplanung])
        #expect(result.filesByCategory[.plaene] == nil)
        #expect(result.filesByCategory[.vorplanung]?.count == 1)
    }

    // (d) Fehlende Schema-Ordner → leere Kategorien, kein Fehler, kein Wurf.
    @Test func fehlendeOrdnerSindLeerStattFehler() async throws {
        let client = PlanFakeClient(tree: [
            "ROOT": [folder("99 Sonstiges", "x")],
            "x":    [pdf("irgendwas.pdf", "f1")],
        ])
        let result = try await PlanCollector.load(rootFolderID: "ROOT", client: client)
        #expect(result.foundCategories.isEmpty)
        #expect(result.isEmpty)
    }

    // (e) Typ-Whitelist: PDF/Bilder rein, ZIP/.numbers/Mail raus.
    @Test func whitelistFiltertNichtPlanDateien() async throws {
        let client = PlanFakeClient(tree: [
            "ROOT": [folder("Renderings", "r")],
            "r": [
                pdf("Rendering_final.pdf", "ok1"),
                image("Kueche_v2.jpg", "ok2"),
                image("Insel.heic", "ok3"),
                file("Archiv.zip", "bad1", mime: "application/zip"),
                file("Kalkulation.numbers", "bad2", mime: "application/octet-stream"),
                file("Korrespondenz.eml", "bad3", mime: "message/rfc822"),
            ],
        ])
        let result = try await PlanCollector.load(rootFolderID: "ROOT", client: client)
        let names = Set(result.filesByCategory[.renderings]?.map(\.name) ?? [])
        #expect(names == ["Rendering_final.pdf", "Kueche_v2.jpg", "Insel.heic"])
    }

    // (f) maxDepth wird respektiert — zu tief liegende Schema-Ordner bleiben unentdeckt.
    @Test func maxDepthBegrenztDieSuche() async throws {
        let client = PlanFakeClient(tree: [
            "ROOT": [folder("Ebene1", "e1")],
            "e1":   [folder("Ebene2", "e2")],
            "e2":   [folder("08 Werkszeichnung", "wz")],
            "wz":   [pdf("Detail.pdf", "d1")],
        ])
        let flach = try await PlanCollector.load(rootFolderID: "ROOT", client: client, maxDepth: 1)
        #expect(flach.foundCategories.isEmpty)

        let tief = try await PlanCollector.load(rootFolderID: "ROOT", client: client, maxDepth: 3)
        #expect(tief.foundCategories.contains(.werkszeichnung))
    }

    // (g) Regressionsschutz: der alte Material-Tab-Umfang (03 PRÄSENTATION) bleibt.
    @Test func praesentationWirdWeiterGefunden() async throws {
        let client = PlanFakeClient(tree: [
            "ROOT":  [folder("03 PRÄSENTATION", "praes")],
            "praes": [pdf("Moodboard_Schmidt.pdf", "m1")],
        ])
        let result = try await PlanCollector.load(rootFolderID: "ROOT", client: client)
        #expect(result.foundCategories.contains(.praesentation))
        #expect(result.filesByCategory[.praesentation]?.count == 1)
        // Präsentation gehört NICHT in den globalen Katalog:
        #expect(PlanCategory.praesentation.inGlobalKatalog == false)
        #expect(PlanCategory.plaene.inGlobalKatalog == true)
    }

    // Sortierung innerhalb einer Kategorie: neueste zuerst.
    @Test func sortiertProKategorieNeuesteZuerst() async throws {
        let client = PlanFakeClient(tree: [
            "ROOT": [folder("Layouts", "l")],
            "l": [
                pdf("alt.pdf", "a", at: Date(timeIntervalSince1970: 1_000)),
                pdf("neu.pdf", "n", at: Date(timeIntervalSince1970: 9_000)),
            ],
        ])
        let result = try await PlanCollector.load(rootFolderID: "ROOT", client: client)
        #expect(result.filesByCategory[.layouts]?.map(\.name) == ["neu.pdf", "alt.pdf"])
    }
}

// MARK: - Hilfen

private func folder(_ name: String, _ id: String) -> GoogleDriveFile {
    GoogleDriveFile(id: id, name: name, mimeType: "application/vnd.google-apps.folder",
                    modifiedAt: nil, webViewLink: nil)
}

private func pdf(_ name: String, _ id: String, at date: Date? = nil) -> GoogleDriveFile {
    GoogleDriveFile(id: id, name: name, mimeType: "application/pdf",
                    modifiedAt: date, webViewLink: nil)
}

private func image(_ name: String, _ id: String) -> GoogleDriveFile {
    GoogleDriveFile(id: id, name: name, mimeType: "image/jpeg",
                    modifiedAt: nil, webViewLink: nil)
}

private func file(_ name: String, _ id: String, mime: String) -> GoogleDriveFile {
    GoogleDriveFile(id: id, name: name, mimeType: mime, modifiedAt: nil, webViewLink: nil)
}

private final class PlanFakeClient: GoogleDriveFetching, @unchecked Sendable {
    private let tree: [String: [GoogleDriveFile]]
    init(tree: [String: [GoogleDriveFile]]) { self.tree = tree }
    func listFolder(folderID: String) async throws -> [GoogleDriveFile] { tree[folderID] ?? [] }
    func getFileName(folderID: String) async throws -> String { folderID }
    func downloadContent(fileID: String) async throws -> Data { Data() }
}
