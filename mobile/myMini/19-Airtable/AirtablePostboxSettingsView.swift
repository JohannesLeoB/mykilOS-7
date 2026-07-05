import SwiftUI

/// Zwei Zustände, ein Sheet. Der Token landet ausschließlich im Schlüsselbund —
/// erscheint hier nie geloggt, nie im Code, nie im Chat.
struct AirtablePostboxSettingsView: View {
    let credentialsStore: AirtablePostboxCredentialsStoring
    @Binding var verbunden: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var token = ""
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
                        SecureField("Airtable Personal Access Token", text: $token)
                        Button("Verbinden") { verbinden() }
                            .disabled(token.isEmpty)
                    }
                } footer: {
                    Text("Landet ausschließlich im iPhone-Schlüsselbund — nie im Code, nie im Chat, nie im Repo.")
                }
                if let fehler {
                    Text(fehler).foregroundStyle(MykColor.crit)
                }
            }
            .navigationTitle("Airtable Postbox")
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
            let bereinigt = token.trimmingCharacters(in: .whitespacesAndNewlines)
            try credentialsStore.save(AirtablePostboxCredentials(pat: bereinigt))
            verbunden = true
            token = ""
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
