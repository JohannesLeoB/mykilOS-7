import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - ClickUpProjektMetaStrip (CLICKUP_DATENINTEGRATION Schritt 2, 2026-07-07)
// Read-only Anzeige der Projekt-Custom-Fields aus der verknüpften ClickUp-Liste
// (ClickUpClient.projektMeta → ClickUpProjektMeta über den Schaltschrank-Mapper).
// Kompakte Chip-Zeile unter dem Lebenszyklus-Band, erscheint NUR, wenn eine Liste
// verknüpft ist UND ClickUp mindestens ein Feld liefert. Rein lesend — kein Schreiben,
// keine Ableitung in lokale Felder (das wäre ein späterer, bewusst getrennter Schritt).
struct ClickUpProjektMetaStrip: View {
    let clickUpListID: String?
    var client: ClickUpFetching = ClickUpClient()

    @State private var meta: ClickUpProjektMeta = .empty

    var body: some View {
        let chips = Self.chips(from: meta)
        Group {
            if chips.isEmpty == false {
                VStack(alignment: .leading, spacing: MykSpace.s2) {
                    Text("CLICKUP-PROJEKTDATEN")
                        .font(.mykMono(9)).tracking(0.5).foregroundStyle(MykColor.faint.color)
                    FlowChips(chips: chips)
                }
                .padding(.horizontal, MykSpace.s8)
                .padding(.bottom, MykSpace.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MykColor.paper.color)
            }
        }
        .task(id: clickUpListID) { await load() }
    }

    private func load() async {
        guard let listID = clickUpListID, listID.isEmpty == false else {
            meta = .empty
            return
        }
        // Fehler bewusst geschluckt (Hintergrund-Lesefetch): kein Störbanner im Projekt-
        // Detail — fehlt/scheitert der Abruf, bleibt der Streifen einfach leer.
        if let geladen = try? await client.projektMeta(listID: listID) {
            meta = geladen
        }
    }

    // MARK: - Reine, testbare Chip-Ableitung

    private static let datumsFormat: DateFormatter = {
        let fmt = DateFormatter(); fmt.dateFormat = "dd.MM.yyyy"; fmt.locale = Locale(identifier: "de_DE"); return fmt
    }()

    private static let budgetFormat: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.locale = Locale(identifier: "de_DE")
        fmt.maximumFractionDigits = 0
        return fmt
    }()

    /// Ein anzeigbares Meta-Feld (Label + Wert). `id` = Label (je Streifen eindeutig).
    struct MetaChip: Identifiable, Equatable {
        let label: String
        let value: String
        var id: String { label }
    }

    /// Nur die GESETZTEN Felder als Chips, in stabiler Reihenfolge. Leere Slots erscheinen
    /// nicht (nichts wird erfunden). Reine Funktion → unit-testbar.
    static func chips(from meta: ClickUpProjektMeta) -> [MetaChip] {
        var out: [MetaChip] = []
        if let budget = meta.budget {
            out.append(MetaChip(label: "Budget", value: budgetFormat.string(from: NSNumber(value: budget)) ?? "\(Int(budget)) €"))
        }
        if let datum = meta.angebotsdatum { out.append(MetaChip(label: "Angebot", value: datumsFormat.string(from: datum))) }
        if let datum = meta.auftragsdatum { out.append(MetaChip(label: "Auftrag", value: datumsFormat.string(from: datum))) }
        if let datum = meta.naechstesNachfassen { out.append(MetaChip(label: "Nachfassen", value: datumsFormat.string(from: datum))) }
        if let ort = meta.ort { out.append(MetaChip(label: "Ort", value: ort)) }
        if let lead = meta.lead { out.append(MetaChip(label: "Lead", value: lead)) }
        if let typ = meta.projekttyp { out.append(MetaChip(label: "Typ", value: typ)) }
        if let risiko = meta.risikoEngpass { out.append(MetaChip(label: "Risiko", value: risiko)) }
        if let lieferanten = meta.lieferanten, lieferanten.isEmpty == false {
            out.append(MetaChip(label: "Lieferanten", value: lieferanten.joined(separator: ", ")))
        }
        return out
    }
}

// MARK: - FlowChips — einfache umbrechende Chip-Reihe (read-only)
private struct FlowChips: View {
    let chips: [ClickUpProjektMetaStrip.MetaChip]

    var body: some View {
        // Bewusst schlicht: eine LazyVGrid mit adaptiven Spalten bricht sauber um, read-only.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: MykSpace.s2, alignment: .leading)],
                  alignment: .leading, spacing: MykSpace.s2) {
            ForEach(chips) { chip in
                HStack(spacing: 4) {
                    Text(chip.label.uppercased())
                        .font(.mykMono(8)).foregroundStyle(MykColor.faint.color)
                    Text(chip.value)
                        .font(.mykMono(10)).foregroundStyle(MykColor.inkSoft.color)
                        .lineLimit(1)
                }
                .padding(.horizontal, MykSpace.s3)
                .padding(.vertical, MykSpace.s2)
                .background(Capsule().fill(MykColor.card.color))
                .overlay(Capsule().stroke(MykColor.line.color, lineWidth: 1))
            }
        }
    }
}
