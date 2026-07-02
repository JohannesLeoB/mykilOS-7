import SwiftUI
import AppKit
import MykilosDesign
import MykilosKit

// MARK: - DevCheckoutSheet (Dev-Checkout-Exporter)
//
// Pragmatischer, LOCAL-ONLY Checkout-Dialog für Johannes' Live-Test von Warenkorb-Formen
// VOR der vollen Wirbelsäule-Pipeline (siehe docs/S10_WIRBELSAEULE.md). Öffnet sich sowohl
// vom aktiven Session-Warenkorb (WarenkorbPanel) als auch von jedem bereits gespeicherten
// Warenkorb in der Warenkorb-Liste (WebshopTabs.WarenkorbListeTab) — beide Aufrufer bauen
// hier denselben `DevBasketExport`-Snapshot.
//
// Card→Confirm-Muster: Vorschau (Format + Ziel + JSON) ist IMMER zuerst sichtbar, jede
// Ausgabeart hat einen eigenen expliziten Ausführen-Button. Kein Auto-Fire beim Öffnen.
// Kein Schreiben in Airtable/Drive/sevDesk — ausschließlich lokale Ziele (Zwischenablage,
// Notizen.app, ZIP auf der Festplatte).
@MainActor
struct DevCheckoutSheet: View {
    /// Snapshot der zu exportierenden Positionen — vom Aufrufer bereits aus
    /// WarenkorbState.positionen ODER WarenkorbEintrag.decodedItems() gebaut.
    let quelle: String
    let bezeichnung: String?
    let projekt: String?
    let positionen: [DevBasketExportPosition]
    let summeEKNetto: Double?
    let summeVKNetto: Double?
    let onDismiss: () -> Void

    @State private var ziel: DevExportZiel = .freierExport
    @State private var modus: DevExportModus = .zwischenablage
    @State private var export: DevBasketExport
    @State private var jsonPreview: String = ""
    @State private var previewError: String?
    @State private var actionState: ActionState = .idle

    enum ActionState: Equatable {
        case idle
        case running
        case success(String)
        case failure(String)
    }

    init(
        quelle: String,
        bezeichnung: String? = nil,
        projekt: String? = nil,
        positionen: [DevBasketExportPosition],
        summeEKNetto: Double? = nil,
        summeVKNetto: Double? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.quelle = quelle
        self.bezeichnung = bezeichnung
        self.projekt = projekt
        self.positionen = positionen
        self.summeEKNetto = summeEKNetto
        self.summeVKNetto = summeVKNetto
        self.onDismiss = onDismiss
        _export = State(initialValue: DevBasketExport(
            quelle: quelle,
            bezeichnung: bezeichnung,
            projekt: projekt,
            positionen: positionen,
            summeEKNetto: summeEKNetto,
            summeVKNetto: summeVKNetto
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(MykColor.line.color)

            ScrollView {
                VStack(alignment: .leading, spacing: MykSpace.s6) {
                    hinweisBanner
                    zielPicker
                    modusPicker
                    previewSection
                    actionSection
                }
                .padding(MykSpace.s8)
            }
        }
        .frame(width: 620, height: 680)
        .background(MykColor.paper.color)
        .task { refreshPreview() }
        .onChange(of: ziel) { refreshPreview() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "shippingbox")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.cash.color)
            Text("Dev-Checkout-Exporter")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            Spacer()
            Text("\(positionen.count) Pos.")
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
            Button { onDismiss() } label: {
                Image(systemName: "xmark")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, MykSpace.s8)
        .padding(.top, MykSpace.s8)
        .padding(.bottom, MykSpace.s4)
    }

    private var hinweisBanner: some View {
        HStack(alignment: .top, spacing: MykSpace.s3) {
            Image(systemName: "info.circle")
                .font(.mykCaption)
                .foregroundStyle(MykColor.cash.color)
            Text("Lokaler Dev-Sandbox-Export — keine Live-Anbindung an Airtable, Drive oder sevDesk. "
                 + "Alle Ausgabearten schreiben ausschließlich lokal (Zwischenablage, Notizen.app, ZIP-Datei).")
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MykSpace.s4)
        .background(MykColor.cash.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
    }

    // MARK: - Ziel-Picker (Port)

    private var zielPicker: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text("Ziel-Format")
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
            Picker("Ziel-Format", selection: $ziel) {
                ForEach(DevExportZiel.allCases) { z in
                    Text(z.rawValue).tag(z)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            Text(ziel.vorschauHinweis)
                .font(.mykMono(9))
                .foregroundStyle(MykColor.faint.color)
        }
    }

    // MARK: - Ausgabe-Modus-Picker

    private var modusPicker: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text("Ausgabeart")
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
            Picker("Ausgabeart", selection: $modus) {
                ForEach(DevExportModus.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: modus) { actionState = .idle }
        }
    }

    // MARK: - Vorschau (immer sichtbar, VOR jeder Aktion)

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text("Vorschau (JSON)")
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
            if let previewError {
                Text("Vorschau-Fehler: \(previewError)")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.critical.color)
            } else {
                ScrollView {
                    Text(jsonPreview)
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.ink.color)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(MykSpace.s4)
                }
                .frame(height: 220)
                .background(MykColor.card.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
            }
        }
    }

    // MARK: - Aktion (explizit, kein Auto-Fire)

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            switch actionState {
            case .idle: EmptyView()
            case .running:
                HStack(spacing: MykSpace.s3) {
                    ProgressView()
                    Text("Wird ausgeführt …").font(.mykSmall).foregroundStyle(MykColor.muted.color)
                }
            case .success(let msg):
                statusLine(icon: "checkmark.circle.fill", text: msg, color: .positive)
            case .failure(let msg):
                statusLine(icon: "exclamationmark.triangle.fill", text: msg, color: .critical)
            }

            HStack {
                Spacer()
                Button {
                    runAction()
                } label: {
                    Label(aktionLabel, systemImage: aktionIcon)
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.paper.color)
                        .padding(.horizontal, MykSpace.s5)
                        .padding(.vertical, MykSpace.s3)
                        .background(MykColor.cash.color)
                        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                }
                .buttonStyle(.plain)
                .disabled(actionState == .running || previewError != nil)
            }
        }
    }

    private func statusLine(icon: String, text: String, color: MykColor) -> some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: icon).foregroundStyle(color.color)
            Text(text).font(.mykSmall).foregroundStyle(color.color)
        }
        .padding(MykSpace.s4)
        .background(color.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
    }

    private var aktionLabel: String {
        switch modus {
        case .zwischenablage: "In Zwischenablage kopieren"
        case .notiz: "Als Notiz sichern"
        case .zip: "Als ZIP exportieren …"
        }
    }

    private var aktionIcon: String {
        switch modus {
        case .zwischenablage: "doc.on.clipboard"
        case .notiz: "note.text"
        case .zip: "archivebox"
        }
    }

    // MARK: - Vorschau-Aufbau

    /// Jeder Export bekommt eine FRISCHE exportID — auch beim Ziel-Wechsel, damit die
    /// exportID nie über zwei verschiedene Vorschauen hinweg wiederverwendet wird.
    private func refreshPreview() {
        let neuerExport = DevBasketExport(
            quelle: quelle,
            bezeichnung: bezeichnung,
            projekt: projekt,
            positionen: positionen,
            summeEKNetto: summeEKNetto,
            summeVKNetto: summeVKNetto
        )
        export = neuerExport
        do {
            jsonPreview = try neuerExport.prettyJSON()
            previewError = nil
        } catch {
            previewError = error.localizedDescription
            jsonPreview = ""
        }
    }

    // MARK: - Ausgabe-Aktionen

    private func runAction() {
        actionState = .running
        switch modus {
        case .zwischenablage:
            copyToClipboard()
        case .notiz:
            saveAsNote()
        case .zip:
            exportAsZip()
        }
    }

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let ok = pasteboard.setString(jsonPreview, forType: .string)
        if ok {
            actionState = .success("In Zwischenablage kopiert (Export-ID \(export.exportID)).")
        } else {
            actionState = .failure("Zwischenablage konnte nicht beschrieben werden.")
        }
    }

    private func saveAsNote() {
        let titel = (bezeichnung?.isEmpty == false ? bezeichnung! : "Warenkorb-Export") + " · \(export.exportID)"
        // AppleScript-Anführungszeichen/Backslashes im Body müssen escaped werden, sonst
        // bricht das generierte Skript. Titel ebenso.
        let escapedTitle = escapeForAppleScript(titel)
        let escapedBody = escapeForAppleScript(jsonPreview)
        let script = """
        tell application "Notes"
            tell account "iCloud"
                make new note at folder "Notizen" with properties {name:"\(escapedTitle)", body:"\(escapedBody)"}
            end tell
        end tell
        """
        guard let appleScript = NSAppleScript(source: script) else {
            actionState = .failure("AppleScript konnte nicht erstellt werden.")
            return
        }
        var errorInfo: NSDictionary?
        appleScript.executeAndReturnError(&errorInfo)
        if let errorInfo {
            // Häufigster Fall: Automatisierungs-Berechtigung noch nicht erteilt (erster Aufruf).
            let message = (errorInfo[NSAppleScript.errorMessage] as? String)
                ?? "Unbekannter AppleScript-Fehler (\(errorInfo))"
            actionState = .failure("Notiz konnte nicht erstellt werden: \(message)")
            return
        }
        actionState = .success("Notiz „\(titel)" + "“ in Notizen.app angelegt.")
    }

    private func escapeForAppleScript(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private func exportAsZip() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Ordner wählen"
        panel.message = "Zielordner für den ZIP-Export wählen"

        guard panel.runModal() == .OK, let zielOrdner = panel.url else {
            actionState = .idle
            return
        }

        let dateiname = "warenkorb-export-\(export.exportID)"
        let tempDir = FileManager.default.temporaryDirectory
        let tempJSONURL = tempDir.appendingPathComponent("\(dateiname).json")
        let zielZipURL = zielOrdner.appendingPathComponent("\(dateiname).zip")

        do {
            try jsonPreview.write(to: tempJSONURL, atomically: true, encoding: .utf8)
        } catch {
            actionState = .failure("JSON-Datei konnte nicht geschrieben werden: \(error.localizedDescription)")
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = tempDir
        process.arguments = ["-j", zielZipURL.path, tempJSONURL.path]

        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            try? FileManager.default.removeItem(at: tempJSONURL)
            actionState = .failure("ZIP-Prozess konnte nicht gestartet werden: \(error.localizedDescription)")
            return
        }

        // Aufräumen: temporäre JSON immer entfernen, unabhängig vom Ausgang.
        try? FileManager.default.removeItem(at: tempJSONURL)

        if process.terminationStatus != 0 {
            let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let errText = String(data: errData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? "unbekannter Fehler"
            actionState = .failure("ZIP-Export fehlgeschlagen (Code \(process.terminationStatus)): \(errText)")
            return
        }

        actionState = .success("ZIP-Datei erstellt: \(zielZipURL.path)")
    }
}
