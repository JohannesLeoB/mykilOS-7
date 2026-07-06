# S10 Learning — S20 Sprint-Vorbereitung (keen-williamson-ddb354)

**Datum:** 2026-06-28  
**Session-Typ:** Learning / Tisch — kein Build  
**Worktree:** `~/Desktop/CLAUDE/_mykilOS/mykilOS Mac/keen-williamson-ddb354`

---

## Was diese Session getan hat

Johannes war frustriert. Zu Recht. Er hat eine Liste aufgemacht:

1. Layout-Bug in Projekt-Übersicht: AssistantWidget an Position 0, dunkles Banner oben
2. Google Drive nicht in Projektseiten sichtbar
3. Per-Kategorie-Layouts: Johannes will das nicht — einheitliches Layout für alle Projekte
4. Assistent: Emojis, KI-Floskeln, Demo-Projekte statt echter Airtable-Daten
5. 18 macOS Keychain-Prompts pro Build
6. Airtable-Writes nie gebaut (Eingehende-Angebote, Kalkulations-Positionen = 0 Records)
7. Alles soll S20 geliefert bekommen — vollständig, nichts vergessen

### Was konkret getan wurde:

**AssistantGrounding.swift — Ton-Fix**  
Der System-Prompt hat nie Emojis oder KI-Floskeln unterdrückt.
Ergänzt: direkte Ton-Regeln — kein Emoji, keine Floskeln, kein KI-Selbstbezug.
Datei im Repo liegt korrekt.

**Root Causes identifiziert:**
- Keychain-Prompts: ACL gebunden an Binary-Hash → jeder neue Build = neue "App" = Dialog
- Board-Layout-Bug: GRDB-persistierte Boards aus alter Session haben AssistantWidget an Pos 0
- Drive nicht sichtbar: Google Re-Consent nötig (S17 hat neue Scopes hinzugefügt)
- Falsche Projekte: Airtable `baseID`-Feld im Keychain enthält zweiten PAT statt `appuVMh3KDfKw4OoQ`
- Airtable-Writes: nie gebaut, nur in Ideen-Log erwähnt

**STARTPROMPT_S20.md geschrieben:**  
Alle 8 Aufgaben, Reihenfolge, NO-GOs, manuelle Schritte für Johannes, Handoff-Pflicht.

---

## Lessons learned

**Johannes sieht zu Recht was nach außen nie fertig wurde.**  
Sessions können build-grün sein und trotzdem große Lücken in der Live-Wiring haben.
"grün" heißt Tests grün — nicht "Feature live".

**Root Cause ist selten dort wo man zuerst hinschaut.**  
Der Drive-Fehler lag nicht im Code — Google braucht Re-Consent für S17-Scopes.
Der Airtable-Fehler lag im Keychain-Inhalt, nicht in der Sync-Logik.
Der Board-Layout-Bug lag in alten GRDB-Daten, nicht im Default-Code.

**Keychain ACL-Migration: einfaches Pattern.**  
load() → sofort store() → ACL migriert, einmalig. Kein Drama.

**Einheitliches Layout ist die richtige Entscheidung.**  
Per-Kategorie-Unterschiede kosten Maintenance-Zeit und bringen keinen Nutzen.
Johannes hat das klar entschieden. Umsetzen, nicht diskutieren.

**Airtable-Writes sind trivial — das war reines Versäumnis.**  
`createRecord` POST ist ein Einzeiler mit FakeHTTP-Test. Die Verzögerung war kein
technisches Problem, sondern Scope-Creep-Vermeidung die zu weit ging.

---

## An den Tisch (nächste Session S20)

- **Branch**: `claude/elegant-nobel-ee5ece` (S17+S18+S19 fertig, 217 Tests)
- **STARTPROMPT** liegt bereit: `docs/handoffs/STARTPROMPT_S20.md`
- Vor dem Start: Johannes muss Airtable Base-ID korrigieren + Google Re-Consent
- 8 Aufgaben — alle dokumentiert, alle mit Datei-Pfad und Code-Snippet

*Verfasst von S10 Learning (mykilOS 6 Entwicklungsteam), 2026-06-28*
