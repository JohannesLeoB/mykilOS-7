import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - ContactsImportView (Google→Airtable-Kontakte-Import, 2026-07-04)
// Entschieden (Johannes 2026-07-02): die Airtable-Tabelle „Kontakte" wird die Wahrheit für
// Projekt-Kontakte statt der live durchsuchten Google-Kontakte. Diese Ansicht ist der EINMALIGE
// (wiederholbare) Migrations-Trigger — Johannes klickt „Vorschau laden", sieht die geplanten
// Entscheidungen (neu/Dublette/verworfen), und erst „N Kontakte anlegen" schreibt wirklich.
// Läuft bewusst NICHT automatisch: Claude Code hat keinen Zugriff auf die echte Google-OAuth-
// Session dieses Nutzers — nur die laufende App kann diesen Import tatsächlich ausführen.
// Schreibpfad: `AppState.writeAirtableContact` (bestehend, `.create`), pro Kontakt einzeln,
// mit Audit + DataFlowLogger — kein Batch-Write, kein Umgehen des bestehenden Gates.
struct ContactsImportView: View {
    @Environment(AppState.self) private var appState

    private enum Phase: Equatable {
        case idle, loadingPreview, preview, importing, done
    }

    @State private var phase: Phase = .idle
    @State private var candidates: [ContactImportCandidate] = []
    @State private var fehler: String?
    @State private var createdCount = 0
    @State private var importFehler: [String] = []

    private var neuKandidaten: [ContactImportCandidate] { candidates.filter { $0.decision == .create } }
    private var dublettenCount: Int {
        candidates.filter { if case .duplicate = $0.decision { return true }; return false }.count
    }
    private var verworfenCount: Int { candidates.filter { $0.decision == .skipIncomplete }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Kontakte-Import (Google → Airtable)")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            Text("Migriert echte Google-Kontakte in die Airtable-Tabelle Kontakte — Dubletten (Mail oder Telefon stimmt bereits) werden übersprungen, Einträge ohne Mail UND Telefon verworfen. Nichts wird automatisch geschrieben.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)

            if let fehler {
                Text(fehler).font(.mykMono(10)).foregroundStyle(MykColor.critical.color)
            }

            switch phase {
            case .idle:
                Button("Vorschau laden") { Task { await ladeVorschau() } }
                    .buttonStyle(.bordered)
            case .loadingPreview:
                HStack(spacing: MykSpace.s3) {
                    ProgressView().controlSize(.small)
                    Text("Lade Google-Kontakte + bestehenden Airtable-Bestand …")
                        .font(.mykSmall).foregroundStyle(MykColor.muted.color)
                }
            case .preview:
                previewSummary
                Button("\(neuKandidaten.count) Kontakte anlegen") {
                    Task { await fuehreImportAus() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(neuKandidaten.isEmpty)
            case .importing:
                HStack(spacing: MykSpace.s3) {
                    ProgressView().controlSize(.small)
                    Text("Lege Kontakte an …").font(.mykSmall).foregroundStyle(MykColor.muted.color)
                }
            case .done:
                doneSummary
                Button("Erneut prüfen") { phase = .idle; candidates = []; fehler = nil }
                    .buttonStyle(.bordered)
            }
        }
        .settingsCard()
    }

    private var previewSummary: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            summaryLine("Neu anzulegen", neuKandidaten.count, MykColor.positive.color)
            summaryLine("Dubletten übersprungen", dublettenCount, MykColor.muted.color)
            summaryLine("Unvollständig verworfen (weder Mail noch Telefon)", verworfenCount, MykColor.faint.color)
            if neuKandidaten.isEmpty == false {
                Text(neuKandidaten.prefix(8).map(\.googleContact.displayName).joined(separator: ", ")
                     + (neuKandidaten.count > 8 ? " …" : ""))
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.muted.color)
                    .lineLimit(2)
            }
        }
    }

    private var doneSummary: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(MykColor.positive.color)
                Text("\(createdCount) Kontakte angelegt in Airtable").font(.mykSmall).foregroundStyle(MykColor.positive.color)
            }
            ForEach(importFehler, id: \.self) { msg in
                Text(msg).font(.mykMono(9)).foregroundStyle(MykColor.critical.color)
            }
        }
    }

    private func summaryLine(_ label: String, _ count: Int, _ color: Color) -> some View {
        HStack(spacing: MykSpace.s2) {
            Text("\(count)").font(.mykMono(11)).foregroundStyle(color)
            Text(label.uppercased()).font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
        }
    }

    // MARK: Aktionen

    private func ladeVorschau() async {
        phase = .loadingPreview
        fehler = nil
        let start = DispatchTime.now()
        do {
            let google = try await GoogleContactsClient().listAllContacts()
            let airtableLoader = AirtableContactsLoader()
            await airtableLoader.load()
            candidates = ContactImportPlanner.plan(googleContacts: google, existing: airtableLoader.contacts)
            let durationMs = Int(Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000)
            appState.dataFlow.log(
                integrationID: "GOOGLE_CONTACTS_TO_AIRTABLE_IMPORT", actorUserID: appState.actorUserID,
                action: .success, recordsRead: google.count, durationMs: durationMs,
                summary: "Vorschau: \(neuKandidaten.count) neu, \(dublettenCount) Dubletten, \(verworfenCount) verworfen")
            phase = .preview
        } catch {
            fehler = "Vorschau fehlgeschlagen: \(error)"
            phase = .idle
        }
    }

    private func fuehreImportAus() async {
        phase = .importing
        var created = 0
        var errors: [String] = []
        for candidate in neuKandidaten {
            guard let draft = ContactImportPlanner.draft(for: candidate) else { continue }
            switch await appState.writeAirtableContact(draft) {
            case .created: created += 1
            case .failed(let msg): errors.append("\(candidate.googleContact.displayName): \(msg)")
            case .updated: break
            }
        }
        createdCount = created
        importFehler = errors
        phase = .done
    }
}
