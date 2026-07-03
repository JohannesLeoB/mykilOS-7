# ClickUp ↔ Projekt-Detailseite — Mapping-Konzept

**Stand 2026-07-03 · Konzept (Bau nach V10-Kern).** Wie ClickUp-Aufgaben und Meilensteine richtig
auf die mykilOS-Projekt-Detailseiten mappen — Custom Fields, Wahrheits-Richtungen, Nerv-Stufen.

**Grundsatz-Rahmen:** ClickUp gilt **nicht als KI** — es wird von Menschen befüllt. mykilOS zeigt
und erinnert; es erstellt/zuweist nie selbst (Eiserne Regel „Aufgaben nur Mensch→Mensch",
CLAUDE.md). Schreiben nach ClickUp: vorerst gar nicht (read-only), später nur gated
Karte→Bestätigung — und Go-Live schaltet ausschließlich Johannes.

---

## 1. Der Join — wie ein Task sein Projekt findet

**Zwei Schlüssel, klare Rollen:**

| Schlüssel | Rolle | Quelle |
|---|---|---|
| `clickUpListID` (bestehendes Handle in `ProjectLinks`) | **Primär:** „die Liste des Projekts" — 1 API-Call, speist das TasksWidget (Muster existiert) | Airtable Mastermind |
| Custom Field **`mykilos_project_id`** (Format `JJJJ-NNN`) | **Sekundär/listenübergreifend:** findet projektzugehörige Tasks AUSSERHALB der Projektliste (z. B. Slack-Archiv-Historie) — dieselbe Verlink-Wahrheit wie beim Brain-Merge | ClickUp Custom Field |

→ Detailseite lädt primär die Projektliste; eine „Historie einblenden"-Option zieht zusätzlich
alle Tasks mit passender `mykilos_project_id` (z. B. aus dem 88-Slack-Archiv). Kein Dedupe nötig —
Live und Historie bleiben getrennt gruppiert.

## 2. Custom-Field-Mapping (die 10 existieren bereits im Testspace)

| ClickUp-Feld | Auf der Detailseite | Darstellung (Farbe = Sprache) |
|---|---|---|
| `mykilos_project_id` | Join (unsichtbar) | — |
| `project_phase` (Briefing…Service) | **Abgleich mit Lebenszyklus-Stepper** | bei Divergenz dezenter Hinweis „ClickUp sagt: Ausführung" — **kein Auto-Write** in beide Richtungen |
| `blocker_type` (intern/Kunde/Lieferant/Daten/Geld/Datei) | Blocker-Badge an der Task-Zeile + Filter | critical-Ton, dezent |
| `finance_relevant` | €-Punkt an der Zeile | cash-Tiefblau; Querverweis im Cash-Widget denkbar (später) |
| `change_order_relevant` | „Nachtrag"-Badge | verknüpft gedanklich mit Warenkorb-Nachträgen (§5j) |
| `review_required` | „Review"-Badge | ocker |
| `evidence_grade` (stark…konflikt) | nur bei Historie-Tasks: Vertrauens-Punkt | grau-Skala, klein |
| `source_system` (Slack/Drive/…) | Quellen-Chip | bestehende SourceChip-Farben |
| `drive_folder_url` | Ordner-Icon → öffnet Drive | terrakotta |
| `client_name` | redundant (Projekt kennt Kunde) — nur Tooltip | — |

**Assignees:** angezeigt wird, was Menschen in ClickUp setzen (echte Namen nach Go-Live;
im Testspace Ghost-Kürzel aus der Description als Text). mykilOS setzt nie welche.

## 3. Meilensteine

- **Quelle:** ClickUp-Tasks vom Typ *Milestone* (oder Tag `meilenstein`) **mit due_date** — von
  Menschen gesetzt.
- **Anzeige 1 — Stepper-Strip:** unter dem Lebenszyklus-Stepper eine schlanke Datumszeile:
  nächster Meilenstein + Monat (erfüllt die Backlog-Idee „Meilenstein-Statusbar mit Monatsangaben").
- **Anzeige 2 — Timeline-Tab:** Meilensteine als Marker zwischen den bestehenden Einträgen.
- Überfälliger Meilenstein = Hinweis-Kandidat (siehe 4), nie „Aufgabe".

## 4. „Genervt werden" — Hinweise mit Stufen-Rollout

**Erlaubt, weil der Aufgaben-Absender ein Mensch ist — die App ist nur der Bote.**

- **Hinweis-Arten (dezent, Signal-Strip / Heute-Board, kein Push):** heute fällig · überfällig ·
  neuer Blocker · überfälliger Meilenstein. Jeweils mit Quellen-Chip „CLICKUP".
- **Per-User-Opt-in** in Settings → Datenschutz („ClickUp-Hinweise", Default AUS — Alerts-Regel):
  - **Stufe 1 (JETZT):** Johannes an.
  - **Stufe 2:** Daniel — Toggle erscheint ihm beim Login, er entscheidet selbst.
  - **Stufe 3 (Team):** erst mit echtem Go-Live, das **nur Johannes** grün schaltet.
- Jeder sieht nur Hinweise zu Tasks, die ihn betreffen (eigene Assignments + Projekt-offene) —
  nie Quer-Einblick in fremde persönliche Zuweisungslast.

## 5. Was mykilOS (vorerst) NICHT tut

Kein Task-Erstellen · kein Zuweisen · kein Status-Schreiben (auch kein „Abhaken" — kommt später
höchstens als gated Karte) · kein Verschieben · keine Notifikationen an Dritte. Read + erinnern,
mehr nicht.

## 6. Bau-Reihenfolge (nach V10-Kern, kleine Blöcke)

1. **M1:** TasksWidget-Anreicherung (Badges + Chips aus den Custom Fields, Testspace, read-only).
2. **M2:** Meilenstein-Strip am Stepper + Timeline-Marker.
3. **M3:** Hinweis-Kandidaten in den Signal-Strip + Datenschutz-Toggle (Stufe 1: Johannes).
4. **M4:** Historie-Einblendung via `mykilos_project_id` (Slack-Archiv-Tasks).
5. **M5 (viel später, nach Go-Live-Grün):** gated „Abhaken"-Karte.

*Kosten-Notiz: alles über die bestehende ClickUp-Read-API, pro Projektöffnung 1–2 Calls, Poll
gemächlich — kein neues Limit-Risiko.*
