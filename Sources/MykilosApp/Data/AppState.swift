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
    // mykilOS 8, Block A: vollständige, unverlierbare Kopie jedes externen
    // Schreibvorgangs (lokal GRDB immer, Airtable-Backup-Base sobald angelegt).
    public let writeShadow: WriteShadowRecorder
    // mykilOS 8, Block A: TEST/PROD-Schalter (Default .test, .prod gesperrt).
    public let provisioningMode: ProvisioningModeStore
    // mykilOS 8, Block A: der EINZIGE Resolver für Routing (Mastermind) ↔
    // Geschäft (Artikel-Base) über die Projektnummer. Siehe ExternalMappingRegistry.swift.
    // Optional wie `RegistryStore`s privater Cache: Verzeichnis-Init-Fehler = kein
    // Resolver statt Absturz (derselbe begründete try?-Ausnahmefall wie dort).
    public let externalMapping: ExternalMappingRegistry?
    // mykilOS 8, Block A (Erweiterung, Johannes-Entscheidung 2026-06-30): rein lokale,
    // manuell bestätigte Brücke Geschäftsprojekt → Projektnummer (solange Artikel-
    // `Projekte` kein Projektnummer-Feld hat). Siehe ProjectNumberBindingStore.swift.
    public let projectNumberBindings: ProjectNumberBindingStore

    // mykilOS 8, Block B (S1): lokales Zeit-Subsystem (Timer/Pause/Buchung/Puls).
    // Rein lokal, kein externer Write — Clockodo-Upload ist S3. Siehe TimerStore.swift.
    public let timer: TimerStore

    // mykilOS 8, Block C (S2): Identität + Nomenklatur. NomenklaturStore (Ordner-Konnektoren,
    // FolderSchema-Version, Kostenstellen-Overrides) + NumberAuthority (Projektnummern-Vergabe,
    // austauschbarer Adapter für die spätere Sevdesk-Vorgabe). Rein lokal, kein externer Write.
    public let nomenklatur: NomenklaturStore
    public let numberAuthority: any NumberAuthority
    // Review-Fix (high, Block D): konkreter Typ zusätzlich zum Protokoll gespeichert, damit
    // numberAuthorityLocal() nie einen unsicheren `as?`-Fallback mit LEERER aktiveNummern-Closure
    // bauen muss (Kollisionsgefahr bei Nummernvergabe). Ein Cast kann nie mehr fehlschlagen.
    private let numberAuthorityConcrete: LocalSequentialAuthority

    // mykilOS 8, Block D (S4): Provisioning. Ledger (Idempotenz/Teilfehler), Service
    // (Mehrsystem-Geburt Drive+Airtable, gated TEST-Sandbox), ClickUp-Routing-Gerüst (§9, kein Write).
    public let provisioningLedger: ProvisioningLedger
    public let provisioningService: ProjektProvisioningService
    public let clickUpRouting: ClickUpRoutingStore
    // mykilOS 8 (2026-07-02): rein lokale, nutzergesetzte Lebenszyklus-Stufe je Projekt
    // für den Hero-Stepper. Kein externer Write.
    public let projectLifecycle: ProjectLifecycleStore

    // Härtung (2026-07-01, Johannes: Erinnerungsfunktion für den Fragebogen). Lebt hier auf
    // AppState-Ebene statt als @State in KatalogeView — sonst zerstört ein Sidebar-
    // Modulwechsel (der `switch module` in MykilOS6App.swift/moduleView ersetzt KatalogeView
    // komplett durch eine andere View) KatalogeViews @State und damit den Entwurf, obwohl
    // AppState selbst für die gesamte App-Sitzung erhalten bleibt.
    public var fragebogenEntwurf = FragebogenModel()
    public var zeigeFragebogen: Bool = false
    // Härtung (2026-07-01, Audit): spiegelt FragebogenViews privates `schreibPhase == .speichert`
    // nach außen — KatalogeView nutzt es, um die Sheet-Ebene selbst per `.interactiveDismissDisabled`
    // gegen die Escape-Taste zu sperren (die sonst alle `.disabled(...)`-Gates in FragebogenView
    // umgeht, weil sie direkt den `.sheet`-Bindingwert auf false setzt, ohne irgendeinen
    // FragebogenView-Button-Handler aufzurufen).
    public var fragebogenSchreibtGerade: Bool = false

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

    // Härtung (2026-07-01, API-Effizienz-Audit): TTL-Cache für search_gmail — war fertig
    // gebaut (GmailCacheStore, eigene Tests) aber nie hier instanziiert/übergeben, sodass
    // jede Gmail-Suche im Chat immer live gegen die API lief. Eine EINZIGE, langlebige
    // Instanz (nicht pro updateRegistry-Aufruf neu), sonst verliert der Cache seinen Zweck.
    // Härtung (2026-07-02): nicht mehr private — MailClientView nutzte bislang denselben
    // Cache nicht, jede Ordner-/Suchaktion im Mail-Tab lief live gegen die API.
    let gmailCache = GmailCacheStore()

    // S13: Snapshot der Airtable-Tabelle „Kontakte" (Adresse/Telefon/E-Mail) für lookup_kontakt.
    // public(set) damit KontakteKatalogTab den Snapshot direkt lesen kann (read-only).
    public private(set) var studioContacts: [StudioContact] = []

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
        // V10 Folge-Block A: stabile lokale userID VOR den Keychain-AuthServices
        // ermitteln (synchron, direkt gegen die DB — profile.load() läuft erst
        // async in bootstrap(), zu spät für die Store-Konstruktion hier).
        // Erzeugt beim allerersten Start eine UUID und persistiert sie sofort;
        // danach bleibt sie stabil über Neustarts (siehe ProfileStore.ensureUserID()).
        let userID = ProfileStore.ensureUserID(db: database)
        // Prozess-weit sichtbar machen: alle Default-Parameter-Konstruktionen
        // von KeychainXCredentialsStore/KeychainGoogleTokenStore (Dutzende
        // Call-Sites in AssistantTool.swift, TimelineTabView.swift, …) lösen
        // ihre userID künftig hierüber auf statt "local" zu bekommen.
        CurrentUserContext.set(userID)
        self.googleAuth = GoogleAuthService(tokenStore: KeychainGoogleTokenStore(userID: userID))
        self.clockodoAuth = ClockodoAuthService(
            credentialsStore: KeychainClockodoCredentialsStore(userID: userID))
        self.clickUpAuth = ClickUpAuthService(
            credentialsStore: KeychainClickUpCredentialsStore(userID: userID))
        self.sevdeskAuth = SevdeskAuthService(
            credentialsStore: KeychainSevdeskCredentialsStore(userID: userID))
        self.airtableAuth = AirtableAuthService(
            credentialsStore: KeychainAirtableCredentialsStore(userID: userID))
        // Logger spiegelt nach Airtable über den eng begrenzten Schreibpfad
        // (nur Datenstrom-Log der Mastermind-Base; Whitelist im AirtableClient).
        let dataFlowLogger = DataFlowLogger(db: database, airtable: AirtableClient())
        self.dataFlow = dataFlowLogger
        // mykilOS 8, Block A: Backup-Base von Johannes live angelegt (2026-06-30,
        // "mykilOS 8 Backup Base"). Tabellenname "Write-Shadow-Log" ist UNVERIFIZIERT —
        // der verfügbare Airtable-MCP sieht diese Base nicht (403), daher konnte das
        // Schema nicht gegengeprüft werden. Stimmt der Name nicht, scheitert NUR der
        // externe Spiegel (non-fatal, siehe WriteShadowRecorder.mirrorToBackupBase) —
        // der lokale GRDB-Eintrag (die eigentliche Sicherheitskopie) passiert immer.
        self.writeShadow = WriteShadowRecorder(
            db: database, airtable: AirtableClient(), backupBaseID: "app56DTbSoqPvZhom", dataFlow: dataFlowLogger)
        self.provisioningMode = ProvisioningModeStore(db: database)
        // Begründeter try?-Ausnahmefall (wie RegistryStore.init): Verzeichnis-Init-
        // Fehler ergibt keinen Resolver statt Absturz; der echte Fehler würde ohnehin
        // beim ersten echten Dateizugriff auftreten, nicht hier.
        if let routingCache = try? CachedProjectRegistry(), let businessCache = try? CachedBusinessRegistry() {
            self.externalMapping = ExternalMappingRegistry(routing: routingCache, business: businessCache)
        } else {
            self.externalMapping = nil
        }
        self.projectNumberBindings = ProjectNumberBindingStore(db: database)
        self.timer = TimerStore(db: database)
        let nomenklaturStore = NomenklaturStore(db: database)
        self.nomenklatur = nomenklaturStore
        // Aktive Projektnummern kommen live aus dem lokalen Routing-Cache (Eine Wahrheit) —
        // die Authority kombiniert sie mit ihrem GRDB-Register (archiviert/reserviert).
        // Das Datei-IO läuft explizit off-main (Task.detached), damit ein Vergabe-Aufruf
        // nie den aufrufenden Kontext blockiert (Block-C-Review-Fix).
        let localSequentialAuthority = LocalSequentialAuthority(
            db: database,
            aktiveNummern: {
                await Task.detached(priority: .utility) {
                    let projekte = (try? CachedProjectRegistry().allProjects()) ?? []
                    return projekte.compactMap { Projektnummer(parsing: $0.projectNumber) }
                }.value
            })
        self.numberAuthority = localSequentialAuthority
        self.numberAuthorityConcrete = localSequentialAuthority
        // mykilOS 8, Block D (S4): Provisioning — Ledger + Service (Drive+Airtable, gated
        // TEST-Sandbox) + ClickUp-Routing-Gerüst. Der Service nutzt echte Clients, schreibt
        // aber NUR in die TEST-Sandbox (ProvisioningMode.test) und protokolliert via Write-Shadow.
        let ledger = ProvisioningLedger(db: database)
        self.provisioningLedger = ledger
        self.provisioningService = ProjektProvisioningService(
            drive: GoogleDriveClient(), airtableCreate: AirtableClient(), airtableFetch: AirtableClient(),
            ledger: ledger, audit: self.audit, writeShadow: self.writeShadow,
            clickUp: ClickUpClient())
        self.clickUpRouting = ClickUpRoutingStore(db: database)
        self.projectLifecycle = ProjectLifecycleStore(db: database)
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
            auditStore: audit,   // bestätigte Anpassungen landen im Audit-Log
            // Härtung 2026-07-01: importPDF() (SHA256-Dedup + Airtable-Ablage) live.
            // Schreibt trotzdem NICHT, solange "Eingehende-Angebote" nicht auf
            // AirtableClient.writableMap steht (Johannes-Freigabe ausstehend) —
            // createRecord wirft dann ehrlich .invalidBaseID statt still zu versagen.
            drive: GoogleDriveClient(),
            airtable: AirtableClient(),
            dataFlowLogger: dataFlow
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
            registry: .standard(gmailCache: gmailCache, kalkulationsEngine: kalkulationsEngine, notesStore: notes, tasksStore: tasks),
            dataFlowLogger: dataFlow,
            memoryStore: ChatMemoryStore(db: database)
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
        try? provisioningMode.load()   // mykilOS 8, Block A: ungefunden = Default .test
        try? projectNumberBindings.load()   // mykilOS 8, Block A: ungefunden = leere Liste
        try? timer.load()              // mykilOS 8, Block B: laufender Timer/offene Buchung überlebt Neustart
        try? nomenklatur.load()        // mykilOS 8, Block C: Konnektoren (v1-Seed), Schema-Version, Kostenstellen-Overrides
        try? clickUpRouting.load()     // mykilOS 8, Block D: ClickUp-Routing-Gerüst (Default-Zeilen seeden)
        try? projectLifecycle.load()   // mykilOS 8: lokale Lebenszyklus-Stufen je Projekt
        // Registry seeden/laden
        await registry.seedIfEmpty()
        await registry.load()
        // L24: Assistent bekommt das Kunden-Verzeichnis (lokaler Snapshot) — nach dem
        // Laden, damit lookup_kunde echte Daten sieht statt einer leeren Cold-Start-Liste.
        refreshAssistantKundenWissen()

        // Resilienz: höchstens 1×/Tag automatisch einen konsistenten DB-Snapshot anlegen.
        // Fire-and-forget, blockiert den Start nicht; ohne dies existierte oft gar kein Backup.
        Task { await autoBackupIfDue() }

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
            // Kanonische Base statt der gespeicherten credentials.baseID: die ist durch
            // den wiederkehrenden Keychain-Bug teils kaputt (PAT statt ID) → der Sync
            // schlug fehl und vergiftete airtableAuth.status auf .error, was wiederum
            // JEDES Schreiben blockierte. Alle Airtable-Zugriffe nutzen jetzt dieselbe ID.
            await registry.syncFromAirtable(baseID: AirtableClient.writableBaseID, auth: airtableAuth)
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
        // mykilOS 8, Block A: Geschäfts-Registry auch beim App-Start synchronisieren —
        // sonst zeigt die Bindungsvorschläge-Sektion in den Integrationen erst nach dem
        // ersten Intake-Submit überhaupt Kandidaten.
        await syncBusinessRegistry()
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

    // S3: sendet eine vom Nutzer AUSDRÜCKLICH BESTÄTIGTE Mail (messages.send). Kein
    // Auto-Versand — der Aufrufer (ComposeMailView) hat eine Bestätigung davor. Braucht
    // gmail.compose (Re-Consent M2); ohne Scope → permissionRequired (inert bis Johannes
    // freigibt). Jeder Versand wird als AuditEntry(.draftSent) protokolliert.
    public func sendMail(_ draft: EmailDraft) async -> MailSendOutcome {
        do {
            try await GoogleGmailClient().sendMessage(draft)
        } catch GoogleGmailError.notConnected {
            return .permissionRequired
        } catch GoogleGmailError.httpError(403) {
            return .permissionRequired
        } catch {
            return .failed("Versand fehlgeschlagen: \(error.localizedDescription)")
        }
        let empfaenger = draft.to ?? "?"
        do {
            try audit.append(AuditEntry(actorUserID: actorUserID, projectID: "-",
                                        action: .draftSent,
                                        summary: "Mail gesendet an \(empfaenger): \(draft.subject)"))
        } catch {
            MykLog.contacts.error("Audit für Versand fehlgeschlagen: \(String(describing: error), privacy: .public)")
        }
        return .sent("Mail gesendet an \(empfaenger).")
    }

    // feat/assistant-file-drop: lädt eine vom Nutzer BESTÄTIGTE Datei via GoogleDriveClient
    // in den vorgeschlagenen Drive-Ordner hoch. Erfordert drive.file-Scope (Re-Consent M1).
    // Wird der AssistantChatView als `onUploadFileToDrive` injiziert.
    // parentFolderID = aus DriveFolderSuggestionResolver; wird NICHT automatisch ermittelt
    // (das macht die Drop-Card direkt), hier ist der Ordner bereits bekannt.
    public func uploadFileToDrive(_ file: DroppedFile, parentFolderID: String) async -> DriveUploadOutcome {
        do {
            let result = try await GoogleDriveClient().uploadFile(
                name: file.fileName,
                mimeType: file.mimeType,
                data: file.data,
                parentFolderID: parentFolderID
            )
            do {
                try audit.append(AuditEntry(
                    actorUserID: actorUserID,
                    projectID: "-",
                    action: .driveFileUploaded,
                    summary: "Drive-Upload: \(file.fileName) → \(parentFolderID)"
                ))
            } catch {
                MykLog.lifecycle.error("Audit für Drive-Upload fehlgeschlagen: \(String(describing: error), privacy: .public)")
            }
            return .uploaded(webLink: result.webViewLink)
        } catch GoogleDriveError.notConnected {
            return .permissionRequired
        } catch GoogleDriveError.uploadDestinationForbidden(let id) {
            return .failed("Upload verweigert: Ordner \(id) ist ein NO-GO-Ziel.")
        } catch GoogleDriveError.httpError(403) {
            // 403 = drive.file-Scope fehlt oder nicht im genehmigten Verzeichnis
            return .permissionRequired
        } catch {
            return .failed("Upload fehlgeschlagen: \(error.localizedDescription)")
        }
    }

    // feat/assistant-file-drop (2026-07-02): listet die unmittelbaren Unterordner eines
    // Drive-Ordners für die Ziel-Ordner-Auswahl beim Datei-Drop. Read-only; Fehler → leer
    // (die Drop-Card fällt dann auf den Projektordner zurück).
    public func listDriveSubfolders(parentFolderID: String) async -> [DriveFolderChoice] {
        guard !parentFolderID.isEmpty else { return [] }
        do {
            let items = try await GoogleDriveClient().listFolder(folderID: parentFolderID)
            return items
                .filter(\.isFolder)
                .map { DriveFolderChoice(id: $0.id, name: $0.name) }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        } catch {
            return []
        }
    }

    // feat/assistant-file-drop: legt einen Mail-Entwurf mit Dateianhang an.
    // Wird der AssistantChatView als `onAttachFileToMailDraft` injiziert.
    // Versendet NIE — nur Gmail-Entwurf anlegen.
    public func createDraftWithAttachment(_ file: DroppedFile) async -> DraftCreateOutcome {
        await createDraftWithAttachments([file])
    }

    // feat/assistant-file-drop (2026-07-02): mehrere gedropte Dateien als EINE Mail mit
    // N Anhängen. Der Gmail-Client baut multipart/mixed mit beliebig vielen Parts (fertig),
    // hier nur alle DroppedFiles zu DraftAttachments sammeln. Versendet NIE — nur Entwurf.
    public func createDraftWithAttachments(_ files: [DroppedFile]) async -> DraftCreateOutcome {
        guard files.isEmpty == false else { return .failed("Keine Dateien zum Anhängen.") }
        let attachments = files.map { DraftAttachment(filename: $0.fileName, mimeType: $0.mimeType, data: $0.data) }
        let gesamt = files.reduce(0) { $0 + $1.data.count }
        let sizeLabel = ByteCountFormatter.string(fromByteCount: Int64(gesamt), countStyle: .file)
        let liste = files.map { "· \($0.fileName)" }.joined(separator: "\n")
        let subject = files.count == 1 ? files[0].fileName : "\(files.count) Dateien"
        let draft = EmailDraft(
            to: nil,
            subject: subject,
            body: "Angehängt (\(files.count), \(sizeLabel)):\n\(liste)",
            attachments: attachments
        )
        return await createDraft(draft)
    }

    // S19: schreibt einen vom Nutzer BESTÄTIGTEN Airtable-Kontakt-Entwurf.
    // create → AirtableClient.createRecord; update → AirtableClient.updateRecord.
    // KEIN delete. Wird der AssistantChatView als `onWriteAirtableContact` injiziert.
    public func writeAirtableContact(_ draft: AirtableContactDraft) async -> AirtableContactWriteOutcome {
        // KEIN Gate auf airtableAuth.status: ein fehlgeschlagener Projekt-Sync darf das
        // Schreiben nicht blockieren (genau dieser Bug kam wiederholt). Ob ein PAT da ist,
        // prüft AirtableClient.createRecord/updateRecord selbst und wirft sonst .notConnected.
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
                // Härtung (2026-07-01, Audit): der ECHTE bestätigte Write hatte bisher keinen
                // dataFlow.log — ConversationEngine loggt nur den Tool-Aufruf (Entwurfsphase,
                // VOR der Bestätigung), was einen grünen Erfolg zeigen kann, bevor überhaupt
                // etwas geschrieben wurde. Dieser Aufruf hier spiegelt den tatsächlichen Write.
                dataFlow.log(integrationID: "AIRTABLE_KONTAKTE_CREATE", actorUserID: actorUserID,
                             action: .success, recordsWritten: 1,
                             summary: "Airtable-Kontakt angelegt: \(draft.name)")
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
                dataFlow.log(integrationID: "AIRTABLE_KONTAKTE_UPDATE", actorUserID: actorUserID,
                             action: .success, recordsWritten: 1,
                             summary: "Airtable-Kontakt aktualisiert: \(draft.name)")
                await syncKontakte(baseID: baseID)
                refreshAssistantKundenWissen()
                return .updated(draft.displayName)
            }
        } catch AirtableError.invalidBaseID(let msg) {
            dataFlow.log(integrationID: draft.intent == .create ? "AIRTABLE_KONTAKTE_CREATE" : "AIRTABLE_KONTAKTE_UPDATE",
                         actorUserID: actorUserID, action: .error, errorMessage: msg, summary: "Airtable-Kontakt-Write fehlgeschlagen")
            return .failed("Schreibschutz verletzt: \(msg)")
        } catch AirtableError.notConnected {
            dataFlow.log(integrationID: draft.intent == .create ? "AIRTABLE_KONTAKTE_CREATE" : "AIRTABLE_KONTAKTE_UPDATE",
                         actorUserID: actorUserID, action: .error, errorMessage: "notConnected", summary: "Airtable-Kontakt-Write fehlgeschlagen")
            return .failed("Airtable nicht verbunden — Personal Access Token in den Einstellungen eintragen.")
        } catch AirtableError.httpError(let code) where code == 401 || code == 403 {
            dataFlow.log(integrationID: draft.intent == .create ? "AIRTABLE_KONTAKTE_CREATE" : "AIRTABLE_KONTAKTE_UPDATE",
                         actorUserID: actorUserID, action: .error, errorMessage: "httpError(\(code))", summary: "Airtable-Kontakt-Write fehlgeschlagen")
            return .failed("Airtable-Token hat keine Schreibrechte (Fehler \(code)). In Airtable einen Token mit Scope „data.records:write\" für die Mastermind-Base erstellen und in den Einstellungen eintragen.")
        } catch AirtableError.validationFailed(let code, let message) where code == 401 || code == 403 {
            dataFlow.log(integrationID: draft.intent == .create ? "AIRTABLE_KONTAKTE_CREATE" : "AIRTABLE_KONTAKTE_UPDATE",
                         actorUserID: actorUserID, action: .error, errorMessage: "validationFailed(\(code)): \(message)", summary: "Airtable-Kontakt-Write fehlgeschlagen")
            return .failed("Airtable-Token hat keine Schreibrechte (Fehler \(code)). In Airtable einen Token mit Scope „data.records:write\" für die Mastermind-Base erstellen und in den Einstellungen eintragen.")
        } catch {
            dataFlow.log(integrationID: draft.intent == .create ? "AIRTABLE_KONTAKTE_CREATE" : "AIRTABLE_KONTAKTE_UPDATE",
                         actorUserID: actorUserID, action: .error, errorMessage: error.localizedDescription, summary: "Airtable-Kontakt-Write fehlgeschlagen")
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
            gmailCache: gmailCache,
            kalkulationsEngine: kalkulationsEngine, kundenDirectory: brain,
            contactDirectory: contactDir, clickUpListings: clickUpListings,
            notesStore: assistantNotes, tasksStore: assistantTasks, projectDirectory: dir))
    }

    /// Umfang des Drive-Ordners für die echte Provisionierung (Fragebogen). `.leadRumpf`
    /// legt nur den Wurzelordner (kein Schema-Unterbau) in `PROJEKTE/_LEADS/` an;
    /// `.vollstaendig` den kompletten Baum direkt im echten `PROJEKTE`-Root.
    private enum ProjektOrdnerModus: String, CustomStringConvertible {
        case leadRumpf, vollstaendig
        var description: String { rawValue }
    }

    // MARK: - Projekt-Intake (Fragebogen → Kunde [+ Projekt [+ Ordner]] je Anlege-Stufe)
    // Gated: NUR CREATE, NIE update/delete bestehender Records.
    // Dispatcht auf die von Johannes gewählte `FragebogenTriggerStufe` (2026-07-01,
    // "die Triggerstufe wird im letzten Dialog zur Auswahl angegeben"):
    //  · .kontakt         → NUR Kunde (Google-Kontakt + Artikel-DB), kein Projekt/Ordner.
    //  · .lead            → Kunde+Projekt + Rumpf-Ordner unter PROJEKTE/_LEADS (Phase=Lead).
    //  · .projektMitOrdner → Kunde+Projekt + voller Ordnerbaum im PROJEKTE-Root (Phase=Aktiv).
    public func erzeugeAusFragebogen(
        ergebnis: IntakeErgebnis, modell: FragebogenModel, stufe: FragebogenTriggerStufe
    ) async throws -> IntakeAnlageErgebnis {
        switch stufe {
        case .kontakt:
            return try await erzeugeNurKontakt(ergebnis: ergebnis)
        case .lead:
            return try await erzeugeKundeUndProjekt(ergebnis: ergebnis, modell: modell, ordnerModus: .leadRumpf)
        case .projektMitOrdner:
            return try await erzeugeKundeUndProjekt(ergebnis: ergebnis, modell: modell, ordnerModus: .vollstaendig)
        }
    }

    /// Stufe „Nur Kontakt speichern": Google-Kontakt (People API, best-effort wie im
    /// Assistenten üblich) UND Kunde in der Artikel-DB (dublettengeschützt) — explizit
    /// KEIN Projekt, KEIN Drive-Ordner, KEIN Mastermind-Routing-Eintrag.
    private func erzeugeNurKontakt(ergebnis: IntakeErgebnis) async throws -> IntakeAnlageErgebnis {
        let client = AirtableClient()

        let draft = ContactDraft(
            givenName: ergebnis.kundeFelder["Vorname"] ?? ergebnis.kundeFelder["Nachname"] ?? "",
            familyName: ergebnis.kundeFelder["Nachname"],
            email: ergebnis.kundeFelder["Kontakt 1 Email"],
            phone: ergebnis.kundeFelder["Kontakt 1 Telefon"],
            organization: ergebnis.kundeFelder["Firma"])
        let kontaktOutcome = await createContact(draft)

        let kundeRecordID = try await legeKundeAnFallsNichtVorhanden(ergebnis: ergebnis, client: client)

        await syncBusinessRegistry()
        refreshAssistantKundenWissen()

        let kontaktSummary: String
        switch kontaktOutcome {
        case .created(let name): kontaktSummary = "Google-Kontakt \(name) angelegt"
        case .failed(let msg): kontaktSummary = "Google-Kontakt nicht angelegt (\(msg))"
        }
        let kundeName = ergebnis.kundeFelder["Nachname"] ?? "Kunde"
        return IntakeAnlageErgebnis(
            summary: "Kontakt gespeichert: \(kundeName) (Artikel-DB-ID \(kundeRecordID)) · \(kontaktSummary)",
            driveProjektOrdnerID: nil)
    }

    /// Kunde in der Artikel-Base anlegen (dublettengeschützt: Fetch-vor-Create). Gemeinsam
    /// genutzt von `.kontakt`- und `.lead`/`.projektMitOrdner`-Stufen.
    private func legeKundeAnFallsNichtVorhanden(ergebnis: IntakeErgebnis, client: AirtableClient) async throws -> String {
        let kundeBaseID = CartStore.artikelBaseID  // appdxTeT6bhSBmwx5
        let kundeTable  = "Kunden"
        let kundeFelder: [String: AirtableFieldValue] = ergebnis.kundeFelder
            .reduce(into: [:]) { dict, pair in dict[pair.key] = .string(pair.value) }

        // Review-Fix (high): ohne Dublettenschutz legt ein Retry nach transientem
        // Netzwerkfehler (der Button reaktiviert sich bei .fehler) denselben Kunden
        // ein zweites Mal an — sichtbar für das ganze Team. Fetch-dann-erst-Create,
        // exakt das Muster aus ProjektProvisioningService.findeBestehendenRecord.
        if let bestehend = try? await findeBestehendenKunden(ergebnis: ergebnis, client: client) {
            return bestehend
        }
        let kundeRecordID: String
        do {
            kundeRecordID = try await client.createRecord(
                baseID: kundeBaseID, table: kundeTable, fields: kundeFelder)
        } catch AirtableError.invalidBaseID(let msg) {
            recordWriteShadowFailure(table: kundeTable, baseID: kundeBaseID, fields: kundeFelder, errorMessage: msg, integrationID: "AIRTABLE_INTAKE_KUNDE_ANLEGEN")
            throw IntakeSchreibFehler.whitelist(msg)
        } catch AirtableError.notConnected {
            recordWriteShadowFailure(table: kundeTable, baseID: kundeBaseID, fields: kundeFelder, errorMessage: "notConnected", integrationID: "AIRTABLE_INTAKE_KUNDE_ANLEGEN")
            throw IntakeSchreibFehler.nichtVerbunden
        } catch AirtableError.httpError(let code) {
            recordWriteShadowFailure(table: kundeTable, baseID: kundeBaseID, fields: kundeFelder, errorMessage: "httpError(\(code))", integrationID: "AIRTABLE_INTAKE_KUNDE_ANLEGEN")
            throw IntakeSchreibFehler.http(code)
        } catch AirtableError.validationFailed(let code, let message) {
            recordWriteShadowFailure(table: kundeTable, baseID: kundeBaseID, fields: kundeFelder, errorMessage: "validationFailed(\(code)): \(message)", integrationID: "AIRTABLE_INTAKE_KUNDE_ANLEGEN")
            throw IntakeSchreibFehler.validationFailed(code, message)
        }

        // mykilOS 8, Block A: vollständige Sicherheitskopie des Writes (siehe
        // WriteShadowRecorder.swift) — nicht-fatal, blockiert den Intake nie.
        try? writeShadow.recordAirtableWrite(
            action: .create, actorUserID: actorUserID, baseID: kundeBaseID, table: kundeTable,
            recordID: kundeRecordID, fields: kundeFelder, mode: provisioningMode.mode, result: .ok)
        // Härtung (2026-07-01, Audit): der meistgenutzte Write der ganzen App hatte bisher
        // KEINEN dataFlow.log-Aufruf — in der Schaltzentrale unsichtbar.
        dataFlow.log(integrationID: "AIRTABLE_INTAKE_KUNDE_ANLEGEN", actorUserID: actorUserID,
                     action: .success, recordsWritten: 1,
                     summary: "Intake: Kunde angelegt (\(kundeRecordID))")

        do {
            try audit.append(AuditEntry(
                actorUserID: actorUserID, projectID: "-",
                action: .contactCreated,
                summary: "Intake: Kunde angelegt (\(ergebnis.kundeFelder["Nachname"] ?? "?"), ID: \(kundeRecordID))"))
        } catch {
            MykLog.lifecycle.error("Audit Kunde-Anlage fehlgeschlagen: \(String(describing: error), privacy: .public)")
        }
        return kundeRecordID
    }

    // Reihenfolge: 1. Kunde anlegen → Record-ID → 2. Projekt mit Kunden-Link anlegen →
    //              3. Warenkorb (falls Positionen vorhanden) via CartStore senden →
    //              4. ECHTE Provisionierung (Johannes, 2026-07-01): Projektnummer reservieren,
    //                 Drive-Ordner anlegen (Umfang je `ordnerModus`), Mastermind-Routing-Eintrag
    //                 schreiben (bisher NUR aus Drive-Scan befüllt), bei `.vollstaendig`
    //                 zusätzlich das Fragebogen-PDF in "07 Fragebogen" ablegen. NICHT-FATAL:
    //                 Kunde+Projekt sind zu diesem Zeitpunkt schon angelegt (append-only) —
    //                 ein Fehler hier darf den Intake nicht rückgängig machen.
    // Bases: Artikel-DB (appdxTeT6bhSBmwx5) für Kunde/Projekt/Warenkorb, Mastermind
    // (appuVMh3KDfKw4OoQ) für den Routing-Eintrag.
    private func erzeugeKundeUndProjekt(
        ergebnis: IntakeErgebnis, modell: FragebogenModel, ordnerModus: ProjektOrdnerModus
    ) async throws -> IntakeAnlageErgebnis {
        let client = AirtableClient()

        // SCHRITT 1: Kunde in Artikel-Base anlegen (gleiche Base wie Projekt → Record-Link gültig)
        let kundeRecordID = try await legeKundeAnFallsNichtVorhanden(ergebnis: ergebnis, client: client)

        // SCHRITT 2: Projekt in Artikel-DB anlegen (+ Kunden-Link als Klartext-ID)
        let projektBaseID = CartStore.artikelBaseID      // appdxTeT6bhSBmwx5
        let projektTable  = "Projekte"
        var projektFelder: [String: AirtableFieldValue] = ergebnis.projektFelder
            .reduce(into: [:]) { dict, pair in dict[pair.key] = .string(pair.value) }
        // Kunden-Verknüpfung: multipleRecordLinks — als Array übergeben.
        // Airtable verlangt für Link-Felder ein JSON-Array. .array([]) ist der korrekte Typ.
        if kundeRecordID.isEmpty == false {
            projektFelder["Kunde"] = .array([kundeRecordID])
        }

        // Gleicher Dublettenschutz wie beim Kunden (siehe oben).
        let projektRecordID: String
        if let bestehend = try? await findeBestehendesProjekt(ergebnis: ergebnis, kundeRecordID: kundeRecordID, client: client) {
            projektRecordID = bestehend
        } else {
            do {
                projektRecordID = try await client.createRecord(
                    baseID: projektBaseID, table: projektTable, fields: projektFelder)
            } catch AirtableError.invalidBaseID(let msg) {
                recordWriteShadowFailure(table: projektTable, baseID: projektBaseID, fields: projektFelder, errorMessage: msg, integrationID: "AIRTABLE_INTAKE_PROJEKT_ANLEGEN")
                throw IntakeSchreibFehler.whitelist("Projekt: \(msg)")
            } catch AirtableError.notConnected {
                recordWriteShadowFailure(table: projektTable, baseID: projektBaseID, fields: projektFelder, errorMessage: "notConnected", integrationID: "AIRTABLE_INTAKE_PROJEKT_ANLEGEN")
                throw IntakeSchreibFehler.nichtVerbunden
            } catch AirtableError.httpError(let code) {
                recordWriteShadowFailure(table: projektTable, baseID: projektBaseID, fields: projektFelder, errorMessage: "httpError(\(code))", integrationID: "AIRTABLE_INTAKE_PROJEKT_ANLEGEN")
                throw IntakeSchreibFehler.http(code)
            } catch AirtableError.validationFailed(let code, let message) {
                recordWriteShadowFailure(table: projektTable, baseID: projektBaseID, fields: projektFelder, errorMessage: "validationFailed(\(code)): \(message)", integrationID: "AIRTABLE_INTAKE_PROJEKT_ANLEGEN")
                throw IntakeSchreibFehler.validationFailed(code, message)
            }

            try? writeShadow.recordAirtableWrite(
                action: .create, actorUserID: actorUserID, baseID: projektBaseID, table: projektTable,
                recordID: projektRecordID, fields: projektFelder, mode: provisioningMode.mode, result: .ok)
            // Härtung (2026-07-01, Audit): analog zur Kunde-Anlage — bisher unsichtbar.
            dataFlow.log(integrationID: "AIRTABLE_INTAKE_PROJEKT_ANLEGEN", actorUserID: actorUserID,
                         action: .success, recordsWritten: 1,
                         summary: "Intake: Projekt angelegt (\(projektRecordID))")

            do {
                try audit.append(AuditEntry(
                    actorUserID: actorUserID, projectID: "-",
                    action: .contactCreated,    // kein separater Intake-AuditTyp nötig — nahe genug
                    summary: "Intake: Projekt angelegt (\(ergebnis.projektFelder["Projektname"] ?? "?"), ID: \(projektRecordID), KundeID: \(kundeRecordID))"))
            } catch {
                MykLog.lifecycle.error("Audit Projekt-Anlage fehlgeschlagen: \(String(describing: error), privacy: .public)")
            }
        }

        // SCHRITT 3: Warenkorb (falls Positionen vorhanden), append-only via CartStore
        if !ergebnis.warenkorb.items.isEmpty {
            let warenkorb = Warenkorb(
                items: ergebnis.warenkorb.items,
                projektRecordID: projektRecordID,
                projektName: ergebnis.projektFelder["Projektname"])
            let cartStore = CartStore(
                fetcher: AirtableClient(),
                creator: AirtableClient(),
                updater: AirtableClient(),
                auditStore: audit,
                actorUserID: actorUserID
            )
            // Fehler beim Warenkorb-Senden sind nicht fatal (Kunde + Projekt sind schon angelegt).
            do {
                let outcome = try await cartStore.sendWarenkorbToAirtable(warenkorb)
                // Härtung (2026-07-01, Audit): bisher kein dataFlow.log für diesen häufig
                // getroffenen Write-Pfad — in der Schaltzentrale unsichtbar.
                if case .success = outcome {
                    dataFlow.log(integrationID: "AIRTABLE_WARENKORB_SENDEN", actorUserID: actorUserID,
                                 action: .success, recordsWritten: 1,
                                 summary: "Intake: Warenkorb gesendet (\(ergebnis.warenkorb.items.count) Positionen)")
                }
            } catch {
                MykLog.lifecycle.error("Intake Warenkorb-Senden fehlgeschlagen: \(String(describing: error), privacy: .public)")
                dataFlow.log(integrationID: "AIRTABLE_WARENKORB_SENDEN", actorUserID: actorUserID,
                             action: .error, errorMessage: error.localizedDescription,
                             summary: "Intake: Warenkorb-Senden fehlgeschlagen")
                // Fehler wird geloggt aber nicht weitergeworfen — Kunde + Projekt sind live.
            }
        }

        // Registry aktualisieren (neue Projekte/Kunden sofort sichtbar)
        await registry.syncFromAirtable(baseID: AirtableClient.writableBaseID, auth: airtableAuth)
        // mykilOS 8, Block A: der Intake schreibt nach Artikel-Base, `registry` syncFromAirtable
        // (oben) liest aber Mastermind — ohne diesen zweiten Sync wäre der neue Kunde/Projekt
        // in der Geschäfts-Wahrheit unsichtbar, bis irgendwann ein Mastermind-Routing-Eintrag
        // entsteht. Siehe ExternalMappingRegistry.swift / AIRTABLE_DATENFLUSS_AUDIT.md §3.
        await syncBusinessRegistry()
        refreshAssistantKundenWissen()

        // SCHRITT 4: Echte Provisionierung (Drive-Ordner + Mastermind-Routing [+ PDF]).
        let driveOrdnerID = await provisioniereEchtesProjekt(ergebnis: ergebnis, modell: modell, ordnerModus: ordnerModus)

        let kundeName = ergebnis.kundeFelder["Nachname"] ?? "Kunde"
        let projektName = ergebnis.projektFelder["Projektname"] ?? "Projekt"
        // Review-Fix (medium): der grüne Erfolgs-Status darf NICHT identisch aussehen,
        // wenn die echte Provisionierung (Drive-Ordner + Galerie-Sichtbarkeit) im
        // Hintergrund fehlgeschlagen ist — Kunde+Projekt sind trotzdem sicher angelegt,
        // aber ohne Hinweis würde niemand merken, dass Drive/Galerie fehlen.
        let summary: String
        if driveOrdnerID != nil {
            summary = "\(kundeName) + \(projektName) erfolgreich angelegt"
        } else if IntakeAdresse.strNummerBildbar(ergebnis: ergebnis) == false {
            // Härtung (2026-07-01, Audit): häufigster, konkret behebbarer Grund für Stufe
            // „Lead" — statt des generischen Hinweises die tatsächliche, umsetzbare Ursache
            // nennen (Lead-Stufe erlaubt bewusst eine adresslose Anlage, siehe FragebogenModel).
            summary = "\(kundeName) + \(projektName) angelegt — kein Drive-Ordner/Galerie-Eintrag: dafür wird mindestens eine Adresse (Straße oder Ort, Kunden- oder Projektadresse) benötigt. Adresse ergänzen und Ordner danach manuell in Drive anlegen."
        } else {
            summary = "\(kundeName) + \(projektName) angelegt — Hinweis: Drive-Ordner/Galerie-Eintrag konnte nicht automatisch erstellt werden (Details in der Schaltzentrale), bitte Johannes informieren."
        }
        return IntakeAnlageErgebnis(summary: summary, driveProjektOrdnerID: driveOrdnerID)
    }

    /// Dublettenschutz vor der Kunde-Anlage (Review-Fix): sucht einen bestehenden Kunden-Record
    /// mit exakt gleichem Nachnamen UND (E-Mail ODER Telefon) — nur ein starkes, zweifaches
    /// Signal zählt, ein bloßer Namensgleichklang reicht nicht (zu viele „Schmidt"s). Read-only;
    /// ein Fetch-Fehler ist nicht fatal (dann wird wie bisher neu angelegt — kein Verhaltensverlust).
    private func findeBestehendenKunden(ergebnis: IntakeErgebnis, client: AirtableClient) async throws -> String? {
        guard let nachname = ergebnis.kundeFelder["Nachname"], nachname.isEmpty == false else { return nil }
        let email = ergebnis.kundeFelder["Kontakt 1 Email"]
        let telefon = ergebnis.kundeFelder["Kontakt 1 Telefon"]
        guard (email?.isEmpty == false) || (telefon?.isEmpty == false) else { return nil }
        let records = try await client.fetchRecords(baseID: CartStore.artikelBaseID, table: "Kunden")
        let treffer = records.first { record in
            guard record["Nachname"]?.stringValue == nachname else { return false }
            if let email, email.isEmpty == false,
               record["Kontakt 1 Email"]?.stringValue?.lowercased() == email.lowercased() { return true }
            if let telefon, telefon.isEmpty == false,
               record["Kontakt 1 Telefon"]?.stringValue == telefon { return true }
            return false
        }
        return treffer?["_airtableRecordID"]?.stringValue
    }

    /// Dublettenschutz vor der Projekt-Anlage (Review-Fix): sucht einen bestehenden Projekt-Record
    /// mit exakt gleichem Projektnamen UND Kunden-Link. Read-only, nicht-fataler Fetch-Fehler
    /// (dann wird wie bisher neu angelegt).
    private func findeBestehendesProjekt(ergebnis: IntakeErgebnis, kundeRecordID: String, client: AirtableClient) async throws -> String? {
        guard let projektname = ergebnis.projektFelder["Projektname"], projektname.isEmpty == false,
              kundeRecordID.isEmpty == false else { return nil }
        let records = try await client.fetchRecords(baseID: CartStore.artikelBaseID, table: "Projekte")
        let treffer = records.first { record in
            record["Projektname"]?.stringValue == projektname
                && record["Kunde"]?.firstArrayValue == kundeRecordID
        }
        return treffer?["_airtableRecordID"]?.stringValue
    }

    /// Dublettenschutz vor SCHRITT 4 (Härtung, 2026-07-01): sucht einen bestehenden Mastermind-
    /// Routing-Eintrag mit exakt gleichem Kundennummer-Slug UND Titel — verhindert, dass ein
    /// Retry nach fehlgeschlagener Provisionierung eine zweite Projektnummer/Drive-Ordner/
    /// Routing-Zeile für denselben Kunden/Projekt erzeugt. Read-only; ein Fetch-Fehler ist
    /// nicht fatal (dann läuft die Provisionierung wie bisher neu an).
    /// Härtung (2026-07-01, Audit): zusätzlich `Quelle == "Fragebogen"` verlangt — Titel+
    /// Kundennummer-Slug allein (z. B. zwei verschiedene "Schmidt"-Kunden mit demselben, weil
    /// generischen Projektnamen wie "Küche") ist ein zu schwaches Signal für einen fremden,
    /// z. B. aus dem Drive-Scan importierten Routing-Eintrag — engt den Treffer auf "ein
    /// bereits per Fragebogen angelegter Eintrag für exakt diese Kombination" ein.
    private func findeBestehendenRoutingEintrag(
        kundeSlug: String, projektName: String?
    ) async throws -> (recordID: String, driveOrdnerID: String?)? {
        guard let projektName, projektName.isEmpty == false, kundeSlug.isEmpty == false else { return nil }
        let records = try await AirtableClient().fetchRecords(baseID: AirtableClient.writableBaseID, table: "Projekte")
        guard let treffer = records.first(where: { record in
            record["Titel"]?.stringValue == projektName
                && record["Kundennummer"]?.stringValue == kundeSlug
                && record["Quelle"]?.stringValue == "Fragebogen"
        }) else { return nil }
        guard let recordID = treffer["_airtableRecordID"]?.stringValue else { return nil }
        return (recordID, treffer["Drive-Ordner-ID"]?.stringValue)
    }

    /// Reserviert eine echte Projektnummer, legt den Drive-Ordner an (Umfang je `ordnerModus`)
    /// und trägt einen Routing-Eintrag in die Mastermind-„Projekte"-Tabelle ein (macht das
    /// Projekt in der App-Galerie sichtbar). Bei `.vollstaendig` zusätzlich das Fragebogen-PDF
    /// in "07 Fragebogen" hochladen (bei `.leadRumpf` gibt es diesen Unterordner nicht — der
    /// Rumpf-Ordner hat bewusst KEINE Schema-Unterstruktur). NICHT-FATAL: gibt bei jedem
    /// Fehler `nil` zurück (sichtbar geloggt via dataFlow/MykLog) — Kunde+Projekt sind zu
    /// diesem Zeitpunkt schon live in der Artikel-DB, ein Fehler hier darf das nie rückgängig machen.
    private func provisioniereEchtesProjekt(
        ergebnis: IntakeErgebnis, modell: FragebogenModel, ordnerModus: ProjektOrdnerModus
    ) async -> String? {
        do {
            // Härtung (2026-07-01, Audit): SCHRITT 1/2 (Kunde/Projekt in der Artikel-DB) sind
            // dublettengeschützt (Fetch-vor-Create), SCHRITT 4 (Projektnummer + Drive-Ordner +
            // Mastermind-Routing) war es bisher NICHT — ein Retry nach einem fehlgeschlagenen
            // SCHRITT 4 (z. B. transienter Netzwerkfehler beim Routing-Write) hätte sonst bei
            // jedem erneuten Versuch eine weitere, nie wiederverwendbare Projektnummer verbrannt
            // und einen zweiten Drive-Ordner + Mastermind-Eintrag für denselben Kunden/Projekt
            // angelegt. Gleiches Muster wie `findeBestehendenKunden`/`findeBestehendesProjekt`:
            // Fetch-vor-Create, hier gegen die Mastermind-„Projekte"-Tabelle.
            let kundeSlugFuerSuche = (ergebnis.kundeFelder["Nachname"] ?? "Projekt")
                .replacingOccurrences(of: " ", with: "")
            let projektNameFuerSuche = ergebnis.projektFelder["Projektname"]
            // Härtung (2026-07-01, Audit): ein Treffer OHNE Drive-Ordner-ID (z. B. ein
            // Legacy-/Teil-Eintrag) darf NICHT wie ein vollständiger Erfolg kurzgeschlossen
            // werden — das wäre ein permanenter, nie behebbarer Sackgassen-Zustand (jeder
            // erneute Versuch träfe wieder denselben unvollständigen Eintrag und läge wieder
            // nil zurück). Nur ein Treffer MIT echter Drive-Ordner-ID wird kurzgeschlossen;
            // ein unvollständiger Treffer wird unten stattdessen per `updateRecord`
            // vervollständigt statt einen zweiten Routing-Eintrag anzulegen.
            var bestehenderRoutingRecordID: String? = nil
            if let bestehend = try? await findeBestehendenRoutingEintrag(
                kundeSlug: kundeSlugFuerSuche, projektName: projektNameFuerSuche
            ) {
                if let driveOrdnerID = bestehend.driveOrdnerID, driveOrdnerID.isEmpty == false {
                    MykLog.lifecycle.info("Echte Provisionierung übersprungen (Routing-Eintrag existiert bereits): \(driveOrdnerID, privacy: .public)")
                    dataFlow.log(
                        integrationID: "AIRTABLE_FRAGEBOGEN_PROJEKT_ROUTING", actorUserID: actorUserID,
                        action: .success, recordsRead: 1,
                        summary: "Provisionierung übersprungen — bestehender Routing-Eintrag gefunden (\(bestehend.recordID))")
                    return driveOrdnerID
                }
                // Treffer existiert, aber ohne Drive-Ordner-ID — unten vervollständigen statt
                // neu anlegen (kein zweiter Routing-Eintrag für denselben Kunden/Projekt).
                bestehenderRoutingRecordID = bestehend.recordID
                MykLog.lifecycle.info("Unvollständiger Routing-Eintrag gefunden (\(bestehend.recordID)) — wird vervollständigt statt dupliziert.")
            }

            // Review-Fix (medium): die STR-Nr MUSS bildbar sein, BEVOR eine Projektnummer
            // reserviert wird — Projektnummern werden nie wiederverwendet (auch nicht bei
            // Archiv), eine erst NACH der Reservierung fehlschlagende STR-Nr-Bildung hätte
            // sonst bei der (adress-losen) Lead-Stufe still eine Nummer verbrannt, ohne dass
            // je ein Ordner oder Routing-Eintrag entstand. Eine Wahrheit für die Adress-
            // Auflösung — geteilt mit der Stufe-3-Readiness-Prüfung in FragebogenView.
            let (strasse, hausnummer, ort) = IntakeAdresse.aufloesen(ergebnis: ergebnis)
            let strErgebnis = STRNummer.bilde(strasse: strasse, hausnummer: hausnummer, ort: ort)
            let strBlock: String
            switch strErgebnis {
            case .gebildet(let block, _):
                strBlock = block
            case .nichtBildbar(let grund):
                MykLog.lifecycle.error("Echte Provisionierung übersprungen (keine STR-Nr bildbar): \(grund, privacy: .public)")
                // Sichtbar in der Schaltzentrale, nicht nur in der Konsole — sonst verschwindet
                // eine übersprungene Provisionierung spurlos aus dem Team-Handbuch.
                dataFlow.log(
                    integrationID: "DRIVE_FRAGEBOGEN_PROJEKT_ORDNER", actorUserID: actorUserID,
                    action: .error, errorMessage: grund,
                    summary: "Fragebogen: Provisionierung übersprungen — keine STR-Nr bildbar (keine Adresse)")
                return nil
            }

            // Härtung (2026-07-01, echte Kollision live entdeckt: zwei Fragebogen-Läufe
            // vergaben 2026-027/028, obwohl diese Nummern bereits als manuell angelegte
            // Drive-Ordner (außerhalb der App, nie in die Registry gesynct) real existierten).
            // numberAuthorityLocal() kennt nur die Registry (Airtable-Snapshot vom 2026-06-27,
            // seither kein laufender Sync) + eigene GRDB-Reservierungen — beides blind
            // gegenüber Ordnern, die manuell oder außerhalb der App entstehen. Zusätzlich
            // gegen den ECHTEN Drive-Ordnerinhalt prüfen, bevor die Nummer verwendet wird.
            let nummer = try await reserviereKollisionsfreieNummer(jahr: Self.aktuellesJahr(), parentID: Self.projekteRootDriveID)

            // Review-Fix (low): voller Nachname statt nur erstem Wort — "von Boch"/"de Vries"
            // wären sonst auf "von"/"de" verkürzt worden (zu generisch für Kalender-/Kontakte-/
            // Mail-Suche, Verwechslungsgefahr). Leerzeichen entfernt, damit der Ordnername
            // schema-konform bleibt (ein Wortblock wie bei den bestehenden Drive-Ordnern).
            let kundeSlug = (ergebnis.kundeFelder["Nachname"] ?? "Projekt")
                .replacingOccurrences(of: " ", with: "")
            // Härtung (2026-07-01): der beschreibende Teil des ORDNERNAMENS ist im Fragebogen
            // editierbar (Edit-Modus in der Bestätigungsansicht) — die Nummer selbst NIE, die
            // kommt ausschließlich aus der kollisionsgeprüften Vergabe oben. `kundeSlug` bleibt
            // unabhängig davon der Kanon für Kalender-/Kontakte-/Mail-Suche weiter unten.
            let suffixOverride = modell.ordnerNameSuffixOverride.trimmingCharacters(in: .whitespaces)
            let beschreibenderTeil = suffixOverride.isEmpty ? "\(kundeSlug)_\(strBlock)" : suffixOverride
            let ordnerName = "\(nummer.driveFormat)_\(beschreibenderTeil)"

            // Drive-Ordner: bei `.vollstaendig` der komplette Schema-Baum im echten PROJEKTE-
            // Root; bei `.leadRumpf` NUR der Wurzelordner (kein Unterbau) in einem eigenen
            // "_LEADS"-Unterordner (Johannes, 2026-07-01) — bei späterer Aufwertung zu Stufe 3
            // bekommt derselbe Ordnername den vollen Unterbau im echten Root nachgezogen.
            let rootOrdnerID: String
            let unterordnerAnzahl: Int
            switch ordnerModus {
            case .vollstaendig:
                let gebaut = try await DriveOrdnerbaumBuilder.baue(
                    drive: GoogleDriveClient(), parentID: Self.projekteRootDriveID,
                    ordnerName: ordnerName, schema: nomenklatur.aktivesSchema())
                rootOrdnerID = gebaut.rootOrdnerID
                unterordnerAnzahl = gebaut.unterordnerIDs.count
            case .leadRumpf:
                let drive = GoogleDriveClient()
                let leadsParentID = try await drive.findOrCreateSubfolder(parentID: Self.projekteRootDriveID, name: "_LEADS")
                rootOrdnerID = try await drive.findOrCreateSubfolder(parentID: leadsParentID, name: ordnerName)
                unterordnerAnzahl = 0
            }
            dataFlow.log(
                integrationID: "DRIVE_FRAGEBOGEN_PROJEKT_ORDNER", actorUserID: actorUserID,
                action: .success, recordsWritten: unterordnerAnzahl + 1,
                summary: "Fragebogen (\(ordnerModus)): Projekt-Ordner angelegt (\(ordnerName), Ordner-ID \(rootOrdnerID))")

            // Mastermind-Routing-Eintrag — macht das Projekt in der App-Galerie sichtbar.
            // "Fragebogen" ist eine NEUE Quelle-Option (bisher nur "Drive"/"Manuell"), "Lead"
            // eine NEUE Phase-Option (bisher nur "Aktiv"/"Archiviert") — beide mit Johannes
            // abgestimmt (2026-07-01); `typecast` lässt Airtable sie sicher anlegen.
            let routingFelder: [String: AirtableFieldValue] = [
                "Projektnummer": .string(nummer.appFormat),
                "Titel": .string(ergebnis.projektFelder["Projektname"] ?? ordnerName),
                "Art": .string("kitchen"),
                "Kundennummer": .string(kundeSlug),
                "Kalender-Suche": .string(kundeSlug),
                "Kontakte-Suche": .string(kundeSlug),
                "Mail-Suche": .string(kundeSlug),
                "Drive-Ordner-ID": .string(rootOrdnerID),
                "Drive-Ordnername": .string(ordnerName),
                "Phase": .string(ordnerModus == .vollstaendig ? "Aktiv" : "Lead"),
                "Quelle": .string("Fragebogen"),
                "ParseConfidence": .string("full"),
            ]
            // Härtung (2026-07-01, Audit): existiert bereits ein (unvollständiger) Treffer aus
            // der Suche oben, wird er per updateRecord vervollständigt statt einen zweiten
            // Routing-Eintrag für denselben Kunden/Projekt anzulegen.
            let routingRecordID: String
            let routingAction: WriteShadowAction
            do {
                if let bestehenderRoutingRecordID {
                    // Härtung (2026-07-01, Audit): typecast:true wie beim CREATE-Zweig unten —
                    // sonst würde das Vervollständigen eines unvollständigen Eintrags an
                    // Phase="Lead"/Quelle="Fragebogen" scheitern, falls diese Optionen dort
                    // noch nicht existieren.
                    try await AirtableClient().updateRecord(
                        baseID: AirtableClient.writableBaseID, table: "Projekte",
                        recordID: bestehenderRoutingRecordID, fields: routingFelder, typecast: true)
                    routingRecordID = bestehenderRoutingRecordID
                    routingAction = .update
                } else {
                    routingRecordID = try await AirtableClient().createRecord(
                        baseID: AirtableClient.writableBaseID, table: "Projekte", fields: routingFelder, typecast: true)
                    routingAction = .create
                }
            } catch {
                recordWriteShadowFailure(
                    table: "Projekte", baseID: AirtableClient.writableBaseID,
                    fields: routingFelder, errorMessage: String(describing: error))
                dataFlow.log(
                    integrationID: "AIRTABLE_FRAGEBOGEN_PROJEKT_ROUTING", actorUserID: actorUserID,
                    action: .error, errorMessage: String(describing: error),
                    summary: "Mastermind-Routing-Eintrag fehlgeschlagen für \(ordnerName)")
                throw error
            }
            try? writeShadow.recordAirtableWrite(
                action: routingAction, actorUserID: actorUserID, baseID: AirtableClient.writableBaseID, table: "Projekte",
                recordID: routingRecordID, fields: routingFelder, mode: provisioningMode.mode, result: .ok)
            dataFlow.log(
                integrationID: "AIRTABLE_FRAGEBOGEN_PROJEKT_ROUTING", actorUserID: actorUserID,
                action: .success, recordsWritten: 1,
                summary: "Mastermind-Routing-Eintrag angelegt (\(nummer.appFormat))")

            // Studio-OS-Rollout (2026-07-02, Johannes): „Projekt-Anlegen-Maske feuert in
            // ClickUp, schickt Kunde/Daten, legt Drive-Ordner an" — ECHTE ClickUp-Liste im
            // Ordner "01 Kundenprojekte" (kein TEST-Präfix). NICHT-FATAL wie der PDF-Upload
            // unten: Kunde+Projekt+Drive sind zu diesem Zeitpunkt bereits sicher angelegt,
            // ein ClickUp-Fehler (z. B. nicht verbunden) darf das nie rückgängig machen.
            let vorname = ergebnis.kundeFelder["Vorname"] ?? ""
            let nachname = ergebnis.kundeFelder["Nachname"] ?? "Kunde"
            let kundeAnzeigename = vorname.isEmpty ? nachname : "\(vorname) \(nachname)"
            do {
                let clickUp = ClickUpClient()
                let listenContent = """
                Kunde: \(kundeAnzeigename)
                Projektnummer: \(nummer.appFormat)
                Drive: https://drive.google.com/drive/folders/\(rootOrdnerID)
                Quelle: mykilOS Fragebogen
                """
                let listID = try await clickUp.findOrCreateList(
                    folderID: Self.clickUpKundenprojekteFolderID, name: ordnerName, content: listenContent)
                let bestehendeTasks = Set((try? await clickUp.tasks(listID: listID))?.map(\.name) ?? [])
                for taskName in ClickUpProjectTemplate.standardKundenprojekt
                where bestehendeTasks.contains(taskName) == false {
                    _ = try await clickUp.createTask(listID: listID, name: taskName)
                }
                dataFlow.log(
                    integrationID: "CLICKUP_FRAGEBOGEN_PROJEKT_ANLEGEN", actorUserID: actorUserID,
                    action: .success, recordsWritten: 1,
                    summary: "ClickUp-Liste angelegt (\(listID)) für \(ordnerName)")
            } catch {
                MykLog.lifecycle.error("ClickUp-Provisionierung fehlgeschlagen: \(String(describing: error), privacy: .public)")
                dataFlow.log(
                    integrationID: "CLICKUP_FRAGEBOGEN_PROJEKT_ANLEGEN", actorUserID: actorUserID,
                    action: .error, errorMessage: String(describing: error),
                    summary: "ClickUp-Provisionierung fehlgeschlagen für \(ordnerName)")
            }

            do {
                try audit.append(AuditEntry(
                    actorUserID: actorUserID, projectID: nummer.appFormat,
                    action: .projectLinked,
                    summary: "Fragebogen: echte Provisionierung — Drive \(rootOrdnerID), Routing \(routingRecordID)"))
            } catch {
                MykLog.lifecycle.error("Audit für echte Provisionierung fehlgeschlagen: \(String(describing: error), privacy: .public)")
            }

            // Registry sofort aktualisieren — das neue Projekt ist ab jetzt live in der Galerie.
            await registry.syncFromAirtable(baseID: AirtableClient.writableBaseID, auth: airtableAuth)

            // Fragebogen-PDF in den neuen "07 Fragebogen"-Ordner hochladen — NUR bei
            // `.vollstaendig` (der Rumpf-Ordner hat keinen solchen Unterordner). Rein
            // kosmetisch, nicht-fatal (Projekt existiert bereits vollständig ohne diesen Schritt).
            if ordnerModus == .vollstaendig {
                do {
                    let pdf = try await MykFragebogenPDFRenderer().renderPDF(modell: modell)
                    _ = try await MykFragebogenDriveUploader().uploadFragebogenPDF(
                        pdfData: pdf, projektFolderID: rootOrdnerID,
                        dateiname: "Fragebogen_\(nummer.driveFormat)_\(kundeSlug).pdf")
                } catch {
                    MykLog.lifecycle.error("Fragebogen-PDF-Upload fehlgeschlagen: \(String(describing: error), privacy: .public)")
                }
            }

            return rootOrdnerID
        } catch {
            MykLog.lifecycle.error("Echte Provisionierung fehlgeschlagen: \(String(describing: error), privacy: .public)")
            // Härtung (2026-07-01, Audit): dieser äußere catch (z. B. Projektnummer-Reservierung
            // oder Drive-Ordner-Erstellung schlägt fehl) loggte bisher nur in die Konsole — die
            // Schaltzentrale zeigte also auch diesen Fehlerfall nicht an.
            dataFlow.log(
                integrationID: "DRIVE_FRAGEBOGEN_PROJEKT_ORDNER", actorUserID: actorUserID,
                action: .error, errorMessage: String(describing: error),
                summary: "Echte Provisionierung fehlgeschlagen")
            return nil
        }
    }

    /// Echter Google-Drive-Ordner "PROJEKTE" (Team-Ablage) — Johannes bestätigt, 2026-07-01.
    private static let projekteRootDriveID = "1Q-H_3JsZfiXosFmxtNgoy0hI3cvZLgST"

    /// Echter ClickUp-Ordner "01 Kundenprojekte" im Studio-OS-Workspace (Space
    /// "MYKILOS API TESTSPACE", `90128024109`) — Johannes bestätigt, 2026-07-02: die
    /// Projekt-Anlage-Maske feuert in ClickUp, ohne TEST-Präfix (echte Projekte). Getrennt
    /// von `AppState.clickUpTestProvisioningFolderID` (Sandbox-Isolationsordner).
    private static let clickUpKundenprojekteFolderID = "901211866053"

    // MARK: - Projekt-Geburt (mykilOS 8, Block D / S4) — TEST-Sandbox
    // Eine bestätigte Karte → ein neues Projekt in Drive + Airtable (TEST-Sandbox).
    // Reserviert atomar die nächste Projektnummer, bildet die STR-Nr + den Ordnernamen,
    // baut den Plan und ruft den idempotenten ProvisioningService. Gated über
    // provisioningMode (.test). Liefert das Ergebnis (Drive-Ordner-ID, Airtable-Record-ID).
    public func gebaereTestProjekt(
        kundeName: String, kdnr: String, strasse: String?, hausnummer: String?, ort: String?,
        driveParentID: String, airtableBaseID: String, airtableTabelle: String,
        clickUpFolderID: String? = nil
    ) async throws -> ProvisioningResult {
        // 1. Nächste Projektnummer atomar reservieren — zusätzlich gegen den echten Inhalt
        // von "_TEST_PROVISIONING" geprüft (Konsistenz mit der echten Provisionierung,
        // schützt vor Kollisionen bei wiederholten Sandbox-Testläufen).
        let nummer = try await reserviereKollisionsfreieNummer(
            jahr: Self.aktuellesJahr(), parentID: driveParentID, nestedSubfolderName: "_TEST_PROVISIONING")
        // 2. STR-Nr bilden — Schema-Bruch wird hier zur Warnung, kein kaputter Ordner.
        let strErgebnis = STRNummer.bilde(strasse: strasse, hausnummer: hausnummer, ort: ort)
        let strBlock: String
        switch strErgebnis {
        case .gebildet(let block, _): strBlock = block
        case .nichtBildbar(let grund): throw ProvisioningError.ungueltigerPlan("STR-Nr: \(grund)")
        }
        let kundeSlug = kundeName.split(separator: " ").first.map(String.init) ?? kundeName
        let ordnerName = "\(nummer.driveFormat)_\(kundeSlug)_\(strBlock)"
        let plan = ProvisioningPlan(
            projektnummer: nummer, kdnr: kdnr, kundeName: kundeName, ordnerName: ordnerName,
            airtableFelder: ["Projektname": "\(kundeSlug) \(strBlock)"],
            schema: nomenklatur.aktivesSchema())
        // 3. Provisionieren (gated TEST-Sandbox, idempotent, teilfehler-fest).
        return try await provisioningService.provision(
            plan: plan, mode: provisioningMode.mode, driveParentID: driveParentID,
            airtableBaseID: airtableBaseID, airtableTabelle: airtableTabelle,
            clickUpFolderID: clickUpFolderID, actorUserID: actorUserID)
    }

    /// Studio-OS-Rollout (2026-07-02): die `_TEST_PROVISIONING`-Isolationsebene im echten
    /// ClickUp-Testspace ("MYKILOS API TESTSPACE", Space 90128024109) — analog zum gleich-
    /// namigen Drive-Unterordner. Test-Läufe schreiben AUSSCHLIESSLICH hierhin, nie in die
    /// 10 echten Studio-OS-Ordner daneben.
    public static let clickUpTestProvisioningFolderID = "901212093014"

    /// Die konkrete LocalSequentialAuthority (für nextAndReserve, das nicht im Protokoll ist).
    /// Review-Fix (high, Block D): kein `as?`-Cast mehr — der konkrete Typ wird im Init direkt
    /// mitgespeichert, damit hier nie ein Fallback mit leerer aktiveNummern-Closure entstehen kann.
    private func numberAuthorityLocal() -> LocalSequentialAuthority {
        numberAuthorityConcrete
    }

    /// Härtung (2026-07-01, echte Live-Kollision entdeckt): der Drive-Ordnerinhalt eines Roots
    /// (+ optional eines benannten Unterordners, z. B. "_LEADS"/"_TEST_PROVISIONING") — die
    /// gemeinsame Grundlage für die reservierende UND die reine Vorschau-Variante darunter.
    /// Registry-Cache + eigenes GRDB-Register kennen keine Ordner, die manuell oder außerhalb
    /// der App entstehen; dieser Live-Check schließt genau diese Lücke.
    private func bekanntesProjektOrdnernamen(
        parentID: String, nestedSubfolderName: String?, drive: GoogleDriveFetching
    ) async -> Set<String> {
        var namen: Set<String> = []
        if let wurzel = try? await drive.listFolder(folderID: parentID) {
            namen.formUnion(wurzel.map(\.name))
            if let nestedSubfolderName,
               let unterordner = wurzel.first(where: { $0.name == nestedSubfolderName }),
               let inhalt = try? await drive.listFolder(folderID: unterordner.id) {
                namen.formUnion(inhalt.map(\.name))
            }
        }
        return namen
    }

    private func istDriveKollision(_ kandidat: Projektnummer, bekannteNamen: Set<String>) -> Bool {
        let praefix = kandidat.driveFormat + "_"
        return bekannteNamen.contains { $0.hasPrefix(praefix) }
    }

    /// Reserviert eine Projektnummer UND verifiziert sie zusätzlich gegen den ECHTEN, aktuellen
    /// Drive-Ordnerinhalt — nicht nur gegen den (nachweislich lückenhaften) Registry-Cache. Die
    /// eigentliche Retry-Schleife lebt testbar in `LocalSequentialAuthority.nextAndReserveKollisionsfrei`.
    private func reserviereKollisionsfreieNummer(
        jahr: Int, parentID: String, nestedSubfolderName: String? = "_LEADS",
        drive: GoogleDriveFetching = GoogleDriveClient()
    ) async throws -> Projektnummer {
        let bekannteNamen = await bekanntesProjektOrdnernamen(parentID: parentID, nestedSubfolderName: nestedSubfolderName, drive: drive)
        return try await numberAuthorityLocal().nextAndReserveKollisionsfrei(jahr: jahr) {
            istDriveKollision($0, bekannteNamen: bekannteNamen)
        }
    }

    /// Öffentliche, reine Vorschau (reserviert NICHTS) für die Fragebogen-Bestätigungsansicht:
    /// liefert den vollständigen vorgeschlagenen Projekt-Ordnernamen (Nummer + Kundenname +
    /// STR-Block), damit der Nutzer ihn VOR der echten Anlage sieht. Die Nummer selbst ist NIE
    /// editierbar — das war genau der Ursprung der Live-Kollision, die diese Härtung auslöste;
    /// nur der beschreibende Teil (Kundenname_STR-Block) darf im Edit-Modus angepasst werden.
    /// `nil`, wenn keine STR-Nr bildbar ist (keine Adresse) — dieselbe Prüfung wie bei der echten Anlage.
    public func vorschauProjektOrdnerName(
        kundeNachname: String, strasse: String?, hausnummer: String?, ort: String?
    ) async -> (nummer: String, vorgeschlagenerName: String)? {
        guard case .gebildet(let strBlock, _) = STRNummer.bilde(strasse: strasse, hausnummer: hausnummer, ort: ort) else {
            return nil
        }
        let bekannteNamen = await bekanntesProjektOrdnernamen(
            parentID: Self.projekteRootDriveID, nestedSubfolderName: "_LEADS", drive: GoogleDriveClient())
        guard let nummer = try? await numberAuthorityLocal().nextProjektnummerKollisionsfrei(jahr: Self.aktuellesJahr(), istExternKollidiert: {
            istDriveKollision($0, bekannteNamen: bekannteNamen)
        }) else { return nil }
        let kundeSlug = kundeNachname.replacingOccurrences(of: " ", with: "")
        return (nummer.appFormat, "\(nummer.driveFormat)_\(kundeSlug)_\(strBlock)")
    }

    static func aktuellesJahr() -> Int {
        Calendar.current.component(.year, from: Date())
    }

    /// mykilOS 8, Block A: synct die Geschäfts-Wahrheit (Artikel-Base `Kunden`/
    /// `Projekte`) in den `ExternalMappingRegistry`-Business-Cache. Fehler sind
    /// nicht-fatal (Komfort-Sichtbarkeit, kein Boot-/Intake-Blocker) — sichtbar via
    /// os.Logger, wie `syncKontakte`.
    public func syncBusinessRegistry() async {
        guard let externalMapping else { return }
        do {
            try await externalMapping.syncBusiness(client: AirtableClient(), baseID: CartStore.artikelBaseID)
            dataFlow.log(integrationID: "AIRTABLE_GESCHAEFT_KUNDEN_PROJEKTE", actorUserID: actorUserID,
                         action: .success, summary: "Geschäfts-Kunden/Projekte aus Artikel-Base synchronisiert")
        } catch {
            dataFlow.log(integrationID: "AIRTABLE_GESCHAEFT_KUNDEN_PROJEKTE", actorUserID: actorUserID,
                         action: .error, summary: "Business-Registry-Sync fehlgeschlagen")
            MykLog.lifecycle.error("Business-Registry-Sync fehlgeschlagen: \(String(describing: error), privacy: .public)")
        }
    }

    /// mykilOS 8, Block A (Erweiterung 2026-06-30): Bindungs-Kandidaten für die
    /// Schaltzentrum-Ansicht — Geschäftsprojekte ohne Projektnummer, die per exaktem
    /// Titel-Match genau einem Routing-Projekt zugeordnet werden könnten. Bereits
    /// bestätigte Bindungen werden rausgefiltert.
    public func projectNumberBindingCandidates() -> [ProjectNumberBindingCandidate] {
        guard let externalMapping else { return [] }
        let confirmed = Set(projectNumberBindings.bindings.map(\.businessRecordID))
        return (try? externalMapping.candidateBindings(excluding: confirmed)) ?? []
    }

    /// Bestätigt EINEN Bindungs-Kandidaten — Karte→Bestätigung→Audit, wie jeder andere
    /// Schreibpfad. Rein lokal (GRDB), rührt die Artikel-Projektliste nie an.
    public func confirmProjectNumberBinding(_ candidate: ProjectNumberBindingCandidate) throws {
        try projectNumberBindings.confirm(candidate, actorUserID: actorUserID)
        try audit.append(AuditEntry(
            actorUserID: actorUserID, projectID: candidate.projectNumber,
            action: .projectLinked,
            summary: "Geschäftsprojekt „\(candidate.businessProjektname)“ lokal an Projektnummer \(candidate.projectNumber) gebunden (manuell bestätigt)"))
        // Härtung (2026-07-01, Datenstrom-Audit): der Manifest-Eintrag
        // "PROJECT_NUMBER_LOCAL_BINDING" existierte bisher ohne EINEN einzigen echten
        // dataFlow.log-Aufruf — die Schaltzentrale zeigte die Weiche permanent als
        // "nie ausgelöst", obwohl die Bindung tatsächlich lief.
        dataFlow.log(
            integrationID: "PROJECT_NUMBER_LOCAL_BINDING", actorUserID: actorUserID,
            action: .success, recordsWritten: 1,
            summary: "Lokale Bindung bestätigt: \(candidate.businessProjektname) → \(candidate.projectNumber)")
    }

    /// mykilOS 8, Block A: spiegelt einen FEHLGESCHLAGENEN Airtable-Write — die
    /// Backup-Base-Doku verlangt ausdrücklich „auch fehlgeschlagene Versuche".
    /// Härtung (2026-07-01, Audit): optionales `integrationID` — loggt den Fehlschlag
    /// zusätzlich in die Schaltzentrale (bisher nur bei manchen Aufrufern separat gemacht,
    /// beim Kunde-/Projekt-Anlegen-Pfad KOMPLETT gefehlt). `nil` für Aufrufer, die ihr
    /// eigenes dataFlow.log daneben schon selbst setzen (kein Doppel-Log).
    private func recordWriteShadowFailure(
        table: String, baseID: String, fields: [String: AirtableFieldValue], errorMessage: String,
        integrationID: String? = nil
    ) {
        try? writeShadow.recordAirtableWrite(
            action: .create, actorUserID: actorUserID, baseID: baseID, table: table,
            recordID: nil, fields: fields, mode: provisioningMode.mode,
            result: .error, errorMessage: errorMessage)
        if let integrationID {
            dataFlow.log(integrationID: integrationID, actorUserID: actorUserID,
                         action: .error, errorMessage: errorMessage,
                         summary: "Airtable-Write fehlgeschlagen (\(table))")
        }
    }

    // MARK: - Clockodo-Adapter-Sync (Multi-Base-Architektur v2, 2026-07-01)
    // Spiegelt frisch lokal bestätigte Timer-Buchungen (TimerStore.confirmBooking hat
    // bereits die "Karte→Bestätigung" durchlaufen) als "Vorgebucht"-Zeilen in die neue
    // Airtable-Base mykilOS-Adapter Clockodo. Best-effort: die lokale GRDB-Buchung ist
    // bereits vollständig und bleibt in jedem Fall gültig — dieser Sync läuft im
    // Hintergrund und blockiert/wirft NIE zur UI hin (kein Datenverlust bei Offline/
    // Airtable-nicht-verbunden, nur ein sichtbarer Fehler im Datenstrom-Log).
    public func synchronisiereZeitbuchungenZuClockodoAdapter(_ segments: [TimeSegment]) {
        guard airtableAuth.status == .connected, segments.isEmpty == false else { return }
        let vollname = profile.profile?.displayName ?? ""
        let mitarbeiter = vollname.split(separator: " ").first.map(String.init) ?? vollname
        guard mitarbeiter.isEmpty == false else { return }
        let writer = ClockodoAdapterWriter(creator: AirtableClient())
        let uid = actorUserID
        let mode = provisioningMode.mode
        Task {
            for segment in segments {
                let fields = ClockodoAdapterWriter.felder(fuer: segment, mitarbeiter: mitarbeiter)
                do {
                    let recordID = try await writer.schreibeVorbuchung(segment, mitarbeiter: mitarbeiter)
                    try? writeShadow.recordAirtableWrite(
                        action: .create, actorUserID: uid, baseID: ClockodoAdapterWriter.baseID,
                        table: ClockodoAdapterWriter.table, recordID: recordID, fields: fields,
                        mode: mode, result: .ok)
                    dataFlow.log(integrationID: "AIRTABLE_CLOCKODO_ADAPTER_ZEITBUCHUNG", actorUserID: uid,
                                 action: .success, recordsWritten: 1,
                                 summary: "Zeitbuchung gespiegelt: \(segment.projektTitel) · \(segment.kostenstelle)")
                } catch {
                    try? writeShadow.recordAirtableWrite(
                        action: .create, actorUserID: uid, baseID: ClockodoAdapterWriter.baseID,
                        table: ClockodoAdapterWriter.table, recordID: nil, fields: fields,
                        mode: mode, result: .error, errorMessage: String(describing: error))
                    dataFlow.log(integrationID: "AIRTABLE_CLOCKODO_ADAPTER_ZEITBUCHUNG", actorUserID: uid,
                                 action: .error, errorMessage: String(describing: error),
                                 summary: "Zeitbuchung-Sync fehlgeschlagen (lokale Buchung bleibt gültig)")
                }
            }
        }
    }

    // MARK: - Backup (Mandate G)
    // Erzwungener WAL-Checkpoint + konsistentes Backup, off-main ausgeführt.
    // Lokal, read-only auf die DB — kein externer Schreibzugriff.
    public func createBackup(tag: String = "manual") async {
        backupState = .saving
        let db = database
        let appSupportDir = AppDatabase.productionURL.deletingLastPathComponent()
        let version = AppIdentity.version
        let commit = AppIdentity.gitCommit
        do {
            let url = try await Task.detached(priority: .utility) {
                let service = BackupService(appSupportDir: appSupportDir)
                let folder = try service.createConsistentBackup(
                    db: db, tag: tag, appVersion: version, gitCommit: commit)
                try? service.pruneOldBackups(olderThanDays: 30)   // Zeit-Retention
                try? service.pruneToCount(keepNewest: 30)         // Anzahl-Retention (max. 30)
                return folder
            }.value
            backupState = .saved(Date())
            MykLog.backup.notice("Backup erstellt (\(tag, privacy: .public)): \(url.lastPathComponent, privacy: .public)")
        } catch {
            backupState = .failed(String(describing: error))
            MykLog.backup.error("Backup fehlgeschlagen: \(String(describing: error), privacy: .public)")
        }
    }

    /// Auto-Backup beim App-Start: legt höchstens 1×/Tag automatisch einen Snapshot an,
    /// damit ein Sicherungsstand existiert, ohne dass der Nutzer „Backup jetzt" klicken muss.
    /// Best-effort, off-main, blockiert den Start nicht.
    public func autoBackupIfDue() async {
        let appSupportDir = AppDatabase.productionURL.deletingLastPathComponent()
        let due: Bool = await Task.detached(priority: .utility) {
            let service = BackupService(appSupportDir: appSupportDir)
            guard let last = service.latestBackupDate() else { return true }
            return Date().timeIntervalSince(last) > 20 * 3600
        }.value
        if due { await createBackup(tag: "auto") }
    }

    /// Vorhandene Backups (neueste zuerst) für die Restore-Liste in den Einstellungen.
    public func listBackups() -> [BackupService.BackupInfo] {
        BackupService(appSupportDir: AppDatabase.productionURL.deletingLastPathComponent()).listBackups()
    }

    /// Merkt ein ausgewähltes Backup zur Wiederherstellung vor. Angewandt wird es beim
    /// NÄCHSTEN Start (bevor die DB geöffnet ist) — sicher, weil kein offenes Handle.
    public func stageRestore(_ info: BackupService.BackupInfo) {
        AppDatabase.stageRestore(from: info.folderURL)
    }
}
