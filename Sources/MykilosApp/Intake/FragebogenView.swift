import SwiftUI
import MykilosDesign
import MykilosServices
import MykilosKit

// MARK: - FragebogenView
// Geführte Maske: Schritt-für-Schritt-Wizard für den Küchen-Projekt-Fragebogen.
// Öffnet als Sheet. Abschnitte via Tab-Leiste navigierbar.
// Zwischenspeichern (lokal, in-memory — kein GRDB). Schreiben gated via AppState.
@MainActor
struct FragebogenView: View {
    @Environment(AppState.self) private var appState
    @Bindable private var modell: FragebogenModel
    let onDismiss: () -> Void

    // Schritt-Navigation
    @State private var schritt: FragebogenSchritt = .kontakt
    // Bestätigungsphase
    @State private var zeigeBestaetigung: Bool = false
    @State private var ergebnis: IntakeErgebnis? = nil
    @State private var schreibPhase: SchreibPhase = .idle
    // Anlege-Stufe (Johannes, 2026-07-01): am letzten Dialog gewählt, NICHT vorbelegt
    // mit der vollen Stufe — bewusste Entscheidung statt versehentlicher Volltreffer.
    @State private var triggerStufe: FragebogenTriggerStufe = .kontakt
    // Erinnerungsfunktion (Johannes, 2026-07-01): "Ausgefüllte Daten bei Fensterwechsel oder
    // temporärem Schließen noch bereithalten" + expliziter "Verwerfen"-Button. Das `modell`
    // selbst wird vom Aufrufer (KatalogeView) NICHT mehr bei jedem Schließen zurückgesetzt —
    // nur ein bewusstes "Verwerfen" hier oder ein erfolgreiches "Jetzt anlegen" leert es.
    @State private var zeigeVerwerfenBestaetigung: Bool = false
    // Härtung (2026-07-01, Audit): `schreibPhase` allein reicht NICHT, um "nach einem
    // erfolgreichen Anlegen beim Schließen zurücksetzen" zu entscheiden — ein Stufenwechsel
    // NACH einem Erfolg setzt schreibPhase zurück auf .idle (siehe schrittLeiste-Picker unten),
    // wodurch der alte, auf schreibPhase gestützte Check beim Schließen silently nicht mehr
    // feuerte, obwohl in dieser Sitzung bereits echt etwas angelegt wurde. Dieses Flag merkt
    // sich den Erfolg unabhängig von schreibPhase, für die gesamte Dialog-Lebensdauer.
    @State private var hatErfolgreichAngelegt: Bool = false

    init(modell: FragebogenModel = FragebogenModel(), onDismiss: @escaping () -> Void) {
        self.modell = modell
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(MykColor.line.color)
            schrittLeiste
            Divider().overlay(MykColor.line.color)
            Group {
                if zeigeBestaetigung, let ergebnis {
                    bestaetigungsView(ergebnis: ergebnis)
                } else {
                    scrollContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider().overlay(MykColor.line.color)
            fusszeile
        }
        .frame(width: 720, height: 700)
        .background(MykColor.paper.color)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: MykSpace.s4) {
            ZStack {
                RoundedRectangle(cornerRadius: MykRadius.sm)
                    .fill(MykColor.brand.color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.mykBody)
                    .foregroundStyle(MykColor.brand.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Neues Projekt — Fragebogen")
                    .font(.mykHeadline)
                    .foregroundStyle(MykColor.ink.color)
                Text("Schritt \(schritt.index + 1) von \(FragebogenSchritt.allCases.count) · \(schritt.title)")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.muted.color)
            }
            Spacer()
            // Erinnerungsfunktion (Johannes, 2026-07-01): expliziter "Verwerfen"-Button, getrennt
            // vom einfachen Schließen (X) — Schließen bewahrt die Eingaben jetzt auf, nur
            // "Verwerfen" löscht sie endgültig.
            Button {
                if modell.hatNennenswerteEingaben {
                    zeigeVerwerfenBestaetigung = true
                } else {
                    verwerfen()
                }
            } label: {
                Text("Verwerfen")
                    .font(.mykSmall)
                    .foregroundStyle(schreibPhase == .speichert ? MykColor.faint.color.opacity(0.4) : MykColor.critical.color)
            }
            .buttonStyle(.plain)
            .disabled(schreibPhase == .speichert)
            .confirmationDialog(
                "Eingaben wirklich verwerfen?",
                isPresented: $zeigeVerwerfenBestaetigung,
                titleVisibility: .visible
            ) {
                Button("Verwerfen", role: .destructive) { verwerfen() }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Alle Eingaben in diesem Fragebogen gehen dabei verloren.")
            }
            Button {
                // Härtung (2026-07-01, Johannes: Erinnerungsfunktion): nach ERFOLGREICHER
                // Anlage wird das Modell geleert — ein Wiederöffnen soll nicht versehentlich
                // dieselben, schon angelegten Daten nochmal anbieten. Bei jedem anderen
                // Zustand (mittendrin, Fehler, noch nicht versucht) bleibt alles erhalten.
                // Härtung (2026-07-01, Audit): `hatErfolgreichAngelegt` statt `schreibPhase`
                // geprüft — ein Stufenwechsel nach dem Erfolg hätte sonst schreibPhase schon
                // wieder auf .idle gesetzt und diesen Reset silently übersprungen.
                if hatErfolgreichAngelegt {
                    modell.reset()
                    schritt = .kontakt
                    zeigeBestaetigung = false
                    ergebnis = nil
                    schreibPhase = .idle
                    triggerStufe = .kontakt
                    hatErfolgreichAngelegt = false
                }
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.mykBody)
                    .foregroundStyle(schreibPhase == .speichert ? MykColor.faint.color.opacity(0.4) : MykColor.faint.color)
            }
            .buttonStyle(.plain)
            // Härtung (2026-07-01, Audit): während ein Anlegen-Schreibvorgang läuft, würde
            // Schließen die Airtable-/Drive-Schreibvorgänge unsichtbar im Hintergrund weiterlaufen
            // lassen — ohne Rückmeldung UND ohne Möglichkeit, sie wirklich abzubrechen.
            .disabled(schreibPhase == .speichert)
        }
        .padding(.horizontal, MykSpace.s7)
        .padding(.vertical, MykSpace.s5)
        .background(MykColor.card.color)
    }

    private func verwerfen() {
        modell.reset()
        schritt = .kontakt
        zeigeBestaetigung = false
        ergebnis = nil
        schreibPhase = .idle
        triggerStufe = .kontakt
        hatErfolgreichAngelegt = false
        onDismiss()
    }

    // MARK: Schritt-Leiste

    private var schrittLeiste: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MykSpace.s2) {
                ForEach(FragebogenSchritt.allCases) { s in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { schritt = s }
                    } label: {
                        HStack(spacing: MykSpace.s2) {
                            // Fortschritts-Dot
                            Circle()
                                .fill(s == schritt ? MykColor.brand.color : MykColor.faint.color)
                                .frame(width: 6, height: 6)
                            Text(s.title)
                                .font(.mykMono(9.5))
                                .foregroundStyle(s == schritt ? MykColor.ink.color : MykColor.muted.color)
                        }
                        .padding(.horizontal, MykSpace.s3)
                        .padding(.vertical, MykSpace.s2)
                        .background(s == schritt ? MykColor.brand.color.opacity(0.10) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                    }
                    .buttonStyle(.plain)
                    // Review-Fix (low): während der Bestätigungsansicht zeigt der Body immer
                    // bestaetigungsView, unabhängig von `schritt` — ohne diese Sperre konnte ein
                    // Klick hier Kopfzeile/Tab-Highlight sichtbar umschalten, während der Inhalt
                    // eingefroren auf der Bestätigung blieb (widersprüchlicher UI-Zustand).
                    .disabled(zeigeBestaetigung)
                }
            }
            .padding(.horizontal, MykSpace.s7)
        }
        .frame(height: 36)
        .background(MykColor.paper2.color)
        .opacity(zeigeBestaetigung ? 0.4 : 1)
    }

    // MARK: Scroll-Inhalt (Schritt-Dispatch)

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MykSpace.s6) {
                switch schritt {
                case .kontakt:    kontaktSektion
                case .projekt:    projektSektion
                case .raum:       raumSektion
                case .einbau:     einbauSektion
                case .stil:       stilSektion
                case .geraete:    geraeteSektion
                case .ausstattung: ausstattungSektion
                case .zeitplanung: zeitplanungSektion
                case .sonstiges:  sonstigesSektion
                }
            }
            .padding(MykSpace.s7)
        }
    }

    // MARK: - Schritt 1: Kontakt

    private var kontaktSektion: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            sektionHeader(icon: "person.fill", titel: "Kundenkontakt", farbe: .people)

            HStack(spacing: MykSpace.s4) {
                IntakeTextFeld(label: "Vorname", icon: "person", text: $modell.kundeVorname)
                IntakeTextFeld(label: "Nachname *", icon: "person", text: $modell.kundeNachname)
            }
            IntakeTextFeld(label: "Firma", icon: "building.2", text: $modell.kundeFirma)
            IntakeTextFeld(label: "E-Mail", icon: "envelope", text: $modell.kundeEmail)
            IntakeTextFeld(label: "Telefon", icon: "phone", text: $modell.kundeTelefon)

            sektionHeader(icon: "map", titel: "Rechnungsadresse (optional)", farbe: .muted)
            HStack(spacing: MykSpace.s4) {
                IntakeTextFeld(label: "Straße + Nr.", icon: "mappin", text: $modell.kundeStrasse)
                HStack(spacing: MykSpace.s3) {
                    IntakeTextFeld(label: "PLZ", icon: nil, text: $modell.kundePLZ).frame(width: 100)
                    IntakeTextFeld(label: "Ort", icon: nil, text: $modell.kundeOrt)
                }
            }

            sektionHeader(icon: "questionmark.circle", titel: "Wie auf uns aufmerksam?", farbe: .muted)
            ChipMultiPicker(
                options: Kundenquelle.allCases,
                selection: $modell.quelle,
                label: \.rawValue,
                farbe: .people
            )
            IntakeTextArea(label: "Weitere Anmerkung zur Quelle", text: $modell.quelleFreitext)
        }
    }

    // MARK: - Schritt 2: Projekt

    private var projektSektion: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            sektionHeader(icon: "folder.fill", titel: "Projekt-Grunddaten", farbe: .brand)

            IntakeTextFeld(label: "Projektname *", icon: "pencil", text: $modell.projektName)
                .help("Wird als Projektname in Airtable angelegt")

            HStack(spacing: MykSpace.s4) {
                VStack(alignment: .leading, spacing: MykSpace.s2) {
                    Text("Projektstatus")
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.muted.color)
                    Picker("Status", selection: $modell.projektStatus) {
                        ForEach(["Lead", "Beratung", "Planung", "Angebot", "Auftrag", "Archiv"], id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.mykBody)
                }
                VStack(alignment: .leading, spacing: MykSpace.s2) {
                    Text("Budget (netto €, optional)")
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.muted.color)
                    TextField("z. B. 25000", text: $modell.budgetText)
                        .font(.mykBody)
                        .textFieldStyle(.plain)
                        .onChange(of: modell.budgetText) { _, v in
                            modell.budget = FragebogenModel.parseGermanBudget(v)
                        }
                        .padding(MykSpace.s3)
                        .background(MykColor.card.color)
                        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                        .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(
                            budgetParseFehlgeschlagen ? MykColor.critical.color : MykColor.line.color,
                            lineWidth: budgetParseFehlgeschlagen ? 1.5 : 1))
                    // Härtung (2026-07-01, Audit): parseGermanBudget kann bei mehrdeutigem/
                    // fehlerhaftem Format (z. B. mehreren Punkten ohne Komma) `nil` liefern —
                    // bisher verschwand das Budget dann UNSICHTBAR aus dem Airtable-Write. Jetzt
                    // sichtbarer Hinweis, statt stillschweigend nichts zu schreiben.
                    if budgetParseFehlgeschlagen {
                        Text("Format nicht erkannt — z. B. 25000 oder 25.000,50")
                            .font(.mykMono(9))
                            .foregroundStyle(MykColor.critical.color)
                    }
                }
            }

            sektionHeader(icon: "location.fill", titel: "Baustellen-Adresse", farbe: .muted)
            Text("(falls abweichend von Rechnungsadresse)")
                .font(.mykMono(9))
                .foregroundStyle(MykColor.faint.color)
            HStack(spacing: MykSpace.s4) {
                IntakeTextFeld(label: "Straße + Nr.", icon: "mappin", text: $modell.projektStrasse)
                HStack(spacing: MykSpace.s3) {
                    IntakeTextFeld(label: "PLZ", icon: nil, text: $modell.projektPLZ).frame(width: 100)
                    IntakeTextFeld(label: "Ort", icon: nil, text: $modell.projektOrt)
                }
            }
        }
    }

    // MARK: - Schritt 3: Raum

    private var raumSektion: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            sektionHeader(icon: "square.grid.2x2", titel: "Raumgröße & Form", farbe: .tasks)

            HStack(spacing: MykSpace.s4) {
                IntakeTextFeld(label: "Breite (m)", icon: "arrow.left.and.right", text: $modell.raumBreite)
                IntakeTextFeld(label: "Tiefe (m)", icon: "arrow.up.and.down", text: $modell.raumTiefe)
                IntakeTextFeld(label: "Höhe (m, optional)", icon: "arrow.up", text: $modell.raumHoeheText)
            }

            sektionHeader(icon: "rectangle.grid.1x2", titel: "Raumform", farbe: .muted)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: MykSpace.s2) {
                ForEach(Raumform.allCases) { form in
                    Button {
                        modell.raumform = form
                    } label: {
                        Text(form.rawValue)
                            .font(.mykSmall)
                            .foregroundStyle(modell.raumform == form ? MykColor.paper.color : MykColor.ink.color)
                            .padding(.horizontal, MykSpace.s4)
                            .padding(.vertical, MykSpace.s3)
                            .frame(maxWidth: .infinity)
                            .background(modell.raumform == form ? MykColor.tasks.color : MykColor.card.color)
                            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                            .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            IntakeTextArea(label: "Freitext: Besonderheiten zur Raumform", text: $modell.raumformFreitext)
        }
    }

    // MARK: - Schritt 4: Einbau & Stil

    private var einbauSektion: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            sektionHeader(icon: "hammer.fill", titel: "Einbausituation", farbe: .drive)
            ChipMultiPicker(options: Einbausituation.allCases, selection: $modell.einbausituation, label: \.rawValue, farbe: .drive)
            IntakeTextArea(label: "Freitext", text: $modell.einbausituationFreitext)

            sektionHeader(icon: "paintbrush.fill", titel: "Anschlüsse & Bauzustand", farbe: .drive)
            ChipMultiPicker(options: Anschluss.allCases, selection: $modell.anschluesse, label: \.rawValue, farbe: .tasks)
            IntakeTextArea(label: "Freitext", text: $modell.anschluessFreitext)

            sektionHeader(icon: "trash", titel: "Bestandsküche", farbe: .muted)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: MykSpace.s2) {
                ForEach(BestandsKueche.allCases) { opt in
                    pickButton(opt.rawValue, active: modell.bestandskueche == opt) {
                        modell.bestandskueche = opt
                    }
                }
            }
            IntakeTextArea(label: "Freitext", text: $modell.bestandsFreitext)
        }
    }

    private var stilSektion: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            sektionHeader(icon: "sparkles", titel: "Küchen-Stil", farbe: .personal)
            ChipMultiPicker(options: Kueche_Stil.allCases, selection: $modell.stil, label: \.rawValue, farbe: .personal)
            IntakeTextArea(label: "Freitext Stil-Wunsch", text: $modell.stilFreitext)

            sektionHeader(icon: "hand.tap", titel: "Griffkonzept", farbe: .personal)
            ChipMultiPicker(options: Griffkonzept.allCases, selection: $modell.griffkonzept, label: \.rawValue, farbe: .personal)
            IntakeTextArea(label: "Freitext", text: $modell.griffkonzeptFreitext)

            sektionHeader(icon: "square.fill", titel: "Fronten / Oberfläche", farbe: .drive)
            ChipMultiPicker(options: FrontenMaterial.allCases, selection: $modell.frontenMaterial, label: \.rawValue, farbe: .drive)
            IntakeTextArea(label: "Freitext", text: $modell.frontenFreitext)

            sektionHeader(icon: "table.furniture", titel: "Arbeitsplatten", farbe: .drive)
            ChipMultiPicker(options: ArbeitsplattenMaterial.allCases, selection: $modell.arbeitsplattenMaterial, label: \.rawValue, farbe: .drive)
            IntakeTextArea(label: "Freitext", text: $modell.arbeitsplattenFreitext)
        }
    }

    // MARK: - Schritt 5: Geräte

    private var geraeteSektion: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            sektionHeader(icon: "flame.fill", titel: "Kochfeld", farbe: .critical)
            ChipMultiPicker(options: KochfeldTyp.allCases, selection: $modell.kochfeldTyp, label: \.rawValue, farbe: .critical)
            IntakeTextArea(label: "Freitext / Wunschmodell", text: $modell.kochfeldFreitext)

            sektionHeader(icon: "wind", titel: "Dunstabzug", farbe: .tasks)
            ChipMultiPicker(options: DunstabzugTyp.allCases, selection: $modell.dunstabzugTyp, label: \.rawValue, farbe: .tasks)
            IntakeTextArea(label: "Freitext", text: $modell.dunstabzugFreitext)

            sektionHeader(icon: "oven.fill", titel: "Backofen & Einbaugeräte", farbe: .tasks)
            ChipMultiPicker(options: BackofenTyp.allCases, selection: $modell.backofenTyp, label: \.rawValue, farbe: .tasks)
            IntakeTextArea(label: "Freitext / Wunschmodell", text: $modell.backofenFreitext)

            sektionHeader(icon: "drop.fill", titel: "Spüle & Armatur", farbe: .cash)
            ChipMultiPicker(options: SpuelTyp.allCases, selection: $modell.spuelTyp, label: \.rawValue, farbe: .cash)
            IntakeTextArea(label: "Freitext", text: $modell.spuelFreitext)

            sektionHeader(icon: "snowflake", titel: "Kühlgeräte", farbe: .cash)
            ChipMultiPicker(options: Kuehlgeraet.allCases, selection: $modell.kuehlgeraete, label: \.rawValue, farbe: .cash)
            IntakeTextArea(label: "Freitext", text: $modell.kuehlgeraeteFreitext)

            sektionHeader(icon: "sparkles", titel: "Haushaltsgeräte (Weiße Ware)", farbe: .people)
            ChipMultiPicker(options: Haushaltgeraet.allCases, selection: $modell.haushaltsgerate, label: \.rawValue, farbe: .people)
            IntakeTextArea(label: "Freitext", text: $modell.haushaltsgeraeteFreitext)

            sektionHeader(icon: "wifi", titel: "Technik-Wünsche", farbe: .personal)
            ChipMultiPicker(options: TechnikWunsch.allCases, selection: $modell.technikWuensche, label: \.rawValue, farbe: .personal)
            IntakeTextArea(label: "Freitext", text: $modell.technikFreitext)
        }
    }

    // MARK: - Schritt 6: Ausstattung (Beleuchtung, Schubladen, Inneneinteilung)

    private var ausstattungSektion: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            sektionHeader(icon: "lightbulb.fill", titel: "Beleuchtung", farbe: .tasks)
            ChipMultiPicker(options: Beleuchtung.allCases, selection: $modell.beleuchtung, label: \.rawValue, farbe: .tasks)
            IntakeTextArea(label: "Freitext", text: $modell.beleuchtungFreitext)

            sektionHeader(icon: "square.3.layers.3d", titel: "Schubladen & Auszüge", farbe: .people)
            ChipMultiPicker(options: SchubladenTyp.allCases, selection: $modell.schubladen, label: \.rawValue, farbe: .people)
            IntakeTextArea(label: "Freitext", text: $modell.schubladenFreitext)

            sektionHeader(icon: "tray.2.fill", titel: "Inneneinteilung / Ordnung", farbe: .personal)
            ChipMultiPicker(options: Inneneinteilung.allCases, selection: $modell.inneneinteilung, label: \.rawValue, farbe: .personal)
            IntakeTextArea(label: "Freitext", text: $modell.inneneinteilungFreitext)

            sektionHeader(icon: "cabinet.fill", titel: "Hängeschränke", farbe: .drive)
            ChipMultiPicker(options: Haengeschraenk.allCases, selection: $modell.haengeschraenke, label: \.rawValue, farbe: .drive)
            IntakeTextArea(label: "Freitext", text: $modell.haengeschraenkeFreitext)
        }
    }

    // MARK: - Schritt 7: Zeitplanung & Budget-Kategorie

    private var zeitplanungSektion: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            sektionHeader(icon: "calendar", titel: "Planungsphase", farbe: .people)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: MykSpace.s2) {
                ForEach(Planungsphase.allCases) { p in
                    pickButton(p.rawValue, active: modell.planungsphase == p) { modell.planungsphase = p }
                }
            }
            IntakeTextFeld(label: "Wunschtermin (optional)", icon: "calendar", text: $modell.wunschtermin)
            IntakeTextArea(label: "Freitext Zeitplanung", text: $modell.planungsFreitext)

            sektionHeader(icon: "eurosign.circle", titel: "Budget-Kategorie", farbe: .cash)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: MykSpace.s2) {
                ForEach(BudgetKategorie.allCases) { b in
                    pickButton(b.rawValue, active: modell.budgetKategorie == b) { modell.budgetKategorie = b }
                }
            }
            IntakeTextArea(label: "Freitext Budget-Anmerkung", text: $modell.budgetKategorieFreitext)

            sektionHeader(icon: "person.2.fill", titel: "Entscheidungsstruktur", farbe: .muted)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: MykSpace.s2) {
                ForEach(EntscheidungsTraeger.allCases) { e in
                    pickButton(e.rawValue, active: modell.entscheidungstraeger == e) { modell.entscheidungstraeger = e }
                }
            }
            IntakeTextArea(label: "Freitext", text: $modell.entscheidungFreitext)
        }
    }

    // MARK: - Schritt 8: Sonstiges & Nächster Schritt

    private var sonstigesSektion: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            sektionHeader(icon: "text.bubble.fill", titel: "Sonderwünsche & Notizen", farbe: .personal)
            IntakeTextArea(label: "Alle weiteren Wünsche, Anmerkungen …", text: $modell.sonderwuensche, minHeight: 100)

            sektionHeader(icon: "arrow.forward.circle.fill", titel: "Nächster Schritt", farbe: .brand)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: MykSpace.s2) {
                ForEach(NaechsterSchritt.allCases) { s in
                    pickButton(s.rawValue, active: modell.naechsterSchritt == s) { modell.naechsterSchritt = s }
                }
            }
            IntakeTextArea(label: "Freitext Nächster Schritt", text: $modell.naechsterSchrittFreitext)
        }
    }

    // MARK: - Bestätigungs-View (gated)

    @ViewBuilder
    private func bestaetigungsView(ergebnis: IntakeErgebnis) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                // Anlege-Stufe (Johannes, 2026-07-01): erst hier, am letzten Schritt, gewählt.
                VStack(alignment: .leading, spacing: MykSpace.s3) {
                    Text("ANLEGE-STUFE")
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.muted.color)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: MykSpace.s2) {
                        ForEach(FragebogenTriggerStufe.allCases) { stufe in
                            pickButton(stufe.rawValue, active: triggerStufe == stufe) {
                                // Härtung (2026-07-01, Audit): nur bei ECHTEM Stufenwechsel
                                // zurücksetzen — ein Re-Klick auf die bereits aktive (und ggf.
                                // bereits erfolgreich gespeicherte) Stufe darf `schreibPhase`
                                // NICHT auf .idle zurückwerfen, sonst reaktiviert das "Jetzt
                                // anlegen" für eine exakte Doppel-Anlage (zweiter Google-Kontakt/
                                // zweite Projektnummer/zweiter Drive-Ordner ohne jeden Grund).
                                guard stufe != triggerStufe else { return }
                                triggerStufe = stufe
                                // Fix (Live-Test, 2026-07-01): ein Fehler/Erfolg einer vorherigen
                                // Stufe blieb sonst sichtbar stehen, obwohl noch gar kein Versuch
                                // für die NEU gewählte Stufe unternommen wurde — wirkte wie ein
                                // Fehlschlag aller Stufen, obwohl nur eine wirklich versucht wurde.
                                schreibPhase = .idle
                            }
                        }
                    }
                    // Härtung (2026-07-01, Audit): während eines laufenden Schreibvorgangs darf
                    // die Stufe nicht wechselbar sein — sonst reaktiviert der obige Reset
                    // "Jetzt anlegen" mitten im laufenden, noch nicht abgeschlossenen Schreiben
                    // und ein zweiter Klick spawnt einen zweiten, konkurrierenden Schreib-Task.
                    .disabled(schreibPhase == .speichert)
                    if let hinweis = stufeFehlenderHinweis(ergebnis: ergebnis) {
                        HStack(spacing: MykSpace.s2) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.mykMono(9)).foregroundStyle(MykColor.critical.color)
                            Text(hinweis).font(.mykMono(9)).foregroundStyle(MykColor.critical.color)
                        }
                    }
                }
                .padding(MykSpace.s5)
                .background(MykColor.card.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
                .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1))

                // Bestätigungs-Karte — Inhalt passt sich der gewählten Stufe an.
                VStack(alignment: .leading, spacing: MykSpace.s3) {
                    HStack(spacing: MykSpace.s3) {
                        Image(systemName: "checkmark.seal")
                            .font(.mykHeadline)
                            .foregroundStyle(MykColor.positive.color)
                        Text("Bestätigung erforderlich")
                            .font(.mykHeadline)
                            .foregroundStyle(MykColor.ink.color)
                    }
                    Text("Folgende Datensätze werden NEU angelegt:")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.muted.color)

                    Divider().overlay(MykColor.line.color)

                    // Kunde — immer.
                    bestaetigunsZeile(icon: "person.fill", farbe: .people,
                                      titel: triggerStufe == .kontakt ? "Neuer Kontakt" : "Neuer Kunde",
                                      inhalt: modell.vollstaendigerKundeName + (modell.kundeFirma.isEmpty ? "" : " · \(modell.kundeFirma)"))
                    if triggerStufe == .kontakt {
                        bestaetigunsZeile(icon: "person.crop.circle.badge.plus", farbe: .people,
                                          titel: "Google-Kontakt",
                                          inhalt: "wird zusätzlich in Google Kontakte angelegt")
                    }

                    // Projekt + Ordner + Warenkorb — nur ab Stufe „Lead".
                    if triggerStufe != .kontakt {
                        bestaetigunsZeile(icon: "folder.fill", farbe: .brand,
                                          titel: "Neues Projekt",
                                          inhalt: modell.projektName + " · Status: \(modell.projektStatus)")
                        bestaetigunsZeile(
                            icon: triggerStufe == .lead ? "folder.badge.questionmark" : "folder.fill.badge.gearshape",
                            farbe: .drive,
                            titel: triggerStufe == .lead ? "Rumpf-Ordner (Drive)" : "Voller Projekt-Ordner (Drive)",
                            inhalt: triggerStufe == .lead
                                ? "nur Wurzelordner in PROJEKTE/_LEADS/"
                                : "kompletter Ordnerbaum in PROJEKTE/")
                        if !ergebnis.warenkorb.items.isEmpty {
                            bestaetigunsZeile(icon: "cart.fill", farbe: .tasks,
                                              titel: "Erst-Warenkorb",
                                              inhalt: "\(ergebnis.warenkorb.items.count) Positionen")
                            VStack(alignment: .leading, spacing: MykSpace.s2) {
                                ForEach(ergebnis.warenkorb.items.prefix(5)) { item in
                                    HStack(spacing: MykSpace.s3) {
                                        Text("·").foregroundStyle(MykColor.faint.color)
                                        Text("\(item.menge)× \(item.bezeichnung)")
                                            .font(.mykSmall)
                                            .foregroundStyle(MykColor.inkSoft.color)
                                    }
                                }
                                if ergebnis.warenkorb.items.count > 5 {
                                    Text("… und \(ergebnis.warenkorb.items.count - 5) weitere")
                                        .font(.mykMono(9))
                                        .foregroundStyle(MykColor.faint.color)
                                }
                            }
                            .padding(.leading, MykSpace.s7)
                        }
                    }

                    Divider().overlay(MykColor.line.color)

                    // Warnung / Hinweis
                    HStack(spacing: MykSpace.s3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.mykCaption)
                            .foregroundStyle(MykColor.tasks.color)
                        Text("Append-only: Kein Löschen, kein Überschreiben. Nur neue Records anlegen.")
                            .font(.mykMono(9))
                            .foregroundStyle(MykColor.tasks.color)
                    }
                }
                .padding(MykSpace.s6)
                .background(MykColor.card.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
                .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.positive.color.opacity(0.3), lineWidth: 1))

                // Status
                switch schreibPhase {
                case .idle: EmptyView()
                case .speichert:
                    HStack(spacing: MykSpace.s3) {
                        ProgressView().scaleEffect(0.7)
                        Text("Wird in Airtable angelegt …").font(.mykSmall).foregroundStyle(MykColor.muted.color)
                    }
                case .gespeichert(let summary):
                    HStack(spacing: MykSpace.s3) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(MykColor.positive.color)
                        Text(summary).font(.mykSmall).foregroundStyle(MykColor.positive.color)
                    }
                case .fehler(let msg):
                    HStack(spacing: MykSpace.s3) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(MykColor.critical.color)
                        Text("Fehler: \(msg)").font(.mykSmall).foregroundStyle(MykColor.critical.color)
                    }
                }
            }
            .padding(MykSpace.s7)
        }
    }

    private func bestaetigunsZeile(icon: String, farbe: MykColor, titel: String, inhalt: String) -> some View {
        HStack(alignment: .top, spacing: MykSpace.s4) {
            Image(systemName: icon)
                .font(.mykCaption)
                .foregroundStyle(farbe.color)
                .frame(width: MykSpace.s6, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(titel).font(.mykMono(9)).foregroundStyle(MykColor.faint.color)
                Text(inhalt).font(.mykBody).foregroundStyle(MykColor.ink.color)
            }
        }
    }

    // MARK: - Fußzeile (Navigation + Aktionen)

    private var fusszeile: some View {
        HStack(spacing: MykSpace.s4) {
            // Zurück
            if schritt.index > 0 && !zeigeBestaetigung {
                Button {
                    withAnimation { schritt = FragebogenSchritt.allCases[schritt.index - 1] }
                } label: {
                    Label("Zurück", systemImage: "chevron.left")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.muted.color)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Bestätigung abbrechen
            if zeigeBestaetigung {
                Button("Abbrechen") {
                    zeigeBestaetigung = false
                    ergebnis = nil
                    schreibPhase = .idle
                }
                .font(.mykSmall)
                .buttonStyle(.plain)
                .foregroundStyle(MykColor.muted.color)
                // Härtung (2026-07-01, Audit): "Abbrechen" hat noch nie den laufenden
                // Schreib-Task abgebrochen (nur lokalen UI-State zurückgesetzt) — die echten
                // Airtable-/Drive-Schreibvorgänge liefen bisher unsichtbar im Hintergrund weiter.
                // Da eine echte Task-Abbruchmöglichkeit eine größere Änderung an AppState
                // bräuchte (kooperative Cancellation über die ganze Schreibkette), wird
                // stattdessen verhindert, dass der Nutzer während .speichert überhaupt auf
                // "Abbrechen" klicken kann — kein täuschender Abbruch, der keiner ist.
                .disabled(schreibPhase == .speichert)
            }

            // Weiter / Jetzt anlegen
            if zeigeBestaetigung {
                // Bestätigt → Anlegen. Review-Fix (Johannes, 2026-07-01): "es MUSS ein
                // Minimum an Eingabedaten vorausgesetzt sein" — der Button bleibt gesperrt,
                // solange die GEWÄHLTE Anlege-Stufe ihr eigenes Minimum nicht erfüllt.
                let schreibPhaseBereit = schreibPhase == .idle || {
                    if case .fehler = schreibPhase { return true }
                    return false
                }()
                let kannAnlegen = schreibPhaseBereit && (ergebnis.map { stufeBereit(ergebnis: $0) } ?? false)
                Button {
                    guard let e = ergebnis else { return }
                    // Härtung (2026-07-01, Audit): synchron VOR dem Task-Start gesetzt, nicht
                    // erst als erste Zeile im async Task-Body. `Task { }` startet nicht inline
                    // mit dem Klick, sondern erst auf einem späteren MainActor-Turn — bis dahin
                    // blieb `schreibPhase` sichtbar `.idle` und `kannAnlegen` damit `true`, was
                    // ein zweiter, sehr schneller Klick (Doppelklick oder programmatisch) als
                    // zweiten, konkurrierenden Schreib-Task ausnutzen konnte (TOCTOU).
                    schreibPhase = .speichert
                    // Härtung (2026-07-01, Audit): auf AppState gespiegelt, damit KatalogeView
                    // die Sheet-Ebene selbst gegen Escape-Dismiss sperren kann — `schreibPhase`
                    // ist reines FragebogenView-@State und für den Aufrufer nicht sichtbar.
                    appState.fragebogenSchreibtGerade = true
                    Task { await anlegenBestaetigt(ergebnis: e) }
                } label: {
                    HStack(spacing: MykSpace.s2) {
                        if case .speichert = schreibPhase { ProgressView().scaleEffect(0.6) }
                        else { Image(systemName: "checkmark") }
                        Text("Jetzt anlegen")
                    }
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.paper.color)
                    .padding(.horizontal, MykSpace.s5)
                    .padding(.vertical, MykSpace.s3)
                    .background(
                        RoundedRectangle(cornerRadius: MykRadius.sm)
                            .fill(kannAnlegen ? MykColor.positive.color : MykColor.muted.color.opacity(0.4))
                    )
                }
                .buttonStyle(.plain)
                .disabled(!kannAnlegen)
            } else if schritt.index < FragebogenSchritt.allCases.count - 1 {
                // Weiter
                Button {
                    withAnimation { schritt = FragebogenSchritt.allCases[schritt.index + 1] }
                } label: {
                    Label("Weiter", systemImage: "chevron.right")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.brand.color)
                }
                .buttonStyle(.plain)
            } else {
                // Letzter Schritt → Vorschau
                Button {
                    vorschauAktivieren()
                } label: {
                    HStack(spacing: MykSpace.s2) {
                        Image(systemName: "eye")
                        Text("Vorschau & Anlegen")
                    }
                    .font(.mykSmall)
                    .foregroundStyle(modell.istAusgefuelltGenug ? MykColor.paper.color : MykColor.faint.color)
                    .padding(.horizontal, MykSpace.s5)
                    .padding(.vertical, MykSpace.s3)
                    .background(
                        RoundedRectangle(cornerRadius: MykRadius.sm)
                            .fill(modell.istAusgefuelltGenug ? MykColor.brand.color : MykColor.card.color)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MykRadius.sm)
                            .stroke(modell.istAusgefuelltGenug ? Color.clear : MykColor.line.color, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!modell.istAusgefuelltGenug)
            }
        }
        .padding(.horizontal, MykSpace.s7)
        .padding(.vertical, MykSpace.s4)
        .background(MykColor.card.color)
    }

    // MARK: - Aktionen

    private func vorschauAktivieren() {
        ergebnis = IntakeResultBuilder.build(from: modell)
        zeigeBestaetigung = true
        schreibPhase = .idle
    }

    private func anlegenBestaetigt(ergebnis: IntakeErgebnis) async {
        // schreibPhase = .speichert wird jetzt synchron im Button-Klick gesetzt (siehe fusszeile),
        // nicht mehr hier — das schließt das TOCTOU-Doppelklick-Fenster (siehe Kommentar dort).
        do {
            let outcome = try await appState.erzeugeAusFragebogen(ergebnis: ergebnis, modell: modell, stufe: triggerStufe)
            schreibPhase = .gespeichert(outcome.summary)
            hatErfolgreichAngelegt = true
        } catch {
            schreibPhase = .fehler(error.localizedDescription)
        }
        appState.fragebogenSchreibtGerade = false
    }

    // Härtung (2026-07-01, Audit): true, wenn Text eingegeben wurde, der parseGermanBudget
    // aber nicht in eine Zahl umwandeln konnte — sonst verschwindet das Budget unsichtbar.
    private var budgetParseFehlgeschlagen: Bool {
        !modell.budgetText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && modell.budget == nil
    }

    // MARK: - Anlege-Stufe-Readiness (Johannes, 2026-07-01: Minimum an Eingabedaten je Stufe)

    private func stufeBereit(ergebnis: IntakeErgebnis) -> Bool {
        switch triggerStufe {
        case .kontakt:
            let email = ergebnis.kundeFelder["Kontakt 1 Email"]?.isEmpty == false
            let telefon = ergebnis.kundeFelder["Kontakt 1 Telefon"]?.isEmpty == false
            return email || telefon
        case .lead:
            return ergebnis.projektFelder["Projektname"]?.isEmpty == false
        case .projektMitOrdner:
            return ergebnis.projektFelder["Projektname"]?.isEmpty == false
                && IntakeAdresse.strNummerBildbar(ergebnis: ergebnis)
        }
    }

    private func stufeFehlenderHinweis(ergebnis: IntakeErgebnis) -> String? {
        guard stufeBereit(ergebnis: ergebnis) == false else { return nil }
        switch triggerStufe {
        case .kontakt:
            return "Für „Nur Kontakt speichern“ wird E-Mail ODER Telefon benötigt."
        case .lead:
            return "Für „Als Lead anlegen“ wird ein Projektname benötigt."
        case .projektMitOrdner:
            return "Für „Projekt mit Ordner“ werden Projektname UND eine Straße oder ein Ort (Projekt- oder Kundenadresse) benötigt."
        }
    }

    // MARK: - Hilfsbausteine

    private func sektionHeader(icon: String, titel: String, farbe: MykColor) -> some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: icon)
                .font(.mykCaption)
                .foregroundStyle(farbe.color)
            Text(titel)
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
        }
    }

    private func pickButton(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.mykSmall)
                .foregroundStyle(active ? MykColor.paper.color : MykColor.ink.color)
                .padding(.horizontal, MykSpace.s4)
                .padding(.vertical, MykSpace.s3)
                .frame(maxWidth: .infinity)
                .background(active ? MykColor.brand.color : MykColor.card.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FragebogenSchritt
enum FragebogenSchritt: String, CaseIterable, Identifiable {
    case kontakt   = "Kontakt"
    case projekt   = "Projekt"
    case raum      = "Raum"
    case einbau    = "Einbau & Stil"
    case stil      = "Oberflächen"
    case geraete   = "Geräte"
    case ausstattung = "Ausstattung"
    case zeitplanung = "Zeitplanung"
    case sonstiges = "Sonstiges"

    var id: String { rawValue }
    var title: String { rawValue }
    var index: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}

// MARK: - SchreibPhase
private enum SchreibPhase: Equatable {
    case idle
    case speichert
    case gespeichert(String)
    case fehler(String)
}

// MARK: - IntakeTextFeld
private struct IntakeTextFeld: View {
    let label: String
    let icon: String?
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            if let icon {
                HStack(spacing: MykSpace.s2) {
                    Image(systemName: icon)
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.faint.color)
                    Text(label)
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.faint.color)
                }
            } else {
                Text(label)
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.faint.color)
            }
            TextField(label, text: $text)
                .font(.mykBody)
                .textFieldStyle(.plain)
                .foregroundStyle(MykColor.ink.color)
                .padding(MykSpace.s3)
                .background(MykColor.card.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
        }
    }
}

// MARK: - IntakeTextArea
private struct IntakeTextArea: View {
    let label: String
    @Binding var text: String
    var minHeight: CGFloat = 54

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s2) {
            Text(label)
                .font(.mykMono(9))
                .foregroundStyle(MykColor.faint.color)
            TextEditor(text: $text)
                .font(.mykBody)
                .foregroundStyle(MykColor.ink.color)
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight)
                .padding(MykSpace.s3)
                .background(MykColor.card.color)
                .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(MykColor.line.color, lineWidth: 1))
        }
    }
}

// MARK: - ChipMultiPicker
// Chip-Reihe für Mehrfachauswahl (Set<T: Hashable>).
private struct ChipMultiPicker<T: CaseIterable & Hashable & Sendable>: View where T.AllCases: RandomAccessCollection {
    let options: T.AllCases
    @Binding var selection: Set<T>
    let label: (T) -> String
    let farbe: MykColor

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MykSpace.s2) {
                ForEach(Array(options.enumerated()), id: \.offset) { _, opt in
                    let aktiv = selection.contains(opt)
                    Button {
                        if aktiv { selection.remove(opt) }
                        else     { selection.insert(opt) }
                    } label: {
                        Text(label(opt))
                            .font(.mykMono(9.5))
                            .foregroundStyle(aktiv ? MykColor.paper.color : MykColor.muted.color)
                            .padding(.horizontal, MykSpace.s3)
                            .padding(.vertical, MykSpace.s2)
                            .background(aktiv ? farbe.color : MykColor.card.color)
                            .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                            .overlay(RoundedRectangle(cornerRadius: MykRadius.sm).stroke(aktiv ? farbe.color.opacity(0.5) : MykColor.line.color, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
