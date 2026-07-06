import Foundation
import MykilosKit

// MARK: - DatenschutzExport (Vision-Doku "Nutzerprofil & Datenschutz", DSGVO Art. 15/20)
// Eine EHRLICHE, reale Übersicht der Daten, die mykilOS lokal über den aktuellen Bewohner hält.
// Bewusst NUR das, was heute strukturiert vorliegt (Profil, Notizen, Aufgaben, Chat-Nachrichten-
// zahl je Bereich). Externe Dienste (Google/Clockodo/ClickUp/…) bleiben bei ihrem jeweiligen
// Anbieter und sind hier NICHT enthalten — kein Krake-Datensammler, jeder Dienst bleibt die
// eigene Quelle der Wahrheit für seine Daten.
public struct DatenschutzExport: Codable, Equatable, Sendable {
    public var erstelltAm: Date
    public var profil: UserProfile?
    public var notizen: [String]
    public var aufgaben: [String]
    /// Scope-Schlüssel (z. B. "home", "project:2026-015") → Anzahl Nachrichten in diesem Bereich.
    public var chatNachrichtenJeBereich: [String: Int]

    public init(
        erstelltAm: Date = Date(), profil: UserProfile?, notizen: [String],
        aufgaben: [String], chatNachrichtenJeBereich: [String: Int]
    ) {
        self.erstelltAm = erstelltAm
        self.profil = profil
        self.notizen = notizen
        self.aufgaben = aufgaben
        self.chatNachrichtenJeBereich = chatNachrichtenJeBereich
    }
}

// MARK: - DatenschutzExportService
@MainActor
public enum DatenschutzExportService {
    public static func erstelle(
        profile: ProfileStore,
        notes: AssistantNotesStore,
        tasks: AssistantTasksStore,
        chat: ChatStore,
        projektNummern: [String]
    ) async -> DatenschutzExport {
        let notizen: [String]
        do { notizen = try await notes.all().map(\.body) } catch { notizen = [] }
        let aufgaben: [String]
        do { aufgaben = try await tasks.all().map(\.title) } catch { aufgaben = [] }

        var counts: [String: Int] = [:]
        let bereiche: [ChatScope] = [.home] + projektNummern.map { .project($0) }
        for bereich in bereiche {
            do {
                try chat.loadIfNeeded(bereich)
                counts[bereich.rawKey] = chat.messages(for: bereich).count
            } catch {
                // Dieser eine Bereich bleibt aus der Übersicht ausgespart (sichtbar als
                // fehlender Key), statt den ganzen Export abzubrechen.
            }
        }

        return DatenschutzExport(
            profil: profile.profile,
            notizen: notizen,
            aufgaben: aufgaben,
            chatNachrichtenJeBereich: counts
        )
    }
}
