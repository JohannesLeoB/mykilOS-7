import Foundation
import Observation
import SwiftUI
import GRDB
import MykilosKit

// MARK: - WorkBasketStore (Wirbelsäule, Welle C / C3)
//
// Der verallgemeinerte WorkBasket-Speicher (S10-Blueprint §3/§9): GRDB-backed,
// @MainActor @Observable, sichtbarer SaveState. Persistiert `WorkBasket` +
// seine `Pick`-Positionen matrix-agnostisch — kein Artikel-only-Hardwiring.
//
// Bewusst NEBEN dem bestehenden Airtable-`CartStore` (Sources/MykilosServices/
// Airtable/CartStore.swift): der ist der reine Artikel→Airtable-Versand-Pfad
// und bleibt unverändert (Abwärtskompatibilität, laufende Kundendaten). Dieser
// Store ist der lokale, generische Nachfolge-Speicher aus dem C3-Auftrag —
// jeder neue Pick-Typ (Bild, Kontakt, Textblock, Eingangsangebot, …) läuft
// hier ohne Codeänderung durch, weil `Pick`/`InhaltsArt` das Vokabular sind,
// nicht ein konkreter Artikel-Typ.
//
// Persistenz-Kompromiss: `Pick` ist ein Protokoll (nicht `Codable`) — jeder
// Pick wird beim Schreiben in seine `BasicPick`-Bestandteile zerlegt
// (matrix/objektID/snapshot + der bereits aufgelöste `resolve()`-Inhalt) und
// beim Lesen als `BasicPick` rekonstruiert. Für Picks mit lazy/externem
// resolve() (nicht `BasicPick`) wird der Inhalt beim Speichern einmalig
// materialisiert — WorkBaskets bleiben dadurch selbst nach einem App-Neustart
// vollständig lesbar, auch ohne die ursprüngliche externe Quelle.

// MARK: - WorkBasketRecord (Kopf)
struct WorkBasketRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "workBaskets" }

    var id: String
    var projektNummer: String
    var inhaltsArt: String
    var version: Int
    var statusJSON: String
    var erstellt: Double

    init(from basket: WorkBasket) throws {
        id = basket.id.raw
        projektNummer = basket.projektNummer
        inhaltsArt = basket.inhaltsArt.rawValue
        version = basket.version
        statusJSON = try WorkBasketStatusCoding.encode(basket.status)
        erstellt = basket.erstellt.timeIntervalSince1970
    }

    /// Rekonstruiert den WorkBasket-Kopf; `picks` müssen separat geladen und ergänzt werden.
    func toDomain(picks: [any Pick]) throws -> WorkBasket {
        WorkBasket(
            id: WorkBasketID(id),
            projektNummer: projektNummer,
            inhaltsArt: InhaltsArt(rawValue: inhaltsArt) ?? .gemischt,
            picks: picks,
            version: version,
            status: try WorkBasketStatusCoding.decode(statusJSON),
            erstellt: Date(timeIntervalSince1970: erstellt)
        )
    }
}

// MARK: - WorkBasketPickRecord (Positionen)
struct WorkBasketPickRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "workBasketPicks" }

    var id: String
    var basketID: String
    var position: Int
    var matrix: String
    var objektID: String
    var snapshotJSON: String
    var inhaltJSON: String

    init(basketID: String, position: Int, pick: any Pick, inhalt: PickContent) throws {
        self.id = "\(basketID)#\(position)"
        self.basketID = basketID
        self.position = position
        self.matrix = pick.matrix.rawValue
        self.objektID = pick.objektID.raw
        self.snapshotJSON = try Self.encodeSnapshot(pick.snapshot)
        self.inhaltJSON = try Self.encodeInhalt(inhalt)
    }

    func toDomain() throws -> any Pick {
        BasicPick(
            matrix: CatalogMatrix(rawValue: matrix) ?? .sonstige,
            objektID: CatalogObjectID(objektID),
            snapshot: try Self.decodeSnapshot(snapshotJSON),
            inhalt: try Self.decodeInhalt(inhaltJSON)
        )
    }

    private static func encodeSnapshot(_ snapshot: PickSnapshot) throws -> String {
        let data = try JSONEncoder().encode(snapshot)
        return String(decoding: data, as: UTF8.self)
    }

    private static func decodeSnapshot(_ json: String) throws -> PickSnapshot {
        try JSONDecoder().decode(PickSnapshot.self, from: Data(json.utf8))
    }

    private static func encodeInhalt(_ inhalt: PickContent) throws -> String {
        let data = try JSONEncoder().encode(inhalt)
        return String(decoding: data, as: UTF8.self)
    }

    private static func decodeInhalt(_ json: String) throws -> PickContent {
        try JSONDecoder().decode(PickContent.self, from: Data(json.utf8))
    }
}

// MARK: - WorkBasketStatusCoding
// `WorkBasketStatus` trägt bei nachtrag/gutschrift eine assoziierte `WorkBasketID` —
// kein automatisches Codable am Enum (C1 hält es bewusst schlank). Eigene, kleine
// JSON-Codierung hier in der Persistenz-Schicht statt C1 anzufassen.
enum WorkBasketStatusCoding {
    private struct Wire: Codable {
        var fall: String   // "kalkulation" | "bestaetigt" | "nachtrag" | "gutschrift"
        var elternID: String?
    }

    static func encode(_ status: WorkBasketStatus) throws -> String {
        let wire: Wire
        switch status {
        case .kalkulation:
            wire = Wire(fall: "kalkulation", elternID: nil)
        case .bestaetigt:
            wire = Wire(fall: "bestaetigt", elternID: nil)
        case .nachtrag(let zu):
            wire = Wire(fall: "nachtrag", elternID: zu.raw)
        case .gutschrift(let zu):
            wire = Wire(fall: "gutschrift", elternID: zu.raw)
        }
        let data = try JSONEncoder().encode(wire)
        return String(decoding: data, as: UTF8.self)
    }

    static func decode(_ json: String) throws -> WorkBasketStatus {
        let wire = try JSONDecoder().decode(Wire.self, from: Data(json.utf8))
        switch wire.fall {
        case "bestaetigt":
            return .bestaetigt
        case "nachtrag":
            guard let elternID = wire.elternID else { throw WorkBasketStoreError.korrupterStatus }
            return .nachtrag(zu: WorkBasketID(elternID))
        case "gutschrift":
            guard let elternID = wire.elternID else { throw WorkBasketStoreError.korrupterStatus }
            return .gutschrift(zu: WorkBasketID(elternID))
        default:
            return .kalkulation
        }
    }
}

// MARK: - WorkBasketStoreError
public enum WorkBasketStoreError: Error, Sendable, Equatable {
    /// Persistierter Status konnte nicht dekodiert werden (fehlende Eltern-ID bei nachtrag/gutschrift).
    case korrupterStatus
    /// Statusübergang ist laut `WorkBasketStatus.darfWechselnZu` nicht erlaubt (§7).
    case unerlaubterUebergang
    /// Kein WorkBasket mit dieser ID gefunden.
    case nichtGefunden
}

// MARK: - WorkBasketStore
@MainActor
@Observable
public final class WorkBasketStore {
    public private(set) var saveState: SaveState = .idle

    private let db: GRDBDatabase

    public init(db: GRDBDatabase) {
        self.db = db
    }

    // MARK: Schreiben — throws, SaveState sichtbar (Persistenz-Vertrag)

    /// Legt einen neuen WorkBasket an oder überschreibt ihn (append-only auf App-Ebene:
    /// eine neue `WorkBasketID`/Version entsteht beim Aufrufer, hier wird nur persistiert).
    /// Löst alle Picks auf
    /// (`resolve()`), bevor sie zusammen mit dem Kopf-Record atomar geschrieben werden.
    @discardableResult
    public func speichere(_ basket: WorkBasket) async throws -> WorkBasket {
        saveState = .saving
        do {
            var aufgeloest: [(pick: any Pick, inhalt: PickContent)] = []
            for pick in basket.picks {
                aufgeloest.append((pick, try await pick.resolve()))
            }
            let basketID = basket.id.raw
            let headRecord = try WorkBasketRecord(from: basket)
            let pickRecords = try aufgeloest.enumerated().map { index, entry in
                try WorkBasketPickRecord(basketID: basketID, position: index, pick: entry.pick, inhalt: entry.inhalt)
            }
            try db.write { conn in
                try headRecord.save(conn)
                try WorkBasketPickRecord
                    .filter(Column("basketID") == basketID)
                    .deleteAll(conn)
                for record in pickRecords {
                    try record.insert(conn)
                }
            }
            saveState = .saved(Date())
            return basket
        } catch {
            saveState = .failed(String(describing: error))
            throw error
        }
    }

    /// Statusübergang gemäß der C1-State-Machine (`WorkBasketStatus.darfWechselnZu`, §7).
    /// Verwendet nur die vorhandene Übergangsregel — keine neue Logik.
    @discardableResult
    public func wechsleStatus(basketID: WorkBasketID, zu neuerStatus: WorkBasketStatus) async throws -> WorkBasket {
        guard var basket = try lade(id: basketID) else {
            throw WorkBasketStoreError.nichtGefunden
        }
        guard basket.status.darfWechselnZu(neuerStatus) else {
            throw WorkBasketStoreError.unerlaubterUebergang
        }
        basket.status = neuerStatus
        return try await speichere(basket)
    }

    /// Hängt eine (z. B. aus einem Angebots-PDF herausgelöste) Position als neuen
    /// `BasicPick` an den jüngsten WorkBasket des Projekts an — oder legt einen neuen
    /// an, wenn keiner existiert. Lokale Bearbeitung (gleiche ID, `speichere`
    /// überschreibt); die Airtable-seitige Versionierung bleibt davon unberührt.
    /// EK/VK trägt der Aufrufer bei (aus der Angebotsrichtung).
    // Serialisierungs-Flag gegen Lost-Update (Ultra-Review 2026-07-04): weil
    // `speichere` suspendiert (await), können zwei schnelle Aufrufe auf dem MainActor
    // beide den ALTEN Korb lesen und der zweite den ersten überschreiben. Der
    // Spin-Wait (Task.yield, MainActor-isoliert) macht Lesen→Anhängen→Speichern atomar.
    private var anhaengenLaeuft = false

    @discardableResult
    public func fuegePositionHinzu(
        projektNummer: String,
        bezeichnung: String,
        menge: Int,
        ekEinzel: Double?,
        vkEinzel: Double?,
        objektID: String
    ) async throws -> WorkBasket {
        while anhaengenLaeuft { await Task.yield() }
        anhaengenLaeuft = true
        defer { anhaengenLaeuft = false }
        let pick = BasicPick(
            matrix: .artikel,
            objektID: CatalogObjectID(objektID),
            snapshot: PickSnapshot(bezeichnung: bezeichnung, menge: max(1, menge),
                                   ekEinzel: ekEinzel, vkEinzel: vkEinzel))
        let vorhandene = try alle(projektNummer: projektNummer)
        if var basket = vorhandene.max(by: { $0.erstellt < $1.erstellt }) {
            // Idempotent (Ultra-Review-Fix): gleiche objektID → Menge erhöhen statt
            // Duplikat anhängen (der globale WarenkorbState-Pfad macht es genauso).
            if let idx = basket.picks.firstIndex(where: { ($0 as? BasicPick)?.objektID == CatalogObjectID(objektID) }),
               let alt = basket.picks[idx] as? BasicPick {
                let s = alt.snapshot
                basket.picks[idx] = BasicPick(
                    matrix: alt.matrix, objektID: alt.objektID,
                    snapshot: PickSnapshot(bezeichnung: s.bezeichnung, menge: s.menge + max(1, menge),
                                           ekEinzel: s.ekEinzel, vkEinzel: s.vkEinzel, attribute: s.attribute),
                    inhalt: alt.inhalt)
            } else {
                basket.picks.append(pick)
            }
            return try await speichere(basket)
        }
        let neu = WorkBasket(
            id: WorkBasketID("WK-\(projektNummer)-\(UUID().uuidString.prefix(8))"),
            projektNummer: projektNummer,
            inhaltsArt: .artikel,
            picks: [pick])
        return try await speichere(neu)
    }

    // MARK: Lesen — Cold-Start-safe

    /// Lädt einen WorkBasket per ID (inkl. seiner Picks, positionsgeordnet). `nil`, wenn nicht vorhanden.
    public func lade(id: WorkBasketID) throws -> WorkBasket? {
        try db.read { conn in
            guard let head = try WorkBasketRecord.fetchOne(conn, key: id.raw) else { return nil }
            let pickRecords = try WorkBasketPickRecord
                .filter(Column("basketID") == id.raw)
                .order(Column("position"))
                .fetchAll(conn)
            let picks = try pickRecords.map { try $0.toDomain() }
            return try head.toDomain(picks: picks)
        }
    }

    /// Alle WorkBaskets, optional auf ein Projekt eingegrenzt. Unsortiert (roh) —
    /// Sortieren/Filtern übernimmt die reine `[WorkBasket]`-Erweiterung aus
    /// `MykilosKit` (§9 „Sortieren/Filtern"), damit die Logik testbar in
    /// MykilosKit bleibt statt hier dupliziert zu werden.
    public func alle(projektNummer: String? = nil) throws -> [WorkBasket] {
        try db.read { conn in
            var request = WorkBasketRecord.all()
            if let projektNummer, !projektNummer.isEmpty {
                request = request.filter(Column("projektNummer") == projektNummer)
            }
            let heads = try request.fetchAll(conn)
            return try heads.map { head in
                let pickRecords = try WorkBasketPickRecord
                    .filter(Column("basketID") == head.id)
                    .order(Column("position"))
                    .fetchAll(conn)
                let picks = try pickRecords.map { try $0.toDomain() }
                return try head.toDomain(picks: picks)
            }
        }
    }
}
