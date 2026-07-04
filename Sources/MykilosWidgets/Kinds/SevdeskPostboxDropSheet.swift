import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - SevdeskPostboxDropSheet (Wirbelsäule · sevDesk-Postbox-Drop, UI)
//
// Bestätigungs-Gate für den Drop eines WorkBaskets in die sevDesk-Einweg-Postbox.
// Card→Confirm: die Vorschau (Port.preview inkl. sevDesk-BOSSMODE-Warnung) ist IMMER
// zuerst sichtbar, geschrieben wird erst auf expliziten Knopf. Kein Auto-Fire.
//
// Der eigentliche append-only Airtable-Write passiert im SevdeskPostboxCheckoutPort
// (MykilosServices). Diese View kennt nur Port + Korb + Ziel — kein direkter Airtable-Zugriff.
@MainActor
struct SevdeskPostboxDropSheet: View {
    let port: SevdeskPostboxCheckoutPort
    let basket: WorkBasket
    let actorUserID: String
    let onClose: () -> Void

    @State private var belegTyp: String = "Angebot"
    @State private var preview: CheckoutPreview?
    @State private var previewError: String?
    @State private var status: Status = .idle

    private let belegTypen = ["Angebot", "Rechnung", "Gutschrift", "Lieferschein", "Auftragsbestätigung"]

    private enum Status: Equatable {
        case idle, laeuft
        case erfolg(String)
        case fehler(String)
    }

    private var ziel: PortZiel {
        PortZiel(kind: "postbox", parameter: ["belegTyp": belegTyp, "user": actorUserID])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(MykColor.line.color)
            ScrollView {
                VStack(alignment: .leading, spacing: MykSpace.s6) {
                    hinweisBanner
                    belegTypPicker
                    vorschauSektion
                    statusSektion
                }
                .padding(MykSpace.s8)
            }
            Divider().overlay(MykColor.line.color)
            footer
        }
        .frame(width: 560, height: 560)
        .background(MykColor.paper.color)
        .task(id: belegTyp) { await ladeVorschau() }
    }

    // MARK: Bausteine

    private var header: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: "tray.and.arrow.down").font(.mykHeadline).foregroundStyle(MykColor.cash.color)
            VStack(alignment: .leading, spacing: 2) {
                Text("In sevDesk-Postbox droppen").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
                Text("Projekt \(basket.projektNummer) · \(basket.picks.count) Position(en)")
                    .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
            Spacer()
            Button { onClose() } label: {
                Image(systemName: "xmark").font(.mykSmall).foregroundStyle(MykColor.muted.color)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, MykSpace.s7).padding(.vertical, MykSpace.s6)
    }

    private var hinweisBanner: some View {
        HStack(alignment: .top, spacing: MykSpace.s3) {
            Image(systemName: "info.circle").font(.mykCaption).foregroundStyle(MykColor.cash.color)
            Text("Einweg-Briefkasten Richtung sevDesk. mykilOS stellt keinen Beleg aus — ein Mensch "
                 + "übernimmt in sevDesk. sevDesk hat die Hoheit über Mengen, Margen und Steuer; diese "
                 + "Zahlen sind ein Vorschlag. Append-only, ein zweiter identischer Drop legt nichts Neues an.")
                .font(.mykSmall).foregroundStyle(MykColor.muted.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MykSpace.s4)
        .background(MykColor.cash.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
    }

    private var belegTypPicker: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text("Beleg-Typ").font(.mykSmall).foregroundStyle(MykColor.muted.color)
            Picker("Beleg-Typ", selection: $belegTyp) {
                ForEach(belegTypen, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.segmented).labelsHidden()
            .disabled(status == .laeuft)
        }
    }

    private var vorschauSektion: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text("Vorschau").font(.mykSmall).foregroundStyle(MykColor.muted.color)
            if let previewError {
                Text("Vorschau-Fehler: \(previewError)").font(.mykSmall).foregroundStyle(MykColor.critical.color)
            } else if let preview {
                VStack(alignment: .leading, spacing: MykSpace.s3) {
                    Text(preview.zusammenfassung).font(.mykSmall).foregroundStyle(MykColor.ink.color)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(preview.warnungen, id: \.self) { w in
                        HStack(alignment: .top, spacing: MykSpace.s2) {
                            Image(systemName: "exclamationmark.triangle").font(.mykMono(9)).foregroundStyle(MykColor.tasks.color)
                            Text(w).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(MykSpace.s4)
                .background(MykColor.card.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
            } else {
                ProgressView().controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private var statusSektion: some View {
        switch status {
        case .idle, .laeuft: EmptyView()
        case .erfolg(let msg): statusLine(icon: "checkmark.circle.fill", text: msg, color: .positive)
        case .fehler(let msg): statusLine(icon: "exclamationmark.triangle.fill", text: msg, color: .critical)
        }
    }

    private func statusLine(icon: String, text: String, color: MykColor) -> some View {
        HStack(alignment: .top, spacing: MykSpace.s3) {
            Image(systemName: icon).foregroundStyle(color.color)
            Text(text).font(.mykSmall).foregroundStyle(color.color).fixedSize(horizontal: false, vertical: true)
        }
        .padding(MykSpace.s4).background(color.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
    }

    private var footer: some View {
        HStack {
            if status == .laeuft {
                HStack(spacing: MykSpace.s2) {
                    ProgressView().controlSize(.small)
                    Text("Wird abgelegt …").font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                }
            }
            Spacer()
            Button("Schließen") { onClose() }
                .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.muted.color)
            Button {
                Task { await droppe() }
            } label: {
                Label("In Postbox ablegen", systemImage: "tray.and.arrow.down.fill")
                    .font(.mykSmall).foregroundStyle(MykColor.paper.color)
                    .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s3)
                    .background(MykColor.cash.color).clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            }
            .buttonStyle(.plain)
            .disabled(status == .laeuft || basket.picks.isEmpty || previewError != nil)
        }
        .padding(.horizontal, MykSpace.s7).padding(.vertical, MykSpace.s5)
    }

    // MARK: Aktionen

    private func ladeVorschau() async {
        do {
            preview = try await port.preview(basket: basket, ziel: ziel)
            previewError = nil
        } catch {
            previewError = error.localizedDescription
            preview = nil
        }
    }

    private func droppe() async {
        status = .laeuft
        do {
            let result = try await port.execute(basket: basket, ziel: ziel)
            if result.erfolg {
                status = .erfolg(result.meldung ?? "In sevDesk-Postbox abgelegt.")
            } else {
                status = .fehler(result.meldung ?? "Ablage fehlgeschlagen.")
            }
        } catch {
            status = .fehler(error.localizedDescription)
        }
    }
}
