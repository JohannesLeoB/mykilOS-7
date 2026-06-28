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

---

## Projektgalerie

**Was es tut:** Listet alle aktiven Projekte. Quelle: Airtable `Projekte`-Tabelle
(`appuVMh3KDfKw4OoQ`), automatisch synchronisiert beim App-Start.

**Wo:** Sidebar → Projekte (⌘2)

**Funktionen:**
- Projekte nach Nummer (`JJJJ-NR`) sortiert
- Favoriten-Stern (noch in Entwicklung — L25)
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
Finder-Baum des verknüpften Google-Drive-Projektordners. Unterordner werden
lazy geladen (on-demand). Öffnet Dateien im Browser per Klick.

**Voraussetzung:** Google-Konto verbunden (Settings → Google).

### Angebote
Zeigt alle Angebots-/Rechnungs-PDFs aus dem Drive-Ordner (`04 Angebote`-
Unterordner oder per Keyword erkannt: angebot/rechnung/kostenvoranschlag).
Read-only — öffnet im Browser.

### Timeline
Platzhalter — in Entwicklung (L27).

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

## Assistent — Tool-Use

Wenn Tools aktiviert sind, kann der Assistent folgende Aktionen ausführen
(alle **read-only**, Bestätigung per Action-Card bei Schreibaktionen):

| Tool | Was es tut | Opt-in |
|------|-----------|--------|
| `search_gmail` | Sucht Mails nach Query | toolsEnabled |
| `list_calendar_events` | Liest Kalender-Termine | toolsEnabled |
| `suggest_calendar_event` | Erzeugt Kalender-URL (kein API-Write) | toolsEnabled |
| `list_drive_folder` | Listet Drive-Ordner-Inhalt | toolsEnabled + driveFolderID |
| `list_clickup_tasks` | Liest ClickUp-Aufgaben | toolsEnabled + clickUpListID |
| `search_contacts` | Sucht Google-Kontakte | toolsEnabled |
| `schaetze_projekt` | Kostenschätzung (lokal) | toolsEnabled oder schaetzModus |
| `query_studio_knowledge` | Fragt Slack-Brain | toolsEnabled |

Alle Tool-Calls werden via `DataFlowLogger` lokal protokolliert.

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

### Alle Weichen (Stand 2026-06-28 · 22 Weichen)

#### Airtable

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `AIRTABLE_KUNDEN_PROJEKTE` | Kunden & Projekte | READ | App-Start + manuell | read-only | System-of-Record für Projekte/Kunden. Paginiert (offset). Schreibt nie zurück. |
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

#### Google Gmail

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `GMAIL_SEARCH` | Gmail-Suche (Assistent) | READ | onDemand (Tool-Call) | read-only | Nur Metadaten + Snippet. Tool-Daten fließen nur bei `toolsEnabled`-Opt-in an Claude. |
| `GMAIL_FULL_CACHE` | Postfach-Vollcache | READ | Intervall (geplant) | read-only | **Geplant (L23).** Nur Metadaten+Snippet lokal cachen. Assistent durchsucht Cache. |

#### Google Kalender

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `CALENDAR_LIST` | Kalender-Termine | READ | onDemand (Tool-Call) | read-only | `suggest_calendar_event` erzeugt nur eine URL — kein API-Write. |

#### Google Contacts / Identity

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `CONTACTS_QUERY` | Kontakte-Suche | READ | onDemand (Tool-Call) | read-only | People API `searchContacts`. Assistenten-Tool kommt in Welle 1. |
| `GOOGLE_USERINFO` | Google Identität | READ | App-Start + Re-Auth | read-only | Ein Login `johannes@mykilos.com` deckt Drive + Mail + Kalender + Kontakte ab. |

#### Claude (Anthropic)

| Integrations-ID | Name | Richtung | Trigger | NO-GO | Notiz |
|---|---|---|---|---|---|
| `CLAUDE_MESSAGES` | Assistent (LLM) | BIDIRECTIONAL | onDemand (Chat) | — | Modell `claude-sonnet-4-6`. Tool-Daten nur bei Opt-in. Streaming via SSE. |
| `ASSISTANT_TOOL_CALL` | Tool-Call Logging | READ | onDemand (Tool-Run) | Nein | Seit L5: jeder `registry.run()`-Aufruf → `DataFlowLogger`-Eintrag (integrationID = Tool-Name). Opt-in nötig. |

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

**Wo sichtbar:** Settings → Schaltzentrum (geplant, L7). Aktuell: GRDB direkt.

---

### Wachstum der Schaltzentrale

Wenn eine neue Integration gebaut wird:
1. `DataFlowLogger.log(integrationID: "NEUE_ID", ...)` im Code eintragen
2. Eintrag in Airtable `Datenstrom-Handbuch` anlegen (sofort, nicht später)
3. Abschnitt in diesem Handbuch ergänzen (mit Feature-Commit)

---

*Dieses Dokument wird mit jedem Feature-Commit aktualisiert.*
*Letzte Änderung: 2026-06-28 · polish/dampflok*
