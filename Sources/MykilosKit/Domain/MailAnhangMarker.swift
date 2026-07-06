import Foundation

// MARK: - MailAnhangMarker (2026-07-06)
// Ordner-Schema-Editor-Plan, Abschnitt "Mail-Anhang → Marker → Unterordner": im
// Mail-Anhang-Drive-Dialog kennzeichnet der Nutzer ein Dokument mit einem Marker
// (AB/Rechnung/Zeichnung/…). Der Marker SCHLÄGT den Ziel-Ordner-Slot vor (Schaltschrank-
// Route, kein Hardcode) — die Ablage selbst bleibt bestätigt, nie Auto-Move.
// Foundation-only (MykilosKit-Regel: kein SwiftUI, kein GRDB).
public enum MailAnhangMarker: String, CaseIterable, Codable, Sendable, Identifiable {
    case auftragsbestaetigung
    case rechnung
    case zeichnung
    case angebotAusgehend

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .auftragsbestaetigung: return "AB"
        case .rechnung: return "Rechnung"
        case .zeichnung: return "Zeichnung"
        case .angebotAusgehend: return "Angebot (ausgehend)"
        }
    }
}

// MARK: - MailMarkerRoute — eine gesteckte Brücke Marker → Ordner-Slot
public struct MailMarkerRoute: Codable, Hashable, Sendable, Identifiable {
    public var id: String { routeID }
    /// Stabile Routen-ID.
    public let routeID: String
    public let marker: MailAnhangMarker
    /// mykilOS-Ziel-Klemme (derselbe Slot, den auch das Ordner-Schema/`OrdnerKonnektor` nutzt).
    public let ziel: OrdnerSlot
    /// Stillgelegte Routen werden übersprungen.
    public var aktiv: Bool

    public init(routeID: String, marker: MailAnhangMarker, ziel: OrdnerSlot, aktiv: Bool = true) {
        self.routeID = routeID
        self.marker = marker
        self.ziel = ziel
        self.aktiv = aktiv
    }
}

// MARK: - MailMarkerRouteRegistry — die Verdrahtung als Tabelle, nicht als Code
// ⚠️ Die Defaults sind eine plausible Erst-Vorlage (aus dem Plan: „AB→01 ANGEBOTE",
// „Zeichnung→02 CAD"). Passt eine Zuordnung nicht, wird HIER eine Zeile umgelegt — kein
// UI-/Parser-Umbau. Johannes bestätigt/korrigiert die Zuordnung bei der ersten echten Nutzung.
public struct MailMarkerRouteRegistry: Codable, Sendable {
    public var routes: [MailMarkerRoute]

    public init(routes: [MailMarkerRoute]) {
        self.routes = routes
    }

    public var aktiveRoutes: [MailMarkerRoute] {
        routes.filter(\.aktiv)
    }

    /// Die aktive Route für einen Marker (nil = keine Route, kein Vorschlag).
    public func route(fuer marker: MailAnhangMarker) -> MailMarkerRoute? {
        routes.first { $0.aktiv && $0.marker == marker }
    }

    public static let `default` = MailMarkerRouteRegistry(routes: [
        MailMarkerRoute(routeID: "MAIL_MARKER_AB", marker: .auftragsbestaetigung, ziel: .angeboteEingehend),
        MailMarkerRoute(routeID: "MAIL_MARKER_RECHNUNG", marker: .rechnung, ziel: .angeboteEingehend),
        MailMarkerRoute(routeID: "MAIL_MARKER_ZEICHNUNG", marker: .zeichnung, ziel: .cad),
        MailMarkerRoute(routeID: "MAIL_MARKER_ANGEBOT_AUSGEHEND", marker: .angebotAusgehend, ziel: .angeboteAusgehend)
    ])
}
