import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

// Tests für den Projekt-Meta-Übertrag (Schaltschrank, read-only, 2026-07-06).
// KEIN echtes ClickUp/Netzwerk — nur Fake-`custom_fields` + reine Parser/Mapper/Registry,
// gleiches Muster wie die bestehenden ClickUpClientTests.
struct ClickUpProjektMetaTests {

    // Fälligkeits-/Datum-Referenzwerte (Epoch-Millisekunden, wie ClickUp sie liefert).
    private let angebotMillis = "1704067200000"   // 2024-01-01 00:00:00 UTC
    private let auftragMillis = "1706745600000"   // 2024-02-01 00:00:00 UTC
    private let nachfassMillis = "1709251200000"  // 2024-03-01 00:00:00 UTC

    // MARK: - Voller Übertrag aus Fake-custom_fields

    @Test func parseProjektMetaHebtAlle13FelderKorrekt() throws {
        let json = """
        {
          "tasks": [
            {
              "id": "t1",
              "name": "Projekt-Ankertask",
              "status": { "status": "to do" },
              "custom_fields": [
                { "id": "f1",  "name": "Budget (€)",          "value": "48500" },
                { "id": "f2",  "name": "Angebotsdatum",       "value": "\(angebotMillis)" },
                { "id": "f3",  "name": "Auftragsdatum",       "value": "\(auftragMillis)" },
                { "id": "f4",  "name": "Nächstes Nachfassen", "value": "\(nachfassMillis)" },
                { "id": "f5",  "name": "Drive-Ordner",        "value": "https://drive.google.com/drive/folders/ABC" },
                { "id": "f6",  "name": "Kunde",               "value": "Familie Schmidt" },
                { "id": "f7",  "name": "Kunde-Token",         "value": "KND-2024-015" },
                { "id": "f8",  "name": "Projekttyp",          "value": "Vollprojekt (Privatküche)" },
                { "id": "f9",  "name": "Ort",                 "value": "Bochum-Hustadt" },
                { "id": "f10", "name": "Lead",                "value": "Johannes" },
                { "id": "f11", "name": "Lieferanten",         "value": ["Tischlerei Nord", "Steinmetz Kraus"] },
                { "id": "f12", "name": "Risiko/Engpass",      "value": "Lieferzeit Naturstein" },
                { "id": "f13", "name": "Slack-Channel",       "value": "#proj-2024-015" }
              ]
            }
          ]
        }
        """
        let meta = try ClickUpProjektMetaMapper.parse(from: Data(json.utf8))

        #expect(meta.budget == 48500)
        #expect(meta.angebotsdatum == Date(timeIntervalSince1970: 1_704_067_200))
        #expect(meta.auftragsdatum == Date(timeIntervalSince1970: 1_706_745_600))
        #expect(meta.naechstesNachfassen == Date(timeIntervalSince1970: 1_709_251_200))
        #expect(meta.driveOrdner == "https://drive.google.com/drive/folders/ABC")
        #expect(meta.kunde == "Familie Schmidt")
        #expect(meta.kundeToken == "KND-2024-015")
        #expect(meta.projekttyp == "Vollprojekt (Privatküche)")
        #expect(meta.ort == "Bochum-Hustadt")
        #expect(meta.lead == "Johannes")
        #expect(meta.lieferanten == ["Tischlerei Nord", "Steinmetz Kraus"])
        #expect(meta.risikoEngpass == "Lieferzeit Naturstein")
        #expect(meta.slackChannel == "#proj-2024-015")
        #expect(meta.isEmpty == false)
    }

    // MARK: - Toleranz: fehlende Felder → nil

    @Test func parseProjektMetaFehlendeFelderBleibenNil() throws {
        // Nur Budget + Kunde gesetzt — alle anderen 11 Slots müssen nil bleiben.
        let json = """
        {
          "tasks": [
            {
              "id": "t1",
              "name": "Teilbefülltes Projekt",
              "status": { "status": "to do" },
              "custom_fields": [
                { "id": "f1", "name": "Budget (€)", "value": "12000" },
                { "id": "f6", "name": "Kunde",      "value": "Herr Weber" }
              ]
            }
          ]
        }
        """
        let meta = try ClickUpProjektMetaMapper.parse(from: Data(json.utf8))

        #expect(meta.budget == 12000)
        #expect(meta.kunde == "Herr Weber")
        #expect(meta.angebotsdatum == nil)
        #expect(meta.auftragsdatum == nil)
        #expect(meta.naechstesNachfassen == nil)
        #expect(meta.driveOrdner == nil)
        #expect(meta.kundeToken == nil)
        #expect(meta.projekttyp == nil)
        #expect(meta.ort == nil)
        #expect(meta.lead == nil)
        #expect(meta.lieferanten == nil)
        #expect(meta.risikoEngpass == nil)
        #expect(meta.slackChannel == nil)
    }

    @Test func parseProjektMetaNullWertBleibtNil() throws {
        // Ein explizit auf null gesetztes Feld darf den Slot nicht füllen.
        let json = """
        {
          "tasks": [
            {
              "id": "t1", "name": "Mit null", "status": { "status": "to do" },
              "custom_fields": [
                { "id": "f5", "name": "Drive-Ordner", "value": null },
                { "id": "f9", "name": "Ort",          "value": "Wanne" }
              ]
            }
          ]
        }
        """
        let meta = try ClickUpProjektMetaMapper.parse(from: Data(json.utf8))
        #expect(meta.driveOrdner == nil)
        #expect(meta.ort == "Wanne")
    }

    @Test func parseProjektMetaOhneCustomFieldsIstEmpty() throws {
        let json = """
        { "tasks": [ { "id": "t1", "name": "Kahl", "status": { "status": "to do" } } ] }
        """
        let meta = try ClickUpProjektMetaMapper.parse(from: Data(json.utf8))
        #expect(meta == .empty)
        #expect(meta.isEmpty)
    }

    @Test func parseProjektMetaLeereTaskListeIstEmpty() throws {
        let meta = try ClickUpProjektMetaMapper.parse(from: Data("""
        { "tasks": [] }
        """.utf8))
        #expect(meta == .empty)
    }

    @Test func parseProjektMetaWirftBeiKaputtemJSON() {
        #expect(throws: ClickUpError.decodingFailed) {
            _ = try ClickUpProjektMetaMapper.parse(from: Data("kein json".utf8))
        }
    }

    @Test func parseProjektMetaNimmtErsteTaskMitCustomFields() throws {
        // Erste Task ohne Felder, zweite trägt sie → die zweite gewinnt (Space-Felder erscheinen
        // auf jeder Task; wir werten die erste befüllte aus).
        let json = """
        {
          "tasks": [
            { "id": "t1", "name": "Leer", "status": { "status": "to do" }, "custom_fields": [] },
            {
              "id": "t2", "name": "Trägt Meta", "status": { "status": "to do" },
              "custom_fields": [ { "id": "f9", "name": "Ort", "value": "Herne" } ]
            }
          ]
        }
        """
        let meta = try ClickUpProjektMetaMapper.parse(from: Data(json.utf8))
        #expect(meta.ort == "Herne")
    }

    // MARK: - Der Mapper direkt (Fake-Felder, kein JSON)

    @Test func mapperHebtCurrencyAlsZahlAuchWennNumerisch() {
        // Currency kann als Zahl ODER String kommen — beide müssen greifen.
        let felder = [
            ClickUpMetaField(name: "Budget (€)", raw: .zahl(9900))
        ]
        let meta = ClickUpProjektMetaMapper.map(fields: felder)
        #expect(meta.budget == 9900)
    }

    @Test func mapperHebtLabelsListe() {
        let felder = [
            ClickUpMetaField(name: "Lieferanten", raw: .liste(["Nord", "Süd", "  ", "West"]))
        ]
        let meta = ClickUpProjektMetaMapper.map(fields: felder)
        // Leerwerte werden gefiltert.
        #expect(meta.lieferanten == ["Nord", "Süd", "West"])
    }

    @Test func mapperTrimmtTextUndVerwirftLeeren() {
        let felder = [
            ClickUpMetaField(name: "Ort", raw: .text("  Dortmund  ")),
            ClickUpMetaField(name: "Lead", raw: .text("   "))
        ]
        let meta = ClickUpProjektMetaMapper.map(fields: felder)
        #expect(meta.ort == "Dortmund")
        #expect(meta.lead == nil)   // nur Whitespace → nil
    }

    @Test func mapperIgnoriertUnbekannteFelder() {
        let felder = [
            ClickUpMetaField(name: "project_phase", raw: .zahl(4)),
            ClickUpMetaField(name: "irgendwas_neues", raw: .text("egal")),
            ClickUpMetaField(name: "Kunde", raw: .text("Frau Klein"))
        ]
        let meta = ClickUpProjektMetaMapper.map(fields: felder)
        #expect(meta.kunde == "Frau Klein")
        #expect(meta.isEmpty == false)
        // Nichts anderes wurde gesetzt.
        #expect(meta.projekttyp == nil)
        #expect(meta.budget == nil)
    }

    @Test func mapperIgnoriertTypFremdenRohwert() {
        // Datum-Klemme bekommt eine Liste → bleibt nil (tolerant, nie brechend).
        let felder = [
            ClickUpMetaField(name: "Angebotsdatum", raw: .liste(["x"])),
            ClickUpMetaField(name: "Budget (€)", raw: .liste(["y"]))
        ]
        let meta = ClickUpProjektMetaMapper.map(fields: felder)
        #expect(meta.angebotsdatum == nil)
        #expect(meta.budget == nil)
    }

    // MARK: - Die Route-Tabelle ist testbar (Schaltschrank)

    @Test func defaultRegistryHatFuerJedeKlemmeGenauEineAktiveRoute() {
        let registry = ClickUpFieldRouteRegistry.default
        let zieleDerAktivenRouten = registry.aktiveRoutes.map(\.ziel)
        // Jede der 13 Klemmen ist genau einmal Ziel einer aktiven Route.
        for slot in ClickUpMetaSlot.allCases {
            #expect(zieleDerAktivenRouten.filter { $0 == slot }.count == 1)
        }
        #expect(registry.aktiveRoutes.count == ClickUpMetaSlot.allCases.count)
    }

    @Test func registryFindetRouteUeberQuellFeldname() {
        let registry = ClickUpFieldRouteRegistry.default
        #expect(registry.route(fuerQuelle: "Budget (€)")?.ziel == .budget)
        #expect(registry.route(fuerQuelle: "Slack-Channel")?.ziel == .slackChannel)
        #expect(registry.route(fuerQuelle: "gibt es nicht") == nil)
    }

    @Test func stillgelegteRouteWirdUebersprungen() {
        // Budget-Route deaktivieren → das Budget-Feld darf nicht mehr durchkommen.
        var registry = ClickUpFieldRouteRegistry.default
        registry.routes = registry.routes.map { route in
            var kopie = route
            if kopie.routeID == "CU_META_BUDGET" { kopie.aktiv = false }
            return kopie
        }
        #expect(registry.route(fuerQuelle: "Budget (€)") == nil)

        let felder = [
            ClickUpMetaField(name: "Budget (€)", raw: .zahl(5000)),
            ClickUpMetaField(name: "Kunde", raw: .text("Test"))
        ]
        let meta = ClickUpProjektMetaMapper.map(fields: felder, routes: registry)
        #expect(meta.budget == nil)     // Route inaktiv → nicht übertragen
        #expect(meta.kunde == "Test")   // andere Route unberührt
    }

    @Test func routeUmlegenLeitetQuelleAufAnderesZiel() {
        // Der Kern des Schaltschranks: dieselbe Quelle auf eine andere Klemme umstecken,
        // ohne den Parser/Mapper anzufassen — nur eine Route-Zeile.
        let umgelegt = ClickUpFieldRouteRegistry(routes: [
            // "Ort" wird bewusst auf die Slack-Channel-Klemme gelegt.
            ClickUpFieldRoute(routeID: "R1", quelle: "Ort", ziel: .slackChannel)
        ])
        let felder = [ClickUpMetaField(name: "Ort", raw: .text("#umgeleitet"))]
        let meta = ClickUpProjektMetaMapper.map(fields: felder, routes: umgelegt)

        #expect(meta.slackChannel == "#umgeleitet")  // landete auf der neuen Klemme
        #expect(meta.ort == nil)                      // NICHT mehr auf der alten
    }

    @Test func registryIstCodableRoundtrip() throws {
        // Die Verdrahtung ist Daten (persistierbar/umsteckbar), kein Code → muss roundtripen.
        let original = ClickUpFieldRouteRegistry.default
        let data = try JSONEncoder().encode(original)
        let zurueck = try JSONDecoder().decode(ClickUpFieldRouteRegistry.self, from: data)
        #expect(zurueck.routes == original.routes)
    }

    // MARK: - project_phase bleibt unberührt (Regression)

    @Test func projectPhasePfadBleibtNebenMetaUnveraendert() throws {
        // Dieselbe custom_fields-Struktur trägt project_phase UND Meta-Felder — beide Pfade
        // müssen unabhängig funktionieren.
        let json = """
        {
          "tasks": [
            {
              "id": "t1", "name": "Beides", "status": { "status": "to do" },
              "custom_fields": [
                { "id": "p", "name": "project_phase", "value": 4 },
                { "id": "o", "name": "Ort", "value": "Castrop" }
              ]
            }
          ]
        }
        """
        let tasks = try ClickUpClient.parseTasks(from: Data(json.utf8))
        let meta = try ClickUpProjektMetaMapper.parse(from: Data(json.utf8))
        #expect(tasks[0].projectPhase == .ausfuehrung)  // Int-Pfad unverändert
        #expect(meta.ort == "Castrop")                  // Meta-Pfad
    }
}
