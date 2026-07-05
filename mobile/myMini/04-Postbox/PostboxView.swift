import SwiftUI

/// Die sichtbare Postbox — nicht nur eine Zahl im FangCard-Fußtext, sondern die
/// echte Liste. Nur "zeit"-Einträge lassen sich synchronisieren (bestätigtes
/// ★1-Ziel: Adapter-Base Zeitbuchungen). "idee"-Einträge bleiben lokal geparkt,
/// ihre Ziel-Heimat ist bewusst noch offen — bis dahin per System-Share-Sheet
/// exportierbar (Notizen, Nachricht, wohin auch immer), statt nutzlos zu warten.
/// Verunglückte Einträge lassen sich per Swipe löschen — aber nur solange sie
/// noch nicht synchronisiert sind (danach würde lokales Löschen den echten
/// Airtable-Record nicht mitlöschen, das wäre irreführend).
struct PostboxView: View {
    let postbox: PostboxStore
    @State private var zeigeEinstellungen = false
    @State private var verbunden = false
    @State private var laeuftGerade: Set<UUID> = []
    @State private var fehler: [UUID: String] = [:]

    private let client = AirtableClockodoPostboxClient()
    private let credentialsStore: AirtablePostboxCredentialsStoring = KeychainAirtablePostboxCredentialsStore()

    var body: some View {
        List {
            if postbox.items.isEmpty {
                ContentUnavailableView(
                    "Postbox leer",
                    systemImage: "tray",
                    description: Text("Noch nichts gefangen.")
                )
            } else {
                ForEach(postbox.items.reversed()) { item in
                    row(for: item)
                        .swipeActions(edge: .trailing) {
                            if item.syncedAt == nil {
                                Button("Löschen", role: .destructive) {
                                    try? postbox.remove(item.id)
                                }
                            }
                        }
                }
            }
        }
        .navigationTitle("Postbox")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    zeigeEinstellungen = true
                } label: {
                    Image(systemName: verbunden ? "checkmark.circle.fill" : "key")
                }
                .accessibilityLabel(verbunden ? "Mit Airtable verbunden" : "Airtable-Einstellungen")
            }
        }
        .sheet(isPresented: $zeigeEinstellungen) {
            AirtablePostboxSettingsView(credentialsStore: credentialsStore, verbunden: $verbunden)
        }
        .task {
            verbunden = (try? credentialsStore.load()) != nil
        }
    }

    @ViewBuilder
    private func row(for item: PostboxItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Image(systemName: item.kind == "zeit" ? "clock" : "lightbulb")
                    .foregroundStyle(item.kind == "zeit" ? MykColor.brand : MykColor.plum)
                Text(item.text).font(.subheadline.weight(.semibold))
                Spacer()
                statusView(for: item)
            }
            if !item.kontext.isEmpty {
                Text(item.kontext).font(.caption).foregroundStyle(MykColor.muted)
            }
            Text(item.capturedAt, style: .relative)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(MykColor.muted)
            if let text = fehler[item.id] {
                Text(text).font(.caption2).foregroundStyle(MykColor.crit)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func statusView(for item: PostboxItem) -> some View {
        if item.syncedAt != nil {
            Label("Gesendet", systemImage: "checkmark")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MykColor.ok)
        } else if item.kind == "idee" {
            HStack(spacing: 6) {
                Text("wartet auf Ziel")
                    .font(.caption2)
                    .foregroundStyle(MykColor.muted)
                ShareLink(item: item.text) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                }
                .accessibilityLabel("Idee teilen")
            }
        } else if laeuftGerade.contains(item.id) {
            ProgressView().controlSize(.small)
        } else {
            Button("Sync") { sync(item) }
                .font(.caption2.weight(.semibold))
                .buttonStyle(.bordered)
                .tint(MykColor.brand)
                .disabled(!verbunden)
        }
    }

    private func sync(_ item: PostboxItem) {
        fehler[item.id] = nil
        laeuftGerade.insert(item.id)
        Task {
            defer { laeuftGerade.remove(item.id) }
            do {
                try await client.sync(item)
                try postbox.markSynced(item.id)
            } catch {
                fehler[item.id] = Fehlertext.deutsch(error)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PostboxView(postbox: PostboxStore())
    }
}
