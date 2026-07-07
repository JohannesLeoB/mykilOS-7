import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

// MARK: - SignalNotificationDispatcher (Backlog "native macOS-Push-Benachrichtigungen",
// Johannes 2026-07-02 spät, umgesetzt 2026-07-07)
// Testet nur die reine Inhalts-Entscheidung (inhalt(fuer:)) — die eigentliche
// UNUserNotificationCenter-Verdrahtung ist ohne echte/gemockte Center-Instanz nicht
// sinnvoll unit-testbar (gleiches Muster wie TaskAlarmScheduler.sollAlarmieren).

struct SignalNotificationDispatcherTests {

    @Test func offerDetectedErzeugtInhalt() {
        let signal = WidgetSignal.offerDetected(projectID: "2026-001", label: "Angebot.pdf")
        let inhalt = SignalNotificationDispatcher.inhalt(fuer: signal)
        #expect(inhalt?.titel == "Neues Angebot erkannt")
        #expect(inhalt?.text == "2026-001: Angebot.pdf")
    }

    @Test func drawingDetectedErzeugtInhalt() {
        let signal = WidgetSignal.drawingDetected(projectID: "2026-002", label: "Werkzeichnung.pdf")
        let inhalt = SignalNotificationDispatcher.inhalt(fuer: signal)
        #expect(inhalt?.titel == "Neue Werkzeichnung erkannt")
        #expect(inhalt?.text == "2026-002: Werkzeichnung.pdf")
    }

    @Test func andereSignaleErzeugenKeinenInhalt() {
        let signale: [WidgetSignal] = [
            .driveFileAdded(projectID: "2026-001", fileName: "x.pdf"),
            .projectFocused(projectID: "2026-001"),
            .reviewSuggested(projectID: "2026-001", label: "x"),
            .budgetThresholdCrossed(projectID: "2026-001", ratio: 0.9),
            .deadlineNear(projectID: "2026-001", days: 3),
        ]
        for signal in signale {
            #expect(SignalNotificationDispatcher.inhalt(fuer: signal) == nil)
        }
    }
}
