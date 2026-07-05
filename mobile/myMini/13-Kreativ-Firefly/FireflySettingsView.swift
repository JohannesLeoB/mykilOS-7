import SwiftUI

/// Zugang zu Adobe Firefly Services — Client ID + Secret aus der Adobe
/// Developer Console (OAuth Server-to-Server). Landet ausschliesslich im
/// Schluesselbund. Erst damit wird aus "Prompt kopieren" der In-App-Render.
struct FireflySettingsView: View {
    let credentialsStore: FireflyCredentialsStoring
    @Binding var verbunden: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var clientID = ""
    @State private var clientSecret = ""
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
                        SecureField("Client ID (API Key)", text: $clientID)
                            .textInputAutocapitalization(.never)
                        SecureField("Client Secret", text: $clientSecret)
                            .textInputAutocapitalization(.never)
                        Button("Verbinden") { verbinden() }
                            .disabled(clientID.isEmpty || clientSecret.isEmpty)
                    }
                } header: {
                    Text("Adobe Firefly Services")
                } footer: {
                    Text("Aus der Adobe Developer Console: Projekt -> Firefly Services -> OAuth Server-to-Server. Beide Werte landen ausschliesslich im iPhone-Schluesselbund - nie im Code, Chat oder Repo.")
                }
                if let fehler {
                    Text(fehler).foregroundStyle(MykColor.crit)
                }
            }
            .navigationTitle("Firefly-Zugang")
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
            try credentialsStore.save(FireflyCredentials(
                clientID: clientID.trimmingCharacters(in: .whitespacesAndNewlines),
                clientSecret: clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)))
            verbunden = true
            clientID = ""
            clientSecret = ""
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
