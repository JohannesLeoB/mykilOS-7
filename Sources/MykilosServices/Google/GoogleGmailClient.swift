import Foundation
import MykilosKit

// MARK: - GmailAttachment
/// Metadaten eines Mail-Anhangs (kein Inhalt — nur Name, Typ, ID für späteren Download).
public struct GmailAttachment: Equatable, Sendable {
    public var attachmentID: String
    public var filename: String
    public var mimeType: String
    public var sizeBytes: Int

    public init(attachmentID: String, filename: String, mimeType: String, sizeBytes: Int) {
        self.attachmentID = attachmentID
        self.filename = filename
        self.mimeType = mimeType
        self.sizeBytes = sizeBytes
    }
}

// MARK: - GoogleGmailMessage
public struct GoogleGmailMessage: Identifiable, Equatable, Sendable {
    public var id: String
    public var threadID: String
    public var subject: String
    public var from: String
    public var snippet: String
    public var receivedAt: Date?
    public var labels: [String]
    public var attachments: [GmailAttachment]

    public init(id: String, threadID: String = "", subject: String, from: String, snippet: String, receivedAt: Date?, labels: [String] = [], attachments: [GmailAttachment] = []) {
        self.id = id
        self.threadID = threadID
        self.subject = subject
        self.from = from
        self.snippet = snippet
        self.receivedAt = receivedAt
        self.labels = labels
        self.attachments = attachments
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
    /// Volltext-Body einer Mail (S15). Default-Impl wirft, damit bestehende Fakes
    /// unberührt bleiben — der echte Client überschreibt sie.
    func fetchBody(messageID: String) async throws -> String
    /// Alle Nachrichten eines Threads (für 3-Spalten-View). Default-Impl: leeres Array.
    func fetchThread(threadID: String, maxMessages: Int) async throws -> [GoogleGmailMessage]
}

public extension GoogleGmailFetching {
    func fetchBody(messageID: String) async throws -> String {
        throw GoogleGmailError.invalidResponse
    }
    func fetchThread(threadID: String, maxMessages: Int) async throws -> [GoogleGmailMessage] { [] }
}

// MARK: - GoogleGmailWriting (S14) — getrennt, damit Lese-Fakes unberührt bleiben.
// NUR Entwürfe anlegen (drafts.create). Versenden ist NICHT enthalten (hartes NO-GO).
// Braucht den gmail.compose-Scope → Google Re-Consent (M2).
public protocol GoogleGmailWriting: Sendable {
    func createDraft(_ draft: EmailDraft) async throws -> String   // gibt Draft-ID zurück
}

// MARK: - GoogleGmailClient
// Liest E-Mails readonly über Gmail API v1. Scope gmail.readonly ist bereits
// in GoogleOAuthScope.readOnlyDefaults enthalten.
public struct GoogleGmailClient: GoogleGmailFetching, GoogleGmailWriting {
    private let tokenProvider: GoogleAccessTokenProviding
    private let session: URLSession
    private let baseURL = "https://gmail.googleapis.com/gmail/v1/users/me/messages"
    private let draftsURL = "https://gmail.googleapis.com/gmail/v1/users/me/drafts"

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

    // MARK: - Volltext-Body lesen (S15)

    public func fetchBody(messageID: String) async throws -> String {
        guard let accessToken = try? await tokenProvider.validAccessToken() else {
            throw GoogleGmailError.notConnected
        }
        guard let url = Self.buildDetailURL(messageID: messageID, baseURL: baseURL) else {
            throw GoogleGmailError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GoogleGmailError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw GoogleGmailError.httpError(http.statusCode) }
        return Self.parseBody(from: data)
    }

    // MARK: - Entwurf anlegen (S14)

    public func createDraft(_ draft: EmailDraft) async throws -> String {
        guard let accessToken = try? await tokenProvider.validAccessToken() else {
            throw GoogleGmailError.notConnected
        }
        guard let url = URL(string: draftsURL) else { throw GoogleGmailError.invalidResponse }
        let raw = Self.base64URL(Data(Self.buildMIMEMultipart(draft).utf8))
        let payload = try JSONSerialization.data(withJSONObject: ["message": ["raw": raw]])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = payload

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GoogleGmailError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw GoogleGmailError.httpError(http.statusCode) }
        let decoded = try? JSONDecoder().decode(GmailDraftResponse.self, from: data)
        return decoded?.id ?? ""
    }

    // MARK: - Reine, testbare Bausteine

    /// RFC822-MIME für einen Entwurf. Subject als RFC2047-Encoded-Word bei Nicht-ASCII,
    /// Body base64-transfer-encoded (UTF-8). Deterministisch + testbar.
    static func buildMIME(_ draft: EmailDraft) -> String {
        var lines: [String] = []
        if let to = draft.to?.trimmingCharacters(in: .whitespacesAndNewlines), to.isEmpty == false {
            lines.append("To: \(to)")
        }
        lines.append("Subject: \(encodeHeader(draft.subject))")
        lines.append("MIME-Version: 1.0")
        lines.append("Content-Type: text/plain; charset=\"UTF-8\"")
        lines.append("Content-Transfer-Encoding: base64")
        lines.append("")
        // Body base64 in 76er-Zeilen (RFC2045).
        let b64 = Data(draft.body.utf8).base64EncodedString()
        lines.append(stride(from: 0, to: b64.count, by: 76).map { i -> String in
            let start = b64.index(b64.startIndex, offsetBy: i)
            let end = b64.index(start, offsetBy: 76, limitedBy: b64.endIndex) ?? b64.endIndex
            return String(b64[start..<end])
        }.joined(separator: "\r\n"))
        return lines.joined(separator: "\r\n")
    }

    /// RFC 2822 multipart/mixed: text/plain body + base64-kodierte Anhänge.
    /// Boundary ist deterministisch aus Subject+Date-Hash (testbar ohne Zufallsquelle).
    static func buildMIMEMultipart(_ draft: EmailDraft) -> String {
        guard !draft.attachments.isEmpty else { return buildMIME(draft) }
        let boundary = "myk_boundary_\(abs(draft.subject.hashValue))"
        var lines: [String] = []
        if let to = draft.to?.trimmingCharacters(in: .whitespacesAndNewlines), !to.isEmpty {
            lines.append("To: \(to)")
        }
        lines.append("Subject: \(encodeHeader(draft.subject))")
        lines.append("MIME-Version: 1.0")
        lines.append("Content-Type: multipart/mixed; boundary=\"\(boundary)\"")
        lines.append("")
        // Body part
        lines.append("--\(boundary)")
        lines.append("Content-Type: text/plain; charset=\"UTF-8\"")
        lines.append("Content-Transfer-Encoding: base64")
        lines.append("")
        let b64Body = Data(draft.body.utf8).base64EncodedString()
        lines.append(stride(from: 0, to: b64Body.count, by: 76).map { i -> String in
            let start = b64Body.index(b64Body.startIndex, offsetBy: i)
            let end = b64Body.index(start, offsetBy: 76, limitedBy: b64Body.endIndex) ?? b64Body.endIndex
            return String(b64Body[start..<end])
        }.joined(separator: "\r\n"))
        // Attachment parts
        for attachment in draft.attachments {
            lines.append("--\(boundary)")
            lines.append("Content-Type: \(attachment.mimeType); name=\"\(attachment.filename)\"")
            lines.append("Content-Transfer-Encoding: base64")
            lines.append("Content-Disposition: attachment; filename=\"\(attachment.filename)\"")
            lines.append("")
            let b64att = attachment.data.base64EncodedString()
            lines.append(stride(from: 0, to: b64att.count, by: 76).map { i -> String in
                let start = b64att.index(b64att.startIndex, offsetBy: i)
                let end = b64att.index(start, offsetBy: 76, limitedBy: b64att.endIndex) ?? b64att.endIndex
                return String(b64att[start..<end])
            }.joined(separator: "\r\n"))
        }
        lines.append("--\(boundary)--")
        return lines.joined(separator: "\r\n")
    }

    // MARK: - Thread lesen (Session B)

    public func fetchThread(threadID: String, maxMessages: Int = 10) async throws -> [GoogleGmailMessage] {
        guard let accessToken = try? await tokenProvider.validAccessToken() else {
            throw GoogleGmailError.notConnected
        }
        let urlStr = "https://gmail.googleapis.com/gmail/v1/users/me/threads/\(threadID)?format=full&maxResults=\(maxMessages)"
        guard let url = URL(string: urlStr) else { throw GoogleGmailError.invalidResponse }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GoogleGmailError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return Self.parseThreadMessages(from: data)
    }

    static func parseThreadMessages(from data: Data) -> [GoogleGmailMessage] {
        struct MsgRes: Decodable {
            var id: String
            var threadId: String?
            var snippet: String?
            var labelIds: [String]?
            var payload: PayloadRes?
            struct PayloadRes: Decodable {
                var headers: [HdrRes]?
            }
            struct HdrRes: Decodable { var name: String; var value: String }
        }
        struct TR: Decodable { var messages: [MsgRes]? }
        guard let tr = try? JSONDecoder().decode(TR.self, from: data) else { return [] }
        return (tr.messages ?? []).map { r in
            let headers = r.payload?.headers ?? []
            let subject = headers.first(where: { $0.name == "Subject" })?.value ?? "(kein Betreff)"
            let fromRaw = headers.first(where: { $0.name == "From" })?.value ?? ""
            let dateStr = headers.first(where: { $0.name == "Date" })?.value
            return GoogleGmailMessage(
                id: r.id,
                threadID: r.threadId ?? "",
                subject: subject,
                from: extractSenderName(from: fromRaw),
                snippet: r.snippet ?? "",
                receivedAt: dateStr.flatMap { parseEmailDate($0) },
                labels: r.labelIds ?? [],
                attachments: []
            )
        }
    }

    /// ASCII-Header bleiben roh; Nicht-ASCII → =?UTF-8?B?…?= (RFC2047).
    static func encodeHeader(_ value: String) -> String {
        if value.allSatisfy({ $0.isASCII }) { return value }
        return "=?UTF-8?B?\(Data(value.utf8).base64EncodedString())?="
    }

    /// base64url ohne Padding — Gmail erwartet `raw` so.
    static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Extrahiert den lesbaren Klartext-Body aus einer format=full-Message: bevorzugt
    /// text/plain, sonst grob entschlackter text/html; rekursiv durch Multipart-Teile.
    static func parseBody(from data: Data) -> String {
        guard let resource = try? JSONDecoder().decode(GmailMessageResource.self, from: data) else { return "" }
        if let plain = firstPart(resource.payload, mime: "text/plain") { return plain }
        if let html = firstPart(resource.payload, mime: "text/html") { return stripHTML(html) }
        return resource.snippet ?? ""
    }

    private static func firstPart(_ payload: GmailPayload?, mime: String) -> String? {
        guard let payload else { return nil }
        if payload.mimeType == mime, let decoded = decodeBodyData(payload.body?.data) { return decoded }
        for part in payload.parts ?? [] {
            if let found = firstPartInPart(part, mime: mime) { return found }
        }
        return nil
    }

    private static func firstPartInPart(_ part: GmailPart, mime: String) -> String? {
        if part.mimeType == mime, let decoded = decodeBodyData(part.body?.data) { return decoded }
        for sub in part.parts ?? [] {
            if let found = firstPartInPart(sub, mime: mime) { return found }
        }
        return nil
    }

    private static func decodeBodyData(_ data: String?) -> String? {
        guard let data, data.isEmpty == false else { return nil }
        var s = data.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while s.count % 4 != 0 { s += "=" }
        guard let bytes = Data(base64Encoded: s) else { return nil }
        return String(data: bytes, encoding: .utf8)
    }

    static func stripHTML(_ html: String) -> String {
        var out = html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        out = out.replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
        return out.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

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
        // format=full: liefert Header + Parts (inkl. Anhänge) statt nur metadata.
        components?.queryItems = [
            URLQueryItem(name: "format", value: "full"),
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

        let attachments = extractAttachments(from: resource.payload?.parts ?? [])

        return GoogleGmailMessage(
            id: resource.id,
            threadID: resource.threadId ?? "",
            subject: subject,
            from: extractSenderName(from: fromRaw),
            snippet: resource.snippet ?? "",
            receivedAt: dateString.flatMap { parseEmailDate($0) },
            labels: resource.labelIds ?? [],
            attachments: attachments
        )
    }

    private static func extractAttachments(from parts: [GmailPart]) -> [GmailAttachment] {
        var result: [GmailAttachment] = []
        for part in parts {
            // Rekursiv in verschachtelten Multipart-Teilen suchen
            if let subParts = part.parts {
                result += extractAttachments(from: subParts)
            }
            guard
                let filename = part.filename, !filename.isEmpty,
                let attachmentID = part.body?.attachmentId, !attachmentID.isEmpty
            else { continue }
            result.append(GmailAttachment(
                attachmentID: attachmentID,
                filename: filename,
                mimeType: part.mimeType ?? "application/octet-stream",
                sizeBytes: part.body?.size ?? 0
            ))
        }
        return result
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
    var threadId: String?
    var snippet: String?
    var payload: GmailPayload?
    var labelIds: [String]?
}

private struct GmailPayload: Decodable {
    var mimeType: String?
    var headers: [GmailHeader]?
    var body: GmailPartBody?
    var parts: [GmailPart]?
}

private struct GmailPart: Decodable {
    var filename: String?
    var mimeType: String?
    var body: GmailPartBody?
    var parts: [GmailPart]?    // verschachtelte Multipart-Teile
}

private struct GmailPartBody: Decodable {
    var attachmentId: String?
    var size: Int?
    var data: String?          // base64url-kodierter Inhalt (S15)
}

private struct GmailDraftResponse: Decodable {
    var id: String?
}

private struct GmailHeader: Decodable {
    var name: String
    var value: String
}
