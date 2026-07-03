import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - WorkBasketEditSheet (V10, Block E)
//
// Roomy Editier-Panel für den projektgebundenen `WorkBasket`. Bewusst NICHT im
// schmalen Übersichts-Widget (P0-Layout-Drift-Lehre) — Korrekturen (Menge/Preis,
// Position entfernen) passieren hier, mit sichtbarem SaveState. Persistiert über
// `WorkBasketStore.speichere` (Schreibvertrag: throws, SaveState sichtbar).
//
// Nur `.kalkulation`-Körbe sind editierbar (die Regel lebt testbar in
// `WorkBasketEditing`, MykilosKit — hier nur die UI-Naht).
@MainActor
struct WorkBasketEditSheet: View {
    let store: WorkBasketStore
    let onClose: () -> Void

    @State private var basket: WorkBasket
    @State private var saveError: String?

    init(store: WorkBasketStore, basket: WorkBasket, onClose: @escaping () -> Void) {
        self.store = store
        self.onClose = onClose
        self._basket = State(initialValue: basket)
    }

    private static let preisFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        f.maximumFractionDigits = 2
        return f
    }()

    private var vkSumme: Double { basket.vkNettoSumme }

    /// Zeilen-Modell mit stabiler, positionsabhängiger Identität für `ForEach`.
    private struct IndexedPick: Identifiable {
        let index: Int
        let pick: any Pick
        var id: String { "\(pick.objektID.raw)#\(index)" }
    }

    private var indexedPicks: [IndexedPick] {
        basket.picks.enumerated().map { IndexedPick(index: $0.offset, pick: $0.element) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(MykColor.line.color)

            if basket.picks.isEmpty {
                leer
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Zusammengesetzte Identität (objektID + Index): nach dem Entfernen
                        // einer Position verschieben sich die Indizes → die ID ändert sich →
                        // SwiftUI baut die betroffenen Zeilen frisch auf und initialisiert den
                        // lokalen Preis-State neu (keine verwaiste @State-Zuordnung).
                        ForEach(indexedPicks) { item in
                            WorkBasketEditRow(
                                snapshot: item.pick.snapshot,
                                onMenge: { neu in
                                    basket = WorkBasketEditing.aktualisierePosition(basket, anIndex: item.index, menge: neu)
                                },
                                onPreis: { neu in
                                    basket = WorkBasketEditing.aktualisierePosition(basket, anIndex: item.index, vkEinzel: neu)
                                },
                                onRemove: {
                                    basket = WorkBasketEditing.entfernePosition(basket, anIndex: item.index)
                                }
                            )
                            Divider().overlay(MykColor.line.color)
                        }
                    }
                }
                summenzeile
            }

            Divider().overlay(MykColor.line.color)
            footer
        }
        .frame(width: 520, height: 560)
        .background(MykColor.paper.color)
    }

    // MARK: - Bausteine

    private var header: some View {
        HStack {
            Image(systemName: "cart")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.cash.color)
            VStack(alignment: .leading, spacing: 2) {
                Text("Warenkorb bearbeiten")
                    .font(.mykHeadline)
                    .foregroundStyle(MykColor.ink.color)
                Text("Projekt \(basket.projektNummer) · lokal gespeichert")
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.muted.color)
            }
            Spacer()
            Button { onClose() } label: {
                Image(systemName: "xmark").font(.mykSmall).foregroundStyle(MykColor.muted.color)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, MykSpace.s7)
        .padding(.vertical, MykSpace.s6)
    }

    private var leer: some View {
        VStack(spacing: MykSpace.s4) {
            Spacer()
            Image(systemName: "cart").font(.mykDisplay).foregroundStyle(MykColor.faint.color)
            Text("Keine Positionen mehr im Warenkorb.")
                .font(.mykSmall).foregroundStyle(MykColor.muted.color)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var summenzeile: some View {
        HStack {
            Text("Summe VK netto")
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
            Spacer()
            Text(Self.preisFormatter.string(from: NSNumber(value: vkSumme)) ?? "–")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.cash.color)
        }
        .padding(.horizontal, MykSpace.s7)
        .padding(.vertical, MykSpace.s5)
    }

    private var footer: some View {
        HStack(spacing: MykSpace.s4) {
            saveStateLabel
            Spacer()
            Button("Abbrechen") { onClose() }
                .buttonStyle(.plain)
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
            Button {
                Task { await speichern() }
            } label: {
                Label("Speichern", systemImage: "checkmark")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.paper.color)
                    .padding(.horizontal, MykSpace.s5)
                    .padding(.vertical, MykSpace.s3)
                    .background(MykColor.cash.color)
                    .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            }
            .buttonStyle(.plain)
            .disabled(store.saveState == .saving)
        }
        .padding(.horizontal, MykSpace.s7)
        .padding(.vertical, MykSpace.s5)
    }

    @ViewBuilder
    private var saveStateLabel: some View {
        switch store.saveState {
        case .idle:
            EmptyView()
        case .saving:
            HStack(spacing: MykSpace.s2) {
                ProgressView().controlSize(.small)
                Text("Speichert …").font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
        case .saved:
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(MykColor.positive.color)
                Text("Gespeichert").font(.mykMono(9.5)).foregroundStyle(MykColor.positive.color)
            }
        case .failed(let msg):
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(MykColor.critical.color)
                Text(saveError ?? msg).font(.mykMono(9.5)).foregroundStyle(MykColor.critical.color).lineLimit(1)
            }
        }
    }

    private func speichern() async {
        saveError = nil
        do {
            try await store.speichere(basket)
            onClose()
        } catch {
            saveError = error.localizedDescription
        }
    }
}

// MARK: - WorkBasketEditRow
private struct WorkBasketEditRow: View {
    let snapshot: PickSnapshot
    let onMenge: (Int) -> Void
    let onPreis: (Double) -> Void
    let onRemove: () -> Void

    @State private var preisText: String = ""

    var body: some View {
        HStack(alignment: .center, spacing: MykSpace.s4) {
            VStack(alignment: .leading, spacing: MykSpace.s2) {
                Text(snapshot.bezeichnung)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.ink.color)
                    .lineLimit(2)
                if let art = snapshot.attribute["artikelnummer"], art.isEmpty == false {
                    Text(art)
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.muted.color)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // VK-Einzelpreis (netto), editierbar
            VStack(alignment: .trailing, spacing: 2) {
                TextField("VK", text: $preisText)
                    .font(.mykMono(10))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 74)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: preisText) { _, _ in commitPreisLive() }
                    .onSubmit { commitPreisStrikt() }
                Text("VK netto €").font(.mykMono(8)).foregroundStyle(MykColor.faint.color)
            }

            // Mengen-Stepper
            HStack(spacing: MykSpace.s2) {
                stepperButton("minus") { onMenge(max(0, snapshot.menge - 1)) }
                Text("\(snapshot.menge)")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.ink.color)
                    .frame(width: 26, alignment: .center)
                stepperButton("plus") { onMenge(snapshot.menge + 1) }
            }

            Button { onRemove() } label: {
                Image(systemName: "trash")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.critical.color)
            }
            .buttonStyle(.plain)
            .help("Position entfernen")
        }
        .padding(.horizontal, MykSpace.s7)
        .padding(.vertical, MykSpace.s4)
        .onAppear { preisText = initialPreisText }
    }

    private var initialPreisText: String {
        guard let vk = snapshot.vkEinzel else { return "" }
        // Ganze Beträge ohne Nachkommastellen, sonst 2 Stellen — deutsches Komma.
        if vk == vk.rounded() {
            return String(format: "%.0f", vk)
        }
        return String(format: "%.2f", vk).replacingOccurrences(of: ".", with: ",")
    }

    private func parsePreis() -> Double? {
        let normalized = preisText
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard let wert = Double(normalized), wert >= 0 else { return nil }
        return wert
    }

    /// Live: gültige Eingabe wird sofort übernommen (Summe aktualisiert sich mit).
    /// Ungültige/leere Zwischenstände lassen den Text unangetastet (kein Cursor-Sprung).
    private func commitPreisLive() {
        if let wert = parsePreis() { onPreis(wert) }
    }

    /// Enter: ungültige Eingabe auf den letzten gültigen Wert zurücksetzen.
    private func commitPreisStrikt() {
        if let wert = parsePreis() { onPreis(wert) } else { preisText = initialPreisText }
    }

    private func stepperButton(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.mykMono(9))
                .frame(width: 22, height: 22)
                .background(MykColor.card.color)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }
}
