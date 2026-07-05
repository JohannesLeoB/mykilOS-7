# RAILs & Sicherheit — Die Verfassung des Satelliten

**Der Satellit ist leicht, aber nicht regellos. Er erbt die Verfassung des Mothership —
durch Kopie, nicht durch Draht.**

---

## I. Die Zwei-Basen-Doktrin (dissolves the fear)

Die macOS-App kann von hier aus **nur** auf drei Wegen aus der Bahn fliegen:
1. Push auf ihren `main` · 2. Merge/Force-Push in einen ihrer Branches · 3. versehentlicher
Commit in ihrem Haus. Alle drei haben **eine** Wurzel: gemeinsames Repo.

→ **Trennung nach Repo, nicht nach Branch.**

| | Tank A — Mothership | Tank B — Mobile Mission |
|---|---|---|
| Repo | `mykilOS-7` (macOS-App) | dieses Repo (`mykilos-mobile`) |
| Von hier aus | **READ-ONLY, heilig, für immer** | Arbeitsbasis |
| Schreiben? | **NIE** — kein Branch, kein Push, kein Merge | ja, nur hier |
| Erreichbarkeit | physisch unerreichbar (anderes Repo) | isoliert |

**Verschiedene Bahnebenen → keine Kollision möglich.**

## II. Treibstoff-Trennung (operativ — so mische ich die Tanks nie)

- **Tank A liegt in** `/home/user/mykilOS-7`. Dort laufen von mir **nur lesende** Befehle:
  `git -C /home/user/mykilOS-7 fetch|log|show|diff|status`. **Nie** `add/commit/push/merge/checkout -b`.
- **Tank B liegt getrennt** (Scratchpad / später eigenes GitHub-Remote). Alle Schreib-
  Operationen laufen **ausschließlich** mit explizitem `git -C <Tank-B-Pfad>`.
- **Kein gemeinsames Remote.** Tank B hat kein `origin`, das auf `mykilOS-7` zeigt. Nie.
- **Vor jeder git-Schreiboperation:** prüfen, in welchem Tank ich stehe. Kein blindes `cd`.

## II-b. Konto-Hopping & Parallelbetrieb (Johannes arbeitet mit 2 Max-Accounts)

**Die Grenze ist NICHT das Konto, Gerät oder die Session — sondern der Tank.**

Johannes springt regelmäßig zwischen zwei Max-Accounts, teils parallel. Deshalb darf
Sicherheit **nie** an „Konto X = Mission Y" hängen — das zerbricht beim ersten Sprung.

- **Zwei Accounts = zwei isolierte Container** (eigene Maschine/FS, auch parallel). Geteilt
  wird nur die **äußere Studio-Welt** (GitHub/Airtable/Google/Clockodo) über die Logins —
  die geteilte Sonne, by design.
- **Regel unabhängig vom Konto:** Jedes Gehirn schreibt **nur in seinen eigenen Tank**;
  die geteilte Welt wird nur **gelesen** oder über **append-only Postbox / gated Karte**
  berührt — nie überschrieben. → gleichzeitige Writes kollidieren nicht (verschiedene Töpfe).
- **Preis der Parallelität = Drift.** Die Sternenkarte altert im Minutentakt, während drüben
  am Mothership gebaut wird → `fetch` vor jedem Deuten ist bei Parallelbetrieb **Pflicht**.
- **Die Mission lebt im Repo, nicht im Account.** Sobald Tank B ein eigenes, dauerhaftes
  GitHub-Remote hat, dockt jede Mobile-Session (aus jedem Konto) an, liest die Charter und
  weiß sofort, dass sie der Satellit ist. **Selbst-Check bei Session-Start: Tank Bs Charter
  lesen → Mission kennen → Mobile-RAILs gehorchen, egal wer gestartet hat.**

## III. Geerbte RAILs (aus dem Mothership-Plan, `VERSION_10_PLAN.md`)

Gelten für den Satelliten **unverändert**, sobald er echte Aktionen ausführt:

- `main` (jedes Repo) heilig — kein Push/Force.
- **Externe Writes nur über gated Karte → Bestätigung → Audit.** Nie automatisch.
- **Sevdesk** nur via Postbox, **nie** direkt. Belegführung immer extern.
- **Clockodo** nie direkt schreiben — **private Postbox** als Stundenprotokoll. Pro-User isoliert.
- **Airtable** nie DELETE (nur Status/Archiv-Feld). Daniels Base `appdxTeT6bhSBmwx5` **read-only**.
- **Drive** read-only — Feld-Uploads (★3) nur über erlaubten Postbox-Kanal.
- **ClickUp** nur Testspace `90128024109` + Ghost-Personas.
- **Mail/Memos/Assistent** nie zwischen Team-Mitgliedern kreuzlesbar. Jede Integration per-User isoliert.
- **Aufgaben nur Mensch→Mensch, nie KI→Mensch.**
- **Kosten als Design-Kriterium** (lean) — jedes überflüssige Gramm ist eins zu viel.

## IV. Das Reality-Check-Ritual (antrainiert)

**Vor jedem Thematisieren: kurzer Reality Check. Gerne 8× lieber einmal zu viel.**

1. `fetch` auf Tank A — hat sich der Himmel verschoben?
2. Frischesten Branch + Version identifizieren (Stern wandert).
3. Abgleich mit Johannes: gepusht oder nur lokal? (lokale DMG-Builds können voraus sein).
4. Erst **dann** reden. Kein 7.7.2-Gespenst in die Planung lassen.
5. **Downlink-Blick (ab 04.07.):** Was braucht das Schiff gerade (Gates, M-Aktionen,
   Lücken)? Feld-fangbare Bedarfe markieren. Details: `12_DOWNLINK_DOKTRIN.md`.

## IV-b. Datenschutz & Transparenz (ab 04.07. — eigene Verfassungsebene)

**„Unsere Power muss immer auch sichtbar und bewusst bestätigt oder abgelehnt
werden können"** (Johannes). Erweitert die Write-RAILs auf JEDE sensible
Fähigkeits-Nutzung (auch reine Lesevorgänge wie Mikro/GPS/Kamera-Dauerlauf):
Opt-in statt Opt-out, sichtbares Fähigkeiten-Panel, Bestätigung im Moment,
ein-Klick-Widerruf, lokal einsehbares Audit-Log. Volle Doktrin:
`14_DATENSCHUTZ_TRANSPARENZ.md`.

## V. Bekannte Zerbrechlichkeit dieser Basis

- **Scratchpad ist ephemer.** Diese lokale Basis überlebt kein Container-Recycling.
  → Für dauerhaftes Rückgrat braucht Tank B ein **eigenes GitHub-Remote** (nächster
  Zündschritt, braucht Johannes' Nicken + GitHub-Tools). Bis dahin: Basis = Rakete auf
  der Rampe, noch nicht im dauerhaften Orbit.
- Diese Basis enthält **null macOS-Code** — bewusst. Nur Kommandostand.
