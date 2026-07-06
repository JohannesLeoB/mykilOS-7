import Foundation

// MARK: - ClickUpProjektTypRoute (Backlog: "ClickUp als Quelle für ProjectKind")
// Live-Wiring-Session 1 (2026-06-27): Drive-Ordnernamen lassen ProjectKind (kitchen/lighting/
// addendum/lead/quote/studioInternal) nicht erkennen. ClickUpProjektMeta.projekttyp (Dropdown-
// Klartext) soll das laut eigenem Kommentar später spiegeln — hier die Schaltschrank-Route
// dafür, gleiches Muster wie ClickUpFieldRouteRegistry/MailMarkerRouteRegistry: Umlegen =
// Route-Zeile ändern, kein Parser-Umbau.
//
// ⚠️ Die Default-Labels sind eine plausible Erst-Vorlage (deutsche Klartexte passend zu den
// ProjectKind-Fällen). Die exakten ClickUp-Dropdown-Werte bestätigt Johannes bei der ersten
// echten Nutzung — genau dafür ist die Registry da: eine Zeile anpassen, kein Code-Umbau.
public struct ClickUpProjektTypRoute: Codable, Hashable, Sendable, Identifiable {
    public var id: String { routeID }
    public let routeID: String
    /// ClickUp-"Projekttyp"-Dropdown-Label (die Quelle).
    public let quelle: String
    public let ziel: ProjectKind
    public var aktiv: Bool

    public init(routeID: String, quelle: String, ziel: ProjectKind, aktiv: Bool = true) {
        self.routeID = routeID
        self.quelle = quelle
        self.ziel = ziel
        self.aktiv = aktiv
    }
}

public struct ClickUpProjektTypRouteRegistry: Codable, Sendable {
    public var routes: [ClickUpProjektTypRoute]

    public init(routes: [ClickUpProjektTypRoute]) {
        self.routes = routes
    }

    /// Der ProjectKind für einen ClickUp-Projekttyp-Klartext (nil = kein Treffer, kein Vorschlag).
    /// Groß-/Kleinschreibung-tolerant (ClickUp-Dropdowns variieren erfahrungsgemäß darin).
    public func kind(fuerProjekttyp projekttyp: String?) -> ProjectKind? {
        guard let projekttyp, projekttyp.isEmpty == false else { return nil }
        return routes.first { $0.aktiv && $0.quelle.caseInsensitiveCompare(projekttyp) == .orderedSame }?.ziel
    }

    public static let `default` = ClickUpProjektTypRouteRegistry(routes: [
        ClickUpProjektTypRoute(routeID: "CU_TYP_KUECHE", quelle: "Küche", ziel: .kitchen),
        ClickUpProjektTypRoute(routeID: "CU_TYP_LICHT", quelle: "Licht", ziel: .lighting),
        ClickUpProjektTypRoute(routeID: "CU_TYP_NACHTRAG", quelle: "Nachtrag", ziel: .addendum),
        ClickUpProjektTypRoute(routeID: "CU_TYP_LEAD", quelle: "Lead", ziel: .lead),
        ClickUpProjektTypRoute(routeID: "CU_TYP_ANGEBOT", quelle: "Angebot", ziel: .quote),
        ClickUpProjektTypRoute(routeID: "CU_TYP_INTERN", quelle: "Intern", ziel: .studioInternal)
    ])
}
