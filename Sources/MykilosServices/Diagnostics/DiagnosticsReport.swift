import Foundation

// MARK: - DiagnosticsReport (Mandate F — redaktierter Diagnose-Export)
//
// Baut einen klartext-Diagnosebericht für Support/Fehlersuche. NIMMT BEWUSST nur
// nicht-geheime Felder entgegen (App-Identität + Datenstrom-Handshake-Zeilen) — es gibt
// keinen Parameter für Tokens/Keys/Clockodo-Rohdaten, daher kann der Bericht per
// Konstruktion nichts Geheimes enthalten. Reine Funktion → testbar.
public enum DiagnosticsReport {

    public struct Identity: Sendable {
        public let version: String
        public let build: String
        public let commit: String
        public let branch: String
        public let buildDate: String
        public let bundlePath: String
        public let dbPath: String
        public init(version: String, build: String, commit: String, branch: String,
                    buildDate: String, bundlePath: String, dbPath: String) {
            self.version = version; self.build = build; self.commit = commit
            self.branch = branch; self.buildDate = buildDate
            self.bundlePath = bundlePath; self.dbPath = dbPath
        }
    }

    /// Erzeugt den Bericht. `handshakeLines` sind bereits redaktierte Einzeiler
    /// (z. B. "GMAIL_SEARCH · success · vor 2 Min") — niemals Payloads/Fehlertexte mit Daten.
    public static func build(identity: Identity,
                             handshakeCount: Int,
                             handshakeLines: [String],
                             generatedAt: String) -> String {
        var out = """
        mykilOS 7 — Diagnosebericht
        Erzeugt: \(generatedAt)

        App
          Version:  \(identity.version) (Build \(identity.build))
          Commit:   \(identity.commit)
          Branch:   \(identity.branch)
          Gebaut:   \(identity.buildDate)
          Bundle:   \(identity.bundlePath)
          DB:       \(identity.dbPath)

        Datenstrom-Handshakes (\(handshakeCount) gesamt, letzte \(handshakeLines.count))
        """
        if handshakeLines.isEmpty {
            out += "\n  (keine)"
        } else {
            for line in handshakeLines { out += "\n  \(line)" }
        }
        out += "\n\nHinweis: enthält keine Tokens, API-Keys oder Clockodo-Rohdaten."
        return out
    }
}
