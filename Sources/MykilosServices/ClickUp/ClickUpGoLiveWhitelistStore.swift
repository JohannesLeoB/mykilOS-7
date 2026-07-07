import Foundation
import Observation
import GRDB
import MykilosKit

// MARK: - ClickUpGoLiveWhitelistRow
private struct ClickUpGoLiveWhitelistRow: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "clickUpGoLiveWhitelist" }
    var listID: String
    var projektNummer: String
    var freigegebenVon: String
    var freigegebenAm: Double
}

// MARK: - ClickUpGoLiveWhitelistStore (ClickUp-Vollintegration S10, 2026-07-07)
// Go-Live ist eine WHITELIST konkreter Listen-IDs, KEIN Bool-Toggle (ADMIN_EBENE_BAUPLAN.md,
// CLICKUP_IO_ARCHITEKTUR_PLAN.md S10) — jede Freischaltung ist admin-only (Store-Gate, gleiche
// Linie wie NomenklaturStore/AppState.einladungErstellen) und einzeln auditiert. Leer, bis ein
// Admin explizit eine Liste freischaltet — "kein Nebeneffekt-Kippen": eine allgemeine Bau-
// Ansage öffnet nie automatisch eine echte Produktivliste.
@MainActor
@Observable
public final class ClickUpGoLiveWhitelistStore {
    /// listID → projektNummer (für Anzeige).
    public private(set) var freigegebeneListen: [String: String] = [:]
    public private(set) var saveState: SaveState = .idle

    private let db: GRDBDatabase
    private let adminAuthority: any AdminAuthorizing
    private let audit: AuditStore

    public init(db: GRDBDatabase, audit: AuditStore, adminAuthority: any AdminAuthorizing = AllowlistAdminAuthority()) {
        self.db = db
        self.audit = audit
        self.adminAuthority = adminAuthority
    }

    public func load() throws {
        let rows = try db.read { try ClickUpGoLiveWhitelistRow.fetchAll($0) }
        freigegebeneListen = Dictionary(uniqueKeysWithValues: rows.map { ($0.listID, $0.projektNummer) })
    }

    /// Genau die Listen-IDs, die `ClickUpWriteGate` als Go-Live-freigegeben akzeptiert.
    public var listIDs: Set<String> { Set(freigegebeneListen.keys) }

    /// Store-Gate S10: `assertAdmin` als erste Zeile, vor jedem Schreiben. Bei Erfolg ein
    /// Audit-Eintrag mit der verifizierten `googleEmail` als Actor.
    public func freischalten(
        listID: String, projektNummer: String, ausgeloestVon identity: ResidentIdentity?, tokenPresent: Bool
    ) throws {
        try adminAuthority.assertAdmin(identity, tokenPresent: tokenPresent, funktion: "ClickUp-Liste Go-Live freischalten")
        let ts = Date().timeIntervalSince1970
        let actor = identity?.googleEmail ?? "unbekannt"
        saveState = .saving
        do {
            try db.write { dbc in
                try ClickUpGoLiveWhitelistRow(
                    listID: listID, projektNummer: projektNummer,
                    freigegebenVon: actor, freigegebenAm: ts
                ).save(dbc)
            }
            try audit.append(AuditEntry(
                actorUserID: actor, projectID: projektNummer, action: .clickUpGoLiveFreigegeben,
                summary: "ClickUp-Liste \(listID) Go-Live freigeschaltet", quelle: "clickup-golive"))
            freigegebeneListen[listID] = projektNummer
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }

    /// Store-Gate S10 — Sperren ist genauso admin-only wie Freischalten.
    public func sperren(listID: String, ausgeloestVon identity: ResidentIdentity?, tokenPresent: Bool) throws {
        try adminAuthority.assertAdmin(identity, tokenPresent: tokenPresent, funktion: "ClickUp-Liste Go-Live sperren")
        let projektNummer = freigegebeneListen[listID] ?? listID
        let actor = identity?.googleEmail ?? "unbekannt"
        saveState = .saving
        do {
            try db.write { dbc in _ = try ClickUpGoLiveWhitelistRow.deleteOne(dbc, key: listID) }
            try audit.append(AuditEntry(
                actorUserID: actor, projectID: projektNummer, action: .clickUpGoLiveGesperrt,
                summary: "ClickUp-Liste \(listID) Go-Live gesperrt", quelle: "clickup-golive"))
            freigegebeneListen[listID] = nil
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }
}
