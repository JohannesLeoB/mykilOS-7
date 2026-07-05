import SwiftUI

/// Client-ID wird hier einmalig eingetippt (nicht hardcodiert, gleiches
/// Prinzip wie im Mothership) — danach übernimmt der echte Google-Sign-In-
/// Dialog. Alles landet nur im Schlüsselbund.
struct GoogleSignInSettingsView: View {
    let credentialsStore: GoogleCredentialsStoring
    @Binding var verbunden: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var clientID = ""
    @State private var fehler: String?
    @State private var laeuft = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if verbunden {
                        Label("Verbunden", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(MykColor.ok)
                        Button("Trennen", role: .destructive) { trennen() }
                    } else {
                        TextField("iOS-Client-ID (…apps.googleusercontent.com)", text: $clientID)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button {
                            Task { await anmelden() }
                        } label: {
                            if laeuft {
                                ProgressView()
                            } else {
                                Text("Bei Google anmelden")
                            }
                        }
                        .disabled(clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || laeuft)
                    }
                } footer: {
                    Text("Nur der drive.file-Scope zum Schreiben (+ ein schmaler Lese-Scope zum Auffinden des Zielordners) wird angefragt. Landet ausschließlich im iPhone-Schlüsselbund.")
                }
                if let fehler {
                    Text(fehler).foregroundStyle(MykColor.crit)
                }
            }
            .navigationTitle("Google Drive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }

    private func anmelden() async {
        fehler = nil
        laeuft = true
        defer { laeuft = false }
        let id = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let service = GoogleOAuthPKCEService(clientID: id)
            let tokens = try await service.meldeAn()
            try credentialsStore.save(GoogleCredentials(
                clientID: id,
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken,
                ablaufDatum: tokens.ablaufDatum
            ))
            verbunden = true
            clientID = ""
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
