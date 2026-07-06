import Testing
import Foundation
@testable import MykilosServices

// MARK: - NachfassAlertComputer (2026-07-07)
// Reine Alters-Heuristik: ausgehender Beleg seit N Tagen unverändert. Keine echte
// Reaktionsprüfung (siehe Kommentar in der Implementierung) — nur die Rechenlogik testen.

struct NachfassAlertComputerTests {

    private func offer(direction: AllOffersCollector.Direction, modifiedDaysAgo: Int?, now: Date) -> AllOffersCollector.AggregatedOffer {
        let modifiedAt = modifiedDaysAgo.map { Calendar.current.date(byAdding: .day, value: -$0, to: now)! }
        let file = GoogleDriveFile(id: "f1", name: "angebot.pdf", mimeType: "application/pdf",
                                    modifiedAt: modifiedAt, webViewLink: nil)
        return AllOffersCollector.AggregatedOffer(
            projectNumber: "2026-001", projectTitle: "Cirnavuk", projectFolderID: "F",
            direction: direction, offer: ClassifiedOffer(file: file, type: .angebot)
        )
    }

    @Test func faelligAbSchwelleGenauUndDarueber() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let genau = offer(direction: .outgoing, modifiedDaysAgo: 14, now: now)
        let darueber = offer(direction: .outgoing, modifiedDaysAgo: 20, now: now)
        #expect(NachfassAlertComputer.istFaellig(genau, schwelleInTagen: 14, now: now) == true)
        #expect(NachfassAlertComputer.istFaellig(darueber, schwelleInTagen: 14, now: now) == true)
    }

    @Test func nichtFaelligUnterSchwelle() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let frisch = offer(direction: .outgoing, modifiedDaysAgo: 3, now: now)
        #expect(NachfassAlertComputer.istFaellig(frisch, schwelleInTagen: 14, now: now) == false)
    }

    @Test func eingehendeBelegeWerdenNieGeflaggt() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let altEingehend = offer(direction: .incoming, modifiedDaysAgo: 100, now: now)
        #expect(NachfassAlertComputer.istFaellig(altEingehend, schwelleInTagen: 14, now: now) == false)
    }

    @Test func ohneAenderungsdatumNichtFaellig() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let ohneDatum = offer(direction: .outgoing, modifiedDaysAgo: nil, now: now)
        #expect(NachfassAlertComputer.istFaellig(ohneDatum, schwelleInTagen: 14, now: now) == false)
    }

    @Test func schwelleNullOderNegativDeaktiviert() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let alt = offer(direction: .outgoing, modifiedDaysAgo: 999, now: now)
        #expect(NachfassAlertComputer.istFaellig(alt, schwelleInTagen: 0, now: now) == false)
    }

    @Test func tageSeitAenderungRechnetKorrekt() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let alterBeleg = offer(direction: .outgoing, modifiedDaysAgo: 21, now: now)
        #expect(NachfassAlertComputer.tageSeitAenderung(alterBeleg, now: now) == 21)
    }

    @Test func tageSeitAenderungNilOhneDatum() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let ohneDatum = offer(direction: .outgoing, modifiedDaysAgo: nil, now: now)
        #expect(NachfassAlertComputer.tageSeitAenderung(ohneDatum, now: now) == nil)
    }
}

// MARK: - BitteReagierenAlertComputer (2026-07-07)
// Gegenrichtung zu NachfassAlertComputer: eingehender Beleg seit N Tagen unverändert.

struct BitteReagierenAlertComputerTests {

    private func offer(direction: AllOffersCollector.Direction, modifiedDaysAgo: Int?, now: Date) -> AllOffersCollector.AggregatedOffer {
        let modifiedAt = modifiedDaysAgo.map { Calendar.current.date(byAdding: .day, value: -$0, to: now)! }
        let file = GoogleDriveFile(id: "f1", name: "eingang.pdf", mimeType: "application/pdf",
                                    modifiedAt: modifiedAt, webViewLink: nil)
        return AllOffersCollector.AggregatedOffer(
            projectNumber: "2026-001", projectTitle: "Cirnavuk", projectFolderID: "F",
            direction: direction, offer: ClassifiedOffer(file: file, type: .eingehendesAngebot)
        )
    }

    @Test func faelligAbSchwelleFuerEingehendeBelege() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let genau = offer(direction: .incoming, modifiedDaysAgo: 14, now: now)
        #expect(BitteReagierenAlertComputer.istFaellig(genau, schwelleInTagen: 14, now: now) == true)
    }

    @Test func nichtFaelligUnterSchwelle() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let frisch = offer(direction: .incoming, modifiedDaysAgo: 3, now: now)
        #expect(BitteReagierenAlertComputer.istFaellig(frisch, schwelleInTagen: 14, now: now) == false)
    }

    @Test func ausgehendeBelegeWerdenNieGeflaggt() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let altAusgehend = offer(direction: .outgoing, modifiedDaysAgo: 100, now: now)
        #expect(BitteReagierenAlertComputer.istFaellig(altAusgehend, schwelleInTagen: 14, now: now) == false)
    }

    @Test func ohneAenderungsdatumNichtFaellig() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let ohneDatum = offer(direction: .incoming, modifiedDaysAgo: nil, now: now)
        #expect(BitteReagierenAlertComputer.istFaellig(ohneDatum, schwelleInTagen: 14, now: now) == false)
    }

    @Test func schwelleNullDeaktiviert() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let alt = offer(direction: .incoming, modifiedDaysAgo: 999, now: now)
        #expect(BitteReagierenAlertComputer.istFaellig(alt, schwelleInTagen: 0, now: now) == false)
    }
}
