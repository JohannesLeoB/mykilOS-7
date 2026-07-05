import SwiftUI
import UIKit

/// Die sichtbare Feld-Foto-Liste — mirrort `PostboxView`. Sync-Knopf ruft
/// jetzt echt `GoogleDriveUploadClient` auf. **Erster echter Test einer im
/// Mothership nie live bestätigten Annahme** (drive.file in vorhandene
/// Ordner schreiben) — ein 403 hier ist ein Befund, kein Bug, siehe
/// playbooks/03_feld-foto-verraeumen.md.
struct FeldFotoListView: View {
    let feldFotoStore: FeldFotoStore
    let store: ProjectStore

    @State private var verbunden = false
    @State private var zeigeEinstellungen = false
    @State private var laeuftGerade: Set<UUID> = []
    @State private var fehler: [UUID: String] = [:]

    private let client = GoogleDriveUploadClient()
    private let credentialsStore: GoogleCredentialsStoring = KeychainGoogleCredentialsStore()

    var body: some View {
        List {
            if feldFotoStore.fotos.isEmpty {
                ContentUnavailableView(
                    "Noch keine Feld-Fotos",
                    systemImage: "camera",
                    description: Text("Kamera-Knopf in der Fang-Karte antippen.")
                )
            } else {
                ForEach(feldFotoStore.fotos.reversed()) { foto in
                    row(for: foto)
                        .swipeActions(edge: .trailing) {
                            if foto.syncedAt == nil {
                                Button("Löschen", role: .destructive) {
                                    try? feldFotoStore.remove(foto.id)
                                }
                            }
                        }
                        .contextMenu {
                            Button {
                                try? feldFotoStore.setzeFoerderrelevant(foto.id, foerderrelevant: !foto.foerderrelevant)
                            } label: {
                                Label(
                                    foto.foerderrelevant ? "Förderrelevant entfernen" : "Förderrelevant markieren",
                                    systemImage: foto.foerderrelevant ? "checkmark.seal.fill" : "checkmark.seal"
                                )
                            }
                        }
                }
            }
        }
        .navigationTitle("Feld-Fotos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    FoerderBeweispaketView(feldFotoStore: feldFotoStore, store: store)
                } label: {
                    Image(systemName: "rosette")
                }
                .accessibilityLabel("Förderungs-Beweispakete")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    zeigeEinstellungen = true
                } label: {
                    Image(systemName: verbunden ? "checkmark.circle.fill" : "key")
                }
                .accessibilityLabel(verbunden ? "Mit Google Drive verbunden" : "Google-Drive-Einstellungen")
            }
        }
        .sheet(isPresented: $zeigeEinstellungen) {
            GoogleSignInSettingsView(credentialsStore: credentialsStore, verbunden: $verbunden)
        }
        .task {
            verbunden = (try? credentialsStore.load()) != nil
        }
    }

    @ViewBuilder
    private func row(for foto: FeldFoto) -> some View {
        HStack(alignment: .top, spacing: 11) {
            if let bild = UIImage(contentsOfFile: feldFotoStore.bildURL(fuer: foto).path) {
                Image(uiImage: bild)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(foto.projectTitel).font(.subheadline.weight(.semibold))
                    if foto.foerderrelevant {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(MykColor.sage)
                            .accessibilityLabel("Förderrelevant")
                    }
                }
                Text("\(foto.kanonZiel.titel) · \(foto.kanonZiel.ordner)")
                    .font(.caption)
                    .foregroundStyle(MykColor.muted)
                Text(foto.aufgenommenAm, style: .relative)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(MykColor.muted)
                if let text = fehler[foto.id] {
                    Text(text).font(.caption2).foregroundStyle(MykColor.crit)
                }
            }
            Spacer()
            statusView(for: foto)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func statusView(for foto: FeldFoto) -> some View {
        if foto.syncedAt != nil {
            Label("Gesendet", systemImage: "checkmark")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MykColor.ok)
        } else if laeuftGerade.contains(foto.id) {
            ProgressView().controlSize(.small)
        } else {
            Button("Sync") { sync(foto) }
                .font(.caption2.weight(.semibold))
                .buttonStyle(.bordered)
                .tint(MykColor.brand)
                .disabled(!verbunden)
        }
    }

    private func sync(_ foto: FeldFoto) {
        fehler[foto.id] = nil
        guard let projekt = store.projects.first(where: { $0.projectNumber == foto.projectNumber }) else {
            fehler[foto.id] = "Projekt nicht mehr in der Registry gefunden."
            return
        }
        laeuftGerade.insert(foto.id)
        Task {
            defer { laeuftGerade.remove(foto.id) }
            do {
                let driveFileID = try await client.hochladen(
                    foto: foto,
                    bildURL: feldFotoStore.bildURL(fuer: foto),
                    projektDriveOrdnerID: projekt.driveFolderID
                )
                try feldFotoStore.markSynced(foto.id, driveFileID: driveFileID)
            } catch {
                fehler[foto.id] = Fehlertext.deutsch(error)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FeldFotoListView(feldFotoStore: FeldFotoStore(), store: ProjectStore())
    }
}
