import Testing
import Foundation
import MykilosKit
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

    // S8: Warmup-URL hat leere Query + denselben readMask (People-API Index-Warmup).
    @Test func warmupURLHatLeereQuery() {
        let url = GoogleContactsClient.buildWarmupURL(baseURL: baseURL)
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(items["query"] == "")
        #expect(items["readMask"] == "names,emailAddresses,phoneNumbers,organizations")
    }

    // S8: Projekt-Tokens mit Unterstrich werden zu Leerzeichen, Whitespace kollabiert.
    @Test func normalizedQuerySaeubertUnterstriche() {
        #expect(GoogleContactsClient.normalizedQuery("Fuckner_Huetter") == "Fuckner Huetter")
        #expect(GoogleContactsClient.normalizedQuery("  Meyer  ") == "Meyer")
        #expect(GoogleContactsClient.normalizedQuery("a__b") == "a b")
        #expect(GoogleContactsClient.normalizedQuery(nil) == "")
        #expect(GoogleContactsClient.normalizedQuery("   ") == "")
    }

    // S19: Verzeichnis-Suche — URL hat query, readMask, beide sources, pageSize.
    @Test func directoryURLEnthaeltSourcesUndReadMask() {
        let url = GoogleContactsClient.buildDirectoryURL(query: "Weck", baseURL: "https://people.googleapis.com/v1/people:searchDirectoryPeople")
        let comps = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = comps?.queryItems ?? []
        #expect(items.first { $0.name == "query" }?.value == "Weck")
        #expect(items.first { $0.name == "readMask" }?.value == "names,emailAddresses,phoneNumbers,organizations")
        let sources = items.filter { $0.name == "sources" }.compactMap(\.value)
        #expect(sources.contains("DIRECTORY_SOURCE_TYPE_DOMAIN_PROFILE"))
        #expect(sources.contains("DIRECTORY_SOURCE_TYPE_DOMAIN_CONTACT"))
        #expect(items.first { $0.name == "pageSize" }?.value == "30")
    }

    // S19: searchDirectoryPeople-Antwort (people: [...]) wird korrekt dekodiert.
    @Test func parseDirectoryDekodiertPeople() throws {
        let json = """
        {"people":[
          {"resourceName":"people/c1","names":[{"displayName":"Mario Weck"}],
           "emailAddresses":[{"value":"m.weck@mykilos.com"}],"organizations":[{"name":"MYKILOS"}]},
          {"resourceName":"people/c2","names":[{"displayName":"Jilliana"}]}
        ]}
        """
        let contacts = try GoogleContactsClient.parseDirectory(from: Data(json.utf8))
        #expect(contacts.count == 2)
        #expect(contacts.first?.displayName == "Mario Weck")
        #expect(contacts.first?.email == "m.weck@mykilos.com")
        #expect(contacts.first?.organization == "MYKILOS")
    }

    @Test func parseDirectoryLeerOhnePeople() throws {
        #expect(try GoogleContactsClient.parseDirectory(from: Data("{}".utf8)).isEmpty)
    }

    // S9: createContact-Body enthält nur gesetzte Felder im People-Person-Format.
    @Test func createBodyEnthaeltNurGesetzteFelder() throws {
        let draft = ContactDraft(givenName: "Sinem", familyName: "Cirnavuk",
                                 email: "s@example.com", phone: nil, organization: "MYKILOS")
        let data = try GoogleContactsClient.buildCreateBody(draft)
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let names = obj["names"] as! [[String: String]]
        #expect(names.first?["givenName"] == "Sinem")
        #expect(names.first?["familyName"] == "Cirnavuk")
        #expect((obj["emailAddresses"] as? [[String: String]])?.first?["value"] == "s@example.com")
        #expect((obj["organizations"] as? [[String: String]])?.first?["name"] == "MYKILOS")
        #expect(obj["phoneNumbers"] == nil)   // nicht gesetzt → kein leeres Array
    }

    @Test func createBodyNurVorname() throws {
        let data = try GoogleContactsClient.buildCreateBody(ContactDraft(givenName: "Heinz"))
        let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect((obj["names"] as! [[String: String]]).first?["givenName"] == "Heinz")
        #expect(obj["emailAddresses"] == nil)
        #expect(obj["phoneNumbers"] == nil)
        #expect(obj["organizations"] == nil)
    }

    // S9: parsePerson dekodiert die createContact-Antwort.
    @Test func parsePersonDekodiertAntwort() throws {
        let json = """
        {"resourceName":"people/c123","names":[{"displayName":"Sinem Cirnavuk","givenName":"Sinem"}],
         "emailAddresses":[{"value":"s@example.com"}],"organizations":[{"name":"MYKILOS"}]}
        """
        let c = try GoogleContactsClient.parsePerson(from: Data(json.utf8))
        #expect(c.id == "people/c123")
        #expect(c.displayName == "Sinem Cirnavuk")
        #expect(c.email == "s@example.com")
        #expect(c.organization == "MYKILOS")
    }

    // S9: ContactDraft.displayName setzt Vor-/Nachname sauber zusammen.
    @Test func draftDisplayName() {
        #expect(ContactDraft(givenName: "Sinem", familyName: "Cirnavuk").displayName == "Sinem Cirnavuk")
        #expect(ContactDraft(givenName: "Heinz").displayName == "Heinz")
    }

    // S9 (Review-Nachzug): create_contact-Tool über die Registry — Entwurf, kein Auto-Write.
    @Test func createContactToolErzeugtEntwurf() async {
        let reg = AssistantToolRegistry.standard()
        let r = await reg.run(name: "create_contact", inputJSON: Data(#"{"vorname":"Sinem","nachname":"Cirnavuk","email":"s@x.de","telefon":"0175","firma":"MYKILOS"}"#.utf8))
        #expect(r.isError == false)
        #expect(r.contactDraft?.givenName == "Sinem")
        #expect(r.contactDraft?.familyName == "Cirnavuk")
        #expect(r.contactDraft?.email == "s@x.de")
        #expect(r.contactDraft?.organization == "MYKILOS")
    }

    @Test func createContactNurVornameReicht() async {
        let reg = AssistantToolRegistry.standard()
        let r = await reg.run(name: "create_contact", inputJSON: Data(#"{"vorname":"Heinz"}"#.utf8))
        #expect(r.isError == false)
        #expect(r.contactDraft?.givenName == "Heinz")
        #expect(r.contactDraft?.email == nil)
    }

    @Test func createContactOhneNamenIstFehler() async {
        let reg = AssistantToolRegistry.standard()
        let r = await reg.run(name: "create_contact", inputJSON: Data(#"{"vorname":"   ","email":"x@y.de"}"#.utf8))
        #expect(r.isError == true)
        #expect(r.contactDraft == nil)
    }

    @Test func createContactTrimmtLeereOptionaleFelderAufNil() async {
        let reg = AssistantToolRegistry.standard()
        let r = await reg.run(name: "create_contact", inputJSON: Data(#"{"vorname":"A","telefon":"  ","firma":""}"#.utf8))
        #expect(r.contactDraft?.phone == nil)
        #expect(r.contactDraft?.organization == nil)
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

    @Test func searchContactsMapptRefreshFehlerAufNotConnected() async {
        let client = GoogleContactsClient(tokenProvider: ThrowingTokenProvider(error: GoogleOAuthError.httpError(400)))

        do {
            _ = try await client.searchContacts(query: "Meyer")
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? GoogleContactsError == .notConnected)
        }
    }

    // MARK: - listAllContacts (Google→Airtable-Import, 2026-07-04)

    @Test func connectionsURLOhnePageTokenBeimErstenAufruf() {
        let url = GoogleContactsClient.buildConnectionsURL(
            baseURL: "https://people.googleapis.com/v1/people/me/connections", pageToken: nil)
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        #expect(items["personFields"] == "names,emailAddresses,phoneNumbers,organizations")
        #expect(items["pageSize"] == "200")
        #expect(items["pageToken"] == nil)
    }

    @Test func connectionsURLTraegtPageTokenWeiter() {
        let url = GoogleContactsClient.buildConnectionsURL(
            baseURL: "https://people.googleapis.com/v1/people/me/connections", pageToken: "abc123")
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        #expect(items["pageToken"] == "abc123")
    }

    @Test func parseConnectionsPageDekodiertUndLiefertNextPageToken() throws {
        let json = """
        {
          "connections": [
            { "resourceName": "people/1", "names": [{ "displayName": "Anna Meyer" }],
              "emailAddresses": [{ "value": "anna@example.com" }] }
          ],
          "nextPageToken": "next1"
        }
        """
        let page = try GoogleContactsClient.parseConnectionsPage(from: Data(json.utf8))
        #expect(page.contacts.count == 1)
        #expect(page.contacts[0].displayName == "Anna Meyer")
        #expect(page.nextPageToken == "next1")
    }

    @Test func parseConnectionsPageLetzteSeiteHatKeinNextPageToken() throws {
        let json = """
        { "connections": [ { "resourceName": "people/2", "names": [{ "displayName": "Bert Weck" }] } ] }
        """
        let page = try GoogleContactsClient.parseConnectionsPage(from: Data(json.utf8))
        #expect(page.contacts.count == 1)
        #expect(page.nextPageToken == nil)
    }

    @Test func listAllContactsWirftNotConnectedOhneToken() async {
        let client = GoogleContactsClient(tokenProvider: ThrowingTokenProvider(error: GoogleOAuthError.httpError(400)))
        do {
            _ = try await client.listAllContacts()
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? GoogleContactsError == .notConnected)
        }
    }
}
