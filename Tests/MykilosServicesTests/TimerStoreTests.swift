import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// Block B / S1: das gesamte lokale Zeit-Subsystem. Deterministisch über eine
// injizierte, steuerbare Uhr (`Clock`) — keine echte Wall-Clock im Test.
@MainActor
struct TimerStoreTests {

    /// Steuerbare Uhr für deterministische Zeit.
    final class Clock {
        var current: Date
        init(_ start: Date = Date(timeIntervalSince1970: 1_800_000_000)) { current = start }
        func advance(_ seconds: Double) { current = current.addingTimeInterval(seconds) }
        var nowFn: @MainActor () -> Date { { [unowned self] in self.current } }
    }

    private func makeStore(_ clock: Clock) throws -> TimerStore {
        let db = try GRDBDatabase.inMemory()
        let store = TimerStore(db: db, now: clock.nowFn)
        try store.load()
        return store
    }

    // MARK: Single-Instance-Invariante

    @Test func startWaehrendLaufendemTimerSetztTakeoverStattZweitemTimer() throws {
        let clock = Clock(); let store = try makeStore(clock)
        try store.start(projektNummer: "2026-015", projektTitel: "Vinahl", kostenstelle: "Beratung")
        #expect(store.active?.projektNummer == "2026-015")

        // Start eines ANDEREN Projekts während Timer läuft → kein zweiter Timer, Takeover-Karte.
        try store.start(projektNummer: "2026-016", projektTitel: "Fuckner", kostenstelle: "Montage")
        #expect(store.pendingTakeover != nil)
        #expect(store.active?.projektNummer == "2026-015")   // alter Timer unverändert
    }

    @Test func uebernahmeBeendetAltenTimerUndStartetNeuenNachBuchung() throws {
        let clock = Clock(); let store = try makeStore(clock)
        try store.start(projektNummer: "2026-015", projektTitel: "Vinahl", kostenstelle: "Beratung")
        clock.advance(600)   // 10 Min
        try store.start(projektNummer: "2026-016", projektTitel: "Fuckner", kostenstelle: "Montage")
        try store.confirmTakeover()
        // Alter Lauf wartet jetzt auf Buchung, neuer Timer läuft noch NICHT.
        #expect(store.active == nil)
        #expect(store.pendingDrafts.allSatisfy { $0.projektNummer == "2026-015" })
        // Buchung abschließen → vorgemerkter neuer Timer startet automatisch.
        try store.confirmBooking()
        #expect(store.active?.projektNummer == "2026-016")
        #expect(store.bookedSegments.contains { $0.projektNummer == "2026-015" })
    }

    // MARK: Pause hält / Stopp beendet

    @Test func pauseHaeltZeitStoppBeendet() throws {
        let clock = Clock(); let store = try makeStore(clock)
        try store.start(projektNummer: "P", projektTitel: "P", kostenstelle: "Planung")
        clock.advance(120)               // 2 Min gelaufen
        try store.pause()
        #expect(store.active?.isPaused == true)
        let frozen = store.elapsedSeconds()
        clock.advance(300)               // 5 Min Pause — zählt NICHT
        #expect(abs(store.elapsedSeconds() - frozen) < 0.001)
        try store.resume()
        clock.advance(60)                // 1 Min weiter
        #expect(abs(store.elapsedSeconds() - 180) < 0.001)   // 2 + 1 Min aktiv
        try store.requestStop()
        #expect(store.active == nil)
        #expect(store.pendingDrafts.count == 1)
        #expect(abs(store.pendingDrafts[0].seconds - 180) < 0.001)
    }

    // MARK: Kostenstellen-Wechsel verliert keine Zeit

    @Test func kostenstellenWechselVerliertKeineZeit() throws {
        let clock = Clock(); let store = try makeStore(clock)
        try store.start(projektNummer: "P", projektTitel: "P", kostenstelle: "Beratung")
        clock.advance(300)               // 5 Min Beratung
        try store.switchKostenstelle(to: "Montage")
        #expect(store.active?.kostenstelle == "Montage")
        #expect(store.pendingDrafts.count == 1)              // Beratung-Abschnitt als Draft
        clock.advance(180)               // 3 Min Montage
        try store.requestStop()
        // Gesamtsumme = 5 + 3 Min, aufgeteilt auf zwei Kostenstellen, nichts verloren.
        let total = store.pendingDrafts.reduce(0) { $0 + $1.seconds }
        #expect(abs(total - 480) < 0.001)
        #expect(store.pendingDrafts.contains { $0.kostenstelle == "Beratung" && abs($0.seconds - 300) < 0.001 })
        #expect(store.pendingDrafts.contains { $0.kostenstelle == "Montage" && abs($0.seconds - 180) < 0.001 })
    }

    // MARK: Doppelte Bestätigung committet erst im zweiten Schritt

    @Test func doppelteBestaetigungBuchtErstImZweitenSchritt() throws {
        let clock = Clock(); let store = try makeStore(clock)
        try store.start(projektNummer: "P", projektTitel: "P", kostenstelle: "Planung")
        clock.advance(2820)              // 47 Min
        try store.requestStop()          // Schritt 1: Übersicht — NOCH NICHT gebucht
        #expect(store.bookedSegments.isEmpty)
        #expect(store.pendingDrafts.count == 1)
        try store.confirmBooking()       // Schritt 2: endgültig
        #expect(store.bookedSegments.count == 1)
        #expect(store.pendingDrafts.isEmpty)
        #expect(abs(store.bookedSegments[0].seconds - 2820) < 0.001)
    }

    @Test func verwerfenBuchtNicht() throws {
        let clock = Clock(); let store = try makeStore(clock)
        try store.start(projektNummer: "P", projektTitel: "P", kostenstelle: "Planung")
        clock.advance(600)
        try store.requestStop()
        try store.cancelBooking()
        #expect(store.bookedSegments.isEmpty)
        #expect(store.pendingDrafts.isEmpty)
    }

    // MARK: Cold-Start — Buchung überlebt Neustart

    @Test func gebuchtesSegmentUeberlebtNeustart() throws {
        let clock = Clock()
        let db = try GRDBDatabase.inMemory()
        let storeA = TimerStore(db: db, now: clock.nowFn)
        try storeA.load()
        try storeA.start(projektNummer: "2026-015", projektTitel: "Vinahl", kostenstelle: "Beratung")
        clock.advance(900)
        try storeA.requestStop()
        try storeA.confirmBooking()

        let storeB = TimerStore(db: db, now: clock.nowFn)
        try storeB.load()
        #expect(storeB.bookedSegments.count == 1)
        #expect(storeB.bookedSegments[0].projektNummer == "2026-015")
        #expect(abs(storeB.bookedSegments[0].seconds - 900) < 0.001)
    }

    @Test func offeneBuchungUeberlebtNeustart() throws {
        let clock = Clock()
        let db = try GRDBDatabase.inMemory()
        let storeA = TimerStore(db: db, now: clock.nowFn)
        try storeA.load()
        try storeA.start(projektNummer: "P", projektTitel: "P", kostenstelle: "Planung")
        clock.advance(300)
        try storeA.requestStop()   // offen, nicht bestätigt

        let storeB = TimerStore(db: db, now: clock.nowFn)
        try storeB.load()
        #expect(storeB.pendingDrafts.count == 1)   // Buchungskarte erscheint nach Neustart wieder
        #expect(storeB.bookedSegments.isEmpty)
    }

    // MARK: Puls-Erinnerung — Reset + 3-Min-Beruhigung

    @Test func pulsLogikPulstNurInDenErstenDreiMinutenNachMarke() {
        let anchor = Date(timeIntervalSince1970: 0)
        let interval: Double = 60 * 60   // 60 Min
        func pulse(_ afterSeconds: Double) -> Bool {
            TimerStore.shouldPulse(anchor: anchor, now: anchor.addingTimeInterval(afterSeconds), intervalSeconds: interval)
        }
        #expect(pulse(30 * 60) == false)        // vor erster Marke: ruhig
        #expect(pulse(60 * 60) == true)         // genau auf Marke: pulst
        #expect(pulse(61 * 60) == true)         // 1 Min nach Marke: pulst
        #expect(pulse(63.5 * 60) == false)      // >3 Min nach Marke: beruhigt
        #expect(pulse(90 * 60) == false)        // mittendrin: ruhig
        #expect(pulse(120 * 60) == true)        // zweite Marke: pulst wieder
    }

    @Test func checkInResettetErinnerungsUhr() throws {
        let clock = Clock(); let store = try makeStore(clock)
        try store.setPulseInterval(minutes: 60)
        try store.start(projektNummer: "P", projektTitel: "P", kostenstelle: "Planung")
        clock.advance(61 * 60)           // 61 Min → würde pulsen
        #expect(store.shouldPulse() == true)
        store.resetReminder()            // Check-in „Läuft weiter"
        #expect(store.shouldPulse() == false)   // Uhr zurückgesetzt → ruhig
        clock.advance(61 * 60)           // erneut 61 Min nach Reset
        #expect(store.shouldPulse() == true)
    }

    @Test func pausierterTimerPulstNie() throws {
        let clock = Clock(); let store = try makeStore(clock)
        try store.setPulseInterval(minutes: 60)
        try store.start(projektNummer: "P", projektTitel: "P", kostenstelle: "Planung")
        clock.advance(61 * 60)
        try store.pause()
        #expect(store.shouldPulse() == false)
    }

    // MARK: Zielkontingent

    @Test func zielkontingentUeberlebtNeustart() throws {
        let clock = Clock()
        let db = try GRDBDatabase.inMemory()
        let storeA = TimerStore(db: db, now: clock.nowFn)
        try storeA.load()
        try storeA.setZielkontingent(projektNummer: "2026-015", stunden: 40)

        let storeB = TimerStore(db: db, now: clock.nowFn)
        try storeB.load()
        #expect(storeB.zielkontingent(for: "2026-015")?.zielStunden == 40)
        #expect(storeB.zielkontingent(for: "2026-015")?.herkunft == .manuell)
    }

    // MARK: Formatierung

    @Test func formatHilfsfunktionen() {
        #expect(TimerFormat.clock(3725) == "01:02:05")
        #expect(TimerFormat.clock(0) == "00:00:00")
        #expect(TimerFormat.human(2820) == "47 Min")
        #expect(TimerFormat.human(3600) == "1 Std")
        #expect(TimerFormat.human(4200) == "1 Std 10 Min")
    }
}
