import Testing
import Foundation
@testable import MykilosKit

// Backlog: "ClickUp als Quelle für ProjectKind" — reine Registry-Tests, kein ClickUp/Netzwerk.
struct ClickUpProjektTypRouteTests {

    @Test func defaultRegistryLoestAlleProjectKindFaelleAuf() {
        for kind in ProjectKind.allCases {
            let route = ClickUpProjektTypRouteRegistry.default.routes.first { $0.ziel == kind }
            #expect(route != nil, "ProjectKind \(kind.rawValue) hat keine Default-Route")
        }
    }

    @Test func kuecheMapptAufKitchen() {
        #expect(ClickUpProjektTypRouteRegistry.default.kind(fuerProjekttyp: "Küche") == .kitchen)
    }

    @Test func grossKleinschreibungIstEgal() {
        #expect(ClickUpProjektTypRouteRegistry.default.kind(fuerProjekttyp: "küche") == .kitchen)
        #expect(ClickUpProjektTypRouteRegistry.default.kind(fuerProjekttyp: "KÜCHE") == .kitchen)
    }

    @Test func unbekannterProjekttypLiefertNil() {
        #expect(ClickUpProjektTypRouteRegistry.default.kind(fuerProjekttyp: "Sonstiges") == nil)
    }

    @Test func leererOderFehlenderProjekttypLiefertNil() {
        #expect(ClickUpProjektTypRouteRegistry.default.kind(fuerProjekttyp: "") == nil)
        #expect(ClickUpProjektTypRouteRegistry.default.kind(fuerProjekttyp: nil) == nil)
    }

    @Test func stillgelegteRouteLiefertKeinenTrefferMehr() {
        var registry = ClickUpProjektTypRouteRegistry.default
        registry.routes = registry.routes.map { route in
            var r = route
            if r.ziel == .kitchen { r.aktiv = false }
            return r
        }
        #expect(registry.kind(fuerProjekttyp: "Küche") == nil)
        #expect(registry.kind(fuerProjekttyp: "Licht") == .lighting)   // andere Routen unberührt
    }

    @Test func routeUmlegenAendertNurDieEineZeile() {
        var registry = ClickUpProjektTypRouteRegistry.default
        guard let index = registry.routes.firstIndex(where: { $0.ziel == .kitchen }) else {
            Issue.record("Küche-Route fehlt in .default")
            return
        }
        registry.routes[index] = ClickUpProjektTypRoute(routeID: registry.routes[index].routeID, quelle: "Kitchen", ziel: .kitchen)
        #expect(registry.kind(fuerProjekttyp: "Kitchen") == .kitchen)
        #expect(registry.kind(fuerProjekttyp: "Küche") == nil)          // alter Text greift nicht mehr
        #expect(registry.kind(fuerProjekttyp: "Licht") == .lighting)    // unverändert
    }

    @Test func registryIstCodableRoundtripFaehig() throws {
        let data = try JSONEncoder().encode(ClickUpProjektTypRouteRegistry.default)
        let decoded = try JSONDecoder().decode(ClickUpProjektTypRouteRegistry.self, from: data)
        #expect(decoded.routes == ClickUpProjektTypRouteRegistry.default.routes)
    }
}
