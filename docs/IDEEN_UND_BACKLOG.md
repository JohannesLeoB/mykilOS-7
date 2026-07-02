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

**Format:** Jeder Eintrag hat Status, Quelle (wann/wodurch entstanden) und
Verknüpfung zu Handoffs/Code, falls vorhanden. Status-Werte:
- 💡 **Idee** — nur angedacht, noch nicht bewertet/entschieden
- 📋 **Geplant** — Entscheidung gefallen, noch nicht umgesetzt
- 🚧 **Begonnen** — teilweise umgesetzt
- ✅ **Erledigt** — umgesetzt, bleibt hier als Historie mit Verweis stehen
- ❌ **Verworfen** — bewusst nicht weiterverfolgt, mit Begründung

---

## Nachtrag 2026-07-02 spät — Drive/Mail-Alerts auf bestehenden Beobachtungspfaden (Johannes)

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
- 📋 **Mail SENDEN (nicht nur Entwurf) + Nachrichten-Aktionen** (gelesen/Stern/Archiv). NO-GO in
  MEMORY aufgehoben; als Session S3 (Assistent Schreib-Ausbau) verankert. Braucht `gmail.send`.

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

### 💡 UI-Batch 2026-07-02 (aus Screenshot-Runde)
- **Kontakte klickbar:** Klick auf Mail-Adresse → „Mail schreiben?" → Entwurf im Assistenten-
  Mail-Fenster öffnen. (klein, jetzt baubar)
- **Kontakte-Widget (Projekt-Übersicht):** klickbar/zuweisbar/editierbar machen (heute tot).
  **Entschieden (Johannes 2026-07-02):** Datenquelle wird Airtable (nicht mehr read-only Google).
  Vorgelagerter Daten-Job: **Google-Kontakte → Airtable importieren**, dabei auf **Dubletten**
  prüfen und **Datensatz-Vollständigkeit** validieren. Einträge mit **nur Name** (ohne Mail/
  Telefon/Web) werden **fallengelassen und als UNVOLLSTÄNDIG markiert**. Danach zeigt das
  Projekt-Widget projekt-zugewiesene Airtable-Kontakte → klick/zuweis/editier/Mail.
- **Teamkalender-Widget** in der Projekt-Übersicht: Teamtermine farbcodiert (Button-Farbe),
  Klick → Detail-Vorschau + editierbares Menü. Braucht Kalender-Schreibpfad.
- **Mail: Senden** fehlt (nur Entwürfe) — Fähigkeit + Bestätigungs-Gate; braucht `gmail.send`-
  Re-Consent (M2). Auch Nachrichten-Aktionen (gelesen/Stern/Archiv/Löschen) fehlen.
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
- **Kataloge → Warenkörbe:** „UNGENÜGENDE BEARBEITUNGS- UND ANSICHTS-/VORSCHAU-/
  Editierfunktionen" — die Liste zeigt nur Metadaten, kein Öffnen/Editieren/Vorschauen der
  Positionen. **Der „Wiederherstellen"-Button ist tot** (Button ohne Funktion, klar markiert).
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
