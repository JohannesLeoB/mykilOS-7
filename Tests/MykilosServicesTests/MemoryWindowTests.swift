import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// MARK: - Gedächtnis-Fenster
// Der Assistent bekommt den Verlauf der letzten ~4 Wochen mit (definierter
// Erinnerungshorizont). memoryWindow filtert alt, kappt die Menge und stellt
// sicher, dass der Verlauf nie mit einem assistant-/tool-Turn beginnt (sonst
// bricht ein verwaister tool_result die API).
@MainActor
struct MemoryWindowTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func msg(_ role: ChatRole, daysAgo: Double, text: String = "x") -> ChatMessage {
        ChatMessage(role: role, blocks: [.text(text)], status: .complete,
                    createdAt: now.addingTimeInterval(-daysAgo * 24 * 3600))
    }

    @Test func aeltereAls4WochenFallenRaus() {
        let input = [msg(.user, daysAgo: 40), msg(.assistant, daysAgo: 40), msg(.user, daysAgo: 2)]
        let out = ConversationEngine.memoryWindow(input, now: now)
        #expect(out.count == 1)                    // nur die 2-Tage-Nachricht
        #expect(out.first?.role == .user)
    }

    @Test func beginntNieMitAssistantTurn() {
        // Ein verwaister assistant-Turn am Anfang würde die API brechen.
        let input = [msg(.assistant, daysAgo: 1), msg(.user, daysAgo: 1), msg(.assistant, daysAgo: 1)]
        let out = ConversationEngine.memoryWindow(input, now: now)
        #expect(out.first?.role == .user)
        #expect(out.count == 2)
    }

    @Test func kapptAuf120() {
        let input = (0..<200).map { _ in msg(.user, daysAgo: 1) }
        let out = ConversationEngine.memoryWindow(input, now: now)
        #expect(out.count == 120)
    }

    @Test func leererVerlaufBleibtLeer() {
        #expect(ConversationEngine.memoryWindow([], now: now).isEmpty)
    }
}
