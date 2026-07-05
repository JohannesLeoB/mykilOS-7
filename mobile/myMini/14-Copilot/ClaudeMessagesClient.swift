import Foundation

enum ClaudeClientError: Error, LocalizedError {
    case ungueltigeAntwort
    case serverFehler(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .ungueltigeAntwort: return "Ungültige Antwort von Claude."
        case .serverFehler(let status, let body): return "Claude-Fehler \(status): \(body)"
        }
    }
}

/// ★4 — Claude selbst, im Gespräch. Ruft die Anthropic Messages API direkt vom
/// Gerät auf, mit Johannes' eigenem Key aus dem Schlüsselbund — kein Server
/// dazwischen, genau wie die Mothership-eigene ClaudeMessagesClient-Kopplung.
struct ClaudeMessagesClient {
    static let modell = "claude-sonnet-5"

    private let credentialsStore: ClaudeCredentialsStoring
    private let session: URLSession
    private let apiBase = "https://api.anthropic.com/v1/messages"

    init(
        credentialsStore: ClaudeCredentialsStoring = KeychainClaudeCredentialsStore(),
        session: URLSession = .shared
    ) {
        self.credentialsStore = credentialsStore
        self.session = session
    }

    func antwort(auf verlauf: [ChatMessage], system: String) async throws -> String {
        let credentials = try credentialsStore.load()
        guard let url = URL(string: apiBase) else {
            throw ClaudeClientError.ungueltigeAntwort
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(credentials.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": Self.modell,
            "max_tokens": 1024,
            "system": system,
            "messages": verlauf.map { ["role": $0.rolle.rawValue, "content": $0.text] },
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ClaudeClientError.ungueltigeAntwort
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ClaudeClientError.serverFehler(status: http.statusCode, body: body)
        }

        struct Antwort: Decodable {
            struct Block: Decodable { let type: String; let text: String? }
            let content: [Block]
        }
        let decoded = try JSONDecoder().decode(Antwort.self, from: data)
        return decoded.content.first(where: { $0.type == "text" })?.text ?? ""
    }
}
