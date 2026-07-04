import Testing
import Foundation
import GRDB
@testable import MykilosServices
@testable import MykilosKit

// MARK: - WorkBasketStore Cold-Start-Tests (Wirbelsäule, Welle C / C3)
// Beweist: WorkBaskets (Kopf + Picks) überleben den App-Neustart (GRDB-backed).
// S10-Blueprint §3/§9 — generisch über Pick/InhaltsArt, kein Artikel-only-Hardwiring.
@MainActor
struct WorkBasketStoreTests {

    // MARK: Test-Helfer

    private func machBasket(
        id: String = "WK-2026-015-0001",
        projekt: String = "2026-015",
        inhaltsArt: InhaltsArt = .gemischt,
        version: Int = 1,
        status: WorkBasketStatus = .kalkulation,
        erstellt: Date = Date()
    ) -> WorkBasket {
        let artikel = BasicPick(
            matrix: .artikel,
            objektID: CatalogObjectID("art-0001"),
            snapshot: PickSnapshot(bezeichnung: "Spüle Blanco", menge: 2, ekEinzel: 120.0, vkEinzel: 240.0, attribute: ["farbe": "anthrazit"]),
            inhalt: .text("Blanco Subline 500-U")
        )
        let bild = BasicPick(
            matrix: .bild,
            objektID: CatalogObjectID("img-1"),
            snapshot: PickSnapshot(bezeichnung: "Moodboard-Render"),
            inhalt: .bytes(Data([0x1, 0x2, 0x3]), mimeType: "image/png")
        )
        return WorkBasket(
            id: WorkBasketID(id),
            projektNummer: projekt,
            inhaltsArt: inhaltsArt,
            picks: [artikel, bild],
            version: version,
            status: status,
            erstellt: erstellt
        )
    }

    // MARK: PDF-Positions Teil 2 — Position anhängen (Cold-Start)

    @Test func fuegePositionHinzuLegtNeuenKorbAnUndUeberlebtNeustart() async throws {
        let db = try GRDBDatabase.inMemory()
        let storeA = WorkBasketStore(db: db)
        // Kein Korb vorhanden → neuer wird angelegt.
        let basket = try await storeA.fuegePositionHinzu(
            projektNummer: "2026-015", bezeichnung: "Küchenarbeitsplatte Granit",
            menge: 1, ekEinzel: 5911.70, vkEinzel: nil, objektID: "file1-p1-0")
        #expect(basket.picks.count == 1)

        // Neustart: neue Instanz, selbe DB
        let storeB = WorkBasketStore(db: db)
        let geladen = try storeB.alle(projektNummer: "2026-015")
        #expect(geladen.count == 1)
        #expect(geladen[0].picks.count == 1)
        #expect(geladen[0].picks[0].snapshot.bezeichnung == "Küchenarbeitsplatte Granit")
        #expect(geladen[0].picks[0].snapshot.ekEinzel == 5911.70)
    }

    @Test func fuegePositionHinzuIstIdempotentProObjektID() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = WorkBasketStore(db: db)
        try await store.fuegePositionHinzu(projektNummer: "2026-015", bezeichnung: "Platte",
                                           menge: 1, ekEinzel: 100, vkEinzel: nil, objektID: "f-p1-0")
        // Zweiter Klick auf DIESELBE Position → Menge erhöhen, kein Duplikat.
        try await store.fuegePositionHinzu(projektNummer: "2026-015", bezeichnung: "Platte",
                                           menge: 1, ekEinzel: 100, vkEinzel: nil, objektID: "f-p1-0")
        let korb = try store.alle(projektNummer: "2026-015").max(by: { $0.erstellt < $1.erstellt })
        #expect(korb?.picks.count == 1)
        #expect(korb?.picks.first?.snapshot.menge == 2)
    }

    @Test func fuegePositionHinzuHaengtAnBestehendenKorbAn() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = WorkBasketStore(db: db)
        try await store.speichere(machBasket(projekt: "2026-020"))   // 2 Picks
        try await store.fuegePositionHinzu(
            projektNummer: "2026-020", bezeichnung: "Griffleiste",
            menge: 5, ekEinzel: 12, vkEinzel: nil, objektID: "f-p2-3")
        let korb = try store.alle(projektNummer: "2026-020").max(by: { $0.erstellt < $1.erstellt })
        #expect(korb?.picks.count == 3)
        #expect(korb?.picks.last?.snapshot.menge == 5)
    }

    // MARK: 1. Kern: WorkBasket überlebt Neustart (Kopf + Picks)

    @Test func workBasketUeberlebtNeustart() async throws {
        let db = try GRDBDatabase.inMemory()
        let basket = machBasket()

        let storeA = WorkBasketStore(db: db)
        try await storeA.speichere(basket)
        if case .saved = storeA.saveState { } else {
            Issue.record("Erwarte .saved, war: \(storeA.saveState)")
        }

        // "App neu gestartet": neue Store-Instanz, selbe DB
        let storeB = WorkBasketStore(db: db)
        let geladen = try storeB.lade(id: basket.id)

        #expect(geladen != nil)
        #expect(geladen?.projektNummer == "2026-015")
        #expect(geladen?.inhaltsArt == .gemischt)
        #expect(geladen?.version == 1)
        #expect(geladen?.status == .kalkulation)
        #expect(geladen?.picks.count == 2)

        // Picks identisch (Reihenfolge + Inhalt) zurückgelesen
        let picks = geladen?.picks ?? []
        #expect(picks[0].matrix == .artikel)
        #expect(picks[0].objektID == CatalogObjectID("art-0001"))
        #expect(picks[0].snapshot.bezeichnung == "Spüle Blanco")
        #expect(picks[0].snapshot.attribute["farbe"] == "anthrazit")
        #expect(picks[1].matrix == .bild)
        #expect(picks[1].snapshot.bezeichnung == "Moodboard-Render")

        // resolve() liefert den ursprünglich gespeicherten, aufgelösten Inhalt zurück.
        let artikelInhalt = try await picks[0].resolve()
        #expect(artikelInhalt == .text("Blanco Subline 500-U"))
        let bildInhalt = try await picks[1].resolve()
        #expect(bildInhalt == .bytes(Data([0x1, 0x2, 0x3]), mimeType: "image/png"))
    }

    // MARK: 2. SaveState sichtbar

    @Test func saveStateWirdGesetzt() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = WorkBasketStore(db: db)
        #expect(store.saveState == .idle)
        try await store.speichere(machBasket())
        if case .saved = store.saveState { } else {
            Issue.record("SaveState sollte .saved sein, ist aber: \(store.saveState)")
        }
    }

    // MARK: 3. inhaltsArt persistiert korrekt für alle Fälle

    @Test func inhaltsArtPersistiertFuerAlleFaelle() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = WorkBasketStore(db: db)
        for (index, art) in InhaltsArt.allCases.enumerated() {
            let basket = machBasket(id: "WK-art-\(index)", inhaltsArt: art)
            try await store.speichere(basket)
            let geladen = try store.lade(id: basket.id)
            #expect(geladen?.inhaltsArt == art, "InhaltsArt \(art) sollte identisch zurückkommen")
        }
    }

    // MARK: 4. Lebenszyklus-Status (§7) inkl. Eltern-ID persistiert

    @Test func statusMitElternIDPersistiertKorrekt() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = WorkBasketStore(db: db)
        let elternID = WorkBasketID("WK-2026-015-0001")

        let nachtrag = machBasket(id: "WK-2026-015-0002", status: .nachtrag(zu: elternID))
        try await store.speichere(nachtrag)
        let geladenerNachtrag = try store.lade(id: nachtrag.id)
        #expect(geladenerNachtrag?.status == .nachtrag(zu: elternID))
        #expect(geladenerNachtrag?.status.istEingefroren == true)

        let gutschrift = machBasket(id: "WK-2026-015-0003", status: .gutschrift(zu: elternID))
        try await store.speichere(gutschrift)
        let geladeneGutschrift = try store.lade(id: gutschrift.id)
        #expect(geladeneGutschrift?.status == .gutschrift(zu: elternID))

        // Neustart — Eltern-ID bleibt exakt erhalten.
        let storeB = WorkBasketStore(db: db)
        let neuGeladen = try storeB.lade(id: nachtrag.id)
        #expect(neuGeladen?.status == .nachtrag(zu: elternID))
    }

    // MARK: 5. Statusübergang nutzt die C1-State-Machine (§7) — kein Rückweg aus dem Freeze

    @Test func statusWechselNutztC1UebergangsregelUndVerbietetRueckweg() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = WorkBasketStore(db: db)
        let basket = machBasket(status: .kalkulation)
        try await store.speichere(basket)

        // Erlaubt: kalkulation → bestaetigt
        let bestaetigt = try await store.wechsleStatus(basketID: basket.id, zu: .bestaetigt)
        #expect(bestaetigt.status == .bestaetigt)

        // Verboten: bestaetigt → kalkulation (Rückweg aus dem Freeze)
        do {
            _ = try await store.wechsleStatus(basketID: basket.id, zu: .kalkulation)
            Issue.record("Rückweg aus bestaetigt sollte werfen")
        } catch let error as WorkBasketStoreError {
            #expect(error == .unerlaubterUebergang)
        }

        // Nach dem gescheiterten Versuch bleibt der persistierte Stand unverändert (bestaetigt).
        let geladen = try store.lade(id: basket.id)
        #expect(geladen?.status == .bestaetigt)
    }

    // MARK: 6. Projekt-Zuordnung: Filter über alle()

    @Test func alleFiltertNachProjekt() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = WorkBasketStore(db: db)
        try await store.speichere(machBasket(id: "WK-A", projekt: "2026-015"))
        try await store.speichere(machBasket(id: "WK-B", projekt: "2026-015"))
        try await store.speichere(machBasket(id: "WK-C", projekt: "2026-099"))

        let fuer015 = try store.alle(projektNummer: "2026-015")
        #expect(fuer015.count == 2)
        #expect(fuer015.allSatisfy { $0.projektNummer == "2026-015" })

        let alle = try store.alle()
        #expect(alle.count == 3)
    }

    // MARK: 7. Neuschreiben (gleiche ID) überschreibt Picks statt sie zu duplizieren

    @Test func erneutesSpeichernErsetztPicksStattZuDuplizieren() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = WorkBasketStore(db: db)
        var basket = machBasket()
        try await store.speichere(basket)

        // Version erhöhen, Picks reduzieren — simuliert eine App-seitige Änderung.
        basket.version = 2
        basket.picks = [basket.picks[0]]
        try await store.speichere(basket)

        let geladen = try store.lade(id: basket.id)
        #expect(geladen?.version == 2)
        #expect(geladen?.picks.count == 1)
    }
}

// MARK: - WorkBasket Sortieren/Filtern (reine Funktionen, MykilosKit — C3 §9)
struct WorkBasketSortierenFilternTests {

    private func basket(id: String, projekt: String, art: InhaltsArt, version: Int, erstellt: Date) -> WorkBasket {
        WorkBasket(id: WorkBasketID(id), projektNummer: projekt, inhaltsArt: art, version: version, erstellt: erstellt)
    }

    @Test func sortiertNachErstelltAbsteigend() {
        let alt = basket(id: "WK-1", projekt: "2026-015", art: .artikel, version: 1, erstellt: Date(timeIntervalSince1970: 100))
        let neu = basket(id: "WK-2", projekt: "2026-015", art: .artikel, version: 1, erstellt: Date(timeIntervalSince1970: 200))
        let sortiert = [alt, neu].sortiert(nach: .erstelltAbsteigend)
        #expect(sortiert.map(\.id.raw) == ["WK-2", "WK-1"])
    }

    @Test func sortiertNachVersionAbsteigend() {
        let v1 = basket(id: "WK-1", projekt: "2026-015", art: .artikel, version: 1, erstellt: Date())
        let v3 = basket(id: "WK-2", projekt: "2026-015", art: .artikel, version: 3, erstellt: Date())
        let sortiert = [v1, v3].sortiert(nach: .versionAbsteigend)
        #expect(sortiert.map(\.version) == [3, 1])
    }

    @Test func filtertNachInhaltsArt() {
        let baskets = [
            basket(id: "WK-1", projekt: "2026-015", art: .artikel, version: 1, erstellt: Date()),
            basket(id: "WK-2", projekt: "2026-015", art: .bilder, version: 1, erstellt: Date()),
        ]
        let nurBilder = baskets.gefiltert(nachInhaltsArt: .bilder)
        #expect(nurBilder.count == 1)
        #expect(nurBilder.first?.id.raw == "WK-2")

        // nil = keine Einschränkung
        #expect(baskets.gefiltert(nachInhaltsArt: nil).count == 2)
    }

    @Test func filtertNachProjekt() {
        let baskets = [
            basket(id: "WK-1", projekt: "2026-015", art: .artikel, version: 1, erstellt: Date()),
            basket(id: "WK-2", projekt: "2026-099", art: .artikel, version: 1, erstellt: Date()),
        ]
        let nur015 = baskets.gefiltert(nachProjekt: "2026-015")
        #expect(nur015.count == 1)
        #expect(nur015.first?.id.raw == "WK-1")
    }

    @Test func filtertNachStatusFallIgnoriertElternID() {
        let eltern1 = WorkBasketID("WK-eltern-1")
        let eltern2 = WorkBasketID("WK-eltern-2")
        var b1 = basket(id: "WK-1", projekt: "2026-015", art: .artikel, version: 1, erstellt: Date())
        b1.status = .nachtrag(zu: eltern1)
        var b2 = basket(id: "WK-2", projekt: "2026-015", art: .artikel, version: 1, erstellt: Date())
        b2.status = .nachtrag(zu: eltern2)
        var b3 = basket(id: "WK-3", projekt: "2026-015", art: .artikel, version: 1, erstellt: Date())
        b3.status = .bestaetigt

        // Filter nach "irgendein Nachtrag" (Eltern-ID des Wunsch-Werts ist irrelevant).
        let nachtraege = [b1, b2, b3].gefiltert(nachStatusFall: .nachtrag(zu: eltern1))
        #expect(nachtraege.count == 2)
        #expect(Set(nachtraege.map(\.id.raw)) == ["WK-1", "WK-2"])
    }

    @Test func picksSortiertNachBezeichnungUndGefiltertNachMatrix() {
        let picks: [any Pick] = [
            BasicPick(matrix: .bild, objektID: CatalogObjectID("b"), snapshot: PickSnapshot(bezeichnung: "Zebra")),
            BasicPick(matrix: .artikel, objektID: CatalogObjectID("a"), snapshot: PickSnapshot(bezeichnung: "Anker")),
        ]
        let sortiert = picks.sortiertNachBezeichnung()
        #expect(sortiert.map(\.snapshot.bezeichnung) == ["Anker", "Zebra"])

        let nurArtikel = picks.gefiltert(nachMatrix: .artikel)
        #expect(nurArtikel.count == 1)
        #expect(nurArtikel.first?.matrix == .artikel)
    }
}

// MARK: - v21_workbasket gegen eine ALTE Bestands-DB (V10-Plan, Phase 1, Block C, Risiko #1)
//
// Der Plan benennt das reale Risiko präzise: die Migration `v21_workbasket` läuft längst bei
// jedem App-Start (GRDBDatabase.runMigrations() hängt sie unbedingt an) — tot war nur der
// Swift-Store, nicht das DDL. Das Cold-Start-Gate hier beweist deshalb NICHT "Migration
// zündet zum ersten Mal", sondern: eine Datenbank, die schon bis v20 gewachsen ist (reale
// Bestandsdaten in älteren Tabellen), verträgt den v21-Anhang klaglos UND der WorkBasketStore
// kann direkt danach schreiben/lesen — kein Bruch beim Übergang alt→neu.
@MainActor
struct WorkBasketMigrationGateTests {

    /// Öffnet eine Datei-DB, migriert sie NUR bis v20 (mit `GRDBDatabase.buildMigrator()` —
    /// derselbe Migrator wie im Produktivpfad, nur an einem älteren Punkt gestoppt), schreibt
    /// eine reale Zeile in eine v20-Tabelle hinein (Beleg: "das ist eine echte alte Bestands-DB,
    /// kein leeres Schema"), und gibt den Dateipfad zurück.
    private func macheAlteBestandsDB() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("workbasket-migration-gate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let dbURL = dir.appendingPathComponent("alt.sqlite")

        let queue = try DatabaseQueue(path: dbURL.path)
        let migrator = GRDBDatabase.buildMigrator()
        // Stoppt exakt VOR v21 — die DB kennt noch keine workBaskets/workBasketPicks-Tabellen,
        // hat aber jede frühere Migration (inkl. v20_project_lifecycle_stage) bereits gefahren.
        try migrator.migrate(queue, upTo: "v20_project_lifecycle_stage")

        // Reale Bestandsdaten in einer v20-Tabelle — kein leeres, frisch migriertes Schema.
        try queue.write { db in
            try db.execute(
                sql: """
                INSERT INTO projectLifecycleStage (projectNumber, stageIndex, setAt)
                VALUES (?, ?, ?)
                """,
                arguments: ["2026-015", 2, Date().timeIntervalSince1970]
            )
        }

        // workBaskets/workBasketPicks existieren zu diesem Zeitpunkt nachweislich noch nicht.
        let tabellenVorher = try queue.read { db in
            try Bool.fetchOne(db, sql: """
                SELECT EXISTS (
                    SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'workBaskets'
                )
                """) ?? false
        }
        #expect(tabellenVorher == false, "Testaufbau ungültig: workBaskets sollte vor v21 nicht existieren")

        return dbURL
    }

    @Test func v21LaeuftGegenAlteBestandsDBUndStoreSchreibtLiestDanachSofort() async throws {
        let dbURL = try macheAlteBestandsDB()

        // Der ECHTE Produktivpfad: GRDBDatabase(url:) fährt runMigrations() unbedingt,
        // also auch v21_workbasket — auf einer Datei, die schon reale v20-Daten trägt.
        let db = try GRDBDatabase(url: dbURL)

        // Alte Bestandsdaten bleiben unangetastet.
        let stufe = try db.read { conn in
            try Int.fetchOne(conn, sql: "SELECT stageIndex FROM projectLifecycleStage WHERE projectNumber = ?",
                              arguments: ["2026-015"])
        }
        #expect(stufe == 2)

        // Und der WorkBasketStore funktioniert direkt danach — kein Sonderfall für
        // "DB kam gerade erst von v20 auf v21".
        let store = WorkBasketStore(db: db)
        let basket = WorkBasket(
            id: WorkBasketID("WK-2026-015-migrationsgate"),
            projektNummer: "2026-015",
            inhaltsArt: .artikel,
            picks: [
                BasicPick(
                    matrix: .artikel,
                    objektID: CatalogObjectID("art-migrationsgate"),
                    snapshot: PickSnapshot(bezeichnung: "Testposition", menge: 1, ekEinzel: 10, vkEinzel: 20),
                    inhalt: .text("Testinhalt")
                )
            ],
            status: .kalkulation
        )
        try await store.speichere(basket)

        let geladen = try store.lade(id: basket.id)
        #expect(geladen != nil)
        #expect(geladen?.projektNummer == "2026-015")
        #expect(geladen?.picks.count == 1)
        #expect(geladen?.picks.first?.snapshot.bezeichnung == "Testposition")
    }
}

// MARK: - Warenkorb→WorkBasket-Bridge, Cold-Start (V10-Plan, Phase 1, Block D)
// Beweist: ein per `WarenkorbWorkBasketBridge` gemappter Intake-Warenkorb überlebt den
// App-Neustart über denselben `WorkBasketStore` wie jeder andere WorkBasket — kein
// Sonderfall für den Bridge-Pfad.
@MainActor
struct WarenkorbWorkBasketBridgeColdStartTests {

    @Test func gemappterSchneiderWarenkorbUeberlebtNeustart() async throws {
        let db = try GRDBDatabase.inMemory()

        let schneiderPositionen = [
            WarenkorbItem(
                artikelRecordID: "recSpuele01",
                bezeichnung: "Spüle Schock Typos D-150S",
                artikelnummer: "SCH-TYPOS-D150S",
                menge: 1, ekNetto: 380.0, vkNetto: 620.0, quelle: "katalog"),
            WarenkorbItem(
                bezeichnung: "Elektroanschluss Herd + Spüle",
                artikelnummer: "MONT-ELEK-01",
                menge: 1, ekNetto: nil, vkNetto: 180.0, quelle: "manuell"),
        ]
        let warenkorb = Warenkorb(items: schneiderPositionen, projektRecordID: "recSchneider", projektName: "Küche Schneider")
        let basket = WarenkorbWorkBasketBridge.workBasket(
            aus: warenkorb, projektNummer: "2026-015", id: WorkBasketID("WK-2026-015-schneider-coldstart"))

        let storeA = WorkBasketStore(db: db)
        try await storeA.speichere(basket)

        // "App neu gestartet": neue Store-Instanz, selbe DB.
        let storeB = WorkBasketStore(db: db)
        let geladen = try storeB.lade(id: basket.id)

        #expect(geladen != nil)
        #expect(geladen?.projektNummer == "2026-015")
        #expect(geladen?.status == .kalkulation)
        #expect(geladen?.picks.count == 2)
        #expect(geladen?.picks.first?.snapshot.bezeichnung == "Spüle Schock Typos D-150S")
        #expect(geladen?.picks.first?.snapshot.ekEinzel == 380.0)
        #expect(geladen?.picks.first?.snapshot.vkEinzel == 620.0)

        // Auch über `alle(projektNummer:)` auffindbar (der Pfad, den Block E im Projekt nutzt).
        let alleFuerProjekt = try storeB.alle(projektNummer: "2026-015")
        #expect(alleFuerProjekt.count == 1)
        #expect(alleFuerProjekt.first?.id == basket.id)
    }
}
