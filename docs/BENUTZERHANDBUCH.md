# mykilOS 6 — Benutzerhandbuch

**Stetige Mitschrift aller Funktionen. Stand: 2026-06-28 · Version 6.4.0**
Jede neue Funktion wird hier beim Build dokumentiert. Dieses Dokument ist kein
Abschlussdokument — es wächst mit der App.

---

## Navigation

Die App öffnet sich mit der **Projektgalerie**. Die linke Sidebar enthält alle
Hauptbereiche. Tastenkürzel:

| Kürzel | Bereich |
|--------|---------|
| ⌘1 | Heute |
| ⌘2 | Projekte |
| ⌘3 | Assistent |
| ⌘4 | Dateien |
| ⌘5 | Angebote |
| ⌘6 | Kalkulation |
| ⌘7 | Integrationen |
| ⌘8 | Kataloge |
| ⌘⇧S | Sidebar ein-/ausblenden |

---

## Heute-Board

**Was es tut:** Übersicht über den aktuellen Arbeitstag — Signal-Strip, Drive-Ordner-Status,
offene Aufgaben und Kalender-Ereignisse auf einen Blick.

**Wo:** Sidebar → Heute (⌘1)

**Funktionen:**
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
- Projekte nach Nummer (`JJJJ-NR`) sortiert
- **Favoriten-Stern** auf jeder Karte (und im Projekt-Detail-Header): pinnt das Projekt
  ins Heute-Board. Persistent (GRDB), überlebt Neustart. Stern erneut tippen = entfernen.
- Klick öffnet Projektdetailseite

---

## Projektdetailseite

**Was es tut:** Zeigt alle Informationen und Werkzeuge eines Projekts.

**Tabs:**

### Übersicht
Widget-Board mit bis zu 8 Widget-Arten: Drive, Aufgaben (ClickUp), Kontakte,
Cash/Umsatz, Kalender, Notizen, Mail, Assistent-Insights.

Widgets sind drag-and-drop sortierbar. Jedes Widget zeigt Quelle und SaveState.

### Assistent
Konversationeller Chat, scoped auf dieses Projekt. Claude hat Kontext über
Projektnummer, verknüpfte Drive-Ordner, ClickUp-Liste und Kalender-Suche.
Tool-Use (Drive/Mail/Kalender/Kalkulation) nur bei aktiviertem Opt-in.

### Dateien
Datei-Baum des verknüpften Google-Drive-Projektordners. Unterordner werden
lazy geladen (on-demand). Ist der Ordner über **Google Drive für Desktop** lokal
materialisiert, zeigt die Quellzeile „· LOKAL"; ein Klick auf eine Datei öffnet
dann eine echte **PDFKit-Vorschau** und „Im Finder öffnen" startet die macOS-
Vorschau — **nicht** den Browser. Rechtsklick → **„Im Finder zeigen"** selektiert
die Datei/den Ordner im Finder. Ist nichts lokal vorhanden, bleibt der Browser-
Fallback (`webViewLink`).

**Wie das Routing funktioniert:** `LocalDriveRootResolver` sucht unter
`~/Library/CloudStorage/GoogleDrive-*` den Ordner/die Datei über das Drive-File-
Stream-xattr `com.google.drivefs.item-id#S` (Item-ID-Abgleich), Namens-Fallback.
Optionaler Vorrang: ein expliziter Pfad in Airtable `driveFolderPath`.

**Voraussetzung:** Google-Konto verbunden (Settings → Google); für lokale Vorschau
zusätzlich Google Drive für Desktop mit materialisiertem (heruntergeladenem) Ordner.

### Angebote
Zwei Spalten — eingehende (`05 …`) und ausgehende (`04 …`) Belege —, rekursiv
gesammelt und nach Dokumenttyp gruppiert. **Vorschau** (Icon-Klick) rendert ein
echtes PDF: lokal materialisiert per PDFKit, sonst per read-only Drive-Download
(`downloadContent`) — **nicht** im Browser. **Öffnen** (Klick auf den Namen) startet
lokal-zuerst die macOS-Vorschau, nur ohne lokale Datei den Browser-Fallback.
Rechtsklick → **„Im Finder zeigen"**. Read-only — nie Schreiben.

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
Tools (Mail, Kalender, Drive) nur bei aktivem Opt-in (Schalter in der Chat-UI).

**Schätzchat-Modus**: Separater Toggle (amber). Aktiviert ausschließlich das
`schaetze_projekt`-Tool — kein Mail/Kalender/Drive-Datenzufluss. Erlaubt
Schätzungen ohne verbundenes Projekt.

### Dateien (global)
Alle Drive-Dateien des Accounts, nach Änderungszeit sortiert.

**Voraussetzung:** Google-Konto verbunden.

### Angebote (global)
Projektliste links, Angebots-PDFs des gewählten Projekts rechts.

### Integrationen (⌘7)
Datenstrom-Schaltzentrale: zeigt alle 28 Weichen aus `DatastromManifest.json`
mit letztem Handshake-Zeitstempel und Verbindungsstatus (grün/rot/grau).
Jede Weiche hat eine eindeutige `Integrations-ID` die exakt dem `DataFlowLogger`-Eintrag
im Code entspricht.

Ebenfalls hier: verbundene Dienste (Google, Airtable, ClickUp, Clockodo, Sevdesk, Claude).

### Kataloge (⌘8)
Gerätekatalog read-only. Suche nach Hersteller, Beschreibung oder Artikelnummer.
Zeigt MYKILOS-VK. Quelle: `_Daten/Kalkulation/Devices/catalog.csv`
(5.565 Artikel aus Airtable-DB `appdxTeT6bhSBmwx5` — nur Export, nie schreiben).

**Voraussetzung:** CSV-Datei muss im `_Daten/`-Ordner liegen (nicht im Repo).

### Kalkulation
Kostenschätzungs-Engine (mykilO$$-Integration). Freitext-Eingabe einer
Projektbeschreibung → Min/Mitte/Max-Netto-Schätzung mit Konfidenz-Badge.

**Datenquellen (lokal, kein Netzwerk):**
- `_Daten/Kalkulation/Brain/active_price_anchors.csv` — 203 Tischler-Preisanker
- `_Daten/Kalkulation/Devices/catalog.csv` — 5.565 Geräte/Beschläge
- Fallback: BaselineAnchorProvider (6 konservative Regelanker)

**Lern-Loop:** Bestätigte Anpassungen (Faktor + Grund) werden append-only
gespeichert. Kandidaten können per "Übernehmen" zu aktiven Faktoren promoted
werden → zukünftige Schätzungen verschieben sich.

---

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
API-Key in Keychain. Modell: `claude-sonnet-4-6`. Powers den konversationellen
Assistenten. Tool-Daten fließen nur bei aktivem Opt-in an die API.

---

## Identität & Private Area

**Wo:** Settings → Identität / Private Area

- **Identität**: zeigt verbundenes Google-Konto (Avatar, Domain, E-Mail).
  6-Dot Traffic-Light zeigt Verbindungsstatus aller Integrationen.
- **Private Area**: nutzer-eigene Credentials (Clockodo, perspektivisch weitere).
  Visuell getrennt von geteilten Integrationen.
- **Cache leeren**: löscht lokale GRDB-Daten ohne App-Neuinstallation.

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

---

## Assistent — Tool-Use

Wenn Tools aktiviert sind, kann der Assistent folgende Aktionen ausführen
(alle **read-only**, Bestätigung per Action-Card bei Schreibaktionen):

| Tool | Was es tut | Opt-in |
|------|-----------|--------|
| `search_gmail` | Sucht Mails nach Query | toolsEnabled |
| `list_calendar_events` | Liest Kalender-Termine | toolsEnabled |
| `suggest_calendar_event` | Bereitet einen Termin vor → Aktionskarte „Im Kalender öffnen" (kanonischer Google-Link, kein API-Write, KEIN fabrizierter Inline-Link) | toolsEnabled |
| `list_drive_folder` | Listet Drive-Ordner-Inhalt | toolsEnabled + driveFolderID |
| `find_offers` | Findet Angebote/Rechnungen im Drive (rekursiv, auch in „01 INFOS"); global per Projektname | toolsEnabled |
| `read_drive_file` | Liest den **Inhalt** einer Drive-Datei als Klartext (PDF via PDFKit, Google Docs/Sheets/Slides via Export, Text); findet die Datei per (Teil-)Name rekursiv im Projektordner | toolsEnabled |
| `list_clickup_tasks` | Liest ClickUp-Aufgaben | toolsEnabled + clickUpListID |
| `search_contacts` | Sucht Google-Kontakte | toolsEnabled |
| `schaetze_projekt` | Kostenschätzung (lokal) | toolsEnabled oder schaetzModus |
| `query_studio_knowledge` | Fragt Slack-Brain | toolsEnabled |
| `search_katalog` | Sucht Gerätekatalog (Hersteller, Artikelnr., VK) | toolsEnabled, kein SchaetzModus |
| `lookup_kunde` | Sucht Airtable-Kunden (Name/Kundennr./Projektanzahl, lokaler Sync-Cache) | toolsEnabled |
| `create_note` / `list_notes` / `update_note` / `delete_note` | **Notizen/Erinnerungen** anlegen, auflisten, ändern, löschen (lokal, persistent) — die einzigen **Schreib**-Tools, nur eigene lokale Daten | toolsEnabled |

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

### Alle Weichen (Stand 2026-06-29 · 29 Weichen)

#### Airtable

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `AIRTABLE_KUNDEN_PROJEKTE` | Kunden & Projekte | READ | App-Start + manuell | read-only | System-of-Record für Projekte/Kunden. Paginiert (offset). Schreibt nie zurück. |
| `AIRTABLE_KUNDEN_LOOKUP` | Kunden-Lookup (Assistent) | READ | onDemand (Tool-Call) | read-only | Assistenten-Tool `lookup_kunde` über den **lokalen** Sync-Cache (kein Live-Call): Name, Kundennummer, Projektanzahl. Keine E-Mail/Telefon (→ search_contacts). Eigene Weiche (L24). |
| `DATAFLOW_LOG_WRITE` | Datenstrom-Log | WRITE | Ereignisgesteuert | append-only (Mastermind) | Jeder Sync-Handshake landet hier. Harte Whitelist im AirtableClient: nur diese Tabelle + Handbuch. |
| `DATAFLOW_HANDBOOK_WRITE` | Datenstrom-Handbuch | WRITE | onDemand (Session) | append-only (Mastermind) | Diese Karte selbst. Jede neue Weiche wird hier registriert. |
| `POLISH_LOG_WRITE` | Dampflok Polish-Log | WRITE | onDemand (Session) | append-only (Mastermind) | Nur Claude-Code-Agent, nicht die App. Tabelle `tblberJMgRArGSypE`. |

#### Google Drive

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `DRIVE_POLL_OFFERS` | Angebots-PDF-Watcher | READ | Intervall (60s) + manuell | read-only | Baseline-Semantik: erster Poll meldet nichts. Handshake nur bei echtem Treffer (neues PDF). |
| `DRIVE_FILES_TAB` | Dateien-Tab (Finder-Baum) | READ | onDemand (Tab öffnen) | read-only | Nur Metadaten (Name/Typ/Datum/Größe). `drive.metadata.readonly` Scope. |
| `DRIVE_OFFERS_TAB` | Angebote-Tab | READ | onDemand (Tab öffnen) | read-only | Gleiche Erkennungslogik wie `DriveOfferWatcher.detectOffers`. |
| `DRIVE_MATERIAL_TAB` | Material-Tab | READ | onDemand (Tab öffnen) | read-only | Tolerant per Ordnername gematcht (`05 Material` o.ä.). |
| `DRIVE_ASSISTANT_LIST` | Drive-Ordner-Listing (Assistent) | READ | onDemand (Tool-Call) | read-only | Assistenten-Tool `list_drive_folder`. Nur Metadaten, nie Dateiinhalte. Eigene Weiche (Mandate E). |
| `DRIVE_OFFERS_FIND` | Angebote-Suche (Assistent) | READ | onDemand (Tool-Call) | read-only | Assistenten-Tool `find_offers` über `OffersCollector` (rekursiv, klassifiziert). Findet 04/05 auch verschachtelt in „01 INFOS"; global per Projektname auflösbar (S2). |
| `DRIVE_FILE_READ` | Dateiinhalt lesen (Assistent) | READ | onDemand (Tool-Call) | read-only | Assistenten-Tool `read_drive_file` über `DriveFileReader`: findet die Datei per (Teil-)Name rekursiv und liest den **Inhalt** als Klartext (PDF→PDFKit, Google Docs/Sheets/Slides→Export, Text→utf8, gekürzt auf 6000 Zeichen). Braucht `drive.readonly` Scope. Eigene Weiche (S5). |

#### Google Gmail

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `GMAIL_SEARCH` | Gmail-Suche (Assistent) | READ | onDemand (Tool-Call) | read-only | Nur Metadaten + Snippet. Tool-Daten fließen nur bei `toolsEnabled`-Opt-in an Claude. |
| `GMAIL_FULL_CACHE` | Postfach-Vollcache | READ | Intervall (geplant) | read-only | **Geplant (L23).** Nur Metadaten+Snippet lokal cachen. Assistent durchsucht Cache. |

#### Google Kalender

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `CALENDAR_LIST` | Kalender-Termine | READ | onDemand (Tool-Call) | read-only | Assistenten-Tool `list_calendar_events`. |
| `CALENDAR_SUGGEST` | Termin-Vorschlag (nur Link) | WRITE | onDemand (Tool-Call) | NIE echter API-Write | Assistenten-Tool `suggest_calendar_event` erzeugt nur eine `calendar.google.com`-URL zum Öffnen im Browser — schreibt NIE in den Google-Kalender. Eigene Weiche (Mandate E). |

#### Google Contacts / Identity

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `CONTACTS_QUERY` | Kontakte-Suche | READ | onDemand (Tool-Call) | read-only | People API `searchContacts`. Assistenten-Tool kommt in Welle 1. |
| `GOOGLE_USERINFO` | Google Identität | READ | App-Start + Re-Auth | read-only | Ein Login `johannes@mykilos.com` deckt Drive + Mail + Kalender + Kontakte ab. |

#### Claude (Anthropic)

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `CLAUDE_MESSAGES` | Assistent (LLM) | BIDIRECTIONAL | onDemand (Chat) | — | Modell `claude-sonnet-4-6`. Tool-Daten nur bei Opt-in. Streaming via SSE. |
| `ASSISTANT_TOOL_CALL` | Tool-Call Logging (Umbrella) | READ | onDemand (Tool-Run) | Nein | Umbrella-Fallback für ein (noch) nicht gemapptes Tool. Seit Mandate E mappt `AssistantToolManifest` jeden Tool-Lauf auf seine eigene Manifest-ID (z. B. `search_gmail`→`GMAIL_SEARCH`) statt den Roh-Tool-Namen zu loggen — sonst zeigte das Schaltzentrum 0 Handshakes (Forensik F12). |

#### ClickUp

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `CLICKUP_TASKS` | ClickUp Aufgaben | READ | onDemand (Widget) | read-only | Offene Tasks (`archived=false`). Assistenten-Tool in Entwicklung. |

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
| `ASSISTANT_NOTES` | Assistenten-Notizen (lokal) | WRITE | onDemand (Tool-Call) | nur lokale eigene Daten | Tools `create_note`/`list_notes`/`update_note`/`delete_note`. EINZIGE Schreib-Tools des Assistenten — nur lokale Notizen in GRDB, **kein** externer Schreibzugriff. Persistent über Neustart (S4). |

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

*Dieses Dokument wird mit jedem Feature-Commit aktualisiert.*
*Letzte Änderung: 2026-06-28 · polish/dampflok · L6–L15 abgeschlossen*
