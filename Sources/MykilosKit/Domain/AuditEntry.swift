import Foundation

// MARK: - AuditEntry
// Jede externe Aktion hinterlässt einen Audit-Eintrag.
// Persistiert via AuditStore in der GRDB-Tabelle `auditEntries`.
public struct AuditEntry: Codable, Identifiable, Sendable {
    public enum Action: String, Codable, Sendable {
        case offerImported, draftCreated, draftSent, projectLinked, noteUpdated, estimateAdjusted, calibrationPromoted, contactCreated, driveFileUploaded,
             warenkorbGesendet,   // Webshop Phase 1: Warenkorb-Version in Airtable gespeichert (append-only)
             mailAktionAusgefuehrt,   // gelesen/ungelesen, Stern, Archiv, Papierkorb (Gmail messages.modify/trash)
             inviteCreated,   // Admin-Ebene S4: .mykinvite erstellt (Actor = verifizierte googleEmail, keine Keys geloggt)
             clickUpStatusChanged,   // ClickUp-Vollintegration S4: Status interaktiv geändert (nur Testspace, ClickUpWriteGate)
             clickUpTaskCreated,   // S4: Aufgabe interaktiv angelegt (ClickUpWriteGate, Ghost-Kürzel nur als Text-Marker)
             clickUpGoLiveFreigegeben,   // S10: eine Liste admin-only auf die Go-Live-Whitelist gesetzt
             clickUpGoLiveGesperrt   // S10: eine Liste von der Go-Live-Whitelist entfernt
    }
    public let id: UUID
    public let timestamp: Date
    public let actorUserID: String
    public let projectID: String
    public let action: Action
    public let summary: String
    /// Offene Herkunft des Vorgangs (z. B. "drive-offer", "kalkulation", "warenkorb").
    /// Additiv (CheckIn-Spine, v23) — bestehende Aufrufer + alte GRDB-Zeilen bleiben
    /// gültig (Default nil, decodeIfPresent).
    public let quelle: String?
    /// Deterministischer Dedup-Schlüssel (CheckIn-Spine). Additiv (v23), nullable.
    /// Ein PARTIAL UNIQUE INDEX (WHERE idempotenzKey IS NOT NULL) macht die Idempotenz
    /// hart; Alt-Zeilen mit NULL bleiben gültig.
    public let idempotenzKey: String?

    public init(id: UUID = UUID(), timestamp: Date = Date(), actorUserID: String,
                projectID: String, action: Action, summary: String,
                quelle: String? = nil, idempotenzKey: String? = nil) {
        self.id = id; self.timestamp = timestamp; self.actorUserID = actorUserID
        self.projectID = projectID; self.action = action; self.summary = summary
        self.quelle = quelle; self.idempotenzKey = idempotenzKey
    }

    // Expliziter Decoder: die neuen Felder werden via decodeIfPresent gelesen, sodass
    // bestehende JSON-/Codable-Payloads OHNE quelle/idempotenzKey weiter dekodieren
    // (nicht-brechend). Der Encoder ist der synthetisierte (schreibt alle Felder).
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, actorUserID, projectID, action, summary, quelle, idempotenzKey
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id           = try container.decode(UUID.self, forKey: .id)
        self.timestamp    = try container.decode(Date.self, forKey: .timestamp)
        self.actorUserID  = try container.decode(String.self, forKey: .actorUserID)
        self.projectID    = try container.decode(String.self, forKey: .projectID)
        self.action       = try container.decode(Action.self, forKey: .action)
        self.summary      = try container.decode(String.self, forKey: .summary)
        self.quelle        = try container.decodeIfPresent(String.self, forKey: .quelle) ?? nil
        self.idempotenzKey = try container.decodeIfPresent(String.self, forKey: .idempotenzKey) ?? nil
    }
}
