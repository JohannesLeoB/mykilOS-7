import SwiftUI

/// Kunden-Verzeichnis aus der Mastermind-Base: suchen, anrufen, mailen,
/// Route in Karten oeffnen. Read-only-Spiegel mit neustart-festem Cache —
/// einmal geladen, auch offline auf der Baustelle da.
struct KontakteVerzeichnisView: View {
    @State private var store = KontakteStore()
    @State private var suche = ""
    @Environment(\.openURL) private var openURL

    private var gefiltert: [KundenKontakt] {
        guard !suche.isEmpty else { return store.kontakte }
        return store.kontakte.filter { $0.name.localizedCaseInsensitiveContains(suche) }
    }

    var body: some View {
        List {
            Section {
                TextField("Kunde suchen...", text: $suche)
                if store.kontakte.isEmpty && store.fehler == nil {
                    Text("Noch nichts geladen - oben rechts aktualisieren.")
                        .font(.footnote)
                        .foregroundStyle(MykColor.muted)
                }
                ForEach(gefiltert) { kontakt in
                    zeile(kontakt)
                }
            } footer: {
                Text("AIRTABLE / KUNDEN / READ-ONLY - Aendern weiter in Airtable, die App schreibt nie zurueck.")
            }

            if let fehler = store.fehler {
                Text(fehler).foregroundStyle(MykColor.crit)
            }
        }
        .navigationTitle("Kontakte")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if store.laedtGerade {
                    ProgressView()
                } else {
                    Button {
                        Task { await store.aktualisieren() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Kontakte aus Airtable aktualisieren")
                }
            }
        }
    }

    @ViewBuilder
    private func zeile(_ kontakt: KundenKontakt) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(kontakt.name).font(.subheadline.weight(.semibold))
            if let adresse = kontakt.adresse {
                Text(adresse).font(.caption).foregroundStyle(MykColor.muted)
            }
            HStack(spacing: 10) {
                if let url = kontakt.telefonURL {
                    aktionsKnopf("phone.fill", "Anrufen") { openURL(url) }
                }
                if let url = kontakt.mailURL {
                    aktionsKnopf("envelope.fill", "Mail") { openURL(url) }
                }
                if let url = kontakt.kartenURL {
                    aktionsKnopf("map.fill", "Route") { openURL(url) }
                }
            }
        }
        .padding(.vertical, 3)
    }

    private func aktionsKnopf(_ symbol: String, _ label: String, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            Label(label, systemImage: symbol)
                .font(.caption.weight(.semibold))
        }
        .buttonStyle(.bordered)
        .tint(MykColor.brand)
    }
}

#Preview {
    NavigationStack {
        KontakteVerzeichnisView()
    }
}
