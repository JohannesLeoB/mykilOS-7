import Testing
import Foundation
import GRDB
@testable import MykilosServices

// MARK: - Mandate F — wiederherstellbarer DB-Start + redaktierter Diagnose-Export

struct GRDBDatabaseRecoverabilityTests {

    @Test func oeffnetGueltigenPfadUndUeberlebtRoundtrip() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("grdbboot-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let db = try GRDBDatabase(url: dir.appendingPathComponent("db.sqlite"))
        try db.write { d in
            try d.execute(sql: "CREATE TABLE probe(x INTEGER)")
            try d.execute(sql: "INSERT INTO probe VALUES (42)")
        }
        let value = try db.read { d in try Int.fetchOne(d, sql: "SELECT x FROM probe") }
        #expect(value == 42)
    }

    @Test func wirftBeiUnbeschreibbaremPfadStattZuCrashen() {
        // Eltern-Verzeichnis existiert nicht und wird NICHT angelegt → Öffnen wirft
        // regulär (kein try!-Trap). Genau das macht AppDatabase.boot() abfangbar.
        let bad = URL(fileURLWithPath: "/nonexistent-\(UUID().uuidString)/db.sqlite")
        #expect(throws: (any Error).self) {
            _ = try GRDBDatabase(url: bad)
        }
    }
}

struct DiagnosticsReportTests {

    private func identity() -> DiagnosticsReport.Identity {
        DiagnosticsReport.Identity(
            version: "6.4.0", build: "4", commit: "abc123", branch: "polish/dampflok",
            buildDate: "2026-06-29T10:00Z", bundlePath: "/Apps/mykilOS 6.app", dbPath: "/x/db.sqlite"
        )
    }

    @Test func enthaeltIdentitaetUndHandshakes() {
        let report = DiagnosticsReport.build(
            identity: identity(), handshakeCount: 3,
            handshakeLines: ["GMAIL_SEARCH · SUCCESS · gerade eben"], generatedAt: "jetzt"
        )
        #expect(report.contains("6.4.0"))
        #expect(report.contains("abc123"))
        #expect(report.contains("polish/dampflok"))
        #expect(report.contains("/x/db.sqlite"))
        #expect(report.contains("GMAIL_SEARCH · SUCCESS"))
        #expect(report.contains("3 gesamt"))
    }

    @Test func enthaeltKeineSecretMarker() {
        // Redaktions-Vertrag: der Builder nimmt keine Geheimnisse entgegen → der
        // Bericht kann per Konstruktion keine Token-/Key-Spuren enthalten.
        let report = DiagnosticsReport.build(
            identity: identity(), handshakeCount: 0, handshakeLines: [], generatedAt: "t"
        )
        for marker in ["Bearer ", "apiKey", "pat_", "api_token", "sk-ant"] {
            #expect(report.contains(marker) == false, "Bericht enthält verdächtigen Marker '\(marker)'")
        }
        #expect(report.contains("keine Tokens"))
        #expect(report.contains("(keine)"))   // leere Handshake-Liste
    }
}
