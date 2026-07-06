import SwiftUI
import MykilosDesign
import MykilosServices
import MykilosKit

// MARK: - Aufgaben-Katalog: Quellen-Umschalter (Aufgaben-Spalten-System, 2026-07-07)
// Johannes-Feedback (wörtlich): "Alle 3 Listen über Toggle an- und ausschaltbar. Default
// ist die interne, private Aufgabenliste." Spalte 3 (ClickUp erstellen/zuweisen) folgt
// separat — siehe ClickUpAufgabenSpalte.swift-Kommentar zur eisernen Regel "KI weist nie zu".
enum AufgabenQuelle: String, CaseIterable, Identifiable {
    case privat, clickUp
    var id: String { rawValue }
    var label: String { self == .privat ? "Privat" : "ClickUp" }
}

@MainActor
struct AufgabenKatalogView: View {
    @AppStorage("kataloge.aufgaben.quelle") private var quelleRaw = AufgabenQuelle.privat.rawValue
    private var quelle: AufgabenQuelle { AufgabenQuelle(rawValue: quelleRaw) ?? .privat }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Picker("", selection: Binding(
                get: { quelle },
                set: { quelleRaw = $0.rawValue }
            )) {
                ForEach(AufgabenQuelle.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented).labelsHidden()
            .frame(width: 200)
            .padding(.horizontal, MykSpace.s9).padding(.top, MykSpace.s6)

            switch quelle {
            case .privat: AufgabenKatalogTab()
            case .clickUp: ClickUpAufgabenSpalte()
            }
        }
    }
}

// MARK: - Aufgaben-Katalog (lokale Assistenten-Aufgaben, S6)

@MainActor
struct AufgabenKatalogTab: View {
    @Environment(AppState.self) private var appState
    @State private var tasks: [AssistantTask] = []
    @State private var draft: String = ""
    @State private var errorText: String?
    // Fälligkeit+Alarm beim Anlegen (Johannes-Feedback 2026-07-06/07, Aufgaben-Spalten):
    // per Default eingeklappt, damit das schnelle "nur ein Titel"-Anlegen wie bisher bleibt.
    @State private var zeigeFaelligkeit = false
    @State private var faelligkeitDatum = Date()
    @State private var alarmBeimAnlegen = false
    @State private var editiereTask: AssistantTask?

    private static let stamp: DateFormatter = {
        let fmt = DateFormatter(); fmt.dateFormat = "dd.MM.yy · HH:mm"; fmt.locale = Locale(identifier: "de_DE"); return fmt
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            addBar
            if let errorText { errorLine(errorText) }
            if tasks.isEmpty {
                emptyHint("Keine Aufgaben. Setze dir Memos & Erinnerungen — hier oder im Assistenten-Chat.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks) { task in
                            HStack(spacing: MykSpace.s4) {
                                Button { toggle(task) } label: {
                                    Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                                        .font(.mykBody)
                                        .foregroundStyle(task.done ? MykColor.positive.color : MykColor.tasks.color)
                                }.buttonStyle(.plain)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                        .font(.mykBody)
                                        .foregroundStyle(task.done ? MykColor.muted.color : MykColor.ink.color)
                                        .strikethrough(task.done, color: MykColor.muted.color)
                                    HStack(spacing: MykSpace.s2) {
                                        if let due = task.dueDate {
                                            Text("fällig \(Self.stamp.string(from: due))")
                                                .font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                                            if task.alarmAktiv {
                                                Image(systemName: "bell.fill").font(.mykMono(8)).foregroundStyle(MykColor.tasks.color)
                                            }
                                        }
                                        if let pid = task.projectID {
                                            Text(pid).font(.mykMono(9)).foregroundStyle(MykColor.tasks.color)
                                        }
                                    }
                                }
                                Spacer()
                                Button { editiereTask = task } label: {
                                    Image(systemName: "pencil").font(.mykCaption).foregroundStyle(MykColor.muted.color)
                                }.buttonStyle(.plain).help("Bearbeiten")
                                Button { delete(task) } label: {
                                    Image(systemName: "trash").font(.mykCaption).foregroundStyle(MykColor.critical.color)
                                }.buttonStyle(.plain).help("Löschen")
                            }
                            .padding(.horizontal, MykSpace.s9).padding(.vertical, MykSpace.s3)
                            Divider().overlay(MykColor.line.color)
                        }
                    }
                }
            }
        }
        .task { await reload() }
        .sheet(item: $editiereTask) { task in
            AufgabeEditSheet(task: task, onSave: { neu in
                Task { await speichereEdit(neu) }
            }, onCancel: { editiereTask = nil })
        }
    }

    private var addBar: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "plus").font(.mykCaption).foregroundStyle(MykColor.muted.color)
                TextField("Neue Aufgabe …", text: $draft)
                    .font(.mykBody).textFieldStyle(.plain).onSubmit { add() }
                Button {
                    zeigeFaelligkeit.toggle()
                } label: {
                    Image(systemName: zeigeFaelligkeit ? "calendar.badge.minus" : "calendar.badge.plus")
                        .font(.mykCaption)
                        .foregroundStyle(zeigeFaelligkeit ? MykColor.tasks.color : MykColor.muted.color)
                }
                .buttonStyle(.plain).help("Fälligkeit + Alarm setzen")
                Button("Hinzufügen") { add() }
                    .font(.mykSmall).buttonStyle(.plain).foregroundStyle(MykColor.tasks.color)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if zeigeFaelligkeit {
                HStack(spacing: MykSpace.s4) {
                    DatePicker("", selection: $faelligkeitDatum, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden().datePickerStyle(.field)
                    Toggle(isOn: $alarmBeimAnlegen) {
                        Label("Alarm", systemImage: "bell").font(.mykMono(10))
                    }
                    .toggleStyle(.switch)
                }
            }
        }
        .padding(MykSpace.s4)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
        .padding(MykSpace.s9)
    }

    private func errorLine(_ text: String) -> some View {
        Text(text).font(.mykSmall).foregroundStyle(MykColor.critical.color)
            .padding(.horizontal, MykSpace.s9).padding(.bottom, MykSpace.s3)
    }

    private func emptyHint(_ text: String) -> some View {
        VStack { Spacer(); Text(text).font(.mykSmall).foregroundStyle(MykColor.muted.color).multilineTextAlignment(.center); Spacer() }
            .frame(maxWidth: .infinity).padding(MykSpace.s9)
    }

    private func reload() async {
        do { tasks = try await appState.assistantTasks.all(); errorText = nil }
        catch { errorText = "Aufgaben konnten nicht geladen werden: \(error.localizedDescription)" }
    }
    private func add() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return }
        draft = ""
        let dueDate = zeigeFaelligkeit ? faelligkeitDatum : nil
        let alarm = zeigeFaelligkeit && alarmBeimAnlegen
        zeigeFaelligkeit = false; alarmBeimAnlegen = false
        Task {
            do {
                let created = try await appState.assistantTasks.create(text, dueDate: dueDate, alarmAktiv: alarm)
                if alarm { await TaskAlarmScheduler.requestAuthorizationIfNeeded() }
                await TaskAlarmScheduler.reschedule(created)
                await reload()
            } catch {
                errorText = "Aufgabe konnte nicht gespeichert werden: \(error.localizedDescription)"
            }
        }
    }
    private func toggle(_ task: AssistantTask) {
        Task {
            do {
                guard let aktualisiert = try await appState.assistantTasks.setDone(id: task.id, done: !task.done) else { return }
                await TaskAlarmScheduler.reschedule(aktualisiert)   // erledigt → cancelt den Alarm automatisch
                await reload()
            } catch {
                errorText = "Aufgabe konnte nicht aktualisiert werden: \(error.localizedDescription)"
            }
        }
    }
    private func delete(_ task: AssistantTask) {
        Task {
            do {
                _ = try await appState.assistantTasks.delete(id: task.id)
                TaskAlarmScheduler.cancel(taskID: task.id)
                await reload()
            } catch {
                errorText = "Aufgabe konnte nicht gelöscht werden: \(error.localizedDescription)"
            }
        }
    }
    private func speichereEdit(_ neu: AssistantTask) async {
        editiereTask = nil
        do {
            guard let aktualisiert = try await appState.assistantTasks.update(
                id: neu.id, title: neu.title, dueDate: neu.dueDate, alarmAktiv: neu.alarmAktiv
            ) else { return }
            if aktualisiert.alarmAktiv { await TaskAlarmScheduler.requestAuthorizationIfNeeded() }
            await TaskAlarmScheduler.reschedule(aktualisiert)
            await reload()
        } catch {
            errorText = "Aufgabe konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }
}

// MARK: - AufgabeEditSheet (volle Editierbarkeit: Titel, Fälligkeit, Alarm)
private struct AufgabeEditSheet: View {
    @State var task: AssistantTask
    let onSave: (AssistantTask) -> Void
    let onCancel: () -> Void

    @State private var hatFaelligkeit: Bool
    @State private var datum: Date

    init(task: AssistantTask, onSave: @escaping (AssistantTask) -> Void, onCancel: @escaping () -> Void) {
        _task = State(initialValue: task)
        self.onSave = onSave
        self.onCancel = onCancel
        _hatFaelligkeit = State(initialValue: task.dueDate != nil)
        _datum = State(initialValue: task.dueDate ?? Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Aufgabe bearbeiten").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
            TextField("Titel", text: $task.title).textFieldStyle(.roundedBorder).font(.mykBody)

            Toggle(isOn: $hatFaelligkeit) {
                Label("Fälligkeit", systemImage: "calendar").font(.mykSmall)
            }
            .toggleStyle(.switch)

            if hatFaelligkeit {
                DatePicker("", selection: $datum, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden().datePickerStyle(.field)
                Toggle(isOn: $task.alarmAktiv) {
                    Label("Alarm bei Fälligkeit", systemImage: "bell").font(.mykSmall)
                }
                .toggleStyle(.switch)
            }

            HStack(spacing: MykSpace.s3) {
                Spacer()
                Button("Abbrechen") { onCancel() }
                    .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.muted.color)
                Button("Speichern") {
                    task.dueDate = hatFaelligkeit ? datum : nil
                    if hatFaelligkeit == false { task.alarmAktiv = false }
                    onSave(task)
                }
                .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.paper.color)
                .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s2)
                .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.tasks.color))
                .disabled(task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(MykSpace.s6)
        .frame(width: 360)
    }
}
