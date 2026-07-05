import SwiftUI
import AVFoundation
import MykilosKit
import MykilosDesign

// MARK: - BarcodeWidget
// Kamera-Barcode/QR-Scanner auf der Übersichtsseite. Liest einen Artikel-/
// Produkt-Code über die Mac-Kamera ein — reine Erfassung, kein Schreiben.
// v1: Scan → Code anzeigen + auswählbar. Artikel-Katalog-Lookup ist bewusst v2.
// Kamera-Aufnahme in BarcodeScanner.swift (AVCaptureSession + Vision); der
// eigentliche Scan ist ein Live-Gerät-Check (Kamera nicht unit-testbar).
public struct BarcodeWidget: View {
    @State private var loader = BarcodeScanLoader()
    @State private var showScanner = false
    @State private var showConfirm = false

    public init() {}

    public var body: some View {
        WidgetContainer(
            kind: .barcode,
            sourceLabel: sourceLabel,
            renderState: loader.renderState,
            projectID: "home"
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                header
                scanContent
            }
        }
        .task { loader.refreshAuthorization() }
        .sheet(isPresented: $showScanner) {
            BarcodeScannerSheet(
                onCode: { code in loader.record(code); showScanner = false },
                onClose: { showScanner = false }
            )
        }
        .confirmationDialog("Kamera für den Barcode-Scan öffnen?",
                            isPresented: $showConfirm, titleVisibility: .visible) {
            Button("Kamera öffnen") { requestScan() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Es werden keine Bilder gespeichert oder gesendet.")
        }
    }

    private var sourceLabel: String {
        if let code = loader.lastCode { "KAMERA  ·  \(code)" } else { "KAMERA · BARCODE" }
    }

    private var header: some View {
        HStack {
            SourceChip(kind: .barcode)
            Text("Barcode-Scanner").mykWidgetTitle()
            Spacer()
        }
    }

    @ViewBuilder
    private var scanContent: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            if let code = loader.lastCode {
                Text("Zuletzt gescannt")
                    .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                Text(code)
                    .font(.mykBody).foregroundStyle(MykColor.ink.color)
                    .textSelection(.enabled).lineLimit(2)
            } else {
                Text("Artikel-Barcode oder QR-Code mit der Kamera einlesen.")
                    .font(.mykSmall).foregroundStyle(MykColor.muted.color)
            }
            Button(action: { showConfirm = true }) {
                HStack(spacing: MykSpace.s3) {
                    Image(systemName: "barcode.viewfinder")
                    Text(loader.lastCode == nil ? "Scan starten" : "Erneut scannen")
                }
                .font(.mykCaption)
                .foregroundStyle(MykColor.drive.color)
            }
            .buttonStyle(.plain)
        }
    }

    // Fragt Kamera-Berechtigung an und öffnet bei Erlaubnis das Scanner-Sheet.
    private func requestScan() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showScanner = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted { showScanner = true } else { loader.markDenied() }
                }
            }
        case .denied, .restricted:
            loader.markDenied()
        @unknown default:
            break
        }
    }
}

// MARK: - BarcodeScanLoader
@MainActor
@Observable
private final class BarcodeScanLoader {
    private(set) var renderState: WidgetRenderState = .content
    private(set) var lastCode: String?

    func refreshAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized, .notDetermined: renderState = .content
        case .denied, .restricted:        renderState = .permissionRequired
        @unknown default:                 renderState = .content
        }
    }

    func record(_ code: String) {
        lastCode = code
        renderState = .content
    }

    func markDenied() {
        renderState = .permissionRequired
    }
}
