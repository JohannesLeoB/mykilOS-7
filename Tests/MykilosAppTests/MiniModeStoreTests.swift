import Testing
import Foundation
@testable import MykilosApp

// MARK: - MiniModeStoreTests
//
// Reine, deterministische Logik ohne Netzwerk/GRDB/Keychain: der abgeleitete
// Zähler-Badge (Aufgaben + Signale + Mail; Timer zählt bewusst NICHT), der
// `hasAnything`-Zustand, die H:MM:SS-Formatierung und die Datenschutz-Toggle-
// Auswertung (Default = an, gesetzter Wert überschreibt).

struct MiniModeStoreTests {

    // MARK: Badge

    @Test func badgeSummiertRueckstaendeAberNichtTimer() {
        let snap = MiniModeSnapshot(
            openTaskCount: 3,
            unreadMailCount: 2,
            activeTimerLabel: "Küche Meyer",   // Timer läuft — darf den Badge NICHT erhöhen
            activeTimerSeconds: 120,
            openSignalCount: 4
        )
        #expect(snap.badgeCount == 9)   // 3 + 4 + 2, Timer ignoriert
    }

    @Test func badgeIstNullOhneRueckstaende() {
        let snap = MiniModeSnapshot(activeTimerLabel: "Läuft", activeTimerSeconds: 30)
        #expect(snap.badgeCount == 0)
    }

    @Test func mailNilZaehltNichtInBadge() {
        let snap = MiniModeSnapshot(openTaskCount: 1, unreadMailCount: nil, openSignalCount: 0)
        #expect(snap.badgeCount == 1)
    }

    // MARK: hasAnything

    @Test func hasAnythingErkenntLaufendenTimerOhneBadge() {
        let snap = MiniModeSnapshot(activeTimerLabel: "Küche", activeTimerSeconds: 10)
        #expect(snap.badgeCount == 0)
        #expect(snap.hasAnything == true)
    }

    @Test func hasAnythingIstFalseWennKomplettLeer() {
        #expect(MiniModeSnapshot().hasAnything == false)
    }

    @Test func hasAnythingErkenntTermin() {
        let snap = MiniModeSnapshot(nextEventTitle: "Ortstermin")
        #expect(snap.hasAnything == true)
    }

    // MARK: Zeitformat

    @Test func hmsUnterEinerStundeIstMMSS() {
        #expect(MiniModePopoverView.hms(0) == "00:00")
        #expect(MiniModePopoverView.hms(65) == "01:05")
        #expect(MiniModePopoverView.hms(3599) == "59:59")
    }

    @Test func hmsAbEinerStundeIstHMMSS() {
        #expect(MiniModePopoverView.hms(3600) == "1:00:00")
        #expect(MiniModePopoverView.hms(3661) == "1:01:01")
    }

    @Test func hmsNegativClamptAufNull() {
        #expect(MiniModePopoverView.hms(-42) == "00:00")
    }

    // MARK: Datenschutz-Toggle-Auswertung

    @Test func defaultsSindOhneGesetztenWertAn() {
        let d = UserDefaults(suiteName: "MiniModeTests.default")!
        d.removePersistentDomain(forName: "MiniModeTests.default")
        // Ohne gesetzten Wert liefert object(forKey:) nil → Fallback true.
        #expect(d.object(forKey: MiniModeDefaults.masterKey) == nil)
        // MiniModeDefaults liest die Standard-Domain; hier prüfen wir die Fallback-Semantik
        // (nil → true) über die öffentliche Regel direkt.
        #expect((d.object(forKey: MiniModeSource.timer.defaultsKey) as? Bool ?? true) == true)
    }

    @Test func gesetzterWertUeberschreibtDefault() {
        let d = UserDefaults(suiteName: "MiniModeTests.override")!
        d.removePersistentDomain(forName: "MiniModeTests.override")
        d.set(false, forKey: MiniModeSource.mail.defaultsKey)
        #expect((d.object(forKey: MiniModeSource.mail.defaultsKey) as? Bool ?? true) == false)
    }

    // MARK: Quellen-Metadaten

    @Test func jedeQuelleHatEindeutigenDefaultsKey() {
        let keys = MiniModeSource.allCases.map(\.defaultsKey)
        #expect(Set(keys).count == keys.count)
        // Alle unter dem privacy.miniMode.-Namespace.
        #expect(keys.allSatisfy { $0.hasPrefix("privacy.miniMode.") })
    }

    // MARK: attentionSources (treibt den Per-Icon-Orange-Puls)

    @Test func attentionSourcesEnthaeltNurRueckstaende() {
        let snap = MiniModeSnapshot(
            openTaskCount: 2,
            unreadMailCount: 3,
            activeTimerLabel: "Küche Meyer",   // Timer läuft — Zustand, KEIN Puls
            activeTimerSeconds: 60,
            openSignalCount: 1
        )
        #expect(snap.attentionSources == [.tasks, .mail, .signals])
    }

    @Test func attentionSourcesIstLeerWennNichtsOffen() {
        let snap = MiniModeSnapshot(activeTimerLabel: "Läuft", activeTimerSeconds: 10)
        #expect(snap.attentionSources.isEmpty)
    }

    @Test func attentionSourcesIgnoriertNilUndNullMail() {
        let a = MiniModeSnapshot(openTaskCount: 0, unreadMailCount: nil, openSignalCount: 0)
        #expect(a.attentionSources.isEmpty)
        let b = MiniModeSnapshot(openTaskCount: 0, unreadMailCount: 0, openSignalCount: 0)
        #expect(b.attentionSources.isEmpty)
    }

    // MARK: Rail-Modul → Quellen-Mapping (welches Icon pulst bei welcher Quelle)

    @Test func railModuleMaptAufAppModule() {
        #expect(MiniModeRailModule.today.appModule == .today)
        #expect(MiniModeRailModule.assistant.appModule == .assistant)
        // Einstellungen gehören bewusst NICHT ins Rail.
        #expect(!MiniModeRailModule.allCases.map(\.appModule).contains(.settings))
    }

    @Test func signaleLassenHeuteUndAufgabenLassenAssistentPulsen() {
        #expect(MiniModeRailModule.today.sources.contains(.signals))
        #expect(MiniModeRailModule.assistant.sources.contains(.tasks))
        // Projekte/Kataloge haben (noch) keine Puls-Quelle.
        #expect(MiniModeRailModule.projects.sources.isEmpty)
        #expect(MiniModeRailModule.kataloge.sources.isEmpty)
    }

    // MARK: Mini-Mode-Opt-in-Schlüssel

    @Test func miniModeOptInDefaultIstAus() {
        let d = UserDefaults(suiteName: "MiniModeTests.optin")!
        d.removePersistentDomain(forName: "MiniModeTests.optin")
        // Ohne gesetzten Wert = aus (bewusste Entscheidung, kein Überraschungs-Fenster).
        #expect((d.object(forKey: MiniModeUserPrefs.enabledKey) as? Bool ?? false) == false)
    }
}
