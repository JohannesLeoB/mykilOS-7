import Foundation

// MARK: - ProjectKind
// Spiegelt die Projektarten, die im V5-Code schon als ClickUp-Templates lebten.
public enum ProjectKind: String, Codable, Sendable, CaseIterable {
    case kitchen          // Kundenprojekt Standard (große Küchenplanung)
    case lighting         // reine Lichtplanung
    case addendum         // Service / Nachtrag zu altem Projekt
    case lead             // Anfrage / Lead
    case quote            // Angebot / Kalkulation
    case studioInternal   // Studio intern
}

// MARK: - ProjectLinks
// Die Referenzen & Pfade eines Projekts. NIEMALS Secrets — nur IDs und
// lesbare Pfade. Quelle: Airtable-Spalten "Links und Pfade".
public struct ProjectLinks: Codable, Equatable, Sendable {
    public var driveFolderID: String?
    public var driveFolderPath: String?
    public var clickUpListID: String?
    public var calendarQuery: String?
    public var contactsQuery: String?
    public var mailQuery: String?
    public var sevdeskRef: String?

    public init(driveFolderID: String? = nil, driveFolderPath: String? = nil,
                clickUpListID: String? = nil, calendarQuery: String? = nil,
                contactsQuery: String? = nil, mailQuery: String? = nil,
                sevdeskRef: String? = nil) {
        self.driveFolderID = driveFolderID
        self.driveFolderPath = driveFolderPath
        self.clickUpListID = clickUpListID
        self.calendarQuery = calendarQuery
        self.contactsQuery = contactsQuery
        self.mailQuery = mailQuery
        self.sevdeskRef = sevdeskRef
    }
}

// MARK: - Project
// Identität & Spine eines Projekts. Quelle der Wahrheit: Airtable.
public struct Project: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var projectNumber: String          // Kürzel/Nummer — Business-Schlüssel (Airtable)
    public var title: String
    public var kind: ProjectKind
    public var customerNumber: String          // Verweis auf Customer
    public var parentProjectNumber: String?    // Nachtrag → Eltern-Projekt (Airtable-Verknüpfung)
    public var links: ProjectLinks
    public var phase: String?
    public var airtableRecordID: String?
    public var updatedAt: Date

    public var isAddendum: Bool { kind == .addendum || parentProjectNumber != nil }

    public init(id: UUID = UUID(), projectNumber: String, title: String,
                kind: ProjectKind, customerNumber: String,
                parentProjectNumber: String? = nil, links: ProjectLinks = .init(),
                phase: String? = nil, airtableRecordID: String? = nil,
                updatedAt: Date = Date()) {
        self.id = id
        self.projectNumber = projectNumber
        self.title = title
        self.kind = kind
        self.customerNumber = customerNumber
        self.parentProjectNumber = parentProjectNumber
        self.links = links
        self.phase = phase
        self.airtableRecordID = airtableRecordID
        self.updatedAt = updatedAt
    }
}
