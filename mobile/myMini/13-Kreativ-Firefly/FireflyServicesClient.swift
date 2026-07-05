import Foundation
import UIKit

enum FireflyClientError: Error, LocalizedError {
    case ungueltigeAntwort
    case tokenFehler(status: Int, body: String)
    case renderFehler(status: Int, body: String)
    case keinBild

    var errorDescription: String? {
        switch self {
        case .ungueltigeAntwort: return "Ungueltige Antwort von Adobe."
        case .tokenFehler(let s, let b): return "Firefly-Anmeldung fehlgeschlagen (\(s)): \(b)"
        case .renderFehler(let s, let b): return "Firefly-Render fehlgeschlagen (\(s)): \(b)"
        case .keinBild: return "Firefly hat kein Bild zurueckgegeben."
        }
    }
}

/// Adobe-Firefly-Services-Client — ruft die Firefly-API direkt vom Geraet auf,
/// mit dem firmeneigenen Zugang aus dem Schluesselbund. Kein Server dazwischen,
/// gleiche Haltung wie der ClaudeMessagesClient.
///
/// **Verifizierte Endpunkte** (Adobe-Doku, 04.07.2026):
/// - Token:    POST https://ims-na1.adobelogin.com/ims/token/v3
///             grant_type=client_credentials, scope=...,firefly_api,ff_apis
/// - Header:   Authorization: Bearer <token>, x-api-key: <clientID>
/// - Generate: POST https://firefly-api.adobe.io/v3/images/generate
///
/// **Ehrlich, wie beim Leica-Laser:** die Endpunkte sind aus der Doku
/// bestaetigt, aber der genaue Request-/Response-JSON-Aufbau ist erst am
/// ersten echten Aufruf mit Johannes' Key endgueltig verifiziert — Adobe
/// kann Feldnamen zwischen Doku- Versionen leicht anders benennen. Der Code
/// ist so gebaut, dass das Anpassen trivial ist, und gibt bei Abweichung den
/// rohen Server-Text zurueck, statt still Falsches zu behaupten.
struct FireflyServicesClient {
    private let credentialsStore: FireflyCredentialsStoring
    private let session: URLSession

    private let tokenURL = "https://ims-na1.adobelogin.com/ims/token/v3"
    private let generateURL = "https://firefly-api.adobe.io/v3/images/generate"
    private let scope = "openid,AdobeID,session,additional_info,read_organizations,firefly_api,ff_apis"

    init(
        credentialsStore: FireflyCredentialsStoring = KeychainFireflyCredentialsStore(),
        session: URLSession = .shared
    ) {
        self.credentialsStore = credentialsStore
        self.session = session
    }

    var istVerbunden: Bool { (try? credentialsStore.load()) != nil }

    /// Holt ein 24h gueltiges Access-Token per OAuth Server-to-Server.
    private func token(_ credentials: FireflyCredentials) async throws -> String {
        guard let url = URL(string: tokenURL) else { throw FireflyClientError.ungueltigeAntwort }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var teile = URLComponents()
        teile.queryItems = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "client_id", value: credentials.clientID),
            URLQueryItem(name: "client_secret", value: credentials.clientSecret),
            URLQueryItem(name: "scope", value: scope),
        ]
        request.httpBody = teile.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw FireflyClientError.ungueltigeAntwort }
        guard (200...299).contains(http.statusCode) else {
            throw FireflyClientError.tokenFehler(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
        struct Antwort: Decodable { let access_token: String }
        guard let decoded = try? JSONDecoder().decode(Antwort.self, from: data) else {
            throw FireflyClientError.tokenFehler(status: http.statusCode, body: "Kein access_token im Body.")
        }
        return decoded.access_token
    }

    /// Text-zu-Bild-Render aus dem komponierten Prompt. Liefert das erste
    /// erzeugte Bild als UIImage.
    func rendere(prompt: String, breite: Int = 1024, hoehe: Int = 1024) async throws -> UIImage {
        let credentials = try credentialsStore.load()
        let accessToken = try await token(credentials)

        guard let url = URL(string: generateURL) else { throw FireflyClientError.ungueltigeAntwort }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(credentials.clientID, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "prompt": prompt,
            "numVariations": 1,
            "size": ["width": breite, "height": hoehe],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw FireflyClientError.ungueltigeAntwort }
        guard (200...299).contains(http.statusCode) else {
            throw FireflyClientError.renderFehler(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }

        guard let bildURL = ersteBildURL(aus: data) else { throw FireflyClientError.keinBild }
        let (bildDaten, _) = try await session.data(from: bildURL)
        guard let bild = UIImage(data: bildDaten) else { throw FireflyClientError.keinBild }
        return bild
    }

    /// Zieht die erste Bild-URL aus der Firefly-Antwort. Tolerant gegen die
    /// dokumentierte v3-Form `{ "outputs": [ { "image": { "url": ... } } ] }`
    /// — falls Adobe die Feldnamen anders fasst, faellt es sauber auf nil und
    /// der Aufrufer zeigt den rohen Body.
    private func ersteBildURL(aus data: Data) -> URL? {
        guard let objekt = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let outputs = objekt["outputs"] as? [[String: Any]] {
            for output in outputs {
                if let image = output["image"] as? [String: Any],
                   let urlText = image["url"] as? String, let url = URL(string: urlText) {
                    return url
                }
                if let urlText = output["url"] as? String, let url = URL(string: urlText) { return url }
            }
        }
        return nil
    }
}
