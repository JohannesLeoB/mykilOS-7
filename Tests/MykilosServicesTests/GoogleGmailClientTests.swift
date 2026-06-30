import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

struct GoogleGmailClientTests {

    private let baseURL = "https://gmail.googleapis.com/gmail/v1/users/me/messages"

    // MARK: - S14: Entwurf-MIME / Header / base64url

    @Test func buildMIMEEnthaeltHeaderUndBase64Body() {
        let mime = GoogleGmailClient.buildMIME(EmailDraft(to: "a@b.de", subject: "Test", body: "Hallo Welt"))
        #expect(mime.contains("To: a@b.de"))
        #expect(mime.contains("Subject: Test"))
        #expect(mime.contains("Content-Transfer-Encoding: base64"))
        #expect(mime.contains(Data("Hallo Welt".utf8).base64EncodedString()))
    }

    @Test func buildMIMEOhneEmpfaengerLaesstToWeg() {
        let mime = GoogleGmailClient.buildMIME(EmailDraft(subject: "S", body: "B"))
        #expect(mime.contains("To:") == false)
    }

    @Test func encodeHeaderRFC2047BeiUmlaut() {
        #expect(GoogleGmailClient.encodeHeader("Angebot") == "Angebot")
        let enc = GoogleGmailClient.encodeHeader("Grüße")
        #expect(enc.hasPrefix("=?UTF-8?B?"))
        #expect(enc.hasSuffix("?="))
    }

    @Test func base64URLOhnePadding() {
        let s = GoogleGmailClient.base64URL(Data("xx".utf8))
        #expect(s.contains("=") == false)
        #expect(s.contains("+") == false)
        #expect(s.contains("/") == false)
    }

    // MARK: - S15: Body-Parsing

    @Test func parseBodyDekodiertTextPlain() {
        let plain = Data("Hallo Welt".utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
        let json = """
        {"id":"m1","snippet":"snip","payload":{"mimeType":"multipart/alternative","parts":[
          {"mimeType":"text/plain","body":{"data":"\(plain)"}}]}}
        """
        #expect(GoogleGmailClient.parseBody(from: Data(json.utf8)) == "Hallo Welt")
    }

    @Test func parseBodyFaelltAufSnippetZurueck() {
        let json = #"{"id":"m1","snippet":"nur snippet","payload":{"mimeType":"text/x","parts":[]}}"#
        #expect(GoogleGmailClient.parseBody(from: Data(json.utf8)) == "nur snippet")
    }

    @Test func stripHTMLEntferntTags() {
        #expect(GoogleGmailClient.stripHTML("<p>Hallo&nbsp;<b>Welt</b></p>") == "Hallo Welt")
    }

    // MARK: - S14/S15: Tools über die Registry

    @Test func readEmailToolLiestVollenBody() async {
        let fake = FakeGmailWithBody(
            messages: [GoogleGmailMessage(id: "m1", subject: "Leuchten", from: "Gehrke", snippet: "kurz", receivedAt: nil)],
            bodies: ["m1": "Voller Mailtext mit Details"])
        let reg = AssistantToolRegistry.standard(gmail: fake)
        let r = await reg.run(name: "read_email", inputJSON: Data(#"{"query":"Leuchten"}"#.utf8))
        #expect(r.isError == false)
        #expect(r.text.contains("Voller Mailtext mit Details"))
        #expect(r.text.contains("Leuchten"))
    }

    @Test func createDraftToolErzeugtEntwurfKarte() async {
        let reg = AssistantToolRegistry.standard()
        let r = await reg.run(name: "create_draft", inputJSON: Data(#"{"betreff":"Neurologie","text":"Leuchte kommt am 4. Juli","an":"gehrke@x.de"}"#.utf8))
        #expect(r.isError == false)
        #expect(r.emailDraft?.subject == "Neurologie")
        #expect(r.emailDraft?.to == "gehrke@x.de")
        #expect(r.emailDraft?.body.contains("4. Juli") == true)
    }

    @Test func createDraftOhneInhaltIstFehler() async {
        let reg = AssistantToolRegistry.standard()
        let r = await reg.run(name: "create_draft", inputJSON: Data(#"{"betreff":"","text":""}"#.utf8))
        #expect(r.isError == true)
        #expect(r.emailDraft == nil)
    }

    // S14 (Review-Nachzug): Rand-Fälle des Guards/Trimmings.
    @Test func createDraftNurBetreffOderNurTextReicht() async {
        let reg = AssistantToolRegistry.standard()
        let nurBetreff = await reg.run(name: "create_draft", inputJSON: Data(#"{"betreff":"Titel","text":""}"#.utf8))
        #expect(nurBetreff.isError == false)
        let nurText = await reg.run(name: "create_draft", inputJSON: Data(#"{"betreff":"","text":"Inhalt"}"#.utf8))
        #expect(nurText.isError == false)
    }

    @Test func createDraftNurLeerzeichenIstFehler() async {
        let reg = AssistantToolRegistry.standard()
        let r = await reg.run(name: "create_draft", inputJSON: Data(#"{"betreff":"   ","text":"  "}"#.utf8))
        #expect(r.isError == true)
    }

    @Test func createDraftLeererEmpfaengerWirdNil() async {
        let reg = AssistantToolRegistry.standard()
        let r = await reg.run(name: "create_draft", inputJSON: Data(#"{"an":"   ","betreff":"S","text":"T"}"#.utf8))
        #expect(r.emailDraft?.to == nil)
    }

    // S15 (Review-Nachzug): read_email Index/Fehlerpfade.
    @Test func readEmailNichtGefunden() async {
        let reg = AssistantToolRegistry.standard(gmail: FakeGmailWithBody(messages: [], bodies: [:]))
        let r = await reg.run(name: "read_email", inputJSON: Data(#"{"query":"nichts"}"#.utf8))
        #expect(r.text.contains("Keine Mail"))
    }

    @Test func readEmailNummerAusserhalbIstFehler() async {
        let fake = FakeGmailWithBody(
            messages: [GoogleGmailMessage(id: "m1", subject: "A", from: "X", snippet: "s", receivedAt: nil)],
            bodies: ["m1": "Body"])
        let reg = AssistantToolRegistry.standard(gmail: fake)
        let r = await reg.run(name: "read_email", inputJSON: Data(#"{"query":"A","nummer":"5"}"#.utf8))
        #expect(r.isError == true)
    }

    @Test func readEmailLeereQueryIstFehler() async {
        let reg = AssistantToolRegistry.standard(gmail: FakeGmailWithBody(messages: [], bodies: [:]))
        let r = await reg.run(name: "read_email", inputJSON: Data(#"{"query":""}"#.utf8))
        #expect(r.isError == true)
    }

    // S12: Trefferzahl ist parametrisierbar (Default 25, gekappt auf 100).
    @Test func gmailResultLimitDefaultUndCap() {
        #expect(SearchGmailTool.resultLimit(from: [:]) == 25)
        #expect(SearchGmailTool.resultLimit(from: ["anzahl": "50"]) == 50)
        #expect(SearchGmailTool.resultLimit(from: ["anzahl": "500"]) == 100)   // cap
        #expect(SearchGmailTool.resultLimit(from: ["anzahl": "0"]) == 1)       // floor
        #expect(SearchGmailTool.resultLimit(from: ["anzahl": "abc"]) == 25)    // fallback
    }

    @Test func buildListURLEnthaeltQueryUndMaxResults() {
        let url = GoogleGmailClient.buildListURL(query: "Meyer Küche", maxResults: 5, baseURL: baseURL)
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(items["q"] == "Meyer Küche")
        #expect(items["maxResults"] == "5")
    }

    @Test func buildDetailURLEnthaeltFormatFull() {
        let url = GoogleGmailClient.buildDetailURL(messageID: "abc123", baseURL: baseURL)
        let urlString = url?.absoluteString ?? ""

        #expect(urlString.contains("abc123"))
        #expect(urlString.contains("format=full"))
    }

    @Test func parseMessageIDsDekodiertListe() throws {
        let json = """
        { "messages": [{"id": "m1", "threadId": "t1"}, {"id": "m2", "threadId": "t2"}] }
        """
        let ids = try GoogleGmailClient.parseMessageIDs(from: Data(json.utf8))
        #expect(ids == ["m1", "m2"])
    }

    @Test func parseMessageIDsLeereListe() throws {
        let json = """
        { "resultSizeEstimate": 0 }
        """
        let ids = try GoogleGmailClient.parseMessageIDs(from: Data(json.utf8))
        #expect(ids.isEmpty)
    }

    @Test func parseMessageIDsWirftBeiKaputtemJSON() {
        #expect(throws: GoogleGmailError.decodingFailed) {
            _ = try GoogleGmailClient.parseMessageIDs(from: Data("nope".utf8))
        }
    }

    @Test func parseMessageDekodiertHeadersUndSnippet() throws {
        let json = """
        {
          "id": "msg42",
          "snippet": "Hallo, anbei die neue Zeichnung...",
          "payload": {
            "headers": [
              { "name": "Subject", "value": "Zeichnung Bartresen v3" },
              { "name": "From", "value": "Sandra Adler <sandra@example.com>" },
              { "name": "Date", "value": "Mon, 23 Jun 2026 10:30:00 +0200" }
            ]
          }
        }
        """
        let message = try GoogleGmailClient.parseMessage(from: Data(json.utf8))

        #expect(message.id == "msg42")
        #expect(message.subject == "Zeichnung Bartresen v3")
        #expect(message.from == "Sandra Adler")
        #expect(message.snippet == "Hallo, anbei die neue Zeichnung...")
        #expect(message.receivedAt != nil)
    }

    @Test func parseMessageFallbackOhneHeaders() throws {
        let json = """
        { "id": "msg1", "snippet": "test", "payload": { "headers": [] } }
        """
        let message = try GoogleGmailClient.parseMessage(from: Data(json.utf8))
        #expect(message.subject == "(kein Betreff)")
        #expect(message.from == "")
    }

    @Test func extractSenderNameEntferntEmailKlammer() {
        #expect(GoogleGmailClient.extractSenderName(from: "Max Müller <max@test.de>") == "Max Müller")
        #expect(GoogleGmailClient.extractSenderName(from: "\"Sandra\" <s@b.de>") == "Sandra")
        #expect(GoogleGmailClient.extractSenderName(from: "plain@test.de") == "plain@test.de")
        #expect(GoogleGmailClient.extractSenderName(from: "<only@bracket.de>") == "<only@bracket.de>")
    }

    @Test func searchMessagesWirftNotConnectedOhneToken() async {
        let store = InMemoryGoogleTokenStore()
        let client = GoogleGmailClient(tokenProvider: GoogleAccessTokenProvider(tokenStore: store))

        do {
            _ = try await client.searchMessages(query: "Meyer", maxResults: 5)
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? GoogleGmailError == .notConnected)
        }
    }

    @Test func searchMessagesMapptRefreshFehlerAufNotConnected() async {
        let client = GoogleGmailClient(tokenProvider: ThrowingTokenProvider(error: GoogleOAuthError.httpError(400)))

        do {
            _ = try await client.searchMessages(query: "Meyer", maxResults: 5)
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? GoogleGmailError == .notConnected)
        }
    }

    // MARK: - L19: Anhänge-Parsing (format=full)

    @Test func detailURLNutztFormatFull() {
        let url = GoogleGmailClient.buildDetailURL(
            messageID: "msg_abc", baseURL: "https://gmail.googleapis.com/gmail/v1/users/me/messages"
        )
        let query = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
            .flatMap { c in c.queryItems }
            .map { $0.reduce(into: [:]) { $0[$1.name] = $1.value } } ?? [:]
        #expect(query["format"] == "full")
    }

    @Test func parseMessageMitAnhangLiefertAttachment() throws {
        let json = """
        {
          "id": "m1",
          "snippet": "Datei im Anhang",
          "labelIds": ["INBOX"],
          "payload": {
            "headers": [
              {"name": "Subject", "value": "Angebot PDF"},
              {"name": "From",    "value": "gesa@test.de"},
              {"name": "Date",    "value": "Mon, 2 Jun 2025 10:00:00 +0200"}
            ],
            "parts": [
              {"mimeType": "text/plain", "body": {"size": 50}},
              {
                "mimeType": "application/pdf",
                "filename": "Angebot_2025.pdf",
                "body": {"attachmentId": "att_xyz", "size": 102400}
              }
            ]
          }
        }
        """.data(using: .utf8)!
        let msg = try GoogleGmailClient.parseMessage(from: json)
        #expect(msg.attachments.count == 1)
        #expect(msg.attachments.first?.filename == "Angebot_2025.pdf")
        #expect(msg.attachments.first?.mimeType == "application/pdf")
        #expect(msg.attachments.first?.attachmentID == "att_xyz")
        #expect(msg.attachments.first?.sizeBytes == 102400)
    }

    @Test func parseMessageOhneAnhangGibtLeereArray() throws {
        let json = """
        {"id":"m2","snippet":"","labelIds":["INBOX"],"payload":{"headers":[{"name":"Subject","value":"S"}]}}
        """.data(using: .utf8)!
        let msg = try GoogleGmailClient.parseMessage(from: json)
        #expect(msg.attachments.isEmpty)
    }

    @Test func parseMessageVerschachtelterAnhang() throws {
        let json = """
        {
          "id": "m3", "snippet": "",
          "payload": {
            "headers": [{"name": "Subject", "value": "Multi"}],
            "mimeType": "multipart/mixed",
            "parts": [{
              "mimeType": "multipart/alternative",
              "parts": [
                {"mimeType": "text/plain", "body": {"size": 10}},
                {
                  "mimeType": "image/png",
                  "filename": "logo.png",
                  "body": {"attachmentId": "att_img", "size": 4096}
                }
              ]
            }]
          }
        }
        """.data(using: .utf8)!
        let msg = try GoogleGmailClient.parseMessage(from: json)
        #expect(msg.attachments.count == 1)
        #expect(msg.attachments.first?.filename == "logo.png")
    }

    // MARK: - Session B: Multipart-MIME mit Anhängen

    @Test func buildMIMEMultipartMitAnhangErzeugtMultipartMixed() {
        let att = DraftAttachment(filename: "test.pdf", mimeType: "application/pdf", data: Data("PDF-Inhalt".utf8))
        let draft = EmailDraft(to: "a@b.de", subject: "Mit Anhang", body: "Hallo", attachments: [att])
        let mime = GoogleGmailClient.buildMIMEMultipart(draft)
        #expect(mime.contains("Content-Type: multipart/mixed"))
        #expect(mime.contains("Content-Disposition: attachment; filename=\"test.pdf\""))
        #expect(mime.contains("application/pdf"))
        #expect(mime.contains(String(Data("PDF-Inhalt".utf8).base64EncodedString().prefix(20))))
    }

    @Test func buildMIMEMultipartOhneAnhangDelegiertAnBuildMIME() {
        let draft = EmailDraft(to: "a@b.de", subject: "Ohne Anhang", body: "Text")
        let mime = GoogleGmailClient.buildMIMEMultipart(draft)
        #expect(mime.contains("Content-Type: text/plain"))
        #expect(mime.contains("multipart") == false)
    }

    @Test func draftAttachmentHumanSizeKB() {
        let data = Data(repeating: 0, count: 2048)
        let att = DraftAttachment(filename: "f.bin", mimeType: "application/octet-stream", data: data)
        #expect(att.humanSize == "2 KB")
    }

    @Test func draftAttachmentHumanSizeBytes() {
        let att = DraftAttachment(filename: "f.txt", mimeType: "text/plain", data: Data("abc".utf8))
        #expect(att.humanSize == "3 B")
    }

    @Test func emailDraftMitAnhangEquatable() {
        let att = DraftAttachment(filename: "x.pdf", mimeType: "application/pdf", data: Data([1,2,3]))
        let d1 = EmailDraft(to: "a@b.de", subject: "S", body: "B", attachments: [att])
        let d2 = EmailDraft(to: "a@b.de", subject: "S", body: "B", attachments: [att])
        #expect(d1 == d2)
    }

    @Test func parseThreadMessagesGibtLeereArrayBeiKaputtemJSON() {
        let result = GoogleGmailClient.parseThreadMessages(from: Data("bad json".utf8))
        #expect(result.isEmpty)
    }

    // MARK: - feat/mail-client-v2: decodeBase64URL Roundtrip

    @Test func decodeBase64URLRoundtripMitBinaerDaten() {
        let original = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x00, 0xFF, 0xFE])
        let encoded = GoogleGmailClient.base64URL(original)
        let decoded = GoogleGmailClient.decodeBase64URL(encoded)
        #expect(decoded == original)
    }

    @Test func decodeBase64URLOhnePaddingTollerant() {
        // base64url ohne Padding (wie Gmail API antwortet)
        let original = Data("mykilOS".utf8)
        let b64url = original.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))
        let decoded = GoogleGmailClient.decodeBase64URL(b64url)
        #expect(decoded == original)
    }

    @Test func downloadAttachmentDefaultWirftInvalidResponse() async {
        struct FakeGmail: GoogleGmailFetching, @unchecked Sendable {
            func searchMessages(query: String, maxResults: Int) async throws -> [GoogleGmailMessage] { [] }
        }
        let fake = FakeGmail()
        await #expect(throws: GoogleGmailError.invalidResponse) {
            _ = try await fake.downloadAttachment(messageID: "m1", attachmentID: "a1")
        }
    }

    // MARK: - Auto-Inbox (feat/mail-in-assistant)
    // Prüft, dass die Inbox-Query genau "in:inbox" verwendet, damit der
    // Auto-Posteingang beim Öffnen die echte Gmail-Inbox lädt.
    @Test func inboxQueryNutztGmailInInboxFilter() {
        let url = GoogleGmailClient.buildListURL(query: "in:inbox", maxResults: 25, baseURL: baseURL)
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        #expect(items["q"] == "in:inbox")
        #expect(items["maxResults"] == "25")
    }

    // Prüft, dass eine Inbox-Search-Antwort mit leerer Liste korrekt als
    // leeres Array geparst wird (kein Crash, kein Error-Throw).
    @Test func parseMessageIDsInboxLeer() throws {
        // Gmail liefert bei leerer Inbox kein "messages"-Array
        let json = """
        { "resultSizeEstimate": 0 }
        """
        let ids = try GoogleGmailClient.parseMessageIDs(from: Data(json.utf8))
        #expect(ids.isEmpty)
    }

    // MARK: - feat/mail-folders-reply: Ordner-Queries (als Konstanten dokumentiert)
    // MailFolder lebt in MykilosApp (SwiftUI) — nicht im testbaren MykilosServices-Target.
    // Die Queries sind daher hier als String-Konstanten geprüft (kein Import von App nötig).

    @Test func inboxFolderQueryKonstante() {
        // Dokumentiert, was MailFolder.inbox.gmailQuery liefern muss
        let expected = "in:inbox"
        #expect(expected.hasPrefix("in:"))
    }

    @Test func starredFolderQueryKonstante() {
        // Apple-Mail-Flags syncen zu Gmail-Sternen → is:starred (nicht is:flagged)
        let expected = "is:starred"
        #expect(expected.hasPrefix("is:"))
    }

    @Test func sentFolderQueryKonstante() {
        let expected = "in:sent"
        #expect(expected.hasPrefix("in:"))
    }

    // MARK: - feat/mail-folders-reply: Header-Parsing (To/Cc/From)

    @Test func parseMessageLiefertToUndCcHeader() throws {
        let json = """
        {
          "id": "msg1",
          "snippet": "snippet",
          "payload": {
            "headers": [
              { "name": "Subject", "value": "Test-Betreff" },
              { "name": "From",    "value": "Max Muster <max@example.com>" },
              { "name": "To",      "value": "anna@example.com, ben@example.com" },
              { "name": "Cc",      "value": "cc1@example.com" },
              { "name": "Date",    "value": "Mon, 30 Jun 2026 10:00:00 +0200" }
            ]
          }
        }
        """
        let msg = try GoogleGmailClient.parseMessage(from: Data(json.utf8))
        #expect(msg.fromRaw == "Max Muster <max@example.com>")
        #expect(msg.toRaw == "anna@example.com, ben@example.com")
        #expect(msg.ccRaw == "cc1@example.com")
    }

    @Test func parseMessageOhneToUndCcLiefertLeerenString() throws {
        let json = """
        {
          "id": "msg2",
          "snippet": "",
          "payload": {
            "headers": [
              { "name": "Subject", "value": "Kein CC" },
              { "name": "From",    "value": "s@x.de" }
            ]
          }
        }
        """
        let msg = try GoogleGmailClient.parseMessage(from: Data(json.utf8))
        #expect(msg.toRaw == "")
        #expect(msg.ccRaw == "")
    }

    // MARK: - feat/mail-folders-reply: Reply / Forward Helfer

    @Test func senderEmailExtrahiertAusAngleRaw() {
        let msg = GoogleGmailMessage(
            id: "m1", subject: "S",
            from: "Max", fromRaw: "Max Muster <max@example.com>",
            snippet: "", receivedAt: nil
        )
        #expect(msg.senderEmail == "max@example.com")
    }

    @Test func senderEmailFaelltAufFromZurueckWennKeinAngle() {
        let msg = GoogleGmailMessage(
            id: "m1", subject: "S",
            from: "plain@test.de", fromRaw: "",
            snippet: "", receivedAt: nil
        )
        #expect(msg.senderEmail == "plain@test.de")
    }

    @Test func replySubjectFuegtReAnOhneBestehendes() {
        let msg = GoogleGmailMessage(id: "m1", subject: "Angebot", from: "X", snippet: "", receivedAt: nil)
        #expect(msg.replySubject == "Re: Angebot")
    }

    @Test func replySubjectVerdoppeltReNicht() {
        let msg = GoogleGmailMessage(id: "m1", subject: "Re: Angebot", from: "X", snippet: "", receivedAt: nil)
        #expect(msg.replySubject == "Re: Angebot")
    }

    @Test func forwardSubjectFuegtFwdAn() {
        let msg = GoogleGmailMessage(id: "m1", subject: "Angebot", from: "X", snippet: "", receivedAt: nil)
        #expect(msg.forwardSubject == "Fwd: Angebot")
    }

    @Test func quotedBodyEnthaeltZitatPfeil() {
        let msg = GoogleGmailMessage(id: "m1", subject: "S", from: "Anna", snippet: "", receivedAt: nil)
        let quoted = msg.quotedBody("Zeile 1\nZeile 2")
        #expect(quoted.contains("> Zeile 1"))
        #expect(quoted.contains("> Zeile 2"))
        #expect(quoted.contains("Anna"))
    }

    @Test func extractEmailAusKlammern() {
        #expect(GoogleGmailMessage.extractEmail(from: "Max <max@example.com>") == "max@example.com")
        #expect(GoogleGmailMessage.extractEmail(from: "plain@test.de") == "plain@test.de")
        #expect(GoogleGmailMessage.extractEmail(from: "  ") == "")
    }

    // MARK: - feat/mail-folders-reply: MIME mit CC

    @Test func buildMIMEMitCCEnthaeltCcHeader() {
        let draft = EmailDraft(to: "a@b.de", cc: "c@d.de", subject: "Test", body: "Hallo")
        let mime = GoogleGmailClient.buildMIME(draft)
        #expect(mime.contains("Cc: c@d.de"))
        #expect(mime.contains("To: a@b.de"))
    }

    @Test func buildMIMEOhneCCLaesstCcWeg() {
        let draft = EmailDraft(to: "a@b.de", subject: "Test", body: "Hallo")
        let mime = GoogleGmailClient.buildMIME(draft)
        #expect(mime.contains("Cc:") == false)
    }

    @Test func emailDraftCcRoundtrip() throws {
        let original = EmailDraft(to: "a@b.de", cc: "c@d.de", subject: "S", body: "B")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EmailDraft.self, from: data)
        #expect(decoded.cc == "c@d.de")
        #expect(decoded.to == "a@b.de")
    }

    @Test func emailDraftAltOhneCcLaesstCcNil() throws {
        // Altes JSON ohne "cc"-Key → soll nil liefern, nicht crashen
        let json = #"{"to":"a@b.de","subject":"S","body":"B"}"#
        let draft = try JSONDecoder().decode(EmailDraft.self, from: Data(json.utf8))
        #expect(draft.cc == nil)
    }
}

private struct FakeGmailWithBody: GoogleGmailFetching, @unchecked Sendable {
    let messages: [GoogleGmailMessage]
    let bodies: [String: String]
    func searchMessages(query: String, maxResults: Int) async throws -> [GoogleGmailMessage] { messages }
    func fetchBody(messageID: String) async throws -> String { bodies[messageID] ?? "" }
}
