import SwiftUI
import AVFoundation
import AppKit
import MykilosKit
import MykilosDesign

// MARK: - BarcodeWidget
// Kamera-Barcode/QR-Scanner auf der Übersichtsseite. Liest einen Artikel-/
// Produkt-Code über die Mac-Kamera ein — reine Erfassung, kein Schreiben.
// v1: Scan → Code anzeigen + auswählbar. Artikel-Katalog-Lookup ist bewusst v2.
// Kamera-Aufnahme in BarcodeScanner.swift (AVCaptureSession + Vision).
//
// Kamera-Berechtigung wird IM Widget behandelt (nicht über die generische
// permissionRequired-Chrome, die für API-Integrationen gedacht ist): bei
// verweigerter/eingeschränkter Kamera eine kamera-spezifische Anleitung +
// Direktknopf in die Systemeinstellungen. Braucht das Entitlement
// com.apple.security.device.camera (Hardened Runtime) — siehe script/mykilOS.entitlements.
public struct BarcodeWidget: View {
    @State private var loader = BarcodeScanLoader()
    @State private var showScanner = false
    @State private var showConfirm = false

    public init() {}

    public var body: some View {
        WidgetContainer(kind: .barcode, sourceLabel: sourceLabel, projectID: "home") {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                header
                content
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
    private var content: some View {
        if loader.accessDenied {
            permissionGuidance
        } else {
            scanContent
        }
    }

    // Kamera vom System verweigert/eingeschränkt: klare Anleitung + Direktweg.
    private var permissionGuidance: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            Text("Kamera-Zugriff nötig")
                .font(.mykBody).foregroundStyle(MykColor.ink.color)
            Text("Erlaube mykilOS die Kamera in den macOS-Systemeinstellungen, dann zurück ins Widget.")
                .font(.mykSmall).foregroundStyle(MykColor.muted.color)
            Button(action: openCameraSettings) {
                HStack(spacing: MykSpace.s3) {
                    Image(systemName: "gearshape")
                    Text("Systemeinstellungen öffnen")
                }
                .font(.mykCaption).foregroundStyle(MykColor.drive.color)
            }
            .buttonStyle(.plain)
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
                // QR mit URL-Inhalt (2026-07-06): klickbaren Link anbieten. Bewusst
                // ein expliziter Button (kein Auto-Open) — gescannte Codes können auf
                // beliebige Ziele zeigen; der Nutzer sieht die volle URL oben + im
                // Hover-Tooltip und öffnet selbst. Nur http/https.
                if let link = scannedLink {
                    Button(action: { NSWorkspace.shared.open(link) }) {
                        HStack(spacing: MykSpace.s3) {
                            Image(systemName: "safari")
                            Text("Link öffnen")
                        }
                        .font(.mykCaption).foregroundStyle(MykColor.drive.color)
                    }
                    .buttonStyle(.plain)
                    .help(link.absoluteString)
                }
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

    // Gescannter Code als http/https-URL (QR-Link), sonst nil. Trimmt Whitespace;
    // akzeptiert nur die zwei Web-Schemata — kein file:/javascript:/custom-scheme.
    private var scannedLink: URL? {
        guard let raw = loader.lastCode?.trimmingCharacters(in: .whitespacesAndNewlines),
              raw.isEmpty == false,
              let url = URL(string: raw),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host?.isEmpty == false else { return nil }
        return url
    }

    private func openCameraSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
            NSWorkspace.shared.open(url)
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
                    if granted { showScanner = true } else { loader.refreshAuthorization() }
                }
            }
        case .denied, .restricted:
            loader.refreshAuthorization()   // schaltet auf die Anleitung um
        @unknown default:
            break
        }
    }
}

// MARK: - BarcodeScanLoader
@MainActor
@Observable
private final class BarcodeScanLoader {
    private(set) var accessDenied = false
    private(set) var lastCode: String?

    func refreshAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied, .restricted: accessDenied = true
        default:                   accessDenied = false
        }
    }

    func record(_ code: String) { lastCode = code }
}
