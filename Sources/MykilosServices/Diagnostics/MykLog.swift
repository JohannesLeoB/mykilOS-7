import Foundation
import os

// MARK: - MykLog (Mandate F — strukturierte Diagnose über os.Logger)
//
// Ein Subsystem, klar getrennte Kategorien. Ersetzt das frühere Schweigen (kein print,
// kein Logger) durch nachvollziehbare, in Console.app filterbare Ereignisse — ohne je
// Secrets zu loggen (Tokens/Keys gehören nur in den Keychain, nie in os_log).
public enum MykLog {
    public static let subsystem = "de.mykilos.mykilos6"

    public static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
    public static let db        = Logger(subsystem: subsystem, category: "db")
    public static let drive     = Logger(subsystem: subsystem, category: "drive")
    public static let offers    = Logger(subsystem: subsystem, category: "offers")
    public static let chat      = Logger(subsystem: subsystem, category: "chat")
    public static let backup    = Logger(subsystem: subsystem, category: "backup")
}
