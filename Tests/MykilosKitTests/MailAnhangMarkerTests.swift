import Testing
import Foundation
@testable import MykilosKit

// Ordner-Schema-Editor-Plan, Abschnitt "Mail-Anhang → Marker → Unterordner": reine Registry-/
// Domain-Tests, kein Drive/Netzwerk. Gleiches Muster wie ClickUpFieldRouteRegistry.
struct MailAnhangMarkerTests {

    @Test func defaultRegistryLoestJedenMarkerAufEinenAktivenSlotAuf() {
        for marker in MailAnhangMarker.allCases {
            let route = MailMarkerRouteRegistry.default.route(fuer: marker)
            #expect(route != nil, "Marker \(marker.rawValue) hat keine Default-Route")
            #expect(route?.aktiv == true)
        }
    }

    @Test func abUndZeichnungMappenAufDiePlanBeispiele() {
        #expect(MailMarkerRouteRegistry.default.route(fuer: .auftragsbestaetigung)?.ziel == .angeboteEingehend)
        #expect(MailMarkerRouteRegistry.default.route(fuer: .zeichnung)?.ziel == .cad)
    }

    @Test func stillgelegteRouteLiefertKeinenVorschlagMehr() {
        var registry = MailMarkerRouteRegistry.default
        registry.routes = registry.routes.map { route in
            var r = route
            if r.marker == .rechnung { r.aktiv = false }
            return r
        }
        #expect(registry.route(fuer: .rechnung) == nil)
        // Andere Marker bleiben unberührt.
        #expect(registry.route(fuer: .auftragsbestaetigung) != nil)
    }

    @Test func routeUmlegenAendertNurDieEineZeileNichtDenRest() {
        var registry = MailMarkerRouteRegistry.default
        guard let index = registry.routes.firstIndex(where: { $0.marker == .rechnung }) else {
            Issue.record("Rechnung-Route fehlt in .default")
            return
        }
        registry.routes[index] = MailMarkerRoute(routeID: registry.routes[index].routeID, marker: .rechnung, ziel: .infos)
        #expect(registry.route(fuer: .rechnung)?.ziel == .infos)
        #expect(registry.route(fuer: .auftragsbestaetigung)?.ziel == .angeboteEingehend)   // unverändert
    }

    @Test func registryIstCodableRoundtripFaehig() throws {
        let data = try JSONEncoder().encode(MailMarkerRouteRegistry.default)
        let decoded = try JSONDecoder().decode(MailMarkerRouteRegistry.self, from: data)
        #expect(decoded.routes == MailMarkerRouteRegistry.default.routes)
    }
}
