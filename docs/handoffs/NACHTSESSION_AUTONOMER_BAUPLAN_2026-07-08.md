> **ÜBERHOLT (2026-07-08, konsolidiert):** Nie freigegeben, nie autonom gestartet — stattdessen
> hat Johannes am 2026-07-08 direkt weitergearbeitet ("VOLLE CLICKUP FUNKTIONALITÄT JETZT").
> Aktueller Stand: [HANDOFF_2026-07-08_KONSOLIDIERT.md](HANDOFF_2026-07-08_KONSOLIDIERT.md).
> Diese Datei bleibt als historisches Dokument stehen (zeigt die Screen-unabhängige
> Definition-of-Done-Haltung), ist aber NICHT der aktuelle Plan.

# Nachtsession — Autonomer Bauplan (verankert 2026-07-07 Nacht, für eine fremde Session)

**Kontext:** Diese Session läuft NONSTOP über Nacht, autonom, ohne Johannes' Anwesenheit, in einem
ANDEREN Claude-Account/einer anderen Session als die, die diesen Plan geschrieben hat.
**Screenuse ist tabu** — keine GUI-Klicks, kein `computer-use`, keine visuelle Prüfung. Jede
Definition-of-Done in diesem Plan ist deshalb bewusst screen-unabhängig formuliert:
Build/Test/Lint/echte-CI, nie "sieht gut aus".

**Diese Datei existiert, weil heute Nacht (2026-07-07) genau das Gegenteil davon passiert ist, was
hier verlangt wird:** Pläne ohne Bau, "Tests grün" als falscher Beweis, verschwiegene Lücken, eine
CI, die seit 2026-07-06 rot war und niemand hat's gemerkt, vergessene Hintergrund-Prozesse. Lies
`docs/erfahrungstraeger/PROZESS_LESSONS.md` (oberster Eintrag) und `~/.claude/CLAUDE.md`, um zu
verstehen, warum jede Regel hier so hart formuliert ist.

---

## 0. Pflicht-Preflight (vor JEDER Aktion, nicht nur am Anfang)

```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac"
pwd                                    # MUSS auf ".../mykilOS Mac" enden
git remote get-url origin              # MUSS "mykilOS-macOS" enthalten — sonst SOFORT STOP
git branch --show-current              # MUSS "feat/multi-user-login" sein
git status --short                     # sauber? was liegt unerwartet da?
swift build && swift test 2>&1 | tail -3
swiftlint lint --strict --baseline swiftlint-baseline.json --quiet
gh run list --branch feat/multi-user-login --limit 1   # ECHTE CI prüfen, nicht raten
```

Lies in dieser Reihenfolge, bevor irgendetwas gebaut wird:
1. `docs/erfahrungstraeger/PROZESS_LESSONS.md` (oberster Eintrag)
2. `docs/OFFENE_ZUSAGEN.md` — die eine ehrliche Liste, jetzt auch in der App (Hilfe-Menü)
3. `CLAUDE.md` (eiserne Regeln, ganz oben — inkl. der neuen Regel "Kein Plan ohne Bau-Pflicht")
4. `~/.claude/CLAUDE.md` (projektübergreifend)
5. `KOORDINATEN.md`
6. Diese Datei komplett

---

## 1. Nicht verhandelbare Betriebsregeln für diese Nachtsession

1. **Kein Plan ohne sofortigen Bau** (CLAUDE.md, ganz oben). Jede Etappe unten wird SOFORT gebaut,
   nicht nur vorbereitet.
2. **"Fertig" hat für diese Session eine PRÄZISE, screen-unabhängige Definition:**
   `swift build` grün + `swift test` grün + `swiftlint lint --strict --baseline ... ` sauber +
   **echte CI grün** (`gh run list` nach dem Push geprüft, nicht angenommen) + Code-Review-Pass
   (siehe §3) + `docs/OFFENE_ZUSAGEN.md` aktualisiert. NICHTS davon einzeln ist genug.
3. **UI-Features ohne Screen-Zugriff sind NIE "✅ fertig", höchstens "🟡 code-fertig +
   unit-getestet, NICHT visuell/interaktiv geprüft (kein Screen-Zugriff in dieser Session)."**
   Das explizit so in `docs/OFFENE_ZUSAGEN.md` eintragen — nie stillschweigend als fertig markieren.
4. **Alle 45 Minuten eine frische DMG** — unabhängig davon, ob eine Etappe fertig ist. Nur wenn
   Build+Test+Lint in dem Moment grün sind (nie eine rote DMG ausliefern). Versionsnummer in
   `script/build_and_run.sh` UND `script/create_dmg.sh` synchron hochzählen.
5. **Commit + Push nach JEDER einzeln verifizierten Etappe** auf `feat/multi-user-login`. Kleine
   Commits, nie einen Riesen-Commit am Ende. **NIEMALS nach `main` pushen** — das bleibt exklusiv
   Johannes' Entscheidung, keine Ausnahme, auch nicht "weil CI jetzt grün ist".
6. **Jeder selbst gestartete Hintergrund-Prozess (Agent, Bash-Background) wird am Ende der eigenen
   Verantwortung geprüft und beendet.** Keine Endlosschleifen stehen lassen.
7. **Bei jeder Fortschrittsmeldung (auch nur an `docs/OFFENE_ZUSAGEN.md`) sofort das Delta zum
   ursprünglich vollen Umfang benennen** — nicht nur, was fertig wurde.
8. **Kein Faktum ohne Beleg (S0-Prinzip):** wenn eine Etappe eine externe Entscheidung braucht, die
   nur Johannes treffen kann (Laser-Hardware, echte Notification-Freigaben, main-Push), wird sie
   NICHT geraten, sondern explizit in `docs/OFFENE_ZUSAGEN.md` als blockiert stehen gelassen.
9. **Ghost-Persona-Regel + alle bestehenden NO-GOs bleiben in Kraft** (Sevdesk nie schreiben, echte
   ClickUp-Assignees nur über das Go-Live-Whitelist-Gate, keine echten Notifications ohne explizite
   Freigabe, kein DELETE in Airtable).

---

## 2. Etappen — klein, in Reihenfolge, jede einzeln shippbar

Jede Etappe: bauen → testen (neue Tests für neue Logik, Pflicht bei persistierbaren Features) →
lokal lint grün → committen+pushen → **echte CI-Grün-Prüfung per `gh run list`** → DMG falls
45-Minuten-Marke erreicht → `docs/OFFENE_ZUSAGEN.md` aktualisieren → nächste Etappe.

### Etappe 0 — CI-Fix verifizieren (sollte bereits erledigt sein, aber prüfen)
Commit `7c4a2a6` pinnt SwiftLint auf 0.65.0 in der CI (vorher `brew install` = immer neueste
Version = Drift, CI seit 2026-07-06 rot). **Prüfe per `gh run list`, dass der Push tatsächlich grün
lief, bevor irgendetwas anderes beginnt.** Ist es nicht grün: das ist Etappe 0, alles andere wartet.

### Etappe 1 — Multi-User-Isolation Hard-Gate-Test (reiner Code, kein Screen nötig)
Der im Audit gefundene, nie gebaute Test: echte file-backed GRDB-DB, echte Prozess-Neustart-
Simulation (neue Store-Instanzen gegen dieselbe DB-Datei, Muster: `NomenklaturServiceTests`,
`ClickUpGoLiveWhitelistStoreTests.whitelisteUeberlebtNeustart`), beweist "Person B sieht nie Person
A's private Daten" für Chat/Notes/Tasks/Clockodo-Drafts. Kein Bezug zu Screen — reiner Cold-Start-
Test in neuer Datei `Tests/MykilosServicesTests/MultiUserIsolationHardGateTests.swift`.

### Etappe 2 — ClickUp Kanban-Spalten (Aufgaben-Tab + Haupt-Übersicht)
Johannes' Definition (wörtlich, `docs/OFFENE_ZUSAGEN.md`): "in Spalten sortieren, sauber in den
'Aufgaben' und auf dem Übersichts-Hauptscreen zeigen." Spalten nach Status (dynamisch aus den
geladenen Aufgaben, gleiches Muster wie `bekannteStatuswerte` in `TasksWidget`/
`ClickUpTestWerkbankView`). Zwei Oberflächen: `ClickUpAufgabenSpalte.swift` (Kataloge/Aufgaben-Tab)
UND ein neues, kompaktes Kanban-Widget auf der Heute/Übersicht-Seite. **UI-Korrektheit kann NICHT
visuell geprüft werden — Definition of Done ist "kompiliert, rendert ohne Absturz in Preview/Test,
Logik unit-getestet (Gruppierung nach Status ist eine reine Funktion, genau wie `bekannteStatuswerte`
schon ist)."**

### Etappe 3 — ClickUp-Bearbeitbarkeit (Fälligkeitsdatum, Priorität)
Erweiterung von `ClickUpTaskActionStore` (bereits gebaut: `setStatus`, `createTask`) um
`setDueDate(taskID:listID:dueDate:...)` und `setPriority(taskID:listID:priority:...)` — GLEICHES
Gate (`ClickUpWriteGate.assertSchreibErlaubt`), gleiches Audit-Muster (neue `AuditEntry.Action`-
Fälle `clickUpFaelligkeitGeaendert`/`clickUpPrioritaetGeaendert`). `ClickUpClient` braucht die
passenden PUT-Aufrufe (Muster: `setStatus`, gleicher `/task/{id}`-Endpoint, anderes Feld im Body).
UI-Anschluss in `TasksWidget`/`ClickUpTestWerkbankView` — wieder: code-fertig + unit-getestet,
visuell nicht geprüft.

### Etappe 4 — ClickUp-Zuweisen (MENSCH-initiiert, UI-bestätigt — NIE die KI)
Härteste Etappe, sorgfältig: ein Mensch klickt in der UI "Zuweisen" → wählt einen ECHTEN ClickUp-
Nutzer aus `TeamRoster` → Bestätigungs-Dialog zeigt Klartext "Das löst eine echte ClickUp-
Benachrichtigung an diese Person aus" → erst nach explizitem Klick schreibt
`ClickUpTaskActionStore.assign(taskID:listID:clickUpMemberID:...)` — GLEICHES Gate
(Testspace/Go-Live-Whitelist), GLEICHES Audit-Muster, neuer `AuditEntry.Action`-Fall
`clickUpZugewiesen`. **Kein KI-Tool bekommt Zugriff auf diese Methode — nicht in
`AssistantToolRegistry`, Cross-Check-Test dafür schreiben (Muster:
`AdminEnforcementTests.assistentWhitelistErreichtKeinenAdminStore`).**

### Etappe 5 — Assistent-Grounding-Gate (S0)
Bauen nach der bereits vollständigen Spezifikation in
`docs/handoffs/CLICKUP_IO_ARCHITEKTUR_PLAN.md` §0 (Beleg-Speicher in der `ConversationEngine`,
Grenz-Validator, Muss-Auflösen-Sequenz, Herkunft-auf-Karte, permanenter Anti-Erfindungs-Test) — NICHT
auf den fehlenden Vorfall-Detail von Johannes warten (der wurde nie geliefert, die Spezifikation ist
bereits konkret genug). Erster Nutzer: der bestehende Mail-Entwurf-Pfad (`CreateDraftTool`). Test:
"Entwirf eine Mail an einen Kontakt, den es nicht gibt" → Assert: Lücke gemeldet, NIE eine erfundene
Adresse.

### Etappe 6 — Aufmaß-Widget, NUR der hardware-unabhängige Teil
`docs/handoffs/AUFMASS_WIDGET_PLAN.md` braucht ein echtes Bluetooth-Gerät für 3 von 5 Bausteinen —
das ist in dieser Session UNMÖGLICH (kein Hardware-Zugriff, kein Screen). Explizit NUR bauen:
(a) `LaserPort`-Protokoll (`LaserMeasuring { verbinde(), letztesMaß: AsyncStream<Double> }`) +
ein `FakeLaser`-Test-Double, (b) die Aufmaß-Canvas-Logik (Punkt-zu-Punkt-Linien, reine Geometrie,
ohne CoreBluetooth) inkl. Persistenz-Cold-Start-Test. **Explizit NICHT versuchen:** CoreBluetooth-
Kopplung, Foto-Empfang vom Satelliten — beides bleibt in `docs/OFFENE_ZUSAGEN.md` als 🔴 blockiert
auf Johannes' Laser-Entscheidung + echtes Gerät stehen, mit diesem Fortschritt ergänzt, nicht ersetzt.

### Etappe 7+ — Rollierend weiter
Nach Etappe 6: `docs/OFFENE_ZUSAGEN.md` erneut komplett lesen (könnte sich durch die Etappen
verändert haben), nächsthöchste Priorität wählen, gleiches Muster (klein, testen, Gate, committen,
CI prüfen, DMG-Rhythmus). Nie stehen bleiben, nie auf Bestätigung warten, die nicht kommt — bei
echter Unklarheit den Punkt in `docs/OFFENE_ZUSAGEN.md` als offene Frage vermerken und mit dem
NÄCHSTEN Punkt weitermachen, nicht blockieren.

---

## 3. Selbst-Review-Pflicht (macht diese Session "selbst-reviewend")

Vor JEDEM Commit: `/code-review` (mindestens Level "medium", bei sicherheitsrelevantem Code wie
Etappe 4/5 "high") auf den eigenen Diff laufen lassen. Gefundene echte Probleme SOFORT fixen, nicht
in einer Liste für "später" sammeln. Das ersetzt NICHT Johannes' spätere Live-Prüfung — es ist die
Ebene, die diese Session sich selbst leisten kann, ohne Screen.

## 4. Session-Ende (auch wenn "Ende" nie erreicht wird, weil die Zeit ausgeht)

Egal wann Zeit/Kontext ausgeht: letzte DMG bauen, `docs/OFFENE_ZUSAGEN.md` final abgleichen, ein
ehrlicher `PROZESS_LESSONS.md`-Eintrag (was wurde real fertig, was nicht, wo genau steht die
nächste Session), alles committet + gepusht (nie main). Kein Eintrag, der mehr Fortschritt behauptet
als tatsächlich durch die obige Definition-of-Done bewiesen ist.
