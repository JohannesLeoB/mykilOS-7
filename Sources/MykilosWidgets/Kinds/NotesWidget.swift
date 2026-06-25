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
                    .foregroundStyle(Color(hex: 0x6B5A2F))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 72)
                    .padding(MykSpace.s3)
                    .background(
                        RoundedRectangle(cornerRadius: MykRadius.sm)
                            .fill(LinearGradient(
                                colors: [Color(hex: 0xFBF3DA), Color(hex: 0xF6EAD0)],
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
    }

    // MARK: Autosave (debounced, 0.8 s Pause)
    private func scheduleAutosave() {
        editTimer?.invalidate()
        editTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
            try? noteStore.save()
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
                Image(systemName: "checkmark.circle.fill").font(.system(size: 10)).foregroundStyle(MykColor.positive.color)
                Text("Gespeichert \(d.formatted(.dateTime.hour().minute()))").font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            case .failed(let msg):
                Image(systemName: "exclamationmark.circle").font(.system(size: 10)).foregroundStyle(MykColor.critical.color)
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

private extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF)/255,
                  green: Double((hex >> 8) & 0xFF)/255,
                  blue: Double(hex & 0xFF)/255, opacity: 1)
    }
}
