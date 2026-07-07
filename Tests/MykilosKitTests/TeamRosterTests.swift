import Testing
@testable import MykilosKit

// MARK: - TeamRosterTests (ClickUp-Vollintegration, 2026-07-07)
struct TeamRosterTests {

    @Test func kuerzelLoestBekannteClickUpMemberIDsAuf() {
        #expect(TeamRoster.kuerzel(fuerClickUpMemberID: "99729772") == "Jo")
        #expect(TeamRoster.kuerzel(fuerClickUpMemberID: "296479146") == "Da")
        #expect(TeamRoster.kuerzel(fuerClickUpMemberID: "296476295") == "Fra")
        #expect(TeamRoster.kuerzel(fuerClickUpMemberID: "99729773") == "Sen")
        #expect(TeamRoster.kuerzel(fuerClickUpMemberID: "248493812") == "Jil")
    }

    @Test func kuerzelNilFuerUnbekannteOderFehlendeID() {
        #expect(TeamRoster.kuerzel(fuerClickUpMemberID: "999999999") == nil)
        #expect(TeamRoster.kuerzel(fuerClickUpMemberID: nil) == nil)
    }

    @Test func fuenfEingebackeneMitglieder() {
        #expect(TeamRoster.alle.count == 5)
        #expect(Set(TeamRoster.alle.map(\.kuerzel)) == ["Jo", "Da", "Fra", "Sen", "Jil"])
    }
}
