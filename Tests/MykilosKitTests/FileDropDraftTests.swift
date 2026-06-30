import Testing
import Foundation
@testable import MykilosKit

// MARK: - FileDropDraftTests
// Unit-Tests für DroppedFile-Domäne (rein in-memory, kein Netzwerk/Keychain).

struct FileDropDraftTests {

    // MARK: - DroppedFile

    @Test func droppedFileHatKorrekteMetadaten() {
        let data = Data("PDF-Inhalt".utf8)
        let file = DroppedFile(fileName: "Angebot.pdf", mimeType: "application/pdf", data: data)
        #expect(file.fileName == "Angebot.pdf")
        #expect(file.mimeType == "application/pdf")
        #expect(file.data == data)
    }

    @Test func humanSizeZeigteBytes() {
        let file = DroppedFile(fileName: "tiny.txt", mimeType: "text/plain", data: Data("abc".utf8))
        #expect(file.humanSize == "3 B")
    }

    @Test func humanSizeZeigtKilobytes() {
        let data = Data(repeating: 0, count: 2048)
        let file = DroppedFile(fileName: "klein.bin", mimeType: "application/octet-stream", data: data)
        #expect(file.humanSize == "2 KB")
    }

    @Test func humanSizeZeigtMegabytes() {
        let data = Data(repeating: 0, count: 2_000_000)
        let file = DroppedFile(fileName: "gross.pdf", mimeType: "application/pdf", data: data)
        // 2_000_000 / 1_048_576 ≈ 1.9 MB
        #expect(file.humanSize.hasSuffix("MB"))
    }

    @Test func iconNameFuerPDF() {
        let file = DroppedFile(fileName: "x.pdf", mimeType: "application/pdf", data: Data())
        #expect(file.iconName == "doc.richtext")
    }

    @Test func iconNameFuerBild() {
        let file = DroppedFile(fileName: "x.png", mimeType: "image/png", data: Data())
        #expect(file.iconName == "photo")
    }

    @Test func iconNameFuerText() {
        let file = DroppedFile(fileName: "x.txt", mimeType: "text/plain", data: Data())
        #expect(file.iconName == "doc.text")
    }

    @Test func iconNameFuerUnbekannt() {
        let file = DroppedFile(fileName: "x.zip", mimeType: "application/zip", data: Data())
        #expect(file.iconName == "doc")
    }

    // MARK: - DriveUploadOutcome Equatable

    @Test func uploadOutcomeEqualityUploaded() {
        let a = DriveUploadOutcome.uploaded(webLink: "https://drive.google.com/file/x")
        let b = DriveUploadOutcome.uploaded(webLink: "https://drive.google.com/file/x")
        #expect(a == b)
    }

    @Test func uploadOutcomeEqualityFailed() {
        let a = DriveUploadOutcome.failed("Fehler")
        let b = DriveUploadOutcome.failed("Fehler")
        #expect(a == b)
    }

    @Test func uploadOutcomeEqualityPermissionRequired() {
        #expect(DriveUploadOutcome.permissionRequired == DriveUploadOutcome.permissionRequired)
    }

    @Test func uploadOutcomeUnequal() {
        #expect(DriveUploadOutcome.permissionRequired != DriveUploadOutcome.failed("x"))
    }

    // MARK: - AuditEntry.Action driveFileUploaded

    @Test func auditActionEnthältDriveFileUploaded() {
        let action = AuditEntry.Action.driveFileUploaded
        // Roh-String muss mit dem Codable rawValue übereinstimmen
        #expect(action.rawValue == "driveFileUploaded")
    }

    @Test func auditEntryMitDriveUploadAktionIstKodierbar() throws {
        let entry = AuditEntry(
            actorUserID: "user1",
            projectID: "2026-001",
            action: .driveFileUploaded,
            summary: "Angebot.pdf → Ordner XYZ"
        )
        let encoded = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(AuditEntry.self, from: encoded)
        #expect(decoded.action == .driveFileUploaded)
        #expect(decoded.summary == "Angebot.pdf → Ordner XYZ")
    }
}
