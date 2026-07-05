import Foundation

/// Ein Werkzeug, das der Copilot aufrufen darf — Name, Beschreibung (fuer
/// Claude) und ein JSON-Schema der Parameter.
struct CopilotWerkzeugDef {
    let name: String
    let beschreibung: String
    let schema: [String: Any]
}

/// Ein Tool-Use-Aufruf, den Claude zurueckgibt.
struct CopilotToolAufruf {
    let id: String
    let name: String
    let eingabe: [String: Any]
}

/// Das Ergebnis eines Claude-Schritts: entweder Text (fertig) oder
/// Tool-Aufrufe, die erst ausgefuehrt werden muessen.
struct CopilotSchritt {
    let text: String?
    let toolAufrufe: [CopilotToolAufruf]
    /// Der rohe Assistant-Content (Blocks), damit wir ihn 1:1 in den naechsten
    /// Request zuruecklegen koennen (Anthropic verlangt das bei Tool-Use).
    let assistantContent: [[String: Any]]
    var brauchtToolLauf: Bool { !toolAufrufe.isEmpty }
}

enum CopilotClientError: Error, LocalizedError {
    case ungueltigeAntwort
    case serverFehler(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .ungueltigeAntwort: return "Ungueltige Antwort vom Assistenten."
        case .serverFehler(let s, let b): return "Assistent-Fehler \(s): \(b)"
        }
    }
}

/// Der Tool-Use-fähige Claude-Client fuer den Copiloten. Getrennt vom
/// schlanken `ClaudeMessagesClient` (der bleibt fuer den einfachen Chat),
/// weil hier der volle Content-Block-/Tool-Use-Aufbau der Anthropic-API
/// gebraucht wird. Ruft direkt vom Geraet, Key aus dem Schluesselbund.
struct CopilotClient {
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

    var istVerbunden: Bool { (try? credentialsStore.load()) != nil }

    /// Ein Denk-Schritt: schickt den bisherigen Verlauf + Tool-Definitionen,
    /// gibt Text ODER Tool-Aufrufe zurueck.
    func schritt(system: String, verlauf: [[String: Any]], werkzeuge: [CopilotWerkzeugDef]) async throws -> CopilotSchritt {
        let credentials = try credentialsStore.load()
        guard let url = URL(string: apiBase) else { throw CopilotClientError.ungueltigeAntwort }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(credentials.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let toolPayload: [[String: Any]] = werkzeuge.map {
            ["name": $0.name, "description": $0.beschreibung, "input_schema": $0.schema]
        }
        let payload: [String: Any] = [
            "model": Self.modell,
            "max_tokens": 1536,
            "system": system,
            "tools": toolPayload,
            "messages": verlauf,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CopilotClientError.ungueltigeAntwort }
        guard (200...299).contains(http.statusCode) else {
            throw CopilotClientError.serverFehler(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }

        guard let objekt = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = objekt["content"] as? [[String: Any]] else {
            throw CopilotClientError.ungueltigeAntwort
        }

        var text: String?
        var aufrufe: [CopilotToolAufruf] = []
        for block in content {
            switch block["type"] as? String {
            case "text":
                if let t = block["text"] as? String {
                    text = (text ?? "") + t
                }
            case "tool_use":
                if let id = block["id"] as? String, let name = block["name"] as? String {
                    let eingabe = block["input"] as? [String: Any] ?? [:]
                    aufrufe.append(CopilotToolAufruf(id: id, name: name, eingabe: eingabe))
                }
            default:
                break
            }
        }
        return CopilotSchritt(text: text, toolAufrufe: aufrufe, assistantContent: content)
    }
}
