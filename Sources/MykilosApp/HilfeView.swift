import SwiftUI
import MykilosDesign

// MARK: - HilfeView (In-App-Handbuch)
//
// Rendert das kanonische `docs/BENUTZERHANDBUCH.md` als durchsuchbares Zwei-Spalten-
// Handbuch und ersetzt den macOS-Standard „Help isn't available for mykilOS".
//
// Quelle der Wahrheit bleibt `docs/BENUTZERHANDBUCH.md` (Pflichtdoku laut CLAUDE.md,
// jede Behauptung dort ist gegen den echten Code verifiziert). `build_and_run.sh`
// spiegelt sie bei jedem Bundle-Build frisch nach `Sources/MykilosApp/Resources/`,
// von wo `.copy("Resources")` sie ins Bundle legt → `Bundle.module` findet sie.
// Rein lesend, keine Aktion, kein Schreibvorgang.
@MainActor
struct HilfeView: View {
    @State private var sektionen: [HilfeSektion] = []
    @State private var auswahl: HilfeSektion.ID?
    @State private var suche: String = ""
    @State private var ladeFehler: String?

    // Suche filtert Sektionen nach Titel ODER Rohtext (case-insensitive).
    private var gefiltert: [HilfeSektion] {
        let frage = suche.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard frage.isEmpty == false else { return sektionen }
        return sektionen.filter {
            $0.titel.lowercased().contains(frage) || $0.rohtext.lowercased().contains(frage)
        }
    }

    private var aktiveSektion: HilfeSektion? {
        gefiltert.first { $0.id == auswahl } ?? gefiltert.first
    }

    var body: some View {
        HStack(spacing: 0) {
            seitenleiste
            Divider().overlay(MykColor.line.color)
            inhalt
        }
        .background(MykColor.paper.color)
        .task { ladeHandbuch() }
    }

    // MARK: Linke Spalte: Suche + Sektionsliste

    private var seitenleiste: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Handbuch")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
                .padding(.horizontal, MykSpace.s5)
                .padding(.top, MykSpace.s6)
                .padding(.bottom, MykSpace.s3)

            HStack(spacing: MykSpace.s2) {
                Image(systemName: "magnifyingglass").font(.mykCaption).foregroundStyle(MykColor.muted.color)
                TextField("Durchsuchen …", text: $suche)
                    .font(.mykSmall).textFieldStyle(.plain)
                if suche.isEmpty == false {
                    Button { suche = "" } label: {
                        Image(systemName: "xmark.circle.fill").font(.mykCaption).foregroundStyle(MykColor.faint.color)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s3)
            .background(MykColor.paper.color)
            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
            .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
            .padding(.horizontal, MykSpace.s4)
            .padding(.bottom, MykSpace.s3)

            Divider().overlay(MykColor.line.color)

            ScrollView {
                VStack(alignment: .leading, spacing: 1) {
                    if gefiltert.isEmpty {
                        Text("Keine Treffer.")
                            .font(.mykSmall).foregroundStyle(MykColor.muted.color)
                            .padding(MykSpace.s4)
                    }
                    ForEach(gefiltert) { sektion in
                        let aktiv = aktiveSektion?.id == sektion.id
                        Button { auswahl = sektion.id } label: {
                            Text(sektion.titel)
                                .font(.mykSmall)
                                .foregroundStyle(aktiv ? MykColor.ink.color : MykColor.inkSoft.color)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s3)
                                .background(aktiv ? MykColor.paper2.color : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.vertical, MykSpace.s3)
                .padding(.horizontal, MykSpace.s3)
            }
        }
        .frame(width: 248)
        .background(MykColor.card.color)
    }

    // MARK: Rechte Spalte: gerenderter Abschnitt

    private var inhalt: some View {
        Group {
            if let fehler = ladeFehler {
                zentriert(fehler)
            } else if let sektion = aktiveSektion {
                ScrollView {
                    VStack(alignment: .leading, spacing: MykSpace.s2) {
                        Text(sektion.titel)
                            .font(.mykDisplay)
                            .foregroundStyle(MykColor.ink.color)
                            .padding(.bottom, MykSpace.s3)
                        ForEach(Self.bloecke(sektion.zeilen)) { block in
                            if block.istCode {
                                codeBlock(block.zeilen)
                            } else {
                                zeile(block.zeilen.first ?? "")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(MykSpace.s8)
                }
            } else {
                zentriert("Handbuch wird geladen …")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func zentriert(_ text: String) -> some View {
        VStack { Spacer(); Text(text).font(.mykBody).foregroundStyle(MykColor.muted.color); Spacer() }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Ein zusammenhängender ```-Codeblock: monospaced, eigener Rahmen, horizontal
    // scrollbar (lange Kommandozeilen brechen die Seite sonst auf).
    private func codeBlock(_ zeilen: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(zeilen.enumerated()), id: \.offset) { _, codezeile in
                    Text(codezeile.isEmpty ? " " : codezeile)
                        .font(.mykMono(10)).foregroundStyle(MykColor.inkSoft.color)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MykSpace.s4)
        }
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
        .padding(.vertical, MykSpace.s2)
    }

    // MARK: Zeilen-Renderer (leichtgewichtiges Markdown)

    @ViewBuilder
    private func zeile(_ roh: String) -> some View {
        let text = roh.trimmingCharacters(in: .whitespaces)
        if text.isEmpty {
            Color.clear.frame(height: MykSpace.s2)
        } else if text.hasPrefix("```") {
            EmptyView()                                   // Code-Fence-Marker nicht anzeigen
        } else if text == "---" || text == "***" {
            Divider().overlay(MykColor.line.color).padding(.vertical, MykSpace.s2)
        } else if text.hasPrefix("### ") {
            Text(String(text.dropFirst(4)))
                .font(.mykHeadline).foregroundStyle(MykColor.ink.color)
                .padding(.top, MykSpace.s3)
        } else if text.hasPrefix("#### ") {
            Text(String(text.dropFirst(5)))
                .font(.mykBody).foregroundStyle(MykColor.inkSoft.color)
                .padding(.top, MykSpace.s2)
        } else if text.hasPrefix("|") {
            // Tabellenzeile roh + monospaced (Tabellen-Layout ist v1 bewusst schlicht).
            Text(text).font(.mykMono(10)).foregroundStyle(MykColor.inkSoft.color)
                .textSelection(.enabled)
        } else if text.hasPrefix("- ") || text.hasPrefix("* ") {
            HStack(alignment: .top, spacing: MykSpace.s2) {
                Text("•").font(.mykBody).foregroundStyle(MykColor.muted.color)
                markdownText(String(text.dropFirst(2)))
            }
        } else {
            markdownText(text)
        }
    }

    private func markdownText(_ roh: String) -> some View {
        Text(Self.inlineMarkdown(roh))
            .font(.mykBody).foregroundStyle(MykColor.ink.color)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }

    // Inline-Markdown (fett/kursiv/Code/Links) für eine reine Anzeige-Konvertierung.
    // Scheitert das Parsen, ist der unformatierte Text die bewusst gewählte, sichtbare
    // Rückfallebene — kein verschluckter Fehler, sondern ein definierter Fallback.
    private static func inlineMarkdown(_ roh: String) -> AttributedString {
        do {
            return try AttributedString(
                markdown: roh,
                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            return AttributedString(roh)
        }
    }

    // MARK: Laden + Parsen

    private func ladeHandbuch() {
        guard let url = Bundle.module.url(forResource: "BENUTZERHANDBUCH", withExtension: "md", subdirectory: "Resources")
            ?? Bundle.module.url(forResource: "BENUTZERHANDBUCH", withExtension: "md") else {
            ladeFehler = "Handbuch konnte nicht geladen werden (Ressource fehlt im Bundle)."
            return
        }
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            sektionen = Self.parse(text)
            auswahl = sektionen.first?.id
        } catch {
            ladeFehler = "Handbuch konnte nicht gelesen werden: \(error.localizedDescription)"
        }
    }

    /// Zerlegt das Markdown in Abschnitte an jeder `## `-Überschrift. Der Titel (`# `)
    /// eröffnet den einleitenden Abschnitt; alles davor gehört zu ihm.
    static func parse(_ text: String) -> [HilfeSektion] {
        var ergebnis: [HilfeSektion] = []
        var titel: String?
        var zeilen: [String] = []
        var laufindex = 0

        func abschliessen() {
            guard let titel else { zeilen = []; return }
            ergebnis.append(HilfeSektion(id: laufindex, titel: titel, zeilen: zeilen))
            laufindex += 1
            zeilen = []
        }

        for zeile in text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            if zeile.hasPrefix("## ") {
                abschliessen()
                titel = String(zeile.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            } else if zeile.hasPrefix("# ") && titel == nil {
                titel = String(zeile.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            } else {
                zeilen.append(zeile)
            }
        }
        abschliessen()
        return ergebnis
    }

    /// Gruppiert die Zeilen eines Abschnitts in Blöcke: zusammenhängende ```-Fences
    /// werden zu EINEM Code-Block (monospaced gerendert), alles andere bleibt eine
    /// Ein-Zeilen-Text-Block (den der bestehende `zeile`-Renderer verarbeitet). Reine,
    /// deterministische Funktion — testbar ohne Bundle/View.
    static func bloecke(_ zeilen: [String]) -> [HilfeBlock] {
        var ergebnis: [HilfeBlock] = []
        var index = 0
        var imCode = false
        var codeZeilen: [String] = []

        for zeile in zeilen {
            if zeile.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if imCode {
                    ergebnis.append(HilfeBlock(id: index, istCode: true, zeilen: codeZeilen))
                    index += 1
                    codeZeilen = []
                    imCode = false
                } else {
                    imCode = true
                }
                continue
            }
            if imCode {
                codeZeilen.append(zeile)
            } else {
                ergebnis.append(HilfeBlock(id: index, istCode: false, zeilen: [zeile]))
                index += 1
            }
        }
        // Nicht geschlossener Fence: den gesammelten Code trotzdem als Block ausgeben.
        if imCode && codeZeilen.isEmpty == false {
            ergebnis.append(HilfeBlock(id: index, istCode: true, zeilen: codeZeilen))
        }
        return ergebnis
    }
}

// MARK: - HilfeSektion / HilfeBlock

struct HilfeSektion: Identifiable, Equatable {
    let id: Int
    let titel: String
    let zeilen: [String]
    var rohtext: String { zeilen.joined(separator: "\n") }
}

struct HilfeBlock: Identifiable, Equatable {
    let id: Int
    let istCode: Bool
    let zeilen: [String]
}
