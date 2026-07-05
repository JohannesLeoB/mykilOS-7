import SwiftUI

/// Der Satellit-Copilot als Gespraech: du fragst, der Satellit bedient die
/// App-Werkzeuge und antwortet. Das eine Instrument statt 20 Knoepfe.
struct CopilotView: View {
    let store: ProjectStore
    let feldFotoStore: FeldFotoStore

    @State private var copilot: SatellitCopilot?
    @State private var eingabe = ""

    private let beispiele = [
        "Fass mir das neueste Projekt zusammen",
        "Bau einen Firefly-Prompt fuer eine Kueche im Landhausstil",
        "Welche Projekte haben wir gerade?",
    ]

    var body: some View {
        VStack(spacing: 0) {
            if let copilot {
                if copilot.istVerbunden {
                    gespraech(copilot)
                    eingabeleiste(copilot)
                } else {
                    keinZugang
                }
            } else {
                ProgressView().frame(maxHeight: .infinity)
            }
        }
        .background(MykColor.paper)
        .navigationTitle("Satellit-Copilot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let copilot, !copilot.verlauf.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { copilot.verlaufLeeren() } label: { Image(systemName: "trash") }
                        .accessibilityLabel("Verlauf leeren")
                }
            }
        }
        .onAppear {
            if copilot == nil {
                copilot = SatellitCopilot(projectStore: store, feldFotoStore: feldFotoStore)
            }
        }
    }

    private func gespraech(_ copilot: SatellitCopilot) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if copilot.verlauf.isEmpty { willkommen }
                    ForEach(copilot.verlauf) { zeile in
                        blase(zeile).id(zeile.id)
                    }
                    if copilot.denktGerade {
                        HStack(spacing: 6) {
                            ProgressView()
                            Text("Satellit denkt...").font(.caption).foregroundStyle(MykColor.muted)
                        }
                    }
                    if let fehler = copilot.fehler {
                        Text(fehler).font(.caption).foregroundStyle(MykColor.crit)
                    }
                }
                .padding(14)
            }
            .onChange(of: copilot.verlauf.count) {
                if let letzte = copilot.verlauf.last { withAnimation { proxy.scrollTo(letzte.id, anchor: .bottom) } }
            }
        }
    }

    private var willkommen: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Frag mich - ich bediene die App fuer dich.")
                .font(.callout).foregroundStyle(MykColor.muted)
            ForEach(beispiele, id: \.self) { b in
                Button {
                    eingabe = b
                } label: {
                    Text(b).font(.caption.weight(.semibold)).foregroundStyle(MykColor.brand)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(MykColor.brand.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }

    @ViewBuilder
    private func blase(_ zeile: CopilotAnzeige) -> some View {
        switch zeile.art {
        case .du:
            HStack {
                Spacer(minLength: 40)
                Text(zeile.text)
                    .padding(10)
                    .background(MykColor.brand.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        case .satellit:
            HStack {
                Text(zeile.text)
                    .textSelection(.enabled)
                    .padding(10)
                    .background(MykColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(MykColor.line))
                Spacer(minLength: 40)
            }
        case .werkzeug:
            HStack(spacing: 6) {
                Image(systemName: "wrench.and.screwdriver.fill").font(.caption2)
                Text(zeile.text).font(.caption2)
            }
            .foregroundStyle(MykColor.muted)
            .padding(.leading, 4)
        }
    }

    private func eingabeleiste(_ copilot: SatellitCopilot) -> some View {
        HStack(spacing: 8) {
            TextField("Frag den Satelliten...", text: $eingabe, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
            Button {
                let text = eingabe
                eingabe = ""
                Task { await copilot.sende(text) }
            } label: {
                Image(systemName: "arrow.up.circle.fill").font(.title2)
            }
            .disabled(eingabe.trimmingCharacters(in: .whitespaces).isEmpty || copilot.denktGerade)
            .tint(MykColor.brand)
        }
        .padding(10)
        .background(MykColor.card)
    }

    private var keinZugang: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(MykColor.brand)
            Text("Der Copilot braucht den Assistent-Zugang")
                .font(.headline)
            Text("Hinterlege deinen Anthropic-API-Key unter Verbindungen -> Claude Assistent. Danach bediene ich die App fuer dich.")
                .font(.callout).foregroundStyle(MykColor.muted)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        CopilotView(store: ProjectStore(), feldFotoStore: FeldFotoStore())
    }
}
