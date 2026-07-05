import SwiftUI
import UIKit

/// Fang → Versteh → Verräum. "Sprich oder tippe" ist jetzt beides echt — das
/// Mikro-Icon nimmt auf, transkribiert on-device (Deutsch) und speist den
/// Text in dieselbe Versteh-Pipeline wie Getipptes. Bestätigen schreibt wirklich in die lokale Postbox
/// (`PostboxStore`) — echt, neustart-fest. Der Sync von dort in die Airtable-
/// Adapter-Base (nur Zeit-Einträge, siehe `AirtableClockodoPostboxClient`) ist
/// gebaut, aber ein eigener, expliziter Schritt in der Postbox-Ansicht — nie
/// automatisch beim Bestätigen (Downlink-Doktrin: erst die gemeinsame
/// Orbit-Ablage, nie direkt und nie ungefragt ins Schiff).
struct FangCard: View {
    let postbox: PostboxStore
    let store: ProjectStore
    let feldFotoStore: FeldFotoStore
    let wareneingangStore: WareneingangsLogStore
    @State private var eingabe = ""
    @State private var aktiv: FangKind?
    @State private var erledigtText: String?
    @State private var schreibFehler: String?
    @State private var zeigeKameraAuswahl = false
    @State private var kameraModus: KameraModus?
    @State private var frischesBild: FrischesBild?
    @State private var frischeVisitenkarte: FrischeVisitenkarte?
    @State private var frischerLieferschein: FrischerLieferschein?
    @State private var zeigeSprachaufnahme = false

    private let chips: [String] = ["'4h CAD für Heinz'", "'Idee: Messing für die Bar'"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FANG → VERSTEH → VERRÄUM")
                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(MykColor.brand)

            HStack(spacing: 8) {
                TextField("Sprich oder tippe einen Moment…", text: $eingabe)
                    .textFieldStyle(.plain)
                    .padding(11)
                    .background(MykColor.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(MykColor.line))
                    .onSubmit { fangenFalls(eingabe) }

                Button {
                    fangenFalls(eingabe)
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(MykColor.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    zeigeSprachaufnahme = true
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.body.weight(.bold))
                        .foregroundStyle(MykColor.brand)
                        .frame(width: 44, height: 44)
                        .background(MykColor.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(MykColor.line))
                }
                .accessibilityLabel("Moment sprechen statt tippen")

                Button {
                    zeigeKameraAuswahl = true
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.body.weight(.bold))
                        .foregroundStyle(MykColor.brand)
                        .frame(width: 44, height: 44)
                        .background(MykColor.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(MykColor.line))
                }
                .accessibilityLabel("Kamera — Feld-Foto oder Visitenkarte")
                .confirmationDialog("Was soll die Kamera fangen?", isPresented: $zeigeKameraAuswahl) {
                    Button("Feld-Foto (Projekt-Dokumentation)") { kameraModus = .feldFoto }
                    Button("Visitenkarte (Kontakt anlegen)") { kameraModus = .visitenkarte }
                    Button("Lieferschein (Wareneingang)") { kameraModus = .lieferschein }
                    Button("Abbrechen", role: .cancel) {}
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(chips, id: \.self) { chip in
                        Button(chip) { fangen(chip) }
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 5)
                            .background(MykColor.paper)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(MykColor.line))
                    }
                }
            }

            if let kind = aktiv {
                karte(for: kind)
            }
            if let text = erledigtText {
                Text(text)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(MykColor.ok)
                    .padding(11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(MykColor.ok, lineWidth: 1.5))
            }
            if let fehler = schreibFehler {
                Text(fehler)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(MykColor.crit)
            }
            if !postbox.items.isEmpty {
                NavigationLink {
                    PostboxView(postbox: postbox)
                } label: {
                    Text("\(postbox.items.count) in der Postbox · ansehen")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(MykColor.muted)
                }
            }
        }
        .padding(14)
        .background(MykColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(MykColor.line))
        .fullScreenCover(item: $kameraModus) { modus in
            KameraAufnahmeView(
                onAufnahme: { bild, _ in
                    switch modus {
                    case .feldFoto:
                        frischesBild = FrischesBild(bild: bild, aufgenommenAm: Date())
                    case .visitenkarte:
                        frischeVisitenkarte = FrischeVisitenkarte(bild: bild)
                    case .lieferschein:
                        frischerLieferschein = FrischerLieferschein(bild: bild)
                    }
                    kameraModus = nil
                },
                onAbbruch: { kameraModus = nil }
            )
            .ignoresSafeArea()
        }
        .sheet(item: $frischesBild) { frisch in
            FeldFotoBestaetigungView(
                bild: frisch.bild,
                aufgenommenAm: frisch.aufgenommenAm,
                store: store,
                feldFotoStore: feldFotoStore,
                onFertig: { frischesBild = nil }
            )
        }
        .sheet(item: $frischeVisitenkarte) { frisch in
            VisitenkarteBestaetigungView(bild: frisch.bild, onFertig: { frischeVisitenkarte = nil })
        }
        .sheet(item: $frischerLieferschein) { frisch in
            LieferscheinBestaetigungView(
                bild: frisch.bild,
                store: store,
                wareneingangStore: wareneingangStore,
                onFertig: { frischerLieferschein = nil }
            )
        }
        .sheet(isPresented: $zeigeSprachaufnahme) {
            SprachaufnahmeView(
                onFertig: { text in
                    zeigeSprachaufnahme = false
                    fangenFalls(text)
                },
                onAbbruch: { zeigeSprachaufnahme = false }
            )
            .presentationDetents([.medium])
        }
    }

    /// Projekt-Erkennung im Fang: „3h Montage für Doehle" → Doehle wird in
    /// der Karte SICHTBAR angezeigt, bevor bestätigt wird — kein stilles
    /// Raten, der eine Bestätigen-Tipp gilt für Text UND erkanntes Projekt.
    /// Bei mehreren Treffern gewinnt der längste Titel (spezifischster Name).
    private var erkanntesProjekt: Project? {
        let text = eingabe.lowercased()
        guard !text.isEmpty else { return nil }
        return store.projects
            .filter { $0.title.count >= 3 && text.contains($0.title.lowercased()) }
            .max { $0.title.count < $1.title.count }
    }

    private func fangenFalls(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        fangen(text)
    }

    private func fangen(_ text: String) {
        erledigtText = nil
        schreibFehler = nil
        eingabe = text
            .trimmingCharacters(in: CharacterSet(charactersIn: "\u{201E}\u{201C}\u{201D}"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        aktiv = FangKind.versteh(eingabe)
    }

    private func bestaetigen(_ kind: FangKind) {
        let projektZusatz = erkanntesProjekt.map { " · Projekt \($0.projectNumber)" } ?? ""
        let item: PostboxItem
        switch kind {
        case .zeit(let dauer, let kontext):
            item = PostboxItem(kind: "zeit", text: dauer, kontext: kontext + projektZusatz)
        case .idee(let text):
            item = PostboxItem(kind: "idee", text: text, kontext: projektZusatz.trimmingCharacters(in: CharacterSet(charactersIn: " ·")))
        case .fotoHinweis:
            return
        }
        do {
            try postbox.append(item)
            erledigtText = item.kind == "zeit"
                ? "✓ In der Postbox abgelegt — Sync in die Adapter-Base ist ein eigener Schritt dort."
                : "✓ In der Postbox abgelegt — Ziel-Heimat für Ideen ist noch offen, bleibt bis dahin lokal."
            schreibFehler = nil
            aktiv = nil
            eingabe = ""
        } catch {
            schreibFehler = Fehlertext.deutsch(error)
        }
    }

    @ViewBuilder
    private func karte(for kind: FangKind) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(kind.titel)
                .font(.system(.caption2, design: .monospaced).weight(.bold))
                .foregroundStyle(kind.gesperrt ? MykColor.muted : MykColor.brand)
            Text(kind.koerper).font(.subheadline)
            Text(kind.meta).font(.caption).foregroundStyle(MykColor.muted)

            if !kind.gesperrt, let projekt = erkanntesProjekt {
                Label("\(projekt.title) · \(projekt.projectNumber)", systemImage: "mappin.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MykColor.brand)
                    .accessibilityLabel("Projekt erkannt: \(projekt.title)")
            }

            if !kind.gesperrt {
                HStack(spacing: 8) {
                    Button("Bestätigen") { bestaetigen(kind) }
                        .buttonStyle(.borderedProminent)
                        .tint(MykColor.brand)

                    Button("Verwerfen") { aktiv = nil }
                        .buttonStyle(.bordered)
                }
                .font(.footnote.weight(.semibold))
            }
        }
        .padding(12)
        .background(kind.gesperrt ? Color.clear : MykColor.brand.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(kind.gesperrt ? MykColor.muted : MykColor.brand, lineWidth: 1.4)
        )
    }
}

/// Kleiner Identifiable-Wrapper, damit `.sheet(item:)` ein frisch aufgenommenes
/// Bild + Zeitstempel transportieren kann.
private struct FrischesBild: Identifiable {
    let id = UUID()
    let bild: UIImage
    let aufgenommenAm: Date
}

/// Wofür der nächste Kamera-Aufruf gedacht ist — entscheidet, wohin die
/// Aufnahme danach führt (Feld-Foto-Bestätigung oder Visitenkarten-Bestätigung).
private enum KameraModus: Identifiable {
    case feldFoto
    case visitenkarte
    case lieferschein
    var id: Self { self }
}

private struct FrischeVisitenkarte: Identifiable {
    let id = UUID()
    let bild: UIImage
}

private struct FrischerLieferschein: Identifiable {
    let id = UUID()
    let bild: UIImage
}
