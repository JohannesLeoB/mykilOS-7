import Testing
@testable import MykilosApp

// MARK: - SettingsCategoryTests (Stufe 2, Etappe 1)
// Guard für die konsolidierte Settings-Ebene: „Verbindungen" heißt jetzt
// „Integrationen", die Rail-Reihenfolge folgt den privat→geteilt-Bändern, und die
// rawValues bleiben stabil (sonst verliert @AppStorage die gespeicherte Auswahl).
struct SettingsCategoryTests {

    @Test func verbindungenHeisstJetztIntegrationen() {
        #expect(SettingsCategory.verbindungen.title == "Integrationen")
    }

    @Test func railReihenfolgeIstPrivatZuerst() {
        #expect(SettingsCategory.allCases == [
            .profil, .darstellung, .privat, .schluesselInventar, .verbindungen, .datenschutz, .system
        ])
    }

    @Test func rawValuesUnveraendertFuerAppStoragePersistenz() {
        // Case-Namen (rawValues) dürfen sich NICHT ändern — @AppStorage speichert sie.
        #expect(SettingsCategory.verbindungen.rawValue == "verbindungen")
        #expect(SettingsCategory.privat.rawValue == "privat")
        #expect(SettingsCategory.schluesselInventar.rawValue == "schluesselInventar")
    }
}
