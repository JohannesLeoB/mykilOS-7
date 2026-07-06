import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// Block C / S2: die GRDB-gestützten Nomenklatur-Services (NumberAuthority, NomenklaturStore)
// + die vollen Identitäts-Lookups der ExternalMappingRegistry.
// @MainActor, weil NomenklaturStore main-actor-isoliert ist (wie TimerStoreTests).
@MainActor
struct NomenklaturServiceTests {

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("myk6-nomen-\(UUID().uuidString)", isDirectory: true)
    }

    // MARK: NumberAuthority

    @Test func authorityNextIstMaxPlusEinsUeberAktivUndArchiv() async throws {
        let db = try GRDBDatabase.inMemory()
        // Aktive Nummern (aus Registry): bis 029. Archiv: 050 (höher!) → nächste muss 051 sein.
        let aktive: [Projektnummer] = (1...29).map { Projektnummer(jahr: 2026, laufendeNummer: $0) }
        let authority = LocalSequentialAuthority(db: db, aktiveNummern: { aktive })
        try authority.archiviere(Projektnummer(jahr: 2026, laufendeNummer: 50))

        let next = try await authority.nextProjektnummer(jahr: 2026)
        #expect(next.appFormat == "2026-051")   // max(aktiv 29, archiv 50) + 1
    }

    @Test func authorityReserveVerhindertWiedervergabe() async throws {
        let db = try GRDBDatabase.inMemory()
        let authority = LocalSequentialAuthority(db: db, aktiveNummern: { [] })
        let nr = try await authority.nextProjektnummer(jahr: 2026)   // 2026-001
        try await authority.reserve(nr)
        #expect(try await authority.isVergeben(nr) == true)
        // Nächste überspringt die reservierte.
        let next = try await authority.nextProjektnummer(jahr: 2026)
        #expect(next.appFormat == "2026-002")
        // Doppelt reservieren wirft.
        await #expect(throws: NumberAuthorityError.self) { try await authority.reserve(nr) }
    }

    @Test func authorityArchivUeberlebtNeustart() async throws {
        let dir = tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("db.sqlite")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let dbA = try GRDBDatabase(url: url)
        let authA = LocalSequentialAuthority(db: dbA, aktiveNummern: { [] })
        try authA.archiviere(Projektnummer(jahr: 2026, laufendeNummer: 7))

        let dbB = try GRDBDatabase(url: url)
        let authB = LocalSequentialAuthority(db: dbB, aktiveNummern: { [] })
        #expect(try await authB.isVergeben(Projektnummer(jahr: 2026, laufendeNummer: 7)) == true)
    }

    @Test func authorityBindFromExternalSetztExterneNummer() async throws {
        let db = try GRDBDatabase.inMemory()
        let authority = LocalSequentialAuthority(db: db, aktiveNummern: { [] })
        try await authority.bindFromExternal(quelle: "sevdesk", nummer: Projektnummer(jahr: 2026, laufendeNummer: 99))
        #expect(try await authority.isVergeben(Projektnummer(jahr: 2026, laufendeNummer: 99)) == true)
    }

    @Test func nextAndReserveIstAtomarKeineDoppelvergabe() async throws {
        // Review-Fix: nextAndReserve reserviert in einer Transaktion → zwei (auch
        // gleichzeitige) Aufrufe ziehen NIE dieselbe Nummer.
        let db = try GRDBDatabase.inMemory()
        let authority = LocalSequentialAuthority(db: db, aktiveNummern: { [] })
        async let a = authority.nextAndReserve(jahr: 2026)
        async let b = authority.nextAndReserve(jahr: 2026)
        let (n1, n2) = try await (a, b)
        #expect(n1 != n2)   // verschiedene Nummern, keine Kollision
        #expect(Set([n1.appFormat, n2.appFormat]) == ["2026-001", "2026-002"])
    }

    // MARK: nextAndReserveKollisionsfrei (Härtung 2026-07-01, echte Live-Kollision entdeckt:
    // zwei Fragebogen-Läufe vergaben 2026-027/028, obwohl diese Nummern bereits als manuell
    // angelegte Drive-Ordner existierten — die Registry kannte sie nie.)

    @Test func kollisionsfreieVergabeUeberspringtExternBelegteNummer() async throws {
        let db = try GRDBDatabase.inMemory()
        let authority = LocalSequentialAuthority(db: db, aktiveNummern: { [] })
        // Registry weiß nichts von "2026-001" — aber ein externer Check (z. B. echter
        // Drive-Ordner) sagt: die ist schon belegt. Die Schleife muss zu 002 weiterziehen.
        let nummer = try await authority.nextAndReserveKollisionsfrei(jahr: 2026) { kandidat in
            kandidat.appFormat == "2026-001"
        }
        #expect(nummer.appFormat == "2026-002")
    }

    @Test func kollisionsfreieVergabeGibtNieEineKollidierendeNummerZurueck() async throws {
        let db = try GRDBDatabase.inMemory()
        let authority = LocalSequentialAuthority(db: db, aktiveNummern: { [] })
        let belegt: Set<String> = ["2026-001", "2026-002", "2026-003"]
        let nummer = try await authority.nextAndReserveKollisionsfrei(jahr: 2026) { kandidat in
            belegt.contains(kandidat.appFormat)
        }
        #expect(belegt.contains(nummer.appFormat) == false)
        #expect(nummer.appFormat == "2026-004")
    }

    @Test func kollisionsfreieVergabeReserviertUebersprungeneNummernDauerhaft() async throws {
        // Eine als extern-kollidierend übersprungene Nummer bleibt trotzdem reserviert
        // (Projektnummern sind einmalig) — ein zweiter Aufruf darf sie nie erneut liefern.
        let db = try GRDBDatabase.inMemory()
        let authority = LocalSequentialAuthority(db: db, aktiveNummern: { [] })
        _ = try await authority.nextAndReserveKollisionsfrei(jahr: 2026) { $0.appFormat == "2026-001" }
        #expect(try await authority.isVergeben(Projektnummer(jahr: 2026, laufendeNummer: 1)) == true)
    }

    @Test func kollisionsfreieVergabeWirftNachMaxVersuchen() async throws {
        let db = try GRDBDatabase.inMemory()
        let authority = LocalSequentialAuthority(db: db, aktiveNummern: { [] })
        await #expect(throws: NumberAuthorityError.self) {
            _ = try await authority.nextAndReserveKollisionsfrei(jahr: 2026, istExternKollidiert: { _ in true }, maxVersuche: 5)
        }
    }

    @Test func kollisionsfreieVergabeOhneKollisionVerhaeltSichWieNextAndReserve() async throws {
        let db = try GRDBDatabase.inMemory()
        let authority = LocalSequentialAuthority(db: db, aktiveNummern: { [] })
        let nummer = try await authority.nextAndReserveKollisionsfrei(jahr: 2026) { _ in false }
        #expect(nummer.appFormat == "2026-001")
    }

    // MARK: nextProjektnummerKollisionsfrei (reine Vorschau, reserviert nicht)

    @Test func vorschauUeberspringtKollisionOhneZuReservieren() async throws {
        let db = try GRDBDatabase.inMemory()
        let authority = LocalSequentialAuthority(db: db, aktiveNummern: { [] })
        let vorschau = try await authority.nextProjektnummerKollisionsfrei(jahr: 2026) { $0.appFormat == "2026-001" }
        #expect(vorschau.appFormat == "2026-002")
        // Reserviert wirklich NICHTS — die "übersprungene" 001 bleibt frei für die echte Vergabe.
        #expect(try await authority.isVergeben(Projektnummer(jahr: 2026, laufendeNummer: 1)) == false)
    }

    @Test func vorschauZeigtDieselbeNummerWieDieEchteKollisionsfreieVergabe() async throws {
        // Die UI-Vorschau muss exakt das zeigen, was die echte Anlage danach auch vergibt —
        // sonst wäre die Vorschau irreführend.
        let db = try GRDBDatabase.inMemory()
        let authority = LocalSequentialAuthority(db: db, aktiveNummern: { [] })
        let istKollidiert: (Projektnummer) -> Bool = { $0.appFormat == "2026-001" || $0.appFormat == "2026-002" }
        let vorschau = try await authority.nextProjektnummerKollisionsfrei(jahr: 2026, istExternKollidiert: istKollidiert)
        let echt = try await authority.nextAndReserveKollisionsfrei(jahr: 2026, istExternKollidiert: istKollidiert)
        #expect(vorschau == echt)
    }

    @Test func archiviereUeberschreibtExterneNummerNicht() async throws {
        let db = try GRDBDatabase.inMemory()
        let authority = LocalSequentialAuthority(db: db, aktiveNummern: { [] })
        let nr = Projektnummer(jahr: 2026, laufendeNummer: 50)
        try await authority.bindFromExternal(quelle: "sevdesk", nummer: nr)
        try authority.archiviere(nr)   // darf die extern-Herkunft nicht still überschreiben
        #expect(try await authority.isVergeben(nr) == true)   // bleibt vergeben
    }

    // MARK: NomenklaturStore Cold-Start

    @Test func nomenklaturStoreSeedetKonnektorenUndUeberlebtNeustart() throws {
        let dir = tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("db.sqlite")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let dbA = try GRDBDatabase(url: url)
        let storeA = NomenklaturStore(db: dbA)
        try storeA.load()   // seedet v1-Defaults
        #expect(storeA.konnektor(.fragebogen)?.relativerPfad == "01 INFOS/07 Fragebogen")

        let dbB = try GRDBDatabase(url: url)
        let storeB = NomenklaturStore(db: dbB)
        try storeB.load()   // lädt gespeicherte (kein Re-Seed)
        #expect(storeB.konnektoren.count == OrdnerKonnektor.v1Defaults.count)
    }

    @Test func kostenstellenOverrideUeberlebtNeustart() throws {
        let dir = tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("db.sqlite")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let dbA = try GRDBDatabase(url: url)
        let storeA = NomenklaturStore(db: dbA)
        try storeA.load()
        try storeA.setzeKostenstellen(["Aufmaß", "Lieferung"], fuer: "2026-015")

        let dbB = try GRDBDatabase(url: url)
        let storeB = NomenklaturStore(db: dbB)
        try storeB.load()
        let ks = storeB.kostenstellen(fuer: "2026-015")
        #expect(ks.map(\.name) == ["Aufmaß", "Lieferung"])
        // Anderes Projekt → Default-Liste.
        #expect(storeB.kostenstellen(fuer: "2026-099") == Kostenstelle.defaults)
    }

    @Test func leereKostenstellenFallenAufDefaultsZurueck() throws {
        // Review-Fix: ein leerer Override darf den Timer nicht ohne Kostenstellen lassen.
        let db = try GRDBDatabase.inMemory()
        let store = NomenklaturStore(db: db)
        try store.load()
        try store.setzeKostenstellen([], fuer: "2026-015")            // leer = kein Override
        #expect(store.kostenstellen(fuer: "2026-015") == Kostenstelle.defaults)
        try store.setzeKostenstellen(["  ", ""], fuer: "2026-016")    // nur Whitespace = kein Override
        #expect(store.kostenstellen(fuer: "2026-016") == Kostenstelle.defaults)
    }

    @Test func partielleKonnektorenWerdenBeimLadenErgaenzt() throws {
        let dir = tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("db.sqlite")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let dbA = try GRDBDatabase(url: url)
        let storeA = NomenklaturStore(db: dbA)
        try storeA.load()   // seedet alle 6
        // Einen Slot simuliert-entfernen, dann neu laden → muss ergänzt werden.
        try dbA.write { _ = try $0.execute(sql: "DELETE FROM ordnerKonnektoren WHERE slot = 'cad'") }
        let storeB = NomenklaturStore(db: dbA)
        try storeB.load()
        #expect(storeB.konnektor(.cad) != nil)   // fehlender Slot wurde ergänzt
        #expect(storeB.konnektoren.count == OrdnerKonnektor.v1Defaults.count)
    }

    // MARK: FolderSchema editierbar (Ordner-Schema-Editor, Stufe 1)

    @Test func aktivesSchemaFaelltOhneAdminSchemaAufV1Zurueck() throws {
        let db = try GRDBDatabase.inMemory()
        let store = NomenklaturStore(db: db)
        try store.load()
        #expect(store.aktivesSchema() == FolderSchema.v1)
        #expect(store.customFolderSchema == nil)
    }

    @Test func adminSchemaUeberlebtNeustartUndWirdZumAktivenSchema() throws {
        let dir = tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("db.sqlite")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let eigenesSchema = FolderSchema(
            version: 2,
            rootTemplate: "<JJJJ_NNN_Kunde>",
            children: [FolderNode("01 EIGEN", children: [FolderNode("Unterordner")])],
            rootDateien: []
        )

        let dbA = try GRDBDatabase(url: url)
        let storeA = NomenklaturStore(db: dbA)
        try storeA.load()
        try storeA.setzeSchema(eigenesSchema)
        #expect(storeA.aktivesSchema() == eigenesSchema)
        #expect(storeA.aktiveSchemaVersion == 2)

        let dbB = try GRDBDatabase(url: url)
        let storeB = NomenklaturStore(db: dbB)
        try storeB.load()   // neue Instanz, echter Neustart
        #expect(storeB.aktivesSchema() == eigenesSchema)
        #expect(storeB.customFolderSchema == eigenesSchema)
        #expect(storeB.aktiveSchemaVersion == 2)
    }

    @Test func setzeSchemaAufStandardWirftAdminSchemaWegUndFaelltAufV1Zurueck() throws {
        let db = try GRDBDatabase.inMemory()
        let store = NomenklaturStore(db: db)
        try store.load()
        try store.setzeSchema(FolderSchema(version: 3, rootTemplate: "x", children: [], rootDateien: []))
        #expect(store.aktivesSchema().version == 3)

        try store.setzeSchemaAufStandard()
        #expect(store.aktivesSchema() == FolderSchema.v1)
        #expect(store.customFolderSchema == nil)
        #expect(store.aktiveSchemaVersion == 1)
    }

    // MARK: Registry-Identitäts-Lookups

    @Test func registryLoestKdnrUndProjektnrUndTokenAuf() throws {
        let dir = tempDir(); defer { try? FileManager.default.removeItem(at: dir) }
        let routing = try CachedProjectRegistry(directory: dir)
        let business = try CachedBusinessRegistry(directory: dir)
        try routing.replaceCustomers([Customer(customerNumber: "K-1001", name: "Familie Meyer")])
        try routing.replaceProjects([
            Project(projectNumber: "2026-015", title: "Küche Meyer", kind: .kitchen, customerNumber: "K-1001")
        ])
        let registry = ExternalMappingRegistry(routing: routing, business: business)

        #expect(try registry.customer(kdnr: "K-1001")?.name == "Familie Meyer")
        #expect(try registry.project(projektnummer: "2026-015")?.title == "Küche Meyer")
        #expect(try registry.projects(kdnr: "K-1001").count == 1)

        // Token-Auflösung: Projektnr gewinnt, Kdnr separat, Name als Fallback.
        if case .projekt(let p) = try registry.resolveToken("2026-015") { #expect(p.projectNumber == "2026-015") } else { Issue.record("Projektnr nicht aufgelöst") }
        if case .kunde(let c) = try registry.resolveToken("K-1001") { #expect(c.customerNumber == "K-1001") } else { Issue.record("Kdnr nicht aufgelöst") }
        if case .kunde(let c) = try registry.resolveToken("familie meyer") { #expect(c.customerNumber == "K-1001") } else { Issue.record("Name nicht aufgelöst") }
        #expect(try registry.resolveToken("xyz") == .unbekannt)
    }
}
