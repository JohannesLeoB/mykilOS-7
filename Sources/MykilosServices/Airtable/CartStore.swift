import Foundation
import MykilosKit

// MARK: - CartStore
// Append-only Versand-Logik für Warenkörbe nach Airtable (Base: appdxTeT6bhSBmwx5).
//
// Eiserne Regeln:
//   - KEIN DELETE, KEIN Überschreiben: alte Versionen werden auf "Archiviert" gesetzt (PATCH).
//   - Alle Schreibvorgänge `throws`.
//   - Gated: wird erst NACH expliziter Bestätigung durch den User aufgerufen.
//   - Audit-Eintrag bei jedem erfolgreichen Versand.
//   - Nur Whitelist-Tabellen: "Warenkörbe", "Projektartikel" in "appdxTeT6bhSBmwx5".

// MARK: - CartSendOutcome
public enum CartSendOutcome: Sendable, Equatable {
    /// Erfolgreich: neue Record-ID + Versionsnummer.
    case success(recordID: String, version: Int)
    /// Kein Inhalt — leerer Warenkorb wird nicht versendet.
    case leer
}

// MARK: - CartStore
public struct CartStore: Sendable {

    // Airtable-Konstanten (appdxTeT6bhSBmwx5)
    public static let artikelBaseID      = "appdxTeT6bhSBmwx5"
    public static let warenkorbTable     = "Warenkörbe"
    public static let projektartikelTable = "Projektartikel"

    // Warenkörbe-Felder (nach Spec)
    public static let feldBezeichnung      = "fld2E4ONfJNajOkpw"
    public static let feldProjekt          = "fld198rcMMZY9JfV3"
    public static let feldPruefsumme       = "fldfsBQavBeSXB8k3"
    public static let feldVersion          = "fld4kSshziIqkqNZe"
    public static let feldStatus           = "fldDShiVPhnEu4vOX"
    public static let feldAnzahlPositionen = "fldsiQb11u3tOPxri"
    public static let feldGesamtEK         = "fldEpLh31ub24jwON"
    public static let feldGesamtVK         = "fldNCINxu0cA0FUVE"
    public static let feldPositionenJSON   = "fld7vUTFucNGCjDfk"
    public static let feldErstelltAm       = "fldqxX3y5vkNds0b7"

    // Projektartikel-Felder
    public static let feldProjektLink      = "fldZK2rAVLEQbxEhp"
    public static let feldArtikelLink      = "fldVRLsdUGZTtOaIA"
    public static let feldMenge            = "fldOiXJbWKt0Xxt5m"

    // Härtung (2026-07-01, Audit): NUR für Read-Matching gegen bereits geladene Records.
    // `AirtableClient.fetchRecords` liefert Felder standardmäßig NAME-keyed (die Airtable-API
    // schlüsselt nur ID-basiert, wenn `returnFieldsByFieldId=true` gesetzt wird — das tut kein
    // Aufrufer). Ein Read-Match über die Feld-IDs oben traf deshalb NIE — Archivierung und
    // Versionsnummer liefen seit jeher ins Leere (jeder Warenkorb wurde faktisch immer als
    // "Version 1" angelegt, alte Versionen nie archiviert). Live bestätigte echte Namen
    // (gleiche Technik wie die Kunden/Projekte-Schema-Diagnose): Anzahl Positionen,
    // Bezeichnung, Erstellt-am, Gesamt EK (€), Gesamt VK (€), Positionen (JSON), Projekt,
    // Prüfsumme, Status, Version. Die IDs oben bleiben für CREATE/UPDATE korrekt (Airtable
    // akzeptiert dort sowohl Namen als auch IDs als Feld-Schlüssel).
    static let feldPruefsummeName = "Prüfsumme"
    static let feldStatusName     = "Status"
    static let feldVersionName    = "Version"

    // Status-Werte
    public static let statusAktuell     = "Aktuell"
    public static let statusArchiviert  = "Archiviert"

    private let fetcher: AirtableFetching
    private let creator: AirtableRecordCreating
    private let updater: AirtableRecordUpdating
    private let auditStore: AuditStore?
    private let actorUserID: String

    public init(
        fetcher: AirtableFetching,
        creator: AirtableRecordCreating,
        updater: AirtableRecordUpdating,
        auditStore: AuditStore? = nil,
        actorUserID: String = "system"
    ) {
        self.fetcher = fetcher
        self.creator = creator
        self.updater = updater
        self.auditStore = auditStore
        self.actorUserID = actorUserID
    }

    // MARK: - sendWarenkorbToAirtable

    /// Gated: Warenkorb versioniert nach Airtable senden (append-only).
    ///
    /// Ablauf:
    ///   1. Prüfsumme aus Warenkorb bestimmen.
    ///   2. Bestehende Warenkörbe-Records mit gleicher Prüfsumme suchen.
    ///   3. Alle "Aktuell"-Records davon → PATCH auf "Archiviert" (KEIN DELETE).
    ///   4. Neue Version (max+1) anlegen: Status=Aktuell, alle Felder, Positionen als JSON.
    ///   5. Optional: Projektartikel-Records je Item anlegen (wenn projektRecordID vorhanden).
    ///   6. Audit-Eintrag.
    ///
    /// Wirft bei jedem Fehler (Netz, Whitelist-Verletzung, Serialisierung).
    /// Leerer Warenkorb → `.leer` ohne Netzwerkzugriff.
    public func sendWarenkorbToAirtable(
        _ wk: Warenkorb,
        akteurProjektID: String = ""
    ) async throws -> CartSendOutcome {

        guard !wk.items.isEmpty else { return .leer }

        let pruefsumme = wk.pruefsumme

        // 1. Bestehende Records mit gleicher Prüfsumme laden
        let bestehend = try await fetcher.fetchRecords(
            baseID: Self.artikelBaseID,
            table: Self.warenkorbTable
        )

        // 2. Records mit gleicher Prüfsumme filtern → Aktuell → Archivieren
        // Härtung (2026-07-01, Audit): über die echten NAMEN gelesen, nicht die Feld-IDs
        // (siehe Kommentar bei feldPruefsummeName oben) — sonst matcht dieser Filter nie.
        let zuArchivieren = bestehend.filter { record in
            record[Self.feldPruefsummeName]?.stringValue == pruefsumme
            && record[Self.feldStatusName]?.stringValue == Self.statusAktuell
        }

        for record in zuArchivieren {
            guard let recordID = record["_airtableRecordID"]?.stringValue else { continue }
            try await updater.updateRecord(
                baseID: Self.artikelBaseID,
                table: Self.warenkorbTable,
                recordID: recordID,
                fields: [Self.feldStatus: .string(Self.statusArchiviert)]
            )
        }

        // 3. Maximale Versionsnummer bestimmen (über alle Records mit dieser Prüfsumme)
        let letzteVersion: Int = bestehend
            .filter { $0[Self.feldPruefsummeName]?.stringValue == pruefsumme }
            .compactMap { $0[Self.feldVersionName]?.numberValue }
            .map { Int($0) }
            .max() ?? 0
        let neueVersion = letzteVersion + 1

        // 4. Positionen als JSON serialisieren
        let positioenenJSON = try Self.serializeItems(wk.items)

        // 5. ISO-8601 Timestamp
        let iso8601 = ISO8601DateFormatter().string(from: Date())

        // 6. Bezeichnung: Projektname oder Prüfsumme-Kurzform
        let bezeichnung: String
        if let name = wk.projektName, !name.isEmpty {
            bezeichnung = "Warenkorb \(name) v\(neueVersion)"
        } else {
            let kurz = String(pruefsumme.prefix(8))
            bezeichnung = "Warenkorb \(kurz) v\(neueVersion)"
        }

        // 7. Felder für neuen Record zusammenbauen
        var felder: [String: AirtableFieldValue] = [
            Self.feldBezeichnung:      .string(bezeichnung),
            Self.feldPruefsumme:       .string(pruefsumme),
            Self.feldVersion:          .number(Double(neueVersion)),
            Self.feldStatus:           .string(Self.statusAktuell),
            Self.feldAnzahlPositionen: .number(Double(wk.items.count)),
            Self.feldGesamtEK:         .number(wk.gesamtEKNetto),
            Self.feldGesamtVK:         .number(wk.gesamtVKNetto),
            Self.feldPositionenJSON:   .string(positioenenJSON),
            Self.feldErstelltAm:       .string(iso8601),
        ]

        // Projekt-Record-ID-Link: `feldProjekt` ist ein Link-to-record-Feld in Airtable
        // und verlangt IMMER ein Array echter Record-IDs. Ein roher Projektname-String
        // (ohne Record-ID) führte hier bisher zu HTTP 422 — Fix: Feld bleibt einfach leer,
        // wenn keine Record-ID vorliegt, statt einen ungültigen Freitext-Fallback zu senden.
        if let projektRecordID = wk.projektRecordID {
            felder[Self.feldProjekt] = .array([projektRecordID])
        }

        // 8. Neuen Warenkorb-Record anlegen
        let neueRecordID = try await creator.createRecord(
            baseID: Self.artikelBaseID,
            table: Self.warenkorbTable,
            fields: felder
        )

        // 9. Projektartikel-Records je Item (optional, nur wenn Artikel-Record-ID vorhanden)
        if let projektRecordID = wk.projektRecordID {
            for item in wk.items {
                guard let artikelID = item.artikelRecordID else { continue }
                try await creator.createRecord(
                    baseID: Self.artikelBaseID,
                    table: Self.projektartikelTable,
                    fields: [
                        Self.feldProjektLink: .array([projektRecordID]),
                        Self.feldArtikelLink:  .array([artikelID]),
                        Self.feldMenge:        .number(Double(item.menge)),
                    ]
                )
            }
        }

        // 10. Audit-Eintrag (MainActor-Kontext erfordert await). EK nur nennen,
        // wenn > 0 (Polish 2026-07-04: „EK 0.00 €" wirkte unfertig, wenn keine
        // Einkaufspreise gepflegt sind).
        let ekTeil = wk.gesamtEKNetto > 0 ? ", EK \(String(format: "%.2f", wk.gesamtEKNetto)) €" : ""
        await appendAudit(
            projektID: akteurProjektID,
            summary: "Warenkorb '\(bezeichnung)' v\(neueVersion) → Airtable (\(wk.items.count) Pos.\(ekTeil))"
        )

        return .success(recordID: neueRecordID, version: neueVersion)
    }

    // MARK: - Reine, testbare Hilfsmethoden

    /// Serialisiert WarenkorbItems als JSON-String für das Positionen-Feld.
    /// Reine Funktion, keine Side-Effects.
    public static func serializeItems(_ items: [WarenkorbItem]) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(items)
        guard let string = String(data: data, encoding: .utf8) else {
            throw CartStoreError.serializationFailed
        }
        return string
    }

    /// Deserialisiert JSON-String zurück in WarenkorbItems (für Tests und Verifikation).
    public static func deserializeItems(from json: String) throws -> [WarenkorbItem] {
        guard let data = json.data(using: .utf8) else {
            throw CartStoreError.serializationFailed
        }
        return try JSONDecoder().decode([WarenkorbItem].self, from: data)
    }

    // MARK: - Private Helpers

    @MainActor
    private func appendAudit(projektID: String, summary: String) {
        let entry = AuditEntry(
            actorUserID: actorUserID,
            projectID: projektID,
            action: .warenkorbGesendet,
            summary: summary
        )
        try? auditStore?.append(entry)
    }
}

// MARK: - CartStoreError
public enum CartStoreError: Error, Sendable, Equatable {
    case serializationFailed
    case leeresWarenkorb
}
