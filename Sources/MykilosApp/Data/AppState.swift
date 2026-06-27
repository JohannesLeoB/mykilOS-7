import Foundation
import Observation
import MykilosKit
import MykilosServices

// MARK: - AppState
// Zentrales, injizierbares Objekt mit allen geteilten Stores.
// Übergeben via .environment(appState) — kein Singleton-Wildwuchs.
@MainActor
@Observable
public final class AppState {
    // MARK: Kern
    public let database: GRDBDatabase
    public let registry: RegistryStore

    // MARK: Boards
    public let homeBoard:  WidgetBoardStore
    public let homeNotes:  NoteStore
    public let audit:      AuditStore
    public let chat:       ChatStore
    public let conversation: ConversationEngine

    // MARK: Integrationen
    public let googleAuth: GoogleAuthService
    public let clockodoAuth: ClockodoAuthService
    public let clickUpAuth: ClickUpAuthService
    public let sevdeskAuth: SevdeskAuthService
    public let airtableAuth: AirtableAuthService
    public let claudeAuth: ClaudeAuthService
    public let assistantLLM: any AssistantLLMProviding

    // Projekt-Boards on-demand (pro geöffnetem Projekt)
    private var projectBoards: [String: WidgetBoardStore] = [:]
    private var projectNotes:  [String: NoteStore]        = [:]
    // Pro Projekt EIN langlebiger Watcher: so überlebt die Baseline/„seen"-Menge
    // die Navigation (sonst re-baselined jede neue Detailseite und neue Angebote
    // werden nie gemeldet).
    private var projectOfferWatchers: [String: DriveOfferWatcher] = [:]

    public init(database: GRDBDatabase) {
        self.database = database
        self.registry = RegistryStore()
        self.homeBoard = WidgetBoardStore(
            boardID: WidgetBoardID.home.rawValue,
            db: database,
            defaultLayout: { WidgetBoardDefault.homeLayout }
        )
        self.homeNotes = NoteStore(
            boardID: WidgetBoardID.home.rawValue,
            db: database
        )
        self.audit = AuditStore(db: database)
        let chatStore = ChatStore(db: database)
        self.chat = chatStore
        // Read-only Tool-Whitelist (Sevdesk NIE enthalten). Tools laufen nur,
        // wenn der Nutzer das Opt-in aktiviert (siehe AssistantChatView).
        self.conversation = ConversationEngine(
            chatStore: chatStore,
            provider: ClaudeChatClient(),
            registry: .standard()
        )
        self.googleAuth = GoogleAuthService()
        self.clockodoAuth = ClockodoAuthService()
        self.clickUpAuth = ClickUpAuthService()
        self.sevdeskAuth = SevdeskAuthService()
        self.airtableAuth = AirtableAuthService()
        let claudeCredentials = KeychainClaudeCredentialsStore()
        self.claudeAuth = ClaudeAuthService(credentialsStore: claudeCredentials)
        self.assistantLLM = ClaudeMessagesClient(credentialsStore: claudeCredentials)
    }

    // MARK: Projekt-Board (lazy, gecached)
    public func board(for projectNumber: String, kind: ProjectKind) -> WidgetBoardStore {
        if let existing = projectBoards[projectNumber] { return existing }
        let store = WidgetBoardStore(
            boardID: WidgetBoardID.project(projectNumber).rawValue,
            db: database,
            defaultLayout: { WidgetBoardDefault.layout(for: kind) }
        )
        projectBoards[projectNumber] = store
        return store
    }

    public func notes(for projectNumber: String) -> NoteStore {
        if let existing = projectNotes[projectNumber] { return existing }
        let store = NoteStore(
            boardID: WidgetBoardID.project(projectNumber).rawValue,
            db: database
        )
        projectNotes[projectNumber] = store
        return store
    }

    // MARK: Offer-Watcher (lazy, gecached) — langlebige Live-Quelle je Projekt
    public func offerWatcher(for projectNumber: String) -> DriveOfferWatcher {
        if let existing = projectOfferWatchers[projectNumber] { return existing }
        let watcher = DriveOfferWatcher()
        projectOfferWatchers[projectNumber] = watcher
        return watcher
    }

    // MARK: Notizen-Flush (App-Quit / Hintergrund)
    /// Sichert alle Notiz-Stores mit ungespeicherten Änderungen. Aufzurufen bei
    /// scenePhase == .background, damit Cmd-Q keine offene Notiz verliert.
    public func flushAllNotes() {
        for store in projectNotes.values where store.hasUnsavedChanges {
            // try? gerechtfertigt: App fährt herunter, keine UI mehr für Fehler.
            try? store.save()
        }
        if homeNotes.hasUnsavedChanges {
            try? homeNotes.save()
        }
    }

    // MARK: Bootstrap
    public func bootstrap() async {
        // DB-Stores laden
        try? homeBoard.load()
        try? homeNotes.load()
        do {
            try audit.load()
        } catch {
            // AuditStore macht den Fehler über saveState sichtbar.
        }
        // Registry seeden/laden
        await registry.seedIfEmpty()
        await registry.load()

        guard airtableAuth.status == .connected else { return }
        do {
            guard let credentials = try airtableAuth.storedCredentials() else { return }
            await registry.syncFromAirtable(baseID: credentials.baseID, auth: airtableAuth)
        } catch {
            airtableAuth.setError(String(describing: error))
        }
    }
}
