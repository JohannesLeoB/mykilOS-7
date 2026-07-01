import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

struct AirtableClientTests {

    @Test func buildListURLEnthaeltBaseUndTable() {
        let url = AirtableClient.buildListURL(
            apiBase: "https://api.airtable.com/v0",
            baseID: "appXYZ",
            table: "Kunden",
            offset: nil
        )
        let urlString = url?.absoluteString ?? ""
        #expect(urlString.contains("appXYZ"))
        #expect(urlString.contains("Kunden"))
        #expect(urlString.contains("pageSize=100"))
        #expect(!urlString.contains("offset"))
    }

    @Test func buildListURLMitOffset() {
        let url = AirtableClient.buildListURL(
            apiBase: "https://api.airtable.com/v0",
            baseID: "appXYZ",
            table: "Projekte",
            offset: "itr123"
        )
        let urlString = url?.absoluteString ?? ""
        #expect(urlString.contains("offset=itr123"))
    }

    @Test func parsePageDekodiertRecordsUndOffset() throws {
        let json = """
        {
          "records": [
            { "id": "rec1", "fields": { "Name": "Meyer GmbH", "Nummer": "K-1001" } },
            { "id": "rec2", "fields": { "Name": "Loft GmbH" } }
          ],
          "offset": "nextPage123"
        }
        """
        let page = try AirtableClient.parsePage(from: Data(json.utf8))
        #expect(page.records.count == 2)
        #expect(page.offset == "nextPage123")
        #expect(page.records[0]["Name"]?.stringValue == "Meyer GmbH")
        #expect(page.records[0]["_airtableRecordID"]?.stringValue == "rec1")
    }

    @Test func parsePageOhneOffset() throws {
        let json = """
        { "records": [{ "id": "rec1", "fields": { "X": "Y" } }] }
        """
        let page = try AirtableClient.parsePage(from: Data(json.utf8))
        #expect(page.offset == nil)
        #expect(page.records.count == 1)
    }

    @Test func parsePageWirftBeiKaputtemJSON() {
        #expect(throws: AirtableError.decodingFailed) {
            _ = try AirtableClient.parsePage(from: Data("nope".utf8))
        }
    }

    @Test func mapCustomersExtrahiertNummernUndNamen() {
        let records: [[String: AirtableFieldValue]] = [
            ["Kundennummer": .string("K-1001"), "Name": .string("Meyer"), "_airtableRecordID": .string("rec1")],
            ["Kundennummer": .string("K-1002"), "Name": .string("Loft"), "_airtableRecordID": .string("rec2")],
            ["Name": .string("Nur Name")],
        ]
        let customers = AirtableClient.mapCustomers(from: records)
        #expect(customers.count == 2)
        #expect(customers[0].customerNumber == "K-1001")
        #expect(customers[0].name == "Meyer")
        #expect(customers[0].airtableRecordID == "rec1")
    }

    @Test func mapProjectsExtrahiertAlleFelder() {
        let records: [[String: AirtableFieldValue]] = [
            [
                "Projektnummer": .string("ME-24"),
                "Titel": .string("Küche Meyer"),
                "Art": .string("kitchen"),
                "Kundennummer": .string("K-1001"),
                "Drive-Ordner-ID": .string("folder123"),
                "Kalender-Suche": .string("Meyer"),
                "Kontakte-Suche": .string("Meyer"),
                "Mail-Suche": .string("Meyer Küche"),
                "Phase": .string("Ausführungsplanung"),
                "_airtableRecordID": .string("recME24"),
            ]
        ]
        let projects = AirtableClient.mapProjects(from: records)
        #expect(projects.count == 1)
        let p = projects[0]
        #expect(p.projectNumber == "ME-24")
        #expect(p.title == "Küche Meyer")
        #expect(p.kind == .kitchen)
        #expect(p.customerNumber == "K-1001")
        #expect(p.links.driveFolderID == "folder123")
        #expect(p.links.calendarQuery == "Meyer")
        #expect(p.links.mailQuery == "Meyer Küche")
        #expect(p.phase == "Ausführungsplanung")
        #expect(p.airtableRecordID == "recME24")
    }

    @Test func mapProjectsIgnoriertUnvollstaendigeRecords() {
        let records: [[String: AirtableFieldValue]] = [
            ["Projektnummer": .string("ME-24")],
            ["Titel": .string("Nur Titel")],
        ]
        let projects = AirtableClient.mapProjects(from: records)
        #expect(projects.isEmpty)
    }

    @Test func fetchRecordsWirftNotConnectedOhneCredentials() async {
        let store = InMemoryAirtableCredentialsStore()
        let client = AirtableClient(credentialsStore: store)

        do {
            _ = try await client.fetchRecords(baseID: "app123", table: "Test")
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? AirtableError == .notConnected)
        }
    }

    // MARK: - Whitelist-Map Tests (Phase 1: Webshop-Bases)

    @Test func whitelistMapEnthaeltMastermindUndArtikelBase() {
        #expect(AirtableClient.writableMap["appuVMh3KDfKw4OoQ"] != nil)
        #expect(AirtableClient.writableMap["appdxTeT6bhSBmwx5"] != nil)
    }

    @Test func isWritableErlaubtMastermindTabellen() {
        #expect(AirtableClient.isWritable(baseID: "appuVMh3KDfKw4OoQ", table: "Datenstrom-Handbuch"))
        #expect(AirtableClient.isWritable(baseID: "appuVMh3KDfKw4OoQ", table: "Datenstrom-Log"))
        #expect(AirtableClient.isWritable(baseID: "appuVMh3KDfKw4OoQ", table: "Kontakte"))
    }

    @Test func isWritableErlaubtArtikelBaseTabellen() {
        #expect(AirtableClient.isWritable(baseID: "appdxTeT6bhSBmwx5", table: "Lagerliste"))
        #expect(AirtableClient.isWritable(baseID: "appdxTeT6bhSBmwx5", table: "Projektartikel"))
        #expect(AirtableClient.isWritable(baseID: "appdxTeT6bhSBmwx5", table: "Warenkörbe"))
    }

    @Test func isWritableVerbietedFremdeBasen() {
        // Die geteilte Base darf NIEMALS beschrieben werden
        #expect(!AirtableClient.isWritable(baseID: "appkPzoEiI5eSMkNK", table: "Projekte"))
        #expect(!AirtableClient.isWritable(baseID: "appkPzoEiI5eSMkNK", table: "Kunden"))
        // Unbekannte Bases
        #expect(!AirtableClient.isWritable(baseID: "appUNKNOWN123", table: "Projekte"))
    }

    @Test func isWritableVerbietedNichtFreigegebeneTabellenInArtikelBase() {
        // In der Artikel-Base dürfen nur die drei freigegebenen Tabellen beschrieben werden
        #expect(!AirtableClient.isWritable(baseID: "appdxTeT6bhSBmwx5", table: "Artikel"))
        #expect(!AirtableClient.isWritable(baseID: "appdxTeT6bhSBmwx5", table: "Lieferanten"))
        #expect(!AirtableClient.isWritable(baseID: "appdxTeT6bhSBmwx5", table: "Preise"))
    }

    @Test func isWritableVerbietedNichtFreigegebeneTabellenInMastermind() {
        // In der Mastermind-Base gibt es mehr Tabellen, die NICHT freigebeben sind.
        // "Projekte" ist seit 2026-07-01 freigegeben (Fragebogen-Live-Provisionierung,
        // Johannes bestätigt) — siehe isWritableErlaubtProjekteRoutingInMastermind unten.
        #expect(!AirtableClient.isWritable(baseID: "appuVMh3KDfKw4OoQ", table: "Kunden"))
        #expect(!AirtableClient.isWritable(baseID: "appuVMh3KDfKw4OoQ", table: "Kalkulationen"))
    }

    @Test func isWritableErlaubtProjekteRoutingInMastermind() {
        #expect(AirtableClient.isWritable(baseID: "appuVMh3KDfKw4OoQ", table: "Projekte"))
    }

    @Test func createRecordWirftBeiVerbotenerBase() async {
        let store = InMemoryAirtableCredentialsStore(
            credentials: AirtableCredentials(pat: "fake", baseID: "appXYZ")
        )
        let client = AirtableClient(credentialsStore: store)
        do {
            _ = try await client.createRecord(
                baseID: "appkPzoEiI5eSMkNK",
                table: "Projekte",
                fields: ["Titel": .string("Test")]
            )
            Issue.record("sollte invalidBaseID werfen")
        } catch let err as AirtableError {
            if case .invalidBaseID = err { } else {
                Issue.record("Falscher Fehler: \(err)")
            }
        } catch {
            Issue.record("Unbekannter Fehler: \(error)")
        }
    }

    @Test func updateRecordWirftBeiVerbotenerTabelle() async {
        let store = InMemoryAirtableCredentialsStore(
            credentials: AirtableCredentials(pat: "fake", baseID: "appXYZ")
        )
        let client = AirtableClient(credentialsStore: store)
        do {
            try await client.updateRecord(
                baseID: "appdxTeT6bhSBmwx5",
                table: "Artikel",          // nicht freigebeben
                recordID: "rec123",
                fields: ["Name": .string("Test")]
            )
            Issue.record("sollte invalidBaseID werfen")
        } catch let err as AirtableError {
            if case .invalidBaseID = err { } else {
                Issue.record("Falscher Fehler: \(err)")
            }
        } catch {
            Issue.record("Unbekannter Fehler: \(error)")
        }
    }
}

// MARK: - InMemoryAirtableCredentialsStore

final class InMemoryAirtableCredentialsStore: AirtableCredentialsStoring, @unchecked Sendable {
    private var stored: AirtableCredentials?

    init(credentials: AirtableCredentials? = nil) {
        self.stored = credentials
    }

    func store(_ credentials: AirtableCredentials) throws {
        self.stored = credentials
    }

    func load() throws -> AirtableCredentials? {
        stored
    }

    func clear() throws {
        stored = nil
    }
}
