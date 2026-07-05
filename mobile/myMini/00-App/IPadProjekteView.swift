import SwiftUI

/// iPad-Zweispalter: Projektliste links, der gefuehrte Auftrag rechts -
/// beides gleichzeitig sichtbar. Das ist der eigentliche Tablet-Gewinn:
/// tippen, ohne die Liste zu verlieren. Manuelles Zwei-Panel (HStack) statt
/// verschachteltem SplitView.
struct IPadProjekteView: View {
    let store: ProjectStore
    let feldFotoStore: FeldFotoStore

    @State private var suche = ""
    @State private var gewaehlt: Project?

    private var gefiltert: [Project] {
        store.matching(suche).sorted { $0.projectNumber > $1.projectNumber }
    }

    var body: some View {
        HStack(spacing: 0) {
            liste
                .frame(width: 340)
            Divider()
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Projekte")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var liste: some View {
        VStack(spacing: 0) {
            TextField("Suchen: Name oder Nummer...", text: $suche)
                .textFieldStyle(.roundedBorder)
                .padding(10)
            List(gefiltert, selection: Binding(get: { gewaehlt?.id }, set: { neu in
                gewaehlt = gefiltert.first { $0.id == neu }
            })) { project in
                HStack(spacing: 10) {
                    Circle()
                        .fill(project.kind == "studioInternal" ? MykColor.plum : MykColor.ocker)
                        .frame(width: 8, height: 8)
                    Text(project.title).font(.callout.weight(.semibold))
                    Spacer()
                    Text(project.projectNumber)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(MykColor.muted)
                }
                .tag(project.id)
            }
            .listStyle(.plain)
        }
        .background(MykColor.paper)
    }

    @ViewBuilder
    private var detail: some View {
        if let gewaehlt {
            NavigationStack {
                AuftragsReiseView(project: gewaehlt, store: store, feldFotoStore: feldFotoStore)
            }
            .id(gewaehlt.id)
        } else {
            VStack(spacing: 10) {
                Image(systemName: "hand.point.left.fill")
                    .font(.largeTitle).foregroundStyle(MykColor.muted)
                Text("Projekt links waehlen").foregroundStyle(MykColor.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MykColor.paper)
        }
    }
}

#Preview {
    NavigationStack {
        IPadProjekteView(store: ProjectStore(), feldFotoStore: FeldFotoStore())
    }
}
