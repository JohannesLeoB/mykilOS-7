import Foundation
import Observation
import MykilosKit

// MARK: - DriveFolderProvisioning
// Abstraktion über die idempotente Ordner-Erstellung (find-or-create). GoogleDriveClient
// erfüllt das live; Tests injizieren einen Fake. Bewusst schmal — Block D legt nur Ordner an.
public protocol DriveFolderProvisioning: Sendable {
    func findOrCreateSubfolder(parentID: String, name: String) async throws -> String
}

extension GoogleDriveClient: DriveFolderProvisioning {}

// MARK: - ProjektProvisioningService
// mykilOS 8, Block D (S4): die Mehrsystem-Projekt-Geburt. Eine bestätigte Karte → ein Plan →
// Drive-Ordnerbaum + Airtable-Record, gated in die TEST-Sandbox geschrieben.
//
// Garantien (Brief-Pflicht):
//  · IDEMPOTENT (Schlüssel Kdnr+Projektnummer): zweiter Lauf erzeugt nichts Neues — Drive via
//    find-or-create, Airtable via Ledger-ID-Wiederverwendung; der Ledger merkt jeden erledigten Schritt.
//  · TEILFEHLER-FEST: nach JEDEM Schritt wird der Ledger persistiert. Bricht Schritt 2 ab, bleibt
//    Schritt 1 sauber erledigt im Ledger; ein Re-Run nimmt genau dort wieder auf.
//  · JEDER SCHRITT WIRFT; die Gesamtaktion ist EIN Audit-Eintrag + Write-Shadow je externem Write.
//  · GATED: nur in der TEST-Sandbox (`ProvisioningMode.test`); PROD ist gesperrt (Block A/D-Grenze).
@MainActor
@Observable
public final class ProjektProvisioningService {
    public private(set) var saveState: SaveState = .idle

    private let drive: any DriveFolderProvisioning
    private let airtableCreate: any AirtableRecordCreating
    private let airtableFetch: any AirtableFetching
    private let ledger: ProvisioningLedger
    private let audit: AuditStore
    private let writeShadow: WriteShadowRecorder
    // Review-Fix (critical): austauschbar für Tests (Fakes kennen keine echte Base/Tabelle),
    // im Live-Betrieb IMMER die echte, unveränderliche `AirtableClient.writableMap`.
    private let isWritable: (String, String) -> Bool
    // Studio-OS-Rollout (2026-07-02): optional — nil lässt Schritt 3 einfach übersprungen
    // (additiv, kein Zwang für bestehende Aufrufer/Tests). Read+Write in einem Dependency,
    // weil die Task-Idempotenz denselben Client zum Lesen bestehender Tasks braucht.
    private let clickUp: (any ClickUpFetching & ClickUpProjectProvisioning)?

    public init(
        drive: any DriveFolderProvisioning,
        airtableCreate: any AirtableRecordCreating,
        airtableFetch: any AirtableFetching,
        ledger: ProvisioningLedger,
        audit: AuditStore,
        writeShadow: WriteShadowRecorder,
        isWritable: @escaping (String, String) -> Bool = AirtableClient.isWritable,
        clickUp: (any ClickUpFetching & ClickUpProjectProvisioning)? = nil
    ) {
        self.drive = drive
        self.airtableCreate = airtableCreate
        self.airtableFetch = airtableFetch
        self.ledger = ledger
        self.audit = audit
        self.writeShadow = writeShadow
        self.isWritable = isWritable
        self.clickUp = clickUp
    }

    /// Provisioniert ein Projekt. `driveParentID` = Eltern-Ordner, unter dem `_TEST_PROVISIONING`
    /// liegt. `airtableBaseID`/`airtableTabelle` = die TEST-Sandbox-Tabelle (auf der Whitelist).
    /// `clickUpFolderID` = optionaler ClickUp-Zielordner (z. B. der `_TEST_PROVISIONING`-Ordner
    /// im Testspace) — nil überspringt Schritt 3 komplett (kein ClickUp-Adapter nötig).
    /// `actorUserID` = wer die Geburt auslöst (für Audit/Write-Shadow).
    /// Re-Runnable: liest den bestehenden Ledger-Stand und führt nur fehlende Schritte aus.
    @discardableResult
    public func provision(
        plan: ProvisioningPlan,
        mode: ProvisioningMode,
        driveParentID: String,
        airtableBaseID: String,
        airtableTabelle: String,
        clickUpFolderID: String? = nil,
        actorUserID: String
    ) async throws -> ProvisioningResult {
        // Gate: nur TEST-Sandbox. PROD bleibt gesperrt, bis Johannes je Schritt freigibt.
        guard mode == .test else { throw ProvisioningError.writeGateGesperrt }

        saveState = .saving
        var result = (try ledger.eintrag(fuer: plan.idempotenzSchluessel))
            ?? ProvisioningResult(idempotenzSchluessel: plan.idempotenzSchluessel,
                                  projektnummer: plan.projektnummer.appFormat, kdnr: plan.kdnr)

        do {
            // SCHRITT 1: Drive-Ordnerbaum (find-or-create, idempotent).
            if result.hat(.driveOrdnerbaum) == false {
                result = try await provisioniereDrive(plan: plan, driveParentID: driveParentID, into: result)
                result.erledigteSchritte.insert(.driveOrdnerbaum)
                result.status = .teilweise
                try ledger.speichere(result)   // Teilfehler-Grenze: Stand nach Schritt 1 fix
            }

            // SCHRITT 2: Airtable-Record (TEST-markiert, idempotent über Ledger-ID / Bestandsprüfung).
            if result.hat(.airtableRecord) == false {
                result = try await provisioniereAirtable(
                    plan: plan, baseID: airtableBaseID, tabelle: airtableTabelle, mode: mode,
                    actorUserID: actorUserID, into: result)
                result.erledigteSchritte.insert(.airtableRecord)
                try ledger.speichere(result)
            }

            // SCHRITT 3: ClickUp-Liste + Standard-Tasks (nur wenn Adapter + Ziel-Ordner gegeben).
            if let clickUp, let clickUpFolderID, result.hat(.clickUpStruktur) == false {
                result = try await provisioniereClickUp(
                    plan: plan, folderID: clickUpFolderID, client: clickUp, into: result)
                result.erledigteSchritte.insert(.clickUpStruktur)
                try ledger.speichere(result)
            }

            result.status = .vollstaendig
            result.letzterFehler = nil
            try ledger.speichere(result)
        } catch {
            result.status = .fehler
            result.letzterFehler = String(describing: error)
            try? ledger.speichere(result)   // Stand für Wiederaufnahme festhalten
            saveState = .failed(result.letzterFehler ?? "Fehler")
            throw error
        }

        // EIN Audit-Eintrag für die ganze Geburt (Brief: „eine bestätigte, auditierte Karte").
        do {
            let clickUpTeil = result.clickUpListID.map { " · ClickUp \($0)" } ?? ""
            try audit.append(AuditEntry(
                actorUserID: actorUserID, projectID: plan.projektnummer.appFormat,
                action: .projectLinked,
                summary: "Projekt-Geburt (TEST-Sandbox): \(plan.ordnerName) · Drive \(result.driveProjektOrdnerID ?? "?") · Airtable \(result.airtableRecordID ?? "?")\(clickUpTeil)"))
        } catch {
            MykLog.lifecycle.error("Provisioning-Audit fehlgeschlagen: \(String(describing: error), privacy: .public)")
        }
        saveState = .saved(Date())
        return result
    }

    // MARK: Drive

    private func provisioniereDrive(plan: ProvisioningPlan, driveParentID: String, into start: ProvisioningResult) async throws -> ProvisioningResult {
        var result = start
        do {
            // Sandbox-Wurzel (idempotent) — die eigentliche Baum-Logik ist geteilt
            // (DriveOrdnerbaumBuilder), damit die echte Fragebogen-Provisionierung
            // (AppState.erzeugeKundeUndProjekt) dieselbe Logik nutzt, nur mit anderem Parent.
            let sandboxID = try await drive.findOrCreateSubfolder(parentID: driveParentID, name: "_TEST_PROVISIONING")
            let gebaut = try await DriveOrdnerbaumBuilder.baue(
                drive: drive, parentID: sandboxID, ordnerName: plan.ordnerName,
                schema: plan.schema, bestehendeUnterordnerIDs: result.driveUnterordnerIDs,
                bekannteRootOrdnerID: result.driveProjektOrdnerID)
            result.driveProjektOrdnerID = gebaut.rootOrdnerID
            result.driveUnterordnerIDs = gebaut.unterordnerIDs
            return result
        } catch {
            throw ProvisioningError.schrittFehlgeschlagen(.driveOrdnerbaum, String(describing: error))
        }
    }

    // MARK: Airtable

    private func provisioniereAirtable(plan: ProvisioningPlan, baseID: String, tabelle: String, mode: ProvisioningMode, actorUserID: String, into start: ProvisioningResult) async throws -> ProvisioningResult {
        var result = start

        // Review-Fix (critical): VORAB prüfen, ob Base+Tabelle überhaupt auf der
        // Schreib-Whitelist stehen — sonst scheitert createRecord erst nach dem
        // (idempotenten, aber unnötigen) Idempotenz-Fetch mit einer kryptischen
        // invalidBaseID-Meldung. Klarer Fehler, BEVOR irgendetwas versucht wird.
        guard isWritable(baseID, tabelle) else {
            throw ProvisioningError.schrittFehlgeschlagen(
                .airtableRecord,
                "Tabelle \(tabelle)@\(baseID) ist nicht auf AirtableClient.writableMap — bitte zuerst mit Johannes auf die Schreib-Whitelist setzen lassen.")
        }

        // Idempotenz: schon ein TEST-Record mit dieser Projektnummer? → dessen ID nutzen, nichts neu anlegen.
        if let bestehendeID = try? await findeBestehendenRecord(plan: plan, baseID: baseID, tabelle: tabelle) {
            result.airtableRecordID = bestehendeID
            return result
        }

        // Felder + TEST-Marker (Doppel-Strategie: Name-Präfix TEST_ + Quelle=TEST).
        var felder: [String: AirtableFieldValue] = plan.airtableFelder
            .reduce(into: [:]) { $0[$1.key] = .string($1.value) }
        // Primärfeld (Projektname) mit TEST_-Präfix versehen, sonst ein neutrales hinzufügen.
        // Review-Fix (high): Eingabe NIE blind doppelt präfixen — ein Plan, dessen Projektname
        // schon TEST_ trägt (z. B. ein bereits markierter Re-Run-Versuch), würde sonst
        // TEST_TEST_… werden und am Doppel-Marker-Vergleich vorbeirutschen.
        if let name = plan.airtableFelder["Projektname"] {
            felder["Projektname"] = .string(name.hasPrefix(TestMarker.namePrefix) ? name : TestMarker.namePrefix + name)
        }
        felder["Quelle"] = .string(TestMarker.quelleFieldValue)
        felder["Projektnummer"] = .string(plan.projektnummer.appFormat)

        do {
            let recordID = try await airtableCreate.createRecord(baseID: baseID, table: tabelle, fields: felder)
            result.airtableRecordID = recordID
            // Write-Shadow (auch fehlgeschlagene laufen über recordWriteShadowFailure im catch).
            try? writeShadow.recordAirtableWrite(
                action: .create, actorUserID: actorUserID, baseID: baseID, table: tabelle,
                recordID: recordID, fields: felder, mode: mode, result: .ok)
            return result
        } catch {
            try? writeShadow.recordAirtableWrite(
                action: .create, actorUserID: actorUserID, baseID: baseID, table: tabelle,
                recordID: nil, fields: felder, mode: mode, result: .error, errorMessage: String(describing: error))
            throw ProvisioningError.schrittFehlgeschlagen(.airtableRecord, String(describing: error))
        }
    }

    // MARK: ClickUp

    /// Legt eine Liste (Name = `TEST_` + Ordnername, gleiche Doppel-Strategie wie Airtable)
    /// im gegebenen Ordner an — idempotent (find-or-create) — und seedet die Standard-
    /// Lebenszyklus-Tasks aus `ClickUpProjectTemplate.standardKundenprojekt`. Bereits
    /// vorhandene Tasks (gleicher Name) werden NICHT doppelt angelegt.
    private func provisioniereClickUp(
        plan: ProvisioningPlan, folderID: String,
        client: any ClickUpFetching & ClickUpProjectProvisioning, into start: ProvisioningResult
    ) async throws -> ProvisioningResult {
        var result = start
        let listenName = TestMarker.namePrefix + plan.ordnerName
        do {
            let listID = try await client.findOrCreateList(folderID: folderID, name: listenName, content: nil)
            result.clickUpListID = listID

            // Idempotenz auf Task-Ebene: nur fehlende Template-Tasks anlegen.
            let bestehende = Set((try? await client.tasks(listID: listID))?.map(\.name) ?? [])
            for taskName in ClickUpProjectTemplate.standardKundenprojekt where bestehende.contains(taskName) == false {
                _ = try await client.createTask(listID: listID, name: taskName)
            }
            return result
        } catch {
            throw ProvisioningError.schrittFehlgeschlagen(.clickUpStruktur, String(describing: error))
        }
    }

    /// Sucht einen bestehenden TEST-Record mit dieser Projektnummer (Idempotenz). Liest
    /// read-only; ein Fehler hier ist nicht fatal (dann wird neu angelegt).
    private func findeBestehendenRecord(plan: ProvisioningPlan, baseID: String, tabelle: String) async throws -> String? {
        let records = try await airtableFetch.fetchRecords(baseID: baseID, table: tabelle)
        let treffer = records.first { fields in
            fields["Projektnummer"]?.stringValue == plan.projektnummer.appFormat
                && fields["Quelle"]?.stringValue == TestMarker.quelleFieldValue
        }
        return treffer?["_airtableRecordID"]?.stringValue
    }
}
