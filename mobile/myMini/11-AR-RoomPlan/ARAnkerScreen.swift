import ARKit
import SwiftUI

/// AR-Anker für Gewerke (#6): Wasser/Strom/Abfluss/Sonstiges im Raum
/// markieren, dann als Foto speichern — der Screenshot enthält die Marker
/// direkt. Landet in derselben Karte→Bestätigung wie jedes Feld-Foto
/// (`FeldFotoBestaetigungView`, kein Doppelbau der Projekt-Zuordnung).
/// **Nicht live testbar von hier** — Ebenen-Erkennung und Marker-Platzierung
/// hängen stark von Gerät/Umgebung ab, bleibt ein Beta-Check.
struct ARAnkerScreen: View {
    let store: ProjectStore
    let feldFotoStore: FeldFotoStore

    @State private var ausgewaehlterTyp: GewerkeTyp = .wasser
    @State private var snapshotAnfrage = false
    @State private var frischesBild: FrischesARBild?

    var body: some View {
        Group {
            if ARWorldTrackingConfiguration.isSupported {
                ZStack(alignment: .bottom) {
                    ARAnkerBridge(
                        aktuellerTyp: ausgewaehlterTyp,
                        snapshotAnfrage: $snapshotAnfrage,
                        onSnapshot: { bild in frischesBild = FrischesARBild(bild: bild) }
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 12) {
                        typAuswahl
                        Button {
                            snapshotAnfrage = true
                        } label: {
                            Label("Foto mit Markierungen speichern", systemImage: "camera.fill")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(MykColor.brand)
                    }
                    .padding(16)
                }
            } else {
                ContentUnavailableView(
                    "AR nicht unterstützt",
                    systemImage: "arkit",
                    description: Text("Dieses Gerät unterstützt keine AR-Weltverfolgung.")
                )
            }
        }
        .navigationTitle("AR-Anker · Gewerke")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $frischesBild) { frisch in
            FeldFotoBestaetigungView(
                bild: frisch.bild,
                aufgenommenAm: Date(),
                store: store,
                feldFotoStore: feldFotoStore,
                onFertig: { frischesBild = nil }
            )
        }
    }

    private var typAuswahl: some View {
        HStack(spacing: 8) {
            ForEach(GewerkeTyp.allCases) { typ in
                Button {
                    ausgewaehlterTyp = typ
                } label: {
                    Label(typ.rawValue, systemImage: typ.symbol)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .tint(ausgewaehlterTyp == typ ? MykColor.brand : MykColor.muted)
            }
        }
    }
}

private struct FrischesARBild: Identifiable {
    let id = UUID()
    let bild: UIImage
}

#Preview {
    NavigationStack {
        ARAnkerScreen(store: ProjectStore(), feldFotoStore: FeldFotoStore())
    }
}
