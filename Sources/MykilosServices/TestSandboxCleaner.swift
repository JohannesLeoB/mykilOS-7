import Foundation
import MykilosKit

// MARK: - TestSandboxCleanupCandidate
public struct TestSandboxCleanupCandidate: Sendable, Equatable {
    public let baseID: String
    public let table: String
    public let recordID: String
    public let name: String?
    public let quelle: String?

    public init(baseID: String, table: String, recordID: String, name: String?, quelle: String?) {
        self.baseID = baseID; self.table = table; self.recordID = recordID
        self.name = name; self.quelle = quelle
    }
}

public struct TestSandboxSkip: Sendable, Equatable {
    public let candidate: TestSandboxCleanupCandidate
    public let reason: String
}

public struct TestSandboxCleanupReport: Sendable, Equatable {
    public let deleted: [TestSandboxCleanupCandidate]
    public let skipped: [TestSandboxSkip]
}

// MARK: - TestSandboxCleaner
// mykilOS 8, Block A: findet + löscht NUR Airtable-Records, die zweifelsfrei als
// TEST markiert sind (siehe `TestMarker` — Doppel-Strategie Präfix + Quelle-Feld).
// Drei unabhängige Sicherungen, bevor irgendetwas gelöscht wird:
//   1. `deletableMap` — eine eigene, winzige Whitelist (Stand 2026-06-30 LEER,
//      siehe `AirtableClient.testDeletableMap`), unabhängig von der Schreib-Whitelist.
//   2. Beide TEST-Marker (Name-Präfix `TEST_` UND `Quelle == "TEST"`) müssen stimmen.
//   3. Re-Fetch unmittelbar vor dem Löschen — verhindert, dass ein Record zwischen
//      „gefunden" und „gelöscht" produktiv umbenannt wurde (TOCTOU-Schutz).
// Idempotent: ein zweiter Lauf findet nichts mehr und löscht entsprechend nichts.
public struct TestSandboxCleaner: Sendable {
    private let fetcher: AirtableFetching
    private let deleter: AirtableRecordDeleting
    private let deletableMap: [String: Set<String>]

    public init(
        fetcher: AirtableFetching, deleter: AirtableRecordDeleting,
        deletableMap: [String: Set<String>] = AirtableClient.testDeletableMap
    ) {
        self.fetcher = fetcher
        self.deleter = deleter
        self.deletableMap = deletableMap
    }

    private func isDeletable(baseID: String, table: String) -> Bool {
        deletableMap[baseID]?.contains(table) == true
    }

    /// Findet TEST-markierte Records in EINER Tabelle. `nameField`/`quelleField`
    /// sind Parameter, weil das Primärfeld je Tabelle anders heißt (z. B.
    /// „Projektname" vs. „Nachname").
    public func findTestArtifacts(
        baseID: String, table: String, nameField: String, quelleField: String = "Quelle"
    ) async throws -> [TestSandboxCleanupCandidate] {
        let records = try await fetcher.fetchRecords(baseID: baseID, table: table)
        return records.compactMap { fields -> TestSandboxCleanupCandidate? in
            let name = fields[nameField]?.stringValue
            let quelle = fields[quelleField]?.stringValue
            guard TestMarker.isTestRecord(name: name, quelle: quelle) else { return nil }
            guard let recordID = fields["_airtableRecordID"]?.stringValue, !recordID.isEmpty else { return nil }
            return TestSandboxCleanupCandidate(
                baseID: baseID, table: table, recordID: recordID, name: name, quelle: quelle)
        }
    }

    /// Löscht NUR Kandidaten, die alle drei Sicherungen bestehen. Niemals fatal —
    /// jeder übersprungene Kandidat landet mit Grund im Report, kein Abbruch.
    public func cleanup(
        _ candidates: [TestSandboxCleanupCandidate], nameField: String, quelleField: String = "Quelle"
    ) async throws -> TestSandboxCleanupReport {
        var deleted: [TestSandboxCleanupCandidate] = []
        var skipped: [TestSandboxSkip] = []

        for candidate in candidates {
            guard isDeletable(baseID: candidate.baseID, table: candidate.table) else {
                skipped.append(TestSandboxSkip(candidate: candidate, reason: "nicht auf TEST-Delete-Whitelist"))
                continue
            }
            let freshRecords = try await fetcher.fetchRecords(baseID: candidate.baseID, table: candidate.table)
            guard let fresh = freshRecords.first(where: { $0["_airtableRecordID"]?.stringValue == candidate.recordID }) else {
                // Schon weg (z. B. zweiter Cleanup-Lauf) — kein Fehler, idempotent.
                skipped.append(TestSandboxSkip(candidate: candidate, reason: "Record nicht mehr vorhanden"))
                continue
            }
            guard TestMarker.isTestRecord(name: fresh[nameField]?.stringValue, quelle: fresh[quelleField]?.stringValue) else {
                skipped.append(TestSandboxSkip(candidate: candidate, reason: "Re-Fetch bestätigt TEST-Marker nicht mehr — NICHT gelöscht"))
                continue
            }
            try await deleter.deleteRecord(baseID: candidate.baseID, table: candidate.table, recordID: candidate.recordID)
            deleted.append(candidate)
        }
        return TestSandboxCleanupReport(deleted: deleted, skipped: skipped)
    }
}
