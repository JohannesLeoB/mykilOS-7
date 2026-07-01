import Testing
import Foundation
@testable import MykilosServices

struct ClockodoClientTests {

    @Test func buildEntriesURLEnthaeltTimeSinceUndTimeUntil() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let url = ClockodoClient.buildEntriesURL(
            baseURL: "https://my.clockodo.com/api/v2/entries",
            now: now
        )
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(items["time_since"] != nil)
        #expect(items["time_until"] != nil)
    }

    @Test func parseEntriesDekodiertProjektUndDauer() throws {
        let json = """
        {
          "entries": [
            { "id": 1, "customers_name": "Kunde A", "projects_name": "Projekt X", "duration": 3600 },
            { "id": 2, "customers_name": "Kunde B", "projects_name": null, "duration": 1800 }
          ]
        }
        """
        let entries = try ClockodoClient.parseEntries(from: Data(json.utf8))

        #expect(entries.count == 2)
        #expect(entries[0].label == "Projekt X")
        #expect(entries[0].durationSeconds == 3600)
        #expect(entries[1].label == "Kunde B")
        #expect(entries[1].durationSeconds == 1800)
    }

    @Test func parseEntriesFallbackOhneProjektOhneKunde() throws {
        let json = """
        { "entries": [{ "id": 1, "customers_name": null, "projects_name": null, "duration": 900 }] }
        """
        let entries = try ClockodoClient.parseEntries(from: Data(json.utf8))
        #expect(entries[0].label == "(ohne Projekt)")
    }

    @Test func parseEntriesWirftBeiKaputtemJSON() {
        #expect(throws: ClockodoError.decodingFailed) {
            _ = try ClockodoClient.parseEntries(from: Data("nope".utf8))
        }
    }

    @Test func todaysEntriesWirftNotConnectedOhneCredentials() async {
        let store = InMemoryClockodoCredentialsStore()
        let client = ClockodoClient(credentialsStore: store)

        do {
            _ = try await client.todaysEntries()
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? ClockodoError == .notConnected)
        }
    }

    // MARK: Block E — createEntry (Härtung 2026-07-01)

    @Test func buildCreateEntryBodyEnthaeltPflichtfelder() throws {
        let since = Date(timeIntervalSince1970: 1_700_000_000)
        let until = Date(timeIntervalSince1970: 1_700_003_600)
        let body = ClockodoClient.buildCreateEntryBody(
            customersID: 42, servicesID: 7, timeSince: since, timeUntil: until, billable: true, text: "CAD-Planung"
        )
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])

        #expect(json["customers_id"] as? Int == 42)
        #expect(json["services_id"] as? Int == 7)
        #expect(json["billable"] as? Int == 1)
        #expect(json["text"] as? String == "CAD-Planung")
        #expect(json["time_since"] != nil)
        #expect(json["time_until"] != nil)
    }

    @Test func buildCreateEntryBodyOhneTextLaesstFeldWeg() throws {
        let body = ClockodoClient.buildCreateEntryBody(
            customersID: 1, servicesID: 1, timeSince: Date(), timeUntil: Date(), billable: false, text: nil
        )
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["text"] == nil)
        #expect(json["billable"] as? Int == 0)
    }

    @Test func parseCreateEntryResponseDekodiertID() throws {
        let json = #"{"entry": {"id": 123456, "customers_id": 42}}"#
        let id = try ClockodoClient.parseCreateEntryResponse(from: Data(json.utf8))
        #expect(id == "123456")
    }

    @Test func parseCreateEntryResponseWirftBeiKaputtemJSON() {
        #expect(throws: ClockodoError.decodingFailed) {
            _ = try ClockodoClient.parseCreateEntryResponse(from: Data("nope".utf8))
        }
    }

    @Test func createEntryWirftNotConnectedOhneCredentials() async {
        let store = InMemoryClockodoCredentialsStore()
        let client = ClockodoClient(credentialsStore: store)

        do {
            _ = try await client.createEntry(
                customersID: 1, servicesID: 1, timeSince: Date(), timeUntil: Date(), billable: true, text: nil
            )
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? ClockodoError == .notConnected)
        }
    }
}

// MARK: - InMemoryClockodoCredentialsStore

final class InMemoryClockodoCredentialsStore: ClockodoCredentialsStoring, @unchecked Sendable {
    private var stored: ClockodoCredentials?

    init(credentials: ClockodoCredentials? = nil) {
        self.stored = credentials
    }

    func store(_ credentials: ClockodoCredentials) throws {
        self.stored = credentials
    }

    func load() throws -> ClockodoCredentials? {
        stored
    }

    func clear() throws {
        stored = nil
    }
}
