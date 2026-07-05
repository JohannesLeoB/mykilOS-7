import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

enum GoogleOAuthError: Error, LocalizedError {
    case ungueltigeURL
    case abgebrochen
    case keinCode
    case serverFehler(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .ungueltigeURL: return "Ungültige Google-Anmelde-URL."
        case .abgebrochen: return "Anmeldung abgebrochen."
        case .keinCode: return "Keine Autorisierung von Google erhalten."
        case .serverFehler(let status, let body): return "Google-Fehler \(status): \(body)"
        }
    }
}

struct GoogleTokens {
    let accessToken: String
    let refreshToken: String?
    let ablaufDatum: Date
}

/// PKCE-OAuth-Flow für iOS — `ASWebAuthenticationSession` + Custom-URL-
/// Scheme-Redirect (die "reversed" Client-ID). Der Mothership-Loopback-
/// Server (`GoogleOAuthLoopbackRedirectServer.swift`, 127.0.0.1) ist
/// Desktop/Mac-spezifisch und funktioniert auf iOS nicht — anderer
/// Redirect-Mechanismus, gleiche PKCE-Logik.
///
/// Scope bewusst wie im Mothership-Original gebündelt (nicht nur das
/// schmale drive.file): `drive.metadata.readonly` zum SUCHEN des
/// Kanon-Zielordners (das Auffinden setzt laut Mothership-Code eine
/// Lese-Berechtigung voraus), `drive.file` NUR für den eigentlichen
/// Schreibvorgang. Kein `drive`/volles Drive — das schmale Tor bleibt
/// bestehen, nur der Lese-Teil ist nötig, damit die Suche überhaupt
/// funktioniert (unverifiziert, siehe playbooks/03).
@MainActor
final class GoogleOAuthPKCEService: NSObject {
    static let scope = "https://www.googleapis.com/auth/drive.file https://www.googleapis.com/auth/drive.metadata.readonly"

    private let clientID: String
    private let redirectScheme: String
    private lazy var praesentationsAnker = PraesentationsAnker()
    /// MUSS gehalten werden — ASWebAuthenticationSession wird sonst sofort
    /// wieder freigegeben und der Anmelde-Dialog erscheint nie (bekannte
    /// Falle, kein Sonderfall).
    private var aktiveSession: ASWebAuthenticationSession?

    init(clientID: String) {
        self.clientID = clientID
        // Google verlangt die "reversed" Form der Client-ID als URL-Scheme,
        // z. B. "123-abc.apps.googleusercontent.com" -> "com.googleusercontent.apps.123-abc".
        let kern = clientID.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
        self.redirectScheme = "com.googleusercontent.apps.\(kern)"
    }

    func meldeAn() async throws -> GoogleTokens {
        let verifier = Self.zufallsVerifier()
        let challenge = Self.challenge(fuer: verifier)

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: "\(redirectScheme):/oauth2redirect"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Self.scope),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
        ]
        guard let authURL = components?.url else { throw GoogleOAuthError.ungueltigeURL }

        let callbackURL = try await praesentiere(authURL: authURL)
        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value else {
            throw GoogleOAuthError.keinCode
        }

        return try await tauscheCodeGegenToken(code: code, verifier: verifier)
    }

    func erneuere(refreshToken: String) async throws -> GoogleTokens {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.formEncoded([
            "client_id": clientID,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
        ]).data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw GoogleOAuthError.serverFehler(status: status, body: String(data: data, encoding: .utf8) ?? "")
        }
        struct Antwort: Decodable {
            let access_token: String
            let expires_in: Int
        }
        let decoded = try JSONDecoder().decode(Antwort.self, from: data)
        return GoogleTokens(
            accessToken: decoded.access_token,
            refreshToken: refreshToken,
            ablaufDatum: Date().addingTimeInterval(TimeInterval(decoded.expires_in))
        )
    }

    private func tauscheCodeGegenToken(code: String, verifier: String) async throws -> GoogleTokens {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.formEncoded([
            "client_id": clientID,
            "code": code,
            "code_verifier": verifier,
            "grant_type": "authorization_code",
            "redirect_uri": "\(redirectScheme):/oauth2redirect",
        ]).data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw GoogleOAuthError.serverFehler(status: status, body: String(data: data, encoding: .utf8) ?? "")
        }
        struct Antwort: Decodable {
            let access_token: String
            let refresh_token: String?
            let expires_in: Int
        }
        let decoded = try JSONDecoder().decode(Antwort.self, from: data)
        return GoogleTokens(
            accessToken: decoded.access_token,
            refreshToken: decoded.refresh_token,
            ablaufDatum: Date().addingTimeInterval(TimeInterval(decoded.expires_in))
        )
    }

    private func praesentiere(authURL: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: redirectScheme
            ) { [weak self] url, error in
                self?.aktiveSession = nil
                if let url {
                    continuation.resume(returning: url)
                } else if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                    continuation.resume(throwing: GoogleOAuthError.abgebrochen)
                } else {
                    continuation.resume(throwing: error ?? GoogleOAuthError.abgebrochen)
                }
            }
            session.presentationContextProvider = praesentationsAnker
            session.prefersEphemeralWebBrowserSession = false
            aktiveSession = session
            session.start()
        }
    }

    private static func zufallsVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    private static func challenge(fuer verifier: String) -> String {
        let hash = SHA256.hash(data: Data(verifier.utf8))
        return Data(hash).base64URLEncodedString()
    }

    /// `.urlQueryAllowed` allein lässt „+"/"="/"&" unkodiert — in einem
    /// `application/x-www-form-urlencoded`-Body sind das aber Trennzeichen.
    /// Ein Autorisierungscode, der zufällig eines dieser Zeichen enthält,
    /// würde sonst kaputtgeschnitten. Deshalb ein strengeres, eigenes Set.
    private static let formWertErlaubt = CharacterSet.urlQueryAllowed
        .subtracting(CharacterSet(charactersIn: "+&="))

    private static func formEncoded(_ params: [String: String]) -> String {
        params.map { key, value in
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: formWertErlaubt) ?? value
            return "\(key)=\(encodedValue)"
        }.joined(separator: "&")
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private final class PraesentationsAnker: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? ASPresentationAnchor()
    }
}
