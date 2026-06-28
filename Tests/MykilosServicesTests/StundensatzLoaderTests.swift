import Testing
import Foundation
@testable import MykilosServices
import MykilosKalkulationsCore

struct StundensatzLoaderTests {

    @Test func hardcodeEnthältAlleAchtStages() {
        let saetze = StundensatzLoader.hardcodedSaetze
        let expectedKeys = ["av", "zuschnitt", "kante", "cnc", "bankraum", "lager", "laden", "montage"]
        for key in expectedKeys {
            #expect(saetze[key] != nil, "Key '\(key)' fehlt im Hardcode-Fallback")
            #expect(saetze[key]! > 0)
        }
    }

    @Test func leereAirtableRecordsGibtHardcode() {
        let result = StundensatzLoader.merge(airtableRecords: [])
        let hardcode = StundensatzLoader.hardcodedSaetze
        #expect(result == hardcode)
    }

    @Test func airtableRateÜberschreibtHardcode() {
        let records: [[String: Any]] = [
            ["Name": "Bankraum", "Stundensatz (€/h)": 99.0],
        ]
        let result = StundensatzLoader.merge(airtableRecords: records)
        #expect(result["bankraum"] == Decimal(99))
        // Andere Keys unverändert
        let hardcode = StundensatzLoader.hardcodedSaetze
        #expect(result["montage"] == hardcode["montage"])
    }

    @Test func unbekannteNamenWerdenIgnoriert() {
        let records: [[String: Any]] = [
            ["Name": "UnbekannteLeistung", "Stundensatz (€/h)": 200.0],
        ]
        let result = StundensatzLoader.merge(airtableRecords: records)
        // Unbekannter Name → kein neuer Key, Hardcode unverändert
        #expect(result == StundensatzLoader.hardcodedSaetze)
    }

    @Test func nullRatWirdIgnoriert() {
        let records: [[String: Any]] = [
            ["Name": "AV/Aufmaß", "Stundensatz (€/h)": 0.0],
        ]
        let result = StundensatzLoader.merge(airtableRecords: records)
        // Rate = 0 → ignoriert, Hardcode-Wert bleibt
        let hardcode = StundensatzLoader.hardcodedSaetze
        #expect(result["av"] == hardcode["av"])
    }

    @Test func feldiDBeidesNameFormatFunktioniert() {
        // Airtable kann fieldID ("fld0Q4mwPLiKFAx0x") statt "Name" zurückgeben
        let records: [[String: Any]] = [
            ["fld0Q4mwPLiKFAx0x": "Montage", "fld4NBokj4MoOy8Uq": 88.0],
        ]
        let result = StundensatzLoader.merge(airtableRecords: records)
        #expect(result["montage"] == Decimal(88))
    }
}
