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

    private static let preisFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        f.maximumFractionDigits = 2
        return f
    }()

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
                // Positionsliste
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(warenkorb.positionen) { pos in
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

    var body: some View {
        HStack(alignment: .top, spacing: MykSpace.s4) {
            // Source-Badge
            Text(position.source == "katalog" ? "K" : "L")
                .font(.mykMono(8))
                .foregroundStyle(MykColor.paper.color)
                .frame(width: 16, height: 16)
                .background(position.source == "katalog" ? MykColor.tasks.color : MykColor.drive.color)
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
        let wk = warenkorb.makeWarenkorb(
            projektRecordID: selectedProjekt?.airtableRecordID,
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
            case .leer:
                sendState = .error("Warenkorb ist leer — nichts gesendet.")
            }
        } catch {
            sendState = .error(error.localizedDescription)
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
