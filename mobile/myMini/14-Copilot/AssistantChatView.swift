import SwiftUI

/// ★4 — Claude selbst, im Gespräch. Gegründet auf den echten Projekt-Registry-
/// Snapshot (Projektnummer als Wahrheit, nie Freitext-Namen — Lehre aus
/// Live-Beweis ① "Freitext-Anker lügen"). Reiner Lese-Blick: schreibt nirgends,
/// bestätigt keine Buchungen, legt nichts an. Kein eigener Fang-Kanal — dafür
/// gibt's die Fang-Karte.
struct AssistantChatView: View {
    let store: ProjectStore
    @State private var historie = ChatHistoryStore()
    @State private var eingabe = ""
    @State private var laeuft = false
    @State private var fehler: String?
    @State private var verbunden = false
    @State private var zeigeEinstellungen = false
    @State private var zeigeLoeschenBestaetigung = false

    private let client = ClaudeMessagesClient()
    private let credentialsStore: ClaudeCredentialsStoring = KeychainClaudeCredentialsStore()

    private var systemPrompt: String {
        let projekte = store.projects
            .sorted { $0.projectNumber > $1.projectNumber }
            .map { "\($0.projectNumber) · \($0.title) · \($0.kind)" }
            .joined(separator: "\n")
        return """
        Du bist der Assistent im mykilOS-Satelliten, der mobilen Begleit-App zum \
        Mothership von Johannes, einem Tischler/Produktdesigner/Projektleiter. \
        Antworte kurz und auf Deutsch. Du liest nur — du schreibst nichts, \
        bestätigst keine Buchungen, legst nichts an. Freitext-Namen können \
        täuschen (ein Kunde namens 'Schmidt' ist nicht automatisch Projekt \
        'Schmidt') — verlass dich auf die Projektnummer als Wahrheit, nicht auf \
        den Namen allein.

        Echte, aktuelle Projekte (Nummer · Titel · Art):
        \(projekte)
        """
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if historie.nachrichten.isEmpty { leerZustand }
                        ForEach(historie.nachrichten) { nachricht in bubble(for: nachricht) }
                        if laeuft {
                            ProgressView().padding(.leading, 4)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: historie.nachrichten.count) {
                    if let last = historie.nachrichten.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            if let fehler {
                Text(fehler)
                    .font(.footnote)
                    .foregroundStyle(MykColor.crit)
                    .padding(.horizontal, 16)
            }
            eingabeleiste
        }
        .background(MykColor.paper)
        .navigationTitle("Assistent")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    zeigeEinstellungen = true
                } label: {
                    Image(systemName: verbunden ? "checkmark.circle.fill" : "key")
                }
                .accessibilityLabel(verbunden ? "Mit Claude verbunden" : "Claude-Einstellungen")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    zeigeLoeschenBestaetigung = true
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(historie.nachrichten.isEmpty)
                .accessibilityLabel("Verlauf löschen")
            }
        }
        .confirmationDialog(
            "Verlauf löschen?",
            isPresented: $zeigeLoeschenBestaetigung,
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) { try? historie.loeschen() }
            Button("Abbrechen", role: .cancel) {}
        }
        .sheet(isPresented: $zeigeEinstellungen) {
            ClaudeSettingsView(credentialsStore: credentialsStore, verbunden: $verbunden)
        }
        .task {
            verbunden = (try? credentialsStore.load()) != nil
        }
    }

    private var leerZustand: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Frag mich was.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MykColor.ink)
            Text("Ich kenne deine \(store.projects.count) echten Projekte — les-only, ich schreibe nichts.")
                .font(.footnote)
                .foregroundStyle(MykColor.muted)
        }
    }

    @ViewBuilder
    private func bubble(for nachricht: ChatMessage) -> some View {
        HStack {
            if nachricht.rolle == .assistant {
                Text(nachricht.text)
                    .font(.subheadline)
                    .padding(11)
                    .background(MykColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(MykColor.line))
                Spacer(minLength: 24)
            } else {
                Spacer(minLength: 24)
                Text(nachricht.text)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(11)
                    .background(MykColor.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .id(nachricht.id)
    }

    private var eingabeIstLeer: Bool {
        eingabe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var eingabeleiste: some View {
        HStack(spacing: 8) {
            TextField("Frag den Assistenten…", text: $eingabe)
                .textFieldStyle(.plain)
                .padding(11)
                .background(MykColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(MykColor.line))
                .onSubmit { senden() }

            Button {
                senden()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(verbunden && !eingabeIstLeer ? MykColor.brand : MykColor.muted)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!verbunden || eingabeIstLeer || laeuft)
        }
        .padding(16)
    }

    private func senden() {
        guard !eingabeIstLeer, verbunden, !laeuft else { return }
        let frage = eingabe.trimmingCharacters(in: .whitespacesAndNewlines)
        eingabe = ""
        fehler = nil
        do {
            try historie.append(ChatMessage(rolle: .user, text: frage))
        } catch {
            fehler = Fehlertext.deutsch(error)
            return
        }
        laeuft = true
        Task {
            defer { laeuft = false }
            do {
                let antwort = try await client.antwort(auf: historie.nachrichten, system: systemPrompt)
                try historie.append(ChatMessage(rolle: .assistant, text: antwort))
            } catch {
                fehler = Fehlertext.deutsch(error)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AssistantChatView(store: ProjectStore())
    }
}
