import Testing
import Foundation
import CoreBluetooth
@testable import MykilosServices
@testable import MykilosKit

// Aufmaß-Widget-Plan: nur die REINE Logik (Zustandsüberführung, Payload-Parsing) ist ohne
// echtes/gemocktes CoreBluetooth-Gerät sinnvoll testbar — siehe Kommentar in
// LeicaDistoBluetoothAdapter.swift zum Stand der Portierung.
struct LeicaDistoStatusReducerTests {

    @Test func poweredOnFuehrtZumWeiterScannen() {
        #expect(LeicaDistoStatusReducer.fuerManagerState(.poweredOn) == .weiterScannen)
    }

    @Test func poweredOffMeldetFehler() {
        #expect(LeicaDistoStatusReducer.fuerManagerState(.poweredOff) == .melden(.fehler("Bluetooth ist ausgeschaltet")))
    }

    @Test func unauthorizedMeldetFehler() {
        #expect(LeicaDistoStatusReducer.fuerManagerState(.unauthorized) == .melden(.fehler("Bluetooth-Zugriff nicht erlaubt")))
    }

    @Test func unsupportedMeldetFehler() {
        #expect(LeicaDistoStatusReducer.fuerManagerState(.unsupported) == .melden(.fehler("Bluetooth wird nicht unterstützt")))
    }

    @Test func unbekannterZwischenzustandMeldetSucht() {
        #expect(LeicaDistoStatusReducer.fuerManagerState(.unknown) == .melden(.sucht))
        #expect(LeicaDistoStatusReducer.fuerManagerState(.resetting) == .melden(.sucht))
    }

    @Test func meterAusRohwertParstLittleEndianFloat32() {
        // 1.5 Meter als Little-Endian Float32.
        let wert: Float = 1.5
        let daten = withUnsafeBytes(of: wert.bitPattern.littleEndian) { Data($0) }
        #expect(LeicaDistoStatusReducer.meterAusRohwert(daten) == 1.5)
    }

    @Test func zuKurzeDatenLiefernNil() {
        #expect(LeicaDistoStatusReducer.meterAusRohwert(Data([1, 2, 3])) == nil)
    }

    @Test func negativerWertWirdVerworfen() {
        let wert: Float = -1.0
        let daten = withUnsafeBytes(of: wert.bitPattern.littleEndian) { Data($0) }
        #expect(LeicaDistoStatusReducer.meterAusRohwert(daten) == nil)
    }
}

// MARK: - FakeLaserAdapter (für spätere Canvas-/Widget-Entwicklung ohne echte Hardware)
struct FakeLaserAdapter: LaserMeasuring {
    let status: AsyncStream<LaserVerbindungsStatus>
    let letztesMass: AsyncStream<Double>
    private let statusContinuation: AsyncStream<LaserVerbindungsStatus>.Continuation
    private let massContinuation: AsyncStream<Double>.Continuation

    init() {
        var statusCont: AsyncStream<LaserVerbindungsStatus>.Continuation!
        status = AsyncStream { statusCont = $0 }
        statusContinuation = statusCont
        var massCont: AsyncStream<Double>.Continuation!
        letztesMass = AsyncStream { massCont = $0 }
        massContinuation = massCont
    }

    func verbinde() async throws {
        statusContinuation.yield(.gekoppelt(geraetename: "Fake-Disto"))
    }

    func trenne() async {
        statusContinuation.yield(.getrennt)
    }

    func simuliereMessung(_ meter: Double) {
        massContinuation.yield(meter)
    }
}

struct FakeLaserAdapterTests {
    @Test func verbindeMeldetGekoppeltStatus() async throws {
        let adapter = FakeLaserAdapter()
        async let ersterStatus = adapter.status.first { _ in true }
        try await adapter.verbinde()
        #expect(await ersterStatus == .gekoppelt(geraetename: "Fake-Disto"))
    }

    @Test func simulierteMessungLandetImStream() async throws {
        let adapter = FakeLaserAdapter()
        async let ersterWert = adapter.letztesMass.first { _ in true }
        adapter.simuliereMessung(2.35)
        #expect(await ersterWert == 2.35)
    }
}
