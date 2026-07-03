import SwiftUI
import MykilosDesign
import MykilosServices
import MykilosKit

// MARK: - WarenkorbPanel
// Schwebendes Panel / Sheet für den Warenkorb-Inhalt.
// Zeigt alle Positionen, Mengen (editierbar), Summen EK/VK.
// „An Airtable senden" öffnet WarenkorbVersandView (Projekt wählen + Bezeichnung + Bestätigung).
@MainActor
struct WarenkorbPanel: View {
    @Bindable var warenkorb: WarenkorbState
    @Environment(AppState.self) private var appState

    @State private var showVersand = false
    @State private var showDevCheckout = false
    @State private var showPreview = false

    // MARK: - Task B: Suche/Sortieren/Filtern/Gruppieren (session-lokal, kein Persistenz-Bedarf)
    @State private var query: String = ""
    @State private var sort: WarenkorbSort = .bezeichnung
    @State private var aktiveQuellenFilter: Set<String> = []   // leer = alle Quellen
    @State private var gruppieren: Bool = false

    enum WarenkorbSort: String, CaseIterable, Identifiable {
        case bezeichnung = "Bezeichnung"
        case menge = "Menge"
        case vkWert = "VK-Wert"
        case quelle = "Quelle"
        var id: String { rawValue }
    }

    private static let preisFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        f.maximumFractionDigits = 2
        return f
    }()

    /// Alle in `warenkorb.positionen` tatsächlich vorkommenden Quellen — Basis für die
    /// Filter-Chips. Nur echte Quellen anzeigen (keine leeren Chips für nicht genutzte).
    private var vorhandeneQuellen: [String] {
        Array(Set(warenkorb.positionen.map(\.source))).sorted()
    }

    /// Suche (Bezeichnung/Artikelnummer) → Quellen-Filter → Sortierung.
    private var sichtbarePositionen: [WarenkorbState.Position] {
        var items = warenkorb.positionen
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            items = items.filter {
                $0.bezeichnung.lowercased().contains(q) || $0.artikelnummer.lowercased().contains(q)
            }
        }
        if !aktiveQuellenFilter.isEmpty {
            items = items.filter { aktiveQuellenFilter.contains($0.source) }
        }
        switch sort {
        case .bezeichnung: items.sort { $0.bezeichnung.localizedCaseInsensitiveCompare($1.bezeichnung) == .orderedAscending }
        case .menge: items.sort { $0.menge > $1.menge }
        case .vkWert: items.sort { ($0.vkNetto ?? 0) * Double($0.menge) > ($1.vkNetto ?? 0) * Double($1.menge) }
        case .quelle: items.sort { $0.source < $1.source }
        }
        return items
    }

    /// Gruppiert nach Quelle (nur wenn `gruppieren == true`), sortierte Gruppenreihenfolge.
    private var gruppierteSektionen: [(quelle: String, items: [WarenkorbState.Position])] {
        Dictionary(grouping: sichtbarePositionen, by: \.source)
            .sorted { $0.key < $1.key }
            .map { (quelle: $0.key, items: $0.value) }
    }

    private func quellLabel(_ source: String) -> String {
        switch source {
        case "katalog": "Artikel"
        case "lager": "Lager"
        case "angebot-eingehend": "Angebot eingehend"
        case "angebot-ausgehend": "Angebot ausgehend"
        default: source
        }
    }

    private func gruppenSumme(_ items: [WarenkorbState.Position]) -> (anzahl: Int, vk: Double) {
        let anzahl = items.reduce(0) { $0 + $1.menge }
        let vk = items.reduce(0.0) { $0 + ($1.vkNetto ?? 0) * Double($1.menge) }
        return (anzahl, vk)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Image(systemName: "cart")
                    .font(.mykHeadline)
                    .foregroundStyle(MykColor.tasks.color)
                Text("Warenkorb")
                    .font(.mykHeadline)
                    .foregroundStyle(MykColor.ink.color)
                Spacer()
                Text("\(warenkorb.anzahl) Pos.")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.muted.color)
                Button {
                    warenkorb.showPanel = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.muted.color)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, MykSpace.s7)
            .padding(.top, MykSpace.s7)
            .padding(.bottom, MykSpace.s4)

            Divider().overlay(MykColor.line.color)

            if warenkorb.istLeer {
                VStack(spacing: MykSpace.s4) {
                    Spacer()
                    Image(systemName: "cart")
                        .font(.mykDisplay)
                        .foregroundStyle(MykColor.faint.color)
                    Text("Der Warenkorb ist leer.")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.muted.color)
                    Text("Artikel oder Lager-Positionen\nhinzufügen.")
                        .font(.mykCaption)
                        .foregroundStyle(MykColor.faint.color)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                warenkorbToolbar

                Divider().overlay(MykColor.line.color)

                // Positionsliste (gefiltert/sortiert, optional gruppiert)
                ScrollView {
                    if sichtbarePositionen.isEmpty {
                        VStack(spacing: MykSpace.s3) {
                            Spacer(minLength: MykSpace.s9)
                            Text("Keine Treffer.")
                                .font(.mykSmall)
                                .foregroundStyle(MykColor.muted.color)
                            Spacer(minLength: MykSpace.s9)
                        }
                        .frame(maxWidth: .infinity)
                    } else if gruppieren {
                        VStack(spacing: 0) {
                            ForEach(gruppierteSektionen, id: \.quelle) { sektion in
                                gruppenHeader(sektion.quelle, items: sektion.items)
                                ForEach(sektion.items) { pos in
                                    PositionZeile(
                                        position: pos,
                                        preisFormatter: Self.preisFormatter,
                                        onMengeChange: { warenkorb.setMenge($0, forID: pos.id) },
                                        onRemove: { warenkorb.remove(id: pos.id) }
                                    )
                                    Divider().overlay(MykColor.line.color)
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 0) {
                            ForEach(sichtbarePositionen) { pos in
                                PositionZeile(
                                    position: pos,
                                    preisFormatter: Self.preisFormatter,
                                    onMengeChange: { warenkorb.setMenge($0, forID: pos.id) },
                                    onRemove: { warenkorb.remove(id: pos.id) }
                                )
                                Divider().overlay(MykColor.line.color)
                            }
                        }
                    }
                }

                Divider().overlay(MykColor.line.color)

                // Summenzeile
                VStack(alignment: .leading, spacing: MykSpace.s2) {
                    HStack {
                        Text("Summe EK netto")
                            .font(.mykSmall)
                            .foregroundStyle(MykColor.muted.color)
                        Spacer()
                        Text(Self.preisFormatter.string(from: NSNumber(value: warenkorb.gesamtEK)) ?? "–")
                            .font(.mykSmall)
                            .foregroundStyle(MykColor.inkSoft.color)
                    }
                    HStack {
                        Text("Summe VK netto (MYKILOS)")
                            .font(.mykSmall)
                            .foregroundStyle(MykColor.muted.color)
                        Spacer()
                        Text(Self.preisFormatter.string(from: NSNumber(value: warenkorb.gesamtVK)) ?? "–")
                            .font(.mykHeadline)
                            .foregroundStyle(MykColor.tasks.color)
                    }
                }
                .padding(.horizontal, MykSpace.s7)
                .padding(.vertical, MykSpace.s5)

                Divider().overlay(MykColor.line.color)

                // Actions
                HStack(spacing: MykSpace.s3) {
                    Button(role: .destructive) {
                        warenkorb.leeren()
                    } label: {
                        Label("Leeren", systemImage: "trash")
                            .font(.mykSmall)
                            .foregroundStyle(MykColor.critical.color)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        showPreview = true
                    } label: {
                        Label("Vorschau", systemImage: "eye")
                            .font(.mykSmall)
                            .foregroundStyle(MykColor.muted.color)
                    }
                    .buttonStyle(.plain)
                    .help("Zeigt das JSON-Format des Dev-Exports, bevor du checkoutest")

                    Button {
                        showDevCheckout = true
                    } label: {
                        Label("Checkout (Dev)", systemImage: "shippingbox")
                            .font(.mykSmall)
                            .foregroundStyle(MykColor.cash.color)
                            .padding(.horizontal, MykSpace.s5)
                            .padding(.vertical, MykSpace.s3)
                            .background(MykColor.card.color)
                            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                            .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.cash.color, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .help("Lokaler Dev-Export-Vorschau (kein Airtable-Schreiben)")

                    Button {
                        showVersand = true
                    } label: {
                        Label("An Airtable senden", systemImage: "arrow.up.doc")
                            .font(.mykSmall)
                            .foregroundStyle(MykColor.paper.color)
                            .padding(.horizontal, MykSpace.s5)
                            .padding(.vertical, MykSpace.s3)
                            .background(MykColor.tasks.color)
                            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, MykSpace.s7)
                .padding(.vertical, MykSpace.s5)
            }
        }
        .frame(width: 420)
        .background(MykColor.paper.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: MykRadius.md)
                .stroke(MykColor.line.color, lineWidth: 1)
        )
        .shadow(color: MykColor.ink.color.opacity(0.08), radius: 24, x: 0, y: 4)
        .sheet(isPresented: $showVersand) {
            WarenkorbVersandView(
                warenkorb: warenkorb,
                projekte: appState.registry.projects
            )
        }
        .sheet(isPresented: $showDevCheckout) {
            DevCheckoutSheet(
                quelle: "session",
                bezeichnung: nil,
                projekt: nil,
                positionen: warenkorb.positionen.map { $0.devExportPosition },
                summeEKNetto: warenkorb.istLeer ? nil : warenkorb.gesamtEK,
                summeVKNetto: warenkorb.istLeer ? nil : warenkorb.gesamtVK,
                onDismiss: { showDevCheckout = false }
            )
        }
        .sheet(isPresented: $showPreview) {
            WarenkorbPreviewSheet(
                positionen: sichtbarePositionen.map { $0.devExportPosition },
                onDismiss: { showPreview = false }
            )
        }
    }

    // MARK: - Task B: Toolbar (Suche/Sortieren/Filtern/Gruppieren)

    private var warenkorbToolbar: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "magnifyingglass")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.muted.color)
                TextField("Bezeichnung, Art.-Nr. …", text: $query)
                    .font(.mykSmall)
                    .textFieldStyle(.plain)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.mykCaption)
                            .foregroundStyle(MykColor.faint.color)
                    }
                    .buttonStyle(.plain)
                }

                Menu {
                    ForEach(WarenkorbSort.allCases) { option in
                        Button { sort = option } label: {
                            Label(option.rawValue, systemImage: sort == option ? "checkmark" : "arrow.up.arrow.down")
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.mykCaption)
                        .foregroundStyle(MykColor.muted.color)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Sortieren: \(sort.rawValue)")

                Toggle(isOn: $gruppieren) {
                    Image(systemName: "square.grid.2x2")
                        .font(.mykCaption)
                }
                .toggleStyle(.button)
                .buttonStyle(.plain)
                .foregroundStyle(gruppieren ? MykColor.tasks.color : MykColor.muted.color)
                .help("Nach Quelle gruppieren")
                .accessibilityLabel("Nach Quelle gruppieren")
            }
            .padding(.horizontal, MykSpace.s3)
            .padding(.vertical, MykSpace.s2)
            .background(MykColor.card.color)
            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))

            if vorhandeneQuellen.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MykSpace.s2) {
                        ForEach(vorhandeneQuellen, id: \.self) { quelle in
                            quellFilterChip(quelle)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, MykSpace.s7)
        .padding(.vertical, MykSpace.s4)
    }

    private func quellFilterChip(_ quelle: String) -> some View {
        let aktiv = aktiveQuellenFilter.contains(quelle)
        return Button {
            if aktiv { aktiveQuellenFilter.remove(quelle) } else { aktiveQuellenFilter.insert(quelle) }
        } label: {
            Text(quellLabel(quelle))
                .font(.mykMono(9))
                .foregroundStyle(aktiv ? MykColor.paper.color : MykColor.muted.color)
                .padding(.horizontal, MykSpace.s3)
                .padding(.vertical, MykSpace.s2)
                .background(aktiv ? MykColor.tasks.color : MykColor.card.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func gruppenHeader(_ quelle: String, items: [WarenkorbState.Position]) -> some View {
        let summe = gruppenSumme(items)
        return HStack {
            Text(quellLabel(quelle).uppercased())
                .font(.mykMono(9))
                .foregroundStyle(MykColor.muted.color)
            Spacer()
            Text("\(summe.anzahl) Stk · \(Self.preisFormatter.string(from: NSNumber(value: summe.vk)) ?? "–")")
                .font(.mykMono(9))
                .foregroundStyle(MykColor.faint.color)
        }
        .padding(.horizontal, MykSpace.s7)
        .padding(.vertical, MykSpace.s2)
        .background(MykColor.paper2.color)
    }
}

// MARK: - WarenkorbPreviewSheet
// Task B: zeigt das JSON-Format des Dev-Exports (Task D) VOR dem Checkout — reine
// Leseansicht, löst keine Ausgabeart aus. Nutzt DevBasketExport.prettyJSON() direkt,
// damit Vorschau und Checkout-Sheet garantiert dieselbe Form zeigen.
@MainActor
private struct WarenkorbPreviewSheet: View {
    let positionen: [DevBasketExportPosition]
    let onDismiss: () -> Void

    private var jsonText: String {
        let export = DevBasketExport(quelle: "session-vorschau", positionen: positionen)
        return (try? export.prettyJSON()) ?? "Vorschau konnte nicht erzeugt werden."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            HStack {
                Text("Warenkorb — Vorschau")
                    .font(.mykHeadline)
                    .foregroundStyle(MykColor.ink.color)
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark").font(.mykSmall).foregroundStyle(MykColor.muted.color)
                }
                .buttonStyle(.plain)
            }
            Text("So sieht das Dev-Export-JSON (Task D) für die aktuell gefilterte Liste aus — reine Leseansicht, keine Aktion wird ausgelöst.")
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
                .fixedSize(horizontal: false, vertical: true)
            ScrollView {
                Text(jsonText)
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.ink.color)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(MykSpace.s4)
            }
            .background(MykColor.card.color)
            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
            HStack {
                Spacer()
                Button("Schließen") { onDismiss() }
                    .buttonStyle(.plain)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            }
        }
        .padding(MykSpace.s8)
        .frame(width: 520, height: 480)
        .background(MykColor.paper.color)
    }
}

// MARK: - PositionZeile

@MainActor
private struct PositionZeile: View {
    let position: WarenkorbState.Position
    let preisFormatter: NumberFormatter
    let onMengeChange: (Int) -> Void
    let onRemove: () -> Void

    @State private var mengeText: String = ""

    private var sourceBadgeLabel: String {
        switch position.source {
        case "katalog": "K"
        case "lager": "L"
        case "angebot-eingehend": "AE"
        case "angebot-ausgehend": "AA"
        default: "?"
        }
    }

    private var sourceBadgeColor: Color {
        switch position.source {
        case "katalog": MykColor.tasks.color
        case "lager": MykColor.drive.color
        case "angebot-eingehend", "angebot-ausgehend": MykColor.cash.color
        default: MykColor.muted.color
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: MykSpace.s4) {
            // Source-Badge (Task A: generalisiert über alle vier Quell-Strings)
            Text(sourceBadgeLabel)
                .font(.mykMono(8))
                .foregroundStyle(MykColor.paper.color)
                .frame(width: 16, height: 16)
                .background(sourceBadgeColor)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: MykSpace.s2) {
                Text(position.bezeichnung)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.ink.color)
                    .lineLimit(2)
                Text(position.artikelnummer)
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.muted.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Preis
            VStack(alignment: .trailing, spacing: MykSpace.s2) {
                if let vk = position.vkNetto {
                    Text(preisFormatter.string(from: NSNumber(value: vk * Double(position.menge))) ?? "–")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.tasks.color)
                    Text("VK")
                        .font(.mykMono(8))
                        .foregroundStyle(MykColor.faint.color)
                }
            }

            // Mengen-Stepper
            HStack(spacing: MykSpace.s2) {
                Button {
                    onMengeChange(max(0, position.menge - 1))
                } label: {
                    Image(systemName: "minus")
                        .font(.mykMono(9))
                        .frame(width: 22, height: 22)
                        .background(MykColor.card.color)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)

                Text("\(position.menge)")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.ink.color)
                    .frame(width: 28, alignment: .center)

                Button {
                    onMengeChange(position.menge + 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.mykMono(9))
                        .frame(width: 22, height: 22)
                        .background(MykColor.card.color)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }

            // Löschen
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.faint.color)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, MykSpace.s7)
        .padding(.vertical, MykSpace.s4)
    }
}

// MARK: - WarenkorbVersandView
// Eingabemaske vor dem Airtable-Versand.
// Projekt wählen (oder leer lassen) + eigene Bezeichnung → Bestätigung → CartStore.
// Append-only: kein Delete/Overwrite. Sichtbarer Erfolg/Fehler.
@MainActor
struct WarenkorbVersandView: View {
    @Bindable var warenkorb: WarenkorbState
    let projekte: [Project]

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProjektID: String? = nil       // nil = kein Projekt
    @State private var bezeichnung: String = ""
    @State private var sendState: SendState = .idle
    @State private var showConfirm = false

    enum SendState: Equatable {
        case idle
        case sending
        case success(String, Int)   // recordID, version
        case error(String)
    }

    private var selectedProjekt: Project? {
        guard let id = selectedProjektID else { return nil }
        return projekte.first { $0.projectNumber == id }
    }

    private var effectiveBezeichnung: String {
        let b = bezeichnung.trimmingCharacters(in: .whitespaces)
        if !b.isEmpty { return b }
        if let p = selectedProjekt { return p.title }
        return ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "arrow.up.doc")
                    .font(.mykHeadline)
                    .foregroundStyle(MykColor.tasks.color)
                Text("Warenkorb senden")
                    .font(.mykHeadline)
                    .foregroundStyle(MykColor.ink.color)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.muted.color)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, MykSpace.s8)
            .padding(.top, MykSpace.s8)
            .padding(.bottom, MykSpace.s4)

            Divider().overlay(MykColor.line.color)

            ScrollView {
                VStack(alignment: .leading, spacing: MykSpace.s6) {

                    // Zusammenfassung
                    summarySection

                    Divider().overlay(MykColor.line.color)

                    // Projekt wählen
                    projektSection

                    // Bezeichnung
                    VStack(alignment: .leading, spacing: MykSpace.s2) {
                        Text("Bezeichnung (optional)")
                            .font(.mykSmall)
                            .foregroundStyle(MykColor.muted.color)
                        TextField(
                            selectedProjekt.map { "Warenkorb \($0.title)" } ?? "Bezeichnung …",
                            text: $bezeichnung
                        )
                        .font(.mykBody)
                        .textFieldStyle(.roundedBorder)
                    }

                    // Ergebnisanzeige
                    switch sendState {
                    case .idle: EmptyView()
                    case .sending:
                        HStack(spacing: MykSpace.s3) {
                            ProgressView()
                            Text("Wird gesendet …")
                                .font(.mykSmall)
                                .foregroundStyle(MykColor.muted.color)
                        }
                    case .success(let id, let v):
                        HStack(spacing: MykSpace.s3) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(MykColor.positive.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Erfolgreich gesendet · Version \(v)")
                                    .font(.mykSmall)
                                    .foregroundStyle(MykColor.positive.color)
                                Text("Record: \(id)")
                                    .font(.mykMono(9))
                                    .foregroundStyle(MykColor.muted.color)
                                    .lineLimit(1)
                            }
                        }
                        .padding(MykSpace.s4)
                        .background(MykColor.positive.color.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                    case .error(let msg):
                        HStack(spacing: MykSpace.s3) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(MykColor.critical.color)
                            Text(msg)
                                .font(.mykSmall)
                                .foregroundStyle(MykColor.critical.color)
                        }
                        .padding(MykSpace.s4)
                        .background(MykColor.critical.color.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                    }
                }
                .padding(.horizontal, MykSpace.s8)
                .padding(.vertical, MykSpace.s6)
            }

            Divider().overlay(MykColor.line.color)

            // Footer
            HStack {
                Button("Abbrechen") { dismiss() }
                    .buttonStyle(.plain)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)

                Spacer()

                if case .success = sendState {
                    Button("Schließen") {
                        warenkorb.leeren()
                        dismiss()
                    }
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.paper.color)
                    .padding(.horizontal, MykSpace.s5)
                    .padding(.vertical, MykSpace.s3)
                    .background(MykColor.positive.color)
                    .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                    .buttonStyle(.plain)
                } else {
                    Button {
                        showConfirm = true
                    } label: {
                        Label("Jetzt senden", systemImage: "arrow.up.doc")
                            .font(.mykSmall)
                            .foregroundStyle(sendState == .sending ? MykColor.muted.color : MykColor.paper.color)
                            .padding(.horizontal, MykSpace.s5)
                            .padding(.vertical, MykSpace.s3)
                            .background(sendState == .sending ? MykColor.faint.color : MykColor.tasks.color)
                            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                    }
                    .buttonStyle(.plain)
                    .disabled(sendState == .sending)
                }
            }
            .padding(.horizontal, MykSpace.s8)
            .padding(.vertical, MykSpace.s6)
        }
        .frame(width: 520)
        .background(MykColor.paper.color)
        .alert("Warenkorb senden?", isPresented: $showConfirm) {
            Button("Senden", role: .none) { Task { await send() } }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            let bez = effectiveBezeichnung.isEmpty ? "ohne Bezeichnung" : "\"\(effectiveBezeichnung)\""
            Text("\(warenkorb.positionen.count) Positionen \(bez) werden append-only in Airtable gespeichert. Alte Versionen werden als Archiviert markiert.")
        }
    }

    // MARK: - Subviews

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            Text("Inhalt")
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
            HStack {
                Text("\(warenkorb.positionen.count) Positionen · \(warenkorb.anzahl) Stück")
                    .font(.mykBody)
                    .foregroundStyle(MykColor.ink.color)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("EK \(formatPreis(warenkorb.gesamtEK))")
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.inkSoft.color)
                    Text("VK \(formatPreis(warenkorb.gesamtVK))")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.tasks.color)
                }
            }
        }
    }

    private var projektSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text("Projekt (optional)")
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)
            Picker("Projekt", selection: $selectedProjektID) {
                Text("Kein Projekt").tag(String?.none)
                ForEach(projekte) { p in
                    Text("\(p.projectNumber) · \(p.title)")
                        .tag(String?.some(p.projectNumber))
                }
            }
            .pickerStyle(.menu)
            .font(.mykBody)
        }
    }

    // MARK: - Send

    private func send() async {
        sendState = .sending
        // Bezeichnung: eigener Freitext hat Priorität, dann Projektname
        let finalBezeichnung = effectiveBezeichnung
        let initialProjektName: String? = selectedProjekt.map { $0.title }
        // Härtung (2026-07-01, Audit): `selectedProjekt.airtableRecordID` ist eine Record-ID
        // aus der Mastermind-Base (appuVMh3KDfKw4OoQ, `registry.syncFromAirtable`). CartStore
        // schreibt `projektRecordID` aber als Link-Feld in die ANDERE Base, die Artikel-DB
        // (appdxTeT6bhSBmwx5) — ein Record-Link kann nie über Basen hinweg zeigen. Ohne einen
        // echten Cross-Base-Lookup (der hier bewusst nicht geraten wird) bleibt nur der
        // Projektname als Freitext-Zuordnung; ein blind falscher Link wäre schlimmer als keiner.
        let wk = warenkorb.makeWarenkorb(
            projektRecordID: nil,
            projektName: initialProjektName
        )
        let wkFinal: Warenkorb
        if !finalBezeichnung.isEmpty {
            wkFinal = Warenkorb(
                items: wk.items,
                projektRecordID: wk.projektRecordID,
                projektName: finalBezeichnung
            )
        } else {
            wkFinal = wk
        }
        do {
            let cartStore = makeCartStore()
            let outcome = try await cartStore.sendWarenkorbToAirtable(
                wkFinal,
                akteurProjektID: selectedProjekt?.projectNumber ?? ""
            )
            switch outcome {
            case .success(let id, let version):
                sendState = .success(id, version)
                // Härtung (2026-07-01, Audit): bisher kein dataFlow.log für diesen Write-Pfad.
                appState.dataFlow.log(integrationID: "AIRTABLE_WARENKORB_SENDEN", actorUserID: appState.actorUserID,
                                       action: .success, recordsWritten: 1,
                                       summary: "Warenkorb gesendet (Version \(version), Record \(id))")
            case .leer:
                sendState = .error("Warenkorb ist leer — nichts gesendet.")
            }
        } catch {
            sendState = .error(error.localizedDescription)
            appState.dataFlow.log(integrationID: "AIRTABLE_WARENKORB_SENDEN", actorUserID: appState.actorUserID,
                                   action: .error, errorMessage: error.localizedDescription,
                                   summary: "Warenkorb-Senden fehlgeschlagen")
        }
    }

    private func makeCartStore() -> CartStore {
        CartStore(
            fetcher: AirtableClient(),
            creator: AirtableClient(),
            updater: AirtableClient(),
            auditStore: appState.audit,
            actorUserID: appState.profile.profile?.displayName ?? "system"
        )
    }

    private func formatPreis(_ val: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: val)) ?? "–"
    }
}
