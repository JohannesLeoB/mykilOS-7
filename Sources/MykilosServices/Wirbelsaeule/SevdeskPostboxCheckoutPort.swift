import Foundation
import CryptoKit
import MykilosKit

// MARK: - SevdeskPostboxCheckoutPort (Wirbelsäule · sevDesk-Postbox-Drop)
//
// Der erste CheckoutPort mit echtem externem Write: nimmt einen WorkBasket
// (herausgelöste Angebots-/Rechnungspositionen) und legt ihn append-only in die
// sevDesk-Einweg-Postbox in Airtable ab — ein Beleg-Kopf (`Postbox-Beleg`) plus
// N verlinkte Positionen (`Postbox-Position`). Ein Mensch baut daraus in sevDesk
// den echten Beleg.
//
// EISERNE GRENZEN (docs/SEVDESK_POSTBOX_SCHEMA_ANALYSE.md):
//   - mykilOS stellt NIE selbst einen belegführenden Beleg aus. Die Postbox trägt
//     nur Positions-/Kontextdaten (Vorschlag), nie ein fertiges Dokument.
//   - sevDesk = BOSSMODE über absolute Mengen, Margen und Steuer. Alle kaufmännischen
//     Felder hier sind Vorschlag/Gegenprobe, nie verbindlich. Deshalb schreiben wir
//     KEINE Brutto-/Steuer-Summe (das rechnet sevDesk) — nur die Netto-Gegenprobe aus
//     den vorliegenden Positionspreisen.
//   - Keine echte Belegnummer (kein NUMMERNBOSS definiert). Nur eine Fremd-Referenz
//     als Klartext, falls im Ziel mitgegeben.
//   - Append-only. Kein DELETE, kein Überschreiben. Idempotent über den Objekt-Hash:
//     ein zweiter identischer Drop legt nichts Neues an.
//
// Der Port lebt in MykilosServices, weil er den Airtable-Schreibpfad braucht;
// `CheckoutPort` selbst wohnt in MykilosKit (Foundation-only).
public struct SevdeskPostboxCheckoutPort: CheckoutPort {

    public let id: PortID
    public let name: String

    private let airtableCreate: any AirtableRecordCreating
    private let airtableFetch: any AirtableFetching
    private let baseID: String
    private let belegTable: String
    private let positionTable: String
    private let logger: DataFlowLogger?
    private let jetzt: @Sendable () -> Date

    /// Integrations-ID im Datenstrom-Handbuch — MUSS exakt zum Handbuch-/Manifest-Eintrag passen.
    public static let integrationID = "SEVDESK_POSTBOX_DROP"

    public init(
        id: PortID = PortID("sevdesk-postbox"),
        name: String = "sevDesk-Postbox",
        airtableCreate: any AirtableRecordCreating,
        airtableFetch: any AirtableFetching,
        baseID: String = AirtableClient.writableBaseID,
        belegTable: String = "Postbox-Beleg",
        positionTable: String = "Postbox-Position",
        logger: DataFlowLogger? = nil,
        jetzt: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.id = id
        self.name = name
        self.airtableCreate = airtableCreate
        self.airtableFetch = airtableFetch
        self.baseID = baseID
        self.belegTable = belegTable
        self.positionTable = positionTable
        self.logger = logger
        self.jetzt = jetzt
    }

    /// Positionen aus Angeboten/Rechnungen sind artikel-/dokumentartig.
    public func erlaubteInhaltsArten() -> Set<InhaltsArt> {
        [.artikel, .material, .dokumente, .gemischt]
    }

    // MARK: - Vorschau (schreibt nichts)

    public func preview(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutPreview {
        let anzahl = basket.picks.count
        let netto = Self.nettoGegenprobe(basket)
        var warnungen: [String] = []
        if anzahl == 0 {
            warnungen.append("Korb ist leer — es wird kein Beleg abgelegt.")
        }
        warnungen.append("sevDesk hat die Hoheit über Mengen, Margen und Steuer — diese Zahlen sind ein Vorschlag.")
        let belegTyp = ziel.parameter["belegTyp"] ?? "Angebot"
        let zusammenfassung =
            "\(belegTyp) mit \(anzahl) Position\(anzahl == 1 ? "" : "en") in die sevDesk-Postbox legen "
            + "(Netto-Gegenprobe \(Self.euro(netto))). Kein Beleg, kein Versand — ein Mensch übernimmt in sevDesk."
        return CheckoutPreview(zusammenfassung: zusammenfassung, warnungen: warnungen)
    }

    // MARK: - Ausführung (append-only Write, idempotent)

    public func execute(basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutResult {
        let start = jetzt()
        let objektHash = Self.objektHash(basket)

        // Idempotenz: existiert schon ein Beleg mit diesem Objekt-Hash? → nichts Neues anlegen.
        if let vorhandeneID = try await bestehenderBeleg(objektHash: objektHash) {
            await protokolliere(
                user: ziel.parameter["user"] ?? "unbekannt", recordsWritten: 0, durationMs: 0,
                summary: "sevDesk-Postbox: Duplikat (Objekt-Hash bereits vorhanden), kein neuer Beleg.")
            return CheckoutResult(
                erfolg: true,
                referenz: vorhandeneID,
                meldung: "Bereits in der sevDesk-Postbox (idempotent, kein Duplikat angelegt)."
            )
        }

        // Picks materialisieren (Rückverfolgbarkeit; resolve darf werfen — kein stiller try?).
        for pick in basket.picks { _ = try await pick.resolve() }

        // 1) Beleg-Kopf anlegen.
        let postboxID = "PB-" + String(objektHash.prefix(16))
        let status = ziel.parameter["status"] ?? "Neu"
        let belegTyp = ziel.parameter["belegTyp"] ?? "Angebot"
        let netto = Self.nettoGegenprobe(basket)

        var belegFelder: [String: AirtableFieldValue] = [
            "Postbox-ID":   .string(postboxID),
            "Objekt-Hash":  .string(objektHash),
            "Status":       .string(status),
            "Beleg-Typ":    .string(belegTyp),
            "Projekt-Nr":   .string(basket.projektNummer),
            "Netto-Summe":  .number(netto),
            "Importiert-am": .string(ISO8601DateFormatter().string(from: start)),
        ]
        Self.setzeFalls(&belegFelder, "Betreff", ziel.parameter["betreff"])
        Self.setzeFalls(&belegFelder, "Kunde", ziel.parameter["kunde"])
        Self.setzeFalls(&belegFelder, "Kundennummer", ziel.parameter["kundennummer"])
        Self.setzeFalls(&belegFelder, "Lieferant", ziel.parameter["lieferant"])
        Self.setzeFalls(&belegFelder, "Fremd-Referenznummer", ziel.parameter["fremdRef"])
        Self.setzeFalls(&belegFelder, "Quelldatei", basket.picks.first?.snapshot.attribute["quelle"])
        Self.setzeFalls(&belegFelder, "Importiert-von", ziel.parameter["user"])

        let belegRecordID = try await airtableCreate.createRecord(
            baseID: baseID, table: belegTable, fields: belegFelder
        )

        // 2) Positionen anlegen (verlinkt auf den Beleg).
        var geschrieben = 1
        for (index, pick) in basket.picks.enumerated() {
            let felder = Self.positionsFelder(
                pick: pick, index: index, belegRecordID: belegRecordID, objektHash: objektHash
            )
            _ = try await airtableCreate.createRecord(
                baseID: baseID, table: positionTable, fields: felder
            )
            geschrieben += 1
        }

        let dauerMs = Int(jetzt().timeIntervalSince(start) * 1000)
        await protokolliere(
            user: ziel.parameter["user"] ?? "unbekannt", recordsWritten: geschrieben, durationMs: dauerMs,
            summary: "sevDesk-Postbox: \(belegTyp) \(postboxID) mit \(basket.picks.count) Position(en) abgelegt.")

        return CheckoutResult(
            erfolg: true,
            referenz: belegRecordID,
            meldung: "In sevDesk-Postbox abgelegt: \(postboxID) (\(basket.picks.count) Position(en))."
        )
    }

    // MARK: - Protokoll (Datenstrom-Log; DataFlowLogger ist @MainActor)

    private func protokolliere(user: String, recordsWritten: Int, durationMs: Int, summary: String) async {
        guard let logger else { return }
        await MainActor.run {
            logger.log(
                integrationID: Self.integrationID, actorUserID: user, action: .success,
                recordsWritten: recordsWritten, durationMs: durationMs, summary: summary)
        }
    }

    // MARK: - Bestandsprüfung (Idempotenz)

    private func bestehenderBeleg(objektHash: String) async throws -> String? {
        let records = try await airtableFetch.fetchRecords(baseID: baseID, table: belegTable)
        for record in records where record["Objekt-Hash"]?.stringValue == objektHash {
            // fetchRecords/parsePage legt die Record-ID unter "_airtableRecordID" ab.
            return record["_airtableRecordID"]?.stringValue
        }
        return nil
    }

    // MARK: - Feld-Mapping (rein/testbar)

    /// Netto-Gegenprobe: Summe (Einzelpreis × Menge) über alle Picks. Bewusst NUR netto —
    /// Brutto/Steuer rechnet sevDesk (BOSSMODE).
    static func nettoGegenprobe(_ basket: WorkBasket) -> Double {
        basket.picks.reduce(0.0) { summe, pick in
            let s = pick.snapshot
            let einzel = s.vkEinzel ?? s.ekEinzel ?? 0
            return summe + einzel * Double(s.menge)
        }
    }

    static func positionsFelder(
        pick: any Pick, index: Int, belegRecordID: String, objektHash: String
    ) -> [String: AirtableFieldValue] {
        let s = pick.snapshot
        let attr = s.attribute
        let einzel = s.vkEinzel ?? s.ekEinzel
        let posNr = String(index + 1)
        let positionsHash = sha256Hex(Data(("\(objektHash)|\(index)|\(s.bezeichnung)").utf8))

        var felder: [String: AirtableFieldValue] = [
            "Positions-ID":   .string("\(belegRecordID)-P\(posNr)"),
            "Beleg":          .array([belegRecordID]),
            "Positions-Hash": .string(positionsHash),
            "Pos-Nr":         .string(posNr),
            "Ist-Gruppentitel": .number(0),
            "Titel":          .string(s.bezeichnung),
            "Menge":          .number(Double(s.menge)),
        ]
        setzeFalls(&felder, "Beschreibung", attr["originalText"])
        setzeFalls(&felder, "Artikelnummer", attr["artikelnummer"])
        setzeFalls(&felder, "Einheit", attr["einheit"])
        setzeFalls(&felder, "Richtung", attr["richtung"])
        if let einzel {
            felder["Einzelpreis"] = .number(einzel)
            felder["Gesamtpreis"] = .number(einzel * Double(s.menge))
        }
        return felder
    }

    /// Deterministischer Beleg-Hash über den Korbinhalt (Projekt + geordnete Picks).
    /// Unabhängig von Zeit/Zufall → gleicher Korb ⇒ gleicher Hash ⇒ Idempotenz.
    static func objektHash(_ basket: WorkBasket) -> String {
        var teile: [String] = [basket.projektNummer, basket.inhaltsArt.rawValue]
        for pick in basket.picks {
            let s = pick.snapshot
            teile.append([
                pick.objektID.raw,
                s.bezeichnung,
                String(s.menge),
                s.ekEinzel.map { String($0) } ?? "",
                s.vkEinzel.map { String($0) } ?? "",
                s.attribute["artikelnummer"] ?? "",
                s.attribute["originalText"] ?? "",
            ].joined(separator: "|"))
        }
        return sha256Hex(Data(teile.joined(separator: "\n").utf8))
    }

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func euro(_ wert: Double) -> String { String(format: "%.2f €", wert) }

    /// Setzt ein Feld nur, wenn der Wert nicht nil/leer ist (hält den Record schlank).
    static func setzeFalls(_ felder: inout [String: AirtableFieldValue], _ key: String, _ wert: String?) {
        guard let wert, wert.isEmpty == false else { return }
        felder[key] = .string(wert)
    }
}
