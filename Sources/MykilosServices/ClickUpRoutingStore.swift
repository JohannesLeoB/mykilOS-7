import Foundation
import Observation
import GRDB
import MykilosKit

// MARK: - ClickUpRoutingRecord (GRDB)
private struct ClickUpRoutingRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "clickUpRouting" }
    var routingID: String
    var ebene: String
    var richtung: String
    var appObjekt: String
    var clickUpObjekt: String
    var trigger: String
    var userScope: String
    var frequenz: String
    var noGo: String?
    var clickUpRef: String?
    var aktiv: Bool
    var optin: Bool
    var updatedAt: Double

    init(from z: ClickUpRoutingZeile, now: Double) {
        routingID = z.routingID; ebene = z.ebene; richtung = z.richtung
        appObjekt = z.appObjekt; clickUpObjekt = z.clickUpObjekt; trigger = z.trigger
        userScope = z.userScope; frequenz = z.frequenz; noGo = z.noGo
        clickUpRef = z.clickUpRef; aktiv = z.aktiv; optin = z.optin; updatedAt = now
    }
    var toDomain: ClickUpRoutingZeile {
        ClickUpRoutingZeile(routingID: routingID, ebene: ebene, richtung: richtung, appObjekt: appObjekt,
            clickUpObjekt: clickUpObjekt, trigger: trigger, userScope: userScope, frequenz: frequenz,
            noGo: noGo, clickUpRef: clickUpRef, aktiv: aktiv, optin: optin)
    }
}

// MARK: - ClickUpRoutingStore
// mykilOS 8, Block D (S4): hält das ClickUp-Routing-GERÜST (Adapter-Schema §9). Seedet die
// Default-Zeilen, falls leer. KEIN echter ClickUp-Write — nur das Daten-/Config-Modell, gegen
// das der künftige Konnektor liest/schreibt (Re-Routing = Zeile ändern, nicht Code).
@MainActor
@Observable
public final class ClickUpRoutingStore {
    public private(set) var zeilen: [ClickUpRoutingZeile] = []
    private let db: GRDBDatabase

    public init(db: GRDBDatabase) { self.db = db }

    public func load() throws {
        let records = try db.read { try ClickUpRoutingRecord.fetchAll($0) }
        if records.isEmpty {
            try seedDefaults()
        } else {
            zeilen = records.map(\.toDomain)
            // Fehlende Default-Zeilen ergänzen (neue Schema-Zeilen ohne Bestehende zu überschreiben).
            try ergaenzeFehlende()
        }
    }

    private func seedDefaults() throws {
        let ts = Date().timeIntervalSince1970
        try db.write { dbc in
            for z in ClickUpRoutingZeile.defaults { try ClickUpRoutingRecord(from: z, now: ts).insert(dbc) }
        }
        zeilen = ClickUpRoutingZeile.defaults
    }

    private func ergaenzeFehlende() throws {
        let vorhanden = Set(zeilen.map(\.routingID))
        let fehlende = ClickUpRoutingZeile.defaults.filter { vorhanden.contains($0.routingID) == false }
        guard fehlende.isEmpty == false else { return }
        let ts = Date().timeIntervalSince1970
        try db.write { dbc in for z in fehlende { try ClickUpRoutingRecord(from: z, now: ts).insert(dbc) } }
        zeilen.append(contentsOf: fehlende)
    }
}
