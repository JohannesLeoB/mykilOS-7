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
