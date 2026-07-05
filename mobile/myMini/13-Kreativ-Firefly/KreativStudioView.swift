import SwiftUI
import UIKit

/// Kreativ-Studio (#34/#46/#47): Bestandsfoto + Referenzkueche (Stil-DNA) +
/// Anpassungen -> fertiger Firefly-Render-Prompt zum Kopieren/Teilen.
/// Rein on-device; der eigentliche Render laeuft (heute) in der Firefly-
/// Web-/App-Oberflaeche, in die Prompt + Fotos eingefuegt werden.
struct KreativStudioView: View {
    let store: ProjectStore
    let feldFotoStore: FeldFotoStore

    @State private var briefStore = KreativBriefStore()
    @State private var galerie = ReferenzkuechenStore()

    @State private var suche = ""
    @State private var projekt: Project?
    @State private var bestandsfoto: FeldFoto?
    @State private var referenz: Referenzkueche?
    @State private var stil = ""
    @State private var materialFarbe = ""
    @State private var elemente = ""
    @State private var zusatz = ""
    @State private var modus: RenderModus = .photoshop
    @State private var fertigerPrompt: String?
    @State private var letzterBrief: KreativBrief?
    @State private var fehler: String?

    // Firefly-In-App-Render (nur aktiv, wenn ein Adobe-Zugang hinterlegt ist)
    private let fireflyStore: FireflyCredentialsStoring = KeychainFireflyCredentialsStore()
    @State private var fireflyVerbunden = false
    @State private var zeigeFireflyEinstellungen = false
    @State private var rendertGerade = false
    @State private var renderErgebnis: UIImage?
    @State private var renderFehler: String?
    @State private var renderGespeichert = false

    private enum RenderModus: String, CaseIterable {
        case photoshop = "Photoshop Fuellen"
        case firefly = "Firefly ganzes Bild"
    }

    private var projekte: [Project] {
        store.matching(suche).sorted { $0.projectNumber > $1.projectNumber }
    }

    private var projektFotos: [FeldFoto] {
        guard let projekt else { return [] }
        return feldFotoStore.fotos
            .filter { $0.projectNumber == projekt.projectNumber }
            .sorted { $0.aufgenommenAm > $1.aufgenommenAm }
    }

    var body: some View {
        Form {
            galerieLink
            projektSektion
            if projekt != nil {
                bestandsfotoSektion
                referenzSektion
                anpassungenSektion
                bauenSektion
            }
            if let fertigerPrompt { promptSektion(fertigerPrompt) }
            if fertigerPrompt != nil { renderSektion }
            if let fehler { Text(fehler).foregroundStyle(MykColor.crit) }
        }
        .navigationTitle("Kreativ-Studio")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fireflyVerbunden = (try? fireflyStore.load()) != nil }
        .sheet(isPresented: $zeigeFireflyEinstellungen) {
            FireflySettingsView(credentialsStore: fireflyStore, verbunden: $fireflyVerbunden)
        }
    }

    /// Ein-Knopf-Render, sobald ein Adobe-Firefly-Zugang hinterlegt ist.
    /// Text-zu-Bild aus dem komponierten Prompt (ganzes Bild). Ergebnis
    /// laesst sich als Feld-Foto sichern.
    private var renderSektion: some View {
        Section {
            if fireflyVerbunden {
                if rendertGerade {
                    HStack { ProgressView(); Text("Firefly rendert...").foregroundStyle(MykColor.muted) }
                } else {
                    Button {
                        Task { await rendern() }
                    } label: {
                        Label("In der App rendern (Firefly)", systemImage: "wand.and.stars.inverse")
                    }
                    .buttonStyle(.borderedProminent).tint(MykColor.brand)
                }
                if let renderErgebnis {
                    Image(uiImage: renderErgebnis)
                        .resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Button {
                        ergebnisSpeichern(renderErgebnis)
                    } label: {
                        Label(renderGespeichert ? "Als Feld-Foto gespeichert" : "Als Feld-Foto speichern",
                              systemImage: renderGespeichert ? "checkmark.seal.fill" : "square.and.arrow.down")
                    }
                    .disabled(renderGespeichert)
                    ShareLink(item: Image(uiImage: renderErgebnis), preview: SharePreview("Firefly-Render"))
                }
                if let renderFehler {
                    Text(renderFehler).font(.caption).foregroundStyle(MykColor.crit)
                }
            } else {
                Button {
                    zeigeFireflyEinstellungen = true
                } label: {
                    Label("Firefly-Zugang hinterlegen (Ein-Knopf-Render)", systemImage: "key.fill")
                }
                .font(.callout.weight(.semibold))
            }
        } header: {
            Text("Render")
        } footer: {
            Text(fireflyVerbunden
                 ? "Rendert direkt ueber Adobe Firefly Services. Kostet Adobe-Generative-Credits."
                 : "Ohne Zugang laeuft der Render ueber Kopieren + Firefly/Photoshop (oben).")
        }
    }

    private var galerieLink: some View {
        Section {
            NavigationLink {
                ReferenzGalerieView(galerie: galerie)
            } label: {
                Label("Referenz-Galerie (\(galerie.kuechen.count))", systemImage: "photo.stack.fill")
            }
        } footer: {
            Text("Unsere gebauten Kuechen als Stil-DNA - \"so in etwa soll's sein\".")
        }
    }

    private var projektSektion: some View {
        Section {
            TextField("Projekt suchen...", text: $suche)
            ForEach(projekte.prefix(5)) { p in
                Button {
                    projekt = p
                    bestandsfoto = nil
                    fertigerPrompt = nil
                } label: {
                    HStack {
                        Text(p.title)
                        Spacer()
                        Text(p.projectNumber).font(.system(.caption, design: .monospaced)).foregroundStyle(MykColor.muted)
                        if projekt?.id == p.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(MykColor.brand) }
                    }
                }
                .foregroundStyle(MykColor.ink)
            }
        } header: {
            Text("Schritt 1: Projekt")
        }
    }

    private var bestandsfotoSektion: some View {
        Section {
            if projektFotos.isEmpty {
                Text("Keine Feld-Fotos zu diesem Projekt - Bestandsfoto vorher ueber die Fang-Karte aufnehmen.")
                    .font(.caption).foregroundStyle(MykColor.muted)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(projektFotos.prefix(12)) { foto in
                            fotoKachel(url: feldFotoStore.bildURL(fuer: foto), gewaehlt: bestandsfoto?.id == foto.id)
                                .onTapGesture { bestandsfoto = foto }
                        }
                    }
                }
            }
        } header: {
            Text("Schritt 2: Bestandsfoto (die Firefly-Leinwand)")
        }
    }

    private var referenzSektion: some View {
        Section {
            if galerie.kuechen.isEmpty {
                Text("Noch keine Referenzkueche in der Galerie - oben hinzufuegen.")
                    .font(.caption).foregroundStyle(MykColor.muted)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(galerie.kuechen) { kueche in
                            VStack(spacing: 3) {
                                fotoKachel(url: galerie.bildURL(fuer: kueche), gewaehlt: referenz?.id == kueche.id)
                                Text(kueche.name).font(.caption2).lineLimit(1).frame(width: 90)
                            }
                            .onTapGesture {
                                referenz = kueche
                                if stil.isEmpty { stil = kueche.stil }
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Schritt 3: Stil-Referenz (optional)")
        } footer: {
            Text("Die gewaehlte Referenzkueche wird als Stil-Vorlage mitgeschickt.")
        }
    }

    private var anpassungenSektion: some View {
        Section {
            Picker("Stil", selection: $stil) {
                Text("- keiner -").tag("")
                ForEach(FireflyPromptKomponist.stile, id: \.self) { Text($0).tag($0) }
            }
            TextField("Material / Farbe (z. B. Fronten Eiche natur, Platte Marmor)", text: $materialFarbe, axis: .vertical)
                .lineLimit(1...3)
            TextField("Elemente (z. B. Kochinsel, Dunstabzug in Decke)", text: $elemente, axis: .vertical)
                .lineLimit(1...3)
            if let warenkorb = projekt?.warenkorb, !warenkorb.isEmpty {
                Button {
                    let namen = warenkorb.map(\.name).joined(separator: ", ")
                    elemente = elemente.isEmpty ? namen : elemente + ", " + namen
                } label: {
                    Label("Elemente aus Warenkorb (\(warenkorb.count))", systemImage: "cart.badge.plus")
                }
                .font(.caption.weight(.semibold))
            }
            TextField("Zusatzwuensche (frei)", text: $zusatz, axis: .vertical)
                .lineLimit(1...3)
        } header: {
            Text("Schritt 4: Anpassungen")
        } footer: {
            Text("Spaeter fuellen sich Material/Farbe und Elemente automatisch aus dem Projekt-Warenkorb und dem Material-Moodboard - der Komponist bleibt derselbe, bekommt nur reichere Zutaten.")
        }
    }

    private var bauenSektion: some View {
        Section {
            Picker("Render-Weg", selection: $modus) {
                ForEach(RenderModus.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            Button("Prompt bauen") { bauen() }
                .buttonStyle(.borderedProminent)
                .tint(MykColor.brand)
                .disabled(stil.isEmpty && materialFarbe.isEmpty && elemente.isEmpty && referenz == nil)
        } header: {
            Text("Schritt 5: Render-Weg")
        } footer: {
            Text(modus == .photoshop
                 ? "Photoshop: Bestandsfoto oeffnen, Kuechen-Bereich mit dem Lasso markieren, diesen Prompt ins Generative-Fuellen-Feld."
                 : "Firefly-Web: neues Bild aus Text, Bestandsfoto als Bildreferenz anhaengen.")
        }
    }

    private func promptSektion(_ prompt: String) -> some View {
        Section {
            Text(prompt)
                .font(.callout)
                .textSelection(.enabled)
            Button {
                UIPasteboard.general.string = prompt
            } label: {
                Label("Prompt kopieren", systemImage: "doc.on.doc")
            }
            ShareLink(item: prompt) {
                Label("Prompt + Fotos teilen (an Firefly)", systemImage: "square.and.arrow.up")
            }
            if let bestandsfoto {
                ShareLink(item: feldFotoStore.bildURL(fuer: bestandsfoto)) {
                    Label("Nur Bestandsfoto teilen", systemImage: "photo")
                }
            }
        } header: {
            Text("Fertiger Render-Prompt (Englisch fuer beste Ergebnisse)")
        } footer: {
            Text("In die Firefly-Web-App oder -iPhone-App einfuegen: Bestandsfoto als Bild, diesen Text als Prompt. Sobald ein Adobe-API-Schluessel hinterlegt ist, wird daraus ein Knopf.")
        }
    }

    private func fotoKachel(url: URL, gewaehlt: Bool) -> some View {
        Group {
            if let daten = try? Data(contentsOf: url), let bild = UIImage(data: daten) {
                Image(uiImage: bild).resizable().scaledToFill()
            } else {
                Image(systemName: "photo").foregroundStyle(MykColor.muted)
            }
        }
        .frame(width: 90, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .strokeBorder(gewaehlt ? MykColor.brand : MykColor.line, lineWidth: gewaehlt ? 2.5 : 1))
    }

    private func bauen() {
        guard let projekt else { return }
        fehler = nil
        let brief = KreativBrief(
            projectNumber: projekt.projectNumber,
            projectTitel: projekt.title,
            bestandsfotoDateiname: bestandsfoto?.dateiname,
            referenzName: referenz?.name,
            referenzFotoDateiname: referenz?.dateiname,
            stil: stil,
            materialFarbe: materialFarbe,
            elemente: elemente,
            zusatz: zusatz
        )
        letzterBrief = brief
        renderErgebnis = nil
        renderGespeichert = false
        renderFehler = nil
        fertigerPrompt = modus == .photoshop
            ? FireflyPromptKomponist.komponiereGenerativeFill(brief)
            : FireflyPromptKomponist.komponiere(brief)
        try? briefStore.sichern(brief)
    }

    private func rendern() async {
        guard let brief = letzterBrief else { return }
        rendertGerade = true
        renderFehler = nil
        renderGespeichert = false
        defer { rendertGerade = false }
        // Text-zu-Bild braucht den ganzen-Bild-Prompt, unabhaengig vom
        // Kopier-Umschalter oben.
        let prompt = FireflyPromptKomponist.komponiere(brief)
        do {
            renderErgebnis = try await FireflyServicesClient().rendere(prompt: prompt)
        } catch {
            renderFehler = Fehlertext.deutsch(error)
        }
    }

    private func ergebnisSpeichern(_ bild: UIImage) {
        guard let projekt else { return }
        do {
            try feldFotoStore.aufnehmen(
                bild: bild,
                projectNumber: projekt.projectNumber,
                projectTitel: projekt.title,
                kanonZiel: .bestand,
                aufgenommenAm: Date(),
                breitengrad: nil,
                laengengrad: nil)
            renderGespeichert = true
        } catch {
            renderFehler = Fehlertext.deutsch(error)
        }
    }
}

/// Verwaltung der Referenzkuechen-Galerie: gebaute Kuechen fotografieren,
/// benennen, mit Stil taggen. Die Stil-DNA des Studios.
struct ReferenzGalerieView: View {
    let galerie: ReferenzkuechenStore

    @State private var zeigeKamera = false
    @State private var neuesBild: UIImage?
    @State private var name = ""
    @State private var stil = ""
    @State private var notiz = ""
    @State private var fehler: String?

    var body: some View {
        Form {
            Section {
                Button {
                    zeigeKamera = true
                } label: {
                    Label("Gebaute Kueche fotografieren", systemImage: "camera.fill")
                }
                if let neuesBild {
                    Image(uiImage: neuesBild).resizable().scaledToFit().frame(maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    TextField("Name (z. B. Kueche Doehle 2025)", text: $name)
                    Picker("Stil", selection: $stil) {
                        Text("- keiner -").tag("")
                        ForEach(FireflyPromptKomponist.stile, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Notiz (optional)", text: $notiz)
                    Button("In Galerie aufnehmen") { aufnehmen() }
                        .buttonStyle(.borderedProminent).tint(MykColor.brand)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if let fehler { Text(fehler).font(.caption).foregroundStyle(MykColor.crit) }
            } header: {
                Text("Neue Referenz")
            }

            if !galerie.kuechen.isEmpty {
                Section {
                    ForEach(galerie.kuechen) { kueche in
                        HStack(spacing: 10) {
                            if let daten = try? Data(contentsOf: galerie.bildURL(fuer: kueche)), let bild = UIImage(data: daten) {
                                Image(uiImage: bild).resizable().scaledToFill()
                                    .frame(width: 54, height: 54).clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(kueche.name).font(.subheadline.weight(.semibold))
                                if !kueche.stil.isEmpty {
                                    Text(kueche.stil).font(.caption).foregroundStyle(MykColor.brand)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for i in indexSet { try? galerie.entfernen(galerie.kuechen[i].id) }
                    }
                } header: {
                    Text("Galerie (\(galerie.kuechen.count))")
                }
            }
        }
        .navigationTitle("Referenz-Galerie")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $zeigeKamera) {
            KameraAufnahmeView(
                onAufnahme: { bild, _ in neuesBild = bild; zeigeKamera = false },
                onAbbruch: { zeigeKamera = false }
            )
            .ignoresSafeArea()
        }
    }

    private func aufnehmen() {
        guard let neuesBild else { return }
        fehler = nil
        do {
            try galerie.aufnehmen(
                bild: neuesBild,
                name: name.trimmingCharacters(in: .whitespaces),
                stil: stil,
                notiz: notiz.trimmingCharacters(in: .whitespaces))
            self.neuesBild = nil
            name = ""; stil = ""; notiz = ""
        } catch {
            fehler = Fehlertext.deutsch(error)
        }
    }
}

#Preview {
    NavigationStack {
        KreativStudioView(store: ProjectStore(), feldFotoStore: FeldFotoStore())
    }
}
