import Testing
@testable import MykilosServices

// Onboarding-Plan Ebene 1: reine Dictionary-Logik, kein echtes Bundle.main nötig.
struct BundledGoogleOAuthConfigTests {

    @Test func fehlenderKeyLiefertNil() {
        #expect(BundledGoogleOAuthConfig.wert(fuerKey: "MykGoogleClientID", aus: [:]) == nil)
    }

    @Test func leererStringLiefertNil() {
        let dict: [String: Any] = ["MykGoogleClientID": "   "]
        #expect(BundledGoogleOAuthConfig.wert(fuerKey: "MykGoogleClientID", aus: dict) == nil)
    }

    @Test func echterWertWirdGetrimmtZurueckgegeben() {
        let dict: [String: Any] = ["MykGoogleClientID": "  1234-example.apps.googleusercontent.com  "]
        #expect(BundledGoogleOAuthConfig.wert(fuerKey: "MykGoogleClientID", aus: dict) == "1234-example.apps.googleusercontent.com")
    }

    @Test func nichtStringWertLiefertNil() {
        let dict: [String: Any] = ["MykGoogleClientID": 42]
        #expect(BundledGoogleOAuthConfig.wert(fuerKey: "MykGoogleClientID", aus: dict) == nil)
    }

    @Test func nilDictLiefertNil() {
        #expect(BundledGoogleOAuthConfig.wert(fuerKey: "MykGoogleClientID", aus: nil) == nil)
    }
}
