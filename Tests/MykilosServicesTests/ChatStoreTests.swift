import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// MARK: - ChatStore Phase-0-Tests
// Beweist: der Assistenten-Chat-Verlauf lebt regelkonform (Cold-Start,
// Scope-Isolation, Streaming-Abschluss, Fehler-Turn, SaveState, Scope-Key).
@MainActor
struct ChatStoreTests {

    // Fixe, ganzzahlige Zeitstempel → bitgenauer Double-Roundtrip.
    private func at(_ unix: Double) -> Date { Date(timeIntervalSince1970: unix) }

    // MARK: Cold-Start: Verlauf überlebt Neustart
    @Test func verlaufUeberlebtNeustart() throws {
        let db = try GRDBDatabase.inMemory()
        let scope = ChatScope.project("ME-24")

        let storeA = ChatStore(db: db)
        let user = ChatMessage(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            role: .user, blocks: [.text("Was ist im Montagsmeeting zu besprechen?")],
            status: .complete, createdAt: at(1_800_000_000)
        )
        let assistant = ChatMessage(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            role: .assistant, blocks: [.text("Drei Punkte: Arbeitsplatte, Pantry, Termin.")],
            status: .complete, createdAt: at(1_800_000_060)
        )
        try storeA.append(user, to: scope)
        try storeA.append(assistant, to: scope)

        // „App neu gestartet": neue Instanz, selbe DB
        let storeB = ChatStore(db: db)
        try storeB.loadIfNeeded(scope)
        let loaded = storeB.messages(for: scope)
        #expect(loaded == [user, assistant])   // id/role/blocks/status/createdAt bitgenau
    }

    // MARK: Scope-Isolation + Reihenfolge
    @Test func scopesSindIsoliertUndGeordnet() throws {
        let db = try GRDBDatabase.inMemory()
        let store = ChatStore(db: db)

        try store.append(.text("home a", role: .user), to: .home)
        try store.append(.text("projekt a", role: .user), to: .project("ME-24"))
        try store.append(.text("home b", role: .assistant), to: .home)

        let storeB = ChatStore(db: db)
        try storeB.loadIfNeeded(.home)
        try storeB.loadIfNeeded(.project("ME-24"))
        #expect(storeB.messages(for: .home).map(\.text) == ["home a", "home b"])
        #expect(storeB.messages(for: .project("ME-24")).map(\.text) == ["projekt a"])
    }

    // MARK: Streaming-Turn: append(.streaming) → update(.complete)
    @Test func streamingTurnWirdAbgeschlossenUndPersistiert() throws {
        let db = try GRDBDatabase.inMemory()
        let scope = ChatScope.home
        let store = ChatStore(db: db)

        let turnID = UUID()
        try store.append(.text("frage", role: .user), to: scope)
        try store.append(ChatMessage(id: turnID, role: .assistant, blocks: [.text("")], status: .streaming), to: scope)
        try store.updateAssistantTurn(id: turnID, blocks: [.text("Fertige Antwort.")], status: .complete, in: scope)

        let storeB = ChatStore(db: db)
        try storeB.loadIfNeeded(scope)
        let last = storeB.messages(for: scope).last
        #expect(last?.status == .complete)
        #expect(last?.text == "Fertige Antwort.")
    }

    // MARK: Fehlgeschlagener Turn überlebt als .failed
    @Test func fehlgeschlagenerTurnUeberlebt() throws {
        let db = try GRDBDatabase.inMemory()
        let scope = ChatScope.project("SO-24")
        let store = ChatStore(db: db)

        let turnID = UUID()
        try store.append(ChatMessage(id: turnID, role: .assistant, blocks: [.text("…")], status: .streaming), to: scope)
        try store.updateAssistantTurn(id: turnID, blocks: [.text("…")], status: .failed("Netzwerk weg"), in: scope)

        let storeB = ChatStore(db: db)
        try storeB.loadIfNeeded(scope)
        #expect(storeB.messages(for: scope).last?.status == .failed("Netzwerk weg"))
    }

    // MARK: SaveState ist nach erfolgreichem Schreiben sichtbar
    @Test func saveStateWirdGesetzt() throws {
        let db = try GRDBDatabase.inMemory()
        let store = ChatStore(db: db)
        try store.append(.text("hallo", role: .user), to: .home)
        if case .saved = store.saveState { } else {
            Issue.record("SaveState sollte .saved sein, ist aber: \(store.saveState)")
        }
    }

    // MARK: clear() leert nur den Ziel-Scope
    @Test func clearLeertNurZielScope() throws {
        let db = try GRDBDatabase.inMemory()
        let store = ChatStore(db: db)
        try store.append(.text("home", role: .user), to: .home)
        try store.append(.text("projekt", role: .user), to: .project("ME-24"))
        try store.clear(.home)

        let storeB = ChatStore(db: db)
        try storeB.loadIfNeeded(.home)
        try storeB.loadIfNeeded(.project("ME-24"))
        #expect(storeB.messages(for: .home).isEmpty)
        #expect(storeB.messages(for: .project("ME-24")).map(\.text) == ["projekt"])
    }

    // MARK: Scope-Key-Stabilität (Persistenz-Vertrag)
    @Test func scopeKeyIstStabil() {
        #expect(ChatScope.home.rawKey == "home")
        #expect(ChatScope.project("ME-24").rawKey == "project:ME-24")
        #expect(ChatScope(rawKey: "home") == .home)
        #expect(ChatScope(rawKey: "project:ME-24") == .project("ME-24"))
        #expect(ChatScope(rawKey: "quatsch") == nil)
    }

    // MARK: Multi-User — Chat ist pro Bewohner isoliert (PRIVAT, nie kreuzlesbar)
    @Test func chatIstProBewohnerIsoliert() throws {
        let db = try GRDBDatabase.inMemory()
        // Bewohner A schreibt in Home + ein Projekt.
        let storeA = ChatStore(db: db, userID: "user-a")
        try storeA.append(.text("A's privater Chat", role: .user), to: .home)
        try storeA.append(.text("A's Projekt-Chat", role: .user), to: .project("ME-24"))

        // Bewohner B (andere userID) sieht NICHTS von A — auf demselben Gerät/DB.
        let storeB = ChatStore(db: db, userID: "user-b")
        try storeB.loadIfNeeded(.home)
        try storeB.loadIfNeeded(.project("ME-24"))
        #expect(storeB.messages(for: .home).isEmpty)
        #expect(storeB.messages(for: .project("ME-24")).isEmpty)

        // A findet seinen Verlauf nach „Neustart" (frischer Store, gleiche userID) wieder.
        let storeA2 = ChatStore(db: db, userID: "user-a")
        try storeA2.loadIfNeeded(.home)
        #expect(storeA2.messages(for: .home).map(\.text) == ["A's privater Chat"])
    }

    // MARK: Multi-User — clear() eines Bewohners rührt fremde Nachrichten nicht an
    @Test func clearLoeschtNurEigeneNachrichten() throws {
        let db = try GRDBDatabase.inMemory()
        let storeA = ChatStore(db: db, userID: "user-a")
        try storeA.append(.text("A bleibt", role: .user), to: .home)
        // B löscht seinen (leeren) Home-Scope — A's Nachricht bleibt unberührt.
        let storeB = ChatStore(db: db, userID: "user-b")
        try storeB.clear(.home)
        let storeA2 = ChatStore(db: db, userID: "user-a")
        try storeA2.loadIfNeeded(.home)
        #expect(storeA2.messages(for: .home).map(\.text) == ["A bleibt"])
    }

    // MARK: Multi-User — Backfill ordnet Alt-Zeilen (userID NULL) dem Erst-Bewohner zu
    @Test func backfillOrdnetAltZeilenDemErstBewohnerZu() throws {
        let db = try GRDBDatabase.inMemory()
        // Alt-Zustand vor v25: Nachricht ohne userID (NULL).
        let legacyStore = ChatStore(db: db, userID: nil)
        try legacyStore.append(.text("Bestehender Chat vor Multi-User", role: .user), to: .home)

        // Backfill: NULL → Erst-Bewohner.
        try MultiUserBackfill.assignNullRowsToPrimary(db: db, primaryUserID: "primary")

        // Der Erst-Bewohner sieht die Alt-Nachricht (kein Datenverlust).
        let primaryStore = ChatStore(db: db, userID: "primary")
        try primaryStore.loadIfNeeded(.home)
        #expect(primaryStore.messages(for: .home).map(\.text) == ["Bestehender Chat vor Multi-User"])

        // Ein Zweit-Bewohner sieht sie NICHT (kein Leak).
        let otherStore = ChatStore(db: db, userID: "other")
        try otherStore.loadIfNeeded(.home)
        #expect(otherStore.messages(for: .home).isEmpty)
    }
}
