import Foundation

// MARK: - ClickUpProjektMeta (2026-07-06)
// Typisiertes Modell der 13 Projekt-Custom-Fields aus dem ClickUp-Setup
// (docs/handoffs/CLICKUP_DATENINTEGRATION_PLAN.md). Stufe 1: reine Lese-/Modell-Schicht —
// KEIN Schreiben, KEIN Netzwerk. Der Adapter (`ClickUpClient.parseProjektMeta`) hebt die
// generisch dekodierten `custom_fields` in dieses Modell.
//
// Alle Slots sind optional: ClickUp liefert nicht garantiert jedes Feld (frisches Projekt,
// unausgefülltes Feld). Fehlt ein Feld, bleibt der Slot `nil` — nie ein Parse-Fehler.
//
// Foundation-only (MykilosKit-Regel: kein SwiftUI, kein GRDB). Codable + Sendable.
public struct ClickUpProjektMeta: Codable, Equatable, Sendable {
    /// Budget (€) — ClickUp-Typ Currency → Double.
    public var budget: Double?
    /// Angebotsdatum — Timeline-Meilenstein.
    public var angebotsdatum: Date?
    /// Auftragsdatum — Timeline-Meilenstein.
    public var auftragsdatum: Date?
    /// Nächstes Nachfassen — Fälligkeit / Alert-Kandidat.
    public var naechstesNachfassen: Date?
    /// Drive-Ordner — URL zur Projektakte (spiegelt später `Project.driveFolderID`).
    public var driveOrdner: String?
    /// Kunde — Klartext-Kundenbezug (spiegelt später `Project.customer`).
    public var kunde: String?
    /// Kunde-Token — interne, stabile Kunden-Referenz.
    public var kundeToken: String?
    /// Projekttyp — Dropdown-Klartext (spiegelt später `Project.kind`).
    public var projekttyp: String?
    /// Ort — Projekt-Metadatum.
    public var ort: String?
    /// Lead — Projekt-Verantwortlicher (Klartext-Name/Kürzel, nie ein echtes Assignment).
    public var lead: String?
    /// Lieferanten — Labels (multi) → Liste von Klartext-Werten.
    public var lieferanten: [String]?
    /// Risiko/Engpass — Dropdown-Klartext → Status-Signal / Alert-Kandidat.
    public var risikoEngpass: String?
    /// Slack-Channel — Projekt-Link (Text/URL).
    public var slackChannel: String?

    public init(
        budget: Double? = nil,
        angebotsdatum: Date? = nil,
        auftragsdatum: Date? = nil,
        naechstesNachfassen: Date? = nil,
        driveOrdner: String? = nil,
        kunde: String? = nil,
        kundeToken: String? = nil,
        projekttyp: String? = nil,
        ort: String? = nil,
        lead: String? = nil,
        lieferanten: [String]? = nil,
        risikoEngpass: String? = nil,
        slackChannel: String? = nil
    ) {
        self.budget = budget
        self.angebotsdatum = angebotsdatum
        self.auftragsdatum = auftragsdatum
        self.naechstesNachfassen = naechstesNachfassen
        self.driveOrdner = driveOrdner
        self.kunde = kunde
        self.kundeToken = kundeToken
        self.projekttyp = projekttyp
        self.ort = ort
        self.lead = lead
        self.lieferanten = lieferanten
        self.risikoEngpass = risikoEngpass
        self.slackChannel = slackChannel
    }

    /// Leeres Meta — kein einziges Feld gesetzt. Der ehrliche Default, wenn ClickUp nichts liefert.
    public static let empty = ClickUpProjektMeta()

    /// `true`, wenn kein einziger Slot befüllt ist (nützlich für „nichts anzuzeigen"-Zustände).
    public var isEmpty: Bool { self == ClickUpProjektMeta.empty }
}

// MARK: - ClickUpMetaSlot — die festen Klemmen-Nummern
// Der Schaltschrank (docs/PRINZIP_SCHALTSCHRANK.md): jede Klemme hat eine STABILE ID, nie den
// Klartext-Namen als Schlüssel. `ClickUpMetaSlot` ist das Ziel-Register — die 13 Klemmen, auf
// die eine ClickUp-Ader gelegt werden kann. Umlegen = Route-Zeile ändern (unten), nicht dieses
// Modell umbauen. Der Rohwert ist eine stabile Konstante (nie umbenennen — er ist die ID).
public enum ClickUpMetaSlot: String, CaseIterable, Codable, Sendable {
    case budget
    case angebotsdatum
    case auftragsdatum
    case naechstesNachfassen
    case driveOrdner
    case kunde
    case kundeToken
    case projekttyp
    case ort
    case lead
    case lieferanten
    case risikoEngpass
    case slackChannel

    /// Welcher Werttyp gehört auf diese Klemme? Der Parser nutzt das, um den generischen
    /// Rohwert tolerant in den richtigen Swift-Typ zu heben (Currency→Double, Date→Date, …).
    public enum Kind: Sendable {
        case zahl        // Double  (Currency)
        case datum       // Date    (ClickUp: Epoch-Millisekunden)
        case text        // String  (Text / URL / Dropdown-Label)
        case textListe   // [String] (Labels multi)
    }

    public var kind: Kind {
        switch self {
        case .budget:
            return .zahl
        case .angebotsdatum, .auftragsdatum, .naechstesNachfassen:
            return .datum
        case .lieferanten:
            return .textListe
        case .driveOrdner, .kunde, .kundeToken, .projekttyp, .ort, .lead,
             .risikoEngpass, .slackChannel:
            return .text
        }
    }

    // Ziel-Speicherort als Key-Path — die „welche Klemme schreibt welches Feld"-Zuordnung als
    // DATEN am Slot, nicht als Verzweigung im Parser (hält den Mapper klein + eindeutig). Genau
    // einer der vier Key-Paths ist je Slot gesetzt, passend zu `kind`.
    public var doubleKeyPath: WritableKeyPath<ClickUpProjektMeta, Double?>? {
        switch self {
        case .budget: return \.budget
        default:      return nil
        }
    }

    public var dateKeyPath: WritableKeyPath<ClickUpProjektMeta, Date?>? {
        switch self {
        case .angebotsdatum:       return \.angebotsdatum
        case .auftragsdatum:       return \.auftragsdatum
        case .naechstesNachfassen: return \.naechstesNachfassen
        default:                   return nil
        }
    }

    public var textKeyPath: WritableKeyPath<ClickUpProjektMeta, String?>? {
        switch self {
        case .driveOrdner:   return \.driveOrdner
        case .kunde:         return \.kunde
        case .kundeToken:    return \.kundeToken
        case .projekttyp:    return \.projekttyp
        case .ort:           return \.ort
        case .lead:          return \.lead
        case .risikoEngpass: return \.risikoEngpass
        case .slackChannel:  return \.slackChannel
        default:             return nil
        }
    }

    public var listKeyPath: WritableKeyPath<ClickUpProjektMeta, [String]?>? {
        switch self {
        case .lieferanten: return \.lieferanten
        default:           return nil
        }
    }
}

// MARK: - ClickUpFieldRoute — eine gesteckte Brücke
// Eine Zeile der Routing-Tabelle: „lege die ClickUp-Ader `quelle` auf die Klemme `ziel`".
// `quelle` ist der ClickUp-Feldname als STABILE Referenz (tolerant: Namen ändern sich selten,
// und wenn doch, wird HIER eine Zeile umgelegt — nicht der Parser umgeschrieben). `aktiv`
// erlaubt das Stilllegen einer Route ohne sie zu löschen.
public struct ClickUpFieldRoute: Codable, Hashable, Sendable, Identifiable {
    public var id: String { routeID }
    /// Stabile Routen-ID (die „Nummer der Brücke").
    public let routeID: String
    /// ClickUp-Custom-Field-Name (die Quell-Ader).
    public let quelle: String
    /// mykilOS-Ziel-Klemme.
    public let ziel: ClickUpMetaSlot
    /// Stillgelegte Routen werden vom Parser übersprungen.
    public var aktiv: Bool

    public init(routeID: String, quelle: String, ziel: ClickUpMetaSlot, aktiv: Bool = true) {
        self.routeID = routeID
        self.quelle = quelle
        self.ziel = ziel
        self.aktiv = aktiv
    }
}

// MARK: - ClickUpFieldRouteRegistry — die Verdrahtung als Tabelle, nicht als Code
// Die umsteckbare Routing-Tabelle. `default` ist der aktuelle Stand; eine spätere Session
// (oder ein Admin-Editor) kann Zeilen umlegen/ergänzen, ohne den Parser anzufassen.
//
// ⚠️ Feldnamen als Referenz — die exakten LIVE-Slugs bestätigt Johannes:
// Das Setup (`mykilos_clickup_build.json`) beschreibt die Felder mit deutschen LABELS
// („Budget (€)", „Nächstes Nachfassen"). Der reale `custom_fields[].name`, den die ClickUp-API
// liefert, kann davon abweichen (Slug vs. Label). Genau dafür ist der Schaltschrank da: stimmt
// ein Name live nicht, wird HIER eine `quelle` angepasst — eine Zeile, kein Parser-Umbau.
// Die Defaults nutzen die deutschen Labels aus dem Plan als beste bekannte Referenz.
public struct ClickUpFieldRouteRegistry: Codable, Sendable {
    public var routes: [ClickUpFieldRoute]

    public init(routes: [ClickUpFieldRoute]) {
        self.routes = routes
    }

    /// Nur die aktiven Routen (die der Parser tatsächlich steckt).
    public var aktiveRoutes: [ClickUpFieldRoute] {
        routes.filter(\.aktiv)
    }

    /// Die aktive Route, deren Quell-Feldname exakt `feldName` ist (nil = keine).
    public func route(fuerQuelle feldName: String) -> ClickUpFieldRoute? {
        routes.first { $0.aktiv && $0.quelle == feldName }
    }

    /// Der Standard-Schaltschrank für den Projekt-Meta-Übertrag: 13 Klemmen, je eine Route.
    /// Reihenfolge = Bau-Tabelle aus CLICKUP_DATENINTEGRATION_PLAN.
    public static let `default` = ClickUpFieldRouteRegistry(routes: [
        ClickUpFieldRoute(routeID: "CU_META_BUDGET", quelle: "Budget (€)", ziel: .budget),
        ClickUpFieldRoute(routeID: "CU_META_ANGEBOTSDATUM", quelle: "Angebotsdatum", ziel: .angebotsdatum),
        ClickUpFieldRoute(routeID: "CU_META_AUFTRAGSDATUM", quelle: "Auftragsdatum", ziel: .auftragsdatum),
        ClickUpFieldRoute(routeID: "CU_META_NACHFASSEN", quelle: "Nächstes Nachfassen", ziel: .naechstesNachfassen),
        ClickUpFieldRoute(routeID: "CU_META_DRIVE", quelle: "Drive-Ordner", ziel: .driveOrdner),
        ClickUpFieldRoute(routeID: "CU_META_KUNDE", quelle: "Kunde", ziel: .kunde),
        ClickUpFieldRoute(routeID: "CU_META_KUNDE_TOKEN", quelle: "Kunde-Token", ziel: .kundeToken),
        ClickUpFieldRoute(routeID: "CU_META_PROJEKTTYP", quelle: "Projekttyp", ziel: .projekttyp),
        ClickUpFieldRoute(routeID: "CU_META_ORT", quelle: "Ort", ziel: .ort),
        ClickUpFieldRoute(routeID: "CU_META_LEAD", quelle: "Lead", ziel: .lead),
        ClickUpFieldRoute(routeID: "CU_META_LIEFERANTEN", quelle: "Lieferanten", ziel: .lieferanten),
        ClickUpFieldRoute(routeID: "CU_META_RISIKO", quelle: "Risiko/Engpass", ziel: .risikoEngpass),
        ClickUpFieldRoute(routeID: "CU_META_SLACK", quelle: "Slack-Channel", ziel: .slackChannel)
    ])
}
