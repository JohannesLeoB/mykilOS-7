import Testing
@testable import MykilosApp

// Johannes-Feedback (2026-07-06): "Preis-Wissen" als neuer Kataloge-Tab, togglebar,
// aber standardmäßig AUS (Admin-Opt-in) -- anders als die übrigen Kataloge.
struct KatalogTabTests {

    @Test func preiswissenIstImDefaultOrderEnthalten() {
        #expect(KatalogTab.defaultOrder.contains(.preiswissen))
    }

    @Test func standardAktiveTabsSchliessenPreiswissenAus() {
        #expect(KatalogTab.defaultAktiveTabs.contains(.preiswissen) == false)
        // Alle anderen Kataloge bleiben Standard-sichtbar.
        for tab in KatalogTab.allCases where tab != .preiswissen {
            #expect(KatalogTab.defaultAktiveTabs.contains(tab), "\(tab.rawValue) sollte standardmäßig sichtbar sein")
        }
    }

    @Test func preiswissenRawValueBleibtStabil() {
        // rawValue wird in @AppStorage("kataloge.aktiveTabs") persistiert -- ändert er
        // sich, verlieren bestehende Nutzer ihre gespeicherte Auswahl stillschweigend.
        #expect(KatalogTab.preiswissen.rawValue == "preiswissen")
    }

    @Test func preiswissenHatTitelUndIcon() {
        #expect(KatalogTab.preiswissen.title == "Preis-Wissen")
        #expect(KatalogTab.preiswissen.icon == "brain.head.profile")
    }
}
