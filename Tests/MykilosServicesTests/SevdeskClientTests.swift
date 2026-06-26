import Testing
import Foundation
@testable import MykilosServices

struct SevdeskClientTests {

    private let baseURL = "https://my.sevdesk.de/api/v1"

    @Test func buildInvoicesURLFiltertAufKontaktUndLimit() {
        let url = SevdeskClient.buildInvoicesURL(baseURL: baseURL, contactRef: "1001")
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(components?.path == "/api/v1/Invoice")
        #expect(items["contact[id]"] == "1001")
        #expect(items["contact[objectName]"] == "Contact")
        #expect(items["limit"] == "100")
    }

    @Test func parseInvoicesDekodiertNummerBruttoUndStatus() throws {
        let json = """
        {
          "objects": [
            { "id": "5001", "invoiceNumber": "RE-2024-014", "sumGross": "12500.50", "status": "200" },
            { "id": "5002", "invoiceNumber": "RE-2024-021", "sumGross": "8000.00", "status": "100" }
          ]
        }
        """
        let invoices = try SevdeskClient.parseInvoices(from: Data(json.utf8))

        #expect(invoices.count == 2)
        #expect(invoices[0].id == "5001")
        #expect(invoices[0].number == "RE-2024-014")
        #expect(invoices[0].sumGross == 12500.50)
        #expect(invoices[0].status == "200")
        #expect(invoices[1].sumGross == 8000.00)
    }

    @Test func parseInvoicesLeereListe() throws {
        let json = """
        { "objects": [] }
        """
        let invoices = try SevdeskClient.parseInvoices(from: Data(json.utf8))
        #expect(invoices.isEmpty)
    }

    @Test func parseInvoicesWirftBeiKaputtemJSON() {
        #expect(throws: SevdeskError.decodingFailed) {
            _ = try SevdeskClient.parseInvoices(from: Data("kein json".utf8))
        }
    }

    @Test func doubleKonvertiertStringUndFaelltAufNullZurueck() {
        #expect(SevdeskClient.double(from: "1234.56") == 1234.56)
        #expect(SevdeskClient.double(from: nil) == 0)
        #expect(SevdeskClient.double(from: "keine zahl") == 0)
    }

    @Test func invoicesWirftNotConnectedOhneCredentials() async {
        let store = InMemorySevdeskCredentialsStore()
        let client = SevdeskClient(credentialsStore: store)

        do {
            _ = try await client.invoices(contactRef: "1001")
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? SevdeskError == .notConnected)
        }
    }
}

// MARK: - InMemorySevdeskCredentialsStore

final class InMemorySevdeskCredentialsStore: SevdeskCredentialsStoring, @unchecked Sendable {
    private var stored: SevdeskCredentials?

    init(credentials: SevdeskCredentials? = nil) {
        self.stored = credentials
    }

    func store(_ credentials: SevdeskCredentials) throws {
        self.stored = credentials
    }

    func load() throws -> SevdeskCredentials? {
        stored
    }

    func clear() throws {
        stored = nil
    }
}
