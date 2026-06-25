import Foundation

// MARK: - GoogleCalendarEvent
public struct GoogleCalendarEvent: Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var startsAt: Date?
    public var isAllDay: Bool
    public var location: String?

    public init(id: String, title: String, startsAt: Date?, isAllDay: Bool, location: String?) {
        self.id = id
        self.title = title
        self.startsAt = startsAt
        self.isAllDay = isAllDay
        self.location = location
    }
}

// MARK: - GoogleCalendarError
public enum GoogleCalendarError: Error, Sendable, Equatable {
    case notConnected
    case invalidResponse
    case httpError(Int)
    case decodingFailed
}

// MARK: - GoogleCalendarFetching
public protocol GoogleCalendarFetching: Sendable {
    func listUpcomingEvents(query: String?, withinDays: Int) async throws -> [GoogleCalendarEvent]
}

// MARK: - GoogleCalendarClient
// Liest Termine vom primären Kalender des verbundenen Accounts, gefiltert
// über `q` (Freitext) — das ist genau, was Project.links.calendarQuery trägt:
// eine Suche über den primären Kalender, keine eigene Kalender-ID je Projekt.
public struct GoogleCalendarClient: GoogleCalendarFetching {
    private let tokenProvider: GoogleAccessTokenProviding
    private let session: URLSession
    private let baseURL = "https://www.googleapis.com/calendar/v3/calendars/primary/events"

    public init(
        tokenProvider: GoogleAccessTokenProviding = GoogleAccessTokenProvider(),
        session: URLSession = .shared
    ) {
        self.tokenProvider = tokenProvider
        self.session = session
    }

    public func listUpcomingEvents(query: String?, withinDays: Int = 14) async throws -> [GoogleCalendarEvent] {
        guard let accessToken = try? await tokenProvider.validAccessToken() else {
            throw GoogleCalendarError.notConnected
        }
        guard let url = Self.buildListEventsURL(query: query, withinDays: withinDays, baseURL: baseURL, now: Date()) else {
            throw GoogleCalendarError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GoogleCalendarError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw GoogleCalendarError.httpError(http.statusCode) }

        return try Self.parseEvents(from: data)
    }

    // MARK: - Reine, testbare Bausteine (kein Netzwerk/Keychain)

    static func buildListEventsURL(query: String?, withinDays: Int, baseURL: String, now: Date) -> URL? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let timeMax = now.addingTimeInterval(TimeInterval(withinDays) * 86_400)

        var queryItems = [
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "timeMin", value: isoFormatter.string(from: now)),
            URLQueryItem(name: "timeMax", value: isoFormatter.string(from: timeMax)),
            URLQueryItem(name: "maxResults", value: "20"),
        ]
        if let query, query.isEmpty == false {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }

        var components = URLComponents(string: baseURL)
        components?.queryItems = queryItems
        return components?.url
    }

    static func parseEvents(from data: Data) throws -> [GoogleCalendarEvent] {
        do {
            let decoded = try JSONDecoder().decode(GoogleCalendarListResponse.self, from: data)
            let dateTimeFormatter = ISO8601DateFormatter()
            dateTimeFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateTimeFormatterNoFraction = ISO8601DateFormatter()
            dateTimeFormatterNoFraction.formatOptions = [.withInternetDateTime]
            let dateOnlyFormatter = DateFormatter()
            dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
            dateOnlyFormatter.timeZone = TimeZone(identifier: "UTC")

            return decoded.items.map { entry in
                let isAllDay = entry.start?.dateTime == nil
                let startsAt: Date? = if let raw = entry.start?.dateTime {
                    dateTimeFormatter.date(from: raw) ?? dateTimeFormatterNoFraction.date(from: raw)
                } else if let raw = entry.start?.date {
                    dateOnlyFormatter.date(from: raw)
                } else {
                    nil
                }
                return GoogleCalendarEvent(
                    id: entry.id,
                    title: entry.summary ?? "(ohne Titel)",
                    startsAt: startsAt,
                    isAllDay: isAllDay,
                    location: entry.location
                )
            }
        } catch {
            throw GoogleCalendarError.decodingFailed
        }
    }
}

private struct GoogleCalendarListResponse: Decodable {
    var items: [GoogleCalendarEventEntry]
}

private struct GoogleCalendarEventEntry: Decodable {
    var id: String
    var summary: String?
    var location: String?
    var start: GoogleCalendarEventDateTime?
}

private struct GoogleCalendarEventDateTime: Decodable {
    var date: String?
    var dateTime: String?
}
