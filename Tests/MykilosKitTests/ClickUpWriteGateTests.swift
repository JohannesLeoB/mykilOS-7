import Testing
@testable import MykilosKit

// MARK: - ClickUpWriteGateTests (ClickUp-Vollintegration S4+S10, 2026-07-07)
struct ClickUpWriteGateTests {

    @Test func testspaceListeIstErlaubt() throws {
        try ClickUpWriteGate.assertSchreibErlaubt(spaceID: "90128024109", listID: "irgendeine")
    }

    @Test func fremdeSpaceOhneWhitelistWirdAbgelehnt() {
        #expect(throws: ClickUpWriteGateError.nichtErlaubt(listID: "901218617645")) {
            try ClickUpWriteGate.assertSchreibErlaubt(spaceID: "90127216979", listID: "901218617645")
        }
    }

    // Fail-closed: eine unbekannte/nicht auflösbare Space-ID (nil) wird GENAUSO
    // abgelehnt wie eine fremde — kein impliziter Vertrauensfall.
    @Test func unbekannteSpaceOhneWhitelistWirdAbgelehnt() {
        #expect(throws: ClickUpWriteGateError.nichtErlaubt(listID: "x")) {
            try ClickUpWriteGate.assertSchreibErlaubt(spaceID: nil, listID: "x")
        }
    }

    // Go-Live-Whitelist (S10): eine fremde Space wird erlaubt, WENN die Liste explizit
    // freigeschaltet ist — die Whitelist ist der einzige Weg zu echten Produktivlisten.
    @Test func whitelisteteListeInFremderSpaceIstErlaubt() throws {
        try ClickUpWriteGate.assertSchreibErlaubt(
            spaceID: "90127216979", listID: "901218617645",
            goLiveWhitelist: ["901218617645"])
    }

    @Test func whitelisteUmfasstNurGenannteListenIDs() {
        #expect(throws: ClickUpWriteGateError.nichtErlaubt(listID: "andere-liste")) {
            try ClickUpWriteGate.assertSchreibErlaubt(
                spaceID: "90127216979", listID: "andere-liste",
                goLiveWhitelist: ["901218617645"])
        }
    }
}
