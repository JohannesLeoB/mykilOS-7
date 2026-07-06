# Startprompt S14 — Kalkulations-Widget UI (Schritt 6)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: feat/kalkulation-core-port
Build:  ✅ 194 Tests grün
Datum:  2026-06-28
```

---

## Kontext: Was bisher passiert ist

mykilOS 6 ist ein macOS-14+-Cockpit (SwiftUI, GRDB, local-first, Multi-Target SPM).
Der Schätz-Brain aus der separaten mykilO$-App ist vollständig portiert und live
in `AppState.kalkulationsEngine` verdrahtet (Schritte 1–5, Branch
`feat/kalkulation-core-port`).

**Was der Engine-Adapter bereits kann:**
- `schaetze(projektID:, freitext:)` → `KostenSchaetzung` (min/max/mitte Netto,
  Konfidenz, Evidenzen) — live mit 6 Baseline-Ankern (kein externer Datei-Bedarf)
- `geraetepreis(suchbegriff:)` → `Double?` — nil wenn keine `catalog.csv` in
  Application-Support, sonst MYKILOS-VK aus Preisbuch

**Was noch als Stub wirft** (kein Merge-Blocker, aber noch nicht fertig):
- `importPDF` → `KalkulationsEngineError.notYetImplemented` (braucht Drive-Client)
- `recordAdjustment` → `KalkulationsEngineError.notYetImplemented` (braucht
  ActionCard → Bestätigungs-Flow)

**Alle Tests grün:** 194 (175 swift-testing + 19 XCTest). App läuft stabil.

---

## Dein Auftrag: Kalkulations-Widget UI (Schritt 6)

Baue die Benutzeroberfläche für die Kalkulations-Engine als Widget und Tab.
Kleine Schritte, saubere Handoffs, keine Bugs offen lassen. Tests nach jeder
Änderung. STOP wenn dieser Schritt fertig und gesichert ist.

### Was zu bauen ist

**A) `KalkulationsWidget` in `MykilosWidgets/Kinds/`**

Ein neues Widget (wie `AssistantWidget`, `DriveWidget` etc.) mit allen 6 Renderstates:
- `.loading` — Schätzung läuft
- `.content(KostenSchaetzung)` — Ergebnis mit min/mitte/max Netto, Konfidenz-Badge,
  Top-Evidenzen (Quellen, Preise)
- `.empty` — noch kein Freitext eingegeben
- `.error(String)` — Fehler beim Schätzen
- `.permissionRequired` — (hier: Freitext fehlt, Engine nicht verfügbar)
- `.offline` — (hier: nicht relevant, Engine ist lokal — kann entfallen oder mit
  `.empty` zusammenfallen)

Quellzeile unten: `• KALKULATION · BASELINE-ANKER`

**B) Freitext-Eingabe**

Das Widget braucht ein Eingabefeld für `freitext` (z. B. "5 lfd. m Unterschränke
mit Linoleumfronten, 15 Eichenschubkästen"). Nach Eingabe → `schaetze()` aufrufen
→ Ergebnis anzeigen.

**C) `KalkulationsView`-Tab im Sidebar-Modul**

Neuer Tab `Kalkulation` in der Sidebar (nach `Angebote`, vor `Einstellungen`),
der das `KalkulationsWidget` einbettet und `AppState.kalkulationsEngine` durchreicht.

**D) WidgetKind `.kalkulation`**

Neue `WidgetKind`-Variante (wie `.assistant`, `.drive` etc.) in `MykilosKit`.
Wird für das spätere Einbetten in Projekt-Boards gebraucht (jetzt noch nicht
verdrahten, nur die Variante anlegen).

### Architektur-Regeln die hier gelten

- `MykilosWidgets` importiert **kein GRDB** — Engine-Calls nur über das Protokoll
  `KalkulationsEngineProviding` aus `MykilosKit`
- Schreibvorgänge (wenn `recordAdjustment` mal verdrahtet wird) kommen nicht aus
  der View, sondern über einen Store/ActionCard-Flow — **heute noch kein
  `recordAdjustment`**, der Stub wirft und das ist richtig so
- Token-Disziplin: `MykColor.tasks` (Ocker) als Akzentfarbe für Kalkulation
  (passt thematisch: Aufgaben/Kalkulationen = Ocker), `Font.mykTitle` etc.
- Alle 6 Renderstates implementieren

### Was NICHT Teil dieses Schritts ist

- `recordAdjustment`-Flow (ActionCard + Audit) — separate Session
- `importPDF` — braucht Drive-Client, separate Session
- Seed-Provider / echte destillierte Anker aus SQLite — separate Session
- Preisbuch-CSV nach Application-Support kopieren — explizite Freigabe erforderlich

---

## Pflicht-Checks vor dem ersten Edit

```bash
# Im kanonischen Ordner:
pwd
# Muss enden mit: .../MYKILOS 6/mykilOS Mac

git status
# Branch: feat/kalkulation-core-port, keine uncommitteten Änderungen
# (außer ggf. docs/IDEEN_UND_BACKLOG.md — das ist Johannes' eigene Änderung,
#  NICHT anfassen, NICHT stagen, NICHT committen)

swift build && swift test 2>&1 | tail -5
# Build ✅, 194 Tests grün
```

---

## Wo die relevanten Dateien liegen

| Was | Pfad |
|---|---|
| Engine-Protokoll | `Sources/MykilosKit/Domain/KalkulationsEngineProviding.swift` |
| Engine-Impl | `Sources/MykilosServices/Kalkulation/KalkulationsEngine.swift` |
| AppState | `Sources/MykilosApp/Data/AppState.swift` (Zeile ~89: `kalkulationsEngine`) |
| Existierendes Widget-Beispiel | `Sources/MykilosWidgets/Kinds/AssistantWidget.swift` |
| WidgetKind-Enum | `Sources/MykilosKit/Domain/WidgetFoundation.swift` |
| Sidebar-Module | `Sources/MykilosApp/Shell/ContentView.swift` |
| Design-Tokens | `Sources/MykilosDesign/Tokens.swift` |
| Farbe für Kalkulation | `MykColor.tasks` (Ocker, `#C99A3E`) |

---

## Handoff-Pflicht nach diesem Schritt

Wenn `Schritt 6` abgeschlossen ist:

1. `swift build && swift test` — muss grün sein, keine neuen Fehler
2. `git add <nur eigene Dateien>` — **nie** `git add -A` (IDEEN_UND_BACKLOG.md
   ist Johannes' uncommittete Änderung)
3. `git commit -m "feat: add KalkulationsWidget + KalkulationsView tab (step 6)"`
4. `docs/handoffs/HANDOFF_KALKULATION_CORE_PORT.md` um Schritt 6 ergänzen
5. `docs/EREIGNISPROTOKOLL.md` neuen Eintrag anlegen
6. `CLAUDE.md` Fortschrittstabelle aktualisieren
7. **Kein Push ohne Johannes' Freigabe**
8. STOP — auf Freigabe warten

---

## Absolute Regeln (Kurzfassung)

- Sevdesk: NIE lesen/schreiben
- Airtable-Base `appuVMh3KDfKw4OoQ`: nur lesen (kein Write/Edit/Delete)
- Drive-Ordner `0AOeReQBQKkKBUk9PVA`: read-only
- Secrets nur Keychain, nie in Code/Commits/Logs
- `MykilosKit` importiert nie SwiftUI oder GRDB
- `MykilosWidgets` importiert nie GRDB
- Schreibvorgänge nie aus Views — nur über Stores
- Neues persistierbares Feature → Cold-Start-Test als Merge-Gate
- `try?` nur mit Kommentar und Begründung
- Kein `git add -A` — immer explizite Pfade
