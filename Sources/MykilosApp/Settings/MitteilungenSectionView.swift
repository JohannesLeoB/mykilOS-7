import SwiftUI
import MykilosDesign
import MykilosServices

// MARK: - MitteilungenSectionView (Johannes-Feedback 2026-07-06/07, Aufgaben-Spalten)
// Globaler Schalter + Ton für die Alarme privater Aufgaben (TaskAlarmScheduler).
// Rein lokale UserDefaults-Präferenz, kein GRDB nötig.
struct MitteilungenSectionView: View {
    @State private var alarmAn: Bool = TaskAlarmPreferences.global
    @State private var ton: TaskAlarmSound = TaskAlarmPreferences.sound
    @State private var nachfassAn: Bool = NachfassAlertPreferences.aktiv
    @State private var nachfassSchwelle: Int = NachfassAlertPreferences.schwelleInTagen
    @State private var bitteReagierenAn: Bool = BitteReagierenAlertPreferences.aktiv
    @State private var bitteReagierenSchwelle: Int = BitteReagierenAlertPreferences.schwelleInTagen
    @State private var signaleAn: Bool = SignalNotificationPreferences.aktiv

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            Text("Mitteilungen").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
            Text("Alarme für private Aufgaben mit Fälligkeit (Heute → Aufgaben). Betrifft nicht "
                 + "ClickUp-Aufgaben oder Kalendertermine.")
                .font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(isOn: alarmBinding) {
                Label("Aufgaben-Alarme aktiv", systemImage: "bell").font(.mykSmall)
            }
            .toggleStyle(.switch)
            .frame(maxWidth: 400, alignment: .leading)

            HStack(spacing: MykSpace.s3) {
                Text("Alarmton").font(.mykMono(9.5)).foregroundStyle(MykColor.faint.color)
                Picker("", selection: tonBinding) {
                    ForEach(TaskAlarmSound.allCases, id: \.self) { sound in
                        Text(sound.label).tag(sound)
                    }
                }
                .labelsHidden()
                .frame(width: 160)
                .disabled(alarmAn == false)
            }

            Divider().overlay(MykColor.line.color)

            Text("Nachfass-Erinnerung bei Angebot ohne Aktivität. Reiner Alters-Hinweis, keine "
                 + "bestätigte Kundenreaktion — zeigt nur, seit wann die Datei im Drive "
                 + "unverändert ist (Alle Angebote → Ausgehend).")
                .font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(isOn: nachfassBinding) {
                Label("Nachfass-Hinweis aktiv", systemImage: "clock.badge.exclamationmark").font(.mykSmall)
            }
            .toggleStyle(.switch)
            .frame(maxWidth: 400, alignment: .leading)

            HStack(spacing: MykSpace.s3) {
                Text("Ab wie vielen Tagen").font(.mykMono(9.5)).foregroundStyle(MykColor.faint.color)
                Stepper("\(nachfassSchwelle) Tage", value: nachfassSchwelleBinding, in: 3...60)
                    .font(.mykMono(10)).frame(width: 160)
                    .disabled(nachfassAn == false)
            }

            Divider().overlay(MykColor.line.color)

            Text("\"Bitte reagieren\"-Hinweis bei eingehendem Beleg ohne Aktivität — die Gegenrichtung "
                 + "zum Nachfass-Hinweis. Reiner Alters-Hinweis, kein Beweis für eine noch fehlende "
                 + "eigene Reaktion (Alle Angebote → Eingehend).")
                .font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(isOn: bitteReagierenBinding) {
                Label("\"Bitte reagieren\"-Hinweis aktiv", systemImage: "tray.and.arrow.down").font(.mykSmall)
            }
            .toggleStyle(.switch)
            .frame(maxWidth: 400, alignment: .leading)

            HStack(spacing: MykSpace.s3) {
                Text("Ab wie vielen Tagen").font(.mykMono(9.5)).foregroundStyle(MykColor.faint.color)
                Stepper("\(bitteReagierenSchwelle) Tage", value: bitteReagierenSchwelleBinding, in: 3...60)
                    .font(.mykMono(10)).frame(width: 160)
                    .disabled(bitteReagierenAn == false)
            }

            Divider().overlay(MykColor.line.color)

            Text("Echte macOS-Mitteilungen (Banner/Mitteilungszentrale) für neu erkannte Angebote "
                 + "und Werkzeichnungen — auch wenn mykilOS nicht im Vordergrund ist. Gilt nur für "
                 + "diesen Mac, kein Versand aufs Handy.")
                .font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(isOn: signaleBinding) {
                Label("Mac-Mitteilungen für Signale aktiv", systemImage: "bell.badge").font(.mykSmall)
            }
            .toggleStyle(.switch)
            .frame(maxWidth: 400, alignment: .leading)
        }
        .settingsCard()
    }

    private var alarmBinding: Binding<Bool> {
        Binding(get: { alarmAn }, set: { alarmAn = $0; TaskAlarmPreferences.global = $0 })
    }

    private var tonBinding: Binding<TaskAlarmSound> {
        Binding(get: { ton }, set: { ton = $0; TaskAlarmPreferences.sound = $0 })
    }

    private var nachfassBinding: Binding<Bool> {
        Binding(get: { nachfassAn }, set: { nachfassAn = $0; NachfassAlertPreferences.aktiv = $0 })
    }

    private var nachfassSchwelleBinding: Binding<Int> {
        Binding(get: { nachfassSchwelle }, set: { nachfassSchwelle = $0; NachfassAlertPreferences.schwelleInTagen = $0 })
    }

    private var bitteReagierenBinding: Binding<Bool> {
        Binding(get: { bitteReagierenAn }, set: { bitteReagierenAn = $0; BitteReagierenAlertPreferences.aktiv = $0 })
    }

    private var bitteReagierenSchwelleBinding: Binding<Int> {
        Binding(get: { bitteReagierenSchwelle },
                set: { bitteReagierenSchwelle = $0; BitteReagierenAlertPreferences.schwelleInTagen = $0 })
    }

    private var signaleBinding: Binding<Bool> {
        Binding(get: { signaleAn }, set: { signaleAn = $0; SignalNotificationPreferences.aktiv = $0 })
    }
}
