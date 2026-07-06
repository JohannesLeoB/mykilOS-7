import AppKit
import Foundation

// MARK: - AppRelaunch
// Startet die App neu — für den Multi-User-Nutzer-Wechsel: nach dem „Abmelden"
// muss AppState.init EINMAL frisch laufen, damit alle per-User-Stores mit der
// neuen (Gast-)userID gebaut werden. Das ist der bewusst gewählte, minimal-
// invasive Wechsel (kein riskanter In-Prozess-Hot-Switch).
//
// Mechanik: ein losgelöster Shell-Subprozess wartet kurz, bis DIESE Instanz
// beendet ist, und startet dann via `open -n` eine frische Instanz. Grund für
// das `sleep`: der Single-Instance-Guard in MykilOS6App.init beendet eine zweite
// Instanz, solange die alte noch läuft — der Neustart darf also erst nach dem
// Beenden feuern. mykilOS ist NICHT App-Sandboxed (nur Kamera-Entitlement) →
// Process/open ist erlaubt (Developer-ID + Hardened Runtime, außerhalb App Store).
public enum AppRelaunch {
    @MainActor
    public static func relaunch() {
        let bundlePath = Bundle.main.bundlePath
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        // Pfad in Quotes (Bundle-Name enthält Leerzeichen, z. B. „mykilOS 11.1.0-alpha4.app").
        task.arguments = ["-c", "sleep 1; open -n \"\(bundlePath)\""]
        do {
            try task.run()
        } catch {
            return   // Relaunch fehlgeschlagen — App läuft weiter statt zu crashen.
        }
        NSApp.terminate(nil)
    }
}
