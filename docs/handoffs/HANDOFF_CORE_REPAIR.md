# Handoff: Core Repair (PR #3) — Mandate A–G code-fertig

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: polish/dampflok   (lokal — KEIN Push/Merge ohne ausdrückliche Freigabe)
Build:  ✅ swift build grün
Tests:  ✅ 296 Tests grün (48 Suites · swift test)
Datum:  2026-06-29
Vorher: 270 Tests · HEAD 9c3847b
```

Diese Session hat den **kritischen Pfad der Core-Repair-Mandate A–G** gefahren — die
Wurzel war überall dieselbe (Forensik): *Proof-of-Existence statt Proof-of-Function*.
`ac1c914` hatte die **Bausteine** angelegt, aber fast nichts **verdrahtet**. Jetzt sind
alle sieben Mandate real verdrahtet und mit echten Tests belegt.

Reihenfolge bewusst nach Hustadt-Kritikalität: **E → A → B → D → C → F → G**. Nach jedem
Schritt `swift build && swift test` grün.

---

## Was jedes Mandat liefert

| Mandat | Vorher (Befund) | Jetzt |
|---|---|---|
| **E** Typed I/O | `ConversationEngine` loggte Roh-Tool-Namen → Schaltzentrum 0 Handshakes (F12) | `AssistantToolManifest` (9 Tools → Manifest-IDs), Engine loggt Manifest-ID; 3 neue ehrliche Weichen; docs-Manifest gelöscht; Bug-Test korrigiert + GMAIL_SEARCH-Gate-Test |
| **A** Diagnose | Commit immer „unbekannt"; Diagnose nur im About-Fenster | Echter Git-Commit/Branch/Build-Datum via Info.plist; **Settings → Diagnose**; eine DB-Pfad-Quelle |
| **B** Lokales Drive | `LocalDriveRootResolver` 0 Caller (orphaned); `driveFolderPath` ungenutzt | Foundation-only `DriveLocalResolver` (xattr, testbar); FilesTabView löst lokal auf („· LOKAL"), „Im Finder zeigen"; `driveFolderPath` als Fast-Path |
| **D** Vorschau | `localURL` nie übergeben → PDF öffnet Safari (F11) | PDFKit lokal-zuerst + read-only Remote-Fallback (`downloadContent`→`PDFDocument`); Offers/Files öffnen lokal-zuerst |
| **C** Angebote | Verdrahtet, aber Ordnernamen-Klassifikation 0 Tests; Loader untestbar (F7) | `OffersCollector` (MykilosServices, testbar); echte Rekursion-/Pagination-/Ordnernamen-Tests |
| **F** Crash-Diag | `try!` in Prod-DB; kein `os.Logger`; kein Recovery | `AppDatabase.boot()` (kein try!, kein fatalError mehr in Sources); `DatabaseRecoveryView`; `MykLog`; redaktierter Export |
| **G** Backup | `BackupService` orphaned; WAL-Test war Fake-String-Copy | Erzwungener Checkpoint; „Backup jetzt" (Settings) + Restore (Recovery-View); **echter WAL-Round-Trip-Test** + SHA-256-Known-Vector |

Details je Mandat: [docs/EREIGNISPROTOKOLL.md](../EREIGNISPROTOKOLL.md) (Eintrag „Core Repair Session").

---

## 🟢 Hustadt-Live-Abnahme (das eigentliche „FERTIG" — braucht Johannes am Gerät)

> App via `./script/build_and_run.sh` bauen/starten (injiziert Commit in die Info.plist),
> Projekt **Hustadt** öffnen · driveFolderID `13ITPqAMdz6JrS13u8y7JvkTVXAWznA_S`.

- [ ] **Dateien-Tab** zeigt Dateien; Quellzeile enthält „· LOKAL", wenn der Drive-Ordner
      lokal (Google Drive für Desktop) materialisiert ist.
- [ ] **PDF-Klick** öffnet eine echte Vorschau (PDFKit-Popover bzw. „Im Finder öffnen"
      → macOS-Vorschau) — **NICHT** Safari.
- [ ] **Rechtsklick → „Im Finder zeigen"** selektiert die Datei im Finder.
- [ ] **Angebote-Tab** findet das PDF in `05 eingehende Angebote/Vorplanung…` (rekursiv),
      Spalte „Eingehende Angebote".
- [ ] **Assistent**: einen Chat mit Gmail-Tool laufen lassen → **Settings → Integrationen
      (Schaltzentrum)**: Zeile `GMAIL_SEARCH` zeigt einen frischen Handshake (> 0).
- [ ] **Settings → Diagnose**: Version **und** echter Commit sichtbar (nicht „unbekannt").
- [ ] **Settings → Diagnose → „Backup jetzt"**: Status wird „Backup erstellt"; Ordner unter
      `…/Application Support/mykilOS Mac/backups/` vorhanden.

### Bekannte Live-Unsicherheiten (ehrlich)
- Der xattr-Name `com.google.drivefs.item-id#S` ist gegen einen echten Drive-Mount **nicht**
  verifiziert (nur die Logik per `setxattr`-Test). Falls „· LOKAL" nie erscheint, das xattr
  am Hustadt-Ordner prüfen: `xattr -p com.google.drivefs.item-id#S <ordner>`.
- Prefix-Annahmen `TR/ARE/AB` in der Beleg-Klassifikation sind weiter Annahmen — bei Bedarf
  am echten Bestand justieren (`OfferDocumentClassifier.prefixLexicon`).
- Material-Tab öffnet weiter im Browser (kein Gate-Item; bewusst zurückgestellt).

---

## NO-GOs eingehalten
- Kein Push, kein Merge (Working Tree lokal, bereit zur Review/Freigabe durch Johannes).
- Keine externen Schreibzugriffe (Sevdesk/Airtable/Drive read-only; Backups nur lokal).
- Secrets nur Keychain; Diagnose-Export per Konstruktion ohne Tokens.

## Offene manuelle Aktionen (unverändert, Johannes)
M1 Airtable Base-ID fixen · M2 Google Re-Consent · M3 ClickUp-Listen-IDs · M4 sevdeskRef+Budget ·
M5 Clockodo-Stundensätze · M6 Alt-PAT revoken · M7 `2026_20`→`2026_020`.

## Danach (nächste Session)
🟡 Polish L24–L30 ([docs/POLISH_LOOP_LEDGER.md](../POLISH_LOOP_LEDGER.md)):
Kontakt-Kontext · Favoriten (GRDB) · Dunkelmodus-Kontrast · Timeline-Tab · Leerzustände ·
Test-Decke · Abschluss + DMG.

_Übergabe: 2026-06-29 · Claude Code (Opus) — Core Repair A–G_
