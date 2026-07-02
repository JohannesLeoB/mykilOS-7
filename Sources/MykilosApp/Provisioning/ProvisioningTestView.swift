import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - ProvisioningTestView
// mykilOS 8, Block D (S4): die Live-Verifikations-Oberfläche für die Projekt-Geburt in der
// TEST-Sandbox. Bewusst NÜCHTERN + mit klarer TEST-Warnung — schreibt ECHT (Drive-Ordner +
// Airtable-Record), aber AUSSCHLIESSLICH in die mit dir abgestimmte Sandbox (driveParent +
// TEST-Tabelle). Idempotent: ein zweiter Lauf erzeugt nichts Neues.
struct ProvisioningTestView: View {
    @Environment(AppState.self) private var appState

    @State private var driveParentID = ""
    @State private var airtableBaseID = ""
    @State private var airtableTabelle = ""
    // Studio-OS-Rollout (2026-07-02): vorausgefüllt mit der `_TEST_PROVISIONING`-Isolations-
    // ebene im echten ClickUp-Testspace. Leerfeld = Schritt 3 wird übersprungen (kein Zwang).
    @State private var clickUpFolderID = AppState.clickUpTestProvisioningFolderID
    @State private var kundeName = "Test Schmidt"
    @State private var kdnr = "TEST-K-1"
    @State private var strasse = "Heimhuder"
    @State private var hausnummer = "8"
    @State private var laeuft = false
    @State private var ergebnis: String?
    @State private var fehler: String?

    private var bereit: Bool {
        driveParentID.isEmpty == false && airtableBaseID.isEmpty == false
            && airtableTabelle.isEmpty == false && kundeName.isEmpty == false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            HStack(spacing: 8) {
                Image(systemName: "shippingbox").foregroundStyle(MykColor.tasks.color)
                Text("Projekt-Geburt — TEST-Sandbox").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
            }
            Text("Schreibt ECHT in Drive (_TEST_PROVISIONING) + Airtable (TEST-markiert), aber NUR in die unten genannten Sandbox-Ziele. Idempotent · reversibel · ein Audit-Eintrag.")
                .font(.mykMono(10)).foregroundStyle(MykColor.muted.color).fixedSize(horizontal: false, vertical: true)

            // Sandbox-Ziele (von Johannes)
            gruppe("Sandbox-Ziele") {
                feld("Drive-Parent-Ordner-ID", text: $driveParentID)
                feld("Airtable-Base-ID", text: $airtableBaseID)
                feld("Airtable-TEST-Tabelle", text: $airtableTabelle)
                feld("ClickUp-TEST-Ordner-ID (leer = überspringen)", text: $clickUpFolderID)
            }
            // Test-Projekt
            gruppe("Test-Projekt") {
                feld("Kunde-Name", text: $kundeName)
                feld("Kdnr", text: $kdnr)
                HStack(spacing: MykSpace.s3) {
                    feld("Straße", text: $strasse)
                    feld("Hausnr", text: $hausnummer).frame(width: 90)
                }
            }

            HStack(spacing: MykSpace.s4) {
                Button {
                    Task { await gebaere() }
                } label: {
                    HStack(spacing: 6) {
                        if laeuft { ProgressView().controlSize(.small) }
                        Text(laeuft ? "Provisioniere…" : "Test-Projekt gebären")
                            .font(.mykSmall).foregroundStyle(.white)
                    }
                    .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s3)
                    .background(bereit ? MykColor.tasks.color : MykColor.faint.color)
                    .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                }
                .buttonStyle(.plain).disabled(!bereit || laeuft)
                Text("Modus: \(appState.provisioningMode.mode.rawValue.uppercased())")
                    .font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
            }

            if let ergebnis {
                Text(ergebnis).font(.mykMono(10)).foregroundStyle(MykColor.positive.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let fehler {
                Text(fehler).font(.mykMono(10)).foregroundStyle(MykColor.critical.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(MykSpace.s7)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.lg).stroke(MykColor.tasks.color.opacity(0.4), lineWidth: 1))
    }

    private func gebaere() async {
        laeuft = true; ergebnis = nil; fehler = nil
        do {
            let r = try await appState.gebaereTestProjekt(
                kundeName: kundeName, kdnr: kdnr,
                strasse: strasse.isEmpty ? nil : strasse,
                hausnummer: hausnummer.isEmpty ? nil : hausnummer, ort: nil,
                driveParentID: driveParentID, airtableBaseID: airtableBaseID, airtableTabelle: airtableTabelle,
                clickUpFolderID: clickUpFolderID.isEmpty ? nil : clickUpFolderID)
            ergebnis = "✓ \(r.projektnummer) · Status \(r.status.rawValue)\nDrive-Ordner: \(r.driveProjektOrdnerID ?? "?")\nAirtable: \(r.airtableRecordID ?? "?") · \(r.driveUnterordnerIDs.count) Unterordner\nClickUp-Liste: \(r.clickUpListID ?? "übersprungen")"
        } catch {
            fehler = "✗ \(String(describing: error))"
        }
        laeuft = false
    }

    private func gruppe<Content: View>(_ titel: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            Text(titel.uppercased()).font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
            content()
        }
    }
    private func feld(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.mykMono(8)).foregroundStyle(MykColor.faint.color)
            TextField(label, text: text).textFieldStyle(.roundedBorder).font(.mykSmall)
        }
    }
}
