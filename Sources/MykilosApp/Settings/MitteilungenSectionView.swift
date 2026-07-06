import SwiftUI
import MykilosDesign
import MykilosServices

// MARK: - MitteilungenSectionView (Johannes-Feedback 2026-07-06/07, Aufgaben-Spalten)
// Globaler Schalter + Ton für die Alarme privater Aufgaben (TaskAlarmScheduler).
// Rein lokale UserDefaults-Präferenz, kein GRDB nötig.
struct MitteilungenSectionView: View {
    @State private var alarmAn: Bool = TaskAlarmPreferences.global
    @State private var ton: TaskAlarmSound = TaskAlarmPreferences.sound

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
        }
        .settingsCard()
    }

    private var alarmBinding: Binding<Bool> {
        Binding(get: { alarmAn }, set: { alarmAn = $0; TaskAlarmPreferences.global = $0 })
    }

    private var tonBinding: Binding<TaskAlarmSound> {
        Binding(get: { ton }, set: { ton = $0; TaskAlarmPreferences.sound = $0 })
    }
}
