import Foundation
import CryptoKit
import MykilosKit
import MykilosKalkulationsCore

// MARK: - KalkulationsEngineError

public enum KalkulationsEngineError: Error, CustomStringConvertible {
    /// Fähigkeit ist absichtlich noch nicht verdrahtet (braucht Infra aus einem späteren Schritt).
    case notYetImplemented(String)

    public var description: String {
        switch self {
        case .notYetImplemented(let detail): "Noch nicht implementiert: \(detail)"
        }
    }
}

// MARK: - KalkulationsEngine
// Adapter zwischen mykilOS 6 (`KalkulationsEngineProviding`) und dem portierten
// mykilO$$-Kern. `schaetze` ist der zweistufige Einstieg: `parse` (Semantik) →
// `estimate` (Preislogik) → Mapping `EstimateResult` → `KostenSchaetzung`.
//
// Aktiv: `schaetze` + `geraetepreis` (wenn ein DeviceCatalog injiziert ist;
// sonst nil — der Lookup ist optional) + `recordAdjustment` (persistiert die
// Anpassung im LearningStore und protokolliert sie als AuditEntry) + der sichtbare
// Lern-Loop (`lernUebersicht` liest den Kalibrierungsstand, `promote` übernimmt
// einen Kandidaten als aktiven Faktor und auditiert das) + `importPDF` (Härtung
// 2026-07-01: SHA256-Dedup + Ablage in Airtable „Eingehende-Angebote" — reine
// Positions-/Preis-Anker-Extraktion aus dem PDF-Text ist bewusst NICHT Teil
// davon, das bleibt ein eigenes, großes Folge-Feature, siehe IDEEN_UND_BACKLOG.md).
//
// Actor: die mitgeführten Kern-Objekte (Estimator/Parser/LearningStore) sind nicht
// Sendable; die Actor-Isolation kapselt sie und passt zu den async-Protokollmethoden.
public actor KalkulationsEngine: KalkulationsEngineProviding {
    private let provider: PriceAnchorProviding
    private let learningStore: LearningStore
    private let deviceCatalog: DeviceCatalog?
    private let auditStore: AuditStore?
    // Ohne beide (Default nil) wirft importPDF weiterhin ehrlich .notYetImplemented
    // statt mit Halb-Wahrheiten weiterzumachen (kein Drive-Zugriff ohne Google-
    // Verbindung, kein Airtable-Schreibvorgang ohne Client).
    private let drive: (any GoogleDriveFetching)?
    private let airtable: (any AirtableRecordCreating)?
    // Datenstrom-Handbuch-Pflicht (CLAUDE.md, Eiserne Regel): jede neue Daten-Weiche
    // protokolliert sich selbst. @MainActor-isoliert, Zugriff aus diesem Actor daher
    // per await (Cross-Actor-Hop) — log() schluckt eigene Fehler bewusst nicht-fatal.
    private let dataFlowLogger: DataFlowLogger?
    private let parser = EstimateRequestParser()
    private let maxEvidences: Int

    // Merkt sich je persistierter Schätzung das Projekt, gegen das geschätzt wurde.
    // `recordAdjustment` kennt nur die `schaetzungsID`, der AuditEntry braucht aber
    // ein `projectID`. Innerhalb einer Sitzung läuft schaetze → recordAdjustment
    // sequenziell, daher genügt eine In-Memory-Map (kein Persistenzbedarf).
    private var projektIDBySession: [String: String] = [:]

    public init(
        provider: PriceAnchorProviding,
        learningStore: LearningStore,
        deviceCatalog: DeviceCatalog? = nil,
        auditStore: AuditStore? = nil,
        drive: (any GoogleDriveFetching)? = nil,
        airtable: (any AirtableRecordCreating)? = nil,
        dataFlowLogger: DataFlowLogger? = nil,
        maxEvidences: Int = 5
    ) {
        self.provider = provider
        self.learningStore = learningStore
        self.deviceCatalog = deviceCatalog
        self.auditStore = auditStore
        self.drive = drive
        self.airtable = airtable
        self.dataFlowLogger = dataFlowLogger
        self.maxEvidences = maxEvidences
    }

    public func schaetze(projektID: String, freitext: String) async throws -> KostenSchaetzung {
        let request = parser.parse(freitext)
        let estimator = EvidenceBasedEstimator(provider: provider, calibrationProvider: learningStore)
        let result = try estimator.estimate(request)
        // Session persistieren — liefert die stabile `schaetzungsID`, gegen die
        // später eine Anpassung gebucht werden kann (append-only im LearningStore).
        let session = try learningStore.saveSession(from: result)
        projektIDBySession[session.id] = projektID
        return Self.map(result, schaetzungsID: session.id, projektID: projektID, maxEvidences: maxEvidences)
    }

    public func geraetepreis(suchbegriff: String) async -> Double? {
        guard let deviceCatalog else { return nil }
        guard let best = deviceCatalog.search(suchbegriff, limit: 1).first,
              let preis = best.sellNet else { return nil }
        return Self.double(preis)
    }

    // Härtung 2026-07-01: lädt das PDF, hasht es (SHA256), prüft gegen bereits
    // importierte Dokumente (document_imports, No-delete/append-only) und legt
    // bei einem echten Neuzugang einen Record in Airtable „Eingehende-Angebote"
    // (appuVMh3KDfKw4OoQ) an. Ein Duplikat erzeugt NUR einen lokalen Log-Eintrag,
    // NIE einen zweiten Airtable-Record — das war der ursprüngliche Zweck der
    // Dedup-Prüfung (keine doppelt gezählten Preis-Anker).
    public func importPDF(driveFileID: String, projektID: String) async throws {
        guard let drive, let airtable else {
            throw KalkulationsEngineError.notYetImplemented(
                "PDF-Import braucht einen injizierten GoogleDriveFetching- und AirtableRecordCreating-Client."
            )
        }
        let data = try await drive.downloadContent(fileID: driveFileID)
        let sha256 = Self.sha256Hex(data)
        let db = try learningStore.database()

        if try db.documentImportExists(sha256: sha256) {
            try db.write { conn in
                try db.insert(DocumentImportEntry(
                    recordID: UUID().uuidString, fileName: driveFileID, sha256: sha256, sizeBytes: data.count,
                    isDuplicate: true, duplicateOf: sha256,
                    note: "Duplikat erkannt (SHA256 bereits vorhanden) — kein Airtable-Schreibvorgang."
                ), conn)
            }
            await dataFlowLogger?.log(
                integrationID: "KALKULATION_PDF_IMPORT", actorUserID: "assistant", action: .success,
                summary: "PDF-Import: Duplikat erkannt (SHA256), kein neuer Record."
            )
            return
        }

        // Bester Dateiname, den wir bekommen können — schlägt der Name-Lookup fehl
        // (z. B. Berechtigungsproblem), fällt es ehrlich auf die Drive-File-ID zurück
        // statt den Import ganz abzubrechen.
        let fileName = (try? await drive.getFileName(folderID: driveFileID)) ?? driveFileID
        let isoNow = ISO8601DateFormatter().string(from: Date())
        // Werte gegen die echten Single-Select-Optionen der Airtable-Tabelle
        // verifiziert (2026-07-01): "eingehend"/"Neu" existieren exakt so.
        let airtableRecordID: String
        do {
            airtableRecordID = try await airtable.createRecord(
                baseID: "appuVMh3KDfKw4OoQ",
                table: "Eingehende-Angebote",
                fields: [
                    "SHA256": .string(sha256),
                    "Datei-Name": .string(fileName),
                    "Projekt-Nr": .string(projektID),
                    "Richtung": .string("eingehend"),
                    "Status": .string("Neu"),
                    "Importiert-am": .string(isoNow),
                ]
            )
        } catch {
            await dataFlowLogger?.log(
                integrationID: "KALKULATION_PDF_IMPORT", actorUserID: "assistant", action: .error,
                errorMessage: String(describing: error), summary: "PDF-Import: Airtable-Schreibvorgang fehlgeschlagen."
            )
            throw error
        }
        try db.write { conn in
            try db.insert(DocumentImportEntry(
                recordID: airtableRecordID, fileName: fileName, sha256: sha256, sizeBytes: data.count,
                isDuplicate: false, note: "Importiert nach Eingehende-Angebote."
            ), conn)
        }
        await dataFlowLogger?.log(
            integrationID: "KALKULATION_PDF_IMPORT", actorUserID: "assistant", action: .success,
            recordsWritten: 1, summary: "PDF-Import: \(fileName) → Eingehende-Angebote (\(airtableRecordID))."
        )
    }

    private static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    public func recordAdjustment(schaetzungsID: String, faktor: Double, grund: String, lernen: Bool = false) async throws {
        // `faktor` ist ein Multiplikator um 1.0 (0.8 = 20 % günstiger). Der
        // LearningStore rechnet intern mit Prozent-Delta.
        let percentDelta = (faktor - 1) * 100
        // Manuelle Freitext-Anpassung → Bauchgefühl (niedriges Reliability-Gewicht),
        // Gesamtschätzung, `grund` als Notiz. `learn: lernen` — nur mit gesetztem
        // Haken fließt die Anpassung in einen Kalibrierungs-Kandidaten ein; ohne
        // Haken bleibt es eine reine Einzelkorrektur (Status quo Schritt 7).
        _ = try learningStore.appendAdjustment(
            sessionID: schaetzungsID,
            percentDelta: percentDelta,
            euroDelta: nil,
            reason: .gutFeeling,
            target: .wholeEstimate,
            learn: lernen,
            note: grund
        )

        // Audit: gleiche Semantik wie bestätigte Assistant-Actions — sichtbar,
        // persistent, nachvollziehbar. Ohne injizierten AuditStore (z. B. in
        // reinen Engine-Unit-Tests) wird die Anpassung dennoch persistiert.
        guard let auditStore else { return }
        let projektID = projektIDBySession[schaetzungsID] ?? schaetzungsID
        let prozent = abs(percentDelta).rounded()
        let richtung = percentDelta >= 0 ? "höher" : "günstiger"
        let summary = "Schätzung \(Int(prozent)) % \(richtung) angepasst (\(grund))"
        let entry = AuditEntry(
            actorUserID: "local-user",
            projectID: projektID,
            action: .estimateAdjusted,
            summary: summary
        )
        try await auditStore.append(entry)
    }

    // MARK: Lern-Loop sichtbar machen

    public func lernUebersicht() async throws -> KalkulationsLernStand {
        Self.mapLernStand(try learningStore.summary())
    }

    public func promote(candidateID: String) async throws {
        let factor = try learningStore.promoteCalibration(candidateID: candidateID)

        // Audit: gleiche Semantik wie eine bestätigte Anpassung — sichtbar und
        // nachvollziehbar. Kalibrierung ist projektübergreifend (Schätz-Brain),
        // daher kein Projektbezug, sondern die Sentinel-`projectID` "kalkulation".
        guard let auditStore else { return }
        let prozent = abs(factor.weightedPercentDelta).rounded()
        let richtung = factor.weightedPercentDelta >= 0 ? "höher" : "günstiger"
        let summary = "Kalibrierung übernommen: \(factor.reason.displayName) · \(factor.target.displayName) · "
            + "\(Int(prozent)) % \(richtung) (n=\(factor.sampleCount))"
        let entry = AuditEntry(
            actorUserID: "local-user",
            projectID: "kalkulation",
            action: .calibrationPromoted,
            summary: summary
        )
        try await auditStore.append(entry)
    }

    // MARK: Mapping LearningSummary → KalkulationsLernStand
    // Core-Typen (CalibrationFactorCandidate/ActiveCalibrationFactor) bleiben in
    // MykilosKalkulationsCore; nur die schlanken Kit-Value-Types gehen ins Widget.

    static func mapLernStand(_ summary: LearningSummary) -> KalkulationsLernStand {
        let faktoren = summary.activeFactors.map { factor in
            KalkulationsFaktor(
                id: factor.id,
                grundLabel: factor.reason.displayName,
                zielLabel: factor.target.displayName,
                prozent: factor.weightedPercentDelta,
                sampleCount: factor.sampleCount
            )
        }
        // Nur promotebare Kandidaten zeigen — bereits promotete sind als aktiver
        // Faktor sichtbar und tauchen nicht doppelt als Knopf auf.
        let kandidaten = summary.candidates
            .filter { $0.status == .candidate || $0.status == .strongCandidate }
            .map { candidate in
                KalkulationsKandidat(
                    id: candidate.id,
                    grundLabel: candidate.reason.displayName,
                    zielLabel: candidate.target.displayName,
                    prozent: candidate.weightedPercentDelta,
                    sampleCount: candidate.sampleCount,
                    statusLabel: candidate.status == .strongCandidate ? "Starker Kandidat" : "Kandidat"
                )
            }
        return KalkulationsLernStand(
            sessions: summary.sessions,
            adjustments: summary.adjustments,
            outliers: summary.outliers,
            aktiveFaktoren: faktoren,
            kandidaten: kandidaten
        )
    }

    // MARK: Mapping EstimateResult → KostenSchaetzung

    static func map(_ result: EstimateResult, schaetzungsID: String, projektID: String, maxEvidences: Int) -> KostenSchaetzung {
        let mitte = double(result.totalBand.expected)
        let kostenboden = double(result.bottomUpCost?.total ?? 0)
        let topEvidences = result.evidence.prefix(maxEvidences).map { evidence in
            PriceEvidence(
                lieferant: evidence.supplier,
                dokument: evidence.sourceFile,
                seite: evidence.page,
                originalZitat: evidence.quote,
                nettoPreis: double(evidence.netPrice)
            )
        }
        return KostenSchaetzung(
            schaetzungsID: schaetzungsID,
            projektID: projektID,
            minNetto: double(result.totalBand.low),
            maxNetto: double(result.totalBand.high),
            mitteNetto: mitte,
            confidence: result.confidence,
            evidenceCount: result.evidence.count,
            kostenboden: kostenboden,
            kostenbodenRatio: mitte > 0 ? kostenboden / mitte : 0,
            topEvidences: Array(topEvidences)
        )
    }

    private static func double(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }
}
