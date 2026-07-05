import SwiftUI
import MykilosDesign

// MARK: - SettingsView + Mini-Mode (Datenschutz)
// Ausgelagert aus SettingsView.swift (swiftlint file_length) — reine Verschiebung,
// Verhalten unverändert. Master-Schalter + je ein Schalter pro Aufmerksamkeits-Quelle.
extension SettingsView {
    // Alle default = an; die Schlüssel MÜSSEN mit MiniModeDefaults / MiniModeSource.defaultsKey
    // übereinstimmen (der MiniModeStore/MiniModeRailView liest exakt diese UserDefaults).
    // Dezent + jederzeit abschaltbar (eiserne Alerts-Regel): Master aus → kein Orange-Puls
    // im Mini-Rail, keine Quelle wird mehr gelesen.

    // MARK: - Datenschutz → Mini-Mode Puls

    var miniModeSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Mini-Mode Alerts")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            Text("Im Mini-Mode (schwebendes Icon-Rail) pulst ein Modul-Icon langsam orange, "
                 + "wenn seine Quelle Aufmerksamkeit will. Der Puls liest nur bereits "
                 + "vorhandene lokale Daten — er fragt nichts Neues ab. Jede Quelle lässt "
                 + "sich einzeln abschalten; der Master-Schalter schaltet allen Puls ab. "
                 + "(Den Mini-Mode selbst schaltest du unter Darstellung frei.)")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(isOn: $miniModeEnabled) {
                Label("Orange-Puls anzeigen", systemImage: "circle.grid.2x2")
                    .font(.mykSmall)
            }
            .toggleStyle(.switch)

            Divider().overlay(MykColor.line.color)

            Text("QUELLEN")
                .font(.mykMono(10)).tracking(1.5)
                .foregroundStyle(MykColor.muted.color)

            VStack(alignment: .leading, spacing: MykSpace.s3) {
                Toggle(isOn: $miniModeTimer) {
                    Label("Aktiver Timer", systemImage: "timer").font(.mykSmall)
                }
                Toggle(isOn: $miniModeTasks) {
                    Label("Offene Aufgaben", systemImage: "checklist").font(.mykSmall)
                }
                Toggle(isOn: $miniModeSignals) {
                    Label("Offene Signale", systemImage: "sparkle").font(.mykSmall)
                }
                // Wichtige Mails sind in V1 noch ohne passenden Cache-Producer — der
                // Schalter ist vorhanden, wirkt aber erst mit einer echten Mail-Quelle.
                // Ehrlicher Hinweis statt einer Zeile, die nie einen Wert zeigt.
                Toggle(isOn: $miniModeMail) {
                    Label("Wichtige Mails (bald)", systemImage: "envelope").font(.mykSmall)
                }
                .disabled(true)
                // Nächster Termin ist in V1 noch ohne lokalen Cache — der Schalter ist
                // vorhanden, wirkt aber erst mit dem geplanten Kalender-Cache. Ehrlicher
                // Hinweis statt einer Zeile, die nie einen Wert zeigt.
                Toggle(isOn: $miniModeCalendar) {
                    Label("Nächster Termin (bald)", systemImage: "calendar").font(.mykSmall)
                }
                .disabled(true)
            }
            .toggleStyle(.switch)
            .disabled(!miniModeEnabled)
            .opacity(miniModeEnabled ? 1 : 0.5)
        }
    }
}
