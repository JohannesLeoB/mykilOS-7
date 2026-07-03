# HANDOFF — Provisioning & Nomenklatur (aus dem Bestand gelernt, 2026-06-30)

```
Quelle:  Echter Drive-Mount gelesen — /…/MYKILOS Team/PROJEKTE/ (39 Einträge) + _BEISPIELORDNER.
Zweck:   Verbindliche Regeln für Projekt-/Kundennummern + Drive-Ordnerbaum für mykilOS 8 (S2/S4).
Modus:   Erst lernen, dann zementieren. Sessions fragen Johannes LIVE, wo/wie Ordner+DBs angelegt werden.
```

## 1. Nummernkreis (aus dem echten Bestand)

- **Format Projektordner:** `JJJJ_NNN_Kunde_STR-Nr` (Jahr `_` 3-stellige laufende Nr `_` Kunden-Slug `_` Adressblock).
- **2026 vergeben:** 001-004, 006, 007, 012-029 (Lücken 005, 008-011 — vermutlich Archiv/Leads).
- **➡️ NÄCHSTE 2026-Nummer = `2026_030`** (App-Format `2026-030`).
- **Regel:** strikt **max+1**, **keine Lücken auffüllen**, **nie wiederverwenden**. Beim Vergeben **auch
  `_PROJEKTE_ARCHIV` mitprüfen** (alte Nummern existieren dort). Anomalie `2026_20_Liebig_Quooker` (nicht
  3-stellig) → künftig normalisieren auf `020`.
- **Beim Löschen eines kompletten Projekts:** Projektnummer **archivieren**, **nie** erneut benutzen
  (eigene `archivierteProjektnummern`-Liste/Tabelle, gegen die jede Neuvergabe prüft).
- **Projektnummer (`JJJJ_NNN`) = einmalig**, fortlaufend (max+1), nie wiederverwendet. **Ist** Teil des
  Drive-Ordner-/Projektnamens.
- **Kundennummer (Kdnr) — geklärt:** **einzigartig pro individuellem Kunden**, **NICHT fortlaufend** (kein
  Jahr+Nr-Schema), und **NICHT** Teil der Drive-Ordner- oder Projektbenennung. Sie wird **in Airtable gelesen /
  nach Schema geschrieben / künftig aus Sevdesk vorgeschrieben** (Sevdesk-Route §8 — immer indirekt via Make,
  nie direkt aus der App). Eigener Kundenschlüssel **neben** der Projektnummer; die ExternalMappingRegistry (S2)
  hält Kdnr (Kunde) und Projektnummer (Projekt) **getrennt**.
- **UI:** Die **Kdnr wird auf der Projekt-Detailseite in der Übersicht angezeigt** (neben der Projektnummer).

## 2. Letzter Block `STR-Nr` — Regel + real existierende Varianten

- **Default-Regel:** abgekürzte **Straße der Baustelle + Hausnummer** (Großbuchstaben), z. B.
  `HEI8` = Heimhuder 8, `KOE66`, `HAR12`, `ALS46`, `FLO32`, `DWA27`, `LEI26`, `ROT44`, `MUE71`.
- **Fallback:** fehlt Straße/Hausnr → **`ORT`** (Stadt der Baustelle).
- **⚠️ Bestand zeigt Varianten** (nicht jeder Block ist Adresse): Produkt-/Kontext-Token bei Nicht-Baustellen-
  Projekten — `Geraete`, `Herd`, `Quooker`, `Lightnet`, `Serienkueche`, `W-Bank`, `KV5`. Manche ohne Hausnr
  (`SIZ`, `STE`, `PAR`). → Default-Regel bestätigen + Varianten-Whitelist mit Johannes **live** festlegen.
- **Warn-Pflicht:** kann der Block weder als Adresse noch per ORT-Fallback noch als bestätigte Variante
  gebildet werden → **Maskenübermittlung warnt + blockt** die Anlage (kein schema-brechender Ordner).

## 3. Voller Ordnerbaum (Vorlage `_BEISPIELORDNER`, filesystem-verifiziert)

```
<JJJJ_NNN_Kunde_STR-Nr>
├── 01 INFOS
│   ├── 01 Pläne · 02 Fotos Bestand · 03 Recherche | Zubehör
│   ├── 04 ausgehende Angebote · 05 eingehende Angebote · 06 Fotos Baustelle
│   ├── 07 Fragebogen        ← Fragebogen-PDF
│   ├── 08 Werkszeichnung · 09 Fotos Mängel
├── 02 CAD
│   └── VectorWorks
├── 03 PRÄSENTATION
│   ├── Moodboards · PDF · Renderings · Vorplanung | Screenshots
└── MYKILOS_Abnahmeprotokoll BLANKO.pdf   (Datei, aus Vorlage mitkopieren)
```

- **Globales Schema = konfigurierbar.** Das Ordnerschema kann künftig **neu angelegt** werden — dann müssen
  Ordner **neu verdrahtet + neu schematisiert** werden. Also: Baum **nicht hartkodieren**, sondern aus einer
  **Schema-Definition** (versioniert, z. B. JSON/Plist „FolderSchema v1") erzeugen, gegen die auch das
  Re-Wiring bestehender Projekte läuft. Provisioning liest das aktive Schema, nicht feste Strings.

## 4. Anti-Duplikat-Checks (Pflicht VOR jeder Anlage)

Bei „Projekt anlegen" / „Kunde anlegen" zuerst prüfen — **nie** Kunde/Projekt/Nummer duplizieren:
1. **Kunde existiert schon?** (Airtable `Kunden` + Drive-Slug + Kontakte abgleichen — Name/Firma/Mail/Tel).
2. **Gab es schon Projekte** für diesen Kunden? (verknüpfte Projekte zeigen).
3. **Existiert schon eine anders gelagerte Kundennummer/Kdnr?** (nicht neu vergeben, sondern die bestehende übernehmen).
4. Bei Treffer → **anbieten zu verknüpfen statt neu anzulegen** (Dublettenschutz-Dialog), nicht stumm doppeln.
5. Projektnummer-Vergabe: max+1 über aktive **und** archivierte Nummern; Kollision → Warnung.

## 5. Clockodo (Gerüst jetzt, Details später)

- Jetzt: **Gerüst + API-Write-Schemata architektieren** (noch nicht live schreiben). Sitzt auf dem schon
  entworfenen Zuhörer (`_archiv/HANDOFF_LIVE_WIRING_4.md`): `POST /api/v2/entries` (`customers_id`, `services_id`,
  `time_since`, `time_until`, `billable`), per-User-Keychain-Key, anonymisierter Rücklauf.
- Liefern: Write-Modell (Request/Response-Typen, Mapping Kostenstelle→Service, Idempotenz/Retry), Tests mit
  Fake-Client. **Kein realer POST**, bis Johannes das Write-Gate freigibt.

## 6. ClickUp (Baum live in künftiger Session)

- **Es existiert noch KEINE** ClickUp-Projekt-/Ordnerstruktur, keine Aufgaben/Routinen/Automatisierungen.
- mykilOS 8 baut den Konnektor + das **Schema** (Routine = Checkliste, Aufgaben = Subtasks, 11-Phasen-Rail
  als Präsentationsschicht — siehe `…/strategie/MASTER_Orchestrierung_mykilOS_ClickUp.md`).
- Der **konkrete Baum** (Spaces/Folders/Lists/Tasks) wird **live in einer künftigen Session** nach mykilOS-
  Vorgaben geroutet — **nicht raten**, mit Johannes zusammen anlegen.

## 7. Arbeitsmodus: LIVE fragen

**Die Sessions fragen Johannes live**, **wo und wie** Ordner oder Datenbanken angelegt werden — bei jedem
neuen Provisioning-Schritt (Drive-Ziel, Airtable-Tabelle/-Base, ClickUp-Baum). Default bleibt: in die
**reversible TEST-Sandbox** (`HANDOFF_TEST_SANDBOX.md`), bis Johannes je Schritt auf PROD freigibt.

## 8. Nummern-Autorität: Adapter-Seam für künftige Sevdesk-Vorgabe

**Vorausschau:** Projekt-/Kundennummern könnten künftig **bindend aus Sevdesk** getriggert/vorgeschrieben
werden. Damit das ohne Umbau geht, läuft Nummernvergabe **nie** über fest verdrahtete Logik, sondern über
einen **`NumberAuthority`-Adapter** (Protokoll). Implementierungen austauschbar:

| Autorität (Implementierung) | Quelle | Status |
|---|---|---|
| `LocalSequentialAuthority` | max+1 aus PROJEKTE-Ordnern + Archiv (heute, §1) | aktiv |
| `AirtableAuthority` | Nummernkreis/Reservierung in Airtable | optional |
| **`SevdeskPrescribedAuthority`** | von Sevdesk vorgegebene Nr — **NIE direkt aus der App**: kommt via **Airtable-Feld, das Make.com aus Sevdesk füllt** (Sevdesk-NO-GO bleibt) | **Zukunft, vorgesehen** |

- Adapter liefert: `nextProjektnummer()`, `reserve(nummer)`, `isVergeben(nummer)` (aktiv+archiviert), `bindFromExternal(quelle, nr)`.
- **Umschaltung per Config** (`numberAuthority = local | airtable | sevdesk`), nicht per Codeänderung. So wird
  Sevdesk später „die Wahrheit", ohne dass Vergabe-Aufrufer angefasst werden. Sevdesk-Zugriff **immer indirekt** (Airtable/Make).

## 9. ClickUp-Routing-Adapter (Tabelle — exaktes In/Out je Ebene)

Neue Routing-Tabelle (Heimat: Airtable `ClickUp-Routing` ODER GRDB-Config — **live mit Johannes entscheiden**).
Jede Zeile = eine Weiche: **welcher User bekommt wann was, und triggert wohin.** Spalten + Beispielzeilen:

| Routing-ID | Ebene | Richtung | App-Objekt | ClickUp-Objekt | Trigger | Wer (User-Scope) | Frequenz | NO-GO |
|---|---|---|---|---|---|---|---|---|
| `CU_GLOBAL_SPACES` | global | app→clickup | Projektliste | Space/Folder-Baum | Provisioning (live) | Admin/Johannes | einmalig | — |
| `CU_PROJ_LIST` | projekt | app→clickup | neues Projekt | List in Projekt-Folder | Projekt-Anlage | Ersteller | je Projekt | nur eigenes Projekt |
| `CU_PROJ_TASKS` | projekt | beide | Aufgaben/Subtasks | Task/Subtask | Status-/Phasenwechsel | Projektteam | on-change | — |
| `CU_ROUTINE_CHECK` | projekt | app→clickup | Routine | Checkliste an Task | Phasen-Eintritt | System | je Phase | — |
| `CU_USER_INBOX` | user | clickup→app | Zugewiesene Tasks | Task (assignee) | Polling/Webhook | je User (eigene) | periodisch | nie fremde Tasks zeigen |
| `CU_USER_TIME` | user | app→clickup | Zeit-Notiz (opt.) | Time/Comment | Buchung (opt.) | je User | on-confirm | nur eigene |

- **Felder je Zeile auch:** `clickupRef` (Space/List/Task-ID, zur Laufzeit), `aktiv` (bool), `optin`, `letzterSync`.
- Der konkrete Baum + die echten ClickUp-IDs werden **live** befüllt (§6). Die Tabelle ist das **Adapter-Schema**,
  gegen das der ClickUp-Konnektor liest/schreibt — Re-Routing = Zeile ändern, nicht Code.

## 10. Ordner-Konnektor-Tabelle (Re-Wiring von Unterordnern)

Damit sich Unterordner ändern/verringern/umordnen können, **ohne Code anzufassen**: jede App-Funktion spricht
einen **logischen Slot** an, nicht einen festen Ordnernamen. Eine **Konnektor-Tabelle** mappt Slot → aktuellen
Ordner. Heimat: Airtable `Ordner-Konnektoren` ODER GRDB-Config (**live entscheiden**). Schema + Beispielzeilen:

| Konnektor-ID (Slot) | Aktueller Ordnername | Pfad-Ebene | Drive-Folder-ID (Laufzeit) | Genutzt von (App-Funktion) | Schema-Version |
|---|---|---|---|---|---|
| `INFOS` | `01 INFOS` | 1 | (live) | Projekt-Root-Lesen | v1 |
| `ANGEBOTE_AUSGEHEND` | `04 ausgehende Angebote` | 2 | (live) | Angebote-Tab, Offers-Watcher | v1 |
| `ANGEBOTE_EINGEHEND` | `05 eingehende Angebote` | 2 | (live) | Kalkulation/Eingangs-Angebote | v1 |
| `FRAGEBOGEN` | `07 Fragebogen` | 2 | (live) | Intake-PDF-Upload | v1 |
| `PRAESENTATION_PDF` | `03 PRÄSENTATION/PDF` | 2 | (live) | Material-Tab | v1 |
| `CAD` | `02 CAD/VectorWorks` | 2 | (live) | (künftig) | v1 |

- **Regel:** Code referenziert nur die **Konnektor-ID**. Ändert sich ein Ordnername/-ort, wird **nur die Tabelle**
  aktualisiert (+ `Schema-Version` hochgezählt) — alle Lese-/Schreibpfade folgen automatisch.
- Beim **Re-Schematisieren** (neues globales Schema, §3): neue Schema-Version anlegen, Konnektoren neu auf die
  neuen Ordner mappen, bestehende Projekte per Migration re-verdrahten. Der `DriveProjectFolderResolver` liest die
  Konnektor-Tabelle statt fester Strings.

## 11. Clockodo-Routing-/Schalter-Tabelle (Projekt-Buchungs-Export · Ins & Outs) — MUSS ANGELEGT WERDEN

**Johannes-Vorgabe: „DIE muss angelegt werden!"** — analog zur ClickUp-Routing-Tabelle (§9), aber für Clockodo:
die **Schalter-Tabelle** für den Projekt-Buchungs-Export mit allen **Ins & Outs**. Sitzt auf dem schon
entworfenen Zuhörer + den bestehenden Airtable-Clockodo-Tabellen (`Clockodo-Nutzer` tblPbly2br8mR2kaU,
`Clockodo-EW-<Name>`, `Clockodo-Buchungen`, `Clockodo-Leistungen`). **Heimat: neue Airtable-Tabelle
`Clockodo-Routing` (live mit Johannes anlegen).** Jede Zeile = eine Weiche: **welcher User bucht wann was,
in welche Tabelle rein und nach Clockodo raus** — User-scoped (jeder nur seine eigenen), Rücklauf anonymisiert.

| Routing-ID | Ebene | Richtung | Quelle | Ziel | Trigger | User-Scope | NO-GO |
|---|---|---|---|---|---|---|---|
| `CL_IN_TIMER` | user | IN | Timer-Segment | persönl. `Clockodo-EW-<User>` (Draft) | Stopp/Buchung | je User, nur eigene | — |
| `CL_IN_CHAT` | user | IN | NLP-Chat („4h CAD für Heinz") | persönl. EW-Tabelle (Draft) | Nachricht | je User | — |
| `CL_IN_MAIL_CAL` | user | IN (Vorschlag) | Gmail/GCal | Draft-Vorschlag | periodisch | je User | Bestätigung nötig |
| `CL_OUT_POST` | user | OUT | bestätigter Draft | Clockodo `POST /api/v2/entries` (per-User-Key) | Confirm/Wochenabschluss | je User, eigener Keychain-Key | nie fremde Buchungen, kein App-Key |
| `CL_OUT_MASTER` | user→projekt | OUT | gebuchter Eintrag | Airtable `Clockodo-Buchungen` (Master-Audit) | nach POST | System | keine PII anderer User |
| `CL_BACK_AGG` | projekt | RÜCKLAUF | Clockodo-Aggregation | Geld-Widget Ist (Soll/Ist) | periodisch | **anonymisiert** je Kostenstelle/Projekt | nie personenbezogen |

- **Felder je Zeile auch:** `clockodoRef` (entry-ID, Laufzeit), `kostenstelle→service`-Mapping (aus Airtable-Projektfeld
  → `Clockodo-Leistungen`), `billable`, `aktiv`, `optin`, `letzterSync`, `status`.
- **Privatheits-Grenze (hart):** Zeit-/Buchungsdaten sind pro Nutzer isoliert (Private Area); Rücklauf nur
  aggregiert/anonymisiert; kein Log/Audit enthält Clockodo-Rohdaten anderer. Re-Routing = Zeile ändern, nicht Code.
- **Block-Zuordnung:** wird in **Block E (Clockodo)** angelegt + verdrahtet — `Clockodo-Routing`-Tabelle **live mit Johannes** erstellen.

> §8–§11 sind **Adapter-Seams**: Nummern, ClickUp-Routing, Ordner-Verdrahtung und **Clockodo-Routing** sind
> **Daten/Config, nicht Code** — so bleibt alles re-routebar, wenn Sevdesk die Nummern vorgibt, ClickUp/Clockodo
> anders verdrahtet werden oder sich der Ordnerbaum ändert. Befüllung/echte IDs immer **live mit Johannes**, Default TEST-Sandbox.
