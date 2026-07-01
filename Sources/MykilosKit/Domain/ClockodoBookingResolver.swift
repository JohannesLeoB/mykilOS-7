import Foundation

// MARK: - ClockodoBookingResolution
// Das Ergebnis einer erfolgreichen Auflösung: beide Clockodo-Pflicht-IDs stehen fest.
public struct ClockodoBookingResolution: Equatable, Sendable {
    public let customersID: Int
    public let servicesID: Int
    public init(customersID: Int, servicesID: Int) {
        self.customersID = customersID
        self.servicesID = servicesID
    }
}

// MARK: - ClockodoBookingSkipReason
// Warum ein Segment NICHT gebucht werden kann. Jeder Fall ist ein bewusstes,
// sichtbares Überspringen — NIE ein stilles Raten einer falschen ID in echten
// Abrechnungsdaten. Der Aufrufer loggt den Grund und lässt die lokale Buchung
// unberührt stehen.
public enum ClockodoBookingSkipReason: Error, Equatable, Sendable {
    case unbekannteKostenstelle(String)        // Name in keiner Leistungsliste
    case kostenstelleOhneServiceID(String)     // Leistung existiert, services_id fehlt (z. B. Bestellungen/Versand)
    case projektNichtGefunden(String)          // projektNummer in der Registry unbekannt
    case projektOhneKunde(String)              // Projekt hat keine Kundennummer
    case kundeNichtGefunden(String)            // Kundennummer in der Registry unbekannt
    case kundeOhneClockodoID(String)           // Kunde existiert, aber (noch) nicht in Clockodo gemappt

    public var beschreibung: String {
        switch self {
        case .unbekannteKostenstelle(let k):    "Unbekannte Kostenstelle/Leistung: \(k)"
        case .kostenstelleOhneServiceID(let k): "Leistung ohne Clockodo-ID (nicht buchbar): \(k)"
        case .projektNichtGefunden(let p):      "Projekt nicht gefunden: \(p)"
        case .projektOhneKunde(let p):          "Projekt ohne Kundennummer: \(p)"
        case .kundeNichtGefunden(let c):        "Kunde nicht gefunden: \(c)"
        case .kundeOhneClockodoID(let c):       "Kunde ohne Clockodo-ID (nicht gemappt): \(c)"
        }
    }
}

// MARK: - ClockodoBookingResolver
// Reine, testbare Auflösung der beiden Clockodo-Achsen (Block E, Härtung 2026-07-01):
//   • Kostenstelle (= Clockodo-LEISTUNG)  → services_id  (aus Kostenstelle.defaults)
//   • projektNummer → Projekt → Kundennummer → Kunde → customers_id
// Kein Netzwerk, keine Buchung — gibt entweder eine vollständige Auflösung zurück
// oder einen konkreten Skip-Grund. Die Fallback-Frage („ungemappte Kunden auf
// 'Mykilos GmbH intern' buchen?") ist bewusst NICHT hier entschieden — ein
// ungemappter Kunde führt zu `.kundeOhneClockodoID` (Überspringen), nicht zu
// einer geratenen Ersatz-ID.
public enum ClockodoBookingResolver {
    public static func resolve(
        projektNummer: String,
        kostenstelle: String,
        projects: [Project],
        customers: [Customer],
        leistungen: [Kostenstelle] = Kostenstelle.defaults
    ) -> Result<ClockodoBookingResolution, ClockodoBookingSkipReason> {
        // 1. Leistung → services_id
        guard let leistung = leistungen.first(where: { $0.name == kostenstelle }) else {
            return .failure(.unbekannteKostenstelle(kostenstelle))
        }
        guard let servicesID = leistung.clockodoServiceID else {
            return .failure(.kostenstelleOhneServiceID(kostenstelle))
        }
        // 2. Projekt → Kunde → customers_id
        guard let projekt = projects.first(where: { $0.projectNumber == projektNummer }) else {
            return .failure(.projektNichtGefunden(projektNummer))
        }
        let kundenNummer = projekt.customerNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard kundenNummer.isEmpty == false else {
            return .failure(.projektOhneKunde(projektNummer))
        }
        guard let kunde = customers.first(where: { $0.customerNumber == kundenNummer }) else {
            return .failure(.kundeNichtGefunden(kundenNummer))
        }
        guard let customersID = kunde.clockodoCustomerID else {
            return .failure(.kundeOhneClockodoID(kunde.name))
        }
        return .success(ClockodoBookingResolution(customersID: customersID, servicesID: servicesID))
    }
}
