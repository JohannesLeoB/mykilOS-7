import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets
import MykilosKalkulationsCore

// MARK: - PriceKnowledgeReviewView (Lern-Loop · das menschliche Freigabe-Gate)
//
// Zeigt die vorgemerkten PDF-Positions-KANDIDATEN (dateiübergreifend) und lässt
// den Menschen jeden einzeln als aktiven Preis-Anker FREIGEBEN. Erst die Freigabe
// (`confirmPDFPosition` → ReviewAction) macht eine Position schätz-wirksam — genau
// hier lebt das Gate. Read-until-release; nichts wird automatisch aktiviert.
struct PriceKnowledgeReviewView: View {
    let store: LearningStore
    var onClose: () -> Void
    /// false, wenn diese View fest eingebettet ist (z. B. als Kataloge-Tab) statt als
    /// dismissbares Sheet -- dann ergibt ein "Schließen"-Kreuz keinen Sinn.
    var zeigtSchliessenButton: Bool = true

    @State private var pending: [PDFExtractedPosition] = []
    @State private var freigegeben: Set<String> = []
    @State private var fehler: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(MykColor.line.color)
            content
            Divider().overlay(MykColor.line.color)
            footer
        }
        .frame(minWidth: 560, minHeight: 560)
        .background(MykColor.paper.color)
        .task { reload() }
    }

    private var header: some View {
        HStack(spacing: MykSpace.s4) {
            Image(systemName: "brain.head.profile")
                .font(.mykHeadline).foregroundStyle(MykColor.personal.color)
            VStack(alignment: .leading, spacing: 2) {
                Text("Preis-Wissen freigeben").mykWidgetTitle()
                Text("Bestätigte Positionen fließen als Anker in künftige Schätzungen.")
                    .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
            Spacer()
            if zeigtSchliessenButton {
                Button { onClose() } label: {
                    Image(systemName: "xmark.circle.fill").font(.mykHeadline).foregroundStyle(MykColor.faint.color)
                }
                .buttonStyle(.plain).accessibilityLabel("Schließen")
            }
        }
        .padding(MykSpace.s6)
    }

    @ViewBuilder
    private var content: some View {
        if let fehler {
            hint(icon: "exclamationmark.triangle", text: "Fehler: \(fehler)", critical: true)
        } else if pending.isEmpty {
            hint(icon: "checkmark.seal",
                 text: "Nichts offen. Positionen mit 'Als Preis-Wissen vormerken' landen hier zur Freigabe.")
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(pending) { p in
                        row(p)
                        if p.id != pending.last?.id { Divider().overlay(MykColor.line.color.opacity(0.5)) }
                    }
                }
                .padding(.horizontal, MykSpace.s6)
            }
        }
    }

    private func row(_ p: PDFExtractedPosition) -> some View {
        HStack(spacing: MykSpace.s4) {
            VStack(alignment: .leading, spacing: 3) {
                Text(p.title).font(.mykBody).foregroundStyle(MykColor.ink.color).lineLimit(1)
                HStack(spacing: MykSpace.s3) {
                    if p.componentType != .other {
                        Text(p.componentType.displayName)
                            .font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
                            .padding(.horizontal, MykSpace.s2).padding(.vertical, 1)
                            .background(Capsule().fill(MykColor.line.color.opacity(0.3)))
                    }
                    Text(euro(p.netPrice)).font(.mykMono(10)).foregroundStyle(MykColor.inkSoft.color)
                    Text("· \(p.sourceFile) S.\(p.pageNumber)")
                        .font(.mykMono(9)).foregroundStyle(MykColor.faint.color).lineLimit(1)
                }
            }
            Spacer()
            if freigegeben.contains(p.id) {
                Label("Freigegeben", systemImage: "checkmark.circle.fill")
                    .font(.mykMono(9.5)).foregroundStyle(MykColor.positive.color)
            } else {
                Button {
                    do { try store.confirmPDFPosition(recordID: p.id, note: "Review-Freigabe")
                         freigegeben.insert(p.id); reload() }
                    catch { fehler = String(describing: error) }
                } label: {
                    Label("Freigeben", systemImage: "checkmark.seal")
                        .font(.mykMono(9.5)).foregroundStyle(MykColor.paper.color)
                        .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s2)
                        .background(Capsule().fill(MykColor.positive.color))
                }
                .buttonStyle(.plain)
                .help("Als aktiven Preis-Anker freigeben — wird ab jetzt in Schätzungen berücksichtigt.")
            }
        }
        .padding(.vertical, MykSpace.s4)
    }

    private func hint(icon: String, text: String, critical: Bool = false) -> some View {
        VStack(spacing: MykSpace.s4) {
            Image(systemName: icon).font(.mykHero)
                .foregroundStyle(critical ? MykColor.critical.color : MykColor.faint.color)
            Text(text).font(.mykSmall).foregroundStyle(MykColor.muted.color)
                .multilineTextAlignment(.center).frame(maxWidth: 380)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).padding(MykSpace.s7)
    }

    private var footer: some View {
        HStack(spacing: MykSpace.s3) {
            Circle().fill(MykColor.personal.color).frame(width: 5, height: 5)
            Text("LERN-LOOP · \(pending.count) OFFEN · \(freigegeben.count) FREIGEGEBEN · lokal, review-gated")
                .font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
            Spacer()
        }
        .padding(.horizontal, MykSpace.s6).padding(.vertical, MykSpace.s4)
    }

    private func reload() {
        do { pending = try store.pendingPDFPositions(); fehler = nil }
        catch { fehler = String(describing: error) }
    }

    private func euro(_ d: Decimal) -> String {
        (d as NSDecimalNumber).doubleValue.formatted(.currency(code: "EUR").locale(Locale(identifier: "de_DE")))
    }
}
