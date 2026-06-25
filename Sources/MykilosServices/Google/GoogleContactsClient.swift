import Foundation

// MARK: - GoogleContact
public struct GoogleContact: Identifiable, Equatable, Sendable {
    public var id: String
    public var displayName: String
    public var email: String?
    public var phone: String?
    public var organization: String?

    public init(id: String, displayName: String, email: String?, phone: String?, organization: String?) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.phone = phone
        self.organization = organization
    }
}

// MARK: - GoogleContactsError
public enum GoogleContactsError: Error, Sendable, Equatable {
    case notConnected
    case invalidResponse
    case httpError(Int)
    case decodingFailed
}

// MARK: - GoogleContactsFetching
public protocol GoogleContactsFetching: Sendable {
    func searchContacts(query: String?) async throws -> [GoogleContact]
}

// MARK: - GoogleContactsClient
// Durchsucht die echten Kontakte des verbundenen Accounts per Freitext —
// das ist genau, was Project.links.contactsQuery trägt: keine eigene
// Kontaktliste je Projekt, sondern eine Suche über alle Kontakte.
public struct GoogleContactsClient: GoogleContactsFetching {
    private let tokenProvider: GoogleAccessTokenProviding
    private let session: URLSession
    private let baseURL = "https://people.googleapis.com/v1/people:searchContacts"

    public init(
        tokenProvider: GoogleAccessTokenProviding = GoogleAccessTokenProvider(),
        session: URLSession = .shared
    ) {
        self.tokenProvider = tokenProvider
        self.session = session
    }

    public func searchContacts(query: String?) async throws -> [GoogleContact] {
        guard let query, query.isEmpty == false else {
            return []
        }
        guard let accessToken = try? await tokenProvider.validAccessToken() else {
            throw GoogleContactsError.notConnected
        }
        guard let url = Self.buildSearchURL(query: query, baseURL: baseURL) else {
            throw GoogleContactsError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GoogleContactsError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw GoogleContactsError.httpError(http.statusCode) }

        return try Self.parseContacts(from: data)
    }

    // MARK: - Reine, testbare Bausteine (kein Netzwerk/Keychain)

    static func buildSearchURL(query: String, baseURL: String) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "readMask", value: "names,emailAddresses,phoneNumbers,organizations"),
        ]
        return components?.url
    }

    static func parseContacts(from data: Data) throws -> [GoogleContact] {
        do {
            let decoded = try JSONDecoder().decode(GoogleContactsSearchResponse.self, from: data)
            return (decoded.results ?? []).map { result in
                let person = result.person
                return GoogleContact(
                    id: person?.resourceName ?? UUID().uuidString,
                    displayName: person?.names?.first?.displayName ?? "(ohne Namen)",
                    email: person?.emailAddresses?.first?.value,
                    phone: person?.phoneNumbers?.first?.value,
                    organization: person?.organizations?.first?.name
                )
            }
        } catch {
            throw GoogleContactsError.decodingFailed
        }
    }
}

private struct GoogleContactsSearchResponse: Decodable {
    var results: [GoogleContactsSearchResult]?
}

private struct GoogleContactsSearchResult: Decodable {
    var person: GoogleContactsPerson?
}

private struct GoogleContactsPerson: Decodable {
    var resourceName: String?
    var names: [GoogleContactsName]?
    var emailAddresses: [GoogleContactsEmail]?
    var phoneNumbers: [GoogleContactsPhone]?
    var organizations: [GoogleContactsOrganization]?
}

private struct GoogleContactsName: Decodable {
    var displayName: String?
}

private struct GoogleContactsEmail: Decodable {
    var value: String?
}

private struct GoogleContactsPhone: Decodable {
    var value: String?
}

private struct GoogleContactsOrganization: Decodable {
    var name: String?
}
