import Testing
import Foundation
@testable import MykilosServices

struct GoogleGmailClientTests {

    private let baseURL = "https://gmail.googleapis.com/gmail/v1/users/me/messages"

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
}
