import Testing
@testable import MykilosKit

// Bugfix 2026-07-06/07: geteilte Signatur-Konvention (vorher: ComposeMailView hatte eine
// eigene Kopie, AppState.createDraft (Assistenten-Pfad) hatte GAR keine — jeder Assistenten-
// Entwurf ging ohne Signatur raus).
struct EmailDraftSignaturTests {

    @Test func signaturWirdMitTrennerAngehaengt() {
        let ergebnis = EmailDraft.signaturAnhaengen(an: "Hallo,\n\nviele Grüße", signatur: "Frauke Müller")
        #expect(ergebnis == "Hallo,\n\nviele Grüße\n\n-- \nFrauke Müller")
    }

    @Test func leererBodyBekommtNurDieSignaturMitTrenner() {
        let ergebnis = EmailDraft.signaturAnhaengen(an: "", signatur: "Frauke Müller")
        #expect(ergebnis == "\n\n-- \nFrauke Müller")
    }

    @Test func leereSignaturLaesstBodyUnveraendert() {
        #expect(EmailDraft.signaturAnhaengen(an: "Hallo", signatur: "") == "Hallo")
        #expect(EmailDraft.signaturAnhaengen(an: "Hallo", signatur: nil) == "Hallo")
        #expect(EmailDraft.signaturAnhaengen(an: "Hallo", signatur: "   ") == "Hallo")
    }

    @Test func mitAngehaengterSignaturAendertNurDenBodyRestBleibtGleich() {
        let draft = EmailDraft(to: "kunde@example.com", subject: "Betreff", body: "Text")
        let mitSignatur = draft.mitAngehaengterSignatur("Frauke")
        #expect(mitSignatur.to == draft.to)
        #expect(mitSignatur.subject == draft.subject)
        #expect(mitSignatur.body == "Text\n\n-- \nFrauke")
    }

    @Test func mitAngehaengterSignaturOhneSignaturLiefertUnveraendertenEntwurf() {
        let draft = EmailDraft(subject: "X", body: "Y")
        #expect(draft.mitAngehaengterSignatur(nil) == draft)
        #expect(draft.mitAngehaengterSignatur("") == draft)
    }
}
