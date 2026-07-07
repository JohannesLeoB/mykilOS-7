import Testing
import Foundation
@testable import MykilosServices

struct MykInvitePasswordGeneratorTests {

    @Test func hatDieGewuenschteLaenge() {
        #expect(MykInvitePasswordGenerator.generate(length: 20).count == 20)
        #expect(MykInvitePasswordGenerator.generate(length: 8).count == 8)
    }

    @Test func nutztNurDasErlaubteAlphabet() {
        let erlaubt = Set(MykInvitePasswordGenerator.alphabet)
        let passwort = MykInvitePasswordGenerator.generate(length: 200)
        #expect(passwort.allSatisfy { erlaubt.contains($0) })
    }

    @Test func enthaeltKeineMehrdeutigenZeichen() {
        let mehrdeutig: Set<Character> = ["0", "O", "1", "l", "I"]
        let passwort = MykInvitePasswordGenerator.generate(length: 500)
        #expect(passwort.contains { mehrdeutig.contains($0) } == false)
    }

    @Test func zweiPasswoerterUnterscheidenSich() {
        // Praktisch nie identisch (56^20 Möglichkeiten) — fängt einen kaputten RNG/Konstant-Bug.
        #expect(MykInvitePasswordGenerator.generate() != MykInvitePasswordGenerator.generate())
    }

    @Test func laengeNullOderNegativLiefertMindestensEinZeichen() {
        #expect(MykInvitePasswordGenerator.generate(length: 0).isEmpty == false)
        #expect(MykInvitePasswordGenerator.generate(length: -5).count == 1)
    }
}
