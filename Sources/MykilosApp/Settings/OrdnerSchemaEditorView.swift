import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - OrdnerSchemaEditorView (Ordner-Schema-Editor-Plan, Stufe 2)
// Admin bearbeitet das Projekt-Ordnerschema (Baum + Wurzel-Namensschema), Live-Vorschau der
// Pfade, Speichern über NomenklaturStore.setzeSchema. Betrifft NUR das Muster für KÜNFTIGE
// Projekte — kein Drive-Write, keine bestehenden Ordner werden angefasst.
//
// Nicht Teil dieser Stufe: Drag&Drop-Umhängen bestehender Knoten in einen ANDEREN Elternknoten
// ("verschachteln" im Sinn von Umsortieren) — Verschachtelung entsteht hier über "Unterordner
// hinzufügen" innerhalb eines Knotens. Ein echtes Reparenting per Drag wäre eine eigene, größere
// Stufe (Kollisions-/Zyklen-Prüfung), bewusst zurückgestellt.
struct OrdnerSchemaEditorView: View {
    let store: NomenklaturStore
    // Admin-Ebene S4: für das Store-Gate durchgereicht (nie aus der View selbst behauptet) —
    // AdminZoneSection zeigt diese View ohnehin nur Admins, aber der Store prüft trotzdem
    // selbst (UI-Verstecken ist nie die einzige Grenze, ADMIN_EBENE_BAUPLAN.md Härtung 3).
    let identity: ResidentIdentity?
    let tokenPresent: Bool

    @State private var entwurf: FolderSchema
    @State private var zeigeZuruecksetzenBestaetigung = false

    init(store: NomenklaturStore, identity: ResidentIdentity?, tokenPresent: Bool) {
        self.store = store
        self.identity = identity
        self.tokenPresent = tokenPresent
        _entwurf = State(initialValue: store.aktivesSchema())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            header
            rootTemplateField
            Divider().overlay(MykColor.line.color)
            baumEditor
            Divider().overlay(MykColor.line.color)
            livePreview
            actions
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Projekt-Ordnerschema").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
            Text("Muster für neue Projektordner. Ändert NICHTS an bestehenden Drive-Ordnern — "
                 + "nur an dem Schema, nach dem KÜNFTIGE Projekte angelegt werden.")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var rootTemplateField: some View {
        HStack(spacing: MykSpace.s2) {
            Text("Wurzelname").font(.mykMono(9.5)).foregroundStyle(MykColor.faint.color)
            TextField("<JJJJ_NNN_Kunde>", text: $entwurf.rootTemplate)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(10))
                .frame(maxWidth: 320)
        }
    }

    private var baumEditor: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            HStack {
                Text("ORDNERBAUM").font(.mykMono(10)).tracking(1.5).foregroundStyle(MykColor.muted.color)
                Spacer()
                Button {
                    entwurf.children.append(FolderNode("Neuer Ordner"))
                } label: {
                    Label("Ordner", systemImage: "plus")
                }
                .buttonStyle(.plain).font(.mykMono(9.5)).foregroundStyle(MykColor.drive.color)
            }
            ForEach($entwurf.children) { $node in
                FolderNodeEditorRow(node: $node, tiefe: 0) {
                    entwurf.children.removeAll { $0.id == node.id }
                }
            }
        }
    }

    private var livePreview: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text("VORSCHAU · \(entwurf.allePfade().count) ORDNERPFADE")
                .font(.mykMono(10)).tracking(1.2).foregroundStyle(MykColor.muted.color)
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(entwurf.allePfade(), id: \.self) { pfad in
                        Text(pfad).font(.mykMono(9)).foregroundStyle(MykColor.ink.color)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 160)
        }
    }

    private var actions: some View {
        HStack(spacing: MykSpace.s3) {
            Button("Speichern") { speichern() }
                .buttonStyle(.plain)
                .font(.mykSmall).foregroundStyle(MykColor.paper.color)
                .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s2)
                .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.drive.color))

            Button("Auf Standard zurücksetzen") { zeigeZuruecksetzenBestaetigung = true }
                .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.critical.color)

            saveStateLabel
        }
        .confirmationDialog(
            "Eigenes Schema verwerfen?",
            isPresented: $zeigeZuruecksetzenBestaetigung
        ) {
            Button("Zurücksetzen", role: .destructive) { zuruecksetzen() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Das Standard-Schema gilt danach wieder für neue Projekte. Bestehende Drive-Ordner sind davon nicht betroffen.")
        }
    }

    @ViewBuilder private var saveStateLabel: some View {
        switch store.saveState {
        case .saving:
            ProgressView().controlSize(.small)
        case .saved:
            Label("Gespeichert", systemImage: "checkmark.circle.fill")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.positive.color)
        case .failed(let msg):
            Label(msg, systemImage: "exclamationmark.triangle")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.critical.color)
        case .idle:
            EmptyView()
        }
    }

    private func speichern() {
        var neu = entwurf
        neu.version = store.aktiveSchemaVersion + 1
        // Fehler landet sichtbar in store.saveState (saveStateLabel oben) — kein zweiter
        // Fehlerkanal in der View nötig.
        do {
            try store.setzeSchema(neu, ausgeloestVon: identity, tokenPresent: tokenPresent)
            entwurf = neu
        } catch {
            // store.saveState trägt den Fehler bereits sichtbar.
        }
    }

    private func zuruecksetzen() {
        do {
            try store.setzeSchemaAufStandard(ausgeloestVon: identity, tokenPresent: tokenPresent)
            entwurf = store.aktivesSchema()
        } catch {
            // store.saveState trägt den Fehler bereits sichtbar.
        }
    }
}

// MARK: - FolderNodeEditorRow (rekursiv — Umbenennen/Unterordner hinzufügen/Entfernen)
private struct FolderNodeEditorRow: View {
    @Binding var node: FolderNode
    let tiefe: Int
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "folder").font(.mykMono(9)).foregroundStyle(MykColor.drive.color)
                TextField("Ordnername", text: $node.name)
                    .textFieldStyle(.plain)
                    .font(.mykMono(10))
                Spacer()
                Button {
                    node.children.append(FolderNode("Neuer Unterordner"))
                } label: {
                    Image(systemName: "plus.circle").font(.mykMono(11)).foregroundStyle(MykColor.muted.color)
                }
                .buttonStyle(.plain).help("Unterordner hinzufügen")
                Button(action: onRemove) {
                    Image(systemName: "trash").font(.mykMono(11)).foregroundStyle(MykColor.critical.color)
                }
                .buttonStyle(.plain).help("Diesen Ordner entfernen")
            }
            .padding(.leading, CGFloat(tiefe) * 18)

            ForEach($node.children) { $child in
                FolderNodeEditorRow(node: $child, tiefe: tiefe + 1) {
                    node.children.removeAll { $0.id == child.id }
                }
            }
        }
    }
}
