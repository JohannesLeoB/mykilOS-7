import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

@MainActor
struct DriveOfferWatcherTests {

    // MARK: - Reine Erkennungslogik

    @Test func detectOffersErkenntNurAngebotsPDFs() {
        let files = [
            file(id: "1", name: "Angebot Arbeitsplatte.pdf", mime: "application/pdf"),
            file(id: "2", name: "RECHNUNG_2024_07.PDF", mime: "application/pdf"),
            file(id: "3", name: "Grundriss.pdf", mime: "application/pdf"),          // kein Schlüsselwort
            file(id: "4", name: "Angebot.docx", mime: "application/msword"),         // kein PDF
            file(id: "5", name: "kostenvoranschlag-kueche.pdf", mime: "application/pdf"),
        ]
        let offers = DriveOfferWatcher.detectOffers(in: files)
        #expect(Set(offers.map(\.id)) == ["1", "2", "5"])
    }

    // MARK: - Typ-Whitelist (EINE Quelle der Wahrheit — Filter-Regel)

    @Test func typWhitelistLaesstNurBelegTypenDurch() {
        // Angebote sind NIE ZIP/.numbers — meist PDF, manchmal Bild, selten Mail.
        #expect(DriveOfferWatcher.isAcceptedOfferFileType(
            file(id: "pdf",  name: "Angebot.pdf",           mime: "application/pdf")))
        #expect(DriveOfferWatcher.isAcceptedOfferFileType(
            file(id: "img",  name: "Scan_Angebot.jpg",      mime: "image/jpeg")))
        #expect(DriveOfferWatcher.isAcceptedOfferFileType(
            file(id: "png",  name: "Beleg.PNG",             mime: "image/png")))
        #expect(DriveOfferWatcher.isAcceptedOfferFileType(
            file(id: "mail", name: "Anfrage.eml",           mime: "message/rfc822")))
        // Raus: ZIP, .numbers, Ordner, Office-Sonstiges.
        #expect(DriveOfferWatcher.isAcceptedOfferFileType(
            file(id: "zip",  name: "Produktdatenblätter.zip",     mime: "application/zip")) == false)
        #expect(DriveOfferWatcher.isAcceptedOfferFileType(
            file(id: "num",  name: "Geräteübersicht.numbers",     mime: "application/x-iwork-numbers-sffnumbers")) == false)
        #expect(DriveOfferWatcher.isAcceptedOfferFileType(
            file(id: "xls",  name: "Kalkulation.xlsx",            mime: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")) == false)
        #expect(DriveOfferWatcher.isAcceptedOfferFileType(
            file(id: "dir",  name: "05 eingehende Angebote",      mime: "application/vnd.google-apps.folder")) == false)
    }

    @Test func detectOffersFiltertZipTrotzSchluesselwort() {
        // „Angebot_Paket.zip" hat ein Schlüsselwort, ist aber ein ZIP → kein Angebot.
        let files = [
            file(id: "1", name: "Angebot Naturstein.pdf",  mime: "application/pdf"),
            file(id: "2", name: "Angebot_Paket.zip",       mime: "application/zip"),
            file(id: "3", name: "Rechnung_Scan.jpg",       mime: "image/jpeg"),
            file(id: "4", name: "Übersicht.numbers",       mime: "application/x-iwork-numbers-sffnumbers"),
        ]
        let offers = DriveOfferWatcher.detectOffers(in: files)
        #expect(Set(offers.map(\.id)) == ["1", "3"])   // PDF + Bild mit Schlüsselwort; ZIP/.numbers raus
    }

    // MARK: - Poll-Semantik

    @Test func ersterPollLegtNurBaselineAnUndMeldetNichts() async {
        let fake = FakeDriveClient(files: [
            file(id: "1", name: "Angebot alt.pdf", mime: "application/pdf"),
        ])
        let watcher = DriveOfferWatcher(client: fake)

        let signals = await watcher.poll(projectID: "ME-24", folderID: "folder1")
        #expect(signals.isEmpty)
    }

    @Test func zweiterPollMeldetNurNeuesAngebot() async {
        let fake = FakeDriveClient(files: [
            file(id: "1", name: "Angebot alt.pdf", mime: "application/pdf"),
        ])
        let watcher = DriveOfferWatcher(client: fake)

        _ = await watcher.poll(projectID: "ME-24", folderID: "folder1")   // Baseline

        fake.files.append(file(id: "2", name: "Angebot Naturstein.pdf", mime: "application/pdf"))
        let signals = await watcher.poll(projectID: "ME-24", folderID: "folder1")

        #expect(signals.count == 1)
        if case let .offerDetected(projectID, label) = signals.first {
            #expect(projectID == "ME-24")
            #expect(label == "Angebot Naturstein.pdf")
        } else {
            Issue.record("erwartet offerDetected, war \(String(describing: signals.first))")
        }
    }

    @Test func gleichesAngebotWirdNichtZweimalGemeldet() async {
        let fake = FakeDriveClient(files: [
            file(id: "1", name: "Angebot.pdf", mime: "application/pdf"),
        ])
        let watcher = DriveOfferWatcher(client: fake)

        _ = await watcher.poll(projectID: "ME-24", folderID: "folder1")   // Baseline
        fake.files.append(file(id: "2", name: "Rechnung neu.pdf", mime: "application/pdf"))
        let first = await watcher.poll(projectID: "ME-24", folderID: "folder1")
        let second = await watcher.poll(projectID: "ME-24", folderID: "folder1")

        #expect(first.count == 1)
        #expect(second.isEmpty)
    }

    @Test func neueNichtAngebotDateiEmitiertDriveFileAdded() async {
        let fake = FakeDriveClient(files: [
            file(id: "1", name: "Zeichnung.pdf", mime: "application/pdf"),
        ])
        let watcher = DriveOfferWatcher(client: fake)

        _ = await watcher.poll(projectID: "ME-24", folderID: "folder1")   // Baseline

        fake.files.append(file(id: "2", name: "Grundriss_v2.pdf", mime: "application/pdf"))
        let signals = await watcher.poll(projectID: "ME-24", folderID: "folder1")

        #expect(signals.count == 1)
        if case let .driveFileAdded(projectID, fileName) = signals.first {
            #expect(projectID == "ME-24")
            #expect(fileName == "Grundriss_v2.pdf")
        } else {
            Issue.record("erwartet driveFileAdded, war \(String(describing: signals.first))")
        }
    }

    // MARK: - "Neue Werkzeichnung"-Alert (2026-07-07)

    @Test func neueZeichnungEmitiertDrawingDetected() async {
        let fake = FakeDriveClient(files: [
            file(id: "1", name: "Angebot alt.pdf", mime: "application/pdf"),
        ])
        let watcher = DriveOfferWatcher(client: fake)
        _ = await watcher.poll(projectID: "ME-24", folderID: "folder1")   // Baseline

        fake.files.append(file(id: "2", name: "Werkzeichnung_Kueche_v2.pdf", mime: "application/pdf"))
        let signals = await watcher.poll(projectID: "ME-24", folderID: "folder1")

        #expect(signals.count == 1)
        if case let .drawingDetected(projectID, label) = signals.first {
            #expect(projectID == "ME-24")
            #expect(label == "Werkzeichnung_Kueche_v2.pdf")
        } else {
            Issue.record("erwartet drawingDetected, war \(String(describing: signals.first))")
        }
    }

    @Test func zeichnungKeywordGreiftAuchOhneWerkPraefix() {
        let files = [file(id: "1", name: "Zeichnung Bad.pdf", mime: "application/pdf")]
        #expect(DriveOfferWatcher.isWerkzeichnung(files[0]))
    }

    @Test func zeichnungTypWhitelistGreiftGenauwieBeleg() {
        // ZIP mit Schlüsselwort ist trotzdem keine Werkzeichnung — gleiche Typ-Whitelist.
        let zip = file(id: "1", name: "Werkzeichnung_Paket.zip", mime: "application/zip")
        #expect(DriveOfferWatcher.isWerkzeichnung(zip) == false)
    }

    @Test func angebotUndZeichnungSchliessenSichGegenseitigAus() async {
        // Ein Dateiname mit BEIDEN Schlüsselwörtern ist unwahrscheinlich, aber die
        // Klassifikation muss deterministisch sein: Angebot hat Vorrang (poll()-Reihenfolge).
        let fake = FakeDriveClient(files: [])
        let watcher = DriveOfferWatcher(client: fake)
        _ = await watcher.poll(projectID: "ME-24", folderID: "folder1")   // Baseline

        fake.files.append(file(id: "1", name: "Angebot_mit_Zeichnung.pdf", mime: "application/pdf"))
        let signals = await watcher.poll(projectID: "ME-24", folderID: "folder1")

        #expect(signals.count == 1)
        if case .offerDetected = signals.first {
            // erwartet
        } else {
            Issue.record("erwartet offerDetected (Angebot hat Vorrang), war \(String(describing: signals.first))")
        }
    }

    @Test func fehlerOderLeererOrdnerMeldetNichts() async {
        let failing = FakeDriveClient(files: [], error: GoogleDriveError.notConnected)
        let watcher = DriveOfferWatcher(client: failing)
        let signals = await watcher.poll(projectID: "ME-24", folderID: "folder1")
        #expect(signals.isEmpty)

        let empty = FakeDriveClient(files: [])
        let watcher2 = DriveOfferWatcher(client: empty)
        let baselineSignals = await watcher2.poll(projectID: "ME-24", folderID: "")
        #expect(baselineSignals.isEmpty)
    }

    // MARK: - Helfer

    private func file(id: String, name: String, mime: String) -> GoogleDriveFile {
        GoogleDriveFile(id: id, name: name, mimeType: mime, modifiedAt: nil, webViewLink: nil)
    }
}

// MARK: - FakeDriveClient

final class FakeDriveClient: GoogleDriveFetching, @unchecked Sendable {
    var files: [GoogleDriveFile]
    private let error: Error?

    init(files: [GoogleDriveFile], error: Error? = nil) {
        self.files = files
        self.error = error
    }

    func listFolder(folderID: String) async throws -> [GoogleDriveFile] {
        if let error { throw error }
        return files
    }

    func getFileName(folderID: String) async throws -> String {
        if let error { throw error }
        return "TestOrdner"
    }

    func downloadContent(fileID: String) async throws -> Data {
        if let error { throw error }
        return Data()
    }
}
