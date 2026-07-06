import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// Johannes-Feedback (Aufgaben-Spalten): private Aufgaben mit Fälligkeit + echtem Alarm.
// Nur die REINE Entscheidungslogik ist ohne echtes/gemocktes UNUserNotificationCenter
// sinnvoll unit-testbar (siehe Kommentar in TaskAlarmScheduler.swift).
struct TaskAlarmSchedulerTests {

    private let jetzt = Date(timeIntervalSince1970: 1_800_000_000)

    private func task(alarmAktiv: Bool, done: Bool = false, dueDate: Date?) -> AssistantTask {
        AssistantTask(title: "Test", done: done, dueDate: dueDate, alarmAktiv: alarmAktiv)
    }

    @Test func alarmiertNurMitAllenBedingungenErfuellt() {
        let t = task(alarmAktiv: true, dueDate: jetzt.addingTimeInterval(3600))
        #expect(TaskAlarmScheduler.sollAlarmieren(t, globalErlaubt: true, jetzt: jetzt) == true)
    }

    @Test func keinAlarmWennAufgabeSelbstAlarmAus() {
        let t = task(alarmAktiv: false, dueDate: jetzt.addingTimeInterval(3600))
        #expect(TaskAlarmScheduler.sollAlarmieren(t, globalErlaubt: true, jetzt: jetzt) == false)
    }

    @Test func keinAlarmWennGlobalAus() {
        let t = task(alarmAktiv: true, dueDate: jetzt.addingTimeInterval(3600))
        #expect(TaskAlarmScheduler.sollAlarmieren(t, globalErlaubt: false, jetzt: jetzt) == false)
    }

    @Test func keinAlarmWennErledigt() {
        let t = task(alarmAktiv: true, done: true, dueDate: jetzt.addingTimeInterval(3600))
        #expect(TaskAlarmScheduler.sollAlarmieren(t, globalErlaubt: true, jetzt: jetzt) == false)
    }

    @Test func keinAlarmOhneFaelligkeit() {
        let t = task(alarmAktiv: true, dueDate: nil)
        #expect(TaskAlarmScheduler.sollAlarmieren(t, globalErlaubt: true, jetzt: jetzt) == false)
    }

    @Test func keinAlarmFuerVergangeneFaelligkeit() {
        let t = task(alarmAktiv: true, dueDate: jetzt.addingTimeInterval(-3600))
        #expect(TaskAlarmScheduler.sollAlarmieren(t, globalErlaubt: true, jetzt: jetzt) == false)
    }

    @Test func alarmSoundLabelsSindGesetzt() {
        #expect(TaskAlarmSound.standard.label == "Standard")
        #expect(TaskAlarmSound.lautlos.label == "Lautlos")
    }
}
