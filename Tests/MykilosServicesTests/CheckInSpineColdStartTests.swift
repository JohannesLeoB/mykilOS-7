import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// MARK: - CheckInSpineColdStartTests
// ECHTE datei-basierte Cold-Start-Tests für die CheckIn-Naht (nicht inMemory):
// GRDBDatabase(url:) auf einer temporären Datei anlegen → schreiben → NEUE
// GRDBDatabase(url:) + NEUER AuditStore auf DERSELBEN Datei → lesen → identisch.
// Beweist, dass der Spine-Audit-Pfad + die neuen Felder quelle/idempotenzKey einen
// echten Prozess-Neustart überleben, inklusive der v23-Migration + PARTIAL UNIQUE INDEX.
@MainActor
struct CheckInSpineColdStartTests {

    /// Fake-Adapter ohne Netz — schreibt nichts selbst, liefert nur Roh-Ergebnis + Kanal.
    private final class FakeAdapter: CheckInAdapter, @unchecked Sendable {
        let id = PortID("cash")
        let name = "Fake Cash"
        let key: String
        init(key: String) { self.key = key }
        func erlaubteInhaltsArten() -> Set<InhaltsArt> { [.artikel] }
        func idempotenzSchluessel(_ g: CheckInGegenstand, _ a: CheckInAbsicht) -> String { key }
        func vorschau(_ g: CheckInGegenstand, _ a: CheckInAbsicht) async throws -> CheckInVorschau {
            CheckInVorschau(
                vorschau: CheckoutPreview(zusammenfassung: "v"),
                idempotenzSchluessel: key,
                istDuplikat: false
            )
        }
        func fuehreAus(_ g: CheckInGegenstand, _ a: CheckInAbsicht) async throws -> CheckInAusfuehrung {
            CheckInAusfuehrung(
                ergebnis: CheckoutResult(erfolg: true, referenz: "ref"),
                kanal: .angebotImportiert,
                summaryDetail: nil
            )
        }
    }

    private func gegenstand() -> CheckInGegenstand {
        WorkBasket(id: WorkBasketID("WK-2026-015-0001"), projektNummer: "2026-015", inhaltsArt: .artikel)
    }

    private func absicht() -> CheckInAbsicht {
        CheckInAbsicht(
            adapterID: PortID("cash"),
            ziel: PortZiel(kind: "postbox"),
            begruendung: "Angebot in Review",
            actorUserID: "johannes@example.com",
            projektNummer: "2026-015",
            quelle: "drive-offer"
        )
    }

    /// Temporäre Datei-URL, die nach dem Test wieder verschwindet.
    private func tempDBURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("checkin-coldstart-\(UUID().uuidString).sqlite")
    }

    private func aufraeumen(_ url: URL) {
        let fm = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            try? fm.removeItem(at: URL(fileURLWithPath: url.path + suffix))
        }
    }

    // MARK: - 1. CheckIn-Audit überlebt echten Datei-Neustart

    @Test func checkInAuditUeberlebtNeustart() async throws {
        let url = tempDBURL()
        defer { aufraeumen(url) }

        // Ganzzahliger Sekunden-Timestamp umgeht die Double-Rundung über den Roundtrip.
        let stampSeconds: TimeInterval = 1_806_086_400

        // Session A: echte Datei-DB, Spine schreibt via AuditStoreCheckInSink.
        do {
            let dbA = try GRDBDatabase(url: url)
            let storeA = AuditStore(db: dbA)
            try storeA.load()
            let sink = AuditStoreCheckInSink(store: storeA)
            let spine = CheckInSpine(
                adapter: [FakeAdapter(key: "IDEMP-cash-001")],
                rechte: AllowAllPortRights(alleBekanntenPorts: [PortID("cash")]),
                audit: sink
            )
            let quittung = try await spine.bestaetigen(gegenstand(), absicht())
            #expect(quittung.audit.idempotenzKey == "IDEMP-cash-001")
            // Überschreibe timestamp bewusst NICHT — wir prüfen unten die geschriebenen Felder
            // gegen die frisch geladene Instanz (Roundtrip), nicht gegen einen fixen Wert.
            _ = stampSeconds
        }

        // "App neu gestartet": NEUE GRDBDatabase(url:) auf DERSELBEN Datei.
        let dbB = try GRDBDatabase(url: url)
        let storeB = AuditStore(db: dbB)
        try storeB.load()

        #expect(storeB.entries.count == 1)
        let e = storeB.entries[0]
        #expect(e.actorUserID == "johannes@example.com")
        #expect(e.projectID == "2026-015")
        #expect(e.action == .offerImported)
        #expect(e.quelle == "drive-offer")
        #expect(e.idempotenzKey == "IDEMP-cash-001")
        #expect(e.summary == "Angebot in Review")
    }

    // MARK: - 2. Idempotenz über ZWEI Instanzen: gleicher Key → genau EIN Record

    @Test func checkInIdempotentUeberZweiInstanzen() async throws {
        let url = tempDBURL()
        defer { aufraeumen(url) }

        // Instanz A: erster Check-in mit Key K.
        do {
            let dbA = try GRDBDatabase(url: url)
            let storeA = AuditStore(db: dbA)
            try storeA.load()
            let spine = CheckInSpine(
                adapter: [FakeAdapter(key: "K-DEDUP")],
                rechte: AllowAllPortRights(alleBekanntenPorts: [PortID("cash")]),
                audit: AuditStoreCheckInSink(store: storeA)
            )
            _ = try await spine.bestaetigen(gegenstand(), absicht())
            #expect(storeA.entries.count == 1)
        }

        // Instanz B (Neustart): erneuter Check-in mit GLEICHEM Key K.
        // Der Adapter erkennt hier kein Duplikat (Fake), aber der PARTIAL UNIQUE INDEX
        // auf idempotenzKey macht den zweiten Write HART unmöglich → append wirft.
        let dbB = try GRDBDatabase(url: url)
        let storeB = AuditStore(db: dbB)
        try storeB.load()
        #expect(storeB.entries.count == 1)   // der eine Record aus A ist da

        let spineB = CheckInSpine(
            adapter: [FakeAdapter(key: "K-DEDUP")],
            rechte: AllowAllPortRights(alleBekanntenPorts: [PortID("cash")]),
            audit: AuditStoreCheckInSink(store: storeB)
        )
        // Zweiter Write mit gleichem Key muss vom DB-Constraint abgewehrt werden.
        await #expect(throws: (any Error).self) {
            _ = try await spineB.bestaetigen(gegenstand(), absicht())
        }

        // Neustart C: es darf trotz zweitem Versuch nur EIN Record existieren.
        let dbC = try GRDBDatabase(url: url)
        let storeC = AuditStore(db: dbC)
        try storeC.load()
        #expect(storeC.entries.count == 1)
    }

    // MARK: - Offer-Review-Adapter (der erste migrierte Flow, CashWidget-Ersatz)

    /// Baut die Spine EXAKT wie AppState.checkInSpine (nativer OfferReviewCheckInAdapter
    /// + AuditStoreCheckInSink + AllowAllPortRights). Kein Netz, kein Keychain.
    private func offerSpine(_ store: AuditStore) -> CheckInSpine {
        CheckInSpine(
            adapter: [OfferReviewCheckInAdapter()],
            rechte: AllowAllPortRights(alleBekanntenPorts: [OfferReviewCheckInAdapter.portID]),
            audit: AuditStoreCheckInSink(store: store)
        )
    }

    /// Die Absicht wie AppState.checkInOffer sie baut — mit ECHTEM actorUserID
    /// (nicht dem hartkodierten "local-user") und quelle="drive-offer".
    private func offerAbsicht(projectID: String, label: String, actor: String) -> CheckInAbsicht {
        CheckInAbsicht(
            adapterID: OfferReviewCheckInAdapter.portID,
            ziel: PortZiel(kind: "review", parameter: ["angebotLabel": label]),
            begruendung: "Angebot in Review übernommen: \(label)",
            actorUserID: actor,
            projektNummer: projectID,
            quelle: "drive-offer"
        )
    }

    private func offerGegenstand(projectID: String) -> CheckInGegenstand {
        WorkBasket(id: WorkBasketID("offer-\(projectID)"), projektNummer: projectID, inhaltsArt: .dokumente)
    }

    /// Der VERHALTENSTEST, den es vor der Migration nicht gab (Kritiker-Auflage):
    /// „Angebot in Review" erzeugt GENAU EINEN AuditEntry(.offerImported) mit dem echten
    /// actorUserID (nicht 'local-user') + quelle='drive-offer'.
    @Test func offerCheckInErzeugtGenauEinenAuditMitEchtemActor() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = AuditStore(db: db)
        try store.load()

        let quittung = try await offerSpine(store).bestaetigen(
            offerGegenstand(projectID: "2026-015"),
            offerAbsicht(projectID: "2026-015", label: "Angebot Tischler Müller", actor: "johannes@example.com")
        )

        #expect(store.entries.count == 1)
        let e = store.entries[0]
        #expect(e.action == .offerImported)
        #expect(e.actorUserID == "johannes@example.com")   // NICHT "local-user"
        #expect(e.actorUserID != "local-user")
        #expect(e.projectID == "2026-015")
        #expect(e.quelle == "drive-offer")
        #expect(e.idempotenzKey?.isEmpty == false)
        #expect(quittung.audit.id == e.id)
    }

    /// Zweiter Import desselben Angebots (gleiches Projekt + Label) → gleicher
    /// deterministischer Key → der PARTIAL UNIQUE INDEX wehrt den zweiten Write ab.
    /// Beweist die harte Idempotenz des migrierten Flows über einen echten Neustart.
    @Test func offerCheckInIdempotentBeiGleichemAngebot() async throws {
        let url = tempDBURL()
        defer { aufraeumen(url) }

        do {
            let dbA = try GRDBDatabase(url: url)
            let storeA = AuditStore(db: dbA)
            try storeA.load()
            _ = try await offerSpine(storeA).bestaetigen(
                offerGegenstand(projectID: "2026-020"),
                offerAbsicht(projectID: "2026-020", label: "Angebot Stein", actor: "jo@x.de")
            )
            #expect(storeA.entries.count == 1)
        }

        // Neustart + gleiches Angebot erneut → zweiter Write muss geworfen werden.
        let dbB = try GRDBDatabase(url: url)
        let storeB = AuditStore(db: dbB)
        try storeB.load()
        await #expect(throws: (any Error).self) {
            _ = try await offerSpine(storeB).bestaetigen(
                offerGegenstand(projectID: "2026-020"),
                offerAbsicht(projectID: "2026-020", label: "Angebot Stein", actor: "jo@x.de")
            )
        }

        let dbC = try GRDBDatabase(url: url)
        let storeC = AuditStore(db: dbC)
        try storeC.load()
        #expect(storeC.entries.count == 1)   // trotz zweitem Versuch nur EINER
    }

    // MARK: - 3. Migration v23: alte Zeile ohne quelle/idempotenzKey liest als nil

    @Test func migrationV23AlteZeileLiestAlsNil() async throws {
        let url = tempDBURL()
        defer { aufraeumen(url) }

        // Ein normaler AuditEntry OHNE die neuen Felder (Default nil) — simuliert eine
        // Alt-Zeile, die über die volle Migration (inkl. v23) geschrieben/gelesen wird.
        let altEntry = AuditEntry(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            timestamp: Date(timeIntervalSince1970: 1_800_000_000),
            actorUserID: "local-user",
            projectID: "ME-24",
            action: .noteUpdated,
            summary: "Alt-Eintrag ohne CheckIn-Felder"
        )
        do {
            let dbA = try GRDBDatabase(url: url)
            let storeA = AuditStore(db: dbA)
            try storeA.load()
            try storeA.append(altEntry)
        }

        let dbB = try GRDBDatabase(url: url)
        let storeB = AuditStore(db: dbB)
        try storeB.load()
        #expect(storeB.entries.count == 1)
        let e = storeB.entries[0]
        #expect(e.id == altEntry.id)
        #expect(e.quelle == nil)          // alte Zeile → nil
        #expect(e.idempotenzKey == nil)   // alte Zeile → nil
        #expect(e.action == .noteUpdated)
    }
}
