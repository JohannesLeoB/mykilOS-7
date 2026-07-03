import SwiftUI
import MykilosDesign
import MykilosKit
import MykilosServices

// MARK: - BestandskontaktErgebnis
// Ein vereinheitlichter Suchtreffer aus Airtable-Kontakten ODER Google-Kontakten,
// nur für den Prefill relevant — keine eigene Persistenz.
struct BestandskontaktErgebnis: Identifiable, Equatable {
    enum Quelle: Equatable { case airtable, google }
    let id: String
    let quelle: Quelle
    let anzeigeName: String
    let organisation: String?
    let email: String?
    let telefon: String?
    let vorname: String
    let nachname: String
}

// MARK: - BestandskontaktPicker
// Härtung (2026-07-01, Johannes: "Bestandskunden sollen direkt aus den Airtable/Google
// Kontakten ausgewählt werden können"). Suchfeld + Trefferliste; ein Treffer prefillt
// Vorname/Nachname/Firma/E-Mail/Telefon (nicht die Adresse — weder StudioContact.adresse
// noch GoogleContact liefern strukturierte Straße/PLZ/Ort-Felder, ein Zerlegen wäre raten).
@MainActor
struct BestandskontaktPicker: View {
    let airtableKontakte: [StudioContact]
    let onAuswahl: (BestandskontaktErgebnis) -> Void

    @State private var suchtext: String = ""
    @State private var googleTreffer: [GoogleContact] = []
    @State private var googleSuchLaeuft: Bool = false
    @State private var suchTask: Task<Void, Never>?

    private var airtableTreffer: [StudioContact] {
        let q = suchtext.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2 else { return [] }
        return Array(airtableKontakte.filter { $0.matches(q) }.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.people.color)
                TextField("Bestandskunde suchen (Airtable + Google Kontakte) …", text: $suchtext)
                    .font(.mykBody)
                    .textFieldStyle(.plain)
                    .onChange(of: suchtext) { _, neu in
                        suchTask?.cancel()
                        let q = neu.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard q.count >= 2 else { googleTreffer = []; return }
                        suchTask = Task {
                            try? await Task.sleep(for: .milliseconds(350))
                            guard !Task.isCancelled else { return }
                            await sucheGoogle(q)
                        }
                    }
                if googleSuchLaeuft {
                    ProgressView().scaleEffect(0.6)
                }
            }
            .padding(MykSpace.s3)
            .background(MykColor.card.color)
            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: MykRadius.sm)
                    .stroke(MykColor.line.color, lineWidth: 1)
            )

            if !airtableTreffer.isEmpty || !googleTreffer.isEmpty {
                VStack(alignment: .leading, spacing: MykSpace.s2) {
                    ForEach(airtableTreffer) { kontakt in
                        trefferZeile(
                            quelle: .airtable,
                            name: kontakt.name,
                            organisation: kontakt.organisation,
                            email: kontakt.email,
                            telefon: kontakt.telefon
                        ) {
                            waehle(BestandskontaktErgebnis(
                                id: "airtable-\(kontakt.id)",
                                quelle: .airtable,
                                anzeigeName: kontakt.name,
                                organisation: kontakt.organisation,
                                email: kontakt.email,
                                telefon: kontakt.telefon,
                                vorname: kontakt.vorname ?? Self.ersterToken(kontakt.name),
                                nachname: kontakt.nachname ?? Self.restToken(kontakt.name)
                            ))
                        }
                    }
                    ForEach(googleTreffer) { kontakt in
                        trefferZeile(
                            quelle: .google,
                            name: kontakt.displayName,
                            organisation: kontakt.organization,
                            email: kontakt.email,
                            telefon: kontakt.phone
                        ) {
                            waehle(BestandskontaktErgebnis(
                                id: "google-\(kontakt.id)",
                                quelle: .google,
                                anzeigeName: kontakt.displayName,
                                organisation: kontakt.organization,
                                email: kontakt.email,
                                telefon: kontakt.phone,
                                vorname: kontakt.givenName ?? Self.ersterToken(kontakt.displayName),
                                nachname: kontakt.familyName ?? Self.restToken(kontakt.displayName)
                            ))
                        }
                    }
                }
                .padding(MykSpace.s3)
                .background(MykColor.paper2.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            }
        }
    }

    private func trefferZeile(
        quelle: BestandskontaktErgebnis.Quelle,
        name: String,
        organisation: String?,
        email: String?,
        telefon: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: MykSpace.s3) {
                Image(systemName: quelle == .airtable ? "shippingbox" : "person.crop.circle")
                    .font(.mykMono(9))
                    .foregroundStyle(quelle == .airtable ? MykColor.cash.color : MykColor.people.color)
                VStack(alignment: .leading, spacing: 1) {
                    Text(name).font(.mykSmall).foregroundStyle(MykColor.ink.color)
                    let detail = [organisation, email, telefon].compactMap { $0 }.joined(separator: " · ")
                    if !detail.isEmpty {
                        Text(detail).font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
                    }
                }
                Spacer()
                Text(quelle == .airtable ? "Airtable" : "Google")
                    .font(.mykMono(8))
                    .foregroundStyle(MykColor.faint.color)
            }
            .padding(.vertical, MykSpace.s2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func waehle(_ ergebnis: BestandskontaktErgebnis) {
        onAuswahl(ergebnis)
        suchtext = ""
        googleTreffer = []
        suchTask?.cancel()
    }

    private func sucheGoogle(_ query: String) async {
        googleSuchLaeuft = true
        defer { googleSuchLaeuft = false }
        guard let ergebnisse = try? await GoogleContactsClient().searchContacts(query: query) else {
            googleTreffer = []
            return
        }
        googleTreffer = Array(ergebnisse.prefix(5))
    }

    private static func ersterToken(_ name: String) -> String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    private static func restToken(_ name: String) -> String {
        let teile = name.split(separator: " ")
        guard teile.count > 1 else { return "" }
        return teile.dropFirst().joined(separator: " ")
    }
}
