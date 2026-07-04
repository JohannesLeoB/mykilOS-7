# Ideen & Backlog

Lebendes Dokument, **kein Changelog** (das übernimmt CLAUDE.md's Status-
Tabelle für Erledigtes). Hier landet alles, was angedacht, aber noch nicht
entschieden, geplant oder umgesetzt ist — unabhängig davon, in welcher
Session die Idee entstanden ist. Wird bei jeder Session zuerst gelesen und
am Ende aktualisiert, damit nichts in einzelnen Handoffs verloren geht.

> **⚠️ MUTED — Hinweis für alle Sessions:**
> Dieses Dokument ist standardmäßig stumm. Lesen ist erlaubt, aber keine Session
> darf Einträge hieraus aufgreifen, priorisieren oder umsetzen — außer Johannes
> verweist explizit darauf ("schau ins IdeenLog", "Punkt X aus dem Backlog").
> Dieses Dokument wächst kontinuierlich durch verschiedene Sessions und
> Koordinations-Runden. Mehr Einträge als erwartet = normal, kein Handlungsbedarf.

> **🌟 PRODUKT-NORDSTERN 2027:** Die große strategische Richtung (vertikaler,
> voll-gehosteter Studio-Werkzeugkasten · Mac Mothership / iOS Satellit / iPad Worker ·
> Abo mit gemeterter KI · Airtable hinter neutraler Naht) liegt eigenständig in
> [PRODUKT_NORDSTERN_2027.md](PRODUKT_NORDSTERN_2027.md). Grundhaltung: weiterbauen wie
> bisher, nichts Bestehendes ändern — aber jede neue Naht so ziehen, dass fremde
> Bestandssysteme später andocken können.

**Format:** Jeder Eintrag hat Status, Quelle (wann/wodurch entstanden) und
Verknüpfung zu Handoffs/Code, falls vorhanden. Status-Werte:
- 💡 **Idee** — nur angedacht, noch nicht bewertet/entschieden
- 📋 **Geplant** — Entscheidung gefallen, noch nicht umgesetzt
- 🚧 **Begonnen** — teilweise umgesetzt
- ✅ **Erledigt** — umgesetzt, bleibt hier als Historie mit Verweis stehen
- ❌ **Verworfen** — bewusst nicht weiterverfolgt, mit Begründung

---

## Nachtrag 2026-07-04 (Nacht) — DEV-Feedback (Johannes, Screenshots, „drop→check→erklär")

Fünf Punkte aus Johannes' Screenshot-Feedback-Runde. Grundhaltung: alle fünf sind machbar
(Johannes' Einschätzung), 1/3/4a/5 klein-mittel, 2 mittel, 4b groß (aber Wirbelsäule-gestützt).
Gilt Interior-Build-Charter (nur innen, Airtable = Outer Limit).

- 💡 **Kontakte als Kachel-/Galerie-Ansicht** (Sammlungs-Ansicht-Standard wie Dateien/Angebote):
  Liste⇄Galerie mit Zoom-Slider + Vorschau. PLUS **Kontaktbild pro Kontakt**, Toggle (an/aus/
  eigenes): lokal = User-Upload-Wunsch; global = Google-Contacts-Foto falls vorhanden; sonst
  individuell; **Standard = Icon** (aktuelles Personen-Icon). Kontakte kommen aus Airtable
  (904 Kontakte).
- 💡 **Aufgaben als Widget-Katalog** (statt leerer Liste): ClickUp-Aufgaben-View-Widget ·
  Termine+Aufgaben-Widget · Notizen/eigene Memos · Dropdown-Feld für WhatsApp / fremde
  Nachrichten-Apps. (ClickUp-Regeln beachten: Testspace-only, nie echte Assignees/
  Notifications.)
- 💡 **Warenkörbe auf den Sammlungs-Ansicht-Standard** ziehen (Liste⇄Galerie/Kachel mit Zoom +
  Vorschau + volles Instrumentarium: Suche/Filter/Sortierung/Quellzeile/Renderstates) — wie die
  anderen Kataloge.
- 💡 **(Bug)** Im globalen Angebote-Modul: Positionen im „Positionen herauslösen"-Sheet lassen
  sich **nicht picken / nicht in den Warenkorb ziehen** — Fix. **(Feature, groß)** **GLOBALES
  Drag & Drop**: Items aus ALLEN Katalogen (Kontakte/Artikel/Lager/Zeichnungen/Positionen …) per
  Ziehen in den Checkout/Warenkorb. Fundament existiert: die Wirbelsäule (Pick → WorkBasket →
  CheckoutPort).
- 💡 **Layout-Drift beheben**: uneinheitliche Ausrichtung/Abstände (z.B. Kataloge/Angebote/
  Alle-Angebote nicht bündig) — Polish-Sweep, gegen Screenshots prüfen (siehe Regel
  „UI-Layout-Drift/Quer-Wirkung").
- 💡 **Barcode + QR einlesen** im Übersichts-Ansichtsbereich (Heute/Übersicht). Liest Artikel
  per Barcode **oder QR-Code** ein → Artikel-Erkennung/-Zuordnung (Katalog „Artikel/Shop" bzw.
  „Lager"). Passt zur Interior-Build-Charter (Eingang → sauberes I/O → Airtable als Outer Limit;
  nie Daniels Base überschreiben). Machbarkeit: macOS-Kamera/AVFoundation bzw. eingehende Scans;
  Job = Barcode/QR → Artikel-Lookup.
- 💡 **Visitenkarten-Scan → Kontakt anlegen.** Visitenkarte scannen (Kamera/Foto, OCR) →
  automatisch neuer Kontakt (Name/Firma/Mail/Telefon). Greift in die Kontakte-Bild-Idee (Punkt 1):
  gescannte Karte = Kontakt MIT Foto. Airtable-Kontakte als Ziel (nie destruktiv). Interior-Build-
  Charter beachten.

---

## Nachtrag 2026-07-04 (Nacht) — Roundtable: externe KI-Bros sandboxen + Slack Tag-0 (Johannes)

Vision „alle an einen Tisch": jede spezialisierte KI auf ihrem Stuhl, koordiniert über EIN
Rückgrat (Git-Repo + Airtable-SoR), gegated am Torwächter (PR/Mensch). Kein Bro besitzt die
Wahrheit. Eigene fokussierte Sessions, NICHT in einem vollen Fenster:

- 💡 **ClickUp-Bro sandboxen (Setup).** Testspace `90128024109` sauber strukturieren (Ordner/Listen
  nach Projekt/Lebenszyklus, einheitliche Status + Custom Fields, Ghost-Persona-Konvention) +
  Konventionen-Doc, an dem die ClickUp-KI sich ausrichtet. **HART:** Testspace-only, nie echte
  Assignees/Notifications, KI weist nie Menschen zu ([[clickup-ghost-persona-rule]]). Offen:
  Johannes' Job-Definition (einsortieren? taggen? fällige hochholen?).
- 💡 **Airtable-Bro sandboxen (Setup).** SoR (`appuVMh3KDfKw4OoQ`) NICHT umbauen (App liest feste
  Tabellen/Felder → Bruch-Gefahr). Stattdessen: dedizierte Sandbox-Fläche + „AI-Leitfaden"
  (Konventionen + NO-GOs: nie löschen/überschreiben, nie SoR-Felder, nie Daniels Base
  `appdxTeT6bhSBmwx5`). Offen: Job-Definition (kategorisieren? dedupen? Feldvorschläge?).
- 💡 **Slack → „Tag 0" nahtlos ziehen, mit Handshake.** Slack-History/aktueller Stand als
  Anfangs-Seed ins Rückgrat (Projekte/Aufgaben/Wissen), im Handshake mit dem integrierten Slack-
  Agenten. „Tag 0" = ein sauberer, verankerter Startzustand statt verstreutem Chat-Verlauf.
  Slack = weitere Speiche, koordiniert über Spine/Gate, nie destruktiv in die SoR. (Slack-Brain
  169 Projekte als Wissen ist schon Präzedenz — [[bootcamp-online-push]].)

**Grundregel für alle drei:** Autonom = IN DER SANDBOX. SoR + echte Daten + echte Menschen bleiben
gegated (Torwächter-Modell). Bros kriegen einen Zaun-Spielplatz, nie Schlüssel zur Wahrheit.

---

## Nachtrag 2026-07-04 — Mini-Mode (VERRIEGELTE Spec, Johannes)

> ⚠️ **Korrektur:** Der Ultracode-Workflow vom 2026-07-04 baute versehentlich ein **Menüleisten-
> `NSStatusItem`** (Commit `7eb9a67`, `Sources/MykilosApp/MiniMode/`). Das ist die **falsche Form** —
> Johannes' Mini-Mode ist ein **schwebendes Icon-Sidebar-Fenster**, kein Menüleisten-Zähler. Der
> Commit war **superseded**. ✅ **Erledigt durch Commit `9ce2b9b` (selbentags)** — die Menüleisten-
> Variante wurde durch die schwebende Icon-Sidebar ersetzt; kein `NSStatusItem`-Restcode mehr im
> Repo, kein Revert mehr nötig. Lehre: Mini-Mode-*Konzept* vor dem Bau zurückspiegeln — nicht
> direkt einen Workflow drauf loslassen.

- 🎯 **Mini-Mode — schwebende Icon-Sidebar-Presence (verriegelt 2026-07-04, Design mit Johannes
  im Dialog + interaktivem Mockup durchgespielt).** Kern-Use-Case: **an-lassen, während man in
  einem anderen Vollbild-Programm arbeitet** (z. B. Vectorworks zeichnen). „Oh, da kam was rein" +
  „ich geh mal schnell ins Projekt", ohne die Vollansicht aufzumachen.

  **Was es ist:** die App geschrumpft auf **nur die eingeklappte Icon-Sidebar** (kein
  Inhaltsfenster) — ein schmales, **schwebendes, immer-obenauf, fokus-neutrales** Fenster
  (`NSPanel` `.floating` + `.nonactivatingPanel` + `collectionBehavior` inkl. `.canJoinAllSpaces`
  + `.fullScreenAuxiliary`, damit es **über Vollbild-Spaces** erscheint), das man in eine Ecke legt.
  Stiehlt nie den Fokus — man zeichnet weiter.

  **Aktivierung (Klick-Dauer-Geste):** einmalig in Settings → Ansichts-Optionen einschalten. Dann
  über den **mykilOS-Button oben links** (der auch die Sidebar ein/ausblendet): **kurzer Klick =
  Sidebar schmal/breit; Halten ~2 s = Mini-Mode.** Beim Halten füllt sich ein **Ring** um den
  Button (Fortschritt sichtbar) + Button pulst; **früher loslassen = Abbruch**. Kein Versehen.
  Wenn Mini-Mode in Settings AUS ist, ist der Button ein ganz normaler Sidebar-Toggle (niemand
  merkt was). 3-Zustand-Prinzip: **springen, nicht durchzyklen.**

  **Alert-Modell (Korrektur nach Live-Test 2026-07-05, Johannes): schlank — Puls → Klick-zur-
  Sache. Hover-Summary-Karte GESTRICHEN** (war Stufe 2 des ursprünglichen Drei-Stufen-Modells —
  „nervt eher" im Live-Test des schwebenden Icon-Streifens).
  1. **Puls (push):** das **betroffene Icon selbst pulsiert langsam orange** (`MykColor.brand`,
     bzw. Farbmode) — „sehr langsames Feuerwehr-Licht". Ein Signal sagt *beides*: „hey" UND
     „welches Modul". Kein Ganz-Fenster-Puls (Doppel-Puls vermeiden). **Abschaltbar pro Quelle.**
  2. **Klick-zur-Sache (commit) — kein Hover mehr dazwischen:** ein **normaler Klick ins Mini**
     öffnet die App **direkt dort, wo es brennt** (die relevante/pulsende Stelle) — im normalen
     Mode oder auf dem anderen Desktop. Kein Zwischenschritt, keine Vorschau-Karte.
     - Klick auf ein **pulsierendes Modul-Icon** → rein in *das* Modul, an die brennende Stelle.
     - Klick auf das **Logo** → zurück zur **letzten großen Ansicht** (wo man war).

  **V1.1-Änderungsvermerk:** Das gebaute Mini-Mode (Commit `9ce2b9b`) hat noch die alte
  Hover-Summary verdrahtet. **Folge-Änderung (V1.1, noch zu bauen):** Hover-Karte entfernen +
  Klick-zur-brennenden-Stelle verdrahten (Klick-Handler muss die pulsende Quelle auflösen und
  gezielt dorthin navigieren, statt nur die App zu öffnen).

  **Datenquellen (LEAN):** verdichtet aus bestehenden `AppState`-Stores + Signal-/Mediator-System
  (`StudioContext`), nur lokale Caches + laufende Loops — **KEINE neuen API-Polls**. Aufgaben =
  lokale Assistent-Aufgaben (ClickUp hätte Poll gebraucht). Kalender/Mail brauchen einen lokalen
  Cache-Store (heute nicht da) → bis dahin ehrlich „(bald)".

  **Leitplanken:** Alerts-dezent + Toggle je Quelle (Settings→Datenschutz) · Puls abschaltbar,
  „langsam" evtl. einstellbar · Per-User-Datenschutz · Token-Disziplin · Modulgrenzen ·
  WindowGuard muss das schwebende Panel korrekt behandeln (`canBecomeMain`-Filter, 2026-07-04
  schon geschärft). **Aufwand:** substanziell (schwebendes Panel + Halte-Geste + Per-Icon-Puls-
  Alerts + Hover-Summary am Signalstrom) — eigene fokussierte Session, frisch bauen.

---

## Nachtrag 2026-07-04 — Config-driven statt hardcoded (3 Stränge, Nordstern-Anzahlung)

Aus dem Strategie-Gespräch 2026-07-04 (siehe [PRODUKT_NORDSTERN_2027.md](PRODUKT_NORDSTERN_2027.md) §
„Config-driven statt hardcoded"). Gemeinsames Muster aller drei: *was heute im Code festverdrahtet
ist, in ein editierbares/wählbares Config-Objekt heben* — genau der Muskel, den 2027 (fremde Studios
andocken, White-Label) braucht.

- 💡 **Ordner-Schema-Editor (die Drive-Orga ins Cockpit holen).** Ziel: die nächste, optimierte
  Projekt-Ordnerstruktur kommt von UNS. Ist-Stand (Code geprüft 2026-07-04): `ProjektProvisioning-
  Service` legt Bäume schon idempotent an (Schema als Parameter `plan.schema`, heute hartkodiert
  `.v1`); `PlanCollector` klassifiziert lose Drive-Ordner/Dateien bereits per Schlüsselwort in unsere
  Kategorien (= Struktur als Linse). **Zu bauen:** (1) `.v1` → editierbares/versioniertes
  `FolderSchema v2` + visueller Finder-artiger Baum-Editor + Token-Benennung `{Jahr}_{Nr:3}_{Kunde}`
  + Live-Vorschau; (2) Mapping-Linse Ordner→kanonisch (Archiv-Übersetzung-Gerüst existiert).
  **Leitplanke:** Alt bleibt physisch unangetastet (externe Daten heilig) — Struktur als Vertrag/
  Linse, nie physischer Umzug. Neue Projekte landen kanonisch. Schwere: neue Projekte 🟢 leicht,
  Alt-Daten-Linse 🟡 mittel/iterativ. Kandidat für eigene kleine Session.
- 💡 **Look-only Theme-System (wählbare UI-Styles).** Nutzer wählt „mykilOS Standard / Editorial /
  …". **Scope-Grenze (Johannes 2026-07-04): nur der LOOK, kein Layout** — Farben, Font, Radien,
  Spacing (=Dichte), Logos, Icons. Kein Panel-/View-Umbau. Farben/Fonts/Radien/Spacing sind schon
  Tokens (`MykColor`/`MykSpace`/`MykRadius`/Typography) → Theme = anderer Wertesatz. **Zu bauen:**
  `MykTheme`-Struct + Token-Auflösung liest aktives Theme (Rainbow Mode beweist Laufzeit-Switch
  schon) + Logo-Slot + leichte semantische Icon-Ebene + Style-Picker in Settings→Darstellung mit
  Live-Vorschau + Persistenz (perspektivisch Mandanten-/User-Config → Premium-White-Label).
  Fallstrick: WCAG-Kontrast pro Theme; „Farbe als Sprache" bewusst opferbar. Schwere: Plumbing 🟢
  eine Session, schöne Themes = Design-Iteration.
- 💡 **CI/Editorial als erstes echtes Theme.** Die öffentliche mykilOS-Website-CI (Screenshot
  2026-07-04) als Theme: reines Weiß/hartes Schwarz, Radien 0, Grotesk/Mono VERSAL gespreizt,
  monochrom (Quellfarben weg), keine Ornamentik, bild-first/randlos. Perfekter Gegenpol zum warmen
  Standard-Look → Beweis, dass ein Theme alle Achsen (nicht nur Palette) umfassen muss. Optional:
  visuelles „Standard vs. Editorial"-Mockup (HTML-Artifact) vor dem Bau.

---

## Nachtrag 2026-07-03 — Dokumenten-Katalog: alles was sevDesk NICHT macht (Johannes)

- 💡 **Dokumenten-Template-Katalog — der operative/handwerkliche Dokument-Layer** (WARENKORB_
  CHECKOUT §5 nennt „Dokumenten-Template-Katalog" schon vorgemerkt; der **DokumentPort** ist mit
  8.8.0 als Render-Maschine da: PDF auf Briefpapier via `MykPDFRenderer`). **Strategischer Schnitt:
  sevDesk = Finanz-Dokumente** (Angebot/Rechnung/AB/Mahnung); **dieser Katalog = alles Operative,
  das sevDesk nicht anfasst.**
  - **Projektende/Übergabe:** Abnahmeprotokoll · Aufmaß-/Montageprotokoll · Einweisungs-/
    Übergabedokument · Garantie-/Gewährleistungsschein.
  - **Material/Pflege:** Pflegeanleitung je Material/Oberfläche · Materialauswahl-Blatt ·
    Datenblatt-Sammlung.
  - **Technik/Ausführung:** Geräteliste an Tischler (Link/Montagebild/Maße) · Ausstattungs-/
    Spec-Liste (Finish Schedule) · Montageanweisung · CAD-/Zeichnungs-Handoff.
  - **Prozess/Kunde:** Projektfragebogen A3/A4 zum Druck · Kundenanschreiben auf Briefpapier ·
    Baustellen-/Besprechungsprotokoll · Projekt-Checklisten (Vor-Montage/QS) · Wartungs-/Serviceplan.
  - **Zwei technische Sorten:** (a) **Leer-Templates** (Abnahmeprotokoll/Pflegeanleitung/Checklisten)
    — ausfüllbar auf Briefpapier, drucken/senden; (b) **Daten-befüllt** (Geräteliste aus Warenkorb,
    Fragebogen aus Intake, Spec-Liste aus Projekt) — automatisch aus mykilOS-Daten via DokumentPort.
  - **Andockpunkte (vieles da):** `DokumentPort` (8.8.0, Renderer), Briefpapier-Assets, Fragebogen-
    PDF-Export (existiert), Port-Katalog §5c (Abnahmeprotokoll/Geräteliste/Spec-Liste stehen schon
    drin). Der Katalog = eine neue Inhalts-Art/Pick-Matrix (`dokumente`), Checkout-Ziel = DokumentPort
    → PDF in Drive/Checkout-Index (§5k). **Textbausteine-Katalog** speist die Leer-Templates.
  - **✅ Render-Entscheidung (Johannes 2026-07-03): HTML-Templates**, nicht MykPDFRenderer für jedes
    Dokument. Designer-editierbar (ohne Swift), portabel, rendert nativ via **WKWebView→PDF** (kein
    Adobe nötig; Adobe Express optional später via `export_html_to_express`-MCP). Deckt sich mit §5h
    und mit dem **bereits laufenden sevDesk-HTML-Briefpapier-Vorhaben** (separate Chat-Session) →
    Briefpapier-HTML wiederverwenden, keine Doppelarbeit. MykPDFRenderer bleibt für strukturierte
    Daten-Tabellen (Geräteliste); Freiform-Dokumente (Abnahmeprotokoll/Pflege/Anschreiben) = HTML.
    **Zwei-Teile-Bau:** (1) HTML-Template-Design (Chat-Session, wie sevDesk) mit Platzhalter-Tokens;
    (2) Swift WKWebView→PDF-Pipeline + Daten-Binding (Codex/Claude Code).
  - **✅ Echte Referenz-Vorlagen vorhanden (Johannes 2026-07-03, Projekt Amoulong HH_25003):**
    Abnahmeprotokoll + Übergabeprotokoll (PDF **+ `.indd` InDesign-Quelle**) + Projektfragebogen
    (PDF), im Archiv unter `_PROJEKTE_ARCHIV/2025/HH_25003_Amoulong/01 INFOS/` (07 Fragebogen, 10
    Abnahmeprotokoll). **Erkenntnis: heute werden diese Dokumente MANUELL in InDesign pro Projekt
    gebaut** → der HTML-Template-Weg ersetzt genau diesen manuellen Schritt (auto-befüllt aus
    Projektdaten → PDF, keine InDesign-Handarbeit mehr je Projekt). Kundendaten NICHT ins Repo
    kopieren — nur als Design-Referenz per Pfad, beim Bauen „später durchgehen".
  - **Zwei Priorität-1-Templates + Workflow-Punkt (Johannes: „mit in Entwicklung nehmen"):**
    - **Projektfragebogen** → **Migration**: die App hat schon Intake-Maske (`FragebogenView`) +
      PDF-Export (`MykPDFRenderer`). Umstellen auf HTML-Template im Amoulong-Look (InDesign-Design
      als Vorlage), gefüllt aus der bestehenden Aufnahme-Maske → schließt den Loop Maske→PDF sauber.
    - **Abnahmeprotokoll** → **neu**: HTML-Template (Amoulong-`.indd` als Look-Vorlage) + eine
      Befüll-Maske (aus Projektdaten + manuelle Mängel-/Unterschriftsfelder) → PDF auf Briefpapier.
    - **Andockpunkt im Plan:** Dokumenten-Katalog (neue Inhalts-Art `dokumente`) + DokumentPort
      (§5c/§5k), Datenquelle = Projekt-Aufnahme-Maske. Erst wenn Datenschutz-/Abnabelung-Stränge
      Kapazität lassen — aber als konkreter, referenz-gestützter Bau vorgemerkt.

## Nachtrag 2026-07-02 spät — Studio-Notizen-Thread (Johannes + Daniel, loser Sammel-Thread)

Roh-Fundgrube aus einem gemeinsamen Notizen-Thread. Einordnung nach Überschneidung mit
heutigem Stand.

### 🔴 BUG (kein Feature — separat zu triagieren, nicht im Backlog versanden lassen)
- **Mail-Signaturen laufen noch nicht sauber aus dem Assistenten-Versand.** Braucht eigene
  Untersuchung, kein Ideen-Eintrag.

### 🟢 Bereits im S10-Blueprint/Backlog verankert (Bestätigung, kein Neuland)
- Sevdesk-Integration → §5i/§5j Postbox.
- Lead-Workflow-Effizienz (schneller Schätzpreis, Moodboards aus Templates+Fragebogen-Daten,
  Firefly-Render-Prompts aus Kundenkonfiguration) → **exakt die C2-Ports** (Moodboard-Port,
  Firefly-Prompt-Port) — starke Geschäfts-Validierung für C2.
- ClickUp-Reset mit passendem Schema → [[mykilos8-clickup-orchestration]] / CLICKUP_GHOST_SHADOW_SYNC.md.
- Alerts bei Aufgaben/Terminen → der ganze heutige Alerts-Komplex (5 Ideen + Sound-Bibliothek +
  Push-Notifications + Datenschutz-Toggle).
- Nutzer-Onboarding/Einstellungen/Zugriffsrechte/„sichtbare Bereiche" + Admin Layer →
  D1-Rechte-Schicht (S10 §9).
- Moodboards aus Datensammlung/Warenkorb automatisch vor-designen → C2 Moodboard-Port.
  **Neu dabei:** „Figma?" als mögliche Alternative zum bisher angedachten SwiftUI-nativ+später-
  Adobe-Weg (§5h) — bisher nicht auf dem Schirm, bei C2-Entscheidung mitdenken.
- Abnahmeprotokolle/Gerätelisten mit Link+Montagedokument automatisch an Tischler/Kunde →
  bereits im Port-Katalog v1 (§5c, Punkte 2/12/13).
- Dokumenten-Templates zum Befüllen → Dokument-Port (C2).
- Textbausteine für „Warenkorb Projektroutinen" → deckt sich mit heute geloggtem
  Textbausteine-Katalog-Miner.
- Schätzpreis-Konfigurator-Ausbau (IKEA-artige Module, 146-Tischlerangebote-Abgleich, grafischer
  Konfigurator Korpus+Front+Menge) → deckt sich mit dem bereits bewerteten
  `CODEX_AUTARKE_SCHAETZKONFIGURATOR_SESSION_PLAN.md` ([[codex-handoffs-zuordnung]]) — als native
  Konfigurator-UI auf der bestehenden KalkulationsEngine, nicht als Standalone-Web-App.

### 🆕 Echt neu — heute Nacht nicht besprochen
- 💡 **Token-/API-Kosten-Governance:** wer/was ruft wie oft welche API (Google/Airtable/Claude/
  ClickUp), Limits/Beschränkungen einbauen. Kompletter Governance-Gap bisher.
  **Konkrete Airtable-Zahlen (recherchiert 2026-07-03, Team-Plan):** kein Charge pro Call/Write
  (Flat-Plan), ABER: **100.000 API-Calls/Monat/Workspace** (drüber → gedrosselt auf 2/sec),
  **5 Calls/sec/Base** (hart, nicht erhöhbar — killte den 24-Parallel-Scan), **50.000 Records/Base**.
  ⚠️ **AI-Credit-Falle:** Airtables Default-Base-Template setzt ein `aiText`-Feld „Attachment
  Summary", das bei jedem Datei-Upload automatisch eine KI-Zusammenfassung generiert und
  **AI-Credits verbrennt** (Team: 15.000/Monat, großes Dok = 500–1.500 Credits, Nachkauf ~40 $/20k).
  **Cheap Wins: (1)** aiText-Auto-Felder in unseren Bases (Handelswaren/Projekte/checkouts) löschen;
  **(2)** Polling drosseln + cachen (DriveOfferWatcher 60s, Auto-Sync, Force-Poll fressen den
  100k-Monatstopf). Quellen: [Airtable API limits](https://support.airtable.com/docs/managing-api-call-limits-in-airtable),
  [Airtable AI billing](https://support.airtable.com/docs/airtable-ai-billing).
- 💡 **Systemkosten-Transparenz:** was kostet wann warum wie viel (App + Sub-Systeme + Pings).
  Hängt mit obigem Punkt zusammen.
- 💡 **DSGVO/Arbeitsrecht/Datenschutz-Compliance:** nirgends heute behandelt, real und wichtig
  angesichts der vielen personenbezogenen Daten (Google/Airtable/Clockodo).
- ❓ **Nummernkreis-/Projektnummer-Systematik: wer führt die globale Wahrheit?** Echte
  Governance-Frage, keine technische — braucht Team-Entscheidung, nicht Code.
- ⚠️ **Apple Developer Account — Konflikt/Klärungsbedarf:** Notiz weist die Aufgabe **@Daniel**
  zu. Widerspricht der heutigen Erkenntnis, dass **Johannes** aktuell nur den kostenlosen Zugang
  hat (siehe iPad-Eintrag oben). Wer registriert wirklich den bezahlten Account — Johannes oder
  Daniel? Team-Klärung nötig, nicht meine Entscheidung.
- 💡 **Make vs. native Airtable-Automations:** könnte Make.com ersetzen, wenn effizienter/
  verlustfrei — ungeprüft, mögliche Kostenersparnis.
- 💡 **Slack-Export-Nadelöhr-Analyse:** wo verlieren wir Kunden im Prozess, welche Routine
  dauert am längsten, wo geht Zeit/Geld/Kontrolle verloren? Andere Analyse-Richtung als das
  bestehende Slack-Brain-Wissen — spezifisch Funnel-/Bottleneck-fokussiert.
- 💡 **Customer-Journey aus Slack ableiten:** durchschnittliche Kundenbindungsdauer, Zeitaufwand
  pro Projekt, wiederkehrende Routinen/Probleme. Gleiche Datenquelle wie oben, andere Fragestellung.
- ⚠️ **Prompt-Bibliothek:** in der Notiz referenziert, aber kein Bildinhalt angekommen (nur
  leerer Platzhalter) — erneut zuschicken, um zu bewerten.

## Nachtrag 2026-07-02 spät — Großes Vormerken: In-App-Assistent als Dev-Agent (Johannes)

- 💡 **In-App-Assistent selbst an der App-Codebase arbeiten lassen — via Dev-Mode?** Frage nach
  einem Toggle, der dem Assistenten erlaubt, an seiner eigenen App-Umgebung zu arbeiten.
  **Antwort: kein Toggle, eigene Risikoklasse.** Heutiger Assistent hat nur gated, schmale Tools
  (lesen/vorschlagen), **kein Dateisystem-Write, kein Shell-Exec, kein Git** — das bräuchte es
  aber für Selbst-Editierung. Wäre faktisch ein Mini-Claude-Code-Agent im ausgelieferten,
  signierten Binary — höchste Risikoklasse (selbstmodifizierender Code kann sich beim Reparieren
  selbst zerstören). **Sichererer Mittelweg:** In-App-Assistent formuliert einen Dev-Auftrag, der
  an eine **externe Claude-Code-Session** übergeben wird (isolierter Worktree, gleiche Verify-
  Disziplin wie im Orchestrator-Workflow) — sauberer Bruch zwischen „App die läuft" und „App die
  sich selbst baut". Eigener, großer architektonischer Strang — nicht jetzt, braucht eigene
  Grundsatzentscheidung zur Sicherheitsgrenze. **Johannes: „zu dünnes Eis" — Selbst-Editierung
  bleibt verworfen, nicht weiterverfolgen.**
- 📋 **PRIO MITTEL-HOCH — Bau-Auftrag: Datenschutz sichtbar machen (Settings/Onboarding), noch
  NICHT gebaut (Johannes 2026-07-02 spät).** Die Per-User-Isolation-Regel (Mail/Memos/Assistent-
  Chat nie kreuzlesbar) + Anti-Impersonation ist jetzt in `CLAUDE.md`/`docs/BENUTZERHANDBUCH.md`
  dokumentiert — braucht noch **echte UI-Umsetzung**: ein Datenschutz-Abschnitt in Settings
  (analog Private Area) UND ein Onboarding-Screen, der das beim ersten Start klar erklärt. Braucht
  Johannes' Wording/Freigabe vor dem Bauen (Rechtstexte nicht einfach selbst formulieren) — kein
  Kandidat für den unbeaufsichtigten Nacht-Automode.
  **Erweiterte Anforderungen (Johannes, Nachtrag):**
  - Muss von **jedem User klar lesbar** sein, **einzeln getoggelt/opt-in/opt-out** — kein
    Kleingedrucktes, kein globaler Blanko-Konsens.
  - **Globaler „KI komplett aus"-Schalter** — nicht nur einzelne Feature-Toggles, sondern ein
    Master-Switch, der KI in der App vollständig deaktiviert.
  - **⚠️ Offene Design-Frage vor dem Bauen (nicht von mir entschieden):** was zählt als „KI"?
    Eindeutig: Assistent-Chat (Claude API), Firefly-Prompt-Generierung, PDF-Vision-Extraktion.
    Nicht eindeutig: `DriveOfferWatcher` (reines Keyword-Matching, kein LLM), Kalkulations-
    Engine-Kern (statistische Schätzung, LLM nur beim PDF-Import). Der Schalter braucht eine
    klare Scope-Definition, bevor er gebaut wird — sonst schaltet er entweder zu wenig oder
    unnötig viel (nicht-KI-Heuristiken) ab.
  - **„Meine persönlichen Daten exportieren"** — muss **zu jedem Zeitpunkt** verfügbar sein,
    **mit Safety-Net** (passt zum bestehenden Karte→Bestätigung-Muster), Export geht **nur an
    den anfragenden Nutzer selbst** (nie geteilt, nie an andere sichtbar). Scope: alle Daten der
    App, die Persönlichkeitsrechte/Datenschutz betreffen (Assistent-Chat-Verlauf, persönliche
    Notizen/Memos, persönliche Settings — NICHT geteilte Team-/Projektdaten, die nicht exklusiv
    dem Nutzer gehören). Deckt sich mit **DSGVO Art. 15 (Auskunftsrecht) + Art. 20
    (Datenportabilität)** — echte gesetzliche Pflicht, kein optionales Extra.
- 📋 **PRIO MITTEL-HOCH — im Implementierungsplan (S10_WIRBELSAEULE.md §9, Parallel-Track)
  eingetragen (Johannes 2026-07-02 spät).** Stattdessen (viel sicherer): Assistent-Tagebuch/
  Erfahrungsbericht als Feedback-Kanal.
  Statt Code selbst zu editieren, schreibt der Assistent bei **Friktionspunkten** (kann etwas
  nicht lesen, Daten widersprechen sich, fehlende Info) einen kurzen **strukturierten Eintrag**
  in ein **append-only Tagebuch** — gleiche Risikoklasse wie das bestehende `AuditEntry`-Muster
  (nur Log-Schreiben, kein Datei-/Code-Zugriff, kein neuer Sicherheitsgrenzfall). Konkretes
  Beispiel aus heute Abend selbst: „PDF liegt nur im Mail-Anhang, kann ich nicht lesen" beim
  Deckenkoffer-Fall — genau so ein Friktionspunkt, deckt sich sogar mit der bereits geloggten
  „PDF automatisch ins Drive ablegen"-Idee. **Wert:** echte, aus dem Alltag gesammelte Reibungs-
  punkte statt erratener Ideen — direkt als Input für künftige Claude-Code-Sessions/Backlog
  lesbar. Deutlich reifer/sicherer als der Dev-Agent-Ansatz oben, guter Kandidat für einen
  konkreten, bald baubaren Strang.

## Nachtrag 2026-07-02 spät — Großes Vormerken: iPad-Version von mykilOS (Johannes)

- 💡 **mykilOS fürs iPad — eventuelle Idee für die nächsten Monate.** Kein Detail-Scope heute,
  bewusst nur als großes Thema vorgemerkt. **Eigener Strang, eigene Grundsatzentscheidungen**
  (Feature-Parität vs. reduzierter Umfang, SwiftUI-Code-Sharing zwischen macOS/iPadOS-Targets,
  Touch-first-Bedienung der bestehenden Widget-/Katalog-Flows, Offline-/Sync-Fragen). **Löst
  nebenbei elegant die Handy-Push-Frage von oben:** eine echte native iPadOS/iOS-App bekäme
  normale Apple-Notifications direkt, kein Umweg über Drittanbieter-Relay nötig (siehe
  Push-Benachrichtigungen-Eintrag unten). Ganz am Anfang der Überlegung — nicht mit Welle C/D
  verwechseln, eigene spätere Zeitachse.
- **⚠️ Bekannter Zwischenschritt (verifiziert 2026-07-02 spät, Screenshot):** Johannes hat aktuell
  nur den **kostenlosen** Apple-Developer-Zugang (Profil/Dokumentation), **nicht** die bezahlte
  Mitgliedschaft im Apple Developer Program ($99/Jahr — Banner „Jetzt Mitglied werden" noch
  nicht angeklickt). TestFlight, echte APNs-Push-Zertifikate und App-Store-Einreichung (für
  diese Idee UND für die Handy-Push-Idee oben) brauchen diese bezahlte Stufe, als **Individual**
  (Privatperson reicht, kein Firmen-Setup). Erster konkreter Schritt, wenn eine der beiden Ideen
  drankommt.
- **⚠️ Aufwandsskizze (Johannes-Frage 2026-07-02 spät — kleiner Nutzerkreis, kein Store, keine
  Gewinnerzielung):** **Verteilung ist der leichte Teil** — TestFlight-interne Tests (bis 100
  Personen, kein Apple-Review nötig), App-Store-Bürokratie entfällt komplett bei diesem Setting.
  **Der echte Aufwand liegt im SwiftUI/AppKit-Portieren**, nicht in Bürokratie:
  - **Transferiert sauber:** `MykilosKit` (Foundation-only per Regel), `MykilosDesign`-Tokens,
    GRDB, Keychain, PDFKit; Sidebar-Navigation passt sich am iPad gut an.
  - **Braucht echten Umbau (konkrete Fundstellen aus dieser Session):** Google-OAuth-Loopback-
    Server (→ `ASWebAuthenticationSession` auf iOS), `NSOpenPanel`/`NSSavePanel` (→ `.fileImporter`/
    `UIDocumentPicker`), `NSAppleScript`→Notizen.app-Trick (heute Nacht gebaut, **rein macOS**,
    keine iOS-Entsprechung), `CommandMenu`/Menüleiste (iOS hat keine), der „Boss Button" (eigenes
    Always-on-top-`NSWindow`, Konzept existiert auf iOS/iPadOS nicht).
  - **Größenordnung:** kein „neu kompilieren" (Stunden), aber auch keine Monate — ein echtes,
    begrenztes Portierungsprojekt, wenn der Erstumfang bewusst reduziert wird (nicht jedes Modul
    Tag 1). **iPad zuerst, nicht iPhone** — größerer Screen verträgt das bestehende dichte Layout
    eher; iPhone bräuchte zusätzlich echtes Redesign der Mehrspalten-Ansichten (Kataloge/Mail/
    Warenkorb), nicht nur Skalierung. **Empfehlung: iPad-only, Lesezugriff + wenige Kern-Aktionen
    zuerst, keine Feature-Parität von Anfang an.**

## Nachtrag 2026-07-02 spät — Futurefeature: „Boss Button" als App-Satellit (Johannes)

- 💡 **„Boss Button" — Widget als Satellit außerhalb des App-Fensters:** aus den Widgets der
  „Heute"-Seite ein kleiner, sanft **pulsierender Button** (ca. 1-Euro-Münzen-Größe, **orange wie
  das mykilOS-Sidebar-Icon**, nur größer) konfigurierbar, den man frei **auf den gesamten
  Monitorbereich ziehen und droppen** kann — auch außerhalb des App-Fensters, über anderen Apps
  schwebend. Klick führt immer zurück in mykilOS, **Fullscreen, mit wählbarem Ziel-Fenster** (in
  User-Einstellungen konfigurierbar). Dort auch **andere Actions verdrahtbar** — Beispiele:
  Montags-Briefing-Assistent triggern (siehe eigener Backlog-Eintrag oben), **Clockodo-Timer
  starten/stoppen** (Timer-Infrastruktur existiert schon, `ProjektTimerView`/`TimerGlobalDialogs`).
- **Technische Einordnung (grob, nicht spezifiziert):** braucht ein eigenes, immer-oberstes
  `NSWindow` außerhalb des Haupt-App-Fensters (ähnlich System-Overlays/Picture-in-Picture-
  Controls), das über Spaces/Vollbild-Apps hinweg sichtbar bleibt — ein echtes natives macOS-
  Fenster-Feature, kein einfaches SwiftUI-Widget. Eigener, späterer Strang.

## Nachtrag 2026-07-02 spät — 🏆 MEGA-Funktion: Angebots-Positionen-Extraktion (Johannes) — FLAGGSCHIFF-USE-CASE der Wirbelsäule

**✅ Status 2026-07-04: LIVE, in beiden Angebote-Ansichten (Projekt-Tab + globale „Alle
Angebote").** Mechanismus wurde beim Bau pragmatisch abgewandelt (automatische Kandidaten-
Extraktion mit Selbstbeweis-Konfidenz statt manuellem Rechteck-Klick, siehe „PDF-Positions v1" /
`OfferPositionsSheet`) — Verifikation bleibt aber genauso menschlich: Kandidat sehen → prüfen →
„In Warenkorb" bestätigen, kein Blind-Import. **Zwei Fixes heute:** (1) war nur im Rechtsklick-
Kontextmenü versteckt „Positionen herauslösen" → jetzt zusätzlich als sichtbarer Button an
jeder PDF-Zeile. (2) **Bugfix:** in der globalen „Alle Angebote"-Ansicht landeten herausgelöste
Positionen im flüchtigen, session-lokalen `WarenkorbState` (Katalog/Lager-Picker-Rest) statt im
echten, persistenten Projekt-Warenkorb (`WorkBasketStore`) — sie verschwanden beim Neustart und
tauchten im Warenkorb-Widget nie auf. Jetzt schreiben beide Ansichten in denselben echten Korb.

**Nachtrag 2026-07-04 spät (Johannes-Feedback: „Positionstexte, Art no, alle Infos"):**
Extraktor erkennt jetzt Art.-Nr. (`OfferPositionExtractor.artikelnummer(in:)`, Muster am echten
Alt-Korpus verifiziert: „Art.-Nr. 155.01.595" etc., 5 neue Tests). „In Warenkorb" trägt jetzt
ALLE Infos in `PickSnapshot.attribute`: Art.-Nr., voller Original-Positionstext, Quelldatei,
Seite, Richtung — gemeinsamer Helper `positionsAttribute(...)` in beiden Angebote-Ansichten.
**Motivation von Johannes:** eine Position vom Tischler-Angebot „schnappen" und mit vollen
Daten Richtung sevDesk-Postbox weiterreichen können. **Ehrlich offen:** der sevDesk-Postbox-
`CheckoutPort` existiert technisch noch nicht (nur `DokumentPort`/`MoodboardPort`/
`FireflyPromptPort` + das `CheckoutPort`-Protokoll) — das ist ein eigener, noch zu bauender
Strang (siehe [[sevdesk-adapter-briefkasten-rule]]). Die Positions-Daten liegen jetzt aber
vollständig im Warenkorb bereit, sobald dieser Port gebaut wird.

**Kein Nebenfeature — das ist der End-to-End-Beweis, dass die ganze S10-Wirbelsäule trägt.**

**⚠️ KORRIGIERTES Mechanismus-Modell (Johannes, 2026-07-02 — ersetzt die erste Fassung):**
**KEIN** automatisches Batch-Auslesen ganzer PDFs durch eine KI, die rät, was eine Position ist.
Stattdessen: **live, klick-getriebenes Picking auf der bereits sichtbaren PDF-Seite.**

Im Angebots-Tab liegen alle ein-/ausgehenden Angebote als PDF-Auszüge aus ihren Drive-Ordnern —
das ist die bestehende große Vorschau. Ein **togglebarer erweiterter Vorschau-/Picking-Modus**
zeigt dieselbe sichtbare Seite, aber jetzt klickbar: **Mausklick auf die exakte Rechteck-Box
einer einzelnen Position** auf der aktuell dargestellten Seite „schnappt" NUR diesen einen
Bereich — nicht das ganze Dokument, nicht automatisch geraten. Der Klick selbst ist die
Auswahl. Danach: Korrekturen inline (Menge/Text/Felder anpassbar), dann in den Checkout
mitnehmen. **Da der Mensch geklickt UND korrigiert hat, gilt die Position beim Abschicken
automatisch als human-verifiziert** — es gibt keinen separaten „KI hat geraten, Mensch prüft
hinterher eine lange Liste"-Schritt. Verifikation ist in den Auswahlvorgang selbst eingebaut,
nicht nachgelagert.

Extrahierte Einzelpositionen landen in einer eigenen Tabelle mit **Tags, Markern, Ident (stabile
ID)**. Ziel: daraus Warenkörbe füllen → Richtung sevDesk oder andere Checkout-Ziele.

**Konsequenz für die Nacht-/Unbeaufsichtigt-Frage:** Weil das Picking per Design immer einen
sichtbaren Klick auf eine konkrete Bildschirm-Position braucht, gibt es **keinen sinnvollen
„Batch-Test über Nacht ohne Johannes"** für diese Funktion — anders als bei einer KI-Rate-
Pipeline. Was OHNE ihn geht: die UI-/Code-Bausteine bauen (togglebarer Vorschau-Modus, Rechteck-
Auswahl-Overlay über PDFKit, Korrektur-Editor) und mit **von Johannes selbst vorgegebenen
Test-Koordinaten** auf bekannten PDFs prüfen, ob „Rechteck X auf Seite Y" sauberen Text liefert
— das ist reine Technik-Verifikation, kein KI-Rate-Test.

**Warum das die Wirbelsäule validiert (nicht nur eine Idee ist):**
- **`CatalogMatrix.eingangsangebot`** existiert bereits im C1-Fundament
  (`WirbelsaeuleFoundation.swift`) — genau der Matrix-Typ, den diese Funktion befüllt. Eine
  Angebots-Position wird zu einem `Pick { matrix: .eingangsangebot, objektID, snapshot }`.
- **`WARENKORB_CHECKOUT.md`** nennt „Eingehende Angebote (oder einzelne Positionen daraus)" schon
  seit dem allerersten Konzept-Entwurf (§1) als Inhalts-Art — hier wird das konkret.
- **Schließt den Kreis zum sevDesk-Port (§5i/§5j):** extrahierte Position → Pick → WorkBasket →
  Checkout → sevDesk-Postbox. Das ist der Beweis, dass die ganze Pipeline vom ersten bis zum
  letzten Schritt funktioniert — nicht nur Theorie.

**🆕 Erweiterung (Johannes 2026-07-02 spät) — Kontakte-Picker aus eingehenden PDFs:** analog zur
Positions-Extraktion auch **Kontaktdaten aus eingehenden PDFs picken** und ins Kontaktbuch
übernehmen — mit **kleinem Edit-Fenster** vor dem Speichern, **Dubletten-Check** gegen die
bestehende Datenbank. Gleiches Muster wie der bereits geloggte „Kontakt anlegen"-Alert
(Mail-Signaturen/Dokumente) im Drive/Mail-Alerts-Block unten — hier PDF-Angebote als zusätzliche
Quelle. Nutzt denselben bestehenden `ContactActionCard`-Flow (gated, Karte→Bestätigung→Audit).

**⚠️ KORRIGIERT (Johannes 2026-07-02, „NÖ!"):** die vorherige „Freigabe zum Testen"-Formulierung
ging von einem automatischen Batch-OCR-Modell aus — **falsch**, siehe korrigiertes Mechanismus-
Modell oben. Kein „KI liest alle bekannten Angebote automatisch aus und ich prüfe morgens eine
Liste" — das Feature ist per Design IMMER live/klick-getrieben, es gibt kein sinnvolles
unbeaufsichtigtes „Ausprobieren an allen Angeboten". Was nachts sicher geht: UI-/Technik-Bausteine
bauen (Vorschau-Toggle, Rechteck-Auswahl-Overlay, Editor), Text-Extraktion aus einer **von
Johannes selbst vorgegebenen** Koordinate auf einer bekannten PDF-Seite technisch verifizieren
— nicht „irgendwelche Positionen selbst erkennen und raten". Bei Unsicherheit: fragen, nicht
raten („bevor du kacke baust").

**⚠️ Wichtig — vermutlich KEIN Zero-to-One:** aus der Schätz-Engine-Arbeit (Kalkulations-Port)
existiert bereits ein Korpus mit **~818 bereits extrahierten `position_candidates`** aus 164 PDFs
(siehe Memory „Kalkulation-Datenbestand"). **Vor jedem Neubau prüfen, ob dieser Bestand
wiederverwendet/als Startpunkt genutzt werden kann**, statt Extraktion komplett neu zu bauen.

**⚠️ Korrektur (Johannes 2026-07-02) — BEWUSST ENTKOPPELT von der Kalkulations-Engine:**
der I/O-Audit flaggte `KalkulationsEngine.importPDF` als voll implementiert, aber ohne Aufrufer/
Bestätigungsschicht („geladene Waffe") — das bleibt unverändert offen, **dieses Feature löst es
NICHT** und soll es auch nicht automatisch tun. Johannes: die Kalkulations-Engine bewusst
**außen vor lassen**, die extrahierten Positionsdaten NICHT automatisch „verNaschen" lassen. Der
Positions-Picker ist eine **eigenständige Datengrundlage** (für Warenkorb/Checkout) — was davon
später Richtung **Kalkulations-Engine-Review/-Tuning** fließt, ist ein **separater, bewusst
manuell getriggerter Schritt**, keine automatische Kopplung/kein impliziter `importPDF`-Aufruf.
**Zeitpunkt (Johannes):** diese Kopplung — falls überhaupt — kommt **ganz am Ende, erst in der
„diamantenen Version"** (spätester Reifegrad). Für die aktuelle Bau-Reihenfolge irrelevant, nur
zur Einordnung: nicht Welle C, nicht bald.
`importPDF` bleibt ein eigenes, separates offenes Thema (weiterhin „geladene Waffe", braucht
seinen eigenen Aufrufer/seine eigene Bestätigungsschicht, wenn/falls das mal angegangen wird).

**UX-Workflow (Johannes, Konkretisierung):** Klick auf ein Angebot in der Angebots-Katalogansicht
→ öffnet als **große Vorschau** (PDF-Ansicht, heutiges Verhalten). **Toggle** wechselt in eine
**Detailansicht**, die die einzelnen Positionen des Angebots zeigt und einzeln „mitnehmbar" macht
(Pick-Auswahl je Position). Zwei Ansichtsmodi eines Objekts, ein Toggle dazwischen — kein neuer
Screen, sondern eine Erweiterung der bestehenden Angebots-Vorschau.

**Bau-Einordnung:** gehört in Welle C (C1 ist die Pick-Grundlage, die es schon gibt; die
PDF-Extraktion selbst ist ein eigener, substanzieller Teilstrang — vermutlich Claude-Vision auf
PDF-Text, analog zum bereits bestehenden `OfferDocumentClassifier`-Muster, aber viel tiefer:
Positions-Ebene statt nur Dokument-Klassifikation). **Nicht jetzt bauen** — großer, eigener Strang,
verdient volle Aufmerksamkeit + Johannes' Live-Abnahme auf echten PDFs, nicht nebenbei.

## Nachtrag 2026-07-02 spät — Drive/Mail-Alerts auf bestehenden Beobachtungspfaden (Johannes)

- 📋 **„Bitte reagieren"-Alert bei liegengebliebenem Eingang:** eingehendes Freigabe-Dokument, Mail
  oder Angebot, auf das Johannes lange nicht reagiert hat → Erinnerung. **Gegenrichtung** zur
  bereits geloggten Nachfass-Erinnerung (dort: ausgehendes Angebot ohne Kundenreaktion; hier:
  eingehendes Ding ohne EIGENE Reaktion) — gleiche zeitbasierte Alters-Schwellen-Logik, andere
  Blickrichtung. Beide gehören zusammen in den ohnehin schon geforderten zentralen Alerts-Strang.
- 📋 **„Kontakt anlegen"-Alert bei neu erkannten Kontaktdaten:** tauchen in Mail-Signaturen,
  Mail-Body oder Dokumenten Kontaktdaten auf, die noch **nicht** in der bestehenden Datenbank
  stehen → Vorschlag „Kontakt anlegen?". **Immer** Abgleich gegen die bestehende Datenbank vorher,
  **nie ohne Bestätigung + visuellem Dubletten-Vergleich schreiben** (Johannes' eigene Vorgabe).
  **Buildbar auf Bestehendem:** `ContactActionCard`/`AirtableContactActionCard` (bereits gated,
  Karte→Bestätigung→Audit, im I/O-Audit dieser Session bestätigt) — hier nur die Erkennungsquelle
  erweitern (Mail-Signatur-/Dokument-Scan statt nur explizitem User-Befehl), Sicherheitsmodell
  bleibt identisch zum bestehenden Flow, keine neue Schreiblogik nötig.
- 📋 **Eingehendes Angebot/Routine-Dokument → CTA „Ins Drive ablegen":** empfängt man per Mail ein
  Angebot oder anderes Routine-Dokument, direkter Hinweis/Call-to-Action, es in den passenden
  Projekt-Drive-Ordner zu schieben. **Umgekehrte Richtung des bereits gebauten** Anhang→Drive-Flows
  (`MailAttachmentDriveSheet`, diese Session) — dort manuell ausgelöst, hier proaktiv bei Erkennung.
  Erkennung kann auf `OfferDocumentClassifier`-Heuristik aufbauen (Angebot/Rechnung-Namensmuster
  existiert schon); Projekt-Zuordnung (welcher Ordner passt) ist der offene Teil — vermutlich über
  Kunde/Projektnummer im Betreff/Anhang-Namen, analog zur bestehenden Angebots-Ordner-Zuordnung.
- 📋 **„Alter Zeichnungsstand"-Warnung beim Mail-Versand:** wenn aus Assistent oder integrierter
  Mailfunktion ein Zeichnungsanhang verschickt wird, der nicht die neueste namensähnliche Datei im
  Drive-Projektordner ist → Warnhinweis vor dem Senden. **Buildbar auf Bestehendem:** Drive-
  Ordnerlisting existiert schon (`GoogleDriveClient`), Mail-Anhänge sind gerade erst live geworden
  (`MailAttachmentRow`/`MailAttachmentDriveSheet`, diese Session) — fehlt nur ein Namens-Ähnlichkeits-
  Abgleich (Basisname ohne Versions-/Datumssuffix) + Datums-/Versionsvergleich vor dem Senden.
- 📋 **Nachfass-Erinnerung bei Angebot ohne Reaktion:** „bei dem Angebot müsste ich mal wieder
  nachfassen" — zeitbasiertes Signal, wenn ein ausgehendes Angebot seit N Tagen ohne erkennbare
  Reaktion (keine neue Datei/Mail im Projekt) liegt. **Buildbar auf Bestehendem:** Datum steckt
  schon in `AllOffersView`/`DriveOfferWatcher`, nur eine Alters-Schwelle + Signal fehlt.
- 💡 **„Ist die Rechnung eingegangen/bezahlt?"** — **ehrliche Einschränkung:** ob eine Rechnung
  *bezahlt* ist, lässt sich NICHT zuverlässig daraus ableiten, dass ein PDF im Drive-Ordner liegt
  (ein abgelegtes Dokument beweist nur „Dokument da", nicht „bezahlt"). Echter Bezahlt-Status
  braucht eine echte Datenquelle — deckt sich mit der bereits geplanten **sevDesk-Eingangs-Postbox**
  (Rückrichtung aus §5i/§5j: sevDesk schreibt Status → mykilOS liest, nie direkter Read). Ohne die
  bleibt es Vermutung, nicht Fakt — sollte im UI klar als „ungewiss" markiert sein, falls doch
  heuristisch gebaut wird.
- 📋 **„Neue Werkzeichnung"-Alert:** entweder bei passendem **Mail-Betreff** (neuer, paralleler
  Watcher analog zum bestehenden Gmail-Search-Tool) oder bei **neuer Datei im Drive-Projektordner**
  — **Zweiteres direkt auf dem bestehenden `DriveOfferWatcher`-Muster baubar**: Keyword-Set einfach
  um „zeichnung"/„werkzeichnung" erweitern (heute nur angebot/rechnung/kostenvoranschlag/offer/
  invoice), gleiche Baseline-/Signal-Logik (`offerDetected` → Mediator → Widget-Hinweis).
- **Querverbindung:** das ist bereits die **vierte** Alert-Idee heute (CAD-Adapter, Angebots-/
  Rechnungs-Status, Werkzeichnung, plus die früher erkannte Lücke „Benachrichtigungs-Zentrum" aus
  `FINALE_APP_RUECKWAERTS.md`) — verstärkt den Fall für einen eigenen, zentralen Alerts-Strang statt
  vieler Einzel-Watcher. Nicht jetzt bauen, aber als wiederkehrendes Muster im Blick behalten.
- ⚠️ **QUERSCHNITTS-REGEL für ALLE Alerts oben + jeden künftigen Alert (Johannes 2026-07-02):**
  **dezent** (kein aufdringliches Popup/Badge-Spam) und **je Alert-Art ein-/ausschaltbar** in den
  User-Einstellungen unter **Datenschutz** — pro Nutzer individuell (deckt sich mit dem
  bestehenden Muster „Private Area/Profil-Sektion in Settings"). Gilt rückwirkend für JEDE der
  Alert-Ideen in diesem Nachtrag UND für den später gebauten zentralen Alerts-Strang — kein Alert
  ohne eigenen Toggle, kein Toggle ohne Datenschutz-Sektion. Beim Bauen des Alerts-Zentrums als
  Grundvoraussetzung mitdenken, nicht nachträglich anflicken.

## Nachtrag 2026-07-02 spät — Montags-Projektbesprechung-Briefing (Johannes)

- 📋 **Assistent-Modus „Montags-Briefing":** Jeden Montag ~60–120 Min. Team-Runde nach
  Projektliste/Reihenfolge — Austausch über Stand, Umstände, Termine, offene Punkte je Projekt.
  **Idee:** ein eigener Assistenten-Befehl/-Modus, der genau dieses Meeting **je Projekt einzeln
  UND gesammelt** vorbereitet.
  - **Je Projekt:** was hat sich seit letzter Woche geändert (Status/Phase), anstehende Termine
    (Kalender), offene ClickUp-Tasks, neue Angebote/Belege (AllOffersView), Cash-Stand, evtl.
    offene Mail-Threads.
  - **Gesammelt:** eine Übersicht in der **Reihenfolge der Projektliste** (wie das Team im
    Meeting selbst vorgeht), mit Ampel/Highlights — „was brennt", „was läuft rund".
  - **Datenquellen bereits live vorhanden:** Airtable-Projektliste (Reihenfolge!), ClickUp-Tasks
    je Projekt, Kalender-Widget, Angebote-Erkennung, Cash/Sevdesk-Widget, Mail-Suche.
  - **Ausgabe-Andockpunkt:** könnte dieselben Ausgabewege nutzen, die der Dev-Checkout-Exporter
    gerade baut (Copy-Paste-Vorschau / Notiz / ZIP) — ein „Montags-Briefing" ist im Kern auch nur
    ein strukturierter Export über mehrere Projekte hinweg, kein neues Ausgabe-Konzept nötig.
  - Reiner Lese-Zusammenzug, kein Schreibvorgang — sollte ohne neue Rechte/NO-GO-Fragen baubar
    sein, sobald die einzelnen Quellen (Kalender/ClickUp/Angebote/Cash) je Projekt sauber
    abrufbar sind (größtenteils schon der Fall).

## Nachtrag 2026-07-02 (Assistenten-Tweaks, Johannes im Auto-Modus)

- 📋 **Bestätigung per natürlichem Befehl:** Action-Cards im Assistenten sollen sich auch per
  Wort im Chat bestätigen lassen — „ist bestätigt", „mach", „go", „los", „ja" — statt nur per
  Klick auf den Karten-Button. Sicher: nur auslösen, wenn es GENAU EINE offene, unbestätigte
  Action-Card im letzten Assistenten-Zug gibt (sonst normal an den LLM). Läuft weiter über die
  bestehenden gated Handler (Karte→Bestätigung→Audit) — der Confirm-Word ersetzt nur den Klick.
- 📋 **Datei-/Screenshot-Upload → Bild-Analyse + Kontext + Action-Vorschläge:** Screenshot droppen
  + „schau mal / kennst du das / analysiere" → Assistent erkennt den Inhalt und schlägt passende
  Aktionen als Action-Cards vor: Kontakt-Screenshot → „Kontakt anlegen?"; Google-Maps → „Adresse
  finden / dort suchen / Route?"; Moodboard → „ablegen / verschieben / verschicken?". Kurzer,
  effizienter, ökonomischer Inhalt/Kontext/Action-Abgleich. Braucht Bild→LLM-Vision-Pfad
  (ChatContentBlock.image existiert) + Klassifikations-Prompt → bestehende gated Action-Cards.
  Aktion feuert NIE automatisch — nur Vorschlag, Ausführung über die Karte.

Aus der Multi-Agent-Rückschau (`docs/RUECKSCHAU_UND_SESSIONPLAN_2026-07-02.md`) — diese
verbalen Wünsche waren noch nicht sauber verankert und werden hiermit festgehalten:

- 💡 **Grundriss-/Skizzen-Zeichentool im Fragebogen (Canvas) → Drive-Export.** Schritt „Raum":
  echtes Zeichenwerkzeug (Maus), Ergebnisbild automatisch in den Projekt-Drive-Ordner.
- 💡 **Projekt-Hero-Bild editierbar** (Upload/Import je Nutzer) + volle Identität (Avatar-Wähler).
- 💡 **Teamkalender-Widget in der Projekt-Übersicht** (Teamtermine farbcodiert, Klick → Detail +
  editierbar). Braucht Kalender-Schreibpfad (→ Session S3).
- 💡 **Upload-/Anhang-Icon im Chat-Composer** schöner/echter Anhang-Button (UI-Polish; die
  Multi-Datei-Drop-Kernfunktion ist erledigt).
- 📋 **Kontakte-Widget klickbar/editierbar mit Airtable als Quelle** — vorgelagert Daten-Job
  Google-Kontakte → Airtable (Dubletten-Check, Vollständigkeit; Nur-Name-Einträge als
  UNVOLLSTÄNDIG markieren). Danach Projekt-Widget: klick/zuweis/editier/Mail.
- 📋 **ClickUp-Schreib-/Signal-Integration** — Tasks aus mykilOS anlegen/ändern, alarmieren,
  terminieren (Toggle), Signal-Kanal in die App. Eiserne Regel beachten (Testspace/Ghost).
  **Johannes 2026-07-02: als nächste große Session vorgemerkt** (Ghost Johannes → Real NUR für
  Johannes, andere vier bleiben Ghosts). Siehe S3.5 im Session-Plan.
- 📋 **Dubletten-Zusammenführung realer Projekte** (z. B. Vinahl + Uetersen = EIN reales Projekt)
  mit Nummernkreis-/Vermatschungs-Warnung direkt in der App.
- 💡 **Meilenstein-Statusbar mit Monatsangaben** im Projekt-Hero oder als Widget (der
  Lebenszyklus-Stepper ist erledigt, die Datums-/Monats-Variante fehlt noch).
- **✅ Mail SENDEN (Free-Climber-Anker-Fund 2026-07-04, war veraltet):** längst live —
  `MailClientView` → `appState.sendMail` → `GoogleGmailClient.sendMessage`, mit
  Bestätigungs-Gate (`showSendConfirm` in `ComposeMailView`). Nur im eigenständigen
  Mail-Client-Modul injiziert (`onSend:`), NICHT in Ad-hoc-Compose-Sheets aus anderen Tabs
  (bewusst, siehe Kommentar in `ComposeMailView.swift`). **Noch offen:** Nachrichten-Aktionen
  (gelesen/Stern/Archiv/Löschen).

---

## Zukunfts-Konzepte 2026-07-02 (Vision-Runde mit Johannes)

Kurzfassungen; die Details liegen in eigenen Konzept-Dokumenten. Alles mykilOS-8+,
baut auf der laufenden 8.0 auf.

### 📋 Airtable-Core-Konsolidierung — App von Daniels Base entkoppeln
Neue Greenfield-Base `mykilOS_Core` als einziger Master, mit dem die App spricht;
Daniels Artikel-Base wird gespiegelt (read-only Sync) + neu einsortiert, nie direkt
gelesen/geschrieben. READ leicht (Copy-in), WRITE via Feeder-out an seine sevDesk-
Pipeline. Kern-Entscheidung (frische Core) ✅ getroffen; Sequenz: **nach 8.0**.
→ **docs/AIRTABLE_ARCHITEKTUR.md**

### 💡 Formulare-Ebene — gebrandete Firmendokumente aus mykilOS-Daten
Modul mit Vorlagen-Bibliothek (Moodboard, Brief, Abnahmeprotokoll, Geräteliste,
Präsentation). Engine: **HTML/CSS-Vorlage → PDF (WKWebView)**, weil Design von Daten
trennt. Vorlagen als Daten (CRUD pro Kategorie), Lager: geteilter Drive-Ordner +
Defaults. Befüllung context-driven aus dem local-first Cache. Dokumente **am Projekt
verankert** (Detailseite, vor-ausgefüllt, PDF in Projekt-Drive-Ordner).
→ **docs/FORMULARE_EBENE.md**

### 💡 Gebrandete PDFs — Marken-Assets
MYKILOS-Briefpapier/Logo(SVG)/Monument-Grotesk(woff2 + fertige stylesheet.css)/
Pflicht-Fußtext gesichtet & spezifiziert. Erweitert `MykPDFRenderer` bzw. speist die
Formulare-Engine. Offen: Font-Embedding-Lizenz. → **docs/brand/README.md**

**Update 2026-07-02:** echtes Design-System-Export lokal gefunden (Ordner
„MYKILOS Design System" auf dem Desktop) — enthält jetzt zusätzlich die tatsächlichen
Font-Dateien (`ABCMonumentGrotesk-Medium.otf`, `ABCMonumentGroteskMono-Regular.otf`,
Foundry: **Dinamo Typefaces**) + das echte Vektor-Logo (SVG) + eine präzise CSS-
Spezifikation (Farben/Typografie/Spacing/Radien). **Logo ist bereits eingebaut**
(`Sources/MykilosApp/Resources/mykilos-wordmark-*.svg`, `MykWordmark`-Komponente,
Sidebar-Breitmodus) — eigenes IP, keine Lizenzfrage. **Fonts liegen bereit, sind
aber NICHT ins App-Bundle eingebettet** — die Lizenzfrage (Dinamo-Foundry) ist
weiterhin offen und wurde bewusst nicht eigenmächtig entschieden. Ein bestätigter
Bug dabei gefixt: „ABCMonumentGrotesk-Regular" existierte nie als Datei (nur Medium
+ Mono Regular wurden geliefert) — Typography.swift nutzte das trotzdem für
Body/Small/Caption, was lautlos auf den System-Fallback zurückfiel. Jetzt einheitlich
auf den echten Medium-Schnitt gemappt.

### 💡 Herstellerbilder-/Bild-Assetkatalog (für Moodboards)
Bild-Datenbank **wie die Kataloge** (Artikel-Base hat schon ein Produktbild-Feld),
Zusammenstellung **wie der Warenkorb** („zusammenklicken" → Moodboard-Bildraster).
Eigener kleiner Strang, überschneidet sich mit der Erkundung *Gerätelisten-Expand*.

### 📋 Kunden-Adressmodell (Customer + Adresse, ans Projekt gebunden)
`Customer` um Adressfelder erweitern + ans Projekt binden. **Sinnvoll erst MIT der
Core-Migration** (sonst Wegwerf-Arbeit, weil Adresse in Core lebt). Vorarbeit schon
da: `Customer.clockodoCustomerID`-Muster + `Kunden.Adresse` in der Artikel-Base.

### 💡 3 geparkte Erkundungs-Sessions (im Gedächtnis, auf Johannes-Brief wartend)
Gerätelisten-Expand · Schätzpreis-Konfiguration · ClickUp-Setup aus Slackanalyse.
Nur Eruierung/Pläne, isolierte Branch-Sessions; nicht selbst starten.

### 💡 Warenkorb & Checkout — universeller Picker + Router (Wirbelsäule)
Warenkorb = Picks aus jeder Matrix (Kunde/Produkte/Material/Angebote/Artikel/Zeiten/
Dienstleistungen/Lager); Checkout = Router in beliebige Ziele (DBs/Moodboard/Listen/
Dokumente/Templates). Vereint Formulare-Ebene + Geräteliste + Moodboard + Angebot.
→ **docs/WARENKORB_CHECKOUT.md**

#### 💡 Futurefeature (Johannes 2026-07-04) — Checkout per Drag & Drop als „visualisierter Weg"
Warenkorb **direkt aus dem gewählten Checkout heraus draggen** und auf die **richtige Ziel-App/
-Funktion droppen** → **Bestätigungsdialog** → Ausführung. Kein Menü-Ausklappen, sondern man
**sieht die Route** vom Korb zum Ziel (der „visualisierte Weg"). Fügt sich nahtlos in die
bestehende **Ports-Architektur** ein: jeder `CheckoutPort` (Dokument/sevDesk/Moodboard/VW-Plankopf
…) ist ein Drop-Ziel, der Bestätigungsdialog = `preview()`, das Fallenlassen = `execute()`. Also
eine **visuelle Oberfläche über `PortRegistry`**, kein neues Subsystem. UI-Schicht, später.

#### 💡 Futurefeature (Johannes 2026-07-04) — Text-Bausteine aus PDF via Picker-/Warenkorb-Logik
Textblöcke aus PDFs mit **derselben Picker-/Warenkorb-Mechanik** ernten wie die Angebots-
Positionen-Extraktion (§ Nachtrag 2026-07-02, PDF → Positionen → Warenkorb) — nur gemünzt auf
**Textbausteine** statt Preis-Positionen. Ergebnis: ein `textbausteine`-Pick-Matrix-Korb, der die
Leer-Templates speist (verknüpft mit dem Textbausteine-Katalog oben, Z. 46-47). Verwandt mit dem
VW-Plankopf-Strang: die Geräte-/Material-Textblöcke des Plankopfs sind genau solche Bausteine.

#### 🚧 ClickUp-Basics IN der App (Johannes 2026-07-04: „Aufgaben anlegen, zuweisen, erledigt markieren")
**Status 2026-07-04:** Backend + isolierte Test-Werkbank live. `ClickUpClient` hat jetzt
`ClickUpTaskWriting` (Aufgabe anlegen mit optionalem `content`, Status setzen) — 4 neue Tests,
923 Tests grün. UI: **`ClickUpTestWerkbankView`** in Settings → ClickUp (erscheint nur bei
verbundenem Konto) — schreibt AUSSCHLIESSLICH in die Sandbox-Liste „KUE-2026-014 Küche Müller
TEST" (`901218940344`) im Testspace `90128024109`. Aufgabe anlegen + Ghost-Kürzel-Text-Marker
(kein natives Assignee-Feld) + Status per Menü ändern. **Noch offen/zu verifizieren:** Claude
kann die native macOS-UI nicht selbst klicken — Johannes probiert einmal live in Settings aus,
dann Entscheidung über Wiring in die echte projekt-gebundene `TasksWidget` (Ghost→echt, eigene
Freigabe nötig). Ursprüngliche Analyse: `TasksWidget` war rein READ; `ClickUpClient.createTask`
(2-Arg) existiert(e) nur für `ProjektProvisioningService` (automatische Listen-Anlage), kein
Nutzerpfad — das bleibt unverändert, die neue `createTask(listID:name:content:)` ist ein
separater Overload. **Bau mit
harten Regel-Leitplanken (nicht verhandelbar):**
- **KI weist NIE zu** ([[aufgaben-nur-mensch-zu-mensch-regel]]): die App ist Werkzeug, der
  MENSCH ist Auftraggeber/Absender. Kein Auto-Assign, kein KI-erzeugter Task „an" jemanden.
- **Ghost-Persona-Regel** ([[clickup-ghost-persona-rule]]): Entwicklung/Test NUR im Testspace
  `90128024109`, NIE echte Assignee-ID (löst reale Notifikation aus!), simulierte Zuweisung nur
  als Kürzel (Jo/Da/Fra/Sen/Jil) im Text. Ghost→echt erst auf Johannes' ausdrückliche Freigabe.
- **Baubar davon SICHER jetzt:** Task anlegen (im Testspace), Status ändern / erledigt markieren
  (kein Assignment nötig), Kommentar. `ClickUpClient` braucht Write-Methoden (createTask/
  updateStatus) + der PAT ist per-User ([[team-konten-topologie]]).
- Verwandt: `mykilos8-clickup-orchestration` (vertagt), `vor-rollout-bereinigung-ordner-clickup`.

#### ✅ Galerie-Flug (Johannes 2026-07-04: „durch alle Dateien fliegen, blättern, Diashowen")
Finder-/QuickLook-Inspo (macOS-Screenshots im Feedback-Ordner) → Ausbaustufe des
Sammlungs-Ansicht-Standards. Live in **Material-Tab + Dateien-Tab** (2026-07-04):
1. ✅ **Ansichts-Switch Liste ⇄ Galerie** (Material-Tab, Dateien-Tab). Zeichnungs-Katalog/
   Angebote-Tab noch offen.
2. ✅ **Mouseover:** Anheben+Schatten (MykMotion) + Quick-Action „extern öffnen".
3. ✅ **Blättern:** `DocumentViewerView` nimmt jetzt eine Sammlung + Startindex
   (`DocumentViewerItem`) — ←/→ (Header-Pfeile oder Pfeiltasten) blättert ohne zu schließen.
   Alter Einzeldatei-Init bleibt als Komfort-Wrapper, bestehende Aufrufer unverändert.
4. ✅ **Diashow:** Leertaste oder Play-Button startet Auto-Advance (3,5 s, wrapt am Ende zum
   Anfang), Leertaste/Klick pausiert wieder.
5. ✅ **Echte Mini-Thumbnails** (`ThumbnailStore`: `QLThumbnailGenerator` lokal, Drive
   `thumbnailLink` remote, NSCache LRU). **Fix 2026-07-04:** Drive-Link trug fix `=s220` →
   matschig bei großen Kacheln; jetzt dynamisch auf Zielgröße hochskaliert (gedeckelt 1600px).
6. ✅ **Kachelgröße stufenlos wie Finder** (`KachelGroessenSlider`, `@AppStorage`, pro Tab
   gemerkt).
7. ✅ **Finder-Selektion** (Johannes 2026-07-04): Einfachklick wählt an (oranger Ring),
   Leertaste ODER Doppelklick öffnet die volle Fenster-Vorschau — `DateiGalerieGrid`
   `.onKeyPress(.space)`.
8. ✅ **Hero-Bild-Konsistenz** (Johannes 2026-07-04): Favoriten-Mini-Karten
   (`ProjectFavoritesWidget`) zeigten nur den Archetyp-Gradient, nie das echte Hero-Bild —
   jetzt gleiche Fokus-Fill-Logik wie `ProjectCard`.
Klein & schön (Nordstern). Live-Feedback von Johannes beim Bau erwünscht.

#### 💡 Spielwiese (Johannes 2026-07-04, Nacht) — Heuler + Rainbow/Freaky-Friday-Mode
- **Heuler:** ein bewusst LAUTER, theatralischer Alert (Brüllbrief-Stil) für selbst
  gewählte Dinge („wenn X passiert, schrei mich an"). Spannung zur Eisernen Regel
  „Alerts dezent" → Auflösung: strikt **opt-in, nur an sich selbst**, pro Alert einzeln
  scharf gestellt — Selbst-Beschallung erlaubt, Fremd-Beschallung nie.
- **✅ Rainbow Mode (2026-07-04):** Toggle in Settings → Darstellung. Kein zweites Palette-Set —
  ein Hue-Shift (+0.42) auf jeden `MykColor`-Token direkt in `adaptive()`, liest live aus
  `UserDefaults` (`ui.rainbowMode`), `.id(rainbowMode)` am App-Root erzwingt sofortigen
  Full-Redraw. 928 Tests grün (kein neuer Testtarget nötig — reine Visualebene wie der Rest
  der Tokens-Datei). „Freaky Friday" als eigenes zweites Palette-Set nicht gebaut (YAGNI —
  der Hue-Shift liefert denselben Spaßfaktor architektonisch billiger).
- **Boss-Button 🥹 (Johannes, 2026-07-04 Nacht):** DER eine große Knopf. Lesart A
  „Feierabend-Ritual": ein Druck → Backup jetzt (backup_local_data.sh), Save-States
  geprüft, Status-Einzeiler „alles sicher, gute Nacht". Lesart B „Chef-Moment":
  kontextbewusster Knopf, der das gerade Wichtigste auslöst (Tages-Fokus, dringendster
  Hinweis). Auslegung entscheidet Johannes beim Bau — ein Knopf, ein gutes Gefühl.

### 💡 UI-Batch 2026-07-02 (aus Screenshot-Runde)
- **✅ Kontakte klickbar (2026-07-04):** Mail-Adresse im Kontakte-Widget (Projekt-Übersicht) ist
  jetzt ein eigenes klickbares Element (Hover-Unterstreichung) → öffnet `ComposeMailView` mit
  vorausgefülltem Empfänger. Callback-Injektion `onMailContact` (Widgets→App-Grenze, gleiches
  Muster wie `onAttachFilesToMailDraft`), Sheet + Identifiable-Wrapper `MailComposeTarget` in
  `ProjectWidgetBoardView`. Bewusst schlank: `contacts: []` an ComposeMailView (kein Airtable-
  Kontaktbestand hier verfügbar) — der interne „weiteren Kontakt wählen"-Picker bleibt leer,
  Haupt-Use-Case (direkt an diese Adresse) funktioniert vollständig. 928 Tests grün.
- **🚧 Kontakte-Widget (Projekt-Übersicht) → Airtable-Migration (Schritt 1 gebaut, 2026-07-04):**
  Vorgelagerter Daten-Job jetzt live buildbar: **Settings → Google → „Kontakte-Import"**
  (`ContactsImportView`) — Vorschau lädt ALLE Google-Kontakte (neue `GoogleContactsClient.
  listAllContacts()`, paginiert über `people.connections.list`, anders als das Query-basierte
  `searchContacts`) + bestehenden Airtable-Bestand, `ContactImportPlanner` (rein, 7 Tests)
  entscheidet je Kontakt: **neu anlegen** / **Dublette** (Mail- oder Telefon-Treffer, normalisiert)
  / **verworfen** (weder Mail noch Telefon — kein „Web"-Feld bei Google-Kontakten verfügbar,
  daher nur die zwei Kriterien statt der ursprünglich drei). Bestätigung schreibt über den
  bestehenden `AppState.writeAirtableContact(.create)`-Pfad, ein Kontakt nach dem anderen,
  mit Audit + DataFlowLogger (`GOOGLE_CONTACTS_TO_AIRTABLE_IMPORT`, Handbuch-Eintrag gesetzt).
  **Warum nicht von mir automatisch ausgeführt:** Claude Code hat keinen Zugriff auf die echte
  Google-OAuth-Session der laufenden App — nur Johannes kann den Button selbst klicken (Vorschau
  ansehen, dann bestätigen). **Noch offen (Schritt 2):** Das Projekt-Widget selbst liest weiterhin
  live von Google (`ContactsWidget`/`contactsQuery`) — die Umstellung auf die kuratierte
  `Kundenkontakte`-Tabelle (Projekt-Zuordnung, `Projekt`-Textfeld) + klick/zuweis/editier im
  Widget kommt erst, NACHDEM der Import gelaufen ist und echte Daten zum Zuordnen da sind.
- **Teamkalender-Widget** in der Projekt-Übersicht: Teamtermine farbcodiert (Button-Farbe),
  Klick → Detail-Vorschau + editierbares Menü. Braucht Kalender-Schreibpfad.
- **✅ Mail: Senden** — siehe Korrektur oben (Nachtrag 2026-07-02, Zeile ~452): längst live in
  `MailClientView`. Nachrichten-Aktionen (gelesen/Stern/Archiv/Löschen) fehlen weiterhin.
- **✅ erledigt (2026-07-02) — Preisliste:** Klick-Detail-Vorschau pro Produkt. Klick auf
  einen Artikel (Zeile/Kachel) im Shop → Detail-Sheet (großes Bild klickbar, Bezeichnung,
  Art.-Nr./Kategorie, EK/VK/**Marge %**, Lager-Hinweis, „In den Warenkorb"). `ArtikelDetailSheet`.
- **Artikel-Anreicherung** (Links/Doks/Bilder/Montage/CAD): extern erschlossen, NICHT in der
  Airtable-Artikel-Tabelle — Fundort klären (vermutl. lokales DB-Prefill-Paket), dann integrieren.
- **Projekt-Hero-Bild** editierbar (Upload/Import je Nutzer), **Volle Identität** (Avatar-Wähler/
  Kontakt/Notifications), **volle Datei-Vorschau + Kachel/Liste** — siehe UI-Analyse-Workflow.

### 💡 UI-Batch 2026-07-02 Runde 2 (03:36-Uhr-Screenshots)
- **Fragebogen, Schritt „Raum", Zeichenfläche:** Wunsch nach einem echten Grundriss-/Skizzen-
  Zeichentool (mit Maus zeichnen). Bestehendes Feld ist laut Johannes „klein, unpraktisch,
  unvollständig". Ergebnisbild soll automatisch im Projekt-Drive-Ordner abgelegt werden.
  Braucht ein Canvas-Zeichenwerkzeug (SwiftUI `Canvas`/`PencilKit`-artig) + Export→Drive-Upload.
- **✅ Korrigiert (2026-07-04, war veraltet):** „Der Wiederherstellen-Button ist tot" — stimmt
  nicht mehr. `WebshopTabs.swift` zeigt Vorschau (read-only, ändert nie den aktiven Warenkorb)
  UND Wiederherstellen (`onWiederherstellen` → `WarenkorbSheetKontext(previewOnly: false)`)
  sauber getrennt und funktionsfähig — offenbar zwischen 2026-07-02 (Ersteintrag) und heute
  gefixt, ohne dass diese Zeile aktualisiert wurde. Free-Climber-Anker-Nachtrag.
- **✅ erledigt (2026-07-02) — Warenkorb-Widget auf der Projekt-Detailseite:** `WidgetKind.warenkorb`
  ist live im Übersicht-Board (Position 6, wide). `WarenkorbWidget` zeigt den **aktuellsten
  gespeicherten Warenkorb des Projekts** (Match über Bezeichnung: Projektnummer/-name, weil das
  Airtable-„Projekt"-Link-Feld bewusst leer bleibt) mit Positionen + EK/VK-Summen und allen
  Renderstates. Bestehende Boards bekommen es per Nachzügler-Migration (`ensureWidgetOnce`,
  eigener Marker, respektiert Entfernen). Erster konkreter Baustein des
  **[WARENKORB_CHECKOUT.md](WARENKORB_CHECKOUT.md)**-Konzepts (Projekt-Picks sichtbar machen).
  Offen bleibt der volle Checkout-Router (universeller Picker über alle Matrizen).

### 💡 UI-Batch 2026-07-02 Runde 3 (Abend-Screenshots, Assistent + Zukunftswünsche)
- **Upload-/Anhang-Icon im Chat-Composer:** Johannes fragt nach einem „schöneren" kleinen
  Upload-Icon rechts neben dem Chat-Eingabefeld. Stand 2026-07-02: der Composer
  (`AssistantChatView.composer`) hat NUR das TextField + den Senden-/Stop-Button
  (`arrow.up.circle.fill`) — es gibt aktuell KEIN dediziertes Upload-/Anhang-Icon dort. Zu
  klären: soll ein echter Datei-Anhang-Button rein (Bild/PDF an den Chat/Entwurf hängen), oder
  ist nur der Senden-Pfeil gemeint (dann Aesthetik-Feinschliff)? Nicht geraten — beim nächsten
  Mal mit Johannes am Bildschirm zeigen lassen.
- **✅ erledigt (2026-07-02):** Kopieren-Knopf im Assistentenchat (Hover-Button unter
  Assistenten-Antworten + Kopieren am Mail-Entwurf + Text markierbar), `CopyButton`.

### 🗺️ Future: Google-Maps-Widget je Projekt (Baustelle/Kundenadresse)
Kleines, echtes Google-Maps-Widget auf der Projekt-Detailseite: zeigt die Baustellen- bzw.
Kundenadresse des Projekts als klickbare Karte mit Stecknadel. Datenquelle: `Project`-Adresse
(Projektadresse Straße/PLZ/Ort) bzw. Kundenadresse. Umsetzung: statische Maps (Static Maps API,
ein Bild + Deep-Link zu Google Maps) ist am einfachsten und braucht keine JS-Karte; interaktive
Einbettung wäre ein WKWebView. Klick öffnet Google Maps mit der Adresse. Offen: Maps-API-Key
(→ Zugangsdaten-Registry/TRESOR), Kosten-/Kontingent-Frage der Static-Maps-API.

### 🗄️ Future: Archivierte Drive-Projektordner (alte Nomenklatur) in mykilOS abbilden
Für den Rückblick 1–2 Jahre: die im Drive `_PROJEKTE_ARCHIV` liegenden, teils nach ALTEN,
uneinheitlichen Namensschemata (Standort-Präfixe `B_`/`HH_`/`K_`/`WI_`, verschachtelte
Jahres-Unterordner) aufgebauten Projektordner sollen bei Bedarf auch in mykilOS sicht-/
durchsuchbar sein — ohne die aktive Projektliste zu verschmutzen. Ansatz (schon früher grob
skizziert, jetzt als Feature notiert): eigener Alt-Nomenklatur-Parser + eine
Übersetzungsregistry (Alt-Name ↔ `JJJJ-NNN`-Schema, dieselbe Intake-/Warnungs-Mechanik wie beim
Daniel-DB-Abgleich), als GETRENNTER „Archiv"-Bereich (eigener Filter/Modus), read-only. Bewusst
noch nicht angefasst — großer, eigener Strang.

---

## Architektur-Vorschlag: WorkBasket/Checkout-Pipeline (generisches Schreib-Modell)

### 📋 Generische DataObject→WorkBasket→CheckoutRun→Preview→Review→Audit-Pipeline
**Quelle:** Branch `handoff/workbasket-checkout-architecture-2026-07-01` (vermutlich
Codex-Session, 2026-07-01), gelesen + eingeordnet während der mykilOS-8.0-Konsolidierung.
**Status:** S0/S1 (reine Doku, 0 Code) laut eigener Stop-Regel abgeschlossen — kein
Feature-Code, bevor Johannes den I/O-Stand akzeptiert hat.

**Kernidee:** Statt jedes Schreib-Feature (Warenkorb, Angebote, CAD-Handoff, Mail,
Moodboards …) einzeln zu bauen, alle über dieselbe Pipeline: `DataObject →
WorkBasketItem → WorkBasket → CheckoutRun → Preview → Review/Safety → Output →
Audit → Postflight`. 18 durchgeplante I/O-Einträge (IO-001–IO-018), alle ❌ noch
nicht gebaut — u. a. Schätzung/Vergleich/Angebots-Template/Projektanlage-Staging
(überschneidet sich mit Block-F-Umfang), CAD-Handoff, Bildindex, Moodboard-Generator,
Firefly-Prompts, Dokument-/Mail-Vorlagen, Gmail-Drafts, Protokollpakete,
Auftragsbestätigungen (alles NEU, nicht im Rolling Plan).

**Bemerkenswert:** Zitiert unabhängig dieselbe HTTP-422-Lehre (Number-Feld als String,
Linked-Record mit rohem String) wie unsere eigene Live-Untersuchung vom selben Tag,
und nennt `ProjektProvisioningService` (mykilOS-8 Block D) explizit als Vorbild für
die künftige `CheckoutRun`-Implementierung.

**Wichtige Einschränkung:** Diese Branch ist von `main`/v7.7.2 abgeleitet, NICHT von
den mykilOS-8-Feature-Branches (Block A–D) — kennt `ExternalMappingRegistry`,
`WriteShadowRecorder`, `ProvisioningLedger` nicht im eigenen Code. Eigene Risiko-Notiz:
"Vor S3+ (echter Code) mit Johannes klären, welcher Branch der Merge-Zielpunkt ist."

**Offene Grundsatzentscheidung (nicht Teil der aktuellen Konsolidierung, für 8.1
mitzunehmen):** Rolling-Plan-Blöcke E/F/G wie geplant als Einzelfeatures weiterbauen,
oder auf dieses generische Pipeline-Modell umschwenken/verschmelzen? Branch bleibt bis
dahin unangetastet liegen.

---

## 🚨 P0-BLOCKER — Projektübersicht überlagert und blockiert die Sidebar

### 🟡 FIX COMMITTED (9ddf75a) — Live-Abnahme durch Johannes weiterhin ausstehend
**Quelle:** Live-Screenshots von Johannes, 2026-06-28 um 09:38/09:39;
forensische Auswertung durch Codex. **Korrigiert 2026-07-01** (Doku-Konsolidierung):
dieser Eintrag hieß bisher fälschlich "🚨 OFFEN", obwohl CLAUDE.md bereits seit
2026-06-28 "FIX COMMITTED · Live-Abnahme ausstehend" dokumentiert — reine
Doku-Inkonsistenz zwischen den beiden Dateien, kein neuer Code-Fund. Der Fix selbst
(`ZStack(.bottom)` → `.bottomLeading`, `VStack.leading`, Tab-Bar `maxWidth: .infinity,
alignment: .leading`) ist committed; **die Live-Abnahme am echten Gerät (Sidebar bei
aktiver Übersicht vor/während/nach Widget-Ladevorgängen klickbar) steht weiterhin aus**
— siehe Phase 4 der aktuellen Konsolidierungs-Session.
**Priorität:** P0 — vor S18/S20-Feature-Arbeit beheben und live abnehmen.
**Handoff:** [HANDOFF_P0_OVERVIEW_SIDEBAR_HITTEST.md](handoffs/HANDOFF_P0_OVERVIEW_SIDEBAR_HITTEST.md)

**Reproduktion:**
1. Projekt öffnen.
2. „Angebote“, „Timeline“ oder „Material“ aktivieren: Sidebar funktioniert.
3. „Übersicht“ aktivieren: Hero-/Tab-Inhalte werden links abgeschnitten; Sidebar
   bleibt sichtbar, nimmt aber keine Klicks mehr an.

**Kein Sidebar-Toggle:** Die Sidebar wird nicht absichtlich ausgeblendet. Das
Overview-Widget-Board wird horizontal übergroß; seine unsichtbare
Interaktionsfläche überlagert die Sidebar. Der Fehler ist deshalb gleichzeitig
Layout-, Navigation- und Accessibility-Blocker.

**Root Cause:** `ProjectWidgetBoardView` verwendet als einziger Tab ein
intrinsisch vermessenes SwiftUI-`Grid` mit flexiblen/asynchron wechselnden
Widgets und einem `Color.clear`-Filler. `.clipped()` versteckt Überstand nur
optisch und löst das Hit-Testing nicht.

**Nicht als Fix akzeptieren:**
- nur `.clipped()`, `.fixedSize`, `.layoutPriority` oder `WindowGuard`
- nur Build-/Unit-Test-Erfolg
- Prüfung ausschließlich in anderen Projekttabs

**Definition of Done:**
- Übersicht, Hero und alle Tabs bleiben vollständig innerhalb des rechten Panes.
- Sidebar bleibt vor, während und nach allen Widget-Ladevorgängen anklickbar.
- Prüfung unmittelbar und nach 300/800/1800 ms.
- Mehrere Projekte und Fenstergrößen live geprüft.
- Ergebnis mit Screenshots im Ereignisprotokoll/Handoff dokumentiert.

---

## Assistent als Kontakt- und Beziehungsintelligenz

### 💡 Assistent kennt alle Kontakt-Zusammenhänge (Vollbild-Vision)
**Quelle:** User-Wunsch 2026-06-27 (Kontakte-Import-Session).
**Vision:** Der Assistent hat ein vollständiges, lebendiges Bild aller
Personen, die mit MYKILOS in Berührung kommen — projektbezogen, aus
Google Kontakten und aus dem gesamten Mail-Verlauf. Er kennt:
- Wer ist Projektkunde, Architekt/Planer, Lieferant, Handwerker, Team?
- Welche Person gehört zu welchem Projekt (auch wenn der Name nur in einer
  Mail-CC oder im Betreff steht)?
- Wer hat wen vermittelt (z. B. Christian Westphal → Dr. Klose)?
- Welche Firmen/Domains tauchen project-übergreifend auf (Weichsel78,
  MGB Naturstein, HS-Architekten arbeiten an mehreren Projekten)?
- Welche Kontakte fehlen noch (25 von 31 Projekten ohne direkten
  Kundenkontakt in den CSV-Exporten)?

**Aktueller Stand (2026-06-27):**
- Airtable Mastermind hat jetzt eine **Kontakte-Tabelle** mit 914 Einträgen
  (891 aus CSV-Export + 23 aus Gmail-Recherche).
- 6 Projekte haben direkte Projektkunden-Links; 25 Projekte sind noch offen
  (Bellavance, Cirnavuk, Hustadt etc. haben Kunden per Gmail gefunden und
  bereits in Airtable eingetragen, aber noch nicht alle 31 abgedeckt).
- Gmail-Recherche liefert deutlich mehr Kontext als CSV-Export allein:
  Projektnummern im Betreff (#Cirnavuk, #Schmid), CCs mit Kunden-Mails,
  Architekten-Kontakte als Vermittler.

**Nächste Schritte für die App-Umsetzung:**
- AssistantWidget: Kontakte-Kontext aus Airtable laden (pro Projekt: wer
  ist der Ansprechpartner, wer ist der Architekt, wer sind die Lieferanten?)
- Gmail-Suche nach Projektnamen als Assistenz-Funktion (bereits im
  ASSISTANT_CAPABILITIES_PLAN.md als Lese-Punkt A3/A4 vorgesehen)
- Kontakte-Tabelle als lebendes Gedächtnis: neue Mail-Kontakte automatisch
  vorschlagen (Assistent erkennt unbekannte Absender in Projekt-Threads)
- Beziehungsgraph: wer arbeitet mit wem zusammen? (z. B. HS-Architekten
  orchestriert mehrere Gewerke bei Projekten 2026-021 und 2026-026;
  Weichsel78 ist Tischler für 6+ Projekte)

**Daten-Qualitätslücken:**
- 371 Kontakte haben keine E-Mail (nur Name/Telefon aus CSV-Export)
- Manche Projekt-Kunden sind nur per Firmen-Mail erreichbar (z. B. Wartenb
  erg Vermögensverwaltung), kein privater Kanal
- May, Wobig, von Boch, Loidl, Mohadjer, Cirnavuk (Kunde direkt),
  Zitscher (Kunde direkt) — Kunden-E-Mails noch unbekannt

---

## Clockodo Zuhörer — Smart Time Logger

### 📋 Clockodo Zeitbuchung aus Assistent-Chat + Kalender/Mail-Vorschlägen
**Quelle:** User-Wunsch 2026-06-28. Architektur definiert, Airtable-Schema live,
Code-Implementierung steht noch aus (nächste Session).

**Kernregel — User-Scoping:**
Jeder angemeldete User bucht, sieht und editiert **ausschließlich seine eigenen**
Zeiteinträge. `ClockodoDraftEntry` hat `clockodoUserID: Int`, alle GRDB-Queries
filtern darauf. Clockodo-API-Credentials (E-Mail + API-Key) liegen per User im
Keychain — wer die Creds nicht hat, kann nicht buchen. Clockodo erzwingt dies
auch serverseitig (POST als eigener User-Account).

**Airtable-Schema (live in `appuVMh3KDfKw4OoQ` seit 2026-06-28):**
- `Clockodo-Nutzer` (`tblPbly2br8mR2kaU`) — 4 Records mit Feld
  `Airtable-Entwurf-Tabelle` (`fldsoeQHWDmbBt7FM`) → zeigt auf persönl. EW-Tabelle.
- `Clockodo-EW-Johannes` (`tbl4vZ2UFyeTRD8hd`) — persönliche Arbeitstabelle.
- `Clockodo-EW-Jilliana` (`tblXQIDrvPVN9ijI9`) — persönliche Arbeitstabelle.
- `Clockodo-EW-Daniel`   (`tblNDVve3jjJ9s8HB`) — persönliche Arbeitstabelle.
- `Clockodo-EW-Frauke`   (`tblRrqIQZmm2DosJT`) — persönliche Arbeitstabelle.
  Felder je EW-Tabelle: Datum, Von, Bis, Dauer-h, Projekt, Kunden-ID,
  Leistung, Leistungs-ID, Notiz, Billable, KW, Quelle, Status.
- `Clockodo-Buchungen` (`tblYQxlauwej7FD1w`) — Master-Audit-Log nach Bestätigung.
- `Clockodo-Leistungen` (`tblRtsegocdpM8CJd`) — bereits befüllt (8 Services).
- `Kunden.Clockodo-Kunden-ID` — gemappt für 10 von 30 Kunden.

**6-Schichten-Architektur (Code pending):**
1. **Intent Layer**: `ClaudeConversationEngine` neuer Intent `clockodoDraft`,
   extrahiert Dauer + Leistungstyp + Kunden-/Projektreferenz aus Freitext.
2. **Resolution Layer**: `ClockodoDraftResolver` → Airtable-Lookup → echte IDs.
   Fallback bei unbekanntem Kunden: "Mykilos GmbH intern" + Freitext.
   Mehrdeutigkeit → Assistent fragt nach, kein stilles Raten.
3. **Draft Store — Dual**: `ClockodoDraftEntry` (GRDB lokal, user-scoped) +
   Sync → persönliche `Clockodo-EW-{Name}`-Tabelle in Airtable.
   EW-Tabellen-ID kommt aus `Clockodo-Nutzer.Airtable-Entwurf-Tabelle`.
4. **Zwei UI-Orte (beides)**:
   - ClockodoWidget (Heute-Seite): Quick-Add-Sheet + Wochenbalken, kompakt.
   - Zeiten-Tab (Chat-Assistent): NLP-Eingabe, Detailansicht KW, Wochenabschluss.
5. **Confirm → POST**: Bestätigung → `POST /api/v2/entries` mit User-Creds →
   `AuditEntry` (GRDB) + Record in `Clockodo-Buchungen` (Airtable Master-Log).
   EW-Tabelle-Status → "Gebucht". Nie automatisch buchen.
6. **Mail/Kalender-Vorschläge**: Claude liest Gmail + GCal → schlägt Drafts vor
   (quelle: `.calendar`/`.mail`). Gleicher Bestätigungs-Pfad.

**API-Status:** `POST /api/v2/entries` aktiv. `GET /api/v2/clock` aktiv (Timer-Check).
Pflichtfelder POST: `customers_id`, `services_id`, `time_since`, `time_until`, `billable`.

**Offene Entscheidungen vor Implementierung:**
- Wo sitzt die Wochenvorschau? (Neuer Chat-Tab "Zeiten" vs. ClockodoWidget-Erweiterung)
- Format `time_since`/`time_until`: UTC oder lokale TZ? (Clockodo-Dokumentation prüfen)
- Airtable-Schreibrecht für `Clockodo-Buchungen` nach Confirm: welcher Client?
  (Bestehender `AirtableClient` kann Records anlegen — testen)

---

## Partner-App: Kalkulation & Preisschätzung

### 📋 Shared-Airtable-Schema + Merge-Plan (KalkulationsApp)
**Quelle:** User-Entscheidung 2026-06-28. Eine Partner-App für Kalkulation
und Preisschätzung soll gleichberechtigt auf dieselbe Airtable-Base schreiben.
Ein späterer Merge beider Apps ist geplant.

**Status:** Schema vollständig in Airtable angelegt und dokumentiert.
Details: [PARTNER_APP_SCHEMA.md](PARTNER_APP_SCHEMA.md)

**Ownership-Modell (wer schreibt wohin):**
- mykilOS SCHREIBT: Kunden, Projekte, Kontakte, Clockodo-* (alle)
- KalkulationsApp SCHREIBT: Kalkulationen, Kalkulations-Positionen
- BEIDE LESEN: alles

**Neue Airtable-Tabellen (live seit 2026-06-28):**
- `Kalkulationen` (`tblO3y2jdmxDnuiZj`) — Projektkostenrahmen und Angebote.
  Felder: Bezeichnung, Projekt-Nr, Datum, Gültig bis, Status, Gesamt-netto,
  Mehrwertsteuer, Gesamt-brutto, Notiz, App-Quelle.
- `Kalkulations-Positionen` (`tblNamx3cHTus6gtk`) — Einzelpositionen je Kalkulation.
  Felder: Bezeichnung, Kalkulation (Link), Kategorie (Honorar/Material/…),
  Leistung (Link → Clockodo-Leistungen), Menge, Einheit, Stundensatz-Snapshot,
  Einzelpreis, Gesamt, Notiz.

**Neue Felder in bestehenden Tabellen:**
- `Clockodo-Leistungen.Stundensatz (€/h)` (`fld4NBokj4MoOy8Uq`) — von beiden Apps gelesen.
  **Noch leer — Büro-Stundensätze eintragen.**
- `Clockodo-Nutzer.Stundensatz-Override (€/h)` (`fld9Ljvdo20qCwKIe`) — user-spezifische Rate.
  Priorität: Override > Leistungs-Stundensatz.

**Merge-Readiness:**
- Keine App-Präfixe in Tabellennamen nötig (schon merge-fähig)
- Linked Records über echte Airtable-IDs
- Keine Datenmigration beim Merge — Code liest beide Tabellensätze

**Noch offen:**
- Stundensätze für die 8 Leistungsarten manuell eintragen (Bürogeheimnis).
- Architektur der KalkulationsApp selbst (separates Repo/Projekt).

---

## Assistent-Ausbau (großer Block, eigenes Dokument)

### 📋 Vollständiger Such-/Schreib-Ausbau des Assistenten
**Quelle:** User-Wunsch 2026-06-27. Mail/Kalender/Drive komplett durchsuchen,
Projektordner+Unterordner crawlen, Mail-Entwürfe, echtes Kalender-Schreiben,
Notizen-Verwaltung, Clockodo-Vorbereitung, Kontakt-/Bild-/Angebots-Suche.
Vollständig zerlegt in [ASSISTANT_CAPABILITIES_PLAN.md](ASSISTANT_CAPABILITIES_PLAN.md)
(7 Lese-Punkte, 5 Schreib-Punkte, Reihenfolge-Empfehlung, zwei offene
Entscheidungen: Google-Scope-Erweiterung für Mail/Kalender-Write, und ob
Clockodo wirklich nur "vorbereiten" bleibt statt selbst zu buchen).

---

## Airtable-Infrastruktur

### ✅ Workspace-Plan: Team (bezahlt) — kein Handlungsbedarf
**Quelle:** Live-Check 2026-06-28 (Airtable-Bereinigungssession).
**Status:** "Mein erster Workspace" läuft auf **Team-Plan (monatlich)** mit AmEx ****3007.
Limits: 50.000 Records/Base (aktuell 13.444), 20 GB Anhänge, 100.000 API-Calls/Monat.
Kein Verschieben der Mastermind-Base nötig. Kein Upgrade nötig.

### ✅ Zulieferpreise (3.383 Beobachtungen): lokal in SQLite — nicht in Airtable
**Quelle:** Expertise-Entscheidung 2026-06-28 (Airtable-Bereinigungssession).
**Entscheidung:** Die mykilO$$-Rohbeobachtungen bleiben lokal. Die V2-Swift-
Destillationspipeline verarbeitet sie in `learning.sqlite` → App liest daraus.
Die existierende `Preis-Beobachtungen`-Tabelle in Mastermind bleibt als Archiv,
ist aber kein operativer Datenpfad.
**Grund:** Rohdaten für ML-Pipeline gehören nicht in Airtable. 3.383 Records × Sync-
Logik × kein Edit-Bedarf = unnötige Komplexität. SQLite ist direkt und schnell.

### ✅ Stundensätze + Bases-Struktur entschieden
**Quelle:** Airtable-Bereinigungssession 2026-06-28.
**Stundensätze:** Airtable als Master (`Clockodo-Leistungen.Stundensatz`), GRDB als Cache.
App sync't beim Start, Kalkulationsmodul liest lokal. Keine doppelte Pflege.
**Bases:** 1 Base bleibt — Mastermind `appuVMh3KDfKw4OoQ`. Kein Split geplant.
Alte Base `appkPzoEiI5eSMkNK` ist stillgelegt — nie anfassen.

### 🚧 Stundensätze — Schätzwerte eingetragen, echte Werte stehen aus (Johannes-Aktion)
**Quelle:** PARTNER_APP_SCHEMA.md offener Punkt, bestätigt 2026-06-28. **Update 2026-07-01
(M5, Konsolidierung):** `Clockodo-Leistungen.Stundensatz (€/h)` war leer und blockierte damit
JEDE Kalkulation (leerer Wert statt Platzhalter). Auf Johannes' Wunsch jetzt mit runden
Schätzwerten befüllt (60–100 €/h, nach Leistungsart gestaffelt: Kundenberatung/Konzeption-CAD
am höchsten, interne Arbeitszeit am niedrigsten) — bewusst nur direkt in Airtable, keine
Schreib-UI in der App (Bürogeheimnis-Regel bleibt: Werte nie in Code/Docs).
**Aktion (weiterhin offen):** Johannes ersetzt die Schätzwerte direkt in Airtable durch die
echten Büro-Stundensätze, sobald er Zeit hat — kein Zeitdruck, das Kalkulationsmodul rechnet
bis dahin mit plausiblen Platzhaltern statt gar nicht.

---

## Architektur & Datenfluss

### 💡 Multi-Base-Architektur v2 + zentrale Datenweichen-Router-Tabelle
**Quelle:** Johannes, 2026-06-30 (während mykilOS 8 Block A). Johannes hat 17 neue, domänen-
getrennte Airtable-Bases angelegt: `mykilOS_Projekte`, `mykilOS_Datenweichen`,
`mykilOS_Handelswaren`, `mykilOS_Onlineshop & Verkauf`, `mykilOS_App Entwicklung`,
`mykilOS_Rechnungen IN`/`OUT`, `mykilOS_Angebote IN`/`OUT`, `mykilOS_Fragebogen & Projekt IN`,
`mykilOS_Adapter ClickUp`/`Slack`/`Sevdesk`/`GoogleDrive`/`Weclapp`, `mykilOS_TRESOR` — sichtbar
über den `list_bases`-Meta-Endpoint mit dem App-PAT, nicht über den Standard-Airtable-MCP.

**Frage:** lohnt sich der Umbau auf Domänen-Bases + eine zentrale Master-/Router-Tabelle, die
maschinenlesbar führt, welche Base/Tabelle für welches Datum die SoR ist (die `Datenstrom-
Handbuch`-Idee konsequent zu Ende gedacht — die App liest Routing-Entscheidungen dann aus dieser
Tabelle statt aus hartcodierten `AirtableClient.writableMap`-Konstanten)?

**Einschätzung:** architektonisch richtig — ein Adapter pro externem System trennt sauber
externe Spiegelung von Geschäftsdaten, genau die Trennung, die den Mastermind↔Artikel-Konflikt
aus Block A verursacht hat (siehe oben). **Umfang ≥ Block C/D, eigener Strang:** 17 Schemata
lesen+verstehen, SoR-Karte v2 entwerfen, gesamtes App-Routing umschreiben (`writableMap`,
`mapProjects`/`mapCustomers`, `ExternalMappingRegistry`, `CartStore`, Intake-Schreibpfad), dazu
intensive Live-Tests (von Johannes selbst gefordert). **Bewusst NICHT in Block A angefasst** —
keine Daten geschrieben/migriert, reine Erkundung.

**Hinweis:** die alte tabu-Base `appkPzoEiI5eSMkNK` (Zuliefererpreise Schätzung) ist über den
App-PAT jetzt ebenfalls sichtbar (gleicher Token, breiterer Zugriff) — das **NO-GO bleibt
unverändert in Kraft**, Sichtbarkeit ist keine Erlaubnis.

**Plan:** erster Schritt einer künftigen, voll budgetierten Session — alle 17 Schemata
domänenweise lesen, Verständnis-Report + konkreten Router-Tabellen-Vorschlag liefern, Johannes
entscheidet, was von Mastermind/Artikel-Base abgelöst wird vs. koexistiert, erst dann bauen.

**🚧 Erster konkreter Schritt getan (2026-07-01, M4-Vertagung):** `mykilOS_Adapter Sevdesk`
(`appcSjFNs1knLeM3G`) hatte noch die unangetastete Airtable-Standardvorlage — jetzt eine Tabelle
`IO-Register` (`tblE8uvRt8nI4utD4`) angelegt, Schema an das bestehende Datenstrom-Handbuch
angelehnt, mit einem Platzhalter-Eintrag `SEVDESK_ADAPTER_IO` (Status „Ausgeklammert", NO-GO
„NIE schreiben") — spiegelt den bestehenden `SEVDESK_INVOICES`-Eintrag im zentralen Datenstrom-
Handbuch, ist aber noch nicht an echten App-Code angebunden. Reine Doku/Struktur-Vorbereitung,
keine Code-Änderung. Bewusst nur DIESE eine Adapter-Base angefasst, nicht alle 17 — der große
Umbau bleibt wie oben beschrieben ein eigener, größerer Strang.

**Performance/Caching-Frage geklärt (2026-06-30):** mehr Bases machen die App NICHT langsamer,
solange das bestehende Lokal-Cache-Muster beibehalten wird (UI liest nie live von Airtable,
immer aus `CachedProjectRegistry`/`CachedBusinessRegistry`/künftigem Artikel-Spiegel — Kosten
skalieren mit Datensätzen pro Sync, nicht mit Anzahl Bases). **Johannes' Entscheidung: Webhook-
basiertes Push ist der bevorzugte Weg** (nicht nur Intervall-Polling) — heißt: für die
Umsetzung braucht es einen kleinen Relay-Server mit öffentlich erreichbarer HTTPS-URL, der
Airtable-Automations/Webhooks empfängt und an die App weiterreicht (eine lokale Mac-App kann
selbst keine Webhook-Ziel-URL sein). **Für die nächste Session vorzubereiten/abzustimmen:** wo
läuft der Relay (eigener kleiner Cloud-Dienst?), wie meldet sich die App dort an, Fallback auf
Polling falls die App offline ist/der Relay nicht erreichbar ist. Sofort-Sync nach eigenem
Write (wie heute bei Intake) bleibt davon unabhängig zusätzlich bestehen. **Push heißt lokal
aktualisieren** (Johannes, 2026-06-30): ein eingehendes Webhook-Event muss den jeweiligen lokalen
Cache (GRDB/FileBackedRepository) genauso befüllen wie ein normaler Sync — der Relay liefert nur
den Auslöse-Impuls „etwas hat sich geändert", die App holt/cached danach wie gewohnt über die
bestehenden `sync(...)`-Pfade. Kein separater Schreibweg am Cache vorbei.

**Weiterer Ausbau angekündigt (Johannes, 2026-06-30):** es wird später zusätzlich eine
**intelligente Alerts-Logik** geben, gestützt auf eigene Airtable-Base(s) für Alerts/Regeln —
Details (welche Trigger, welche Schwellenwerte, wohin gemeldet) noch offen, in der nächsten
vollen Session mit dem Multi-Base-Strang gemeinsam abstimmen.

### 🚨 Budget hat HEUTE zwei Quellen (Mastermind `Project.links.budget` vs. Artikel `BusinessProject.budget`)
**Quelle:** mykilOS 8 Block A, S0-Audit (2026-06-30), code-verifiziert. `CashWidget` liest
`project.links.budget` aus dem Mastermind-Cache (Soll-Wert für den Ist-vs-Budget-Balken). Die
neue `ExternalMappingRegistry` (Block A) liest Budget aus der Artikel-Base als die eigentliche
Geschäfts-Wahrheit (siehe SoR-Karte in `AIRTABLE_DATENFLUSS_AUDIT.md` §3) — beide Felder existieren
parallel und können auseinanderlaufen. **Bewusst NICHT in Block A gefixt** (CashWidget-Umbau wäre
Scope-Creep + Layout-/Regressionsrisiko außerhalb des Block-A-Auftrags). **Plan:** sobald
Geschäftsprojekte über die Projektnummer gebunden sind (siehe `businessOnlyUnbound`-Eintrag
darunter), `CashWidget` auf `ExternalMappingRegistry.resolve(...).business?.budget` umstellen und
`Project.links.budget` als reinen Altlast-Fallback behandeln oder entfernen.

### 🚨 Artikel-Base `Projekte` hat kein `Projektnummer`-Feld → neue Geschäftsprojekte sind unverbindbar
**Quelle:** mykilOS 8 Block A, S0-Audit (2026-06-30), code-verifiziert (Feldnamen aus
`IntakeResultBuilder.mapProjektFelder`: `Projektname`/`Projektstatus`/`Budget`/Adresse — kein
Nummernfeld). `ExternalMappingRegistry` markiert solche Records als `businessOnlyUnbound`
(abrufbar über `unboundBusinessProjects()`).

**Entschieden (Johannes, 2026-06-30):** KEIN Projektname-Fuzzy-Match als Workaround — zu
gefährlich bei Geld-/Statusdaten. Stattdessen exakt das Gegenteil von „selbst reparieren": die
**bestehende Artikel-Projektliste wird von mykilOS/Claude NIE editiert** — weder Schema (neues
Feld) noch Daten (Bestandsrecords). Das ist und bleibt **Daniels Backend-Hoheit** (siehe
`AGENTS.md` „Wer darf was"). Folge: das Feld kommt, wenn Daniel es anlegt — kein Zeitdruck von
unserer Seite, kein Workaround drumherum. Neue Projekte, die Block C (Nomenklatur) zukünftig
selbst per gated CREATE anlegt, können die Projektnummer beim Anlegen mitschreiben, SOBALD das
Feld existiert — das ist kein „Editieren bestehender Daten", sondern ein neues, eigenes CREATE.
Bis dahin bleibt `businessOnlyUnbound` der ehrliche, dauerhafte Zustand für unverbundene
Bestandsprojekte — keine Eile, kein Drängen auf Daniel.

### 📋 ClickUp als Quelle für `ProjectKind`
**Quelle:** Live-Wiring-Session 1 (2026-06-27). Drive-Ordnernamen lassen
`ProjectKind` (kitchen/lighting/addendum/lead/quote) nicht erkennen.
**Plan:** Handle/Link-Konnektor (ClickUp-Listen-ID pro Projekt, Feld
`ClickUp-Liste` existiert bereits in `Project.links` und in der Airtable-
Tabelle `Projekte`) + eine Übersetzungsregistry, die ClickUp-Daten auf
`ProjectKind` mapped. Der neue ClickUp-Sandbox-Space "MYKILOS API
TESTSPACE" (`90128024109`) ist der vorgesehene Testort dafür.
**Noch offen:** genaues Mapping-Schema (welches ClickUp-Feld/Status/Tag
→ welcher `ProjectKind`) ist nicht entschieden.

### 📋 Archiv-Übersetzungsregistry für `_PROJEKTE_ARCHIV`
**Quelle:** Live-Wiring-Session 1. ~200+ archivierte Projektordner
(2018–2026) mit komplett anderem, uneinheitlichem Namensschema
(Standort-Präfixe `B_`/`HH_`/`K_`/`WI_` statt `JJJJ_lfdNr_Kunde`), mehrfach
verschachtelte Jahres-Unterordner.
**Plan:** eigener Namens-Mapping-Parser fürs alte Schema + Airtable-Tabelle
`Archiv-Übersetzung` (Schema bereits angelegt: Alter Ordnername, Vermutete
Projektnummer, Jahr, Standort-Präfix, Status — aktuell leer, 0 Records).
**Bewusst zurückgestellt**, kein Termin.

### 💡 "Drive-Ordner anlegen"-Automatisierung über ClickUp
**Quelle:** Beim Connector-Recheck dieser Session im ClickUp-Sandbox
entdeckt — die Test-Liste "KUE-2026-014 Küche Müller TEST" hat bereits ein
Custom Field `Drive-Ordner anlegen` (Checkbox) angelegt.
**Noch offen:** Was genau soll dieser Trigger tun? (Vermutung: neuer
ClickUp-Task mit Checkbox aktiviert → Drive-Ordner für neues Projekt
automatisch anlegen, inkl. Unterordner-Struktur `00 INFOS`/`02 CAD`/
`03 PRÄSENTATION`/`04`/`05`.) Mit dem User klären, bevor das gebaut wird —
das wäre der erste echte **Schreibzugriff** auf Drive (aktuell strikt
read-only laut NO-GO).

### 💡 Drei-Kopien-Redundanzmodell — vierte Frage: was wenn Airtable wechselt?
**Quelle:** User-Kommentar dieser Session: *"Wir brauchen Redundanz [...]
Airtable bleibt evtl. nicht der permanente Hub, ein anderes Tool könnte es
später ersetzen."* Umgesetzt: 3 Kopien (Airtable/lokaler Cache/Git-JSON,
siehe `docs/registry/README.md`).
**Noch offen / Idee:** Falls Airtable tatsächlich ersetzt wird — welches
Tool käme infrage, und müsste die App (`AirtableClient`/`AirtableRegistry`)
dann durch eine generische Sync-Schnittstelle ersetzt werden, damit nicht
wieder hartkodierter Airtable-Code überall verteilt ist? Reine Idee, keine
Entscheidung.

---

## Neue Tabs / Oberflächen

### 📋 Zeichnungen-Tab mit PDF-Vorschau
**Quelle:** User-Entscheidung in dieser Session. Neuer Projekt-Tab, Quelle
`02 CAD`-Unterordner. Technisch unklarster Punkt: PDF-Vorschau in SwiftUI
(QuickLook/PDFKit), vermutlich echter Datei-Download nötig (aktuell wird
bei Drive nur `webViewLink` im Browser geöffnet, kein Download/Cache).
Details: [HANDOFF_LIVE_WIRING_1.md](handoffs/HANDOFF_LIVE_WIRING_1.md)
Abschnitt 5a, Schritt D.

### 📋 Material-Tab
**Quelle:** User-Entscheidung. Quelle `03 PRÄSENTATION`-Unterordner,
vermutlich einfache Dateiliste wie Angebote-Tab, kein PDF-Vorschau-Bedarf.

### 💡 Abnahme-Bereich für Abnahmeprotokoll
**Quelle:** User-Wunsch, am wenigsten konkret. Noch keine Drive-Quelle
zugeordnet — ungeklärt, ob eigener Unterordner oder eigenes Datenmodell
(strukturiertes Formular statt Dateiliste). **Mit dem User klären, bevor
Umsetzung beginnt.**

### 💡 Timeline-Tab — Calendar jetzt, ClickUp später
**Quelle:** User-Entscheidung in dieser Session. Aktuell `ComingTabView`-
Platzhalter. Phase 1: Google Calendar (bestehender `GoogleCalendarClient`,
`calendarQuery`). Phase 2 (nicht terminiert): ClickUp-Aufgaben mit
Fälligkeitsdatum einblenden, sobald Aufgabe "ClickUp-Handle für
ProjectKind" (oben) steht und die Datenqualität dafür ausreicht.

---

## Bugs (real, kein Feature-Wunsch)

### ✅ Hartkodierte Demo-Werte in drei Widgets — behoben
**Quelle:** Code-Audit in Live-Wiring-Session 1. **Behoben 2026-06-27.**
- `ProjectHeroView.swift` — Budget-Balken zeigt jetzt echtes Airtable-Budget
  oder gar nichts (kein Fake-72-%-Wert mehr).
- `FocusWidget.swift` — nutzt echte `projectID` + Registry-Lookup für Titel.
- `CashWidget.swift` — liest echten Signal-Label aus `.reviewSuggested`,
  "In Review übernehmen" schreibt in `AuditStore` (persistiert über Neustarts).

### ✅ Demo-Signal-Buttons emittieren Fake-Signale — behoben
**Quelle:** Code-Audit. **Behoben 2026-06-27.**
`SignalDemoView.swift` (Projektdetail) und `HomeForcePollButton` (Heute-Board)
lösen jetzt echten `DriveOfferWatcher.poll(...)` mit echter `projectID` aus
statt ein hartkodiertes Fake-Signal für `"ME-24"` zu emittieren.

### ✅ RecentActivityWidget zeigt Demo-Daten — behoben
**Quelle:** Code-Audit 2026-06-27. **Behoben 2026-06-27.**
Das Widget zeigte immer dieselben drei erfundenen Einträge ("Zeichnung
Bartresen_v3.pdf · MEYER" etc.) ohne reale Datenquelle. Fix: sauberer
Empty-State statt Demo-Content; echte Implementierung folgt sobald
Drive-Change-Tracking und ClickUp-Listen-IDs umgesetzt sind.

---

## Bekannte offene technische Fragen (nicht terminiert)

### 💡 Google "Desktop App"-OAuth — `client_secret` nötig?
**Quelle:** Seit Akt 3, Schritt 1 offen. Ob Googles "Desktop App"-Client-
Typ bei PKCE zusätzlich ein `client_secret` verlangt, ist nie live
getestet worden (V5 unterstützte es optional). Falls beim ersten echten
Verbinden `invalid_client` auftritt: `clientSecret`-Parameter in
`GoogleOAuthPKCEService` nachziehen.

### 💡 "Nie verbunden" vs. "Sitzung abgelaufen" bei Google-Refresh
**Quelle:** Seit Schritt 3 offen, bewusst für V1 zusammengefasst (beide
zeigen `.permissionRequired`). Ein eigener `.authExpired`-State wäre für
V1 Over-Engineering — als Idee hier vermerkt, falls es in der Praxis doch
zu Verwirrung führt.

### 💡 Airtable-MCP-Connector ohne Record-Write
**Quelle:** Live-Wiring-Session 1 — `create_records_for_table` existiert im
aktuellen Connector-Toolset nicht (nur Schema-Tools). Workaround per
Personal-Access-Token + lokalem `curl`-Skript funktioniert, ist aber kein
dauerhaft eingebauter App-Mechanismus. Falls der Connector das später
nachrüstet: Workaround obsolet, aber unkritisch.

### 📋 Airtable-Automation gegen doppelte Projektnummer (Rezept, nicht gebaut)
**Quelle:** 2026-07-01, Nachgang zur Kollisionshärtung (`44270bb`). Die
App-seitige Live-Drive-Kollisionsprüfung (`reserviereKollisionsfreieNummer`)
schließt nur die Lücke "Drive-Ordner ohne Airtable-Zeile". Zwei doppelte
Airtable-**Zeilen** mit derselben Projektnummer (z. B. durch einen manuellen
Airtable-Edit) erkennt sie nicht — das bräuchte eine Airtable-native
Automation. Mein Airtable-MCP-Toolset kann den Automation-Editor nicht
ansteuern (nur Base/Tabelle/Feld/Record-CRUD), daher hier als manuelles
Rezept für den Airtable-Automation-Editor (Web-UI, Base "mykilOS Mastermind"
→ Automations → "+ Create automation"):
1. **Trigger:** "When a record is updated" → Tabelle `Projekte`, beobachtetes
   Feld `Projektnummer`.
2. **Action 1 — Find records:** Tabelle `Projekte`, Filter
   `Projektnummer = {Trigger record → Projektnummer}`, Sortierung egal.
3. **Action 2 — Condition:** nur fortfahren, wenn "Find records" **mehr als
   1** Treffer liefert (sonst ist es die triggernde Zeile selbst).
4. **Action 3 — Send email/Slack-Nachricht** (oder ein Feld `Duplikat-
   Warnung` per "Update record" setzen): Text z. B. "Doppelte Projektnummer
   {Projektnummer} in {Anzahl Treffer} Zeilen — bitte manuell klären."
Ergänzt das bereits gebaute `Format-Check`-Formelfeld (prüft nur die eigene
Zeile gegen das `JJJJ_NNN_...`-Schema, siehe BENUTZERHANDBUCH.md) um den
zeilenübergreifenden Fall. Aufwand ca. 10 Minuten im Airtable-UI, nicht
terminiert — bei Bedarf einfach nachbauen.

---

## Security & Onboarding

### 📋 User-Identität nach Google-Login
**Quelle:** Team-Review 2026-06-28 (S10 Learning Session).
**Problem:** Nach erfolgreichem Google-Login weiß die App nicht wer eingeloggt ist.
Kein Name, keine E-Mail, kein Avatar sichtbar. Nutzer kann nicht erkennen ob er mit
dem richtigen Account verbunden ist — Onboarding-Killer und latentes Sicherheitsproblem.
**Plan (Session A aus MASTER_HANDOFF_CODEX.md):**
`GoogleAuthService` → nach Token-Tausch `GET /oauth2/v2/userinfo` → `GoogleUserInfo(email, displayName)`
→ Keychain-Cache → `AppState.currentGoogleUser` → Anzeige in `SidebarView` unten.
Test: `GoogleUserInfoTests` — JSON-Parsing ohne Netzwerk.

### 🔴 Keychain-Bug: `baseID` enthält PAT statt Base-ID
**Quelle:** Bekannt seit Post-Akt-5, bestätigt 2026-06-28.
**Problem:** Im Keychain-Feld `baseID` (Service `com.mykilos6.airtable`) steht
fälschlicherweise ein zweites PAT-Token statt der Base-ID `appuVMh3KDfKw4OoQ`.
Airtable-Sync schlägt still fehl — kein Nutzer kann das selbst debuggen.
**Fix:** Validierung beim Speichern in Settings (`baseID` muss mit `app` beginnen) +
klare Fehlermeldung. Sofortmaßnahme: manuell in App-Einstellungen → Airtable
Base-ID-Feld → `appuVMh3KDfKw4OoQ` eintragen.

### ✅ `AirtableSyncService.swift` löschen — bereits erledigt
**Quelle:** Code-Audit S10/S12 2026-06-28. **Nachtrag 2026-07-01:** beim Aufräum-Durchgang
geprüft — die Datei existiert nicht mehr im Repo, `git log --all` findet keinen einzigen
Commit dazu (offenbar nie tatsächlich eingecheckt oder in einer früheren, nicht dokumentierten
Session bereits entfernt). Kein Handlungsbedarf mehr, Backlog-Eintrag war veraltet.

### 💡 Onboarding-Flow für neue Nutzer
**Quelle:** Team-Review 2026-06-28 (S10 Learning Session).
**Problem:** Neuer Nutzer öffnet die App → sieht Demo-Projekte → weiß nicht was er
verbinden soll oder in welcher Reihenfolge. Kein geführter Einstieg.
**Idee:** "Erste Schritte"-Checklist in Settings oder Launch-Screen beim ersten Start:
1. Google-Account verbinden → 2. Airtable-Base eintragen → 3. Clockodo-Key (optional)
→ 4. Claude API-Key (optional). Fortschrittsanzeige pro Schritt.

### 💡 SQLite-Backup / Archiv-Log
**Quelle:** Team-Review 2026-06-28.
**Problem:** GRDB-Datenbank liegt in `Application Support` — kein automatisches Backup.
Wenn jemand die App löscht oder die DB korrupt wird, ist der gesamte Audit-Log weg.
**Idee:** Täglicher automatischer SQLite-Snapshot nach
`~/Library/Application Support/mykilOS/Backups/YYYY-MM-DD.sqlite`.
Maximal 30 Snapshots behalten (älteste löschen). "Backup wiederherstellen"-Option in Settings.

### 💡 Crash-Reporting
**Quelle:** Team-Review 2026-06-28.
**Problem:** Kein Crash-Reporting-System vorhanden. Abstürze werden nur bekannt wenn
der Nutzer sie meldet.
**Idee:** Optionen abwiegen — macOS-native (`NSApplication.shared.reportException` +
lokales Crash-Log in `Application Support`) vs. leichtgewichtiger externer Dienst
(Sentry o.ä.). Wichtig: local-first-Prinzip — keine Daten nach außen ohne explizite
Nutzer-Zustimmung. Mindestlösung: Crash-Log lokal schreiben + "Fehlerprotokoll zeigen"-
Button in Settings.

### 💡 Cache-Management
**Quelle:** Team-Review 2026-06-28.
**Problem:** Google/Airtable-Daten werden in GRDB gecacht, aber kein TTL definiert,
kein "Cache leeren"-Button in Settings. Kein explizites Cache-Management.
**Idee:** "Cache leeren"-Option in Settings pro Integration (Google / Airtable).
TTL pro Datentyp definieren (z.B. Drive-Dateiliste: 5 Min, Kalender: 15 Min,
Kontakte: 1 Stunde). Offline-Indikator wenn Cache veraltet ist.

---

## Hinweis für zukünftige Sessions

Dieses Dokument ist **additiv** — neue Ideen unten/in der passenden
Sektion ergänzen, Status bei Fortschritt ändern, nichts löschen (außer bei
❌ Verworfen kurz die Begründung ergänzen und stehen lassen, das ist auch
eine Information). Wenn ein Punkt in einem Handoff im Detail beschrieben
ist, hier nur kurz zusammenfassen + verlinken, nicht duplizieren.

### 💡 Kataloge selbst-konfigurierbar wie Widgets (Johannes, 2026-07-02)
Die Kataloge-Tabs sollen sich pro User **individuell aufziehen** — analog zum Widget-Selektor:
- Jeder User **aktiviert/deaktiviert**, welche Kataloge in *seiner* Ansicht erscheinen (nicht
  jeder muss alle sehen).
- **Reihenfolge** selbst bestimmen (Drag ist teils da via `kataloge.taborder`, aber das
  Ein-/Ausblenden pro Katalog fehlt).
- Umsetzung: ein „Kataloge"-Selektor wie `WidgetSelectorView` (Ein/Aus + Reihenfolge),
  persistent (@AppStorage/lokal, per User). Skaliert mit den wachsenden Katalog-Quellen
  (Artikel/Lager/Warenkörbe/Angebote/Kontakte/Notizen/Aufgaben + Bilderdatenbank/Doku-Template/
  Textbausteine/Zeichnungen/Shopify …).

### 🌈 Easter Egg: „Crazy"-Mode (eigenes Theme) — Johannes 2026-07-02
Bei Erscheinungsbild (Hell/Dunkel/System) ein **viertes Regenbogen-Icon = „Crazy"** anbieten.
Aktiviert einen **User-eigenen Theme-Editor**: Farbwähler für Text/Hintergründe/Akzente — der
Nutzer stellt sich seine eigenen **Farb-Swatches** für SEINE Ansicht zusammen.
- Rein lokal (@AppStorage, pro User), nur die eigene Ansicht — kein geteilter Zustand.
- Umsetzung: ein Opt-in-**Override-Layer** über den MykColor-Tokens zur Laufzeit (Default = CI
  bleibt unangetastet; die Token-Disziplin/SwiftLint gilt weiter, „Crazy" ist ein Runtime-Override).
- Spaß-Feature, „für später oder wenn es passt". Schöner Vertrauensbeweis: local-first heißt auch
  „deine App, deine Farben".

### 🎉 Easter-Egg-Sammlung — alles hinter EINEM Opt-in „Spaß-Mode" (Johannes 2026-07-02)
Grundregel: **ein Schalter in Settings** („Spaß-Mode / Easter Eggs") — Default AUS. Nichts davon
stört den professionellen Betrieb; erst der Opt-in weckt die Spielereien. Dezent, kurz, nie im Weg.

**Assistent / Kalkulation:**
- 💶 **Cash-Regen/GIF**, wenn eine Küchenschätzung reinkommt — Intensität ~ Höhe der Schätzung
  (kleine Summe = ein paar Scheine, große = kurzer Geldregen). Dann sofort weg.
- 🦆 „Rubber-Duck"-Aside: seltener, trockener Einzeiler des Assistenten („…schöne Marge übrigens.").
- 🎯 Wenn eine Schätzung auf eine runde/lustige Zahl fällt → Mini-Zwinkern.

**Momente / Meilensteine:**
- 🥂 **Konfetti**, wenn ein Projekt in die Stufe „Abschluss" wandert (Pipeline-Board).
- ✉️ Kleiner Funken, wenn die **erste echte Mail** gesendet wird (S3).
- 🛒 Warenkorb erreicht viele Positionen → kurzer „voll beladen"-Wackler.
- 🌙 **Feierabend-Zen:** wenn alle Aufgaben abgehakt / Inbox leer → ruhiger Glückwunsch-Moment.

**Versteckt / klassisch:**
- ⬆️⬆️⬇️⬇️⬅️➡️⬅️➡️ **Konami-Code** → schaltet den „Crazy"-Theme-Editor (🌈) frei.
- 🔢 Versionsnummer im About-Fenster N-mal klicken → Credits / Augenzwinkern.
- ❄️ Dezent saisonal (z. B. minimaler Schnee im Dezember) — sehr subtil.

**Ton (optional, extra Unter-Schalter):**
- 🔔 Feiner Chime bei Speichern/Bestätigen (nur wenn zusätzlich aktiviert).
- 💡 **Erweiterung — Sound-Bibliothek pro User + Notification-Kategorie (Johannes 2026-07-02
  spät):** kleine Auswahl an angenehmen, dezenten Chimes/Mini-Sounds, **je Kategorie separat
  wählbar** (Alerts, Wecker, Kalender, Timer, etc.) und **je User individuell** — volle
  Einstellungsmöglichkeit in Settings, nicht nur ein globaler An/Aus-Schalter. Gehört in dieselbe
  Datenschutz-/Settings-Sektion wie die Alert-Toggles
  ([[alerts-dezent-datenschutz-toggle-regel]]) — konsequent zu Ende gedacht: nicht nur OB ein
  Alert klingt, sondern WIE (welcher Sound aus der Bibliothek), pro Kategorie und pro Person.
- 📋 **Verbindende Infrastruktur — native macOS-Push-Benachrichtigungen (Johannes 2026-07-02
  spät):** echte System-Notifications wie gewohnt (Banner/Notification-Center), über Apples
  **`UserNotifications`-Framework** (`UNUserNotificationCenter`) — Standard-API, keine
  Unsicherheit, braucht nur einmalige `requestAuthorization`-Berechtigung. **Das ist der fehlende
  Zustellweg für ALLE heute geloggten Alert-Ideen** (Werkzeichnung/Nachfass/Kontakt-Erkennung/
  Bezahlt-Status-ungewiss/„Bitte reagieren") **und der Träger für die Sound-Bibliothek oben** —
  Kategorie + Sound + Ein/Aus-Toggle greifen direkt hier. Baut den Datenschutz-Toggle
  ([[alerts-dezent-datenschutz-toggle-regel]]) technisch um: pro Kategorie eigene
  `UNNotificationCategory`, System-Berechtigung einmal beim ersten Alert anfragen.
  **⚠️ Gilt nur für den Mac.** Aufs **Handy** braucht es echte zusätzliche Infrastruktur, die
  mykilOS heute nicht hat (kein Server, keine iOS-Companion-App) — drei realistische Wege,
  Aufwand steigend: **(a) Drittanbieter-Push-Relay** (Pushover/ntfy.sh — mykilOS macht einen
  HTTP-Call, Johannes nutzt deren bestehende Handy-App, kein eigener Server nötig, pragmatischster
  Einstieg); **(b) CloudKit + eigene schlanke iOS-App** (Apple übernimmt den Push-Mechanismus,
  aber eine iOS-App muss trotzdem gebaut werden); **(c) eigene APNs-Infrastruktur** (volle
  iOS-App + eigener Server mit Push-Zertifikaten — eigenständiges Entwicklungsprojekt, keine
  Erweiterung nebenbei). Für „einfach eine Nachricht aufs Handy" ist (a) der Einstieg.

Umsetzung: reine Overlay-/Animations-Schicht (SwiftUI transitions/particles), rein lokal, kein
Datenbezug, kein Audit-Rauschen. Neue Ideen hier ergänzen.

**Nachtrag Party/Team (Johannes 2026-07-02):**
- 🎊 **Party-Mode freitags:** dezent-wildes Blinken / Party-Overlay am Freitag (bei aktivem
  Spaß-Mode). Optional automatisch ab Freitagnachmittag oder manuell zuschaltbar.
- 🎂 **Geburtstags-Konfetti:** hat ein Teammitglied/Kontakt Geburtstag → Konfetti + kurzer
  Glückwunsch beim App-Start. Braucht ein **Geburtstagsdatum** an Profil/Kontakt (kleiner
  Daten-Job: Feld an UserProfile bzw. Airtable-Kontakt) — Datenschutz beachten (nur Team-Namen,
  keine sensiblen Daten). Auch ohne Datum baubar: manuell „heute hat X Geburtstag" markieren.
- 💡 **Futurefeature — Team-Meme-Ordner + Easter-Egg-Assistent (Johannes 2026-07-02):**
  Ein **gesyncter Drive-Ordner** ("Privat"-Bereich), den jeder Mitarbeiter per **Drag&Drop im
  Assistenten** mit GIFs, lustigen Bildern, Mini-Videos befüllen kann — gemeinsamer
  Team-Spaß-Fundus. Im **Easter-Egg-Modus** kann der Assistent auf Befehl ein zufälliges GIF/Bild
  zeigen, einen Witz erzählen oder einen „Projekt-Fail zum Lachen" ausspielen. Zusätzlich eine
  kleine **GIF-/Sticker-Sammlung**, die bei bestimmten **Projekt-Meilensteinen, ClickUp-Triggern,
  Geburtstagen oder Events** automatisch abgegriffen/ausgespielt wird — Anknüpfungspunkt an die
  Party-Mode/Konfetti-Ideen oben. Braucht: Drive-Ordner-Sync + Assistent-Datei-Drop (Muster schon
  vorhanden, siehe `AssistantChatView.onUploadFileToDrive`), Easter-Egg-Trigger-Logik, Verknüpfung
  an Signal-/ClickUp-Ereignisse. Rein spaßig, kein Datenbezug zu Geschäftsdaten — sollte NIE echte
  Projekt-/Kundendaten in ausgespielten „Fails" bloßstellen (Anonymisierung/Opt-in beachten).
- 💡 **Erweiterung — Casual-Mode-Toggle für kontextuelle GIF-Antworten (Johannes 2026-07-02
  spät):** ein Toggle „Casual Mode", das dem Assistenten erlaubt, **passende GIFs aus dem
  Team-Meme-Ordner kontextbezogen** in Antworten/Alerts einzustreuen — nicht nur auf expliziten
  Befehl („zeig mir was Lustiges"), sondern situativ im normalen Gesprächsfluss, wenn der Kontext
  passt. Braucht eine leichte Kontext→GIF-Zuordnung (Tags aus dem Meme-Ordner gegen Gesprächs-
  thema/Stimmung matchen) — kein Datenbezug zu Geschäftsdaten. **Gehört zur selben
  Datenschutz/Dezent-Familie wie Alerts** ([[alerts-dezent-datenschutz-toggle-regel]]) — eigener
  Ein/Aus-Schalter, standardmäßig aus, nie aufdringlich.

---

## Nachtrag 2026-07-02 spät — Massendaten-Miner + externe Zeichnungs-Integration

Aus der Wirbelsäulen-Session (S10-Blueprint-Arbeit). Vier verwandte „Massendaten
crawlen/taggen/zuordnen/sortieren"-Ideen für die künftigen Kataloge (§4 im
S10_WIRBELSAEULE.md nennt Textbausteine-/Bilderdatenbank-Katalog bereits vorgemerkt).
Werkzeug-Einordnung in [[massendaten-katalog-miner]] (Memory):

- 💡 **Textbausteine-Katalog aus Angeboten destillieren:** ähnliche/routine-bedeutende
  Formulierungen aus der Angebotsdatenbank clustern + sauber destillieren. **ChatGPT-web-
  geeignet** (reine Textmuster-Analyse auf exportierten eigenen Daten, kein Crawling, keine
  Rechte-Fragen) — einzige der vier Ideen, die sofort ohne Codex-Session anlaufen kann.
- 💡 **Preislisten + passender Weblink/Montage-PDF/Datenblatt/Maße/Produktbild pro Artikel
  massenhaft beschaffen.** Braucht echtes Web-Crawling + Rechte-Prüfung (Hersteller-IP,
  Fehl-Matching gefährlich) — **Codex-Strang**, deckt sich mit bereits bewertetem Handoff-Paket
  `CODEX_LOCAL_ONLY_SELF_TESTING_COMPLETENESS_LOOP_HANDOFF_v4.zip`
  ([[codex-handoffs-zuordnung]]), local-only, keine Prod-Writes.
- 💡 **Moodboard-PDFs aus den Projekt-Unterordnern nach Parametern matchen/filtern**, als
  eigener Katalog vorbereiten. Braucht echten Drive-Zugriff (read-only, unproblematisch) über
  hunderte Projektordner — **Codex-Strang**, gleicher Bauplan wie oben, andere Quelle (Drive
  statt Web).
- 💡 **Vectorworks-Planköpfe aus Checkout generieren + direkt senden (Johannes 2026-07-03,
  Erweiterung):** aus einem mykilOS-Checkout die **Plankopf-/Title-Block-Daten** eines Vectorworks-
  Plans befüllen (Kunde · Geräte · Materialien · Projektdaten) und direkt rausgeben/senden. Konkrete
  Ausprägung des Vectorworks-Ports (Port #17), eng verwandt mit „Geräteliste an Tischler" — statt
  eigenem Dokument werden hier die strukturierten Planköpfe eines CAD-Plans bespielt. **Vectorworks-
  Referenz-Screenshot** von Johannes angekündigt (Feedback-Ordner) — beim Bau/Recherche ansehen.
- 💡 **Vectorworks-Sync (Zeichnungs-Integration):** Artikel-Warenkörbe (Geräte/Material/Kunde/
  Projekt) in Vectorworks-Zeichnungsfelder exportieren/importieren/syncen. Trifft den bereits
  benannten, aber leeren **Port #17 „CAD-/Zeichnungs-Handoff"** im S10-Blueprint
  (`docs/S10_WIRBELSAEULE.md` §4). **Technische Machbarkeit ungeklärt** (Vectorworks'
  Worksheet-/Records-/IFC-/Scripting-Mechanik nicht recherchiert) — vor jedem Bau erst eine
  eigene, günstige Recherche-Session. Rückrichtung (Vectorworks→mykilOS) besonders vorsichtig
  angehen (Zeichnungsarbeit der Planer nicht überschreiben) — analog Read-only-first-Prinzip
  der sevDesk-Postbox.
  **Architektur-Antwort (Johannes-Frage 2026-07-02, geklärt):** Rückrichtung läuft über eine
  **`mykilOS_CAD Adapter`-Postbox** (spiegelbildlich zur sevDesk-Postbox, Richtung umgekehrt:
  Vectorworks schreibt, mykilOS liest read-only) — das ist die Datenquellen-Schicht. **KEINE**
  eigene CAD-spezifische Alerts-Tabelle daneben — der Adapter speist stattdessen das
  **bestehende Signal-System** (`StudioContext.emit()` → Mediator → Widget-Hinweis, gleiches
  Muster wie `DriveOfferWatcher` → `offerDetected` heute schon). Eine generische, zentrale
  **„mykilOS Alerts"-Tabelle** (ClickUp-Deadlines + neue Angebote + Mail + CAD zusammen) ist das
  bereits erkannte **Benachrichtigungs-Zentrum** aus `FINALE_APP_RUECKWAERTS.md` — ein eigener,
  größerer Strang, nicht nebenbei für CAD mitzubauen.

**Alle vier: nicht selbstständig starten.** Erst auf Johannes' ausdrücklichen Zuruf zünden.

- 💡 **Assistent verschickt Mail mit gedroppter Datei (Johannes 2026-07-03):** Datei in den
  Assistenten-Chat droppen → Assistent textet die Mail (kontextbewusst) → **nach Bestätigung**
  echter Gmail-Versand mit Anhang. Braucht zwei noch ungebaute Bausteine: (a) Datei-Drop/Anhang im
  Chat-Composer, (b) echter `gmail.send`-Pfad mit hartem Bestätigungs-Gate. Sitzt auf dem
  Mail-Send-Strang (Integrationen) + dem Checkout/Übergabe-Gedanken. Konkreter Auslöser: das
  Übergabe-Paket an Daniel schicken. **Nicht in V10** (V10 = ein Auftrag läuft durch), Kandidat V11.

- 💡 **Maps-Widget — Technik ENTSCHIEDEN (Empfehlung Claude, 2026-07-03): Apple MapKit statt
  Google.** Native SwiftUI-`Map` + `CLGeocoder` (Projekt-Adresse → Pin) = kostenlos, kein API-Key,
  kein externes Limit, nativ-schön ([[oekonomisch-schlank-lean-app-regel]]). Google Static Maps
  (Key+Kosten) damit vom Tisch. Umfang: `WidgetKind .map`, alle Renderstates (keine Adresse →
  Empty), Snapshot cachen, „Route in Karten öffnen"-Klick. Adressquelle: Intake/`mykilOS_Projekte.
  Adresse`. Slot: Delight-Block NACH der Feedback-Fix-Welle (Task #9), nicht im V10-Kern.

- 💡 **Boss Button × pulsierender Clockodo-Timer (Johannes 2026-07-03 früh, verknüpft):** Der
  schwebende App-Satellit (Boss Button, Always-on-top-NSWindow, bereits im Backlog) bekommt den
  laufenden Clockodo-Timer als *Herzschlag*: läuft eine Zeitaufzeichnung, **pulsiert der Satellit
  sanft** (dezenter Atem-Puls in MYKILOS-Orange, kein Blinken) — sichtbar aus jedem Kontext, auch
  über anderen Apps. Klick = stoppen/Buchungs-Draft. Gleiche Puls-FX auch inline im
  Zeiterfassung-Widget. Hängt am Clockodo-Zeit-Strang (Timer/Buchen, 6-Schichten-Architektur) —
  erst wenn der echte Timer läuft, lohnt der Puls. Dezent per Design ([[alerts-dezent-datenschutz-
  toggle-regel]]-Geist: abschaltbar). Slot: nach V10-Kern, eigener Delight-Strang mit Boss Button.

- ⚖️ **KORREKTUR Clockodo-Architektur (Johannes 2026-07-03, EISERN): Clockodo wird NIE direkt
  beschrieben.** Die alte 6-Schichten-Architektur (HANDOFF_LIVE_WIRING_4) ändert sich: Schicht 5
  „Confirm → POST /api/v2/entries" **entfällt ersatzlos**. Stattdessen: Timer (auch der geplante
  Boss-Button-Puls) + NLP-Drafts buchen in die **private Clockodo-POSTBOX** (per-User) — ein
  **Stundenprotokoll für die Eigeneingabe** in Clockodo (auch als Checkout exportierbar). Wahre
  Zeiten kommen ausschließlich **lesend aus Clockodo** zurück. Gleiche Philosophie wie
  Belegführung-extern/sevDesk-Postbox: mykilOS protokolliert vor, das externe System beurkundet.

- ⚖️ **EISERNE REGEL systemweit (Johannes 2026-07-03): Aufgaben nur Mensch→Mensch, nie KI→Mensch.**
  Prägt zwei Stränge dauerhaft: **ClickUp Ghost→Live** (auch nach Go-Live setzt die App NIE einen
  Assignee / erstellt NIE Tasks „an" Personen — KI liefert Entwürfe, ein Mensch weist zu und ist
  Absender; die Ghost-Regel war der Testschutz, dies ist das Dauerprinzip) und den **Alerts-Strang**
  (Alerts = dezente Hinweise an den Nutzer selbst, nie Aufträge, nie an Dritte). Assistent:
  Action-Card → Mensch bestätigt → Mensch ist Auftraggeber. In CLAUDE.md „Absolute Regeln" verankert.
