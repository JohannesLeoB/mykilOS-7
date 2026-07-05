import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - ClickUpTestWerkbankView (2026-07-04)
// Interaktive Write-Basics für ClickUp — Aufgabe anlegen, Status ändern/erledigt markieren —
// AUSSCHLIESSLICH gegen eine fest verdrahtete Liste im Sandbox-Space „MYKILOS API TESTSPACE"
// (`90128024109`). Kein Projekt-Bezug, keine echten Projektlisten — bewusst getrennt vom
// read-only `TasksWidget`, damit Entwicklung/Verifikation nie versehentlich echte Produktiv-
// Listen berührt (Eiserne Regel [[clickup-ghost-persona-rule]]).
//
// „Zuweisen" ist NIE das native ClickUp-`assignees`-Feld (das löst eine echte Benachrichtigung
// an eine reale Person aus) — nur ein Ghost-Kürzel als Text-Marker im Beschreibungsfeld
// (`content`). Ghost→echte Zuweisung erst auf Johannes' ausdrückliche Freigabe.
struct ClickUpTestWerkbankView: View {
    // KUE-2026-014 Küche Müller TEST — Liste im Ordner „01 Kundenprojekte" des Testspace.
    private static let testListID = "901218940344"
    private static let testListLabel = "KUE-2026-014 Küche Müller TEST"

    private static let ghostKuerzel = ["Jo", "Da", "Fra", "Sen", "Jil"]

    @State private var tasks: [ClickUpTask] = []
    @State private var isLoading = false
    @State private var fehler: String?
    @State private var neuerName = ""
    @State private var neuerGhost: String?
    @State private var legeAn = false
    @State private var statusAktion: String?

    private let client = ClickUpClient()

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("ClickUp-Testspace — Werkbank")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            Text("🧪 Schreibt ausschließlich in die Sandbox-Liste \(Self.testListLabel) im Space MYKILOS API TESTSPACE — nie in ein echtes Projekt.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)

            anlegenZeile

            if let fehler {
                Text(fehler).font(.mykMono(10)).foregroundStyle(MykColor.critical.color)
            }

            if isLoading {
                ProgressView().controlSize(.small)
            } else if tasks.isEmpty {
                Text("Keine offenen Aufgaben in der Testliste.")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            } else {
                VStack(spacing: 0) {
                    ForEach(tasks) { task in
                        taskZeile(task)
                        if task.id != tasks.last?.id {
                            Divider().overlay(MykColor.line.color.opacity(0.4))
                        }
                    }
                }
            }
        }
        .settingsCard()
        .task { await lade() }
    }

    // MARK: Anlegen

    private var anlegenZeile: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            HStack(spacing: MykSpace.s3) {
                TextField("Neue Test-Aufgabe …", text: $neuerName)
                    .textFieldStyle(.roundedBorder)
                    .font(.mykSmall)
                Picker("Ghost-Kürzel", selection: $neuerGhost) {
                    Text("Keine Zuweisung").tag(String?.none)
                    ForEach(Self.ghostKuerzel, id: \.self) { kuerzel in
                        Text(kuerzel).tag(String?.some(kuerzel))
                    }
                }
                .labelsHidden()
                .frame(width: 140)
                Button {
                    Task { await legeTaskAn() }
                } label: {
                    if legeAn { ProgressView().controlSize(.small) } else { Text("Anlegen") }
                }
                .disabled(neuerName.trimmingCharacters(in: .whitespaces).isEmpty || legeAn)
            }
            Text("Ghost-Kürzel schreibt nur einen Text-Hinweis in die Beschreibung — kein echtes ClickUp-Assignee, keine Benachrichtigung.")
                .font(.mykMono(8.5))
                .foregroundStyle(MykColor.faint.color)
        }
    }

    private func legeTaskAn() async {
        legeAn = true
        fehler = nil
        defer { legeAn = false }
        let name = neuerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let content = neuerGhost.map { "Zugewiesen (simuliert, Ghost-Persona): \($0)" }
        do {
            _ = try await client.createTask(listID: Self.testListID, name: name, content: content)
            neuerName = ""
            neuerGhost = nil
            await lade()
        } catch {
            fehler = "Anlegen fehlgeschlagen: \(error)"
        }
    }

    // MARK: Zeile + Status

    private func taskZeile(_ task: ClickUpTask) -> some View {
        HStack(spacing: MykSpace.s4) {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.name).font(.mykSmall).foregroundStyle(MykColor.ink.color).lineLimit(1)
                if let assignee = task.assignee {
                    Text(assignee).font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
                }
            }
            Spacer()
            statusMenu(for: task)
        }
        .padding(.vertical, MykSpace.s2)
    }

    // Statuswerte kommen ausschließlich aus bereits geladenen Aufgaben dieser Liste — keine
    // erfundenen Werte, keine zusätzliche Metadaten-Abfrage nötig.
    private var bekannteStatuswerte: [String] {
        Array(Set(tasks.map(\.status))).sorted()
    }

    private func statusMenu(for task: ClickUpTask) -> some View {
        Menu {
            ForEach(bekannteStatuswerte, id: \.self) { status in
                Button(status) { Task { await setzeStatus(task: task, status: status) } }
            }
        } label: {
            HStack(spacing: MykSpace.s2) {
                if statusAktion == task.id { ProgressView().controlSize(.small) }
                Text(task.status.isEmpty ? "—" : task.status)
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.cash.color)
                Image(systemName: "chevron.down").font(.mykMono(8))
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func setzeStatus(task: ClickUpTask, status: String) async {
        statusAktion = task.id
        fehler = nil
        defer { statusAktion = nil }
        do {
            try await client.setStatus(taskID: task.id, status: status)
            await lade()
        } catch {
            fehler = "Status ändern fehlgeschlagen: \(error)"
        }
    }

    // MARK: Laden

    private func lade() async {
        isLoading = true
        fehler = nil
        defer { isLoading = false }
        do {
            tasks = try await client.tasks(listID: Self.testListID)
        } catch {
            fehler = "Laden fehlgeschlagen: \(error)"
        }
    }
}
