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
    /// Beide Seiten vorhanden, über Projektnummer verbunden.
    case linked
    /// Nur Mastermind-Routing bekannt (kein Geschäftsprojekt mit dieser Nummer gefunden).
    case routingOnly
    /// Geschäftsprojekt existiert, hat aber keine (oder eine unbekannte) Projektnummer
    /// und kann deshalb nicht verbunden werden — der heutige Normalfall für Intake-Projekte.
    case businessOnlyUnbound
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
