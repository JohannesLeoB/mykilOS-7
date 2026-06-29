import Testing
@testable import MykilosServices

// MARK: - S3: DocumentViewerMode-Klassifizierung

struct DocumentViewerModeTests {
    @Test func klassifiziertNachMimeTyp() {
        #expect(DocumentViewerMode.classify(mimeType: "application/pdf") == .pdf)
        #expect(DocumentViewerMode.classify(mimeType: "image/png") == .image)
        #expect(DocumentViewerMode.classify(mimeType: "image/jpeg") == .image)
        #expect(DocumentViewerMode.classify(mimeType: "application/vnd.google-apps.document") == .browserOnly)
        #expect(DocumentViewerMode.classify(mimeType: "application/vnd.google-apps.spreadsheet") == .browserOnly)
        #expect(DocumentViewerMode.classify(mimeType: "text/plain") == .quicklook)
        #expect(DocumentViewerMode.classify(mimeType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document") == .quicklook)
        #expect(DocumentViewerMode.classify(mimeType: "") == .quicklook)
    }
}
