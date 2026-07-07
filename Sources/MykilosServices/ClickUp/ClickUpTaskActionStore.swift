import Foundation
import Observation
import MykilosKit

// MARK: - ClickUpTaskActionStore (ClickUp-Vollintegration, S4+S10, 2026-07-07)
// Der EINZIGE Weg, wie mykilOS-UI interaktiv einen ClickUp-Task anlegt oder dessen Status
// ändert. Jeder Aufruf löst die Ziel-Liste live gegen ihre Space-ID auf und lässt
// `ClickUpWriteGate` entscheiden (Testspace ODER admin-freigeschaltete Go-Live-Whitelist) —
// fail-closed, kein UI-Verstecken als einzige Grenze (gleiches Prinzip wie die Admin-Store-
// Gates). Bei Erfolg ein Audit-Eintrag; Fehler (inkl. Gate-Ablehnung) werfen sichtbar.
@MainActor
@Observable
public final class ClickUpTaskActionStore {
    public private(set) var saveState: SaveState = .idle

    private let client: ClickUpTaskWriting & ClickUpSpaceResolving
    private let audit: AuditStore
    /// `nil` = nur Testspace (kein Go-Live-Anschluss übergeben) — sicherer Default.
    private let goLiveWhitelist: ClickUpGoLiveWhitelistStore?

    public init(
        client: ClickUpTaskWriting & ClickUpSpaceResolving = ClickUpClient(),
        audit: AuditStore, goLiveWhitelist: ClickUpGoLiveWhitelistStore? = nil
    ) {
        self.client = client
        self.audit = audit
        self.goLiveWhitelist = goLiveWhitelist
    }

    /// Statuswechsel. `status` kommt aus bereits geladenen Aufgaben der Liste (kein erfundener
    /// Wert). Wirft `ClickUpWriteGateError.nichtErlaubt`, wenn die Liste weder Testspace noch
    /// Go-Live-freigegeben ist.
    public func setStatus(
        taskID: String, listID: String, status: String, projectID: String, actorUserID: String
    ) async throws {
        saveState = .saving
        do {
            let spaceID = try await client.spaceID(forListID: listID)
            try ClickUpWriteGate.assertSchreibErlaubt(
                spaceID: spaceID, listID: listID, goLiveWhitelist: goLiveWhitelist?.listIDs ?? [])
            try await client.setStatus(taskID: taskID, status: status)
            try audit.append(AuditEntry(
                actorUserID: actorUserID, projectID: projectID, action: .clickUpStatusChanged,
                summary: "ClickUp-Status geändert: \(status)", quelle: "clickup-write"))
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }

    /// Aufgabe anlegen. `ghostKuerzel` (falls gesetzt) wird NUR als Text-Marker im
    /// Beschreibungsfeld hinterlegt — NIE das native ClickUp-`assignees`-Feld
    /// ([[aufgaben-nur-mensch-zu-mensch-regel]]). Gleiches Gate wie `setStatus`.
    @discardableResult
    public func createTask(
        listID: String, name: String, ghostKuerzel: String?, projectID: String, actorUserID: String
    ) async throws -> String {
        saveState = .saving
        do {
            let spaceID = try await client.spaceID(forListID: listID)
            try ClickUpWriteGate.assertSchreibErlaubt(
                spaceID: spaceID, listID: listID, goLiveWhitelist: goLiveWhitelist?.listIDs ?? [])
            let content = ghostKuerzel.map { "Zugewiesen (simuliert, Ghost-Persona): \($0)" }
            let newID = try await client.createTask(listID: listID, name: name, content: content)
            try audit.append(AuditEntry(
                actorUserID: actorUserID, projectID: projectID, action: .clickUpTaskCreated,
                summary: "ClickUp-Aufgabe angelegt: \(name)", quelle: "clickup-write"))
            saveState = .saved(Date())
            return newID
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }
}
