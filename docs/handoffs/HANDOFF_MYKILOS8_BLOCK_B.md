# HANDOFF — mykilOS 8 Block B: Lokales Zeit-Subsystem (S1)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: feat/mykilos8-block-b-zeit-subsystem (von Block-A-Branch abgezweigt)
Build:  ✅ swift build grün
Tests:  ✅ 672 Tests grün (13 neu für Block B)
Datum:  2026-07-01
```

## 0. Auftrag

Block B aus [HANDOFF_MYKILOS8_ROLLING_PLAN.md](HANDOFF_MYKILOS8_ROLLING_PLAN.md) §2 +
`mykilOS8_Orchestrierung/codesession_handoff/briefs/S1_Lokales_Zeit_Subsystem.md`: die gesamte
lokale Zeiterfassung — UI + Zustand + Persistenz, **ohne jeden externen Write** (Clockodo = S3).

Johannes' Defaults zu den zwei offenen Brief-Fragen:
1. **Timer-Wechsel zwischen Projekten:** nachfragen (Übernahme-Karte), nicht auto-umschalten.
2. **Puls bei Ignorieren:** nach **3 Minuten** beruhigen (nicht dauerhaft, nicht 5 Min).

## 1. Was gebaut wurde

| Komponente | Datei |
|---|---|
| Domain-Typen (Kostenstelle, ActiveTimer, TimeSegmentDraft, TimeSegment, ProjectZielkontingent, TimerFormat) | `Sources/MykilosKit/Domain/TimeTracking.swift` |
| GRDB-Migration `v15_time_tracking` (4 Tabellen, additiv) | `Sources/MykilosServices/Database/GRDBDatabase.swift` |
| `TimerStore` (Zustandsmaschine, @MainActor @Observable) | `Sources/MykilosServices/Database/TimerStore.swift` |
| Projekt-Timer-Widget (Tab „Zeit") | `Sources/MykilosApp/Time/ProjektTimerView.swift` |
| Globale Dialoge (Übernahme / 2-Schritt-Buchung / Check-in) | `Sources/MykilosApp/Time/TimerGlobalDialogs.swift` |
| Sidebar-Pille + Puls-Hintergrund | `Sources/MykilosApp/Time/TimerSidebarPill.swift` |
| Tab `.zeit` verdrahtet | `Sources/MykilosApp/Detail/ProjectDetailView.swift` |
| Pille + Puls in Sidebar | `Sources/MykilosApp/Shell/SidebarView.swift` |
| Dialog-Overlay + Check-in-State | `Sources/MykilosApp/MykilOS6App.swift` |
| `timer: TimerStore` | `Sources/MykilosApp/Data/AppState.swift` |
| 13 Tests | `Tests/MykilosServicesTests/TimerStoreTests.swift` |

## 2. Architektur-Entscheidungen

- **Draft-vor-Buchung-Modell:** Ein Kostenstellen-/Projektwechsel schließt den laufenden Abschnitt
  als `TimeSegmentDraft` ab (nicht gebucht) und startet sofort einen neuen — so geht keine Sekunde
  verloren, aber nichts wird ohne die doppelte Bestätigung committet. Stopp macht den letzten
  Abschnitt zum Draft; `confirmBooking` wandelt ALLE Drafts des Laufs in append-only `TimeSegment`s.
- **Single-Instance:** Tabelle `activeTimer` mit fester id `"singleton"`; `start()` während eines
  laufenden Timers setzt `pendingTakeover` statt eines zweiten Timers. „Übernehmen" stoppt den
  alten (→ Buchung) und merkt den neuen Start vor (`queuedStart`), der nach Klärung der Buchung feuert.
- **Puls** als reine, testbare Funktion `TimerStore.shouldPulse(anchor:now:intervalSeconds:calmAfter:)`:
  nach jeder Intervall-Marke 3 Min pulsen, dann Ruhe bis zur nächsten Marke; pausierter Timer nie.
- **Live-Zeit** über `TimelineView(.periodic by: 1)` in Pille/Widget/Puls — kein globaler Dauer-Timer
  im AppState; nur die zeitabhängigen Views ticken.

## 3. ZIEL-CHECK (Rolling-Plan §3)

1. **Vollständigkeit:** alle Brief-Punkte gebaut (Timer/Pause/Stopp, Single-Instance, Kostenstellen,
   Sidebar-Pille, Puls, Doppelbestätigung, Zielkontingent) + live im Bundle (kein Crash, Log sauber).
2. **Quer-Wirkung:** adversarialer Multi-Agent-Review (4 Dimensionen: Regression, Timer-Logik,
   Persistenz, Token/SwiftUI) — Ergebnis siehe §4.
3. **Eine-Wahrheit:** rein lokal, kein neues externes Datum; Migration additiv; appSettings-Key
   `timerPulseIntervalMinutes` kollidiert nicht mit Block A (`provisioningMode`).
4. **Sicherheit:** kein externer Write; alle Writes `throws`; Single-Row + append-only.
5. **Tests:** 13 neu (Single-Instance, Pause-hält/Stopp-beendet, Kostenstellenwechsel ohne
   Zeitverlust, Erinnerungs-Reset, Doppelbestätigung erst im 2. Schritt, 3 Cold-Start, Puls-Logik,
   Zielkontingent, Format) + volle Suite grün (672).
6. **Abschluss:** DMG-Versionsbump 7.9.0, Bericht, Übergang Block C.

## 4. Review-Befunde (adversarialer Multi-Agent-ZIEL-CHECK)

Ein Workflow mit 4 parallelen Review-Dimensionen (Regression, Timer-Logik, Persistenz,
Token/SwiftUI) + adversarialer Verifikation jedes Findings: **12 Findings, 8 bestätigt, 4 als
False-Positive aussortiert** (852k Subagent-Tokens, 16 Agenten).

**Bestätigt + gefixt:**
| # | Schwere | Befund | Fix |
|---|---|---|---|
| 1 | **critical** | `runQueuedStartIfNeeded()` setzte `queuedStart=nil` VOR `try? startFresh` → bei DB-Fehler ging der vorgemerkte Übernahme-Start lautlos verloren (Nutzer denkt, Timer läuft) | `do/catch`: `queuedStart` bleibt bei Fehler erhalten, Fehler über `saveState` sichtbar |
| 2 | high | `.font(.system(size: 38))` (Clock) verletzt Token-Disziplin (CI-Custom-Rule `no_system_font` = error) | neuer Token `Font.mykTimerClock` in `Typography.swift` |
| 3 | medium | `SidebarPulseBackground` tickte 1 Hz auch ohne aktiven Timer (Dauer-Render) | TimelineView nur noch wenn `timer.active != nil` (nicht an `shouldPulse()` gekoppelt — sonst Henne-Ei: Puls würde nie starten) |
| 4–6 | medium | weitere `.font(.system(size: 9/11))` an Icons | `.mykCaption`/`.mykSmall`/`.mykMono(9)` |
| 7 | low | appSettings-Key `timerPulseIntervalMinutes` nicht namespaced | → `blockB.timer.pulseIntervalMinutes` |

**Bewusst NICHT geändert (begründet):** Die drei `.foregroundStyle(.white)`-Findings (Glyph/Text auf
farbigem Button) sind **keine** Regelverstöße — die SwiftLint-Custom-Rules verbieten nur `Color(red:)`/
`Color(hex:)`, nicht `.white`; und der Bestandscode (`ProjectCard`, `ProjectHeroView`,
`ProjectFavoritesWidget`) nutzt `.white` durchgängig für Text auf Akzentfarbe. `MykColor.paper` wäre
hier sogar falsch (im Dark Mode dunkel → unlesbar auf Sage/Critical).

**False-Positives (vom Verifizierer korrekt verworfen):** „persistActive Crash-Fenster" (ist atomar
im selben write-Block), „pausierter Timer verliert Zeit beim Kostenstellenwechsel" (`elapsedSeconds`
bezieht `pausedAccumulated` ein), „leeres ZStack fängt Klicks" (`isAnyUp`-Guard), „compactMap
verliert Records still" (lokal erzeugte UUIDs, kein Risiko).

**Hinweis SwiftLint:** Die Default-Regeln `identifier_name`/`file_length` melden im **gesamten Repo
1150 errors** (Bestandscode quer durch die App) — sie sind faktisch nicht das wirksame Gate. Mein
Code folgt dem etablierten Store-Muster (`FavoritesStore`/`AuditStore`: `private let db`, kurze lokale
Namen). Gate = `swift build` + `swift test` + die Custom-Rules (alle grün/erfüllt).

## 5. Offene Punkte / nächste Blöcke

- Kostenstellen sind in S1 statisch (`Kostenstelle.defaults`) — S2 (Block C) bindet die echten
  Airtable-Projektfeld-Werte an, + Zielkontingent-Auto-Herleitung.
- Clockodo-Upload der gebuchten Segmente ist S3 (Block E) — draft→confirm→POST mit per-User-Key.
- Puls-Intervall ist persistiert (`setPulseInterval`), aber noch ohne Settings-UI — kann später in
  die Einstellungen (Private Area) eingehängt werden.

## 6. Push/Merge

Branch ist bereit für Review. Push/Merge nach main nur durch Johannes (eiserne Regel).
