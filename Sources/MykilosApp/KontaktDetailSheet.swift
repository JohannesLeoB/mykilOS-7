import SwiftUI
import MykilosDesign
import MykilosServices
import MykilosKit

// MARK: - KontaktDetailSheet
// Zeigt alle Felder eines Airtable-Kontakts. Felder sind direkt bearbeitbar.
// Speichern: gated über AppState.writeAirtableContact (Intent .update + recordID).
// Kein Delete. Bestätigung + SaveState sichtbar in der Karte.
// „Mail schreiben": öffnet ComposeMailView mit vorausgefülltem Empfänger.
@MainActor
struct KontaktDetailSheet: View {
    let contact: StudioContact
    let allContacts: [StudioContact]
    let onSave: (AirtableContactDraft) -> Void
    let onClose: () -> Void

    // Editierbare Felder (vorbefüllt aus dem Kontakt)
    @State private var name: String
    @State private var organisation: String
    @State private var email: String
    @State private var telefon: String
    @State private var adresse: String
    @State private var kategorie: String

    // Interne Zustände
    @State private var savePhase: DetailSavePhase = .idle
    @State private var showCompose: Bool = false
    @State private var isDirty: Bool = false

    // Härtung (2026-07-01, Audit): "Architekt/Planer" (Schrägstrich) ist die echte, live
    // bestätigte Airtable-Select-Option — "Architekt-Planer" (Bindestrich) hätte hier
    // (kein typecast auf diesem Schreibpfad) einen HTTP 422 ausgelöst.
    private static let kategorien = [
        "Projektkunde", "Lieferant", "Handwerker",
        "Architekt/Planer", "MYKILOS-Team", "Sonstige"
    ]

    private enum DetailSavePhase: Equatable {
        case idle, saving, saved, failed(String)
    }

    init(contact: StudioContact, allContacts: [StudioContact],
         onSave: @escaping (AirtableContactDraft) -> Void,
         onClose: @escaping () -> Void) {
        self.contact = contact
        self.allContacts = allContacts
        self.onSave = onSave
        self.onClose = onClose
        _name = State(initialValue: contact.name)
        _organisation = State(initialValue: contact.organisation ?? "")
        _email = State(initialValue: contact.email ?? "")
        _telefon = State(initialValue: contact.telefon ?? "")
        _adresse = State(initialValue: contact.adresse ?? "")
        _kategorie = State(initialValue: contact.kategorie ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sheetHeader
            Divider().overlay(MykColor.line.color)
            ScrollView {
                VStack(alignment: .leading, spacing: MykSpace.s5) {
                    fieldSection
                    kategorieSection
                    actionSection
                    saveStatusSection
                }
                .padding(MykSpace.s7)
            }
        }
        .frame(width: 520, height: 600)
        .background(MykColor.paper.color)
        .sheet(isPresented: $showCompose) {
            ComposeMailView(
                contacts: allContacts,
                prefilledTo: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email
            )
        }
    }

    // MARK: Sheet-Header

    private var sheetHeader: some View {
        HStack(spacing: MykSpace.s4) {
            // Kategorie-farbiger Avatar
            ZStack {
                Circle()
                    .fill(MykColor.people.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(String(contact.name.prefix(1)).uppercased())
                    .font(.mykHeadline)
                    .foregroundStyle(MykColor.people.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.mykHeadline)
                    .foregroundStyle(MykColor.ink.color)
                if let org = contact.organisation, !org.isEmpty {
                    Text(org)
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.muted.color)
                }
            }
            Spacer()
            Button { onClose() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.mykBody)
                    .foregroundStyle(MykColor.faint.color)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, MykSpace.s7)
        .padding(.vertical, MykSpace.s5)
        .background(MykColor.card.color)
    }

    // MARK: Felder (editierbar)

    private var fieldSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            Text("KONTAKTDATEN")
                .font(.mykMono(9))
                .foregroundStyle(MykColor.muted.color)

            editField(label: "Name", icon: "person", text: $name)
            editField(label: "Organisation", icon: "building.2", text: $organisation)
            editField(label: "E-Mail", icon: "envelope", text: $email)
            editField(label: "Telefon", icon: "phone", text: $telefon)
            editField(label: "Adresse", icon: "map", text: $adresse)
        }
        .padding(MykSpace.s5)
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1))
    }

    private func editField(label: String, icon: String, text: Binding<String>) -> some View {
        HStack(spacing: MykSpace.s4) {
            Image(systemName: icon)
                .font(.mykCaption)
                .foregroundStyle(MykColor.people.color)
                .frame(width: MykSpace.s6, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.faint.color)
                TextField(label, text: text)
                    .font(.mykBody)
                    .textFieldStyle(.plain)
                    .foregroundStyle(MykColor.ink.color)
                    .onChange(of: text.wrappedValue) { _, _ in isDirty = true }
            }
        }
        .padding(.vertical, MykSpace.s2)
    }

    // MARK: Kategorie-Picker

    private var kategorieSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            Text("KATEGORIE")
                .font(.mykMono(9))
                .foregroundStyle(MykColor.muted.color)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MykSpace.s2) {
                    ForEach(Self.kategorien, id: \.self) { kat in
                        let active = kategorie == kat
                        Button {
                            kategorie = kat
                            isDirty = true
                        } label: {
                            Text(kat)
                                .font(.mykMono(9.5))
                                .foregroundStyle(active ? MykColor.paper.color : MykColor.muted.color)
                                .padding(.horizontal, MykSpace.s3)
                                .padding(.vertical, MykSpace.s2)
                                .background(active ? MykColor.people.color : MykColor.card.color)
                                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Aktionen (Mail + Speichern)

    private var actionSection: some View {
        HStack(spacing: MykSpace.s4) {
            // Mail-Button — nur wenn E-Mail vorhanden
            let hasEmail = !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            Button {
                showCompose = true
            } label: {
                Label("Mail schreiben", systemImage: "envelope")
                    .font(.mykSmall)
                    .foregroundStyle(hasEmail ? MykColor.personal.color : MykColor.faint.color)
                    .padding(.horizontal, MykSpace.s5)
                    .padding(.vertical, MykSpace.s3)
                    .background(
                        RoundedRectangle(cornerRadius: MykRadius.sm)
                            .fill(hasEmail ? MykColor.personal.color.opacity(0.12) : MykColor.faint.color.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MykRadius.sm)
                            .stroke(hasEmail ? MykColor.personal.color.opacity(0.4) : MykColor.line.color, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!hasEmail)

            Spacer()

            // Abbrechen
            Button("Abbrechen") { onClose() }
                .font(.mykSmall)
                .buttonStyle(.plain)
                .foregroundStyle(MykColor.muted.color)

            // Speichern (nur wenn Änderungen vorliegen und recordID gesetzt)
            let recordID = contact.id
            let canSave = isDirty && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !recordID.isEmpty && savePhase != .saving

            Button {
                saveContact()
            } label: {
                HStack(spacing: MykSpace.s2) {
                    if savePhase == .saving {
                        ProgressView().scaleEffect(0.6)
                    } else {
                        Image(systemName: "checkmark")
                    }
                    Text(savePhase == .saving ? "Speichert …" : "Änderungen speichern")
                }
                .font(.mykSmall)
                .foregroundStyle(MykColor.paper.color)
                .padding(.horizontal, MykSpace.s5)
                .padding(.vertical, MykSpace.s3)
                .background(
                    RoundedRectangle(cornerRadius: MykRadius.sm)
                        .fill(canSave ? MykColor.people.color : MykColor.muted.color.opacity(0.4))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
    }

    // MARK: Speicher-Status

    @ViewBuilder
    private var saveStatusSection: some View {
        switch savePhase {
        case .idle:
            if !isDirty {
                Text("Felder bearbeiten, um Änderungen zu speichern · AIRTABLE")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.faint.color)
            }
        case .saving:
            EmptyView()
        case .saved:
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(MykColor.positive.color)
                Text("Kontakt aktualisiert — Airtable Mastermind")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.positive.color)
            }
        case .failed(let msg):
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(MykColor.critical.color)
                Text("Fehler: \(msg)")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.critical.color)
            }
        }
    }

    // MARK: - Speicher-Aktion

    private func saveContact() {
        savePhase = .saving
        let draft = AirtableContactDraft(
            intent: .update,
            recordID: contact.id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            organisation: organisation.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            telefon: telefon.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            adresse: adresse.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            kategorie: kategorie.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        )
        // onSave wird vom Parent (KontakteKatalogTab) ausgeführt → async writeAirtableContact
        // Wir zeigen hier optimistisch .saved; echte Fehler landen im AuditLog.
        onSave(draft)
        savePhase = .saved
        isDirty = false
    }
}

// MARK: - Hilfserweiterung

private extension String {
    /// Gibt nil zurück wenn der String leer ist.
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
