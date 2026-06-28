# Startprompt S15 — recordAdjustment-Flow + KalkulationsWidget in Projekt-Boards

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: feat/kalkulation-core-port (oder main nach Merge von PR #2)
Build:  ✅ 194 Tests grün
Datum:  2026-06-28
```

---

## Session-Schematik

Wir arbeiten in der Schematik S12 → S14 → S15 → ...SXX.
Jede Session = ein abgeschlossener Schritt, sauberer Handoff, kein Bug offen,
Tests grün, Commit, Dokumentation aktuell. STOP wenn der Schritt fertig ist.

---

## Was bisher gebaut wurde (Kalkulations-Port, Schritte 1–6)

| Schritt | Was | Status |
|---|---|---|
| 1 | `MykilosKalkulationsCore` (10 Dateien verbatim, Foundation-only) | ✅ |
| 2 | GRDB-Lernschicht + Cold-Start-Gate | ✅ |
| 3 | `KalkulationsEngineProviding` + `KalkulationsEngine` actor | ✅ |
| 4 | `DeviceCatalog` + `geraetepreis` live | ✅ |
| 5 | `BaselineAnchorProvider` + `AppState.kalkulationsEngine` live | ✅ |
| 6 | `KalkulationsWidget` + Sidebar-Tab "Kalkulation" + `WidgetKind.kalkulation` | ✅ |

**PR:** https://github.com/JohannesLeoB/mykilOS-6/pull/2

**Offene Stubs in `KalkulationsEngine`:**
- `importPDF` → wirft `notYetImplemented` (braucht Drive-Client, spätere Session)
- `recordAdjustment` → wirft `notYetImplemented` ← **das ist dein Auftrag**

---

## Pflicht-Checks ZUERST

```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6"
pwd
git status
git log --oneline -3
swift build && swift test 2>&1 | tail -5
```

Falls PR #2 gemergt wurde: `git checkout main && git pull`. Sonst auf
`feat/kalkulation-core-port` bleiben und von dort einen neuen Branch abzweigen:
`git checkout -b feat/kalkulation-record-adjustment`.

---

## Dein Auftrag: `recordAdjustment`-Flow (Schritt 7)

### Was zu bauen ist

`recordAdjustment(schaetzungsID: String, faktor: Double, grund: String)` soll nicht
mehr werfen, sondern den Anpassungswert persistent im `LearningStore` ablegen UND
als `AuditEntry` protokollieren (genauso wie `AssistantWidget` das für bestätigte
Actions macht).

**A) `KalkulationsEngine.recordAdjustment` implementieren**

In `Sources/MykilosServices/Kalkulation/KalkulationsEngine.swift` den Stub ersetzen:
```swift
public func recordAdjustment(schaetzungsID: String, faktor: Double, grund: String) async throws {
    try await learningStore.appendAdjustment(
        sessionID: schaetzungsID,
        faktor: faktor,
        grund: grund
    )
    // AuditEntry schreiben — via übergebenen AuditStore (inject oder per Callback)
}
```

`LearningStore.appendAdjustment` existiert bereits (Schritt 2). Schau dir die
Signatur in `Sources/MykilosServices/Kalkulation/LearningStore.swift` an.

**B) `AuditStore` in `KalkulationsEngine` injecten**

`KalkulationsEngine.init` braucht einen `AuditStore`-Parameter (optional, damit
bestehende Tests weiter funktionieren). In `AppState` den `audit`-Store übergeben:
```swift
self.kalkulationsEngine = KalkulationsEngine(
    provider: BaselineAnchorProvider(),
    learningStore: LearningStore(),
    deviceCatalog: DeviceCatalog.loadDefault(),
    auditStore: audit   // neu
)
```

**C) `KalkulationsActionCard` in `KalkulationsWidget`**

Nach einer Schätzung soll der Nutzer eine Anpassung vorschlagen können:
- Schieberegler oder Eingabefeld für `faktor` (z.B. 0.8 = 20% günstiger)
- Textfeld für `grund` (Freitext, z.B. "Aufmaß war kleiner")
- Bestätigungs-Button → `engine.recordAdjustment(...)` → `AuditEntry` sichtbar

Kein automatisches Schreiben — immer erst Bestätigung durch den Nutzer
(gleiche Semantik wie `AssistantWidget`'s Action-Cards).

**D) Cold-Start-Test erweitern**

In `Tests/MykilosServicesTests/KalkulationsLearningStoreTests.swift` einen neuen
Test hinzufügen: Adjustment schreiben → neuen Store auf gleichem Verzeichnis →
Adjustment ist lesbar. (Schreibpfad geht durch `LearningStore.appendAdjustment`
→ GRDB, der Cold-Start-Gate-Test für Sessions existiert schon, jetzt Adjustments
abdecken.)

---

## Relevante Dateipfade

| Was | Pfad |
|---|---|
| Engine | `Sources/MykilosServices/Kalkulation/KalkulationsEngine.swift` |
| LearningStore | `Sources/MykilosServices/Kalkulation/LearningStore.swift` |
| LearningRecords | `Sources/MykilosServices/Kalkulation/LearningRecords.swift` |
| AuditStore | `Sources/MykilosServices/AuditStore.swift` |
| AuditEntry | `Sources/MykilosKit/Domain/AuditEntry.swift` |
| KalkulationsWidget | `Sources/MykilosWidgets/Kinds/KalkulationsWidget.swift` |
| AppState | `Sources/MykilosApp/Data/AppState.swift` |
| LernTests | `Tests/MykilosServicesTests/KalkulationsLearningStoreTests.swift` |

---

## Absolute Regeln

- **Sevdesk: NIE lesen/schreiben**
- **Airtable-Base `appuVMh3KDfKw4OoQ`: nur lesen**
- **Drive-Ordner `0AOeReQBQKkKBUk9PVA`: read-only**
- Secrets nur Keychain, nie in Code/Commits/Logs
- `MykilosKit`: kein SwiftUI, kein GRDB
- `MykilosWidgets`: kein GRDB direkt
- Schreibvorgänge nie aus Views — nur über Stores
- **Neues persistierbares Feature → Cold-Start-Test (Adjustments!)**
- `try?` nur mit erklärendem Kommentar
- **`git add` immer mit expliziten Pfaden — nie `git add -A`**
  (`docs/IDEEN_UND_BACKLOG.md` ist Johannes' eigene Änderung — NIE anfassen)
- **Kein Push ohne explizite Freigabe von Johannes**

---

## Handoff-Pflicht am Ende

1. `swift build && swift test` — grün, keine Regressions, mindestens 194 Tests
2. `git add <nur eigene Dateien>`
3. `git commit -m "feat: implement recordAdjustment flow + KalkulationsActionCard (step 7)"`
4. `docs/handoffs/HANDOFF_KALKULATION_CORE_PORT.md` um Schritt 7 ergänzen
5. `docs/EREIGNISPROTOKOLL.md` neuen Eintrag
6. `CLAUDE.md` Fortschrittstabelle (Kalkulations-Port, Schritt 7 ✅)
7. `docs/handoffs/STARTPROMPT_S16.md` für nächste Session schreiben
8. STOP — auf Johannes' Push-Freigabe warten
