import Foundation

// MARK: - GoogleGmailMessage
public struct GoogleGmailMessage: Identifiable, Equatable, Sendable {
    public var id: String
    public var subject: String
    public var from: String
    public var snippet: String
    public var receivedAt: Date?

    public init(id: String, subject: String, from: String, snippet: String, receivedAt: Date?) {
        self.id = id
        self.subject = subject
        self.from = from
        self.snippet = snippet
        self.receivedAt = receivedAt
    }
}

// MARK: - GoogleGmailError
public enum GoogleGmailError: Error, Sendable, Equatable {
    case notConnected
    case invalidResponse
    case httpError(Int)
    case decodingFailed
}

// MARK: - GoogleGmailFetching
public protocol GoogleGmailFetching: Sendable {
    func searchMessages(query: String, maxResults: Int) async throws -> [GoogleGmailMessage]
}

// MARK: - GoogleGmailClient
// Liest E-Mails readonly über Gmail API v1. Scope gmail.readonly ist bereits
// in GoogleOAuthScope.readOnlyDefaults enthalten.
public struct GoogleGmailClient: GoogleGmailFetching {
    private let tokenProvider: GoogleAccessTokenProviding
    private let session: URLSession
    private let baseURL = "https://gmail.googleapis.com/gmail/v1/users/me/messages"

    public init(
        tokenProvider: GoogleAccessTokenProviding = GoogleAccessTokenProvider(),
        session: URLSession = .shared
    ) {
        self.tokenProvider = tokenProvider
        self.session = session
    }

    public func searchMessages(query: String, maxResults: Int = 10) async throws -> [GoogleGmailMessage] {
        guard let accessToken = try? await tokenProvider.validAccessToken() else {
            throw GoogleGmailError.notConnected
        }

        guard let listURL = Self.buildListURL(query: query, maxResults: maxResults, baseURL: baseURL) else {
            throw GoogleGmailError.invalidResponse
        }

        var listRequest = URLRequest(url: listURL)
        listRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (listData, listResponse) = try await session.data(for: listRequest)
        guard let listHTTP = listResponse as? HTTPURLResponse else { throw GoogleGmailError.invalidResponse }
        guard (200...299).contains(listHTTP.statusCode) else { throw GoogleGmailError.httpError(listHTTP.statusCode) }

        let messageIDs = try Self.parseMessageIDs(from: listData)
        guard !messageIDs.isEmpty else { return [] }

        var messages: [GoogleGmailMessage] = []
        for id in messageIDs {
            guard let detailURL = Self.buildDetailURL(messageID: id, baseURL: baseURL) else { continue }
            var detailRequest = URLRequest(url: detailURL)
            detailRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            let (detailData, detailResponse) = try await session.data(for: detailRequest)
            guard let detailHTTP = detailResponse as? HTTPURLResponse,
                  (200...299).contains(detailHTTP.statusCode) else { continue }
            if let msg = try? Self.parseMessage(from: detailData) {
                messages.append(msg)
            }
        }
        return messages
    }

    // MARK: - Reine, testbare Bausteine

    static func buildListURL(query: String, maxResults: Int, baseURL: String) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
        ]
        return components?.url
    }

    static func buildDetailURL(messageID: String, baseURL: String) -> URL? {
        var components = URLComponents(string: baseURL + "/\(messageID)")
        components?.queryItems = [
            URLQueryItem(name: "format", value: "metadata"),
            URLQueryItem(name: "metadataHeaders", value: "Subject"),
            URLQueryItem(name: "metadataHeaders", value: "From"),
            URLQueryItem(name: "metadataHeaders", value: "Date"),
        ]
        return components?.url
    }

    static func parseMessageIDs(from data: Data) throws -> [String] {
        do {
            let decoded = try JSONDecoder().decode(GmailListResponse.self, from: data)
            return (decoded.messages ?? []).map(\.id)
        } catch {
            throw GoogleGmailError.decodingFailed
        }
    }

    static func parseMessage(from data: Data) throws -> GoogleGmailMessage {
        do {
            let decoded = try JSONDecoder().decode(GmailMessageResource.self, from: data)
            return mapResource(decoded)
        } catch {
            throw GoogleGmailError.decodingFailed
        }
    }

    private static func mapResource(_ resource: GmailMessageResource) -> GoogleGmailMessage {
        let headers = resource.payload?.headers ?? []
        let subject = headers.first(where: { $0.name == "Subject" })?.value ?? "(kein Betreff)"
        let fromRaw = headers.first(where: { $0.name == "From" })?.value ?? ""
        let dateString = headers.first(where: { $0.name == "Date" })?.value

        return GoogleGmailMessage(
            id: resource.id,
            subject: subject,
            from: extractSenderName(from: fromRaw),
            snippet: resource.snippet ?? "",
            receivedAt: dateString.flatMap { parseEmailDate($0) }
        )
    }

    static func extractSenderName(from raw: String) -> String {
        if let angleBracket = raw.firstIndex(of: "<") {
            let name = raw[raw.startIndex..<angleBracket].trimmingCharacters(in: .whitespacesAndNewlines)
            let cleaned = name.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            return cleaned.isEmpty ? raw : cleaned
        }
        return raw
    }

    private static func parseEmailDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in [
            "EEE, d MMM yyyy HH:mm:ss Z",
            "d MMM yyyy HH:mm:ss Z",
            "EEE, d MMM yyyy HH:mm:ss z",
        ] {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) { return date }
        }
        return nil
    }
}

// MARK: - Response Types

private struct GmailListResponse: Decodable {
    var messages: [GmailMessageRef]?
}

private struct GmailMessageRef: Decodable {
    var id: String
}

private struct GmailMessageResource: Decodable {
    var id: String
    var snippet: String?
    var payload: GmailPayload?
}

private struct GmailPayload: Decodable {
    var headers: [GmailHeader]?
}

private struct GmailHeader: Decodable {
    var name: String
    var value: String
}
