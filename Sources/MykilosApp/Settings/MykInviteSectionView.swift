import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - MykInviteSectionView (Onboarding-Plan Ebene 2, Schlüsselbund-Ausbau 2026-07-07)
// Admin: "Kollegen einladen" → ein verschlüsselter Schlüsselbund (.mykinvite) mit den
// AUSGEWÄHLTEN geteilten Team-Keys (Airtable + Google-OAuth-Client-Config + Team-Claude-Key).
// Datei per Mail, Passwort über einen getrennten Kanal (mündlich/Signal). Neuer User: die
// Datei im Onboarding oder hier öffnen → alle Team-Keys landen im Keychain, danach nur noch
// der eigene Google-Login. Persönliches (eigener Google-Login, Clockodo) reist NIE mit.
struct MykInviteSectionView: View {
    @Environment(AppState.self) private var appState

    @State private var zeigeErstellen = false
    @State private var ergebnis: String?
    @State private var istFehler = false

    // Erstellen-Formular
    @State private var eingeladeneEmail = ""
    @State private var eingeladenerName = ""
    @State private var mitAirtable = true
    @State private var mitGoogleClient = true
    @State private var mitClaude = true
    @State private var erstellPasswort = ""

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Kollegen einladen").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
                Text("Ein verschlüsselter Schlüsselbund mit den geteilten Team-Zugangsdaten. "
                     + "Datei per Mail, Passwort über einen getrennten Kanal (mündlich/Signal). "
                     + "Der Kollege macht danach nur noch seinen eigenen Google-Login.")
                    .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: MykSpace.s3) {
                Button("Einladung erstellen …") { erstellenStarten() }
                    .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.drive.color)
                Button("Einladung öffnen …") { oeffnenStarten() }
                    .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.drive.color)
            }
            if let ergebnis {
                Label(ergebnis, systemImage: istFehler ? "exclamationmark.triangle" : "checkmark.circle.fill")
                    .font(.mykMono(9.5))
                    .foregroundStyle(istFehler ? MykColor.critical.color : MykColor.positive.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .sheet(isPresented: $zeigeErstellen) { erstellenSheet }
    }

    // MARK: Erstellen-Sheet

    private var erstellenSheet: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Einladung erstellen").font(.mykHeadline).foregroundStyle(MykColor.ink.color)

            feldGruppe("Für wen? (optional)") {
                TextField("E-Mail des Kollegen", text: $eingeladeneEmail).textFieldStyle(.roundedBorder)
                TextField("Name (optional)", text: $eingeladenerName).textFieldStyle(.roundedBorder)
            }

            feldGruppe("Was mitgeben") {
                keyToggle("Airtable (Projekt-/Kontaktdaten)", isOn: $mitAirtable, verbunden: airtableVerbunden)
                keyToggle("Google-Login-Config (Client-ID/-Secret)", isOn: $mitGoogleClient, verbunden: googleClientVorhanden)
                keyToggle("Claude-Key (Team)", isOn: $mitClaude, verbunden: claudeVerbunden)
            }

            feldGruppe("Passwort (über getrennten Kanal weitergeben)") {
                HStack(spacing: MykSpace.s3) {
                    TextField("Passwort", text: $erstellPasswort).textFieldStyle(.roundedBorder)
                    Button("Generieren") { erstellPasswort = MykInvitePasswordGenerator.generate() }
                        .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.drive.color)
                }
                Text("Empfehlung: \"Generieren\" für ein starkes Zufallspasswort. Datei per Mail, "
                     + "dieses Passwort getrennt (mündlich/Signal). Wird nirgends gespeichert.")
                    .font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: MykSpace.s3) {
                Spacer()
                Button("Abbrechen") { zeigeErstellen = false }
                    .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.muted.color)
                Button("Speichern …") { erstellenUndSpeichern() }
                    .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.paper.color)
                    .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s2)
                    .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.drive.color))
                    .disabled(speichernDeaktiviert)
            }
        }
        .padding(MykSpace.s6)
        .frame(width: 440)
    }

    // MARK: Verbindungs-Status

    private var airtableVerbunden: Bool { appState.airtableAuth.status == .connected }
    private var claudeVerbunden: Bool { appState.claudeAuth.status == .connected }
    private var googleClientVorhanden: Bool {
        ((try? appState.googleAuth.storedClientID()) ?? nil)?.isEmpty == false
    }

    /// Mindestens ein tatsächlich verbundener Key ausgewählt + ein Passwort gesetzt.
    private var speichernDeaktiviert: Bool {
        let ausgewaehlt = (mitAirtable && airtableVerbunden)
            || (mitGoogleClient && googleClientVorhanden)
            || (mitClaude && claudeVerbunden)
        return ausgewaehlt == false || erstellPasswort.isEmpty
    }

    private var gewaehlterInhalt: MykInviteInhalt {
        var inhalt: MykInviteInhalt = []
        if mitAirtable && airtableVerbunden { inhalt.insert(.airtable) }
        if mitGoogleClient && googleClientVorhanden { inhalt.insert(.googleClient) }
        if mitClaude && claudeVerbunden { inhalt.insert(.claude) }
        return inhalt
    }

    // MARK: Aktionen

    private func erstellenStarten() {
        ergebnis = nil
        erstellPasswort = MykInvitePasswordGenerator.generate()   // gleich stark vorbelegt
        mitAirtable = airtableVerbunden
        mitGoogleClient = googleClientVorhanden
        mitClaude = claudeVerbunden
        zeigeErstellen = true
    }

    private func erstellenUndSpeichern() {
        do {
            let daten = try appState.einladungErstellen(
                inhalt: gewaehlterInhalt,
                eingeladeneEmail: eingeladeneEmail.isEmpty ? nil : eingeladeneEmail,
                eingeladenerName: eingeladenerName.isEmpty ? nil : eingeladenerName,
                passwort: erstellPasswort
            )
            if speichernAlsDatei(daten) {
                ergebnis = "Einladung erstellt. Passwort separat weitergeben."
                istFehler = false
                zeigeErstellen = false
            }
            // Abbruch im Speichern-Dialog → Sheet bleibt offen, kein Fehler.
        } catch {
            ergebnis = error.localizedDescription
            istFehler = true
            zeigeErstellen = false
        }
    }

    private func oeffnenStarten() {
        ergebnis = nil
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsOtherFileTypes = true
        panel.prompt = "Einladung wählen"
        panel.message = "Eine .mykinvite-Datei wählen"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let daten: Data
        do {
            daten = try Data(contentsOf: url)
        } catch {
            ergebnis = "Datei konnte nicht gelesen werden: \(error.localizedDescription)"
            istFehler = true
            return
        }
        passwortAbfrageUndOeffnen(daten)
    }

    /// Kleiner modaler Passwort-Prompt via NSAlert + Secure-Textfeld (kein zweites SwiftUI-Sheet).
    private func passwortAbfrageUndOeffnen(_ daten: Data) {
        let alert = NSAlert()
        alert.messageText = "Passwort der Einladung"
        alert.informativeText = "Das Passwort, das dir über den getrennten Kanal mitgeteilt wurde."
        alert.addButton(withTitle: "Übernehmen")
        alert.addButton(withTitle: "Abbrechen")
        let feld = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        alert.accessoryView = feld
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        do {
            let payload = try appState.einladungOeffnen(daten: daten, passwort: feld.stringValue)
            let fuer = payload.eingeladenerName ?? payload.eingeladeneEmail
            ergebnis = fuer.map { "Zugangsdaten übernommen (Einladung für \($0))." } ?? "Zugangsdaten übernommen."
            istFehler = false
        } catch {
            ergebnis = error.localizedDescription
            istFehler = true
        }
    }

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

    // MARK: Bausteine

    private func feldGruppe<Inhalt: View>(_ titel: String, @ViewBuilder _ inhalt: () -> Inhalt) -> some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text(titel.uppercased()).font(.mykMono(9)).tracking(0.5).foregroundStyle(MykColor.muted.color)
            inhalt()
        }
    }

    private func keyToggle(_ titel: String, isOn: Binding<Bool>, verbunden: Bool) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: MykSpace.s2) {
                Text(titel).font(.mykSmall).foregroundStyle(verbunden ? MykColor.ink.color : MykColor.muted.color)
                if verbunden == false {
                    Text("nicht verbunden").font(.mykMono(8)).foregroundStyle(MykColor.faint.color)
                }
            }
        }
        .toggleStyle(.checkbox)
        .disabled(verbunden == false)
    }
}
