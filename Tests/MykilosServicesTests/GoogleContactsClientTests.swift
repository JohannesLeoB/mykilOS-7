import Testing
import Foundation
@testable import MykilosServices

struct GoogleContactsClientTests {

    private let baseURL = "https://people.googleapis.com/v1/people:searchContacts"

    @Test func urlEnthaeltQueryUndReadMask() {
        let url = GoogleContactsClient.buildSearchURL(query: "Meyer", baseURL: baseURL)
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(items["query"] == "Meyer")
        #expect(items["readMask"] == "names,emailAddresses,phoneNumbers,organizations")
    }

    @Test func parseContactsDekodiertResultsPersonStruktur() throws {
        let json = """
        {
          "results": [
            {
              "person": {
                "resourceName": "people/c1",
                "names": [ { "displayName": "Familie Meyer" } ],
                "emailAddresses": [ { "value": "meyer@example.com" } ],
                "phoneNumbers": [ { "value": "+49 123 456" } ],
                "organizations": [ { "name": "Meyer GmbH" } ]
              }
            },
            {
              "person": {
                "resourceName": "people/c2",
                "names": [ { "displayName": "Sandra Adler" } ]
              }
            }
          ]
        }
        """
        let contacts = try GoogleContactsClient.parseContacts(from: Data(json.utf8))

        #expect(contacts.count == 2)
        #expect(contacts[0].displayName == "Familie Meyer")
        #expect(contacts[0].email == "meyer@example.com")
        #expect(contacts[0].phone == "+49 123 456")
        #expect(contacts[0].organization == "Meyer GmbH")
        #expect(contacts[1].displayName == "Sandra Adler")
        #expect(contacts[1].email == nil)
        #expect(contacts[1].phone == nil)
        #expect(contacts[1].organization == nil)
    }

    @Test func parseContactsWirftBeiKaputtemJSON() {
        #expect(throws: GoogleContactsError.decodingFailed) {
            _ = try GoogleContactsClient.parseContacts(from: Data("nicht json".utf8))
        }
    }

    @Test func searchContactsWirftNotConnectedOhneToken() async {
        let store = InMemoryGoogleTokenStore()
        let client = GoogleContactsClient(tokenProvider: GoogleAccessTokenProvider(tokenStore: store))

        do {
            _ = try await client.searchContacts(query: "Meyer")
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? GoogleContactsError == .notConnected)
        }
    }
}
