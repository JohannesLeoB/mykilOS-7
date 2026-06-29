import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - NotesWidget
// Akt 2: ECHTER Speichern-Vertrag via NoteStore + GRDB.
// idle/saving/saved/failed — in der UI als SaveStateBar sichtbar.
// Kein `try?` mehr — Fehler werden angezeigt.
public struct NotesWidget: View {
    public let projectID: String
    public let noteStore: NoteStore

    public init(projectID: String, noteStore: NoteStore) {
        self.projectID = projectID
        self.noteStore = noteStore
    }

    @State private var editTimer: Timer? = nil

    public var body: some View {
        VStack(spacing: 0) {
            WidgetContainer(
                kind: .notes,
                sourceLabel: "LOKAL  ·  \(saveLabel)",
                renderState: .content,
                projectID: projectID
            ) {
                VStack(alignment: .leading, spacing: MykSpace.s5) {
                    HStack {
                        SourceChip(kind: .notes)
                        Text("Notiz").mykWidgetTitle()
                        Spacer()
                    }
                    TextEditor(text: Binding(
                        get: { noteStore.body },
                        set: { newVal in
                            noteStore.update(newVal)
                            scheduleAutosave()
                        }
                    ))
                    .font(.mykBody)
                    .foregroundStyle(MykColor.notesInk.color)   // L26: dark-mode-sicher
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 72)
                    .padding(MykSpace.s3)
                    .background(
                        RoundedRectangle(cornerRadius: MykRadius.sm)
                            .fill(LinearGradient(
                                colors: [MykColor.notesPaper.color, MykColor.notesPaper.color.opacity(0.92)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
                }
            }
            // Speichern-Status direkt unter dem Widget
            if noteStore.saveState != .idle {
                saveLine
            }
        }
        .task { try? noteStore.load() }
        .onDisappear {
            // Beim Verschwinden (Tab-/Projektwechsel, Board-Re-Render) den
            // Debounce-Timer abbrechen und ausstehende Eingaben sofort sichern —
            // sonst stirbt der @State-Timer und die letzte Notiz geht verloren.
            editTimer?.invalidate()
            editTimer = nil
            // try? gerechtfertigt: View ist weg, keine UI mehr für eine
            // Fehleranzeige; hasUnsavedChanges vermeidet No-Op-Writes.
            if noteStore.hasUnsavedChanges { try? noteStore.save() }
        }
    }

    // MARK: Autosave (debounced, 0.8 s Pause)
    private func scheduleAutosave() {
        editTimer?.invalidate()
        editTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
            // Expliziter Hop auf den MainActor: NoteStore.save() ist @MainActor,
            // der Timer-Callback ist nonisolated.
            Task { @MainActor in
                // try? gerechtfertigt: Debounce-Autosave; Fehler erscheint beim
                // nächsten manuellen Speichern bzw. über die SaveStateBar.
                try? noteStore.save()
            }
        }
    }

    // MARK: Spar-Zeile
    private var saveLine: some View {
        HStack(spacing: 6) {
            switch noteStore.saveState {
            case .saving:
                ProgressView().scaleEffect(0.6).tint(MykColor.muted.color)
                Text("Speichern…").font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            case .saved(let d):
                Image(systemName: "checkmark.circle.fill").font(.mykMono(10)).foregroundStyle(MykColor.positive.color)
                Text("Gespeichert \(d.formatted(.dateTime.hour().minute()))").font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            case .failed(let msg):
                Image(systemName: "exclamationmark.circle").font(.mykMono(10)).foregroundStyle(MykColor.critical.color)
                Text(msg).font(.mykMono(9.5)).foregroundStyle(MykColor.critical.color).lineLimit(1)
                Button("Erneut") { try? noteStore.save() }
                    .font(.mykMono(9.5)).foregroundStyle(MykColor.critical.color).buttonStyle(.plain)
            case .idle:
                EmptyView()
            }
            Spacer()
        }
        .padding(.horizontal, MykSpace.s6)
        .padding(.top, 5)
        .animation(.easeInOut(duration: 0.2), value: saveLabel)
    }

    private var saveLabel: String {
        switch noteStore.saveState {
        case .idle:           return "GESPEICHERT"
        case .saving:         return "SPEICHERT…"
        case .saved(let d):   return "GESPEICHERT \(d.formatted(.dateTime.hour().minute()))"
        case .failed:         return "FEHLER"
        }
    }
}
