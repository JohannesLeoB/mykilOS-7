import Testing
import Foundation
@testable import MykilosKit

// MARK: - AdminAuthorityTests
//
// Reines Berechtigungs-Fundament: Admin NUR aus verifizierter Google-Mail, default-deny.
// Enthält den Eskalations-Negativtest — der Kern der Sicherheitsentscheidung: ein normaler
// User (Mail nicht in der Allowlist) ist NIE Admin, und es gibt strukturell keinen
// lokal-setzbaren Pfad zu Admin (die Prüfung nimmt nur die verifizierte Mail entgegen).
struct AdminAuthorityTests {

    private func ausweis(_ email: String) -> ResidentIdentity {
        ResidentIdentity(googleEmail: email, userID: "u-\(email)")
    }

    @Test func adminMailMitTokenIstAdmin() {
        let autoritaet = AllowlistAdminAuthority(allowlist: AdminAllowlist(["johannes@mykilos.com"]))
        #expect(autoritaet.istAdmin(ausweis("johannes@mykilos.com"), tokenPresent: true))
    }

    @Test func adminMailOhneTokenIstKeinAdmin() {
        // TOKEN-KOPPLUNG: die googleEmail allein ist fälschbar (lokal aus Keychain hydriert).
        // Ohne echtes Google-Token → kein Admin, auch wenn die Mail in der Allowlist steht.
        let autoritaet = AllowlistAdminAuthority(allowlist: AdminAllowlist(["johannes@mykilos.com"]))
        #expect(autoritaet.istAdmin(ausweis("johannes@mykilos.com"), tokenPresent: false) == false)
    }

    @Test func normalerUserIstNiemalsAdmin() {
        // ESKALATIONS-NEGATIVTEST: eine Mail, die nicht in der Allowlist steht, ist kein Admin —
        // auch mit vorhandenem Token.
        let autoritaet = AllowlistAdminAuthority(allowlist: AdminAllowlist(["johannes@mykilos.com"]))
        #expect(autoritaet.istAdmin(ausweis("gast@example.com"), tokenPresent: true) == false)
    }

    @Test func nilOderLeererAusweisIstKeinAdmin() {
        let autoritaet = AllowlistAdminAuthority(allowlist: AdminAllowlist(["johannes@mykilos.com"]))
        #expect(autoritaet.istAdmin(nil, tokenPresent: true) == false)
        // Leerer kanonischer Schlüssel → hasValidKey == false → deny (kein geteilter Anker-Kollaps).
        #expect(autoritaet.istAdmin(ausweis(""), tokenPresent: true) == false)
        #expect(autoritaet.istAdmin(ausweis("   "), tokenPresent: true) == false)
    }

    @Test func normalisierungGrossKleinUndWhitespace() {
        let autoritaet = AllowlistAdminAuthority(allowlist: AdminAllowlist(["johannes@mykilos.com"]))
        #expect(autoritaet.istAdmin(ausweis("JOHANNES@MYKILOS.COM"), tokenPresent: true))
        #expect(autoritaet.istAdmin(ausweis("  johannes@mykilos.com  "), tokenPresent: true))
    }

    @Test func assertAdminWirftFuerNichtAdminUndNichtFuerAdmin() throws {
        let autoritaet = AllowlistAdminAuthority(allowlist: AdminAllowlist(["johannes@mykilos.com"]))
        // Admin (Mail + Token): kein Wurf.
        try autoritaet.assertAdmin(ausweis("johannes@mykilos.com"), tokenPresent: true, funktion: "Einladung erzeugen")
        // Nicht-Admin: wirft nurAdmin mit der benannten Funktion.
        #expect(throws: BerechtigungError.nurAdmin(funktion: "Einladung erzeugen")) {
            try autoritaet.assertAdmin(ausweis("gast@example.com"), tokenPresent: true, funktion: "Einladung erzeugen")
        }
        // Admin-Mail aber ohne Token: wirft ebenfalls.
        #expect(throws: BerechtigungError.nurAdmin(funktion: "Einladung erzeugen")) {
            try autoritaet.assertAdmin(ausweis("johannes@mykilos.com"), tokenPresent: false, funktion: "Einladung erzeugen")
        }
    }

    @Test func gebackenerDefaultEnthaeltJohannesNichtBeliebige() {
        // Der eingebackene Anker: Johannes (mit Token) ist Admin, ein beliebiger anderer nicht.
        // (Daniels echte Mail wird von Johannes ergänzt — hier bewusst nicht geraten.)
        let autoritaet = AllowlistAdminAuthority()   // .gebacken
        #expect(autoritaet.istAdmin(ausweis("johannes@mykilos.com"), tokenPresent: true))
        #expect(autoritaet.istAdmin(ausweis("irgendwer@mykilos.com"), tokenPresent: true) == false)
    }

    @Test func allowlistNormalisiertUndFiltertLeere() {
        let liste = AdminAllowlist(["  A@B.COM ", "", "   "])
        #expect(liste.emails == ["a@b.com"])
        #expect(liste.enthaelt("a@b.com"))
        #expect(liste.enthaelt(nil) == false)
    }
}
