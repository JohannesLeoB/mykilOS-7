import Foundation

// MARK: - BusinessCustomer / BusinessProject
// mykilOS 8, Block A: die GESCHÄFTS-Wahrheit aus der Artikel-Base (appdxTeT6bhSBmwx5).
// Bewusst EIGENE Typen, nicht `Customer`/`Project` (Mastermind-Routing) wiederverwendet —
// genau die Vermischung zweier verschiedener Schemas unter einem Typ war die Split-Brain-
// Falle (siehe AIRTABLE_DATENFLUSS_AUDIT.md §3). Feldnamen sind code-verifiziert aus
// `IntakeResultBuilder.mapKundeFelder`/`mapProjektFelder` — das ist der einzige real
// feuernde Schreibpfad in diese Tabellen (Stand 2026-06-30).
public struct BusinessCustomer: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var airtableRecordID: String
    public var nachname: String?
    public var vorname: String?
    public var firma: String?
    public var email: String?
    public var telefon: String?
    public var updatedAt: Date

    public init(
        id: UUID = UUID(), airtableRecordID: String, nachname: String? = nil,
        vorname: String? = nil, firma: String? = nil, email: String? = nil,
        telefon: String? = nil, updatedAt: Date = Date()
    ) {
        self.id = id
        self.airtableRecordID = airtableRecordID
        self.nachname = nachname
        self.vorname = vorname
        self.firma = firma
        self.email = email
        self.telefon = telefon
        self.updatedAt = updatedAt
    }

    /// Menschenlesbarer Anzeigename — Firma bevorzugt, sonst Vor-/Nachname.
    public var displayName: String {
        if let firma, !firma.isEmpty { return firma }
        return [vorname, nachname].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }
}

public struct BusinessProject: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var airtableRecordID: String
    public var projektname: String
    public var projektstatus: String?
    public var budget: Double?
    public var kundeRecordIDs: [String]
    /// JJJJ-NR-Format — existiert in der Artikel-Base `Projekte` HEUTE NICHT als Feld
    /// (Stand 2026-06-30, code-verifiziert). Bleibt `nil`, bis Daniel das Feld ergänzt
    /// oder Block C (Nomenklatur) es beim Anlegen mitschreibt. Solange `nil`: dieses
    /// Geschäftsprojekt ist NICHT über die Registry mit seinem Mastermind-Routing-
    /// Eintrag verknüpfbar — `ExternalMappingRegistry` markiert es `businessOnlyUnbound`.
    public var projectNumber: String?
    public var updatedAt: Date

    public init(
        id: UUID = UUID(), airtableRecordID: String, projektname: String,
        projektstatus: String? = nil, budget: Double? = nil,
        kundeRecordIDs: [String] = [], projectNumber: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.airtableRecordID = airtableRecordID
        self.projektname = projektname
        self.projektstatus = projektstatus
        self.budget = budget
        self.kundeRecordIDs = kundeRecordIDs
        self.projectNumber = projectNumber
        self.updatedAt = updatedAt
    }
}

// MARK: - ResolvedProject
// Das Ergebnis des `ExternalMappingRegistry`-Joins: Routing (Mastermind) + Geschäft
// (Artikel) über die Projektnummer zusammengeführt — NIE geraten, NIE per Namens-Fuzzy-
// Match, nur über den exakten Schlüssel. `bindingState` macht ehrlich sichtbar, wenn
// eine Seite fehlt, statt eine davon stillschweigend als „die Wahrheit" zu behandeln.
public enum ProjectBindingState: String, Codable, Sendable, Equatable {
    /// Beide Seiten vorhanden, über das echte `Projektnummer`-Feld verbunden.
    case linked
    /// Beide Seiten vorhanden, aber NUR über die lokale, manuell bestätigte
    /// Bindungs-Brücke verbunden (kein `Projektnummer`-Feld in Artikel-`Projekte`,
    /// siehe `ProjectNumberBindingStore`) — redundant, ersetzt sich selbst, sobald
    /// das echte Feld existiert (der `linked`-Pfad gewinnt dann automatisch).
    case linkedViaLocalBinding
    /// Nur Mastermind-Routing bekannt (kein Geschäftsprojekt mit dieser Nummer gefunden).
    case routingOnly
    /// Geschäftsprojekt existiert, hat aber keine (oder eine unbekannte) Projektnummer
    /// und kann deshalb nicht verbunden werden — der heutige Normalfall für Intake-Projekte.
    case businessOnlyUnbound
}

// MARK: - ProjectNumberBindingCandidate / ConfirmedProjectNumberBinding
// mykilOS 8, Block A (Erweiterung, 2026-06-30, Johannes-Entscheidung): solange Artikel-
// `Projekte` kein `Projektnummer`-Feld hat (und solange bleibt, bis Daniel es in seiner
// Backend-Hoheit ergänzt — siehe IDEEN_UND_BACKLOG.md), gibt es eine REDUNDANTE, rein
// lokale Brücke: ein Geschäftsprojekt OHNE Nummer wird per exaktem Titel-Match gegen ein
// Mastermind-Routing-Projekt (dessen Nummer aus der Drive-Ordner-Liste stammt) vorgeschlagen
// — NIE automatisch als wahr behandelt, sondern als Kandidat über Karte→Bestätigung→Audit.
// Mehrdeutige Treffer (>1 Routing-Projekt mit demselben Titel) werden NIE vorgeschlagen.
// Rührt die Artikel-Projektliste selbst nie an — die Bindung lebt ausschließlich lokal.
public struct ProjectNumberBindingCandidate: Sendable, Equatable, Identifiable {
    public var id: String { businessRecordID }
    public let businessRecordID: String
    public let businessProjektname: String
    public let projectNumber: String
    public let routingTitle: String

    public init(businessRecordID: String, businessProjektname: String, projectNumber: String, routingTitle: String) {
        self.businessRecordID = businessRecordID
        self.businessProjektname = businessProjektname
        self.projectNumber = projectNumber
        self.routingTitle = routingTitle
    }
}

public struct ConfirmedProjectNumberBinding: Codable, Sendable, Equatable, Identifiable {
    public var id: String { businessRecordID }
    public let businessRecordID: String
    public let projectNumber: String
    public let confirmedAt: Date
    public let actorUserID: String

    public init(businessRecordID: String, projectNumber: String, confirmedAt: Date = Date(), actorUserID: String) {
        self.businessRecordID = businessRecordID
        self.projectNumber = projectNumber
        self.confirmedAt = confirmedAt
        self.actorUserID = actorUserID
    }
}

public struct ResolvedProject: Sendable, Equatable {
    public var projectNumber: String
    public var routing: Project?
    public var business: BusinessProject?
    public var customer: BusinessCustomer?
    public var bindingState: ProjectBindingState

    public init(
        projectNumber: String, routing: Project? = nil, business: BusinessProject? = nil,
        customer: BusinessCustomer? = nil, bindingState: ProjectBindingState
    ) {
        self.projectNumber = projectNumber
        self.routing = routing
        self.business = business
        self.customer = customer
        self.bindingState = bindingState
    }
}
