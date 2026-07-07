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

    @Test func adminMailIstAdmin() {
        let autoritaet = AllowlistAdminAuthority(allowlist: AdminAllowlist(["johannes@mykilos.com"]))
        #expect(autoritaet.istAdmin(ausweis("johannes@mykilos.com")))
    }

    @Test func normalerUserIstNiemalsAdmin() {
        // ESKALATIONS-NEGATIVTEST: eine Mail, die nicht in der Allowlist steht, ist kein Admin.
        let autoritaet = AllowlistAdminAuthority(allowlist: AdminAllowlist(["johannes@mykilos.com"]))
        #expect(autoritaet.istAdmin(ausweis("gast@example.com")) == false)
    }

    @Test func nilOderLeererAusweisIstKeinAdmin() {
        let autoritaet = AllowlistAdminAuthority(allowlist: AdminAllowlist(["johannes@mykilos.com"]))
        #expect(autoritaet.istAdmin(nil) == false)
        // Leerer kanonischer Schlüssel → hasValidKey == false → deny (kein geteilter Anker-Kollaps).
        #expect(autoritaet.istAdmin(ausweis("")) == false)
        #expect(autoritaet.istAdmin(ausweis("   ")) == false)
    }

    @Test func normalisierungGrossKleinUndWhitespace() {
        let autoritaet = AllowlistAdminAuthority(allowlist: AdminAllowlist(["johannes@mykilos.com"]))
        #expect(autoritaet.istAdmin(ausweis("JOHANNES@MYKILOS.COM")))
        #expect(autoritaet.istAdmin(ausweis("  johannes@mykilos.com  ")))
    }

    @Test func assertAdminWirftFuerNichtAdminUndNichtFuerAdmin() throws {
        let autoritaet = AllowlistAdminAuthority(allowlist: AdminAllowlist(["johannes@mykilos.com"]))
        // Admin: kein Wurf.
        try autoritaet.assertAdmin(ausweis("johannes@mykilos.com"), funktion: "Einladung erzeugen")
        // Nicht-Admin: wirft nurAdmin mit der benannten Funktion.
        #expect(throws: BerechtigungError.nurAdmin(funktion: "Einladung erzeugen")) {
            try autoritaet.assertAdmin(ausweis("gast@example.com"), funktion: "Einladung erzeugen")
        }
    }

    @Test func gebackenerDefaultEnthaeltJohannesNichtBeliebige() {
        // Der eingebackene Anker: Johannes ist Admin, ein beliebiger anderer nicht.
        // (Daniels echte Mail wird von Johannes ergänzt — hier bewusst nicht geraten.)
        let autoritaet = AllowlistAdminAuthority()   // .gebacken
        #expect(autoritaet.istAdmin(ausweis("johannes@mykilos.com")))
        #expect(autoritaet.istAdmin(ausweis("irgendwer@mykilos.com")) == false)
    }

    @Test func allowlistNormalisiertUndFiltertLeere() {
        let liste = AdminAllowlist(["  A@B.COM ", "", "   "])
        #expect(liste.emails == ["a@b.com"])
        #expect(liste.enthaelt("a@b.com"))
        #expect(liste.enthaelt(nil) == false)
    }
}
