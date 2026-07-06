import Foundation
import UserNotifications
import MykilosKit

// MARK: - TaskAlarmSound (Johannes-Feedback 2026-07-06/07, Aufgaben-Spalten)
// ⚠️ Ehrlicher Stand: UNNotificationSound(named:) sucht Audiodateien im App-Bundle
// (Library/Sounds), NICHT beliebige macOS-Systemklänge per Namen — ohne selbst
// mitgelieferte .aiff/.caf-Dateien gäbe es nur "so tun als ob" mehrere Töne, die real
// nie unterschiedlich klingen. Deshalb bewusst nur zwei ECHTE, verifizierbare Optionen;
// weitere Töne brauchen tatsächlich mitgelieferte Audiodateien (späterer Schritt).
public enum TaskAlarmSound: String, CaseIterable, Codable, Sendable {
    case standard, lautlos

    public var label: String {
        switch self {
        case .standard: return "Standard"
        case .lautlos:  return "Lautlos"
        }
    }

    var unNotificationSound: UNNotificationSound? {
        switch self {
        case .standard: return .default
        case .lautlos:  return nil
        }
    }
}

// MARK: - TaskAlarmPreferences
// Globale, nutzerlokale Einstellung (UserDefaults, wie mail.signature) — kein GRDB
// nötig für eine reine An/Aus- + Ton-Präferenz. Settings → Mitteilungen liest/schreibt
// dieselben Schlüssel.
public enum TaskAlarmPreferences {
    private static let enabledKey = "aufgaben.alarm.global"
    private static let soundKey = "aufgaben.alarm.ton"

    /// Default true — Alarme sind an, bis der Nutzer sie bewusst abschaltet.
    public static var global: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    public static var sound: TaskAlarmSound {
        get { TaskAlarmSound(rawValue: UserDefaults.standard.string(forKey: soundKey) ?? "") ?? .standard }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: soundKey) }
    }
}

// MARK: - TaskAlarmScheduler
// Echte lokale macOS-Mitteilung bei Fälligkeit einer privaten Aufgabe
// (UNUserNotificationCenter — kein Server, kein Push, rein lokal). Respektiert
// TaskAlarmPreferences.global (Master-Aus) und task.alarmAktiv (pro Aufgabe).
public enum TaskAlarmScheduler {
    /// Fragt die Systemberechtigung an (einmalig; wiederholte Aufrufe sind ein No-Op,
    /// falls der Nutzer schon entschieden hat). Best-effort — eine verweigerte
    /// Berechtigung blockiert die App nicht, Alarme bleiben dann stumm/unsichtbar.
    public static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            // Verweigerte/fehlgeschlagene Berechtigung ist kein App-Fehler — Alarme
            // bleiben dann einfach stumm (reschedule() prüft ohnehin nicht den Status).
        }
    }

    /// Reine, getestete Entscheidung: soll für diese Aufgabe JETZT ein Alarm geplant sein?
    /// Getrennt von der eigentlichen UNUserNotificationCenter-Verdrahtung (die ohne echte/
    /// gemockte Notification-Center-Instanz nicht sinnvoll unit-testbar ist).
    static func sollAlarmieren(_ task: AssistantTask, globalErlaubt: Bool, jetzt: Date) -> Bool {
        guard task.alarmAktiv, task.done == false, globalErlaubt,
              let dueDate = task.dueDate else { return false }
        return dueDate > jetzt
    }

    /// Plant (oder ersetzt) den Alarm für eine Aufgabe. Kein Effekt, wenn die Aufgabe
    /// erledigt ist, keinen Fälligkeitstermin hat, ihr eigener Alarm aus ist, oder der
    /// globale Schalter aus ist — in jedem dieser Fälle wird stattdessen aufgeräumt
    /// (cancel), damit kein verwaister Alarm übrig bleibt.
    public static func reschedule(_ task: AssistantTask) async {
        guard sollAlarmieren(task, globalErlaubt: TaskAlarmPreferences.global, jetzt: Date()),
              let dueDate = task.dueDate else {
            cancel(taskID: task.id)
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "Aufgabe fällig"
        content.body = task.title
        if let sound = TaskAlarmPreferences.sound.unNotificationSound {
            content.sound = sound
        }
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier(for: task.id), content: content, trigger: trigger)
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Scheitert nur bei fehlender Berechtigung/Systemfehler — Aufgabe bleibt
            // gespeichert, nur der Alarm fällt in diesem Fall stumm aus.
        }
    }

    public static func cancel(taskID: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier(for: taskID)])
    }

    private static func identifier(for taskID: String) -> String { "myk.aufgabe.\(taskID)" }
}
