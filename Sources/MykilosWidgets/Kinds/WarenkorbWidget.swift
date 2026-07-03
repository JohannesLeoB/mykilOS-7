import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - WarenkorbWidget (V10, Block E — Quelle der Wahrheit = persistierter WorkBasket)
//
// Zeigt den aktuellsten am Projekt persistierten `WorkBasket` (GRDB, lokal, local-first)
// über `WorkBasketStore` — NICHT mehr den read-only Airtable-`WarenkorbListeStore`.
// Damit ist der Projekt-Warenkorb genau EINE Quelle der Wahrheit und editierbar
// (Menge/Preis korrigieren, Position entfernen — im „Bearbeiten"-Sheet, mit
// sichtbarem SaveState). Positionen + EK/VK-Summen. Tiefblau (cash).
//
// Der Airtable-Versandpfad (`WarenkorbState`/`CartStore`) bleibt für den globalen
// Session-Warenkorb unverändert bestehen — dieser Widget-Pfad ist der lokale,
// projektgebundene Nachfolge-Speicher der Wirbelsäule (C3/Block C+D).
public struct WarenkorbWidget: View {
    public let store: WorkBasketStore
    public let projectID: String        // Projektnummer (JJJJ-NNN)
    public let projektName: String?     // Menschlicher Projektname

    public init(store: WorkBasketStore, projectID: String, projektName: String? = nil) {
        self.store = store
        self.projectID = projectID
        self.projektName = projektName
    }

    @State private var basket: WorkBasket?
    @State private var loadError: String?
    @State private var didLoad = false
    @State private var showEdit = false

    private static let preisFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        f.maximumFractionDigits = 0
        return f
    }()

    public var body: some View {
        WidgetContainer(
            kind: .warenkorb,
            sourceLabel: sourceLabel,
            renderState: renderState,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                header
                if let basket, basket.picks.isEmpty == false {
                    positionsListe(basket)
                    summenLeiste(basket)
                } else {
                    leerHinweis
                }
            }
        }
        .task(id: projectID) { reload() }
        .sheet(isPresented: $showEdit) {
            if let basket {
                WorkBasketEditSheet(store: store, basket: basket, onClose: {
                    showEdit = false
                    reload()
                })
            }
        }
    }

    // MARK: - Laden (lokal, GRDB — Cold-Start-safe, kein Netzwerk)

    private func reload() {
        do {
            let alle = try store.alle(projektNummer: projectID)
            // Aktuellster Korb (jüngster Erstellzeitpunkt) ist der maßgebliche.
            basket = alle.max(by: { $0.erstellt < $1.erstellt })
            loadError = nil
        } catch {
            loadError = String(describing: error)
        }
        didLoad = true
    }

    // MARK: - Renderstates

    private var renderState: WidgetRenderState {
        if didLoad == false { return .loading }
        if let loadError { return .error(loadError) }
        // Leerer/kein Korb → wir rendern den projektspezifischen Leer-Hinweis im Content.
        return .content
    }

    // MARK: - Bausteine

    private var eingefroren: Bool { basket?.status.istEingefroren ?? false }

    private var sourceLabel: String {
        if let basket {
            return "WARENKORB (LOKAL)  ·  \(basket.picks.count) POSITIONEN"
        }
        return "WARENKORB (LOKAL)"
    }

    private var header: some View {
        HStack {
            SourceChip(kind: .warenkorb)
            Text("Warenkorb").mykWidgetTitle()
            Spacer()
            if let basket, basket.picks.isEmpty == false {
                if eingefroren {
                    Text("BESTÄTIGT")
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.positive.color)
                } else {
                    Button { showEdit = true } label: {
                        Label("Bearbeiten", systemImage: "slider.horizontal.3")
                            .font(.mykMono(9.5))
                            .foregroundStyle(MykColor.cash.color)
                    }
                    .buttonStyle(.plain)
                    .help("Menge/Preis korrigieren oder Position entfernen")
                    .accessibilityLabel("Warenkorb bearbeiten")
                }
            }
        }
    }

    private var leerHinweis: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "cart")
                    .font(.mykBody)
                    .foregroundStyle(MykColor.faint.color)
                Text("Noch kein Warenkorb für dieses Projekt")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            }
            Text("Über den Intake-Fragebogen entsteht der Projekt-Warenkorb automatisch.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, MykSpace.s3)
    }

    // Positionsliste (max. 6 sichtbar, Rest als „+N weitere").
    private func positionsListe(_ basket: WorkBasket) -> some View {
        let sichtbar = Array(basket.picks.prefix(6))
        let rest = basket.picks.count - sichtbar.count
        return VStack(spacing: 0) {
            ForEach(Array(sichtbar.enumerated()), id: \.offset) { idx, pick in
                WarenkorbWidgetZeile(snapshot: pick.snapshot, preisFormatter: Self.preisFormatter)
                if idx != sichtbar.count - 1 {
                    Divider().overlay(MykColor.line.color.opacity(0.6))
                }
            }
            if rest > 0 {
                HStack {
                    Text("+ \(rest) weitere Position\(rest == 1 ? "" : "en")")
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.muted.color)
                    Spacer()
                }
                .padding(.top, MykSpace.s3)
            }
        }
    }

    private func summenLeiste(_ basket: WorkBasket) -> some View {
        let ek = basket.picks.reduce(0.0) { $0 + ($1.snapshot.ekEinzel ?? 0) * Double($1.snapshot.menge) }
        let vk = basket.vkNettoSumme
        let stueck = basket.picks.reduce(0) { $0 + $1.snapshot.menge }
        return HStack(spacing: MykSpace.s6) {
            summenFeld("EK", wert: ek, farbe: MykColor.muted)
            summenFeld("VK", wert: vk, farbe: MykColor.cash)
            Spacer()
            Text("\(stueck) Stück")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)
        }
        .padding(.top, MykSpace.s3)
        .overlay(alignment: .top) { Divider().overlay(MykColor.line.color) }
        .padding(.top, MykSpace.s2)
    }

    private func summenFeld(_ titel: String, wert: Double, farbe: MykColor) -> some View {
        HStack(spacing: MykSpace.s2) {
            Text(titel).font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
            Text(Self.preisFormatter.string(from: NSNumber(value: wert)) ?? "–")
                .font(.mykMono(11))
                .foregroundStyle(farbe.color)
        }
    }
}

// MARK: - WarenkorbWidgetZeile
private struct WarenkorbWidgetZeile: View {
    let snapshot: PickSnapshot
    let preisFormatter: NumberFormatter

    var body: some View {
        HStack(alignment: .top, spacing: MykSpace.s4) {
            Text("\(snapshot.menge)×")
                .font(.mykMono(10))
                .foregroundStyle(MykColor.cash.color)
                .frame(width: 28, alignment: .trailing)
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.bezeichnung)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.ink.color)
                    .lineLimit(1)
                if let art = snapshot.attribute["artikelnummer"], art.isEmpty == false {
                    Text(art)
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.muted.color)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: MykSpace.s3)
            if let vk = snapshot.vkEinzel {
                Text(preisFormatter.string(from: NSNumber(value: vk * Double(snapshot.menge))) ?? "–")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.inkSoft.color)
            }
        }
        .padding(.vertical, MykSpace.s3)
    }
}
