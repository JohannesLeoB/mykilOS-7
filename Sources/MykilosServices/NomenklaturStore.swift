import Foundation
import Observation
import GRDB
import MykilosKit

// MARK: - GRDB-Records
private struct OrdnerKonnektorRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "ordnerKonnektoren" }
    var slot: String
    var ordnername: String
    var relativerPfad: String
    var schemaVersion: Int
    var updatedAt: Double

    init(from k: OrdnerKonnektor, now: Double) {
        slot = k.slot.rawValue; ordnername = k.ordnername
        relativerPfad = k.relativerPfad; schemaVersion = k.schemaVersion; updatedAt = now
    }
    var toDomain: OrdnerKonnektor? {
        guard let s = OrdnerSlot(rawValue: slot) else { return nil }
        return OrdnerKonnektor(slot: s, ordnername: ordnername, relativerPfad: relativerPfad, schemaVersion: schemaVersion)
    }
}

private struct NomenklaturConfigRow: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "nomenklaturConfig" }
    var key: String
    var value: String
    var updatedAt: Double
}

private struct ProjektKostenstellenRow: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "projektKostenstellen" }
    var projektNummer: String
    var namenJSON: String
    var updatedAt: Double
}

// MARK: - NomenklaturStore
// mykilOS 8, Block C (S2): hält die lokale Nomenklatur-Config (Johannes' Entscheidung
// 2026-07-01: GRDB-Config lokal, nicht Airtable). Ordner-Konnektoren (Slot→Ordner,
// HANDOFF_PROVISIONING_NOMENKLATUR §10), aktive FolderSchema-Version, NumberAuthorityMode,
// und projektweise Kostenstellen-Overrides (bis ein Airtable-Feld existiert).
@MainActor
@Observable
public final class NomenklaturStore {
    public private(set) var konnektoren: [OrdnerSlot: OrdnerKonnektor] = [:]
    public private(set) var aktiveSchemaVersion: Int = 1
    public private(set) var authorityMode: NumberAuthorityMode = .local
    /// Projektweise Kostenstellen-Overrides (Projektnummer → Namen).
    public private(set) var kostenstellenOverrides: [String: [Kostenstelle]] = [:]
    public private(set) var saveState: SaveState = .idle

    private let db: GRDBDatabase
    private static let schemaVersionKey = "blockC.activeFolderSchemaVersion"
    private static let authorityModeKey = "blockC.numberAuthorityMode"

    public init(db: GRDBDatabase) { self.db = db }

    public func load() throws {
        // Konnektoren laden + FEHLENDE Default-Slots ergänzen. Nicht „nur wenn leer" —
        // sonst hinterließe ein teilweiser Bestand (z. B. nach einem Abbruch) dauerhaft
        // fehlende Slots, und `konnektor(.cad)` gäbe nil zurück. Bestehende (evtl. vom
        // Nutzer angepasste) Konnektoren bleiben unangetastet, nur Lücken werden gefüllt.
        let records = try db.read { try OrdnerKonnektorRecord.fetchAll($0) }
        konnektoren = Dictionary(uniqueKeysWithValues: records.compactMap(\.toDomain).map { ($0.slot, $0) })
        try ergaenzeFehlendeKonnektoren()
        // Config
        if let row = try db.read({ try NomenklaturConfigRow.fetchOne($0, key: Self.schemaVersionKey) }),
           let v = Int(row.value) { aktiveSchemaVersion = v }
        if let row = try db.read({ try NomenklaturConfigRow.fetchOne($0, key: Self.authorityModeKey) }),
           let m = NumberAuthorityMode(rawValue: row.value) { authorityMode = m }
        // Kostenstellen-Overrides
        let ksRows = try db.read { try ProjektKostenstellenRow.fetchAll($0) }
        var overrides: [String: [Kostenstelle]] = [:]
        for row in ksRows {
            guard let data = row.namenJSON.data(using: .utf8) else { continue }
            do {
                let namen = try JSONDecoder().decode([String].self, from: data)
                if namen.isEmpty == false { overrides[row.projektNummer] = namen.map { Kostenstelle(name: $0) } }
            } catch {
                // Kaputter JSON-Eintrag (sollte nicht vorkommen) → überspringen, sichtbar machen.
                MykLog.lifecycle.error("Kostenstellen-Override für \(row.projektNummer, privacy: .public) nicht dekodierbar: \(String(describing: error), privacy: .public)")
            }
        }
        kostenstellenOverrides = overrides
    }

    /// Ergänzt fehlende Default-Slots (idempotent), ohne bestehende zu überschreiben.
    private func ergaenzeFehlendeKonnektoren() throws {
        let fehlende = OrdnerKonnektor.v1Defaults.filter { konnektoren[$0.slot] == nil }
        guard fehlende.isEmpty == false else { return }
        let ts = Date().timeIntervalSince1970
        try db.write { dbc in
            for k in fehlende { try OrdnerKonnektorRecord(from: k, now: ts).insert(dbc) }
        }
        for k in fehlende { konnektoren[k.slot] = k }
    }

    /// Den realen Ordnernamen/-pfad für einen logischen Slot (Re-Wiring-sicher).
    public func konnektor(_ slot: OrdnerSlot) -> OrdnerKonnektor? { konnektoren[slot] }

    /// Das aktive Ordnerschema (heute v1). Re-Schematisierung legt eine neue Version an.
    public func aktivesSchema() -> FolderSchema { aktiveSchemaVersion == 1 ? .v1 : .v1 }

    // MARK: Kostenstellen (Block C: Default-Liste, Airtable-Quelle sobald Feld da)

    /// Direkte Kostenstellen-Abfrage — vermeidet die Provider-Allokation pro UI-Frame
    /// (Block-C-Review-Fix). Leere Overrides fallen auf die Defaults zurück.
    public func kostenstellen(fuer projektNummer: String) -> [Kostenstelle] {
        let o = kostenstellenOverrides[projektNummer]
        return (o?.isEmpty == false) ? o! : Kostenstelle.defaults
    }

    /// Provider-Sicht (für Aufrufer, die die Abstraktion brauchen).
    public func kostenstellenProvider() -> KostenstellenProviding {
        DefaultKostenstellenProvider(overrides: kostenstellenOverrides)
    }

    public func setzeKostenstellen(_ namen: [String], fuer projektNummer: String) throws {
        // Leere Liste = „kein Override" → nicht speichern (sonst stünde der Timer ohne
        // Kostenstellen da). Bestehenden Override entfernen, auf Defaults zurückfallen.
        let bereinigt = namen.map { $0.trimmingCharacters(in: .whitespaces) }.filter { $0.isEmpty == false }
        guard bereinigt.isEmpty == false else {
            try db.write { dbc in _ = try ProjektKostenstellenRow.deleteOne(dbc, key: projektNummer) }
            kostenstellenOverrides[projektNummer] = nil
            return
        }
        let json = (try? JSONEncoder().encode(bereinigt)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        let ts = Date().timeIntervalSince1970
        saveState = .saving
        do {
            try db.write { dbc in
                try ProjektKostenstellenRow(projektNummer: projektNummer, namenJSON: json, updatedAt: ts).save(dbc)
            }
            kostenstellenOverrides[projektNummer] = bereinigt.map { Kostenstelle(name: $0) }
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }
}
