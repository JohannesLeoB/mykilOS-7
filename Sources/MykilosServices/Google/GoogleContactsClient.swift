import Foundation
import MykilosKit

// MARK: - GoogleContact
public struct GoogleContact: Identifiable, Equatable, Sendable {
    public var id: String
    public var displayName: String
    public var email: String?
    public var phone: String?
    public var organization: String?
    // Härtung (2026-07-01, Johannes: Bestandskunden-Auswahl im Fragebogen): die People-API
    // liefert givenName/familyName bereits im "names"-readMask mit — bisher verworfen und
    // nur displayName behalten. Für ein sauberes Vorname/Nachname-Prefill statt Raten
    // (z. B. erstes Wort als Vorname) jetzt direkt mitgeführt, wenn vorhanden.
    public var givenName: String?
    public var familyName: String?

    public init(
        id: String, displayName: String, email: String?, phone: String?, organization: String?,
        givenName: String? = nil, familyName: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.phone = phone
        self.organization = organization
        self.givenName = givenName
        self.familyName = familyName
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
    /// Durchsucht das Google-Workspace-VERZEICHNIS der Domain (S19): Team-Profile +
    /// admin-geteilte Domain-Kontakte (kontounabhängig). Default-Impl wirft, damit
    /// bestehende Fakes unberührt bleiben — der echte Client überschreibt sie.
    func searchDirectory(query: String?) async throws -> [GoogleContact]
}

public extension GoogleContactsFetching {
    func searchDirectory(query: String?) async throws -> [GoogleContact] {
        throw GoogleContactsError.invalidResponse
    }
}

// MARK: - GoogleContactsWriting (S9)
// Schreibender Zugriff — getrennt von der Lese-Schnittstelle, damit Lese-Fakes
// unberührt bleiben. Schreibt EINEN neuen Kontakt (People API createContact).
// Braucht den `contacts`-Scope (nicht nur readonly) → Google Re-Consent (M2).
public protocol GoogleContactsWriting: Sendable {
    func createContact(_ draft: ContactDraft) async throws -> GoogleContact
}

// MARK: - GoogleContactsClient
// Durchsucht die echten Kontakte des verbundenen Accounts per Freitext —
// das ist genau, was Project.links.contactsQuery trägt: keine eigene
// Kontaktliste je Projekt, sondern eine Suche über alle Kontakte.
public struct GoogleContactsClient: GoogleContactsFetching, GoogleContactsWriting {
    private let tokenProvider: GoogleAccessTokenProviding
    private let session: URLSession
    private let baseURL = "https://people.googleapis.com/v1/people:searchContacts"
    private let createURL = "https://people.googleapis.com/v1/people:createContact"
    private let directoryURL = "https://people.googleapis.com/v1/people:searchDirectoryPeople"

    public init(
        tokenProvider: GoogleAccessTokenProviding = GoogleAccessTokenProvider(),
        session: URLSession = .shared
    ) {
        self.tokenProvider = tokenProvider
        self.session = session
    }

    public func searchContacts(query rawQuery: String?) async throws -> [GoogleContact] {
        let query = Self.normalizedQuery(rawQuery)
        guard query.isEmpty == false else {
            return []
        }
        guard let accessToken = try? await tokenProvider.validAccessToken() else {
            throw GoogleContactsError.notConnected
        }

        // People API searchContacts braucht einen WARMUP: Google baut den Such-Index
        // asynchron auf, der allererste Aufruf nach kaltem Cache liefert deterministisch
        // LEER — unabhängig davon, ob es Treffer gäbe. Das war der „Kontakte gehen nicht"-
        // Bug: jede frische Projektseite bekam eine leere Liste. Doku:
        // https://developers.google.com/people/v1/contacts#search_the_users_contacts
        // Fix: stiller Warmup (leere Query), dann die echte Suche; bleibt sie leer,
        // einmal kurz nachfassen (Index evtl. noch nicht warm).
        await warmup(accessToken: accessToken)
        var contacts = try await runSearch(query: query, accessToken: accessToken)
        if contacts.isEmpty {
            try? await Task.sleep(nanoseconds: 500_000_000)
            contacts = try await runSearch(query: query, accessToken: accessToken)
        }
        return contacts
    }

    // S19: Workspace-Verzeichnis durchsuchen (Team-Profile + admin-geteilte Domain-Kontakte).
    // Braucht den directory.readonly-Scope → Re-Consent (M2). Read-only.
    public func searchDirectory(query rawQuery: String?) async throws -> [GoogleContact] {
        let query = Self.normalizedQuery(rawQuery)
        guard query.isEmpty == false else { return [] }
        guard let accessToken = try? await tokenProvider.validAccessToken() else {
            throw GoogleContactsError.notConnected
        }
        guard let url = Self.buildDirectoryURL(query: query, baseURL: directoryURL) else {
            throw GoogleContactsError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GoogleContactsError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw GoogleContactsError.httpError(http.statusCode) }
        return try Self.parseDirectory(from: data)
    }

    private func warmup(accessToken: String) async {
        guard let url = Self.buildWarmupURL(baseURL: baseURL) else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        _ = try? await session.data(for: request)   // Ergebnis bewusst verworfen (nur Index aufwärmen)
    }

    private func runSearch(query: String, accessToken: String) async throws -> [GoogleContact] {
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

    // MARK: - Schreiben (S9)

    public func createContact(_ draft: ContactDraft) async throws -> GoogleContact {
        guard draft.givenName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw GoogleContactsError.invalidResponse
        }
        guard let accessToken = try? await tokenProvider.validAccessToken() else {
            throw GoogleContactsError.notConnected
        }
        guard let url = URL(string: createURL) else { throw GoogleContactsError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try Self.buildCreateBody(draft)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GoogleContactsError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw GoogleContactsError.httpError(http.statusCode) }
        return try Self.parsePerson(from: data)
    }

    // MARK: - Reine, testbare Bausteine (kein Netzwerk/Keychain)

    /// Baut den People-API `Person`-Body für createContact. Nur gesetzte Felder werden
    /// aufgenommen (keine leeren Arrays). Deterministisch + testbar.
    static func buildCreateBody(_ draft: ContactDraft) throws -> Data {
        var person: [String: Any] = [:]
        var name: [String: String] = ["givenName": draft.givenName.trimmingCharacters(in: .whitespacesAndNewlines)]
        if let fam = draft.familyName?.trimmingCharacters(in: .whitespacesAndNewlines), fam.isEmpty == false {
            name["familyName"] = fam
        }
        person["names"] = [name]
        if let mail = draft.email?.trimmingCharacters(in: .whitespacesAndNewlines), mail.isEmpty == false {
            person["emailAddresses"] = [["value": mail]]
        }
        if let phone = draft.phone?.trimmingCharacters(in: .whitespacesAndNewlines), phone.isEmpty == false {
            person["phoneNumbers"] = [["value": phone]]
        }
        if let org = draft.organization?.trimmingCharacters(in: .whitespacesAndNewlines), org.isEmpty == false {
            person["organizations"] = [["name": org]]
        }
        return try JSONSerialization.data(withJSONObject: person, options: [.sortedKeys])
    }

    /// Dekodiert die von createContact zurückgegebene Person in einen GoogleContact.
    static func parsePerson(from data: Data) throws -> GoogleContact {
        do {
            let person = try JSONDecoder().decode(GoogleContactsPerson.self, from: data)
            return GoogleContact(
                id: person.resourceName ?? UUID().uuidString,
                displayName: person.names?.first?.displayName
                    ?? person.names?.first?.givenName
                    ?? "(neuer Kontakt)",
                email: person.emailAddresses?.first?.value,
                phone: person.phoneNumbers?.first?.value,
                organization: person.organizations?.first?.name,
                givenName: person.names?.first?.givenName,
                familyName: person.names?.first?.familyName)
        } catch {
            throw GoogleContactsError.decodingFailed
        }
    }

    /// Säubert die Projekt-Suchbegriffe: Unterstriche (die in echten Kontaktnamen nie
    /// vorkommen, aber in den Projekt-Tokens wie „Fuckner_Huetter" stehen) werden zu
    /// Leerzeichen, Mehrfach-Whitespace kollabiert, Rand getrimmt.
    static func normalizedQuery(_ raw: String?) -> String {
        guard let raw else { return "" }
        let spaced = raw.replacingOccurrences(of: "_", with: " ")
        return spaced.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
            .joined(separator: " ")
    }

    static func buildWarmupURL(baseURL: String) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "query", value: ""),
            URLQueryItem(name: "readMask", value: "names,emailAddresses,phoneNumbers,organizations"),
        ]
        return components?.url
    }

    static func buildSearchURL(query: String, baseURL: String) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "readMask", value: "names,emailAddresses,phoneNumbers,organizations"),
        ]
        return components?.url
    }

    // S19: searchDirectoryPeople — Domain-Profile (Team) + admin-geteilte Domain-Kontakte.
    static func buildDirectoryURL(query: String, baseURL: String) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "readMask", value: "names,emailAddresses,phoneNumbers,organizations"),
            URLQueryItem(name: "sources", value: "DIRECTORY_SOURCE_TYPE_DOMAIN_PROFILE"),
            URLQueryItem(name: "sources", value: "DIRECTORY_SOURCE_TYPE_DOMAIN_CONTACT"),
            URLQueryItem(name: "pageSize", value: "30"),
        ]
        return components?.url
    }

    // searchDirectoryPeople liefert `people: [Person]` (anders als searchContacts: `results[].person`).
    static func parseDirectory(from data: Data) throws -> [GoogleContact] {
        do {
            let decoded = try JSONDecoder().decode(GoogleDirectoryResponse.self, from: data)
            return (decoded.people ?? []).map { person in
                GoogleContact(
                    id: person.resourceName ?? UUID().uuidString,
                    displayName: person.names?.first?.displayName ?? "(ohne Namen)",
                    email: person.emailAddresses?.first?.value,
                    phone: person.phoneNumbers?.first?.value,
                    organization: person.organizations?.first?.name,
                    givenName: person.names?.first?.givenName,
                    familyName: person.names?.first?.familyName)
            }
        } catch {
            throw GoogleContactsError.decodingFailed
        }
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
                    organization: person?.organizations?.first?.name,
                    givenName: person?.names?.first?.givenName,
                    familyName: person?.names?.first?.familyName
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

private struct GoogleDirectoryResponse: Decodable {
    var people: [GoogleContactsPerson]?
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
    var givenName: String?
    var familyName: String?
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
