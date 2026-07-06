import SwiftUI
import AppKit
import MykilosDesign
import MykilosServices

// MARK: - MykInviteSectionView (Onboarding-Plan Ebene 2)
// Admin: "Kollegen einladen" → .mykinvite-Datei (verschlüsselt) speichern, Passwort separat
// (mündlich/Signal) weitergeben. Neuer User: "Einladung öffnen" → Datei + Passwort → Airtable-
// Zugangsdaten landen automatisch im Keychain (kein Klartext-Formular nötig).
struct MykInviteSectionView: View {
    let airtableAuth: AirtableAuthService

    @State private var modus: Modus?
    @State private var passwort = ""
    @State private var ergebnis: String?
    @State private var istFehler = false

    private enum Modus: Identifiable {
        case erstellen(Data)
        case oeffnen(Data)
        var id: String {
            switch self {
            case .erstellen: return "erstellen"
            case .oeffnen: return "oeffnen"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Kollegen einladen").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
                Text("Teilt die geteilten Airtable-Zugangsdaten als passwortgeschützte Datei. "
                     + "Datei per Mail, Passwort über einen getrennten Kanal (mündlich/Signal).")
                    .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: MykSpace.s3) {
                Button("Einladung erstellen …") { einladungErstellenStarten() }
                    .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.drive.color)
                Button("Einladung öffnen …") { einladungOeffnenStarten() }
                    .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.drive.color)
            }
            if let ergebnis {
                Label(ergebnis, systemImage: istFehler ? "exclamationmark.triangle" : "checkmark.circle.fill")
                    .font(.mykMono(9.5))
                    .foregroundStyle(istFehler ? MykColor.critical.color : MykColor.positive.color)
            }
        }
        .sheet(item: $modus) { modus in
            passwortSheet(fuer: modus)
        }
    }

    // MARK: Passwort-Sheet (gemeinsam für Erstellen/Öffnen)

    @ViewBuilder
    private func passwortSheet(fuer modus: Modus) -> some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            Text(istErstellenModus(modus) ? "Passwort für die Einladung" : "Passwort der Einladung")
                .font(.mykHeadline).foregroundStyle(MykColor.ink.color)
            SecureField("Passwort", text: $passwort)
                .textFieldStyle(.roundedBorder)
                .frame(width: 280)
            HStack(spacing: MykSpace.s3) {
                Button("Abbrechen") { self.modus = nil; passwort = "" }
                    .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.muted.color)
                Button(istErstellenModus(modus) ? "Speichern …" : "Übernehmen") {
                    weiterMit(modus)
                }
                .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.paper.color)
                .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s2)
                .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.drive.color))
                .disabled(passwort.isEmpty)
            }
        }
        .padding(MykSpace.s6)
        .frame(width: 360)
    }

    private func istErstellenModus(_ modus: Modus) -> Bool {
        if case .erstellen = modus { return true }
        return false
    }

    // MARK: Aktionen

    private func einladungErstellenStarten() {
        ergebnis = nil
        modus = .erstellen(Data())   // Platzhalter — die echten Bytes entstehen erst nach Passwort-Eingabe
    }

    private func einladungOeffnenStarten() {
        ergebnis = nil
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = []
        panel.allowsOtherFileTypes = true
        panel.prompt = "Einladung wählen"
        panel.message = "Eine .mykinvite-Datei wählen"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            modus = .oeffnen(try Data(contentsOf: url))
        } catch {
            ergebnis = "Datei konnte nicht gelesen werden: \(error.localizedDescription)"
            istFehler = true
        }
    }

    private func weiterMit(_ modus: Modus) {
        switch modus {
        case .erstellen:
            do {
                let daten = try airtableAuth.einladungErstellen(passwort: passwort)
                if speichernAlsDatei(daten) {
                    ergebnis = "Einladung erstellt. Passwort separat weitergeben."
                    istFehler = false
                }
                // Abbruch im Speichern-Dialog → kein Ergebnis-Text, kein Fehler (Nutzer hat bewusst abgebrochen).
            } catch {
                ergebnis = error.localizedDescription
                istFehler = true
            }
        case .oeffnen(let daten):
            do {
                try airtableAuth.einladungOeffnen(daten: daten, passwort: passwort)
                ergebnis = "Zugangsdaten übernommen."
                istFehler = false
            } catch {
                ergebnis = error.localizedDescription
                istFehler = true
            }
        }
        self.modus = nil
        passwort = ""
    }

    /// Liefert `true`, wenn tatsächlich gespeichert wurde (Abbruch/Fehler → `false`, Fehler
    /// zusätzlich sichtbar über `ergebnis`/`istFehler`).
    private func speichernAlsDatei(_ daten: Data) -> Bool {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "kollege.mykinvite"
        panel.prompt = "Speichern"
        panel.message = "Einladungsdatei speichern"
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        do {
            try daten.write(to: url)
            return true
        } catch {
            ergebnis = "Speichern fehlgeschlagen: \(error.localizedDescription)"
            istFehler = true
            return false
        }
    }
}
