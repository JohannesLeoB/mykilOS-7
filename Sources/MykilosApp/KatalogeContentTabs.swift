import SwiftUI
import MykilosDesign
import MykilosServices
import MykilosKit

// MARK: - Kontakte-Katalog (Google-Workspace-Verzeichnis, read-only, S19)

@MainActor
struct KontakteKatalogTab: View {
    @State private var query: String = ""
    @State private var results: [GoogleContact] = []
    @State private var state: LoadPhase = .idle

    private enum LoadPhase: Equatable { case idle, loading, loaded, notConnected, error(String) }
    private let client: GoogleContactsFetching = GoogleContactsClient()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchBar
            switch state {
            case .idle:
                hint("Suche im mykilOS.com-Workspace-Verzeichnis: Team-Profile und vom Admin geteilte Domain-Kontakte (Name, Firma, E-Mail).")
            case .loading:
                VStack { Spacer(); ProgressView("Suche …").font(.mykSmall); Spacer() }.frame(maxWidth: .infinity)
            case .notConnected:
                hint("Google nicht verbunden bzw. Verzeichnis-Berechtigung fehlt — in den Einstellungen neu verbinden (directory.readonly).")
            case .error(let msg):
                hint("Fehler: \(msg)")
            case .loaded:
                if results.isEmpty { hint("Keine Verzeichnis-Treffer für \"\(query)\".") } else { list }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: "magnifyingglass").font(.mykCaption).foregroundStyle(MykColor.muted.color)
            TextField("Verzeichnis durchsuchen (Name, Firma, E-Mail) …", text: $query)
                .font(.mykBody).textFieldStyle(.plain)
                .onSubmit { Task { await search() } }
            Button("Suchen") { Task { await search() } }
                .font(.mykSmall).buttonStyle(.plain).foregroundStyle(MykColor.people.color)
        }
        .padding(MykSpace.s4)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
        .padding(MykSpace.s9)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(results) { contact in
                    HStack(spacing: MykSpace.s4) {
                        Image(systemName: "person.crop.circle")
                            .font(.mykHeadline).foregroundStyle(MykColor.people.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(contact.displayName).font(.mykBody).foregroundStyle(MykColor.ink.color)
                            if let org = contact.organization, !org.isEmpty {
                                Text(org).font(.mykSmall).foregroundStyle(MykColor.muted.color)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            if let mail = contact.email { Text(mail).font(.mykMono(10)).foregroundStyle(MykColor.muted.color) }
                            if let phone = contact.phone { Text(phone).font(.mykMono(10)).foregroundStyle(MykColor.faint.color) }
                        }
                    }
                    .padding(.horizontal, MykSpace.s9).padding(.vertical, MykSpace.s3)
                    Divider().overlay(MykColor.line.color)
                }
            }
        }
    }

    private func hint(_ text: String) -> some View {
        VStack { Spacer(); Text(text).font(.mykSmall).foregroundStyle(MykColor.muted.color).multilineTextAlignment(.center); Spacer() }
            .frame(maxWidth: .infinity).padding(MykSpace.s9)
    }

    private func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { state = .idle; results = []; return }
        state = .loading
        do {
            results = try await client.searchDirectory(query: trimmed)
            state = .loaded
        } catch GoogleContactsError.notConnected {
            state = .notConnected
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

// MARK: - Notizen-Katalog (lokale Assistenten-Notizen, S4)

// Zwei Notiz-Ansichten (Wunsch): cleane Liste ODER bunte Zettel-Wand. Persistent.
enum NotizenView: String { case liste, wand }

@MainActor
struct NotizenKatalogTab: View {
    @Environment(AppState.self) private var appState
    @State private var notes: [AssistantNote] = []
    @State private var draft: String = ""
    @State private var errorText: String?
    @State private var editing: AssistantNote?
    @AppStorage("kataloge.notizen.view") private var viewModeRaw = NotizenView.liste.rawValue
    private var viewMode: NotizenView { NotizenView(rawValue: viewModeRaw) ?? .liste }

    private static let stamp: DateFormatter = {
        let fmt = DateFormatter(); fmt.dateFormat = "dd.MM.yy HH:mm"; fmt.locale = Locale(identifier: "de_DE"); return fmt
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: MykSpace.s3) {
                addBar
                viewToggle
            }
            .padding(.horizontal, MykSpace.s9).padding(.top, MykSpace.s9).padding(.bottom, MykSpace.s3)
            if let errorText { errorLine(errorText) }
            if notes.isEmpty {
                emptyHint("Noch keine Notizen. Lege welche an — hier oder im Assistenten-Chat.")
            } else if viewMode == .wand {
                noteWall
            } else {
                noteList
            }
        }
        .task { await reload() }
        .sheet(item: $editing) { note in
            NoteEditorSheet(
                note: note,
                onSave: { body, color in save(note, body: body, color: color) },
                onDelete: { delete(note); editing = nil },
                onClose: { editing = nil })
        }
    }

    // MARK: Ansicht-Umschalter

    private var viewToggle: some View {
        HStack(spacing: 0) {
            toggleButton(.liste, icon: "list.bullet", label: "Liste")
            toggleButton(.wand, icon: "square.grid.2x2.fill", label: "Wand")
        }
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
    }

    private func toggleButton(_ mode: NotizenView, icon: String, label: String) -> some View {
        let active = viewMode == mode
        return Button { viewModeRaw = mode.rawValue } label: {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: icon).font(.mykCaption)
                Text(label).font(.mykSmall)
            }
            .foregroundStyle(active ? MykColor.paper.color : MykColor.muted.color)
            .padding(.horizontal, MykSpace.s3).padding(.vertical, MykSpace.s2)
            .background(active ? MykColor.personal.color : Color.clear)
        }
        .buttonStyle(.plain)
    }

    // MARK: Liste (clean)

    private var noteList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(notes) { note in
                    HStack(alignment: .top, spacing: MykSpace.s4) {
                        Image(systemName: "note.text").font(.mykBody).foregroundStyle(MykColor.personal.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(note.body).font(.mykBody).foregroundStyle(MykColor.ink.color)
                            HStack(spacing: MykSpace.s2) {
                                Text("[\(note.ref)] \u{00B7} \(Self.stamp.string(from: note.updatedAt))")
                                    .font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                                if let pid = note.projectID {
                                    Text(pid).font(.mykMono(9)).foregroundStyle(MykColor.personal.color)
                                }
                            }
                        }
                        if let key = note.color, let c = NoteColorPalette.mykColor(key) {
                            Circle().fill(c.color).frame(width: 9, height: 9)
                        }
                        Spacer()
                        Button { editing = note } label: {
                            Image(systemName: "pencil").font(.mykCaption).foregroundStyle(MykColor.muted.color)
                        }.buttonStyle(.plain)
                        Button { delete(note) } label: {
                            Image(systemName: "trash").font(.mykCaption).foregroundStyle(MykColor.critical.color)
                        }.buttonStyle(.plain)
                    }
                    .padding(.horizontal, MykSpace.s9).padding(.vertical, MykSpace.s3)
                    .contentShape(Rectangle())
                    .onTapGesture { editing = note }
                    Divider().overlay(MykColor.line.color)
                }
            }
        }
    }

    // MARK: Wand (bunte Zettel)

    private var noteWall: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: 280), spacing: MykSpace.s5)],
                      alignment: .leading, spacing: MykSpace.s5) {
                ForEach(notes) { note in
                    StickyNoteCard(note: note, dateText: Self.stamp.string(from: note.updatedAt),
                                   onTap: { editing = note },
                                   onDelete: { delete(note) })
                }
            }
            .padding(MykSpace.s9)
        }
    }

    private var addBar: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: "plus").font(.mykCaption).foregroundStyle(MykColor.muted.color)
            TextField("Neue Notiz …", text: $draft)
                .font(.mykBody).textFieldStyle(.plain).onSubmit { add() }
            Button("Sichern") { add() }
                .font(.mykSmall).buttonStyle(.plain).foregroundStyle(MykColor.personal.color)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(MykSpace.s4)
        .frame(maxWidth: .infinity)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
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
        do { notes = try await appState.assistantNotes.all(); errorText = nil }
        catch { errorText = "Notizen konnten nicht geladen werden: \(error.localizedDescription)" }
    }
    private func add() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return }
        draft = ""
        Task {
            do { try await appState.assistantNotes.create(text); await reload() }
            catch { errorText = "Notiz konnte nicht gespeichert werden: \(error.localizedDescription)" }
        }
    }
    private func delete(_ note: AssistantNote) {
        Task {
            do { try await appState.assistantNotes.delete(matching: note.id); await reload() }
            catch { errorText = "Notiz konnte nicht gelöscht werden: \(error.localizedDescription)" }
        }
    }
    private func save(_ note: AssistantNote, body: String, color: String?) {
        editing = nil
        Task {
            do { try await appState.assistantNotes.update(id: note.id, body: body, color: color); await reload() }
            catch { errorText = "Notiz konnte nicht gespeichert werden: \(error.localizedDescription)" }
        }
    }
}

// MARK: - NoteEditorSheet — Notiz bearbeiten + 4-Farb-Picker
private struct NoteEditorSheet: View {
    let note: AssistantNote
    let onSave: (_ body: String, _ color: String?) -> Void
    let onDelete: () -> Void
    let onClose: () -> Void

    @State private var text: String
    @State private var color: String?

    init(note: AssistantNote, onSave: @escaping (String, String?) -> Void,
         onDelete: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.note = note; self.onSave = onSave; self.onDelete = onDelete; self.onClose = onClose
        _text = State(initialValue: note.body)
        _color = State(initialValue: note.color)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Notiz bearbeiten").font(.mykHeadline).foregroundStyle(MykColor.ink.color)

            TextEditor(text: $text)
                .font(.mykBody).foregroundStyle(MykColor.ink.color)
                .scrollContentBackground(.hidden)
                .padding(MykSpace.s3)
                .frame(minHeight: 140)
                .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.card.color))
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))

            HStack(spacing: MykSpace.s4) {
                Text("Farbe").font(.mykSmall).foregroundStyle(MykColor.muted.color)
                ForEach(NoteColorPalette.pickKeys, id: \.self) { key in
                    let c = NoteColorPalette.mykColor(key) ?? .personal
                    Circle()
                        .fill(c.color.opacity(0.5))
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(color == key ? MykColor.ink.color : c.color.opacity(0.7),
                                                 lineWidth: color == key ? 2 : 1))
                        .overlay {
                            if color == key {
                                Image(systemName: "checkmark").font(.mykMono(10)).foregroundStyle(MykColor.ink.color)
                            }
                        }
                        .onTapGesture { color = (color == key) ? nil : key }
                }
                Spacer()
            }

            HStack {
                Button(role: .destructive) { onDelete() } label: {
                    Label("Löschen", systemImage: "trash").font(.mykSmall).foregroundStyle(MykColor.critical.color)
                }.buttonStyle(.plain)
                Spacer()
                Button("Abbrechen") { onClose() }.font(.mykSmall).buttonStyle(.plain).foregroundStyle(MykColor.muted.color)
                Button("Speichern") { onSave(text, color) }
                    .font(.mykSmall).foregroundStyle(MykColor.paper.color)
                    .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s2)
                    .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.personal.color))
                    .buttonStyle(.plain)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(MykSpace.s7)
        .frame(width: 460)
        .background(MykColor.paper.color)
    }
}

// MARK: - NoteColorPalette — 4 wählbare Farben + Auto-Palette (Token-Disziplin: nur MykColor)
enum NoteColorPalette {
    /// Die 4 wählbaren Farb-Schlüssel für den Picker.
    static let pickKeys = ["tasks", "people", "personal", "cash"]
    /// Schlüssel → MykColor; unbekannt/nil → nil (dann Auto-Farbe).
    static func mykColor(_ key: String?) -> MykColor? {
        switch key {
        case "tasks":    return .tasks
        case "people":   return .people
        case "personal": return .personal
        case "cash":     return .cash
        default:         return nil
        }
    }
    /// Automatische Palette (für Notizen ohne gewählte Farbe).
    static let auto: [MykColor] = [.tasks, .people, .personal, .drive, .cash, .brand]
    static func autoColor(forID id: String) -> MykColor {
        let seed = id.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return auto[seed % auto.count]
    }
}

// MARK: - StickyNoteCard — bunter Notizzettel für die Wand-Ansicht
private struct StickyNoteCard: View {
    let note: AssistantNote
    let dateText: String
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    // Stabiler Winkel aus der Notiz-ID → Neigung bleibt an der Notiz.
    private var seed: Int { note.id.unicodeScalars.reduce(0) { $0 &+ Int($1.value) } }
    // Gewählte Farbe gewinnt, sonst automatische aus der ID.
    private var accent: MykColor { NoteColorPalette.mykColor(note.color) ?? NoteColorPalette.autoColor(forID: note.id) }
    private var tilt: Double { Double((seed % 5) - 2) * 1.1 }   // ca. -2.2° … +2.2°

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            Text(note.body)
                .font(.mykBody).foregroundStyle(MykColor.ink.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: MykSpace.s4)
            HStack(spacing: MykSpace.s2) {
                if let pid = note.projectID {
                    Text(pid).font(.mykMono(8)).foregroundStyle(accent.color)
                }
                Text(dateText).font(.mykMono(8)).foregroundStyle(MykColor.faint.color)
                Spacer()
                if isHovered {
                    Button(action: onDelete) {
                        Image(systemName: "trash").font(.mykCaption).foregroundStyle(MykColor.critical.color)
                    }.buttonStyle(.plain)
                }
            }
        }
        .padding(MykSpace.s4)
        .frame(minHeight: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.sm)
                .fill(accent.color.opacity(isHovered ? 0.42 : 0.32))
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(accent.color.opacity(0.7), lineWidth: 1))
        )
        .rotationEffect(.degrees(isHovered ? 0 : tilt))
        .shadow(color: MykColor.ink.color.opacity(0.10), radius: 3, x: 0, y: 2)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

// MARK: - Aufgaben-Katalog (lokale Assistenten-Aufgaben, S6)

@MainActor
struct AufgabenKatalogTab: View {
    @Environment(AppState.self) private var appState
    @State private var tasks: [AssistantTask] = []
    @State private var draft: String = ""
    @State private var errorText: String?

    private static let stamp: DateFormatter = {
        let fmt = DateFormatter(); fmt.dateFormat = "dd.MM.yy"; fmt.locale = Locale(identifier: "de_DE"); return fmt
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
                                        }
                                        if let pid = task.projectID {
                                            Text(pid).font(.mykMono(9)).foregroundStyle(MykColor.tasks.color)
                                        }
                                    }
                                }
                                Spacer()
                                Button { delete(task) } label: {
                                    Image(systemName: "trash").font(.mykCaption).foregroundStyle(MykColor.critical.color)
                                }.buttonStyle(.plain)
                            }
                            .padding(.horizontal, MykSpace.s9).padding(.vertical, MykSpace.s3)
                            Divider().overlay(MykColor.line.color)
                        }
                    }
                }
            }
        }
        .task { await reload() }
    }

    private var addBar: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: "plus").font(.mykCaption).foregroundStyle(MykColor.muted.color)
            TextField("Neue Aufgabe …", text: $draft)
                .font(.mykBody).textFieldStyle(.plain).onSubmit { add() }
            Button("Hinzufügen") { add() }
                .font(.mykSmall).buttonStyle(.plain).foregroundStyle(MykColor.tasks.color)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        Task {
            do { try await appState.assistantTasks.create(text); await reload() }
            catch { errorText = "Aufgabe konnte nicht gespeichert werden: \(error.localizedDescription)" }
        }
    }
    private func toggle(_ task: AssistantTask) {
        Task {
            do { try await appState.assistantTasks.setDone(matching: task.id, done: !task.done); await reload() }
            catch { errorText = "Aufgabe konnte nicht aktualisiert werden: \(error.localizedDescription)" }
        }
    }
    private func delete(_ task: AssistantTask) {
        Task {
            do { try await appState.assistantTasks.delete(matching: task.id); await reload() }
            catch { errorText = "Aufgabe konnte nicht gelöscht werden: \(error.localizedDescription)" }
        }
    }
}
