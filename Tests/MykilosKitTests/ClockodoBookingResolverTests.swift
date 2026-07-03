import Testing
import Foundation
@testable import MykilosKit

// MARK: - ClockodoBookingResolver + Customer.clockodoCustomerID (Block E, Härtung 2026-07-01)
struct ClockodoBookingResolverTests {

    private func projekt(_ nr: String, kunde: String) -> Project {
        Project(projectNumber: nr, title: "T-\(nr)", kind: .kitchen, customerNumber: kunde)
    }
    private func kunde(_ nr: String, clockodoID: Int?) -> Customer {
        Customer(customerNumber: nr, name: "Kunde \(nr)", clockodoCustomerID: clockodoID)
    }

    // MARK: Happy path — beide Achsen sauber auflösbar
    @Test func loestBeideAchsenAuf() {
        let projects = [projekt("2026-015", kunde: "K-42")]
        let customers = [kunde("K-42", clockodoID: 9001)]
        let result = ClockodoBookingResolver.resolve(
            projektNummer: "2026-015", kostenstelle: "Kundenberatung",
            projects: projects, customers: customers
        )
        #expect(result == .success(ClockodoBookingResolution(customersID: 9001, servicesID: 1430450)))
    }

    // MARK: Kostenstelle ohne services_id (Bestellungen/Versand) → sicherer Skip
    @Test func leistungOhneServiceIDWirdUebersprungen() {
        let result = ClockodoBookingResolver.resolve(
            projektNummer: "2026-015", kostenstelle: "Bestellungen",
            projects: [projekt("2026-015", kunde: "K-42")],
            customers: [kunde("K-42", clockodoID: 9001)]
        )
        #expect(result == .failure(.kostenstelleOhneServiceID("Bestellungen")))
    }

    @Test func unbekannteKostenstelleWirdUebersprungen() {
        let result = ClockodoBookingResolver.resolve(
            projektNummer: "2026-015", kostenstelle: "GibtEsNicht",
            projects: [projekt("2026-015", kunde: "K-42")],
            customers: [kunde("K-42", clockodoID: 9001)]
        )
        #expect(result == .failure(.unbekannteKostenstelle("GibtEsNicht")))
    }

    // MARK: Ungemappter Kunde → Skip, KEIN Raten einer Ersatz-ID (Fallback-Entscheidung offen)
    @Test func ungemappterKundeWirdUebersprungenStattGeraten() {
        let result = ClockodoBookingResolver.resolve(
            projektNummer: "2026-015", kostenstelle: "Kundenberatung",
            projects: [projekt("2026-015", kunde: "K-99")],
            customers: [kunde("K-99", clockodoID: nil)]   // existiert, aber nicht in Clockodo gemappt
        )
        #expect(result == .failure(.kundeOhneClockodoID("Kunde K-99")))
    }

    @Test func unbekanntesProjektWirdUebersprungen() {
        let result = ClockodoBookingResolver.resolve(
            projektNummer: "2026-999", kostenstelle: "Kundenberatung",
            projects: [projekt("2026-015", kunde: "K-42")],
            customers: [kunde("K-42", clockodoID: 9001)]
        )
        #expect(result == .failure(.projektNichtGefunden("2026-999")))
    }

    @Test func projektOhneKundennummerWirdUebersprungen() {
        let result = ClockodoBookingResolver.resolve(
            projektNummer: "2026-015", kostenstelle: "Kundenberatung",
            projects: [projekt("2026-015", kunde: "")],
            customers: []
        )
        #expect(result == .failure(.projektOhneKunde("2026-015")))
    }

    // MARK: Codable-Rückwärtskompatibilität (bekannte Falle — siehe Memory)
    // Ein ALTER Customer-JSON OHNE clockodoCustomerID muss weiterhin dekodieren
    // (Optional → decodeIfPresent → nil), sonst verschwände beim Update die
    // komplette persistierte Kundenliste.
    @Test func alterCustomerJSONOhneClockodoIDDekodiertZuNil() throws {
        let alterJSON = """
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "customerNumber": "K-1",
          "name": "Altbestand",
          "updatedAt": 760000000
        }
        """
        let decoded = try JSONDecoder().decode(Customer.self, from: Data(alterJSON.utf8))
        #expect(decoded.customerNumber == "K-1")
        #expect(decoded.clockodoCustomerID == nil)
    }

    @Test func customerMitClockodoIDRoundtrip() throws {
        let original = Customer(customerNumber: "K-7", name: "Mit ID", clockodoCustomerID: 12345)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Customer.self, from: data)
        #expect(decoded.clockodoCustomerID == 12345)
    }
}
