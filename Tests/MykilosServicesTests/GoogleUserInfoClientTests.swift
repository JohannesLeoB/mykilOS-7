import Testing
import Foundation
@testable import MykilosServices
import MykilosKit

// MARK: - FakeGoogleHTTPClient
// Test-Double — kein echtes Netzwerk im automatisierten Testlauf.
private final class FakeGoogleHTTPClient: GoogleHTTPClient, @unchecked Sendable {
    var stubbedData: Data
    var stubbedStatusCode: Int

    init(data: Data, statusCode: Int = 200) {
        self.stubbedData = data
        self.stubbedStatusCode = statusCode
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: stubbedStatusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (stubbedData, response)
    }
}

// MARK: - GoogleUserInfoClientTests
struct GoogleUserInfoClientTests {

    @Test func buildRequestSetztAuthorizationHeader() {
        let url = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!
        let request = GoogleUserInfoClient.buildRequest(url: url, accessToken: "ya29.test-token")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer ya29.test-token")
        #expect(request.url == url)
    }

    @Test func parseUserInfoLiefertEmailUndName() throws {
        let json = #"{"email":"johannes@mykilos.com","name":"Johannes Leo Berger"}"#.data(using: .utf8)!
        let info = try GoogleUserInfoClient.parseUserInfo(from: json)
        #expect(info.email == "johannes@mykilos.com")
        #expect(info.displayName == "Johannes Leo Berger")
    }

    @Test func parseUserInfoFaelltAufEmailZurueckWennKeinName() throws {
        let json = #"{"email":"johannes@mykilos.com"}"#.data(using: .utf8)!
        let info = try GoogleUserInfoClient.parseUserInfo(from: json)
        #expect(info.email == "johannes@mykilos.com")
        #expect(info.displayName == "johannes@mykilos.com")
    }

    @Test func parseUserInfoFaelltAufEmailZurueckBeiLeeremName() throws {
        let json = #"{"email":"test@example.com","name":"   "}"#.data(using: .utf8)!
        let info = try GoogleUserInfoClient.parseUserInfo(from: json)
        #expect(info.displayName == "test@example.com")
    }

    @Test func parseUserInfoWirftBeiKaputtemJSON() {
        let data = #"{"not_email":true}"#.data(using: .utf8)!
        #expect(throws: GoogleOAuthError.decodingFailed) {
            try GoogleUserInfoClient.parseUserInfo(from: data)
        }
    }

    @Test func fetchUserInfoLiefertGeparsteIdentitaet() async throws {
        let json = #"{"email":"j@mykilos.com","name":"Johannes"}"#.data(using: .utf8)!
        let fake = FakeGoogleHTTPClient(data: json, statusCode: 200)
        let client = GoogleUserInfoClient(
            httpClient: fake,
            userInfoURL: URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!
        )
        let info = try await client.fetchUserInfo(accessToken: "token")
        #expect(info.email == "j@mykilos.com")
        #expect(info.displayName == "Johannes")
    }

    @Test func fetchUserInfoWirftBeiHTTPFehler() async {
        let fake = FakeGoogleHTTPClient(data: Data(), statusCode: 401)
        let client = GoogleUserInfoClient(
            httpClient: fake,
            userInfoURL: URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!
        )
        await #expect(throws: GoogleOAuthError.httpError(401)) {
            try await client.fetchUserInfo(accessToken: "bad-token")
        }
    }
}
