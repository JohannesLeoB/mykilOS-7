import SwiftUI

/// Zwei Zustände, ein Sheet — gleiches Muster wie `AirtablePostboxSettingsView`.
/// Der Key landet ausschließlich im Schlüsselbund.
struct ClaudeSettingsView: View {
    let credentialsStore: ClaudeCredentialsStoring
    @Binding var verbunden: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var fehler: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if verbunden {
                        Label("Verbunden", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(MykColor.ok)
                        Button("Trennen", role: .destructive) { trennen() }
                    } else {
                        SecureField("Anthropic API-Key", text: $apiKey)
                        Button("Verbinden") { verbinden() }
                            .disabled(apiKey.isEmpty)
                    }
                } footer: {
                    Text("Landet ausschließlich im iPhone-Schlüsselbund — nie im Code, nie im Chat, nie im Repo.")
                }
                if let fehler {
                    Text(fehler).foregroundStyle(MykColor.crit)
                }
            }
            .navigationTitle("Assistent-Zugang")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }

    private func verbinden() {
        do {
            let bereinigt = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            try credentialsStore.save(ClaudeCredentials(apiKey: bereinigt))
            verbunden = true
            apiKey = ""
            fehler = nil
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }

    private func trennen() {
        do {
            try credentialsStore.clear()
            verbunden = false
            fehler = nil
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }
}
