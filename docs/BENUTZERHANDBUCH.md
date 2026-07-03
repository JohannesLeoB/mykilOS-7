# mykilOS 6 — Benutzerhandbuch

**Stetige Mitschrift aller Funktionen. Stand: 2026-07-03 · Version 10.0.0-alpha4**
Jede neue Funktion wird hier beim Build dokumentiert. Dieses Dokument ist kein
Abschlussdokument — es wächst mit der App.

---

## Navigation

Die App öffnet sich mit der **Projektgalerie**. Die linke Sidebar enthält alle
Hauptbereiche. Tastenkürzel:

| Kürzel | Bereich |
|--------|---------|
| ⌘K | **Suchen & Springen** (Command-Palette) |
| ⌘1 | Heute |
| ⌘2 | Projekte |
| ⌘3 | Assistent |
| ⌘4 | Kataloge |
| ⌘, | Einstellungen |
| ⌘⇧S | Sidebar ein-/ausblenden |

**⌘K Command-Palette (2026-07-02):** Ein Overlay mit Suchfeld springt per Fuzzy-Treffer zu
**App-Bereichen** (Heute/Projekte/Assistent/Kataloge/Einstellungen) und **Projekten** (Treffer
auf Nummer, Titel oder Kundenname; Prefix-Treffer stehen oben). **Enter** oder **Klick** öffnet,
**Esc** oder Klick auf den Hintergrund schließt. Rein lokal, read-only.

**Navigation/Settings-Umbau (2026-07-02, Johannes):**
- **„Integrationen" ist kein eigener Sidebar-Punkt mehr** — der Inhalt (Verbindungs-Status,
  Datenstrom-Schaltzentrale, Projektnummer-Bindung, Provisioning-Test) lebt vollständig in
  den **Einstellungen**.
- **Einstellungen als Sidebar-Modus (2026-07-02):** Klick auf den **Initialen-Avatar** unten
  links wechselt die normale Nav-Sidebar gegen die **Einstellungs-Kategorien** (gleiches Layout
  und Design). Der Content rechts zeigt nur noch die gewählte Kategorie. **Zurück:** erneuter
  Klick auf den Avatar **oder** auf den **MYKILOS-Button** oben — beides toggelt zur normalen
  Sidebar (und zum zuletzt aktiven Bereich). Gespiegelt im macOS-App-Menü über **⌘,**.
- **Avatar-Initialen** (Sidebar + Einstellungen) zeigen jetzt einheitlich **Vorname+Nachname**
  (z. B. „Johannes Leo Berger" → „JB").
- **Profil-Einstellungen mit Speichern/Abbrechen:** „Speichern" ist nur bei echter Änderung
  aktiv, „Abbrechen" stellt den gespeicherten Stand wieder her (kein stiller Verlust beim
  Kategoriewechsel). Integrationen speichern über Verbinden/Trennen, Darstellung sofort.

---

## Heute-Board

**Was es tut:** Übersicht über den aktuellen Arbeitstag — Signal-Strip, Drive-Ordner-Status,
offene Aufgaben und Kalender-Ereignisse auf einen Blick.

**Wo:** Sidebar → Heute (⌘1)

**Funktionen:**
- **Widget-Selektor (2026-07-02):** Button **„Widgets"** oben rechts im Heute-Kopf öffnet den
  Selektor — Heute-Widgets (Fokus-Liste, Notiz, Projekt-Favoriten, Letzte Aktivität,
  Zeiterfassung) frei **ein-/ausblenden** und in der **Größe** wählen (Klein/Mittel/Breit/Voll).
  Dieselbe Mechanik wie in der Projekt-Übersicht; Reihenfolge per Drag im Board.
- **DriveFolderRefreshBar**: zeigt wann der Drive-Ordner zuletzt geprüft wurde.
  "Jetzt prüfen" erzwingt einen sofortigen Poll aller aktiven Projektordner auf neue Angebots-PDFs.
- **Signal-Strip**: zeigt Signale aus dem aktuellen Projektkontext (z.B. neue Angebote erkannt).
- **Favoriten**: angepinnte Projekte als Schnellzugriff (Stern auf einer Projektkarte/im
  Detail-Header). Leer, bis du das erste Projekt anpinnst.
- **Letzte Aktivität**: die neuesten Datenstrom-Handshakes (Sync/Tool-Calls) und bestätigten
  Audit-Aktionen, neueste zuerst — grüner Punkt = ok, rot = Fehler, pflaume = Audit.

---

## Projektgalerie

**Was es tut:** Listet alle aktiven Projekte. Quelle: Airtable `Projekte`-Tabelle
(`appuVMh3KDfKw4OoQ`), automatisch synchronisiert beim App-Start.

**Wo:** Sidebar → Projekte (⌘2)

**Funktionen:**
- **Sortieren (S21):** Menü „Sortieren" — Nummer · Name · Datum (neueste zuerst) ·
  Kategorie · **Eigene**. Die Wahl wird gemerkt (`@AppStorage`).
- **Filtern (S21):** Menü „Kategorie" — alle vorkommenden Kategorien (Küche/Licht/…).
- **Frei sortieren per Drag&Drop (S21):** Karte auf eine andere ziehen → eigene Reihenfolge;
  aktiviert automatisch die „Eigene"-Sortierung, persistent.
- **Gespeicherte Ansichten (2026-07-02):** Menü „Ansichten" — die aktuelle Kombination aus
  Kategorie + Sortierung + Suche unter einem Namen sichern („Aktuellen Filter sichern …"),
  später per Klick wieder anwenden oder löschen. Persistent (`@AppStorage`), rein lokal.
- **Favoriten-Stern** auf jeder Karte (und im Projekt-Detail-Header): pinnt das Projekt
  ins Heute-Board. Persistent (GRDB), überlebt Neustart. Stern erneut tippen = entfernen.
- Suche (Name/Nummer/Kundennr.). Klick öffnet Projektdetailseite.

---

## Projektdetailseite

**Was es tut:** Zeigt alle Informationen und Werkzeuge eines Projekts.

**Tabs:**

### Übersicht
Widget-Board mit Widget-Arten: Drive, Aufgaben (ClickUp), Kontakte,
Cash/Umsatz, Kalender, Notizen, **Warenkorb**, Mail, Assistent.

Widgets sind drag-and-drop sortierbar. Jedes Widget zeigt Quelle und SaveState.

**Widget-Selektor (2026-07-02):** Button **„Widgets"** oben rechts über dem Board öffnet ein
Popover zum Selbst-Konfigurieren: pro Widget-Art ein **Ein/Aus-Schalter** (aus = ausgeblendet,
Position/Größe bleiben erhalten) und — wenn sichtbar — eine **Größenwahl** (Klein/Mittel/Breit/
Voll). Änderungen greifen sofort (SaveState). Reihenfolge weiterhin per Drag im Board.

**Warenkorb-Widget (V10, Block E — 2026-07-03):** Zeigt jetzt den **lokal am Projekt
gespeicherten Warenkorb** (WorkBasket, GRDB/local-first) statt der Airtable-Kopie —
**eine editierbare Quelle der Wahrheit**. Positionen (Menge × Bezeichnung · Art.-Nr. · VK)
und EK/VK-Summen. Über **„Bearbeiten"** öffnet sich ein Panel, in dem man **Menge (±)** und
**VK-Einzelpreis** korrigieren sowie Positionen **entfernen** kann; gespeichert wird sofort
mit sichtbarem SaveState. Bestätigte (eingefrorene) Warenkörbe sind nicht editierbar
(Zustand „BESTÄTIGT"). Der Projekt-Warenkorb entsteht automatisch über den Intake-Fragebogen.
Der frühere Airtable-Versandpfad (globaler Session-Warenkorb im Kataloge-Modul) bleibt
unverändert bestehen. *Wo:* Projekt → Übersicht. *Voraussetzung:* keine (lokal).

**Cash-Widget — „Kalkuliert (Warenkorb)" (V10, Block H — 2026-07-03):** Das Cash-Widget zeigt
zusätzlich eine schlanke Zeile mit der **kalkulierten Warenkorb-Summe** dieses Projekts
(VK **netto** und **brutto** inkl. 19 % MwSt), sobald ein Warenkorb mit Positionen existiert.
Reine Anzeige — kein Schreiben, keine sevDesk-Buchung; der Ist-Umsatz-Balken (sevDesk) bleibt
unverändert read-only. *Wo:* Projekt → Übersicht → Cash. *Voraussetzung:* keine (lokal).

**Assistent-Widget (S25):** Das volle-Breite Assistent-Widget zeigt jetzt den
**kompletten konversationellen Chat** (statt der alten Insight-Liste) — kompakt
eingebettet, mit „Maximieren"-Knopf (↖↘ oben rechts) → volles Chatfenster.
Es ist **derselbe Chat wie der „Assistent"-Tab** (gleicher Scope, gleicher
Verlauf): eine Frage im Widget steht auch im Tab und umgekehrt.

### Assistent
Konversationeller Chat, scoped auf dieses Projekt. Claude hat Kontext über
Projektnummer, verknüpfte Drive-Ordner, ClickUp-Liste und Kalender-Suche.
Tool-Use (Drive/Mail/Kalender/Kalkulation) nur bei aktiviertem Opt-in.

**Anklickbare Datei-Ergebnisse (S22):** Findet der Assistent über `find_offers`
Angebote/Rechnungen, erscheinen sie als anklickbare Karte (Symbol + Dateiname +
„ausgehend/eingehend · Typ · Datum"). Ein Klick öffnet die **In-App-Vorschau**
(derselbe Voll-Viewer wie unter „Dateien": PDF/Bild/QuickLook). Read-only —
lokal materialisierte Dateien sofort, der Drive-Inhalt braucht `drive.readonly`
(M2). Über „Im Browser" bleibt der `webViewLink`-Fallback.

### Dateien
Datei-Baum des verknüpften Google-Drive-Projektordners. Unterordner werden
lazy geladen (on-demand) — der **komplette Projektordner** ist begehbar.
Ist der Ordner über **Google Drive für Desktop** lokal materialisiert, zeigt die
Quellzeile „· LOKAL". Rechtsklick → **„Im Finder zeigen"** selektiert die Datei/den
Ordner im Finder, **„Im Browser öffnen"** nutzt den `webViewLink`-Fallback.

**Vorschau per Single-Click (S25):** Ein Klick auf eine Datei öffnet **direkt** die
volle Dokumentenvorschau (kein Zwischenschritt mehr) — ein großes Fenster mit
mehrseitigem **PDF-Viewer** (scrollbar/zoom), **Bild-Viewer** oder macOS **QuickLook**
(Office/Text/viele Formate). Quelle: lokale Datei zuerst, sonst read-only Drive-Inhalt
(braucht `drive.readonly` → M2). Alle Zustände sind sichtbar (laden/Fehler/
Verbindung-nötig); Google-Docs/Sheets/Slides verweisen auf den Browser.

**Wie das Routing funktioniert:** `LocalDriveRootResolver` sucht unter
`~/Library/CloudStorage/GoogleDrive-*` den Ordner/die Datei über das Drive-File-
Stream-xattr `com.google.drivefs.item-id#S` (Item-ID-Abgleich), Namens-Fallback.
Optionaler Vorrang: ein expliziter Pfad in Airtable `driveFolderPath`.

**Voraussetzung:** Google-Konto verbunden (Settings → Google); für lokale Vorschau
zusätzlich Google Drive für Desktop mit materialisiertem (heruntergeladenem) Ordner.

### Angebote
Zwei Spalten — eingehende (`05 …`) und ausgehende (`04 …`) Belege —, rekursiv
gesammelt und nach Dokumenttyp gruppiert. Es werden nur echte Beleg-Dateitypen
angezeigt (**PDF/Bild/Mail**); ZIP, `.numbers` u.ä. werden per Typ-Whitelist
(`DriveOfferWatcher.isAcceptedOfferFileType`) ausgefiltert — dieselbe Regel wie
in „Alle Angebote". **Vorschau** (Icon-Klick) rendert ein
echtes PDF: lokal materialisiert per PDFKit, sonst per read-only Drive-Download
(`downloadContent`) — **nicht** im Browser. **Öffnen** (Klick auf den Namen) startet
lokal-zuerst die macOS-Vorschau, nur ohne lokale Datei den Browser-Fallback.
Rechtsklick → **„Im Finder zeigen"**. Read-only — nie Schreiben.

**„Zum Angebot" — Kalkulations-Vorschau (V10, Block G — 2026-07-03):** Oben im Angebote-Tab
erzeugt der Knopf **„Zum Angebot"** aus dem am Projekt gespeicherten Warenkorb ein
**Angebots-Vorschau-PDF** (Briefkopf, Positionstabelle, Netto/19 % MwSt/Brutto, aus der
Projektnummer abgeleitete Angebotsnummer, Datum). Die Vorschau wird **lokal** abgelegt
(`~/Library/Application Support/mykilOS6/AngebotsVorschau/<Projektnummer>/`) und darunter
gelistet — Klick öffnet sie in der macOS-Vorschau, Rechtsklick → „Im Finder zeigen".
**Eiserne Regel Belegführung extern:** Das PDF ist eine **beschriftete Vorschau** („Angebots-
Vorschau", Kopf-Hinweis + Fußzeile „Kalkulations-Vorschau — kein offizielles Angebot"), **kein**
verbuchungspflichtiger Beleg. Das verbindliche Angebot entsteht separat in sevDesk. **Kein
Drive-/sevDesk-Schreiben.** *Voraussetzung:* ein Projekt-Warenkorb mit Positionen (aus dem Intake).

### Timeline
**Verlauf** des Projekts als eine chronologische Spine: Drive-Dateien, Angebote
(eingehend/ausgehend), kommende Kalendertermine und bestätigte Audit-Aktionen —
verschmolzen und neueste zuerst, je Quelle farbig (Drive terrakotta, Angebot blau,
Termin salbei, Audit pflaume). Klick auf eine Datei/ein Angebot öffnet den Link.
Read-only. Eine kaputte Quelle leert den Tab nicht (die übrigen werden trotzdem gezeigt).

### Material
Zeigt Drive-Unterordner `05 Material` (tolerant per Name gematcht).

---

## Globale Ansichten (Sidebar)

### Assistent (global)
Konversationeller Chat ohne Projektscope. Zeigt alle Projekte als Kontext.

**Immer live (S27):** Tools (Mail, Kalender, Drive, Aufgaben, Kontakte) und die
Kostenschätzung sind fester Teil des Chats — **kein Opt-in-Toggle, kein separater
Schätzchat-Modus** mehr. Frag einfach (z. B. „was kostet eine 4,5 m Eiche-Küche?")
→ die Schätz-Engine antwortet direkt als Karte im Chat.

**Dateien in den Chat ziehen (Mehrfach, 2026-07-02):** Dateien auf den Chat droppen —
**mehrere gleichzeitig**, auch **ganze Ordner** (werden aufgelöst; ZIPs bleiben als eine
Datei). Eine Sammelkarte unter dem Eingabefeld listet alle Dateien (Gesamtgröße, Einzel-
Entfernen). Im Projekt-Chat lässt sich der **Ziel-Ordner wählen** (Menü „Ziel": Projektordner
oder ein Unterordner — die Unterordner werden read-only aus Drive geladen). Zwei Sammelaktionen,
beide mit Bestätigung — **kein Auto-Schreiben**: **„Alle in Drive"** (lädt jede Datei in den
gewählten Ordner; braucht `drive.file`) und **„Alle an Mail-Entwurf"** (hängt **alle** Dateien
an **einen** Gmail-Entwurf — kein Versand).

### Dateien (global)
Alle Drive-Dateien des Accounts, nach Änderungszeit sortiert.

**Voraussetzung:** Google-Konto verbunden.

### Angebote (global)
Projektliste links, Angebots-PDFs des gewählten Projekts rechts.

**Alle Angebote (S23):** Oben in der Projektliste der Button **„Alle Angebote"**.
Er aggregiert die Belege **aller** 04/05-Ordner **aller** Projekte mit Drive-Ordner.

- **Zweispaltiges Layout:** links **Eingehend**, rechts **Ausgehend** (die Richtung
  steckt bereits im Beleg-Modell). Jede Spalte scrollt eigenständig und ist innerhalb
  nach **Dokumenttyp** gruppiert (Angebote / Aufträge / Rechnungen / Eingehende Angebote /
  Bestellungen / Sonstige).
- **Projektzuordnung pro Beleg:** jede Zeile zeigt ihr **echtes** Projekt (Titel · Nummer) —
  nie das Projekt der ersten Zeile. Bei nur einem gefüllten Projekt erscheinen naturgemäß
  nur dessen Belege (kein Fehler); über die Suche nach einem anderen Projektnamen werden
  dessen Belege sichtbar.
- **Kategorie-Filter:** Dropdown „Alle Kategorien" → auf einen Dokumenttyp einschränken.
- **Suche:** über Dateiname, Projekt(-Titel/-Nummer) und Belegnummer.
- **Sortierung** (innerhalb der Spalten): Datum, Projekt, Typ, Name.
- **Typ-Whitelist (Filter-Regel):** Angebote sind **nie ZIP/.numbers** — angezeigt werden
  nur **PDF** (primär), **Bilder** (sekundär) und **Mail** (selten). ZIP, `.numbers`,
  Office-Tabellen u.ä. werden ausgefiltert. Die Regel liegt an **einer** Stelle
  (`DriveOfferWatcher.isAcceptedOfferFileType`) und gilt für Projekt-Tab, „Alle Angebote"
  und das `offerDetected`-Signal gleichermaßen — kein zweiter Filter in der UI.

Jede Zeile ist anklickbar → In-App-Vorschau (lokale Datei zuerst, sonst read-only
Drive-Bytes; Vollvorschau über das Popover). Read-only, nutzt dieselbe `OffersCollector`-Logik
wie der Projekt-Tab (eine Quelle der Wahrheit). Das Durchsuchen aller Projektordner läuft
begrenzt nebenläufig (schont das Drive-Rate-Limit) mit Lade-Fortschrittsanzeige; einzelne
nicht erreichbare Projektordner werden übersprungen und gezählt. **Voraussetzung:**
Google-Konto verbunden (volle Drive-Vorschau via M2).

### Mail — Anhänge klickbar + in Drive ablegen (2026-07-02)
Der Mail-Reader (Sidebar → Mail bzw. Assistent → Mail-Umschalter) zeigt zu jeder
Nachricht ihre Anhänge. Diese sind jetzt **interaktiv**:

**Anhang anklicken → In-App-Vorschau.** Ein Klick auf die Anhang-Zeile (Auge-Symbol)
öffnet **denselben Voll-Viewer** wie unter „Dateien"/„Angebote" (mehrseitiges
**PDF**, **Bild** oder macOS **QuickLook** für Office/Text/viele Formate). Die
Anhang-Bytes werden **read-only** über die Gmail-API geladen (`downloadAttachment`,
Gmail-Scope reicht — **kein** `drive.readonly` nötig). „Im Browser" gibt es hier
nicht (Anhänge haben keinen Drive-Web-Link).

**Anhang → Drive-Projektordner ablegen (Bestätigungs-Gate).** Der Ordner-Knopf
(`folder.badge.plus`, terrakotta) neben dem Anhang öffnet ein Ablage-Fenster:
1. **Projekt wählen** (nur Projekte mit verknüpftem Drive-Ordner).
2. **Zielordner wählen** — Projektordner oder ein Unterordner (Unterordner werden
   read-only aus Drive geladen), über **dieselbe Ablage-Karte** wie beim Datei-Drop
   im Chat.
3. **„In Drive ablegen" bestätigen** → der Anhang wird hochgeladen und als
   `AuditEntry(.driveFileUploaded)` protokolliert.

**Wo zu finden:** Nachrichten-Detailansicht → Abschnitt „ANHÄNGE".
**Voraussetzungen:** Google verbunden (Gmail-Scope für Vorschau; **`drive.file`/M1**
für den Upload). Fehlt der Schreib-Scope, meldet die Karte klar „Drive-Schreibzugriff
nötig" — es wird **nichts** geschrieben.
**Einschränkungen:** **Kein Auto-Write** — Ablage nur nach ausdrücklicher Projekt-/
Ordnerwahl und Klick. Kein Versand, kein Löschen. Read-only Download; der Upload
nutzt exakt den bestehenden `uploadFileToDrive`-Pfad (NO-GO-Ordner-Guard + Audit).

### Integrationen (⌘7)
Datenstrom-Schaltzentrale: zeigt alle 47 Weichen aus `DatastromManifest.json`
mit letztem Handshake-Zeitstempel und Verbindungsstatus (grün/rot/grau).
Jede Weiche hat eine eindeutige `Integrations-ID` die exakt dem `DataFlowLogger`-Eintrag
im Code entspricht.

Ebenfalls hier: verbundene Dienste (Google, Airtable, ClickUp, Clockodo, Sevdesk, Claude).

### Kataloge (⌘8)
**Umsortierbare Unter-Tabs** (Tab mit der Maus ziehen → Reihenfolge wird gemerkt,
`@AppStorage`): Artikel/Shop, Lager, Warenkörbe, Angebote, Kontakte, Notizen, Aufgaben.
Oben rechts: **+ Neues Projekt** (Fragebogen) und der **Warenkorb-Badge** (Positionszahl).

- **Artikel / Shop** — der Live-Artikelkatalog (Airtable-Base `appdxTeT6bhSBmwx5`, ~13.419
  Records), clientseitig durch-/filterbar (Bezeichnung/Hersteller/Art.-Nr., Kategorie- und
  Hersteller-Filter), Liste **oder** Kachel, Pagination (25/50/100). Je Zeile Auf-Lager-Badge
  + **+ Korb**. **Neu (2026-07-02): Preislisten-Detailvorschau** — Klick auf einen Artikel
  (Zeile oder Kachel, außerhalb des +Korb-Buttons) öffnet ein Detail-Sheet: großes Produktbild
  (klickbar → im Browser öffnen), Bezeichnung, Art.-Nr.- und Kategorie-Chip, **EK / VK / Marge %**,
  Lager-Hinweis und **In den Warenkorb**. Read-only auf die Artikel-Daten (Daniels Base bleibt
  unangetastet).
- **Warenkörbe** — die gespeicherten Warenkörbe (Airtable „Warenkörbe", read-only Liste, neueste
  zuerst; Filter Aktuell/Archiviert). **Vorschau** (Auge-Icon) öffnet die Positionen read-only,
  **ohne** den aktiven Warenkorb zu verändern; **Wiederherstellen** lädt sie zurück in den
  aktiven Warenkorb. Editieren der Mengen passiert im Warenkorb-Panel (Badge oben rechts).
- **Kontakte** — das geteilte **Airtable-Kontaktverzeichnis** (Mastermind-Base, Tabelle
  „Kontakte"): Kunden, Lieferanten, Handwerker, Architekt/Planer, Team. Sortier- und filterbar
  (Kategorie + Freitext über Name/Firma/Projekt). **Zeile klicken** → Detailkarte: alle Felder
  **editierbar** (Name/Firma/Mail/Telefon/Adresse/Kategorie), Speichern läuft gated über
  Karte→Bestätigung→Audit (`AppState.writeAirtableContact`, `.update` — kein Löschen).
  **Neu (2026-07-02): Klick direkt auf die Mail-Adresse** → Rückfrage „Mail an … schreiben?" →
  öffnet einen vorbefüllten Entwurf **im Assistenten-Mail-Fenster** (Assistent → Mail). Kein
  Auto-Versand — nur Entwurf. Voraussetzung fürs Verzeichnis: Airtable verbunden.
- **Notizen** — die lokalen Assistenten-Notizen (S4). Direkt hier anlegen (Sichern) und
  löschen, oder über den Assistenten-Chat. Rein lokal. **Zwei Ansichten umschaltbar (S18):**
  *Liste* (clean) oder *Wand* (bunte Notizzettel, je nach Notiz eingefärbt & leicht geneigt);
  die Wahl wird gemerkt. **Bearbeiten (S20):** Klick auf einen Zettel/eine Zeile öffnet den
  Editor (Text ändern, **4-Farb-Picker**, Speichern/Löschen); die Farbe bleibt an der Notiz.
- **Aufgaben** — die lokale Aufgabenliste (S6): To-dos/Erinnerungen abhaken, anlegen,
  löschen — hier oder im Assistenten-Chat. Offene zuerst, Fälligkeit sichtbar. Rein lokal.

### Kalkulation (jetzt im Assistenten, S27)
Der eigene „Kalkulation"-Sidebar-Tab ist **entfernt** — die Kostenschätzungs-Engine
ist fester Teil des **Assistenten** (frag im Chat, z. B. „was kostet …"). Ergebnis:
Min/Mitte/Max-Netto mit Konfidenz, direkt als Karte. Datenquellen unverändert:

**Datenquellen (lokal, kein Netzwerk):**
- `_Daten/Kalkulation/Brain/active_price_anchors.csv` — 203 Tischler-Preisanker
- `_Daten/Kalkulation/Devices/catalog.csv` — 5.565 Geräte/Beschläge
- Fallback: BaselineAnchorProvider (6 konservative Regelanker)

**Lern-Loop:** Bestätigte Anpassungen (Faktor + Grund) werden append-only
gespeichert. Kandidaten können per "Übernehmen" zu aktiven Faktoren promoted
werden → zukünftige Schätzungen verschieben sich.

**PDF-Import (Härtung, 2026-07-01).** `KalkulationsEngine.importPDF` lädt ein
Lieferanten-PDF aus Drive, berechnet den SHA256-Hash und prüft gegen bereits
importierte Dokumente (`document_imports`, append-only, No-delete). Ein echter
Neuzugang legt einen Record in Airtable **Eingehende-Angebote**
(`appuVMh3KDfKw4OoQ`) an (SHA256, Datei-Name, Projekt-Nr, Richtung=„eingehend",
Status=„Neu", Importiert-am) — ein erkanntes Duplikat erzeugt **nur** einen
lokalen Log-Eintrag, nie einen zweiten Airtable-Record (verhindert doppelt
gezählte Preis-Anker). Datenstrom-ID `KALKULATION_PDF_IMPORT`.
**Einschränkung:** reine Positions-/Preis-Anker-Extraktion aus dem PDF-Text
ist bewusst NICHT Teil davon — eigenes, größeres Folge-Feature (Positions-
Parser, siehe `docs/IDEEN_UND_BACKLOG.md`). **Schreiben aktuell blockiert:**
`Eingehende-Angebote` steht noch nicht auf `AirtableClient.writableMap` —
Freigabe von Johannes ausstehend, `createRecord` wirft bis dahin ehrlich
`.invalidBaseID` statt eine Halbwahrheit zu schreiben.

---

## Darstellung — Hell/Dunkel/Auto (Settings → Darstellung, 2026-07-02)

Neuer Abschnitt in den Einstellungen (direkt unter „Wer bin ich?"): ein
Segment-Umschalter **Automatisch · Hell · Dunkel**. Die App-Ansicht richtet sich
damit **nicht mehr stur nach dem System**, sondern nach deiner Wahl.
- **Name · Was es tut:** legt das Farbschema der gesamten App fest (treibt alle
  Design-Tokens `MykColor` um). „Automatisch" folgt weiter dem System.
- **Wo zu finden:** Einstellungen → Darstellung.
- **Voraussetzungen:** keine.
- **Einschränkungen:** **pro Nutzer/Gerät** gespeichert (AppStorage `ui.appearance`,
  UserDefaults) — nicht teamweit geteilt, passt zum local-first Ein-Nutzer-pro-Gerät-
  Modell. Gilt sofort, auch fürs „Über"-Fenster.

**Barrierefreiheits-Härtung (2026-07-02):** Die Sekundär-/Tertiärtext-Farben (`muted`,
`faint`) wurden systemweit nachgedunkelt, bis sie den WCAG-AA-Kontrasttest bestehen
(muted ≥4.5:1 für Normaltext, faint ≥3.0:1 — in Hell UND Dunkel, auf allen drei
Hintergrundtönen). Zusätzlich tragen alle Icon-only-Buttons mit Tooltip jetzt ein
VoiceOver-Label (26 Stellen), und es gibt einen zentralen `MykIconButton`-Baustein
(MykilosDesign), bei dem das Label ein Pflicht-Parameter ist — künftige Icon-Buttons
können nicht mehr ohne entstehen. Kleine, flächige Aufhellung der grauen Texte ist
beabsichtigt und kein Fehler.

## Integrationen (Settings → Integrationen)

Übersicht aller verbundenen Dienste mit Verbindungsstatus.

### Google
Verbindet Drive, Kalender, Kontakte und Gmail über ein einziges OAuth-Login
(`johannes@mykilos.com`). PKCE-Flow, Token in Keychain.

Scopes: Drive (read-only Metadaten), Calendar (read), Contacts (read),
Gmail (read Metadaten+Snippet), UserInfo (E-Mail + Profil).

### Airtable
Personal Access Token (PAT) + Base-ID. Liest `Kunden` und `Projekte` aus
`appuVMh3KDfKw4OoQ`. Sync bei App-Start und manuell über Force-Poll-Button.

**NO-GO:** Geteilte Base `appkPzoEiI5eSMkNK` und Artikel-DB `appdxTeT6bhSBmwx5`
werden nie beschrieben.

### ClickUp
Personal Token. Liest offene Aufgaben je Projektliste (`list_clickup_tasks`-Tool).

### Clockodo
API-Key pro User (Private Area). Jeder User sieht nur eigene Zeiteinträge.
Datensensitiv — erscheint nur in der Private Area der Settings.

### Sevdesk
API-Token (Private Area). Liest Ist-Umsatz für das Cash-Widget.
**NIE als Assistenten-Tool — nur Widget.**

### Claude (Anthropic)
API-Key in Keychain. Powers den konversationellen Assistenten. Tool-Daten fließen
nur bei aktivem Opt-in an die API.

**Auto-Modell-Routing (S26):** Der Assistent wählt jetzt **selbstständig pro Anfrage
das günstigste Modell**, das der Aufgabe gewachsen ist — statt fix `claude-sonnet-4-6`:
- **Haiku** — einfache, kurze Konversation (günstigste).
- **Sonnet** — Tool-Use (Mail/Drive/Kalender/Kontakte) oder komplexe/lange Freitext-Fragen.
- **Opus** — Kostenschätzung/Kalkulation (Schätzmodus oder Kosten-/Budget-/Marge-Fragen) — bestes Reasoning.

Das gewählte Modell steht live in der Quellzeile unter dem Chat („CLAUDE · AUTO · HAIKU/SONNET/OPUS").
Spart Kosten ohne Qualitätsverlust im Alltag. Logik: `AssistantModelRouter`.

---

## Identität & Private Area

**Wo:** Settings → Identität / Private Area

- **Identität**: zeigt verbundenes Google-Konto (Avatar, Domain, E-Mail).
  6-Dot Traffic-Light zeigt Verbindungsstatus aller Integrationen.
- **Private Area**: nutzer-eigene Credentials (Clockodo, perspektivisch weitere).
  Visuell getrennt von geteilten Integrationen.
- **Cache leeren**: löscht lokale GRDB-Daten ohne App-Neuinstallation.

---

## Datenschutz-Grenzen zwischen Team-Mitgliedern

**Was es tut:** mykilOS ist ein **persönliches Cockpit** — dein Assistent, deine Mail, deine
Notizen gehören dir. Kolleg:innen können deine E-Mails, Memos/Notizen oder deinen Assistent-
Chat-Verlauf **niemals einsehen**, und umgekehrt. Geteilt sind ausschließlich gemeinsame
Projektdaten (Drive-Ordner, Kalender, ClickUp-Aufgaben, Airtable-Projekte) — alles Persönliche
bleibt strikt bei dir.

**Wo:** gilt automatisch, überall in der App — jeder verbindet sein eigenes Google-Konto, kein
gemeinsamer Zugriff auf persönliche Postfächer.

**Voraussetzungen:** keine — strukturell durch die Architektur gesichert (eigenes OAuth-Konto
pro Nutzer).

**Einschränkungen:** Funktionen, die Team-weites Wissen sammeln (z. B. ein künftiges Assistent-
Tagebuch für Produktverbesserung), zeigen ausschließlich **aggregierte, anonyme Muster** — nie
den Wortlaut deiner persönlichen Nachrichten. Jede solche Funktion ist **einzeln ein-/
ausschaltbar** in den Einstellungen unter Datenschutz und standardmäßig transparent erklärt,
bevor du sie aktivierst — nie stillschweigend im Hintergrund an.

**Rechtlicher Rahmen:** orientiert sich an DSGVO/§ 26 BDSG (Beschäftigtendatenschutz) und dem
Grundsatz freiwilliger, informierter Einwilligung bei KI-gestützten Funktionen, die
Nutzungsmuster erfassen könnten.

---

## Diagnose

**Name:** App-Diagnose · **Was es tut:** zeigt die App-Identität für Support &
Fehlersuche. · **Wo zu finden:** Settings → Abschnitt „Diagnose" (zusätzlich im
Fenster „Über mykilOS 6", App-Menü / ⌘,). · **Voraussetzungen:** keine. ·
**Einschränkungen:** zeigt keine Tokens/Keychain-Daten.

Felder: **Version** (+ Build-Nummer), **Commit** (echter Git-Kurz-Hash),
**Branch**, **Gebaut** (UTC-Build-Zeitpunkt), **Bundle**-Pfad, **DB**-Pfad.
Commit/Branch/Build-Datum injiziert `script/build_and_run.sh` beim Bauen in die
`Info.plist` (Keys `MykGitCommit`/`MykGitBranch`/`MykBuildDate`); die App liest sie
über `Bundle.main.infoDictionary`. Bei `swift run` ohne App-Bundle stehen sie
ehrlich auf „–"/„unbekannt". Der DB-Pfad stammt aus derselben Quelle
(`AppDatabase.productionURL`), die die App real öffnet — kann also nie divergieren.

**Diagnose kopieren:** Der Button legt einen redaktierten Diagnosebericht (App-
Identität + die letzten Datenstrom-Handshakes) in die Zwischenablage — **ohne**
Tokens/API-Keys/Clockodo-Rohdaten (per Konstruktion). Gut für Support-Anfragen.

**Datenbank-Wiederherstellung:** Lässt sich die lokale Datenbank beim Start nicht
öffnen (gesperrt/korrupt), zeigt mykilOS statt eines Absturzes eine
Wiederherstellungs-Ansicht mit Fehlertext und DB-Pfad. „Datenbank zurücksetzen"
verschiebt die beschädigte Datei zerstörungsfrei in Quarantäne (`*.corrupt-…`) und
legt eine neue an. Geteilte Daten (Drive/Kalender/Airtable) sind nie betroffen.

**Backup & Restore (2026-07-02):** mykilOS legt **automatisch beim Start höchstens
1×/Tag** einen konsistenten, geprüften Snapshot der lokalen Datenbank an (WAL-Checkpoint
+ SHA-256-Manifest), lokal im Unterordner `backups/`. **„Backup jetzt"** erzwingt sofort
einen Snapshot. Es werden **max. 30 Snapshots** behalten (ältere werden gelöscht).
Darunter listet Settings die vorhandenen Backups (Datum · Tag · Größe); **„Wiederherstellen"**
merkt ein Backup vor — es wird beim **nächsten App-Start** angewandt (sicher, bevor die DB
geöffnet ist; der aktuelle Stand wird vorher automatisch als Rettungsbackup gesichert). Nach
dem Vormerken erscheint der Hinweis, die App neu zu starten. **„Im Finder"** öffnet den
`backups/`-Ordner. Alles rein lokal — kein externer Schreibzugriff.

---

## Assistent — Tool-Use

Wenn Tools aktiviert sind, kann der Assistent folgende Aktionen ausführen
(alle **read-only**, Bestätigung per Action-Card bei Schreibaktionen):

| Tool | Was es tut | Opt-in |
|------|-----------|--------|
| `search_gmail` | Sucht Mails nach Query (Gmail-Operatoren, z. B. `after:2025/01/01`) — die Suche umfasst das **ganze Postfach**. Trefferzahl via `anzahl` (Standard 25, max 100) | toolsEnabled |
| `read_email` | Liest den **vollen Inhalt** einer Mail (PDF/Text-Body, nicht nur die Vorschau); findet sie per Gmail-Suche | toolsEnabled |
| `create_draft` | Bereitet einen **Mail-Entwurf** vor → Bestätigungskarte → legt nach Klick einen **Gmail-Entwurf** an (erscheint in Apple Mail). **Versendet NIE** | toolsEnabled (+ `gmail.compose`/M2) |
| `list_calendar_events` | Liest Kalender-Termine | toolsEnabled |
| `suggest_calendar_event` | Bereitet einen Termin vor → Aktionskarte „Im Kalender öffnen" (kanonischer Google-Link, kein API-Write, KEIN fabrizierter Inline-Link) | toolsEnabled |
| `list_drive_folder` | Listet Drive-Ordner-Inhalt | toolsEnabled + driveFolderID |
| `find_offers` | Findet Angebote/Rechnungen im Drive (rekursiv, auch in „01 INFOS"); global per Projektname | toolsEnabled |
| `read_drive_file` | Liest den **Inhalt** einer Drive-Datei als Klartext (PDF via PDFKit, Google Docs/Sheets/Slides via Export, Text); findet die Datei per (Teil-)Name rekursiv im Projektordner | toolsEnabled |
| `list_clickup_tasks` | Liest offene ClickUp-Aufgaben des aktuellen Projekts | toolsEnabled + clickUpListID |
| `list_all_clickup_tasks` | **Projektübergreifende** Übersicht aller offenen ClickUp-Aufgaben, gruppiert nach Projekt (optional Projekt-Filter) | toolsEnabled + ≥1 Projekt mit ClickUp-Liste |
| `search_contacts` | Sucht Google-Kontakte | toolsEnabled |
| `create_contact` | Schlägt einen **neuen** Google-Kontakt vor → Bestätigungskarte. Schreibt erst nach Klick „Kontakt anlegen" (People API + Audit), nie automatisch | toolsEnabled (+ Google verbunden, `contacts`-Scope/M2) |
| `schaetze_projekt` | Kostenschätzung (lokal) | toolsEnabled oder schaetzModus |
| `query_studio_knowledge` | Fragt Slack-Brain | toolsEnabled |
| `search_katalog` | Sucht Gerätekatalog (Hersteller, Artikelnr., VK) | toolsEnabled, kein SchaetzModus |
| `lookup_kunde` | Sucht Airtable-Kunden (Name/Kundennr./Projektanzahl, lokaler Sync-Cache) | toolsEnabled |
| `lookup_kontakt` | Sucht im **Airtable-Kontaktverzeichnis** (Kunden/Lieferanten/Handwerker/Team): Name, Organisation, **Telefon**, E-Mail, **Adresse**, Projekt. Beantwortet „Adresse Cirnavuk?" lokal, ohne Google/M2 | toolsEnabled (+ Airtable verbunden) |
| `create_note` / `list_notes` / `update_note` / `delete_note` | **Notizen/Erinnerungen** anlegen, auflisten, ändern, löschen (lokal, persistent). Im Projekt-Chat automatisch dem Projekt zugeordnet; `list_notes` zeigt Projekt+global (`alle=true` = alle) | toolsEnabled |
| `create_task` / `list_tasks` / `complete_task` / `delete_task` | **Aufgaben/To-dos** anlegen, auflisten, abhaken, löschen (lokal, persistent, optionales Fälligkeitsdatum). Im Projekt-Chat automatisch dem Projekt zugeordnet | toolsEnabled |

Alle Tool-Calls werden via `DataFlowLogger` lokal protokolliert.

**Capability-Chips:** Im optIn-Bereich des Chats zeigen farbige Chips welche
Fähigkeiten gerade aktiv sind (Gmail, Kalender, Drive, ClickUp, Kontakte,
Studio-Wissen, Katalog, Kalkulation). Grüner Chip = Opt-in aktiv + Handle vorhanden.
Gelber Chip = nur mit dem jeweiligen Scope verfügbar (z. B. Drive nur mit Projekt-Ordner).

**ThinkingIndicator:** Während Claude antwortet erscheint ein 3-Punkt-Bounce als
Ladeindikator. Bei aktivem Streaming tippt der Text mit blinkenden Cursor `▌`.

---

---

## Datenstrom-Schaltzentrale

Die Schaltzentrale ist die vollständige Karte aller Datenströme von mykilOS 6.
Sie beantwortet: **Wo kommt was her? Wohin geht was? Wer darf was lesen/schreiben?**

**Maschinenlesbare Wahrheit:** Airtable `appuVMh3KDfKw4OoQ` → Tabelle `Datenstrom-Handbuch`
(`tblaUVftka0GvXzeU`). Jede Weiche hat eine eindeutige `Integrations-ID`, die exakt
mit den `DataFlowLogger.log(integrationID:)`-Aufrufen im Code übereinstimmt.

**Handshake-Protokoll:** Jeder Datensync schreibt einen Eintrag in `DataFlowLogger`
(lokal GRDB + Spiegel nach Airtable `Datenstrom-Log`). Felder: Timestamp, Integrations-ID,
Nutzer-ID, Aktion (START/SUCCESS/ERROR), Records gelesen/geschrieben, HTTP-Status,
Fehlermeldung, Dauer-ms, Zusammenfassung.

---

### Alle Weichen (Stand 2026-07-01 · 39 Weichen)

#### Airtable

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `AIRTABLE_KUNDEN_PROJEKTE` | Kunden & Projekte | READ | App-Start + manuell | read-only | System-of-Record für Projekte/Kunden. Paginiert (offset). Schreibt nie zurück. |
| `AIRTABLE_GESCHAEFT_KUNDEN_PROJEKTE` | Geschäfts-Kunden & -Projekte (Artikel-Base) | READ | App-Start + nach Intake-Submit | read-only | mykilOS 8, Block A: zweite Hälfte der SoR-Karte — Geschäfts-Wahrheit (Status/Budget/Sevdesk) aus der Artikel-Base, getrennt gecacht vom Mastermind-Routing. Resolver: `ExternalMappingRegistry`. Join über Projektnummer — Artikel-`Projekte` hat das Feld heute noch nicht, daher laufen neue Intake-Projekte vorerst als `businessOnlyUnbound`. |
| `AIRTABLE_KUNDEN_LOOKUP` | Kunden-Lookup (Assistent) | READ | onDemand (Tool-Call) | read-only | Assistenten-Tool `lookup_kunde` über den **lokalen** Sync-Cache (kein Live-Call): Name, Kundennummer, Projektanzahl. Adresse/Telefon → `lookup_kontakt`. Eigene Weiche (L24). |
| `AIRTABLE_KONTAKTE_LOOKUP` | Kontakte-Lookup (Assistent) | READ | App-Start (Sync) + Tool-Call | read-only | Read-only Sync der Mastermind-Tabelle `Kontakte` (~914 Records) in lokalen `ContactDirectory`-Snapshot; Tool `lookup_kontakt` liefert Name/Organisation/**Telefon**/E-Mail/**Adresse**/Projekt. Beantwortet „Adresse Cirnavuk?" ohne Google/M2. Eigene Weiche (S13). |
| `DATAFLOW_LOG_WRITE` | Datenstrom-Log | WRITE | Ereignisgesteuert | append-only (Mastermind) | Jeder Sync-Handshake landet hier. Harte Whitelist im AirtableClient: nur diese Tabelle + Handbuch. |
| `DATAFLOW_HANDBOOK_WRITE` | Datenstrom-Handbuch | WRITE | onDemand (Session) | append-only (Mastermind) | Diese Karte selbst. Jede neue Weiche wird hier registriert. |
| `POLISH_LOG_WRITE` | Dampflok Polish-Log | WRITE | onDemand (Session) | append-only (Mastermind) | Nur Claude-Code-Agent, nicht die App. Tabelle `tblberJMgRArGSypE`. |
| `WRITE_SHADOW_LOG` | Write-Shadow-Log (Backup-Base) | WRITE | onDemand (jeder Write) | append-only (Mastermind) | **Aktiv, live verifiziert** — mykilOS 8, Block A. Base `mykilOS 8 Backup Base` (`app56DTbSoqPvZhom`), Tabelle `Write-Shadow-Log` (11 Felder, per Meta-API angelegt, freigegeben durch Johannes). Echter Test-Write kam mit 200 OK an. `WriteShadowRecorder` schreibt zusätzlich IMMER vollständig lokal (GRDB `writeShadowLog`, Cold-Start-getestet). |
| `WRITE_SHADOW_BACKUP_FEHLT` | Write-Shadow ohne Backup-Base (Warnung) | READ | onDemand (jeder Write, solange Spiegel scheitert) | keine | Lokale Sichtbarkeits-Warnung — feuert jetzt auch, wenn der Airtable-Spiegel trotz gesetzter `backupBaseID` fehlschlägt (z. B. falscher Tabellenname), nicht nur wenn die Base ganz fehlt. Macht jede Spiegel-Lücke sichtbar statt sie zu verstecken. |
| `PROJECT_NUMBER_LOCAL_BINDING` | Projektnummer-Bindungs-Brücke (lokal) | WRITE | onDemand (manuelle Bestätigung) | keine | mykilOS 8, Block A-Erweiterung (Johannes-Entscheidung 2026-06-30): rein lokale GRDB-Tabelle (`projectNumberBindings`) — **kein Airtable-Write, rührt die Artikel-Projektliste nie an.** Bindet ein Geschäftsprojekt ohne Projektnummer-Feld an eine Mastermind-Projektnummer, NUR nach manueller Bestätigung eines automatisch erkannten (exakter Titel-Match) Kandidaten. |
| `AIRTABLE_FRAGEBOGEN_PROJEKT_ROUTING` | Fragebogen: Mastermind-Routing-Eintrag | WRITE | onDemand (Fragebogen-Bestätigung, Stufe „Lead"/„Projekt mit Ordner") | append-only (Mastermind) | 2026-07-01, Johannes freigegeben: erster echter Write-Pfad in die Mastermind-Tabelle `Projekte` (`tblGJR13OliFt6Ewi`, bisher nur aus Drive-Scan befüllt) — macht ein per Fragebogen angelegtes Projekt in der App-Galerie sichtbar. Phase = „Aktiv" (Stufe „Projekt mit Ordner") oder „Lead" (Stufe „Als Lead anlegen", neue Select-Option). Dublettenschutz auf Kunde/Projekt-Ebene davor (Fetch-vor-Create), nicht-fatal bei Fehler; Provisionierung wird VOR der Projektnummern-Reservierung übersprungen, wenn keine STR-Nr bildbar ist (keine Nummer wird verschwendet). |
| `AIRTABLE_INTAKE_KUNDE_ANLEGEN` | Intake: Kunde in Artikel-DB anlegen | WRITE | onDemand (Fragebogen-Bestätigung, jede Anlege-Stufe) | keine | Härtung 2026-07-01 (Datenstrom-Check): existierte im Code seit der Fragebogen-Einführung, hatte aber nie einen `dataFlow.log`-Aufruf — der meistgenutzte Write der App war in der Schaltzentrale unsichtbar. Dublettengeschützt (Fetch-vor-Create über Nachname+E-Mail/Telefon). |
| `AIRTABLE_INTAKE_PROJEKT_ANLEGEN` | Intake: Projekt in Artikel-DB anlegen | WRITE | onDemand (Fragebogen-Bestätigung, Stufe „Lead"/„Projekt mit Ordner") | keine | Härtung 2026-07-01 (Datenstrom-Check): analoge Lücke wie beim Kunde-Anlegen, jetzt geschlossen. Dublettengeschützt (Fetch-vor-Create über Projektname+Kunden-Link). |
| `AIRTABLE_WARENKORB_SENDEN` | Warenkorb an Airtable senden | WRITE | onDemand (Senden-Button / Fragebogen SCHRITT 3) | keine | Härtung 2026-07-01 (Datenstrom-Check): CartStore.sendWarenkorbToAirtable hatte keinen `dataFlow.log`. Zusätzlich gefunden: die Archivierungs-/Versionslogik matchte bisher über Feld-IDs statt der echten NAME-keyed Airtable-Antwort — Archivierung alter Versionen und Versionszählung liefen seit jeher ins Leere (jeder Send erschien als „Version 1"). Jetzt auf die echten Feldnamen (Prüfsumme/Status/Version) korrigiert. |

#### Google Drive

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `DRIVE_POLL_OFFERS` | Angebots-PDF-Watcher | READ | Intervall (60s) + manuell | read-only | Baseline-Semantik: erster Poll meldet nichts. Handshake nur bei echtem Treffer. `isOffer` = Typ-Whitelist (PDF/Bild/Mail, kein ZIP/.numbers) **plus** Angebots-/Rechnungs-Schlüsselwort. |
| `DRIVE_FILES_TAB` | Dateien-Tab (Finder-Baum) | READ | onDemand (Tab öffnen) | read-only | Nur Metadaten (Name/Typ/Datum/Größe). `drive.metadata.readonly` Scope. |
| `DRIVE_OFFERS_TAB` | Angebote-Tab | READ | onDemand (Tab öffnen) | read-only | Gleiche Erkennungslogik wie `DriveOfferWatcher.detectOffers`. Typ-Whitelist (`isAcceptedOfferFileType`, EINE Quelle der Wahrheit): nur PDF/Bild/Mail, ZIP/.numbers werden ausgefiltert. |
| `DRIVE_MATERIAL_TAB` | Material-Tab | READ | onDemand (Tab öffnen) | read-only | Tolerant per Ordnername gematcht (`05 Material` o.ä.). |
| `DRIVE_ASSISTANT_LIST` | Drive-Ordner-Listing (Assistent) | READ | onDemand (Tool-Call) | read-only | Assistenten-Tool `list_drive_folder`. Nur Metadaten, nie Dateiinhalte. Eigene Weiche (Mandate E). |
| `DRIVE_OFFERS_FIND` | Angebote-Suche (Assistent) | READ | onDemand (Tool-Call) | read-only | Assistenten-Tool `find_offers` über `OffersCollector` (rekursiv, klassifiziert). Findet 04/05 auch verschachtelt in „01 INFOS"; global per Projektname auflösbar (S2). Ergebnisse erscheinen als **anklickbare** Karte mit In-App-Vorschau (S22, reine UI — keine eigene Weiche). |
| `DRIVE_ALL_OFFERS` | Alle Angebote (global) | READ | onDemand (Button „Alle Angebote") | read-only | Aggregiert die 04/05-Belege ALLER Projekte mit Drive-Ordner (`AllOffersCollector`, begrenzt nebenläufig). **Zweispaltig** nach Richtung (Eingehend/Ausgehend), pro Typ gruppiert, **Kategorie-Filter** + Suche (Name/Projekt/Belegnummer). Jede Zeile trägt ihre echte Projektzuordnung. Gleiche `OffersCollector`-Logik + Typ-Whitelist (PDF/Bild/Mail; ZIP/.numbers raus) wie der Projekt-Tab. Klick → In-App-Vorschau. S23 (MYKILOS 7), Ausbau 2026-07-02. |
| `DRIVE_FILE_READ` | Dateiinhalt lesen (Assistent) | READ | onDemand (Tool-Call) | read-only | Assistenten-Tool `read_drive_file` über `DriveFileReader`: findet die Datei per (Teil-)Name rekursiv und liest den **Inhalt** als Klartext (PDF→PDFKit, Google Docs/Sheets/Slides→Export, Text→utf8, gekürzt auf 6000 Zeichen). Braucht `drive.readonly` Scope. Eigene Weiche (S5). |
| `DRIVE_FRAGEBOGEN_PROJEKT_ORDNER` | Fragebogen: echter Projekt-Ordner | WRITE | onDemand (Fragebogen-Bestätigung, Stufe „Lead"/„Projekt mit Ordner") | keine | 2026-07-01, Johannes freigegeben: erste echte (nicht-Sandbox) Drive-Provisionierung, kein `_TEST_PROVISIONING`. Stufe „Projekt mit Ordner": kompletter FolderSchema-v1-Unterbau im echten `PROJEKTE`-Root. Stufe „Als Lead anlegen": NUR der Wurzelordner (kein Unterbau) unter `PROJEKTE/_LEADS/`. Nicht-fatal bei Fehler (Kunde/Projekt sind trotzdem schon angelegt); übersprungen (mit sichtbarem Handshake) statt einer Nummernverschwendung, wenn keine STR-Nr bildbar ist. |

#### Google Gmail

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `GMAIL_SEARCH` | Gmail-Suche/-Lesen (Assistent) | READ | onDemand (Tool-Call) | read-only | Tools `search_gmail` (ganzes Postfach, `anzahl` bis 100) + `read_email` (voller Body, S15). Tool-Daten fließen nur bei `toolsEnabled`-Opt-in an Claude. |
| `GMAIL_DRAFT_CREATE` | Gmail-Entwurf anlegen (Assistent) | WRITE | onDemand (Tool-Call) | nur Karte→Bestätigung→Audit; **VERSENDEN NIE** | Tool `create_draft` → `DraftActionCard` → `AppState.createDraft` (`drafts.create`) + Audit `.draftCreated`. Entwurf erscheint in Gmail **und Apple Mail**. Braucht `gmail.compose`-Scope (M2). S14. |
| `GMAIL_FULL_CACHE` | Postfach-Vollcache | READ | Intervall (geplant) | read-only | **Geplant (L23).** Nur Metadaten+Snippet lokal cachen. Assistent durchsucht Cache. |

#### Google Kalender

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `CALENDAR_LIST` | Kalender-Termine | READ | onDemand (Tool-Call) | read-only | Assistenten-Tool `list_calendar_events`. |
| `CALENDAR_SUGGEST` | Termin-Vorschlag (nur Link) | WRITE | onDemand (Tool-Call) | NIE echter API-Write | Assistenten-Tool `suggest_calendar_event` erzeugt nur eine `calendar.google.com`-URL zum Öffnen im Browser — schreibt NIE in den Google-Kalender. Eigene Weiche (Mandate E). |

#### Google Contacts / Identity

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `CONTACTS_QUERY` | Kontakte-Suche (Assistent) | READ | onDemand (Tool-Call) | read-only | People API `searchContacts` mit Warmup (kalter Index liefert sonst leer, S8). Assistenten-Tool `search_contacts` (persönliche Kontakte des verbundenen Accounts). |
| `CONTACTS_DIRECTORY` | Workspace-Verzeichnis (Kataloge) | READ | onDemand (Suche) | read-only | People API `searchDirectoryPeople`: Team-Profile + admin-geteilte Domain-Kontakte von mykilos.com. `KontakteKatalogTab.searchDirectory`. Braucht `directory.readonly` (M2). NICHT info@-Privatkontakte. S19. |
| `CONTACTS_CREATE` | Kontakt anlegen (Assistent) | WRITE | onDemand (Tool-Call) | nur über Karte→Bestätigung→Audit | Tool `create_contact` erzeugt nur einen Entwurf; erst die Bestätigung an der `ContactActionCard` ruft `AppState.createContact` (People API `people:createContact`) + Audit `.contactCreated`. Assistent schreibt NIE selbst. Braucht `contacts`-Scope (Re-Consent M2). S9. |
| `GOOGLE_USERINFO` | Google Identität | READ | App-Start + Re-Auth | read-only | Ein Login `johannes@mykilos.com` deckt Drive + Mail + Kalender + Kontakte ab. |

#### Claude (Anthropic)

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `CLAUDE_MESSAGES` | Assistent (LLM) | BIDIRECTIONAL | onDemand (Chat) | — | Modell `claude-sonnet-4-6`. Tool-Daten nur bei Opt-in. Streaming via SSE. |
| `ASSISTANT_TOOL_CALL` | Tool-Call Logging (Umbrella) | READ | onDemand (Tool-Run) | Nein | Umbrella-Fallback für ein (noch) nicht gemapptes Tool. Seit Mandate E mappt `AssistantToolManifest` jeden Tool-Lauf auf seine eigene Manifest-ID (z. B. `search_gmail`→`GMAIL_SEARCH`) statt den Roh-Tool-Namen zu loggen — sonst zeigte das Schaltzentrum 0 Handshakes (Forensik F12). |

#### ClickUp

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `CLICKUP_TASKS` | ClickUp Aufgaben | READ | onDemand (Widget/Tool) | read-only | Offene Tasks (`archived=false`). Tools: `list_clickup_tasks` (Fokus-Projekt) + `list_all_clickup_tasks` (projektübergreifend, gruppiert, S11). Daten erst vollständig, wenn ClickUp-Listen-IDs in Airtable gepflegt sind (M3). |

**Studio-OS-Rollout (2026-07-02):** Zwei ClickUp-Schreibpfade, beide additiv/nicht-fatal:
1. **TEST-Sandbox** (`ProjektProvisioningService`, Schritt `.clickUpStruktur`, nur im
   `#if DEBUG`-Sandbox-Bildschirm) — legt bei einer Test-Projekt-Geburt eine ClickUp-Liste +
   8 Standard-Tasks im Ordner `_TEST_PROVISIONING` an (TEST-Präfix, kein echtes Projekt).
2. **ECHTE Fragebogen-Projekt-Anlage** (`AppState.provisioniereEchtesProjekt`) — sobald ein
   echtes Projekt im Fragebogen angelegt wird, entsteht automatisch (kein TEST-Präfix) eine
   ClickUp-Liste im Ordner „01 Kundenprojekte" mit Kunde/Projektnummer/Drive-Link als
   Beschreibung + den 8 Standard-Lebenszyklus-Tasks. **Nicht-fatal:** ein ClickUp-Fehler
   (z. B. nicht verbunden) verhindert nie die Kunde/Projekt/Drive-Anlage — Fehler landen in
   der Schaltzentrale (`CLICKUP_FRAGEBOGEN_PROJEKT_ANLEGEN`). Voraussetzung: ClickUp in den
   Einstellungen verbunden (Personal-API-Token). Details:
   [HANDOFF_MYKILOS8_BLOCK_D.md](handoffs/HANDOFF_MYKILOS8_BLOCK_D.md) §7.

#### Clockodo

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `CLOCKODO_TODAY` | Heutige Zeiteinträge | READ | onDemand (Widget) | read-only | Datensensitiv. Per-User-Keychain. Jeder sieht nur eigene Einträge. |

#### Sevdesk

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `SEVDESK_INVOICES` | Rechnungen (Ist-Umsatz) | READ | onDemand (Widget) | NIE als Tool | Nur Cash-Widget. Nie Assistenten-Tool, nie schreiben. |

#### Lokal (keine Netzwerkverbindung)

| Integrations-ID | Name | Richtung | Trigger | Quelle | Notiz |
|---|---|---|---|---|---|
| `KALKULATION_LOCAL` | Kostenschätzung | READ | onDemand | GRDB `learning.sqlite` | Kein Netzwerk. Lernschicht lokal. Baseline- oder BrainSeed-Anker. |
| `LOCAL_BRAINSEED_PRICE_ANCHORS` | Preis-Anker (BrainSeed) | READ | App-Start | `_Daten/Kalkulation/Brain/active_price_anchors.csv` | 203 Tischler-Anker. Fallback: 6 konservative BaselineAnchors. NIE ins Repo. |
| `LOCAL_DEVICECATALOG_ARTIKEL` | Geräte-Preisbuch | READ | App-Start | `_Daten/Kalkulation/Devices/catalog.csv` | 5.565 Artikel (Gaggenau, Miele, Blum…). Quelle Airtable-DB `appdxTeT6bhSBmwx5` (read-only Export). NIE ins Repo. |
| `DEVICE_CATALOG_LOAD` | Gerätekatalog laden | READ | App-Start | `DeviceCatalog.loadDefault()` | Optional — fehlt die CSV, bleibt Katalog nil, kein Crash. |
| `STUDIO_KNOWLEDGE_QUERY` | Studio-Wissensbasis-Abfrage | READ | onDemand (Tool-Call) | read-only | Assistenten-Tool `query_studio_knowledge` über die lokale `StudioBrain`-Projekthistorie. Eigene Weiche (Mandate E). |
| `ASSISTANT_NOTES` | Assistenten-Notizen (lokal) | WRITE | onDemand (Tool-Call) | nur lokale eigene Daten | Tools `create_note`/`list_notes`/`update_note`/`delete_note`. Lokale Notizen in GRDB, **kein** externer Schreibzugriff. Persistent über Neustart (S4). |
| `ASSISTANT_TASKS` | Assistenten-Aufgaben (lokal) | WRITE | onDemand (Tool-Call) | nur lokale eigene Daten | Tools `create_task`/`list_tasks`/`complete_task`/`delete_task`. Interne To-dos/Erinnerungen (optionales Fälligkeitsdatum) in GRDB v9, **kein** externer Schreibzugriff. Auch sichtbar im Kataloge-Tab „Aufgaben". Persistent über Neustart (S6). |
| `AIRTABLE_CLOCKODO_ADAPTER_ZEITBUCHUNG` | Zeitbuchung an Clockodo-Adapter (Vorgebucht) | WRITE | onDemand (Buchungs-Bestätigung „Ja, buchen") | keine | 2026-07-01, Johannes freigegeben: `ClockodoAdapterWriter` spiegelt jedes lokal bestätigte `TimeSegment` (Timer-Buchung, 2. Schritt der Doppelbestätigung) als "Vorgebucht"-Zeile in die neue Airtable-Base `mykilOS-Adapter Clockodo` (appuQDCFGLmjo2L6T, Tabelle Zeitbuchungen) — nach Mitarbeiter (Vorname aus dem lokalen Profil)/Datum/Kalenderwoche/Projekt/Kostenstelle aufgegliedert. **Best-effort:** die lokale GRDB-Buchung bleibt in jedem Fall gültig, auch wenn dieser Sync fehlschlägt (offline/Airtable nicht verbunden) — kein Blocker, kein Datenverlust, nur ein Fehler im Datenstrom-Log. **Kein echter Clockodo-API-POST** — das bleibt ein separater, späterer Schritt (braucht den persönlichen Clockodo-API-Key je Nutzer aus der Private Area). Stammdaten (Clockodo-Leistungen mit Schätz-Stundensätzen, Kostenstellen) liegen in derselben Base, nur direkt in Airtable editierbar — kein App-Schreibpfad dafür. |
| `WORKBASKET_INTAKE_PERSIST` | Fragebogen-Warenkorb als WorkBasket (lokal) | WRITE | onDemand (Fragebogen-Bestätigung, Stufe „Lead"/„Projekt mit Ordner", nur bei Positionen) | nur lokale eigene Daten | V10-Plan, Phase 1, Block C+D (2026-07-03): `WorkBasketStore` (Wirbelsäule, GRDB, vorher `0` Instanziierungen im App-Code) hängt jetzt an `AppState`. `WarenkorbWorkBasketBridge` (MykilosKit, Foundation-only) mappt die Intake-`Warenkorb`-Positionen (Airtable-Domäne) auf `WorkBasket`/`BasicPick` (Status `.kalkulation`, `inhaltsArt = .artikel`) — **kein Fuzzy-Match**, `projektNummer` kommt ausschließlich aus der soeben kollisionsfrei reservierten `nummer.appFormat`. Läuft **zusätzlich** zum bestehenden `AIRTABLE_WARENKORB_SENDEN`-Pfad (unverändert) — noch keine einzige Quelle der Wahrheit, das kommt erst in Block E. Nicht-fatal: Kunde+Projekt+Drive+Routing sind zu diesem Zeitpunkt schon sicher angelegt. |

---

### Handshake-Protokoll — wie Syncs protokolliert werden

Jeder externe Datenstrom schreibt beim Aufruf einen **Handshake** in `DataFlowLogger`:

```
START  → Sync beginnt
SUCCESS → Sync erfolgreich (recordsRead / recordsWritten / durationMs)
ERROR  → Sync fehlgeschlagen (errorMessage / httpStatus)
```

Der Logger schreibt **immer zuerst lokal** (GRDB, `dataFlowLog`-Tabelle).
Danach spiegelt er nicht-fatal nach Airtable `Datenstrom-Log` — ein Airtable-Ausfall
stoppt nie den eigentlichen Datenstrom.

**Wo sichtbar:** Sidebar → Integrationen (⌘7) → Schaltzentrum-Abschnitt.

---

### Wachstum der Schaltzentrale

Wenn eine neue Integration gebaut wird:
1. `DataFlowLogger.log(integrationID: "NEUE_ID", ...)` im Code eintragen
2. Eintrag in Airtable `Datenstrom-Handbuch` anlegen (sofort, nicht später)
3. Abschnitt in diesem Handbuch ergänzen (mit Feature-Commit)

---

## Webshop & Projektaufnahme (7.7.2)

**Kataloge → Artikel/Shop.** Vollständiger Artikel-Katalog (13.419 Artikel, live aus Airtable):
Vorschaubilder, Kategorie-/Hersteller-Filter, Ansicht als **Liste oder Kacheln**, Seiten-Navigation
mit wählbarer Seitengröße (25/50/100). *Voraussetzung:* Airtable verbunden. Der frühere „Geräte"-Tab
(lokale CSV) ist entfallen — vollständig im Artikel/Shop aufgegangen.

**Kataloge → Warenkörbe.** Liste aller gesendeten Projekt-Warenkörbe (Datum, Bezeichnung, Projekt,
Status, Version, Summen) als Spiegelung der Airtable-Tabelle. Ein Warenkorb ist **wieder aufrufbar**
(Positionen zurück in den Warenkorb laden). Speichern bleibt **append-only** (neue Version, alte
→ archiviert; nie Löschen/Überschreiben).

**Neues Projekt (Fragebogen).** „+ Neues Projekt (Fragebogen)" in Kataloge öffnet den geführten
Küchen-Projekt-Fragebogen (24 Sektionen + Kontakt/Budget/Raum). **Am letzten Schritt
(Bestätigungsansicht) wählst du die Anlege-Stufe** — bewusst nicht vorbelegt, jede Stufe hat ihr
eigenes Minimum an Eingabedaten, das der „Jetzt anlegen"-Button erzwingt (fehlt es, bleibt der
Button gesperrt + roter Hinweistext):

| Stufe | Minimum | Was entsteht |
|---|---|---|
| **Nur Kontakt speichern** | Nachname + (E-Mail ODER Telefon) | Google-Kontakt (People API) **und** Kunde in der Artikel-DB. Kein Projekt, kein Drive-Ordner, kein Routing-Eintrag. |
| **Als Lead anlegen** | + Projektname | zusätzlich ein **Projekt** in der Artikel-DB (+ Erst-Warenkorb) und ein **Rumpf-Ordner** (nur Wurzelordner, kein Unterbau) unter `PROJEKTE/_LEADS/` im echten Drive + ein Mastermind-Routing-Eintrag mit Phase „Lead" (erscheint als Lead in der Galerie). |
| **Projekt mit Ordner + allen Triggern** | + Straße oder Ort (Projekt- oder Kundenadresse, für die STR-Nr) | der volle Umfang: echte Projektnummer, kompletter Drive-Ordnerbaum im echten `PROJEKTE`-Root, Mastermind-Routing-Eintrag mit Phase „Aktiv", Fragebogen-PDF-Upload in `01 INFOS / 07 Fragebogen`. |

Kunde/Projekt-Anlage in der Artikel-DB ist immer append-only (Dublettenschutz: Fetch-vor-Create
über Nachname+E-Mail/Telefon bzw. Projektname+Kunden-Link — ein Retry nach transientem
Netzwerkfehler legt nie doppelt an). Ab „Als Lead anlegen" sind die weiteren Schritte
(Drive-Ordner, Routing-Eintrag, PDF) **nicht-fatal**: Kunde+Projekt sind bereits angelegt, bevor
sie starten — schlägt z. B. der Drive-Ordner fehl, bleibt der Intake trotzdem erfolgreich, aber
die Bestätigungskarte zeigt dann explizit einen Hinweis statt eines blanken Erfolgs, damit
niemand fälschlich glaubt, das Projekt sei schon in der Galerie sichtbar. Fehlt speziell eine
Adresse (Straße/Ort), nennt der Hinweis das konkret (statt eines allgemeinen „bitte Johannes
informieren") — die Lead-Stufe erlaubt bewusst eine adresslose Anlage ohne Ordner.
**Härtung (2026-07-01):** auch der Drive-Ordner/Routing-Schritt selbst ist jetzt dublettengeschützt
(Fetch-vor-Create gegen die Mastermind-„Projekte"-Tabelle, Match auf Titel+Kundennummer) — ein
erneuter Versuch nach einem fehlgeschlagenen Schritt verbrennt keine zweite Projektnummer und
legt keinen zweiten Drive-Ordner/Routing-Eintrag mehr an.
*Voraussetzung:* Google verbunden (Drive-Schreibrecht) für Stufe 2+3, Airtable verbunden für alle.
*Einschränkung:* nur Anlegen, nie Ändern/Löschen bestehender Records — jeder Schritt ist ein
reiner CREATE.

**Warenkorb wird zusätzlich lokal als WorkBasket persistiert (V10-Plan, Phase 1, Block C+D,
2026-07-03).** *Was es tut:* Sobald der Fragebogen-Warenkorb Positionen enthält UND die echte
Projektnummer erfolgreich reserviert wurde (Stufe „Lead"/„Projekt mit Ordner", SCHRITT 4), mappt
`WarenkorbWorkBasketBridge` die Positionen auf einen `WorkBasket` (Status `.kalkulation`,
`inhaltsArt = .artikel`, ein `BasicPick` je Position mit Bezeichnung/Menge/EK/VK/Artikelnummer)
und `AppState.workBaskets` (`WorkBasketStore`, GRDB) speichert ihn lokal ab. *Wo zu finden:* noch
nirgends in der UI sichtbar — reine Persistenz-Schicht, die Sichtbarkeit im Projekt kommt in
Block E (Warenkorb-Panel auf den persistierten WorkBasket umgehängt). *Voraussetzungen:* nur
innerhalb des Fragebogen-Anlage-Flusses, nur bei mindestens einer Warenkorb-Position, nur nach
erfolgreicher Projektnummern-Reservierung. *Einschränkungen:* läuft **zusätzlich** zum
bestehenden `AIRTABLE_WARENKORB_SENDEN` (Airtable-`CartStore`-Pfad bleibt unverändert) — es gibt
noch **keine** einzige Quelle der Wahrheit zwischen beiden. `projektNummer` wird nie geraten
(kein Fuzzy-Match), sondern immer aus der soeben kollisionsfrei reservierten Nummer übernommen.
Nicht-fatal: ein Fehler hier (z. B. GRDB-Schreibfehler) wird geloggt, macht aber die bereits
angelegten Kunde/Projekt/Drive/Routing-Daten nie rückgängig.

**Erinnerungsfunktion + Verwerfen (Härtung, 2026-07-01, Johannes).** Der Fragebogen-Dialog verliert
keine Eingaben mehr beim Schließen (X-Button, Fensterwechsel, Fensterwechsel innerhalb derselben
App-Sitzung) — dieselbe Entwurfs-Instanz bleibt erhalten und ein Wiederöffnen zeigt exakt den
Stand von vorher. Geleert wird der Entwurf nur in zwei Fällen: (1) nach einer **erfolgreichen**
„Jetzt anlegen"-Anlage wird beim Schließen automatisch zurückgesetzt (kein versehentliches
Doppelt-Anlegen derselben Daten), oder (2) über den neuen, expliziten **„Verwerfen"**-Button im
Kopfbereich (mit Sicherheitsabfrage, außer das Formular ist noch leer). Die Persistenz gilt für
die laufende App-Sitzung (kein GRDB/Neustart-Schutz) — passend zu „temporäres Schließen", nicht
zu einem vollständigen App-Neustart.

**Kollisionsschutz + Ordnername-Vorschau (Härtung, 2026-07-01, echte Live-Kollision entdeckt).**
Am 2026-07-01 vergab die Projektnummer-Vergabe zweimal eine bereits belegte Nummer (2026-027 und
2026-028 kollidierten mit real existierenden, manuell in Drive angelegten Ordnern) — die interne
Nummern-Registry kennt nur Airtable-Snapshots und eigene Reservierungen, nie Ordner, die manuell
oder außerhalb der App entstehen. Zwei Härtungen:
1. **Live-Kollisionsprüfung:** Vor jeder echten Nummernvergabe (Fragebogen „Lead"/„Projekt mit
   Ordner" UND Block-D-Sandbox-Test) wird zusätzlich der ECHTE, aktuelle Drive-Ordnerinhalt
   (`PROJEKTE`-Root + `_LEADS` bzw. `_TEST_PROVISIONING`) geprüft. Kollidiert eine frisch
   reservierte Nummer mit einem real existierenden Ordnernamen, wird automatisch die nächste
   versucht (bis zu 25 Läufe) — eine bereits real vergebene Nummer wird nie zurückgegeben.
2. **Ordnername-Vorschau vor der Anlage:** Im letzten Fragebogen-Schritt (Bestätigung) zeigt ein
   neuer Bereich „Vorgeschlagener Ordnername" den vollständigen, kollisionsgeprüften Namen, BEVOR
   „Jetzt anlegen" geklickt wird. Über „Bearbeiten" lässt sich der beschreibende Teil (Kundenname
   + Straßen-Code) manuell anpassen — die laufende Projektnummer selbst ist **nie** editierbar,
   die kommt ausschließlich aus der kollisionsgeprüften Vergabe.

**Kostenstellen = echte Clockodo-Leistungen (Härtung, 2026-07-01, aus Live-Screenshots abgeleitet).**
Die Timer-Kostenstellen waren bisher 5 Platzhalter (Planung/Beratung/Montage/Fahrtzeit/Sonstiges),
die nicht der Realität entsprachen. Aus den echten Clockodo-Screenshots ist jetzt das korrekte
**Zwei-Achsen-Modell** verankert:
- Clockodo **„Kunde/Projekt"** (Mykilos GmbH, Amoulong, Baron-Voght-Straße …) = die **Projekt-
  Achse** (`customers_id`). Kommt in mykilOS aus der Projektnummer — **keine Kostenstelle**.
- Clockodo **„Leistung"** (Kundenberatung, CAD-Planung, Ortstermin …) = die **Kostenstelle**
  (`services_id`). `Kostenstelle.clockodoServiceID` trägt die echte Clockodo-ID, sodass die
  Buchung ohne Rate-Mapping direkt die richtige `services_id` setzt.
Die 10 echten Leistungen sind im Code (`Kostenstelle.defaults`) verankert; 8 mit bekannter
Clockodo-ID, 2 (Bestellungen/Versand) sind in Clockodo vorhanden, aber ihre `services_id` ist
noch nicht erfasst → nicht buchbar bis nachgetragen (kein Raten in echten Abrechnungsdaten). Die
Airtable-Tabelle `Clockodo-Leistungen` (Mirror) enthält jetzt alle 10.

**Clockodo-Buchungs-Resolver (Härtung, 2026-07-01).** `ClockodoBookingResolver` (rein, testbar)
löst beide Clockodo-Achsen auf: Kostenstelle→`services_id` (aus `Kostenstelle.defaults`) und
projektNummer→Projekt→Kunde→`customers_id` (`Customer.clockodoCustomerID`, gelesen aus Airtable
`Kunden.Clockodo-Kunden-ID`). **Sicheres Überspringen statt Raten:** unbekannte Kostenstelle,
Leistung ohne ID, unbekanntes Projekt, Projekt ohne Kunde, ungemappter Kunde → jeweils ein
konkreter Skip-Grund, NIE eine geratene Ersatz-ID in echten Abrechnungsdaten. Die Fallback-Frage
(„ungemappte Kunden auf 'Mykilos GmbH intern' buchen?") ist bewusst offen — aktuell wird
übersprungen. **Kein direkter Clockodo-POST vorgesehen (EISERNE REGEL Clockodo-Postbox):** ein
Schreibzugriff auf die echte Clockodo-API ist nicht geplant und wird es auch nicht sein. Buchungen
laufen ausschließlich über die private Clockodo-Postbox (Airtable-Adapter,
`AIRTABLE_CLOCKODO_ADAPTER_ZEITBUCHUNG`) als Stundenprotokoll für die manuelle Eigeneingabe. Wahre
Zeiten kommen nur lesend aus Clockodo zurück.

**Assistent: destilliertes Gedächtnis Stufe 2 (Härtung, 2026-07-01, Johannes).**
Ergänzt Stufe 1 (System-Prompt-/Tool-Cache-Breakpoints): bei langen Chat-Threads wurde bisher der
komplette Rohverlauf (bis zu 120 Nachrichten, siehe `memoryWindowDays`) bei jedem Turn neu an die
API geschickt — teuer und irgendwann kontraproduktiv (endlos wachsender Kontext). Neu:
- Sobald ein Scope (Home oder ein Projekt-Thread) mehr als 8 Rohnachrichten im Erinnerungsfenster
  hat, werden alle bis auf die letzten 8 zu einer Zusammenfassung verdichtet — aber erst, sobald
  seit der letzten Verdichtung mindestens 12 neue (alte) Nachrichten angefallen sind (Batching,
  kein Verdichtungs-Call bei jedem einzelnen Turn).
- Ein günstiger Haiku-Call (kein Tool-Zugriff) verschmilzt die bisherige Zusammenfassung + die
  neuen alten Nachrichten zu EINER neuen Fassung — überschreibt, häuft nicht an. Ein überholter
  Fakt fällt beim nächsten Verdichtungslauf raus, statt für immer im Kontext zu kleben ("nicht auf
  Kontexte versteifen").
- Die Zusammenfassung landet im System-Prompt (`AssistantGrounding.systemPrompt`), NICHT in der
  Nachrichtenliste — profitiert dadurch vom bestehenden Cache-Breakpoint auf dem System-Block.
  An Claude geht dann nur noch: Zusammenfassung (gecacht) + die letzten 8 Rohnachrichten + der
  neue Turn — nicht mehr die komplette Historie.
- Persistenz: neue GRDB-Tabelle `chatMemorySummaries` (ein Row je Scope, `ChatMemoryStore`),
  Migration `v18_chat_memory_summary`. Cold-Start-getestet.
- Fail-safe: schlägt die Verdichtung fehl (Netzwerk/Store), läuft der Turn unverändert mit der
  vollen Rohhistorie weiter — kein sichtbarer Fehler für den Nutzer.

**Start-Hinweis "aktueller Build" + Aufräumen von Alt-Versionen (Härtung, 2026-07-01, Johannes).**
Auslöser: mehrere parallel installierte mykilOS-Versionen unter `/Applications/` (5.app, 7.5.app,
7.6.6.app, 7.6.8.app, 7.11.0.app — teils mit Ordnername/interner Version auseinanderlaufend, z. B.
"7.5.app" enthielt intern 7.6.1) führten zu einer echten Verwechslung beim Screenshotten (Johannes
testete versehentlich eine alte Version und hielt das für einen Feature-Verlust). Drei Bausteine:
1. **Aufgeräumt:** Alle Alt-Versionen außer der neuesten (`7.11.0.app`) in den Papierkorb verschoben
   (nicht hart gelöscht), eine Sicherungskopie von `7.11.0.app` liegt zusätzlich unter
   `~/mykilOS-App-Backups/`. `MYKILOS Assistent 2.0.app` (andere Bundle-ID `com.mykilos.assistent`,
   eigenständiges Produkt) blieb unangetastet.
2. **`script/cleanup_old_app_versions.sh`** (neu): erkennt alle `/Applications/*.app` mit Bundle-ID
   `de.mykilos.mykilos6`, behält die N neuesten (Default 2), verschiebt den Rest per Finder-Delete
   in den Papierkorb. In `script/create_dmg.sh` mit `KEEP=1` eingehängt — jede künftige Release-
   Session trimmt automatisch vor dem Bauen einer neuen DMG, sodass nach der nächsten Installation
   nie mehr als „aktuell + vorherig" existieren.
3. **`AppFreshnessBanner`** (`MykilOS6App.swift`): kurzes Banner beim App-Start, zeigt Version,
   Git-Commit und Build-Datum aus `AppIdentity` (dieselbe Quelle wie das About-Fenster) — auto-
   verschwindet nach 6 s, manuell schließbar. Zeigt ehrlich „das läuft hier gerade", keine
   Behauptung „das ist weltweit die neueste Version" (dafür gibt es in einer local-first App keine
   Vergleichsgrundlage). Nebenbei behoben: `AboutMykilOSView` zeigte hartkodiert „mykilOS 7.7" statt
   der echten `AppIdentity.version` — seit 8.0.0 falsch, jetzt dynamisch.

**Assistent: Loop-Härtung gegen endloses/teures Suchen (Härtung, 2026-07-01, Johannes).**
Der konversationelle Assistent (`ConversationEngine`) konnte bisher bis zu 6 volle
Claude-Runden brauchen, bevor er aufgab — auch wenn er dieselbe erfolglose Anfrage (z. B. eine
leere Airtable-Suche) mehrfach identisch wiederholte, und ein einzelner hängender Tool-Call
(Google/Airtable/ClickUp ohne Antwort) konnte die ganze Runde blockieren, ohne dass der Nutzer
sie abbrechen konnte. Vier Bausteine:
1. **Wiederholungs-Erkennung:** Stellt Claude innerhalb desselben Chat-Turns denselben Tool-Call
   (Name + Argumente identisch) ein zweites Mal, bricht die Schleife sofort ab, statt bis
   `maxToolRounds` (6) weiterzulaufen — mit einer ehrlichen Antwort („konnte dazu keine neuen
   Daten finden"), statt teure Wiederholungsrunden zu verbrauchen.
2. **Turn-Deadline (45 s):** Unabhängig von der Rundenzahl bricht die gesamte Antwort nach 45
   Sekunden mit einer freundlichen Meldung ab.
3. **Tool-Timeout (15 s):** Ein einzelner Tool-Call, der nicht antwortet, wird nach 15 Sekunden
   als Fehler an Claude zurückgegeben (statt die Runde unbegrenzt zu blockieren) — Claude sieht
   den Fehler wie jeden anderen und kann reagieren.
4. **Echter Abbrechen-Button:** Der Senden-Button im Chat-Composer wechselt während einer
   laufenden Antwort zu einem Stopp-Symbol und bricht bei Klick über `engine.cancel()` wirklich
   ab (kooperative Swift-Task-Cancellation, propagiert bis in den laufenden HTTP-Call) — vorher
   war der Button während der Antwortzeit nur deaktiviert, ohne Abbruchmöglichkeit.
Zusätzlich: `ClaudeChatClient` setzt jetzt `request.timeoutInterval = 30` als Netzwerk-Level-
Absicherung gegen echte HTTP-Hänger (unabhängig von der App-Logik).

**Bestandskunde auswählen (Härtung, 2026-07-01, Johannes).** Im ersten Fragebogen-Schritt
(„Kundenkontakt") steht jetzt oberhalb der manuellen Felder ein Suchfeld „Bestandskunde suchen
(Airtable + Google Kontakte)". Ab 2 Zeichen erscheinen Treffer aus zwei bereits vorhandenen
Quellen: sofort, lokal aus den bereits geladenen Mastermind-Kontakten (`AppState.studioContacts`)
und – nach kurzer Verzögerung, um nicht bei jedem Tastendruck einen Netzwerkaufruf auszulösen –
live aus der echten Google-Kontakte-Suche (People API, gleicher Client wie Kontakte-Widget und
Mail-Assistent). Jede Zeile zeigt Name, Organisation/E-Mail/Telefon und eine Quellen-Markierung
(„Airtable"/„Google"). Ein Klick füllt Vorname, Nachname, Firma, E-Mail und Telefon vor — die
Adresse bleibt bewusst leer, weder die Airtable-Kontakte noch Google-Kontakte liefern strukturierte
Straße/PLZ/Ort-Felder, ein automatisches Zerlegen der Freitext-Adresse wäre reines Raten. Kein
neuer Datenstrom: beide Quellen wurden vorher schon anderswo in der App gelesen (Kontakte-Widget,
Mail-Assistent), hier nur zusätzlich im Fragebogen zugänglich gemacht.

**Diagnose-Härtung (2026-07-01).** Airtable-Fehler HTTP 422 zeigen jetzt Airtables echte
Fehlermeldung inklusive des betroffenen Feldnamens (`AirtableError.validationFailed`), statt nur
des bloßen HTTP-Codes — damit lässt sich die Ursache (z. B. ein unbekannter Select-Options-Wert)
direkt aus der Fehlermeldung ablesen, ohne weiter raten zu müssen.

**Live-Schema-Korrektur (2026-07-01) — was wirklich in Airtable landet.** Ein wiederholter
HTTP 422 („Unknown field name: 'Notizen'") deckte auf, dass mehrere Feldnamen im Kunden-/
Projekt-Write reine Annahmen waren, nie gegen das echte Schema geprüft. Da kein Schema-
Lesezugriff über den MCP-Connector besteht, wurden die echten Feldnamen stattdessen über den
bereits laufenden, echten Read (`ExternalMappingRegistry.syncBusiness`, Vereinigung über alle
vorhandenen Records) ermittelt. Ergebnis: **`Notizen`, `Quelle`, `Projektstatus`, `Budget` und
`Projektart` existieren NICHT** als Felder der echten Kunden-/Projekte-Tabelle — sie wurden bei
jeder Anlage blind gesendet und haben praktisch jede „Projekt mit Ordner"/„Lead"-Anlage blockiert.
Alle fünf wurden aus dem Write entfernt (kein Raten eines Ersatzwerts). Real geschrieben werden
nur noch: Kunden — `Nachname`/`Vorname`/`Firma`/`Kontakt 1 Email`/`Kontakt 1 Telefon`/
`Angebotsadresse Straße`/`PLZ`/`Ort`; Projekte — `Projektname`/`Projektadresse Straße`/`PLZ`/`Ort`/
`Kunde` (Link). **Konsequenz:** die ausführlichen Fragebogen-Angaben (Raumgröße, Stil, Geräte-
Wünsche, Budget, Sonderwünsche, Zeitplanung, Quelle usw.) haben aktuell **keinen Ort in Airtable**
— die Artikel-DB-Tabellen sind für Daniels Geschäfts-/sevDesk-Tracking gedacht, nicht für die
Fragebogen-Detailtiefe. Diese Detaildaten sollen laut Johannes (2026-07-01) in eine **eigene,
sichere Tabelle** in einer neuen, mykilOS-eigenen Airtable-Base (`app2XOhOxXfkLtGVC`) wandern —
noch nicht gebaut, siehe „Warenkörbe-Migration" unten. Der echte `Status`-Wert der Projekte-
Tabelle wird laut Johannes (2026-07-01) über ClickUp gesetzt, nicht über den Fragebogen — bleibt
bewusst offen, bis das ClickUp-Setup steht.

**Warenkörbe-Migration (angekündigt, 2026-07-01, Johannes).** Die Artikel-DB
(`appdxTeT6bhSBmwx5`) darf künftig nicht mehr beschrieben werden — dort arbeitet Daniel an einem
eigenen Strang, Lesen bleibt erlaubt. Geplanter Umzug: NUR die Tabellen `Warenkörbe` +
`Projektartikel` ziehen in eigene, mykilOS-eigene Tabellen in der neuen Base
(`app2XOhOxXfkLtGVC`, aktuell noch Airtables unveränderte Default-Vorlage) um; Kunden/Projekte
bleiben in der Artikel-DB (nur lesend). Bestehende Warenkorb-Records werden dabei in die neue
Base kopiert, nie aus der alten gelöscht. **Noch nicht umgesetzt** — Schema-Design für die neue
Base steht noch aus.

---

---

## mykilOS 8, Block A — Fundament: Eine Wahrheit + Sicherheit

Block A baut überwiegend **Mechanik, nicht Oberfläche** — eine erste UI-Sektion (Projektnummer-
Bindungsvorschläge) ist dazugekommen, siehe unten. Spätere Blöcke (C, D, E, F) bauen direkt auf
der Mechanik auf.

**`ExternalMappingRegistry`** löst die Split-Brain-Verletzung (zwei `Kunden`-/`Projekte`-Tabellen,
Mastermind vs. Artikel-Base) auf: Routing-Wahrheit bleibt Mastermind, Geschäfts-Wahrheit ist die
Artikel-Base, beide werden in **getrennten** lokalen Caches gehalten und primär über die
**Projektnummer** gejoint — nie geraten, nie per Namens-Fuzzy-Match. Solange die Artikel-Base
kein `Projektnummer`-Feld hat (Stand 2026-06-30), bleiben neue Intake-Projekte `businessOnlyUnbound`
— sichtbar über `unboundBusinessProjects()`, nicht versteckt.

**Projektnummer-Bindungsvorschläge (Integrationen-Tab).** Solange das echte Feld fehlt, zeigt
die Schaltzentrum-Ansicht automatisch erkannte Bindungs-Kandidaten — ein Geschäftsprojekt ohne
Nummer, das per **exaktem** Titel-Match (nie mehrdeutig, nie fuzzy) genau einem Mastermind-
Routing-Projekt zugeordnet werden könnte. Ein Klick auf „Bestätigen" macht die Bindung gültig
(Karte→Bestätigung→Audit) — gespeichert rein lokal (GRDB `projectNumberBindings`), **rührt die
Artikel-Projektliste nie an**. Existiert später das echte Feld, gewinnt es automatisch vor dieser
Brücke. *Voraussetzung:* Airtable verbunden, Geschäfts-Registry synct beim App-Start.

**`WriteShadowRecorder`** spiegelt jeden Airtable-Write (aktuell: den Intake-Schreibpfad) als
vollständige Sicherheitskopie — lokal in GRDB (`writeShadowLog`, immer, Cold-Start-getestet)
und nach der eigenen Airtable-Base `mykilOS 8 Backup Base` (`app56DTbSoqPvZhom`, von Johannes
2026-06-30 angelegt, append-only, keine Löschrechte). Scheitert der externe Spiegel (z. B. noch
unverifizierter Tabellenname), bleibt der lokale GRDB-Eintrag die primäre Kopie, und der Fehler
wird sichtbar über `WRITE_SHADOW_BACKUP_FEHLT` gemeldet statt stillschweigend zu verschwinden.

**`ProvisioningModeStore`** ist der TEST/PROD-Schalter (Default `.test`). `.prod` ist hart im
Code gesperrt — es gibt keinen Parameter, der das umgeht — bis Nomenklatur (Block C),
Lern-Runde und Johannes' ausdrückliche Freigabe vorliegen.

**`TestSandboxCleaner`** findet und löscht ausschließlich Airtable-Records mit doppeltem
TEST-Marker (Namens-Präfix `TEST_` UND Feld `Quelle = "TEST"`), zusätzlich abgesichert durch
eine eigene, von der Schreib-Whitelist unabhängige Lösch-Whitelist (`AirtableClient.
testDeletableMap`, Stand 2026-06-30 **leer** — es gibt noch keine echte TEST-Tabelle) und einen
Re-Fetch direkt vor jedem Löschen. `AirtableClient.deleteRecord` ist die einzige Stelle im
gesamten Code, die überhaupt eine DELETE-Anfrage absetzen kann.

---

## mykilOS 8, Block B — Lokales Zeit-Subsystem (Zeiterfassung)

Block B bringt die **lokale Zeiterfassung** — alles rein lokal (GRDB), kein externer Write
(Clockodo-Upload folgt in einem späteren Block). Farbe: Salbei (Zeit/Menschen).

**Projekt-Timer (Projekt-Detailseite → Tab „Zeit").** Großes Clock-Display, Start/Pause/Stopp.
Pro Projekt 3–5 **Kostenstellen-Buttons** (S1: Planung/Beratung/Montage/Fahrtzeit/Sonstiges —
später aus Airtable). Eine Kostenstelle wechseln während der Timer läuft beendet sauber das
laufende Segment und startet ein neues — **keine Zeit geht verloren**, keine Stunde landet im
falschen Topf. *Wo:* Projekt öffnen → Tab „Zeit".

**Single-Instance-Invariante.** Es läuft nie mehr als ein Timer gleichzeitig. Startet man einen
Timer, während in einem anderen Projekt schon einer läuft, erscheint eine **Übernahme-Karte**
(Nachfragen, kein automatisches Umschalten): „Übernehmen" stoppt den alten (→ dessen Buchung wird
bestätigt) und startet danach den neuen.

**Aktiv-Timer-Pille in der Sidebar.** Sichtbar nur wenn ein Timer läuft — Play/Pause-Symbol,
Projekt + Kostenstelle + tickende Zeit. Läuft nichts, ist die Pille unsichtbar. Klick auf die
Pille öffnet den **Check-in**.

**Puls-Erinnerung.** Nach dem eingestellten Intervall (Default 60 Min) **pulsiert die ganze
Sidebar** dezent — ein Hinweis „läuft der Timer noch?". Ignoriert man den Puls, **beruhigt er sich
nach 3 Minuten** wieder bis zur nächsten Marke. Klick auf die Pille → Check-in „Jetzt stoppen" /
„Läuft weiter" (Letzteres setzt die Erinnerungs-Uhr zurück).

**Doppelte Buchungs-Bestätigung.** Stopp zeigt zuerst eine **Übersicht** (welche Kostenstellen,
wie viel Zeit), erst ein zweiter expliziter **„Ja, buchen"** committet die Zeit lokal. Verwerfen
oder Zurück jederzeit möglich. Eine offene Buchung überlebt den App-Neustart (die Karte erscheint
wieder).

**Zielkontingent je Projekt.** Lokal editierbares Soll-Stunden-Kontingent mit Fortschrittsbalken
(gebucht / Ziel) und Herkunfts-Markierung (S1: manuell; automatische Herleitung folgt mit der
Airtable-Anbindung).

*Einschränkungen S1:* alles lokal, keine Clockodo-Buchung; Kostenstellen noch statisch (nicht aus
Airtable); Zielkontingent nur manuell.

---

## mykilOS 8, Block C — Identität + Nomenklatur (S2)

Block C baut die **Nomenklatur-Logik** — die Regeln für Projektnummern, Ordnerschema, Kunden-
identität und Dublettenschutz. Rein lokal, kein externer Write; das eigentliche Provisioning
(Ordner/Records erzeugen) ist Block D. Diese Bausteine sind das Fundament dafür.

**Projektnummer + NumberAuthority.** Das Format `JJJJ-NNN` (App) bzw. `JJJJ_NNN` (Drive-Ordner) ist
einmalig und fortlaufend — strikt **max+1, keine Lücken auffüllen, nie wiederverwenden** (prüft auch
das Archiv). Die Vergabe läuft über eine **austauschbare NumberAuthority** (heute lokal aus dem
Projektbestand + Archiv; perspektivisch von Sevdesk vorgegeben — dann via Airtable/Make, nie direkt).
Gelöschte Projekte werden archiviert, ihre Nummer nie erneut vergeben.

**Kundennummer (Kdnr) ≠ Projektnummer.** Die Kdnr identifiziert den **Kunden** (einzigartig, nicht
fortlaufend, kein Teil des Ordnernamens), die Projektnummer das **Projekt**. Beide werden getrennt
geführt; die Registry löst Kdnr→Kunde, Projektnr→Projekt und Freitext-Token→beides auf. *Neu:* Die
**Kdnr steht jetzt auf der Projekt-Detailseite** in der Übersicht, neben der Projektnummer.

**STR-Nr (letzter Ordnerblock).** Default: abgekürzte **Straße der Baustelle + Hausnummer**
(z. B. HEI8 = Heimhuder 8, KOE66, MUE71 — Umlaute werden transliteriert). Fehlt die Adresse →
**ORT** (Stadt). Für Nicht-Baustellen-Projekte gibt es eine bestätigte **Varianten-Whitelist**
(Geräte/Herd/Quooker/Lightnet/…). Kann der Block weder als Adresse noch per ORT noch als bestätigte
Variante gebildet werden → **Warnung + Block** (kein schema-brechender Ordner).

**Ordnerschema + Konnektoren.** Der Projekt-Ordnerbaum ist **versionierte Daten** (FolderSchema v1),
nicht hartkodiert — so kann er künftig neu schematisiert werden. Jede App-Funktion spricht einen
**logischen Slot** an (z. B. „Fragebogen"), eine Konnektor-Tabelle mappt Slot→aktuellen Ordner.
Ändert sich ein Ordnername, wird nur der Konnektor angepasst, der Code bleibt. (Lokal in GRDB.)

**Anti-Duplikat-Checks.** Vor jeder Kunden-/Projekt-Anlage prüft die Logik, ob Kunde/Kdnr/Projekt
schon existieren (über Name/Firma/E-Mail/Telefon/Kundennummer) — bei Treffer wird **Verknüpfen statt
Neu-Anlegen** angeboten, nichts wird stumm gedoppelt.

**Kostenstellen-Provider.** Die Timer-Kostenstellen (Block B) kommen jetzt über eine Abstraktion:
heute die Default-Liste (lokal pro Projekt überschreibbar), fertig verdrahtet für eine Airtable-
Quelle, sobald ein entsprechendes Projektfeld existiert.

*Einschränkungen S2:* alles lokal, kein externer Write; Kostenstellen-Airtable-Quelle wartet auf ein
Backend-Feld; das echte Ordner-/Nummern-Provisioning kommt in Block D (Sandbox).

---

## mykilOS 8, Block D — Provisioning in der Sandbox (S4)

Block D macht aus der Nomenklatur (Block C) eine **Projekt-Geburt**: eine bestätigte Karte → ein
neues Projekt entsteht in mehreren Systemen gleichzeitig. **Der erste Block, der echt nach außen
schreibt** — aber ausschließlich gated in die **TEST-Sandbox** (Johannes' Entscheidung: echte
Sandbox-Writes scharf, Clockodo erst Block E, ClickUp nur als Gerüst).

**ProjektProvisioningService (Drive + Airtable).** Eine Geburt legt an:
1. **Drive:** unter `_TEST_PROVISIONING/` einen Projektordner `JJJJ_NNN_Kunde_STR-Nr` + den
   kompletten Unterordnerbaum aus FolderSchema v1 (über die Konnektoren).
2. **Airtable:** einen Projekt-Record, **TEST-markiert** (Namens-Präfix `TEST_` + Feld `Quelle=TEST`).

**Garantien (alle testbewiesen):**
- **Idempotent** (Schlüssel Kdnr + Projektnummer): ein zweiter Lauf erzeugt nichts Neues — Drive über
  find-or-create, Airtable über Bestandsprüfung + Ledger-ID.
- **Teilfehler-fest:** nach jedem Schritt wird der Ledger persistiert; bricht Schritt 2 ab, bleibt
  Schritt 1 sauber erledigt, ein Re-Run nimmt genau dort wieder auf.
- **Jeder Schritt wirft**, die Geburt ist **ein** Audit-Eintrag + Write-Shadow je externem Write.
- **Gated:** nur `ProvisioningMode = .test`; PROD bleibt gesperrt.

**Update 2026-07-01:** Die Test-Karte „Projekt-Geburt — TEST-Sandbox" in der Schaltzentrale ist
entfallen — die Ordnerbaum-Logik lebt jetzt direkt im Fragebogen-Dialog (echte Provisionierung,
siehe „Webshop & Projektaufnahme" oben) statt in einem separaten Integrations-Testwerkzeug. Die
Baum-Logik selbst ist geteilt (`DriveOrdnerbaumBuilder`) — `ProjektProvisioningService` (TEST-
Sandbox, gated) und die echte Fragebogen-Provisionierung nutzen dieselbe Implementierung, nur mit
unterschiedlichem Parent-Ordner. Die TEST-Sandbox-Fähigkeit selbst bleibt bestehen und getestet
(`ProvisioningServiceTests`), nur ohne eigenen UI-Einstieg.

**ClickUp-Routing-Gerüst.** Die Adapter-Tabelle (welcher User bekommt wann was, triggert wohin) als
Datenmodell — **kein echter ClickUp-Write**; der konkrete Baum wird live in einer späteren Session
geroutet.

*Einschränkungen S4:* nur TEST-Sandbox (PROD gesperrt); Clockodo-Schritte erst Block E; ClickUp nur
Gerüst; der Intake-Drive-Upload-Trigger ist noch nicht scharf (braucht `drive.file`-Re-Consent +
Klärung echter Ordner vs. Sandbox).

---

*Dieses Dokument wird mit jedem Feature-Commit aktualisiert.*
*Letzte Änderung: 2026-07-03 · feat/mykilos8-block-d-provisioning · Projektnummer-Kollisionsschutz
(echte Live-Kollision entdeckt + gefixt: Live-Drive-Check vor jeder Nummernvergabe + Ordnername-
Vorschau/Edit-Modus im Fragebogen), mykilOS-8.0-Konsolidierung: HYPERBUILD/CLAUDE.md-Doku-Wahrheit,
toter Code raus (AssistantWidget, Fragebogen-Stubs, Bootstrap-Sondierung), Anthropic Prompt-Caching,
GmailCacheStore verdrahtet, M3 ClickUp-Listen-IDs teilweise live verlinkt (10 von 33 Projekten,
live gegen Airtable geprüft 2026-07-01 — noch nicht vollständig, siehe HYPERBUILD.md M3),
Clockodo-Adapter-Base aufgebaut
(Stundensätze/Kostenstellen-Stammdaten + ClockodoAdapterWriter: Timer-Buchungen → Zeitbuchungen-
Tabelle), Bestandskunde-auswählen im Fragebogen (Airtable+Google), Artikel-Katalog-Cache,
Gmail-Parallelfetch, Assistent-Chat-Scroll-Fix, Live-Schema-Diagnose, CartStore-Feld-ID-Fix,
Mail-Entwürfe-Ordner, Assistent-Loop-Härtung (Wiederholungs-Erkennung, Tool-Timeout 15s,
Turn-Deadline 45s, echter Abbrechen-Button, Netzwerk-Timeout ClaudeChatClient), Alt-Versionen-
Aufräumen + Retention-Skript + AppFreshnessBanner-Starthinweis, destilliertes Gedächtnis Stufe 2
(ChatMemoryStore, Verdichtung ab Schwelle statt endlos wachsender Rohverlauf), toter Code raus
(ComingTabView/ComingSoonView), Clockodo-Postbox-Grundlage (`AIRTABLE_CLOCKODO_ADAPTER_ZEITBUCHUNG`
statt direktem API-POST, per EISERNER Regel 2026-07-03), PDF-Import (SHA256-Dedup +
Eingehende-Angebote, Schreiben blockiert bis Whitelist-Freigabe)*
