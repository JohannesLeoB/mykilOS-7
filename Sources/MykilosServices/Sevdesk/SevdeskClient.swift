import Foundation

// MARK: - SevdeskInvoice
// Eine Rechnung aus sevdesk für den im Projekt verlinkten Kontakt
// (Project.links.sevdeskRef = sevdesk-Kontakt-ID). Reiner Lesefetch — der
// Ist-Umsatz speist den Budget-Balken; mykilOS bucht/schreibt nichts in sevdesk.
public struct SevdeskInvoice: Identifiable, Equatable, Sendable {
    public var id: String
    public var number: String
    public var sumGross: Double
    public var status: String

    public init(id: String, number: String, sumGross: Double, status: String) {
        self.id = id
        self.number = number
        self.sumGross = sumGross
        self.status = status
    }
}

// MARK: - SevdeskError
public enum SevdeskError: Error, Sendable, Equatable {
    case notConnected
    case invalidResponse
    case httpError(Int)
    case decodingFailed
}

// MARK: - SevdeskFetching
public protocol SevdeskFetching: Sendable {
    func invoices(contactRef: String) async throws -> [SevdeskInvoice]
}

// MARK: - SevdeskClient
// Liest die Rechnungen eines sevdesk-Kontakts des verbundenen Accounts.
// Auth: API-Token direkt im Authorization-Header (kein "Bearer").
public struct SevdeskClient: SevdeskFetching {
    private let credentialsStore: SevdeskCredentialsStoring
    private let session: URLSession
    private let baseURL = "https://my.sevdesk.de/api/v1"

    public init(
        credentialsStore: SevdeskCredentialsStoring = KeychainSevdeskCredentialsStore(),
        session: URLSession = .shared
    ) {
        self.credentialsStore = credentialsStore
        self.session = session
    }

    public func invoices(contactRef: String) async throws -> [SevdeskInvoice] {
        guard let credentials = try? credentialsStore.load() else {
            throw SevdeskError.notConnected
        }
        guard let url = Self.buildInvoicesURL(baseURL: baseURL, contactRef: contactRef) else {
            throw SevdeskError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue(credentials.apiToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw SevdeskError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw SevdeskError.httpError(http.statusCode) }

        return try Self.parseInvoices(from: data)
    }

    // MARK: - Reine, testbare Bausteine (kein Netzwerk/Keychain)

    static func buildInvoicesURL(baseURL: String, contactRef: String) -> URL? {
        var components = URLComponents(string: "\(baseURL)/Invoice")
        components?.queryItems = [
            URLQueryItem(name: "contact[id]", value: contactRef),
            URLQueryItem(name: "contact[objectName]", value: "Contact"),
            URLQueryItem(name: "limit", value: "100"),
        ]
        return components?.url
    }

    static func parseInvoices(from data: Data) throws -> [SevdeskInvoice] {
        do {
            let decoded = try JSONDecoder().decode(SevdeskInvoiceResponse.self, from: data)
            return decoded.objects.map { entity in
                SevdeskInvoice(
                    id: entity.id ?? "",
                    number: entity.invoiceNumber ?? "",
                    sumGross: Self.double(from: entity.sumGross),
                    status: entity.status ?? ""
                )
            }
        } catch {
            throw SevdeskError.decodingFailed
        }
    }

    // sevdesk liefert Geldbeträge als String (z. B. "1234.56").
    static func double(from value: String?) -> Double {
        guard let value, let parsed = Double(value) else { return 0 }
        return parsed
    }
}

// MARK: - Decodable-Spiegel der sevdesk-Antwort
private struct SevdeskInvoiceResponse: Decodable {
    var objects: [SevdeskInvoiceEntity]
}

private struct SevdeskInvoiceEntity: Decodable {
    var id: String?
    var invoiceNumber: String?
    var sumGross: String?
    var status: String?
}
