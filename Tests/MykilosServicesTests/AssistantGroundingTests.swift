import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

struct AssistantGroundingTests {

    private func montag29Juni2026() -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return cal.date(from: DateComponents(year: 2026, month: 6, day: 29, hour: 12))!
    }

    private let kuecheMeyer = Project(
        projectNumber: "ME-24", title: "Küche Meyer", kind: .kitchen,
        customerNumber: "K-1", phase: "Ausführungsplanung"
    )

    @Test func promptLoestWochentagUndDatumAuf() {
        let prompt = AssistantGrounding.systemPrompt(
            focusedProjectID: nil, signals: [], projects: [], now: montag29Juni2026()
        )
        #expect(prompt.contains("Montag"))
        #expect(prompt.contains("29. Juni 2026"))
    }

    @Test func promptNenntFokusprojektUndSignale() {
        let prompt = AssistantGrounding.systemPrompt(
            focusedProjectID: "ME-24",
            signals: [.deadlineNear(projectID: "ME-24", days: 2), .offerDetected(projectID: "ME-24", label: "Naturstein")],
            projects: [kuecheMeyer],
            now: montag29Juni2026()
        )
        #expect(prompt.contains("Küche Meyer"))
        #expect(prompt.contains("ME-24"))
        #expect(prompt.contains("Ausführungsplanung"))
        #expect(prompt.contains("Deadline in ME-24: 2 Tage"))
        #expect(prompt.contains("Naturstein"))
    }

    @Test func promptZeigtKeineSignaleSauber() {
        let prompt = AssistantGrounding.systemPrompt(
            focusedProjectID: nil, signals: [], projects: [kuecheMeyer], now: montag29Juni2026()
        )
        #expect(prompt.contains("Offene Signale:\n- keine"))
    }

    @Test func promptHaertetGegenHalluzinationUndAutonomeWrites() {
        let prompt = AssistantGrounding.systemPrompt(
            focusedProjectID: nil, signals: [], projects: [], now: montag29Juni2026()
        )
        #expect(prompt.contains("Erfinde keine Fakten"))
        #expect(prompt.contains("KEINE Live-Zugriffe"))
        #expect(prompt.contains("nur als Vorschlag"))
    }

    @Test func promptNenntNutzerMitProfilUndRolle() {
        let profile = UserProfile(displayName: "Johannes", role: "Design & Projektleitung", updatedAt: Date())
        let prompt = AssistantGrounding.systemPrompt(
            profile: profile,
            focusedProjectID: nil, signals: [], projects: [], now: montag29Juni2026()
        )
        #expect(prompt.contains("Du sprichst mit Johannes"))
        #expect(prompt.contains("Design & Projektleitung"))
    }

    @Test func promptOhneProfilNenntKeinenNamen() {
        let prompt = AssistantGrounding.systemPrompt(
            profile: nil,
            focusedProjectID: nil, signals: [], projects: [], now: montag29Juni2026()
        )
        #expect(prompt.contains("Du sprichst mit") == false)
    }

    @Test func promptMitToolsEnabledNenntErlaubteTools() {
        let prompt = AssistantGrounding.systemPrompt(
            focusedProjectID: nil, signals: [], projects: [], now: montag29Juni2026(),
            toolsEnabled: true
        )
        #expect(prompt.contains("search_gmail"))
        #expect(prompt.contains("list_calendar_events"))
        #expect(prompt.contains("suggest_calendar_event"))   // Phase 3: Kalender-Link-Tool erwähnt
        // toolsEnabled=true: LIVE-Zugriff auf Gmail/Kalender, aber nicht Mail/Kalender als "KEINE"-Pfad
        #expect(prompt.contains("LIVE-Lesezugriff"))
        #expect(prompt.contains("KEINE Live-Zugriffe auf \nMails, Kalender") == false)
    }

    @Test func promptOhneToolsEnabledVerbieteLiveZugriffe() {
        let prompt = AssistantGrounding.systemPrompt(
            focusedProjectID: nil, signals: [], projects: [], now: montag29Juni2026(),
            toolsEnabled: false
        )
        // toolsEnabled=false: kein Hinweis auf erlaubte Tools, generelles Verbot
        #expect(prompt.contains("KEINE Live-Zugriffe"))
        #expect(prompt.contains("search_gmail") == false)
        #expect(prompt.contains("LIVE-Lesezugriff") == false)
    }
}
