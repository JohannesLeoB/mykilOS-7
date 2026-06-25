import Foundation

// MARK: - GoogleTokenRefreshing
public protocol GoogleTokenRefreshing: Sendable {
    func refresh(refreshToken: String, clientID: String) async throws -> GoogleOAuthTokenExchangeResponse
}

// MARK: - GoogleTokenRefreshService
// Tauscht ein Refresh-Token gegen ein neues Access-Token — derselbe
// Token-Endpoint wie der PKCE-Code-Exchange, nur mit grant_type=refresh_token
// und ohne redirect_uri/code_verifier.
public struct GoogleTokenRefreshService: GoogleTokenRefreshing {
    private let tokenEndpoint = "https://oauth2.googleapis.com/token"
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func refresh(refreshToken: String, clientID: String) async throws -> GoogleOAuthTokenExchangeResponse {
        guard let url = URL(string: tokenEndpoint) else {
            throw GoogleOAuthError.invalidEndpoint
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = urlEncodedFormBody([
            "client_id": clientID,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
        ])

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GoogleOAuthError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw GoogleOAuthError.httpError(http.statusCode) }

        do {
            return try JSONDecoder().decode(GoogleOAuthTokenExchangeResponse.self, from: data)
        } catch {
            throw GoogleOAuthError.decodingFailed
        }
    }
}
