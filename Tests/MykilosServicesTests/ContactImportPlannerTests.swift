import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

struct ContactImportPlannerTests {

    private func google(id: String, name: String, email: String? = nil, phone: String? = nil,
                        org: String? = nil) -> GoogleContact {
        GoogleContact(id: id, displayName: name, email: email, phone: phone, organization: org)
    }

    private func studio(id: String, name: String, email: String? = nil, telefon: String? = nil) -> StudioContact {
        StudioContact(id: id, name: name, email: email, telefon: telefon)
    }

    @Test func kontaktOhneMailUndTelefonWirdVerworfen() {
        let candidates = ContactImportPlanner.plan(
            googleContacts: [google(id: "g1", name: "Nur Name")], existing: [])
        #expect(candidates[0].decision == .skipIncomplete)
    }

    @Test func neuerKontaktMitMailWirdAngelegt() {
        let candidates = ContactImportPlanner.plan(
            googleContacts: [google(id: "g1", name: "Anna Meyer", email: "anna@example.com")], existing: [])
        #expect(candidates[0].decision == .create)
    }

    @Test func dubletteUeberMailWirdErkannt() {
        let existing = [studio(id: "rec1", name: "Anna Meyer", email: "Anna@Example.com")]
        let candidates = ContactImportPlanner.plan(
            googleContacts: [google(id: "g1", name: "Anna Meyer", email: "anna@example.com")], existing: existing)
        #expect(candidates[0].decision == .duplicate(existingRecordID: "rec1"))
    }

    @Test func dubletteUeberTelefonTrotzUnterschiedlicherFormatierung() {
        let existing = [studio(id: "rec2", name: "Bert Weck", telefon: "+49 40 12345")]
        let candidates = ContactImportPlanner.plan(
            googleContacts: [google(id: "g1", name: "Bert Weck", phone: "49-40-12345")], existing: existing)
        #expect(candidates[0].decision == .duplicate(existingRecordID: "rec2"))
    }

    @Test func nurTelefonOhneMailReichtFuerNeuanlage() {
        let candidates = ContactImportPlanner.plan(
            googleContacts: [google(id: "g1", name: "Carla Fuchs", phone: "030123456")], existing: [])
        #expect(candidates[0].decision == .create)
    }

    @Test func draftNurFuerCreateKandidaten() {
        let createCandidate = ContactImportCandidate(
            googleContact: google(id: "g1", name: "Anna Meyer", email: "anna@example.com", org: "Musterfirma"),
            decision: .create)
        let dupCandidate = ContactImportCandidate(
            googleContact: google(id: "g2", name: "Bert Weck"), decision: .duplicate(existingRecordID: "rec1"))
        let skipCandidate = ContactImportCandidate(
            googleContact: google(id: "g3", name: "Carla Fuchs"), decision: .skipIncomplete)

        let draft = ContactImportPlanner.draft(for: createCandidate)
        #expect(draft?.name == "Anna Meyer")
        #expect(draft?.email == "anna@example.com")
        #expect(draft?.organisation == "Musterfirma")
        #expect(draft?.intent == .create)

        #expect(ContactImportPlanner.draft(for: dupCandidate) == nil)
        #expect(ContactImportPlanner.draft(for: skipCandidate) == nil)
    }

    @Test func gemischteListeGibtJedemGenauEineEntscheidung() {
        let existing = [studio(id: "rec1", name: "Anna Meyer", email: "anna@example.com")]
        let contacts = [
            google(id: "g1", name: "Anna Meyer", email: "anna@example.com"),   // Dublette
            google(id: "g2", name: "Bert Weck", email: "bert@example.com"),    // neu
            google(id: "g3", name: "Nur Name"),                                // unvollständig
        ]
        let candidates = ContactImportPlanner.plan(googleContacts: contacts, existing: existing)
        #expect(candidates.count == 3)
        #expect(candidates[0].decision == .duplicate(existingRecordID: "rec1"))
        #expect(candidates[1].decision == .create)
        #expect(candidates[2].decision == .skipIncomplete)
    }
}
