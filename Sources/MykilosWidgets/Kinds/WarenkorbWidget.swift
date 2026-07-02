import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - WarenkorbWidget
// Zeigt den aktuellsten gespeicherten Warenkorb DIESES Projekts (aus der Airtable-
// Tabelle „Warenkörbe", read-only). Positionen + EK/VK-Summen. Tiefblau (cash).
// Zusammenstellen/Editieren passiert im Kataloge-Modul → Warenkörbe; hier nur Anzeige.
// Match: Airtable-Feld „Projekt" (Name/Lookup) gegen Projektnummer ODER Projektname.
public struct WarenkorbWidget: View {
    public let projectID: String        // Projektnummer (JJJJ-NNN)
    public let projektName: String?     // Menschlicher Projektname

    public init(projectID: String, projektName: String? = nil) {
        self.projectID = projectID
        self.projektName = projektName
    }

    @State private var store = WarenkorbListeStore()

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
                if items.isEmpty {
                    leerHinweis
                } else {
                    positionsListe
                    summenLeiste
                }
            }
        }
        .task(id: projectID) { await store.load() }
    }

    // MARK: - Auswahl des Projekt-Warenkorbs

    /// Aktuellster Warenkorb (Store sortiert neueste zuerst), dessen „Projekt"-Feld passt.
    private var eintrag: WarenkorbEintrag? {
        store.eintraege.first { passtZuProjekt($0) }
    }

    private func passtZuProjekt(_ e: WarenkorbEintrag) -> Bool {
        guard let projekt = e.projekt?.lowercased(), !projekt.isEmpty else { return false }
        if projekt.contains(projectID.lowercased()) { return true }
        if let name = projektName?.lowercased(), !name.isEmpty,
           projekt.contains(name) || name.contains(projekt) { return true }
        return false
    }

    private var items: [WarenkorbItem] { eintrag?.decodedItems() ?? [] }

    private var renderState: WidgetRenderState {
        switch store.state {
        case .idle, .loading:  return .loading
        case .notConnected:    return .permissionRequired
        case .error(let msg):  return .error(msg)
        // „empty"/„content" auf Store-Ebene: wir rendern den projektspezifischen
        // Leer-Hinweis selbst im Content, damit die Botschaft klar ist.
        case .empty, .content: return .content
        }
    }

    // MARK: - Bausteine

    private var sourceLabel: String {
        if let e = eintrag {
            let n = e.anzahlPositionen ?? items.count
            return "WARENKÖRBE  ·  \(n) POSITIONEN"
        }
        return "WARENKÖRBE"
    }

    private var header: some View {
        HStack {
            SourceChip(kind: .warenkorb)
            Text("Warenkorb").mykWidgetTitle()
            Spacer()
            if let e = eintrag {
                Text(versionsLabel(e))
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.muted.color)
            }
        }
    }

    private func versionsLabel(_ e: WarenkorbEintrag) -> String {
        var parts: [String] = ["v\(e.version)"]
        if let d = e.erstelltAm {
            parts.append(d.formatted(.dateTime.day().month(.abbreviated)))
        }
        if !e.istAktuell { parts.append("ARCHIV") }
        return parts.joined(separator: "  ·  ")
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
            Text("Im Kataloge-Modul zusammenstellen und dem Projekt zuweisen.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, MykSpace.s3)
    }

    // Positionsliste (max. 6 sichtbar, Rest als „+N weitere").
    private var positionsListe: some View {
        let sichtbar = Array(items.prefix(6))
        let rest = items.count - sichtbar.count
        return VStack(spacing: 0) {
            ForEach(sichtbar) { item in
                WarenkorbWidgetZeile(item: item, preisFormatter: Self.preisFormatter)
                if item.id != sichtbar.last?.id {
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

    private var summenLeiste: some View {
        HStack(spacing: MykSpace.s6) {
            summenFeld("EK", wert: eintrag?.gesamtEK ?? gesamtEK, farbe: MykColor.muted)
            summenFeld("VK", wert: eintrag?.gesamtVK ?? gesamtVK, farbe: MykColor.cash)
            Spacer()
            Text("\(items.reduce(0) { $0 + $1.menge }) Stück")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)
        }
        .padding(.top, MykSpace.s3)
        .overlay(alignment: .top) { Divider().overlay(MykColor.line.color) }
        .padding(.top, MykSpace.s2)
    }

    private var gesamtEK: Double { items.reduce(0) { $0 + ($1.ekNetto ?? 0) * Double($1.menge) } }
    private var gesamtVK: Double { items.reduce(0) { $0 + ($1.vkNetto ?? 0) * Double($1.menge) } }

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
    let item: WarenkorbItem
    let preisFormatter: NumberFormatter

    var body: some View {
        HStack(alignment: .top, spacing: MykSpace.s4) {
            Text("\(item.menge)×")
                .font(.mykMono(10))
                .foregroundStyle(MykColor.cash.color)
                .frame(width: 28, alignment: .trailing)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.bezeichnung)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.ink.color)
                    .lineLimit(1)
                Text(item.artikelnummer)
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.muted.color)
                    .lineLimit(1)
            }
            Spacer(minLength: MykSpace.s3)
            if let vk = item.vkNetto {
                Text(preisFormatter.string(from: NSNumber(value: vk * Double(item.menge))) ?? "–")
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.inkSoft.color)
            }
        }
        .padding(.vertical, MykSpace.s3)
    }
}
