import SwiftUI
import MykilosDesign
import MykilosServices

// MARK: - KatalogeView
// Zeigt den lokalen Gerätekatalog (DeviceCatalog) read-only.
// Quelle: CSV aus MYKILOS-Ordner — Export aus Airtable appdxTeT6bhSBmwx5 (read-only).
// Schreibt NIE zurück. Lädt per .task einmalig vom Standardort.
@MainActor
struct KatalogeView: View {
    @State private var catalog: DeviceCatalog? = nil
    @State private var query: String = ""
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            searchBar

            if isLoading {
                Spacer()
                ProgressView("Lade Katalog …")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else if catalog == nil {
                emptyState
            } else {
                resultsTable
            }
        }
        .background(MykColor.paper.color)
        .task { await loadCatalog() }
    }

    // MARK: - Sub-Views

    private var header: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text("Gerätekatalog")
                .font(.mykDisplay)
                .foregroundStyle(MykColor.ink.color)
            Group {
                if let c = catalog {
                    Text("\(c.entries.count) Artikel \u{00B7} read-only \u{00B7} Airtable appdxTeT6bhSBmwx5")
                } else {
                    Text("Kein Katalog geladen")
                }
            }
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
        }
        .padding(MykSpace.s9)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchBar: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: "magnifyingglass")
                .font(.mykCaption)
                .foregroundStyle(MykColor.muted.color)
            TextField("Hersteller, Kategorie, Artikelnummer …", text: $query)
                .font(.mykBody)
                .textFieldStyle(.plain)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.mykCaption)
                        .foregroundStyle(MykColor.faint.color)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MykSpace.s4)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: MykRadius.sm)
                .stroke(MykColor.line.color, lineWidth: 1)
        )
        .padding(.horizontal, MykSpace.s9)
        .padding(.bottom, MykSpace.s4)
    }

    private var resultsTable: some View {
        let results = filteredResults
        return VStack(spacing: 0) {
            tableHeader
            if results.isEmpty {
                Text("Keine Treffer für \"\(query)\"")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
                    .padding(MykSpace.s9)
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.offset) { _, entry in
                            KatalogeRow(entry: entry)
                            Divider().overlay(MykColor.line.color)
                        }
                    }
                }
                Text("\(results.count) \(results.count == 1 ? "Artikel" : "Artikel") angezeigt")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.faint.color)
                    .padding(.vertical, MykSpace.s3)
                    .padding(.horizontal, MykSpace.s9)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("Hersteller").frame(width: 120, alignment: .leading)
            Text("Kategorie").frame(width: 130, alignment: .leading)
            Text("Beschreibung").frame(maxWidth: .infinity, alignment: .leading)
            Text("Art.-Nr.").frame(width: 110, alignment: .leading)
            Text("MYKILOS-VK").frame(width: 90, alignment: .trailing)
        }
        .font(.mykMono(9))
        .foregroundStyle(MykColor.muted.color)
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s2)
        .background(MykColor.paper2.color)
    }

    private var emptyState: some View {
        VStack(spacing: MykSpace.s4) {
            Image(systemName: "tray.slash")
                .font(.mykDisplay)
                .foregroundStyle(MykColor.faint.color)
            Text("Kein Gerätekatalog gefunden")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.muted.color)
            Text("CSV unter:\n\(DeviceCatalog.defaultURL().path)")
                .font(.mykMono(9))
                .foregroundStyle(MykColor.faint.color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(MykSpace.s9)
    }

    // MARK: - Logic

    private var filteredResults: [DeviceCatalogEntry] {
        guard let catalog else { return [] }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty {
            return Array(catalog.entries.prefix(200))
        }
        return catalog.search(q, limit: 200)
    }

    private func loadCatalog() async {
        let loaded = await Task.detached(priority: .userInitiated) {
            DeviceCatalog.loadDefault()
        }.value
        catalog = loaded
        isLoading = false
    }
}

// MARK: - KatalogeRow

private struct KatalogeRow: View {
    let entry: DeviceCatalogEntry
    @State private var isHovered = false

    private static let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        f.maximumFractionDigits = 2
        return f
    }()

    var body: some View {
        HStack(spacing: 0) {
            Text(entry.manufacturer)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)
            Text(entry.category)
                .foregroundStyle(MykColor.muted.color)
                .frame(width: 130, alignment: .leading)
                .lineLimit(1)
            Text(entry.description)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
            Text(entry.articleNumber)
                .foregroundStyle(MykColor.muted.color)
                .frame(width: 110, alignment: .leading)
                .lineLimit(1)
            if let price = entry.sellNet {
                Text(Self.priceFormatter.string(from: price as NSDecimalNumber) ?? "–")
                    .foregroundStyle(MykColor.tasks.color)
                    .frame(width: 90, alignment: .trailing)
            } else {
                Text("–")
                    .foregroundStyle(MykColor.faint.color)
                    .frame(width: 90, alignment: .trailing)
            }
        }
        .font(.mykMono(10))
        .foregroundStyle(MykColor.ink.color)
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s3)
        .background(isHovered ? MykColor.paper2.color : Color.clear)
        .onHover { isHovered = $0 }
    }
}
