import Foundation
import Observation
import os
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
    public let favorites:  FavoritesStore
    public let chat:       ChatStore
    public let conversation: ConversationEngine
    public let profile:    ProfileStore
    // Schaltzentrum-Logbuch: jeder externe Datensync hinterlässt hier einen
    // Handshake (lokal + Airtable-Spiegel). Siehe DataFlowLogger.
    public let dataFlow:   DataFlowLogger

    // MARK: Integrationen
    public let googleAuth: GoogleAuthService
    public let clockodoAuth: ClockodoAuthService
    public let clickUpAuth: ClickUpAuthService
    public let sevdeskAuth: SevdeskAuthService
    public let airtableAuth: AirtableAuthService
    public let claudeAuth: ClaudeAuthService
    public let assistantLLM: any AssistantLLMProviding

    // Kalkulations-Engine: live mit Baseline-Ankern (keine externen Daten) +
    // DeviceCatalog, falls die echte Preisbuch-CSV in Application-Support liegt
    // (sonst nil-Lookup). Echter Seed-/Korpus-Provider folgt separat.
    public let kalkulationsEngine: any KalkulationsEngineProviding

    // S4: vom Assistenten verwaltete Notizen (lokal, persistent).
    public let assistantNotes: AssistantNotesStore

    // S6: vom Assistenten verwaltete Aufgaben/Erinnerungen (lokal, persistent).
    public let assistantTasks: AssistantTasksStore

    // S13: Snapshot der Airtable-Tabelle „Kontakte" (Adresse/Telefon/E-Mail) für lookup_kontakt.
    private var studioContacts: [StudioContact] = []

    // Projekt-Boards on-demand (pro geöffnetem Projekt)
    private var projectBoards: [String: WidgetBoardStore] = [:]
    private var projectNotes:  [String: NoteStore]        = [:]
    // Pro Projekt EIN langlebiger Watcher: so überlebt die Baseline/„seen"-Menge
    // die Navigation (sonst re-baselined jede neue Detailseite und neue Angebote
    // werden nie gemeldet).
    private var projectOfferWatchers: [String: DriveOfferWatcher] = [:]

    // Google-Identität (S17): forwarding computed property damit SidebarView
    // und andere Views direkt darauf zugreifen können ohne googleAuth zu kennen.
    public var currentGoogleUser: GoogleUserInfo? { googleAuth.currentUser }

    // Wer hat den Datenstrom ausgelöst? Für Handshake-Einträge im Schaltzentrum.
    public var actorUserID: String {
        googleAuth.currentUser?.email ?? profile.profile?.displayName ?? "local"
    }

    // S9: legt einen vom Nutzer BESTÄTIGTEN Kontakt via People API an + Audit.
    // Wird der AssistantChatView als `onCreateContact` injiziert — der Widgets-Layer
    // kennt keinen Schreib-Client. Erst die Bestätigung an der Karte ruft das hier.
    public func createContact(_ draft: ContactDraft) async -> ContactCreateOutcome {
        let contact: GoogleContact
        do {
            contact = try await GoogleContactsClient().createContact(draft)
        } catch GoogleContactsError.notConnected {
            return .failed("Google nicht verbunden — in den Einstellungen verbinden.")
        } catch {
            return .failed("Kontakt konnte nicht angelegt werden: \(error.localizedDescription)")
        }
        // Audit ist Pflicht für externe Schreibvorgänge. Schlägt es fehl, ist der
        // Kontakt dennoch angelegt (externer Effekt) — sichtbar via os.Logger, nicht verschluckt.
        do {
            try audit.append(AuditEntry(actorUserID: actorUserID, projectID: "-",
                                        action: .contactCreated,
                                        summary: "Kontakt angelegt: \(contact.displayName)"))
        } catch {
            MykLog.contacts.error("Audit für Kontaktanlage fehlgeschlagen: \(String(describing: error), privacy: .public)")
        }
        return .created(contact.displayName)
    }

    // MARK: Navigations-Brücke
    // ContentView besitzt `module` (Sidebar-Auswahl), ProjectGalleryView besitzt
    // `selectedProject` (welches Projekt offen ist) — beide bewusst reine
    // View-lokale @State, nicht hier zentralisiert. Andere Module (z. B.
    // ProjectFavoritesWidget im Heute-Tab) brauchen aber einen Weg, "öffne
    // Projekt X" auszulösen, ohne diese beiden States zu kennen. Dieses einzelne
    // Feld ist die Brücke: setzen → ContentView wechselt das Modul, Gallery
    // öffnet das Projekt und räumt danach selbst wieder auf (nil).
    public var pendingProjectSelection: Project?

    // MARK: Backup (Mandate G) — sichtbarer Speicherzustand für „Backup jetzt"
    public private(set) var backupState: SaveState = .idle

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
        self.favorites = FavoritesStore(db: database)
        self.profile = ProfileStore(db: database)
        let chatStore = ChatStore(db: database)
        self.chat = chatStore
        self.googleAuth = GoogleAuthService()
        self.clockodoAuth = ClockodoAuthService()
        self.clickUpAuth = ClickUpAuthService()
        self.sevdeskAuth = SevdeskAuthService()
        self.airtableAuth = AirtableAuthService()
        // Logger spiegelt nach Airtable über den eng begrenzten Schreibpfad
        // (nur Datenstrom-Log der Mastermind-Base; Whitelist im AirtableClient).
        self.dataFlow = DataFlowLogger(db: database, airtable: AirtableClient())
        let claudeCredentials = KeychainClaudeCredentialsStore()
        self.claudeAuth = ClaudeAuthService(credentialsStore: claudeCredentials)
        self.assistantLLM = ClaudeMessagesClient(credentialsStore: claudeCredentials)
        // Engine live: Baseline-Anker (eingebaut) + DeviceCatalog (lädt die echte
        // Preisbuch-CSV aus Application-Support, falls vorhanden — sonst nil-Lookup).
        // Muss vor ConversationEngine initialisiert werden, damit die Registry sie bekommt.
        // Ein geteilter LearningStore für Engine UND gelernten Anker-Kanal (Phase 1,
        // feat/tischler-predictor): der CompositeAnchorProvider legt die review-bestätigten
        // eingehenden Angebote über den destillierten Seed-Korpus. Beide MÜSSEN dieselbe
        // learning.sqlite sehen, sonst liest der Provider ein anderes Gate als die Engine schreibt.
        let learningStore = LearningStore()
        let kalkulationsEngine = KalkulationsEngine(
            provider: CompositeAnchorProvider(
                primary: BrainSeedProvider(),
                learned: LearnedAnchorProvider(store: learningStore)
            ),
            learningStore: learningStore,
            deviceCatalog: DeviceCatalog.loadDefault(),
            auditStore: audit   // bestätigte Anpassungen landen im Audit-Log
        )
        self.kalkulationsEngine = kalkulationsEngine
        let notes = AssistantNotesStore(db: database)
        self.assistantNotes = notes
        let tasks = AssistantTasksStore(db: database)
        self.assistantTasks = tasks
        // Read-only Tool-Whitelist (Sevdesk NIE enthalten) + die lokalen Schreib-Tools
        // für Notizen (S4) und Aufgaben (S6). Tools laufen nur bei Opt-in (siehe AssistantChatView).
        self.conversation = ConversationEngine(
            chatStore: chatStore,
            provider: ClaudeChatClient(),
            registry: .standard(kalkulationsEngine: kalkulationsEngine, notesStore: notes, tasksStore: tasks),
            dataFlowLogger: dataFlow
        )
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

    // MARK: Drive-Poll über alle Projekte
    // Bisher pollte DriveOfferWatcher nur, solange die jeweilige Projektseite
    // offen war — alle anderen Projekte hatten keine Live-Quelle, solange
    // niemand draufschaut. Diese Methode pollt alle aktiven Projekte mit
    // verlinktem Drive-Ordner auf einmal; genutzt vom manuellen
    // "Jetzt prüfen"-Button (TodayView) UND vom Hintergrund-Sweep unten.
    @discardableResult
    public func pollAllActiveProjectsForOffers(into context: StudioContext) async -> Int {
        var total = 0
        var scanned = 0
        for project in registry.activeProjects() {
            guard let folderID = project.links.driveFolderID, folderID.isEmpty == false else { continue }
            scanned += 1
            let watcher = offerWatcher(for: project.projectNumber)
            let signals = await watcher.poll(projectID: project.projectNumber, folderID: folderID)
            for signal in signals { context.emit(signal) }
            total += signals.count
        }
        // Handshake nur bei echtem Treffer protokollieren — der 300s-Hintergrund-
        // Sweep soll das Log nicht mit „nichts Neues" fluten.
        if total > 0 {
            dataFlow.log(
                integrationID: "DRIVE_POLL_OFFERS", actorUserID: actorUserID, action: .success,
                recordsRead: scanned, recordsWritten: 0,
                summary: "\(total) neue Angebots-PDF(s) in \(scanned) Projektordnern erkannt"
            )
        }
        return total
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
        try? profile.load()   // nicht-gefunden ist kein Fehler (leeres Profil)
        do {
            try audit.load()
        } catch {
            // AuditStore macht den Fehler über saveState sichtbar.
        }
        try? dataFlow.load()
        try? favorites.load()   // leere Favoritenmenge ist kein Fehler (L25)
        // Registry seeden/laden
        await registry.seedIfEmpty()
        await registry.load()
        // L24: Assistent bekommt das Kunden-Verzeichnis (lokaler Snapshot) — nach dem
        // Laden, damit lookup_kunde echte Daten sieht statt einer leeren Cold-Start-Liste.
        refreshAssistantKundenWissen()

        // B2-Fix: wenn Google verbunden aber kein UserInfo gecacht (z. B. Login vor S17),
        // einmal im Hintergrund nachladen — non-fatal, Sidebar zeigt Name ohne Flackern.
        if googleAuth.status == .connected, googleAuth.currentUser == nil {
            Task {
                await googleAuth.refreshUserInfoIfNeeded()
            }
        }

        guard airtableAuth.status == .connected else { return }
        guard let credentials = try? airtableAuth.storedCredentials() else { return }
        do {
            dataFlow.log(integrationID: "AIRTABLE_KUNDEN_PROJEKTE", actorUserID: actorUserID,
                         action: .start, summary: "Auto-Sync bei App-Start")
            await registry.syncFromAirtable(baseID: credentials.baseID, auth: airtableAuth)
            if case .error(let msg) = airtableAuth.status {
                dataFlow.log(integrationID: "AIRTABLE_KUNDEN_PROJEKTE", actorUserID: actorUserID,
                             action: .error, errorMessage: msg, summary: "Airtable-Sync fehlgeschlagen")
            } else {
                dataFlow.log(integrationID: "AIRTABLE_KUNDEN_PROJEKTE", actorUserID: actorUserID,
                             action: .success, recordsRead: registry.projects.count,
                             summary: "Projekte/Kunden aus Mastermind synchronisiert")
            }
        } catch {
            airtableAuth.setError(String(describing: error))
        }
        // Kontakte laufen UNABHÄNGIG vom Projekt-/Kunden-Sync (eigene kanonische Base):
        // sonst sieht der Assistent keine Kontakte, sobald die gespeicherte baseID kaputt
        // ist und syncFromAirtable scheitert (Status .error → der Kontakt-Sync wurde im
        // übersprungenen else-Zweig nie ausgeführt).
        await syncKontakte(baseID: credentials.baseID)   // nutzt intern die kanonische Base
        refreshAssistantKundenWissen()                   // frische Kunden + Kontakte → Assistent
    }

    // S13: lädt die Airtable-Tabelle „Kontakte" einmalig (read-only) in den lokalen
    // Snapshot für lookup_kontakt. Fehler werden geschluckt (Verzeichnis bleibt leer,
    // sichtbar via os.Logger) — Kontakte sind ein Komfort-Feature, kein Boot-Blocker.
    private func syncKontakte(baseID: String) async {
        // Kanonische Mastermind-Base — bewusst NICHT die übergebene credentials.baseID:
        // die ist durch den Keychain-Bug teils kaputt (enthielt den PAT statt der ID),
        // wodurch das Assistenten-Kontaktverzeichnis leer blieb, obwohl die Kontakte-
        // Seite (die exakt diese ID hartkodiert) alle Kontakte lud. So sieht der
        // Assistent dieselben Kontakte wie die Seite.
        let kontakteBaseID = "appuVMh3KDfKw4OoQ"
        do {
            let records = try await AirtableClient().fetchRecords(baseID: kontakteBaseID, table: "Kontakte")
            studioContacts = AirtableClient.mapContacts(from: records)
            dataFlow.log(integrationID: "AIRTABLE_KONTAKTE_LOOKUP", actorUserID: actorUserID,
                         action: .success, recordsRead: studioContacts.count,
                         summary: "Kontaktverzeichnis synchronisiert")
        } catch {
            // Detail nur lokal via os.Logger; der DataFlow-Log (ggf. Airtable-gespiegelt)
            // bekommt KEINE Roh-Fehlertexte — Kontaktdaten/PII gehören nie ins Log.
            MykLog.lifecycle.error("Kontakte-Sync fehlgeschlagen: \(String(describing: error), privacy: .public)")
            dataFlow.log(integrationID: "AIRTABLE_KONTAKTE_LOOKUP", actorUserID: actorUserID,
                         action: .error, errorMessage: "Kontakte-Sync fehlgeschlagen",
                         summary: "Kontakte-Sync fehlgeschlagen")
        }
    }

    // S14: legt einen vom Nutzer BESTÄTIGTEN Mail-Entwurf via Gmail API an + Audit.
    // Wird der AssistantChatView als `onCreateDraft` injiziert. Versendet NIE — nur Entwurf.
    public func createDraft(_ draft: EmailDraft) async -> DraftCreateOutcome {
        do {
            _ = try await GoogleGmailClient().createDraft(draft)
        } catch GoogleGmailError.notConnected {
            return .failed("Gmail nicht verbunden / kein Schreibrecht — Google in den Einstellungen neu verbinden (M2).")
        } catch {
            return .failed("Entwurf konnte nicht angelegt werden: \(error.localizedDescription)")
        }
        do {
            try audit.append(AuditEntry(actorUserID: actorUserID, projectID: "-",
                                        action: .draftCreated,
                                        summary: "Gmail-Entwurf angelegt: \(draft.subject)"))
        } catch {
            MykLog.contacts.error("Audit für Entwurf fehlgeschlagen: \(String(describing: error), privacy: .public)")
        }
        return .created("Entwurf in Gmail abgelegt (erscheint auch in Apple Mail).")
    }

    // S19: schreibt einen vom Nutzer BESTÄTIGTEN Airtable-Kontakt-Entwurf.
    // create → AirtableClient.createRecord; update → AirtableClient.updateRecord.
    // KEIN delete. Wird der AssistantChatView als `onWriteAirtableContact` injiziert.
    public func writeAirtableContact(_ draft: AirtableContactDraft) async -> AirtableContactWriteOutcome {
        guard airtableAuth.status == .connected else {
            return .failed("Airtable nicht verbunden — in den Einstellungen verbinden.")
        }
        let client = AirtableClient()
        let baseID = AirtableClient.writableBaseID
        let table  = "Kontakte"
        let fields: [String: AirtableFieldValue] = draft.airtableFields
            .reduce(into: [:]) { dict, pair in dict[pair.key] = .string(pair.value) }

        do {
            switch draft.intent {
            case .create:
                let recordID = try await client.createRecord(baseID: baseID, table: table, fields: fields)
                try audit.append(AuditEntry(
                    actorUserID: actorUserID, projectID: "-",
                    action: .contactCreated,
                    summary: "Airtable-Kontakt angelegt: \(draft.name) (ID \(recordID))"))
                // Snapshot aktualisieren, damit lookup_kontakt sofort den neuen Eintrag findet.
                await syncKontakte(baseID: baseID)
                refreshAssistantKundenWissen()
                return .created(draft.displayName)
            case .update:
                guard let recordID = draft.recordID, recordID.isEmpty == false else {
                    return .failed("Keine Record-ID — update nicht möglich.")
                }
                try await client.updateRecord(baseID: baseID, table: table, recordID: recordID, fields: fields)
                try audit.append(AuditEntry(
                    actorUserID: actorUserID, projectID: "-",
                    action: .contactCreated,   // kein eigener Audit-Typ nötig — .contactCreated ist semantisch nah genug
                    summary: "Airtable-Kontakt aktualisiert: \(draft.name) (ID \(recordID))"))
                await syncKontakte(baseID: baseID)
                refreshAssistantKundenWissen()
                return .updated(draft.displayName)
            }
        } catch AirtableError.invalidBaseID(let msg) {
            return .failed("Schreibschutz verletzt: \(msg)")
        } catch AirtableError.notConnected {
            return .failed("Airtable nicht verbunden — in den Einstellungen verbinden.")
        } catch {
            return .failed("Fehler beim Schreiben: \(error.localizedDescription)")
        }
    }

    // L24: baut die Assistenten-Tool-Registry mit dem aktuellen Kunden-Snapshot neu auf.
    // Rein lokal (kein Airtable-Call) — nutzt die bereits geladene Registry. Erhält die
    // KalkulationsEngine, sonst verschwände schaetze_projekt.
    private func refreshAssistantKundenWissen() {
        let brain = KundenBrain(customers: registry.customers, projects: registry.projects)
        let dir = ProjectDirectory(projects: registry.projects, customers: registry.customers)
        let contactDir = ContactDirectory(contacts: studioContacts)
        // S11: Projekte mit verknüpfter ClickUp-Liste → projektübergreifende Aufgaben-Übersicht.
        let clickUpListings: [ProjectClickUpRef] = registry.projects.compactMap { project in
            guard let listID = project.links.clickUpListID, listID.isEmpty == false else { return nil }
            return ProjectClickUpRef(projectNumber: project.projectNumber, title: project.title, listID: listID)
        }
        conversation.updateRegistry(.standard(
            kalkulationsEngine: kalkulationsEngine, kundenDirectory: brain,
            contactDirectory: contactDir, clickUpListings: clickUpListings,
            notesStore: assistantNotes, tasksStore: assistantTasks, projectDirectory: dir))
    }

    // MARK: - Backup (Mandate G)
    // Erzwungener WAL-Checkpoint + konsistentes Backup, off-main ausgeführt.
    // Lokal, read-only auf die DB — kein externer Schreibzugriff.
    public func createBackup() async {
        backupState = .saving
        let db = database
        let appSupportDir = AppDatabase.productionURL.deletingLastPathComponent()
        let version = AppIdentity.version
        let commit = AppIdentity.gitCommit
        do {
            let url = try await Task.detached(priority: .utility) {
                let service = BackupService(appSupportDir: appSupportDir)
                let folder = try service.createConsistentBackup(
                    db: db, tag: "manual", appVersion: version, gitCommit: commit)
                try? service.pruneOldBackups(olderThanDays: 30)
                return folder
            }.value
            backupState = .saved(Date())
            MykLog.backup.notice("Backup erstellt: \(url.lastPathComponent, privacy: .public)")
        } catch {
            backupState = .failed(String(describing: error))
            MykLog.backup.error("Backup fehlgeschlagen: \(String(describing: error), privacy: .public)")
        }
    }
}
