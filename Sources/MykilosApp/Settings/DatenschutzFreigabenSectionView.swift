import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - DatenschutzFreigabenSectionView (Vision-Doku "Nutzerprofil & Datenschutz", Stufe 3)
// Was dieser Bewohner mit dem Assistenten teilt — einzeln toggelbar (opt-in/opt-out, kein
// Blanko-Konsens), globaler "KI komplett aus"-Schalter, "Meine Daten exportieren" (DSGVO
// Art. 15/20). Die Per-User-Isolation (Mail/Notizen/Chat/Clockodo nie kreuzlesbar) gilt
// TECHNISCH immer, unabhängig von diesen Schaltern — das hier ist die zusätzliche, vom
// Nutzer selbst gesteuerte Sichtbarkeits-Ebene gegenüber dem eigenen Assistenten.
//
// ⚠️ ENTWURF: Die Freigabetexte unten sind ein Vorschlag, keine geprüften Rechtstexte —
// Johannes redigiert den Wortlaut (siehe VISION_LOGIN_UND_DATENFLUSS.md, "keine
// eigenmächtigen Rechtstexte").
struct DatenschutzFreigabenSectionView: View {
    let store: DatenschutzPraeferenzenStore
    let profile: ProfileStore
    let notes: AssistantNotesStore
    let tasks: AssistantTasksStore
    let chat: ChatStore
    let projektNummern: [String]

    @State private var exportErgebnis: String?
    @State private var exportLaeuft = false

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            header
            Divider().overlay(MykColor.line.color)
            kiKomplettAusToggle
            Divider().overlay(MykColor.line.color)
            kategorienToggles
            Divider().overlay(MykColor.line.color)
            exportRow
        }
        .settingsCard()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Was ich teile").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
            Text("ENTWURF — Wortlaut wird noch redigiert. Diese Schalter drücken deine "
                 + "Präferenz aus; der Assistent lässt abgeschaltete Kategorien aus seinem "
                 + "Kontext. Die technische Trennung deiner Daten von anderen Bewohnern "
                 + "(Mail/Notizen/Chat/Zeiten) gilt davon unabhängig immer.")
                .font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var kiKomplettAusToggle: some View {
        Toggle(isOn: kiKomplettAusBinding) {
            Label("KI komplett aus", systemImage: "power")
                .font(.mykSmall).foregroundStyle(MykColor.ink.color)
        }
        .toggleStyle(.switch)
        .frame(maxWidth: 400, alignment: .leading)
    }

    private var kategorienToggles: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            Text("KATEGORIEN").font(.mykMono(10)).tracking(1.5).foregroundStyle(MykColor.muted.color)
            Toggle(isOn: binding(\.teileMailMitAssistent)) {
                Label("Mail", systemImage: "envelope").font(.mykSmall)
            }
            Toggle(isOn: binding(\.teileNotizenMitAssistent)) {
                Label("Notizen", systemImage: "note.text").font(.mykSmall)
            }
            Toggle(isOn: binding(\.teileChatMitAssistent)) {
                Label("Chat-Verlauf", systemImage: "bubble.left.and.bubble.right").font(.mykSmall)
            }
            Toggle(isOn: binding(\.teileClockodoMitAssistent)) {
                Label("Zeiten (Clockodo)", systemImage: "clock").font(.mykSmall)
            }
        }
        .toggleStyle(.switch)
        .frame(maxWidth: 400, alignment: .leading)
        .disabled(store.praeferenzen.kiKomplettAus)
        .opacity(store.praeferenzen.kiKomplettAus ? 0.5 : 1)
    }

    private var exportRow: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            HStack(spacing: MykSpace.s4) {
                Image(systemName: "square.and.arrow.up").foregroundStyle(MykColor.drive.color)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Meine Daten exportieren").font(.mykBody).foregroundStyle(MykColor.ink.color)
                    Text("Profil, Notizen, Aufgaben + Chat-Nachrichtenzahl je Bereich als JSON.")
                        .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                }
                Spacer()
                Button(exportLaeuft ? "Exportiert…" : "Exportieren …") {
                    Task { await exportieren() }
                }
                .font(.mykMono(10)).foregroundStyle(MykColor.drive.color)
                .buttonStyle(.plain).disabled(exportLaeuft)
            }
            if let exportErgebnis {
                Text(exportErgebnis).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
        }
    }

    // MARK: Bindings

    private var kiKomplettAusBinding: Binding<Bool> {
        Binding(
            get: { store.praeferenzen.kiKomplettAus },
            set: { neu in aktualisiere { $0.kiKomplettAus = neu } }
        )
    }

    private func binding(_ keyPath: WritableKeyPath<DatenschutzPraeferenzen, Bool>) -> Binding<Bool> {
        Binding(
            get: { store.praeferenzen[keyPath: keyPath] },
            set: { neu in aktualisiere { $0[keyPath: keyPath] = neu } }
        )
    }

    private func aktualisiere(_ aendern: (inout DatenschutzPraeferenzen) -> Void) {
        var neu = store.praeferenzen
        aendern(&neu)
        neu.updatedAt = Date()
        do {
            try store.speichere(neu)
        } catch {
            // store.saveState trägt den Fehler bereits sichtbar.
        }
    }

    // MARK: Export

    private func exportieren() async {
        exportLaeuft = true
        exportErgebnis = nil
        let export = await DatenschutzExportService.erstelle(
            profile: profile, notes: notes, tasks: tasks, chat: chat, projektNummern: projektNummern
        )
        do {
            let daten = try JSONEncoder.datenschutzExport.encode(export)
            if speichernAlsDatei(daten) {
                exportErgebnis = "Export gespeichert."
            }
        } catch {
            exportErgebnis = "Export fehlgeschlagen: \(error.localizedDescription)"
        }
        exportLaeuft = false
    }

    private func speichernAlsDatei(_ daten: Data) -> Bool {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "meine-daten.json"
        panel.prompt = "Speichern"
        panel.message = "Datenexport speichern"
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        do {
            try daten.write(to: url)
            return true
        } catch {
            exportErgebnis = "Speichern fehlgeschlagen: \(error.localizedDescription)"
            return false
        }
    }
}

private extension JSONEncoder {
    static let datenschutzExport: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}
