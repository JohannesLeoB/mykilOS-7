import Testing
import Foundation
@testable import MykilosKit

// MARK: - EmailDraft Rückwärtskompatibilität
// Regressionstest für den Bug, der das Chat-Archiv „verschwinden" ließ:
// Session B fügte EmailDraft.attachments (nicht-optional) hinzu. Ein im Chat
// persistierter draftAction-Block aus der Zeit DAVOR hatte den Key nicht — der
// synthetisierte Decoder warf keyNotFound, was beim Laden den GESAMTEN Scope
// (alle Nachrichten) mitriss. Diese Tests sperren das ein.
struct EmailDraftBackwardCompatTests {

    @Test func altesJSONOhneAttachmentsDekodiert() throws {
        // Exakt das Format, das im echten Archiv lag (nur subject + body).
        let alt = #"{"subject":"RE: Lieferadresse","body":"Hallo, …"}"#.data(using: .utf8)!
        let draft = try JSONDecoder().decode(EmailDraft.self, from: alt)
        #expect(draft.subject == "RE: Lieferadresse")
        #expect(draft.body == "Hallo, …")
        #expect(draft.attachments.isEmpty)   // fehlender Key → [], NICHT keyNotFound
        #expect(draft.to == nil)
    }

    @Test func alterDraftActionBlockDekodiert() throws {
        // Ein ganzer ChatContentBlock wie im Archiv — ohne attachments im draft.
        let alt = #"{"draftAction":{"draft":{"subject":"X","body":"Y"}}}"#.data(using: .utf8)!
        let block = try JSONDecoder().decode(ChatContentBlock.self, from: alt)
        guard case let .draftAction(draft) = block else {
            Issue.record("Erwartete .draftAction, bekam \(block)"); return
        }
        #expect(draft.subject == "X")
        #expect(draft.attachments.isEmpty)
    }

    @Test func roundtripMitAnhangBleibtErhalten() throws {
        let original = EmailDraft(
            to: "a@b.de", subject: "S", body: "B",
            attachments: [DraftAttachment(filename: "f.pdf", mimeType: "application/pdf", data: Data([1, 2, 3]))]
        )
        let data = try JSONEncoder().encode(original)
        let back = try JSONDecoder().decode(EmailDraft.self, from: data)
        #expect(back == original)
        #expect(back.attachments.count == 1)
    }
}
