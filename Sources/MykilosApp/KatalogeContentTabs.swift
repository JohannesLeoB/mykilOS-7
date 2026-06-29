import SwiftUI
import MykilosDesign
import MykilosServices
import MykilosKit

// MARK: - Kontakte-Katalog (Google-Kontaktsuche, read-only)

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
                hint("Suche nach Name, Firma oder E-Mail in deinen Google-Kontakten.")
            case .loading:
                VStack { Spacer(); ProgressView("Suche …").font(.mykSmall); Spacer() }.frame(maxWidth: .infinity)
            case .notConnected:
                hint("Google nicht verbunden — in den Einstellungen verbinden.")
            case .error(let msg):
                hint("Fehler: \(msg)")
            case .loaded:
                if results.isEmpty { hint("Keine Kontakte für \"\(query)\".") } else { list }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: "magnifyingglass").font(.mykCaption).foregroundStyle(MykColor.muted.color)
            TextField("Kontakt suchen …", text: $query)
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
            results = try await client.searchContacts(query: trimmed)
            state = .loaded
        } catch GoogleContactsError.notConnected {
            state = .notConnected
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

// MARK: - Notizen-Katalog (lokale Assistenten-Notizen, S4)

@MainActor
struct NotizenKatalogTab: View {
    @Environment(AppState.self) private var appState
    @State private var notes: [AssistantNote] = []
    @State private var draft: String = ""
    @State private var errorText: String?

    private static let stamp: DateFormatter = {
        let fmt = DateFormatter(); fmt.dateFormat = "dd.MM.yy HH:mm"; fmt.locale = Locale(identifier: "de_DE"); return fmt
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            addBar
            if let errorText { errorLine(errorText) }
            if notes.isEmpty {
                emptyHint("Noch keine Notizen. Lege welche an — hier oder im Assistenten-Chat.")
            } else {
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
                                Spacer()
                                Button { delete(note) } label: {
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
            TextField("Neue Notiz …", text: $draft)
                .font(.mykBody).textFieldStyle(.plain).onSubmit { add() }
            Button("Sichern") { add() }
                .font(.mykSmall).buttonStyle(.plain).foregroundStyle(MykColor.personal.color)
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
