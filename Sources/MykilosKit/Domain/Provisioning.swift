import Foundation

// MARK: - ProvisioningPlan
// mykilOS 8, Block D (S4): was bei einer Projekt-Geburt entstehen soll. Eine bestätigte
// Karte → ein Plan → Mehrsystem-Anlage (Drive-Ordnerbaum + Airtable-Record), idempotent
// über Kdnr + Projektnummer. Rein lokal beschrieben; die Ausführung (echte Writes) läuft
// gated über den ProjektProvisioningService (TEST-Sandbox, WriteShadow, Audit).
public struct ProvisioningPlan: Sendable, Equatable {
    public let projektnummer: Projektnummer
    public let kdnr: String
    public let kundeName: String
    /// Der reale Projektordner-Name `JJJJ_NNN_Kunde_STR-Nr` (aus Nummer + Kunde + STR-Nr).
    public let ordnerName: String
    /// Felder für den Airtable-Projekt-Record (Feldname → Wert). TEST-Marker fügt der Service hinzu.
    public let airtableFelder: [String: String]
    /// Das aktive Ordnerschema (FolderSchema v1) — bestimmt den Unterordnerbaum.
    public let schema: FolderSchema

    public init(projektnummer: Projektnummer, kdnr: String, kundeName: String,
                ordnerName: String, airtableFelder: [String: String], schema: FolderSchema) {
        self.projektnummer = projektnummer
        self.kdnr = kdnr
        self.kundeName = kundeName
        self.ordnerName = ordnerName
        self.airtableFelder = airtableFelder
        self.schema = schema
    }

    /// Idempotenz-Schlüssel: ein Plan ist eindeutig durch Kdnr + Projektnummer.
    public var idempotenzSchluessel: String { "\(kdnr)::\(projektnummer.appFormat)" }
}

// MARK: - ProvisioningStep / ProvisioningStatus
// Welche Teilschritte eine Geburt hat — für Teilfehler-Festigkeit + Wiederaufnahme.
// Die Projektnummern-Reservierung ist VORBEDINGUNG (die UI ruft NumberAuthority.nextAndReserve,
// bevor sie den Plan baut) — der Service orchestriert nur die externen Writes.
public enum ProvisioningStep: String, Codable, Sendable, CaseIterable {
    case driveOrdnerbaum
    case airtableRecord
}

public enum ProvisioningStatus: String, Codable, Sendable, Equatable {
    case offen          // noch nichts getan
    case teilweise      // einige Schritte erledigt (Wiederaufnahme möglich)
    case vollstaendig   // alle Schritte erledigt
    case fehler         // letzter Lauf brach ab (Wiederaufnahme möglich)
}

// MARK: - ProvisioningResult
// Was tatsächlich entstanden ist (für Audit + Wiederaufnahme + UI). Hält die echten
// IDs (Drive-Ordner, Airtable-Record), damit ein zweiter Lauf nichts dupliziert.
public struct ProvisioningResult: Codable, Sendable, Equatable {
    public var idempotenzSchluessel: String
    public var projektnummer: String       // appFormat
    public var kdnr: String
    public var status: ProvisioningStatus
    public var erledigteSchritte: Set<ProvisioningStep>
    public var driveProjektOrdnerID: String?
    public var driveUnterordnerIDs: [String: String]   // relativerPfad → Folder-ID
    public var airtableRecordID: String?
    public var letzterFehler: String?
    public var updatedAt: Date

    public init(
        idempotenzSchluessel: String, projektnummer: String, kdnr: String,
        status: ProvisioningStatus = .offen, erledigteSchritte: Set<ProvisioningStep> = [],
        driveProjektOrdnerID: String? = nil, driveUnterordnerIDs: [String: String] = [:],
        airtableRecordID: String? = nil, letzterFehler: String? = nil, updatedAt: Date = Date()
    ) {
        self.idempotenzSchluessel = idempotenzSchluessel
        self.projektnummer = projektnummer
        self.kdnr = kdnr
        self.status = status
        self.erledigteSchritte = erledigteSchritte
        self.driveProjektOrdnerID = driveProjektOrdnerID
        self.driveUnterordnerIDs = driveUnterordnerIDs
        self.airtableRecordID = airtableRecordID
        self.letzterFehler = letzterFehler
        self.updatedAt = updatedAt
    }

    public func hat(_ step: ProvisioningStep) -> Bool { erledigteSchritte.contains(step) }
}

// MARK: - ProvisioningError
public enum ProvisioningError: Error, Sendable, Equatable {
    case writeGateGesperrt            // ProvisioningMode != .test/.prod-Freigabe
    case driveNichtVerbunden
    case airtableNichtVerbunden
    case schrittFehlgeschlagen(ProvisioningStep, String)
    case ungueltigerPlan(String)
}
