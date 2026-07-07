import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - TeamMitgliedAnlegenSectionView (Admin-Onboarding-Automatisierung, 2026-07-07)
// EIN Formular statt drei getrennter manueller Schritte: Admin gibt Name + Mail + Rolle
// ein → (1) Clockodo-Nutzer-Airtable-Record idempotent angelegt (NutzerProvisioningService,
// bereits freigegeben/whitelisted), (2) .mykinvite mit generiertem Passwort gebaut
// (bestehender AppState.einladungErstellen), (3) fertiger Willkommenstext zum Copy-Paste.
// Ghost-Personas bewusst NICHT angefasst (Johannes 2026-07-07: "wird es nicht mehr geben,
// wenn alles live ist"). Store-Gate explizit hier (NutzerProvisioningService ist bewusst
// SELBST nicht admin-gated — Self-Service-Design für den eigenen Record; das Anlegen für
// eine ANDERE Person ist der Admin-Akt, deshalb hier per assertAdmin geprüft, nicht dort).
struct TeamMitgliedAnlegenSectionView: View {
    @Environment(AppState.self) private var appState

    @State private var name = ""
    @State private var email = ""
    @State private var laeuft = false
    @State private var fehler: String?
    @State private var ergebnis: Ergebnis?

    private struct Ergebnis {
        let passwort: String
        let einladungsDaten: Data
        let dateiName: String
    }

    private var identity: ResidentIdentity? { appState.currentIdentity }
    private var tokenPresent: Bool { appState.currentAdminTokenPresent }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            header
            if let ergebnis {
                ergebnisAnsicht(ergebnis)
            } else {
                formular
            }
            if let fehler {
                Text(fehler).font(.mykMono(9.5)).foregroundStyle(MykColor.critical.color)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Neues Team-Mitglied anlegen").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
            Text("Ein Formular statt drei manueller Schritte: legt den Airtable-Record an, baut die "
                 + "Einladungsdatei mit generiertem Passwort und liefert einen fertigen Willkommenstext.")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var formular: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            TextField("Name (z. B. Sebastian Enders)", text: $name)
                .textFieldStyle(.roundedBorder).font(.mykMono(11))
            TextField("Google-Mail (die spätere Login-Adresse)", text: $email)
                .textFieldStyle(.roundedBorder).font(.mykMono(11))
            Button {
                Task { await anlegen() }
            } label: {
                if laeuft { ProgressView().controlSize(.small) } else { Text("Team-Mitglied anlegen") }
            }
            .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.paper.color)
            .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s2)
            .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.drive.color))
            .disabled(laeuft
                      || name.trimmingCharacters(in: .whitespaces).isEmpty
                      || email.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func ergebnisAnsicht(_ ergebnis: Ergebnis) -> some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            Label("Angelegt — Airtable-Record + Einladung fertig.", systemImage: "checkmark.circle.fill")
                .font(.mykSmall).foregroundStyle(MykColor.positive.color)

            VStack(alignment: .leading, spacing: MykSpace.s2) {
                Text("PASSWORT (getrennt vom Dateiversand mitteilen)").font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
                HStack(spacing: MykSpace.s3) {
                    Text(ergebnis.passwort).font(.mykMono(13)).foregroundStyle(MykColor.ink.color)
                    Button("Kopieren") { kopiere(ergebnis.passwort) }
                        .buttonStyle(.plain).font(.mykMono(9.5)).foregroundStyle(MykColor.drive.color)
                }
            }

            Button("Einladung speichern …") { speichereEinladung(ergebnis) }
                .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.drive.color)

            VStack(alignment: .leading, spacing: MykSpace.s2) {
                Text("WILLKOMMENSTEXT (fertig zum Versenden)").font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
                Text(willkommensText)
                    .font(.mykMono(9.5)).foregroundStyle(MykColor.ink.color)
                    .padding(MykSpace.s3)
                    .background(MykColor.paper2.color)
                    .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                Button("Willkommenstext kopieren") { kopiere(willkommensText) }
                    .buttonStyle(.plain).font(.mykMono(9.5)).foregroundStyle(MykColor.drive.color)
            }

            Button("Weiteres Mitglied anlegen") { zuruecksetzen() }
                .buttonStyle(.plain).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
        }
    }

    private var willkommensText: String {
        """
        Willkommen bei mykilOS! 🎉

        So richtest du dich ein (ca. 5 Minuten):
        1. Angehängte DMG öffnen, mykilOS in den Programme-Ordner ziehen, öffnen.
        2. Im Einrichtungs-Assistenten bei „Hast du eine Einladung?" die angehängte
           Datei „\(dateiNameOhneEndung).mykinvite" wählen.
        3. Passwort eingeben — bekommst du separat von mir (Signal/Telefon), NIE zusammen mit der Datei.
        4. Mit deinem eigenen Google-Account anmelden.
        5. Mit ClickUp verbinden — eigener Personal-API-Token von clickup.com → Einstellungen → Apps.

        Fertig! Meld dich bei Fragen einfach.
        """
    }

    private var dateiNameOhneEndung: String {
        name.trimmingCharacters(in: .whitespaces).isEmpty ? "einladung" : name.trimmingCharacters(in: .whitespaces)
    }

    private func anlegen() async {
        fehler = nil
        laeuft = true
        defer { laeuft = false }
        do {
            try appState.adminAuthority.assertAdmin(identity, tokenPresent: tokenPresent, funktion: "Team-Mitglied anlegen")
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = try await appState.nutzerProvisioning.findOrCreate(googleEmail: trimmedEmail, displayName: trimmedName)
            let passwort = MykInvitePasswordGenerator.generate()
            let daten = try appState.einladungErstellen(
                inhalt: [.airtable, .googleClient, .claude],
                eingeladeneEmail: trimmedEmail,
                eingeladenerName: trimmedName,
                passwort: passwort
            )
            ergebnis = Ergebnis(passwort: passwort, einladungsDaten: daten, dateiName: "\(dateiNameOhneEndung).mykinvite")
        } catch {
            fehler = error.localizedDescription
        }
    }

    private func speichereEinladung(_ ergebnis: Ergebnis) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = ergebnis.dateiName
        panel.prompt = "Speichern"
        panel.message = "Einladungsdatei speichern"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try ergebnis.einladungsDaten.write(to: url)
        } catch {
            fehler = "Speichern fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    private func kopiere(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func zuruecksetzen() {
        name = ""; email = ""; ergebnis = nil; fehler = nil
    }
}
