import Foundation
import Observation
import MykilosKit
import MykilosServices

// MARK: - MiniModeSource
// Die fünf Aufmerksamkeits-Quellen des Mini-Modus. Jede hat einen eigenen
// Datenschutz-Toggle (Settings → Datenschutz), gespeichert unter der jeweiligen
// `defaultsKey`. Der Store liest den Wert direkt aus UserDefaults (dieselbe Quelle,
// in die `@AppStorage` in der Settings-UI schreibt) — keine SwiftUI-Abhängigkeit hier.
public enum MiniModeSource: String, CaseIterable, Sendable {
    case calendar   // nächster Termin
    case tasks      // offene Aufgaben (Assistent — lokal)
    case mail       // ungelesene/wichtige Mails
    case timer      // aktiver Clockodo-Timer
    case signals    // unbestätigte Signale

    public var defaultsKey: String {
        switch self {
        case .calendar: "privacy.miniMode.calendar"
        case .tasks:    "privacy.miniMode.tasks"
        case .mail:     "privacy.miniMode.mail"
        case .timer:    "privacy.miniMode.timer"
        case .signals:  "privacy.miniMode.signals"
        }
    }

    public var title: String {
        switch self {
        case .calendar: "Nächster Termin"
        case .tasks:    "Offene Aufgaben"
        case .mail:     "Wichtige Mails"
        case .timer:    "Aktiver Timer"
        case .signals:  "Offene Signale"
        }
    }

    public var icon: String {
        switch self {
        case .calendar: "calendar"
        case .tasks:    "checklist"
        case .mail:     "envelope"
        case .timer:    "timer"
        case .signals:  "sparkle"
        }
    }
}

// MARK: - MiniModeDefaults
// Zentrale, SwiftUI-freie Auswertung der Datenschutz-Toggles. Master-Schalter
// (`privacy.miniMode.enabled`) plus je Quelle ein Schalter. Alle default = an,
// damit ein frischer Start ohne gesetzte Defaults das Feature nicht stumm schaltet.
public enum MiniModeDefaults {
    public static let masterKey = "privacy.miniMode.enabled"

    public static var masterEnabled: Bool {
        object(masterKey) as? Bool ?? true
    }

    public static func sourceEnabled(_ source: MiniModeSource) -> Bool {
        object(source.defaultsKey) as? Bool ?? true
    }

    private static func object(_ key: String) -> Any? {
        UserDefaults.standard.object(forKey: key)
    }
}

// MARK: - MiniModeSnapshot
// Ein rein wertbasierter, gerechneter Zustand. Kein I/O beim Lesen in der UI.
public struct MiniModeSnapshot: Equatable, Sendable {
    /// Nächster Termin (Titel + Startzeit). V1: kein Cache vorhanden → immer nil.
    public var nextEventTitle: String?
    public var nextEventDate: Date?
    /// Offene (lokale) Assistent-Aufgaben.
    public var openTaskCount: Int
    /// Ungelesene/wichtige Mails aus dem Gmail-Cache (nil = kein Cache-Treffer, kein Poll).
    public var unreadMailCount: Int?
    /// Aktiver Timer (Projekt + verstrichene Sekunden), nil = kein Timer läuft.
    public var activeTimerLabel: String?
    public var activeTimerSeconds: Double?
    public var timerIsPaused: Bool
    /// Offene, unbestätigte Signale (Vorschläge).
    public var openSignalCount: Int

    public init(
        nextEventTitle: String? = nil, nextEventDate: Date? = nil,
        openTaskCount: Int = 0, unreadMailCount: Int? = nil,
        activeTimerLabel: String? = nil, activeTimerSeconds: Double? = nil,
        timerIsPaused: Bool = false, openSignalCount: Int = 0
    ) {
        self.nextEventTitle = nextEventTitle
        self.nextEventDate = nextEventDate
        self.openTaskCount = openTaskCount
        self.unreadMailCount = unreadMailCount
        self.activeTimerLabel = activeTimerLabel
        self.activeTimerSeconds = activeTimerSeconds
        self.timerIsPaused = timerIsPaused
        self.openSignalCount = openSignalCount
    }

    /// Zähler-Badge fürs Menüleisten-Icon: Summe der „will Aufmerksamkeit"-Posten
    /// (offene Aufgaben + unbestätigte Signale + ungelesene Mails). Der laufende Timer
    /// ist ein Zustand, kein Rückstand → zählt bewusst NICHT in den Badge (er hat seine
    /// eigene, ruhige Zeile). 0 = kein Badge.
    public var badgeCount: Int {
        openTaskCount + openSignalCount + (unreadMailCount ?? 0)
    }

    public var hasAnything: Bool {
        badgeCount > 0 || activeTimerLabel != nil || nextEventTitle != nil
    }
}

// MARK: - MiniModeStore
// Verdichtet die Mini-Modus-Kennzahlen AUSSCHLIESSLICH aus bereits vorhandenen
// lokalen Caches + laufenden Loops (kein neuer Netzwerk-Poll — eiserne LEAN-Regel):
//   • Timer  → AppState.timer.active   (voll im Speicher, kein I/O)
//   • Signale→ StudioContext.signals   (voll im Speicher, kein I/O)
//   • Aufgaben→ AssistantTasksStore.open() (billiger lokaler GRDB-Read)
//   • Mail   → V1: kein passender Cache-Producer vorhanden → bewusst leer (ehrlicher Folgeschritt)
//   • Termin → V1: kein Cache vorhanden → bewusst leer (ehrlicher Folgeschritt)
//
// Jede Quelle respektiert ihren Datenschutz-Toggle (MiniModeDefaults). Ausgeschaltete
// Quellen werden gar nicht erst gelesen — kein GRDB-Read, kein Cache-Zugriff.
@MainActor
@Observable
public final class MiniModeStore {
    public private(set) var snapshot = MiniModeSnapshot()

    private let timer: TimerStore
    private let tasks: AssistantTasksStore
    private let context: StudioContext

    public init(
        timer: TimerStore,
        tasks: AssistantTasksStore,
        context: StudioContext
    ) {
        self.timer = timer
        self.tasks = tasks
        self.context = context
    }

    /// Rechnet den Snapshot neu aus den vorhandenen Caches. Löst NIE einen Netzwerk-
    /// Poll aus. Bei ausgeschaltetem Master-Toggle wird ein leerer Snapshot gesetzt.
    public func refresh() async {
        guard MiniModeDefaults.masterEnabled else {
            snapshot = MiniModeSnapshot()
            return
        }

        var next = MiniModeSnapshot()

        // Timer — synchron, MainActor, kein I/O.
        if MiniModeDefaults.sourceEnabled(.timer), let active = timer.active {
            next.activeTimerLabel = active.projektTitel.isEmpty ? active.kostenstelle : active.projektTitel
            next.activeTimerSeconds = timer.elapsedSeconds()
            next.timerIsPaused = active.isPaused
        }

        // Signale — synchron, kein I/O. Alle im Array sind per Definition unbestätigt.
        if MiniModeDefaults.sourceEnabled(.signals) {
            next.openSignalCount = context.signals.count
        }

        // Aufgaben — billiger lokaler GRDB-Read über den Actor.
        if MiniModeDefaults.sourceEnabled(.tasks) {
            next.openTaskCount = (try? await tasks.open().count) ?? 0
        }

        // Mail — V1 hat keinen passenden Cache-Producer; bleibt leer (Folgeschritt).
        // Termin — V1 hat keinen Kalender-Cache; bleibt leer (Folgeschritt).

        snapshot = next
    }
}
