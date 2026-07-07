import Foundation
import UserNotifications
import MykilosKit

// MARK: - SignalNotificationPreferences (Backlog "native macOS-Push-Benachrichtigungen",
// Johannes 2026-07-02 spät, umgesetzt 2026-07-07)
// Gleiches Muster wie TaskAlarmPreferences: globale, nutzerlokale UserDefaults-Präferenz.
// ⚠️ Gilt NUR für den Mac (UNUserNotificationCenter, lokal) — eine Zustellung aufs Handy
// bräuchte eigene Infrastruktur (Pushover/ntfy.sh-Relay, CloudKit+iOS-App oder eigene APNs),
// die laut Backlog bewusst NICHT Teil dieses Schritts ist (Johannes-Entscheidung offen).
public enum SignalNotificationPreferences {
    private static let enabledKey = "signale.mitteilungen.global"

    /// Default true — Mitteilungen sind an, bis der Nutzer sie bewusst abschaltet.
    public static var aktiv: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }
}

// MARK: - SignalNotificationDispatcher
// Echte lokale macOS-Mitteilung für die Signale, die schon heute über den bestehenden
// Hintergrund-Poll laufen (`AppState.pollAllActiveProjectsForOffers` → `DriveOfferWatcher`):
// `offerDetected` und `drawingDetected`. Das ist bewusst der "fehlende Zustellweg" aus dem
// Backlog — die Signale existierten schon (Signal-Strip in TodayView), nur ohne System-
// Banner/Notification-Center-Eintrag, wenn die App nicht gerade offen im Vordergrund ist.
//
// Andere Signal-Arten (driveFileAdded, projectFocused, reviewSuggested,
// budgetThresholdCrossed, deadlineNear) lösen bewusst KEINE Mitteilung aus — driveFileAdded
// ist zu unspezifisch für einen Banner (jede x-beliebige neue Datei), die übrigen sind
// interne Ableitungen ohne eigenen, für den Nutzer verständlichen Text an dieser Stelle.
// `myClickUpTaskDueSoon` (2026-07-07) löst bewusst DOCH aus — es ist per Konstruktion
// personalisiert (nur EIGENE Aufgaben, gefiltert über die eigene clickUpMemberID),
// anders als das projektweite deadlineNear oben.
public enum SignalNotificationDispatcher {
    /// Reine, testbare Entscheidung: Titel + Text für ein Signal, oder nil, wenn dieses
    /// Signal keine Mitteilung auslösen soll. Getrennt von der eigentlichen
    /// UNUserNotificationCenter-Verdrahtung (gleiches Muster wie TaskAlarmScheduler).
    static func inhalt(fuer signal: WidgetSignal) -> (titel: String, text: String)? {
        switch signal {
        case let .offerDetected(projectID, label):
            return ("Neues Angebot erkannt", "\(projectID): \(label)")
        case let .drawingDetected(projectID, label):
            return ("Neue Werkzeichnung erkannt", "\(projectID): \(label)")
        case let .myClickUpTaskDueSoon(projectID, taskName, days):
            // Personalisiert (2026-07-07): nur EIGENE Aufgaben, deshalb hier — anders als
            // deadlineNear (projektweit, jede Fälligkeit egal wer), das bewusst still bleibt.
            let faelligkeit = days == 0 ? "heute fällig" : (days == 1 ? "morgen fällig" : "in \(days) Tagen fällig")
            return ("Eigene Aufgabe \(faelligkeit)", "\(projectID): \(taskName)")
        case .driveFileAdded, .projectFocused, .reviewSuggested, .budgetThresholdCrossed, .deadlineNear:
            return nil
        }
    }

    /// Fragt die Systemberechtigung an (einmalig; No-Op, falls schon entschieden).
    public static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            // Verweigerte/fehlgeschlagene Berechtigung ist kein App-Fehler — Mitteilungen
            // bleiben dann einfach stumm.
        }
    }

    /// Feuert eine sofortige lokale Mitteilung für ein unterstütztes Signal — kein Effekt,
    /// wenn die globale Präferenz aus ist oder das Signal keine Mitteilung auslöst.
    public static func benachrichtige(fuer signal: WidgetSignal) async {
        guard SignalNotificationPreferences.aktiv, let inhalt = Self.inhalt(fuer: signal) else { return }
        await requestAuthorizationIfNeeded()
        let content = UNMutableNotificationContent()
        content.title = inhalt.titel
        content.body = inhalt.text
        content.sound = .default
        // nil-Trigger = sofortige Zustellung (kein Kalender-/Zeit-Trigger nötig).
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Scheitert nur bei fehlender Berechtigung/Systemfehler — die In-App-Signal-
            // Anzeige (TodayView-Signal-Strip) bleibt davon unberührt.
        }
    }
}
