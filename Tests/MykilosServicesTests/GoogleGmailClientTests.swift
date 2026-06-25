import Testing
import Foundation
@testable import MykilosServices

struct GoogleGmailClientTests {

    private let baseURL = "https://gmail.googleapis.com/gmail/v1/users/me/messages"

    @Test func buildListURLEnthaeltQueryUndMaxResults() {
        let url = GoogleGmailClient.buildListURL(query: "Meyer Küche", maxResults: 5, baseURL: baseURL)
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(items["q"] == "Meyer Küche")
        #expect(items["maxResults"] == "5")
    }

    @Test func buildDetailURLEnthaeltFormatUndMetadataHeaders() {
        let url = GoogleGmailClient.buildDetailURL(messageID: "abc123", baseURL: baseURL)
        let urlString = url?.absoluteString ?? ""

        #expect(urlString.contains("abc123"))
        #expect(urlString.contains("format=metadata"))
        #expect(urlString.contains("metadataHeaders"))
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
}
