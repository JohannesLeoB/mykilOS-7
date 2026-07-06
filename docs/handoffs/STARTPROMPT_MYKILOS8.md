# Startprompt — mykilOS 8 (neue Code-Session, anderes Claude-Konto) · FINAL

> **So benutzen:** Im anderen Claude-Konto eine neue Claude-Code-Session im Ordner
> `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/` öffnen und den Block zwischen den
> `=====`-Linien als ERSTE Nachricht einfügen. Selbsttragend — kein Gedächtnis/Chat der Vorsession nötig.
> **Modell: Sonnet 4.6, hohes Reasoning als Default — für ALLE Blöcke ausreichend.** Ein stärkeres Modell ist
> nur **optional** für Block A („eine Wahrheit"/Architektur) oder heikle Entscheidungen (C/E) — **kein Muss**.
> Die Sicherheit kommt aus dem ZIEL-CHECK + Johannes im Loop, nicht aus der Modellstufe.

```
=====================================================================================================

Du bist Claude Code und entwickelst mit mir (Johannes) an mykilOS weiter — einer local-first macOS-
SwiftUI-App (Multi-Target SPM, GRDB). Wir starten das Feature-Paket mykilOS 8 in rollierenden Blöcken.

ARBEITSORDNER (kanonisch): /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
STAND: main = origin/main, Tag v7.7.2, Commit d36063c · swift build grün · 661 Tests grün · DMG signiert.
ÜBERGABE-BRANCH: Diese Verträge liegen auf `docs/mykilos8-handoff` (= v7.7.2 + alle Handoff-Docs, gepusht).
Bestätige mit `git status`; zweige deine Block-A-Arbeit von DIESEM Branch ab (er enthält alle Verträge). main heilig.
MODUS: Read-first · live mit mir abstimmen · in der TEST-Sandbox bauen · alles gegen- und miteinander
testen · KEINE Details übergehen · IMMER Quer-Wirkungen prüfen · nichts raten — bei Unklarheit fragen.

DIE EISERNE INVARIANTE — EINE WAHRHEIT PRO DATUM:
In der ganzen App hat jedes Datum genau EINE Quelle der Wahrheit und EINEN Lesepfad dorthin. Kein Fakt
doppelt, kein Read am Resolver vorbei. (Heutige Verletzung: zwei Kunden-/Projekte-Tabellen Mastermind vs.
Artikel-Base → in Block A auflösen.) Sicherheits-Sockel ab Block A für ALLE Writes: Karte→Bestätigung→Audit,
Write-Shadow in die lösch-rechte-freie Backup-Base, TEST-Sandbox default, Airtable nie DELETE (außer
TEST-scoped), Sevdesk nie direkt.

LIES IN DIESER REIHENFOLGE, BEVOR DU ETWAS TUST:
1. docs/handoffs/HANDOFF_MYKILOS8_ROLLING_PLAN.md — der Orchestrierungs-Plan: §0 Eine-Wahrheit + SoR-Karte,
   §2 die Blöcke A–G (je bestes Modell), §3 der ZIEL-CHECK, **§3b Hart gelernte Fallstricke (ZUERST lesen —
   Codable-Gedächtnisverlust, Layout-Drift, Airtable-Mapping, Agenten-Disziplin)**, §4 Rolling-Mechanik.
2. docs/handoffs/HANDOFF_MYKILOS8_KICKOFF.md — Brücke Briefing↔echter Code. WICHTIG: §2 (wo das Briefing vom
   Code abweicht — z. B. ExternalMappingRegistry existiert NOCH NICHT) und §4 (Clockodo ist schon entworfen).
3. CLAUDE.md + AGENTS.md — die eisernen Regeln (main heilig, isolierte Worktrees, Design-Tokens, jeder Write
   wirft, GRDB-Migrationen, Tests gehören zu „fertig").
4. Die Block-Verträge nach Bedarf: HANDOFF_TEST_SANDBOX.md (Sandbox+Backup-Base §7), 
   HANDOFF_PROVISIONING_NOMENKLATUR.md (Nummern/Ordner/Adapter), HANDOFF_ABNAHME_WIDGET.md,
   HANDOFF_PLANNED_FEATURES.md (Feature A/C/D). Original-Briefing: mykilOS8_Orchestrierung/codesession_handoff/.

ROLLIERENDE BLÖCKE (A→B→C→D→E→F→G — siehe ROLLING_PLAN §2). Default-Modell: Sonnet 4.6 hoch für ALLE Blöcke;
„⤴" = stärkeres Modell optional, kein Muss:
A Fundament (Eine Wahrheit + Sicherheit + Audit/S0) ⤴ · B Lokale Zeit (S1) · C Identität+Nomenklatur (S2) ⤴ ·
D Provisioning in Sandbox (S4) · E Geld & Zeit-Upload (S3) ⤴ ·
F Dokument-Widgets (Abnahme/Warenkorb/Export/+Masken) · G Performance+Politur+Live-Schaltung.

JEDER BLOCK ENDET MIT DEM ZIEL-CHECK (ROLLING_PLAN §3) — NICHTS überspringen:
1) Vollständigkeit: jedes Ziel WIRKLICH gebaut + im laufenden Bundle LIVE verifiziert (nicht nur „kompiliert"/
   „Test grün"). Stub/TODO offen → Block nicht fertig.
2) QUER-WIRKUNGS-CHECK (die Kernfrage): Verschiebt die Änderung ein Layout woanders? Schneide ich an anderer
   Stelle Daten ab (Records still verworfen? Spalten/Felder abgeschnitten? Mapping per Feld-NAME + anyStringValue?)?
   Bricht eine andere Funktion? → betroffene+benachbarte Seiten gegen Screenshots prüfen, volle Regression,
   andere Widgets/Tools real durchklicken.
3) Eine-Wahrheit-Check (kein Datum doppelt, alle Reads über Registry/Stores).
4) Sicherheits-Check (Write-Shadow→Backup, gated, Sandbox, kein Prod-DELETE).
5) Tests gegen- UND miteinander (neue + volle Suite + Cross-Funktions-Integrationstest).
6) Abschluss: build+test grün → DMG (Versionsbump) → Bericht (jedes Ziel erreicht/offen + welche
   Quer-Wirkungen geprüft) → nächsten Block anrollen. Merge/Push nach main: nur ich.

DEIN ERSTER SCHRITT — BLOCK A, beginnend mit S0 (Audit):
Bestätige zuerst den Ordner+Stand (pwd, git status, swift build). Dann lies den Code (Targets, GRDB-Schema/
Migrationen, das Karte→Bestätigung→Audit-Schreibmuster, Widgets/Design-Tokens, Tests) und schreib mir einen
kurzen VERSTÄNDNIS-REPORT + deine offenen Fragen. Danach entwirfst du — und stimmst mit mir ab, BEVOR du
Code schreibst — die SoR-Karte (welche Tabelle ist je Datum die einzige Wahrheit, Mastermind↔Artikel auflösen)
und den Sicherheits-Sockel (WriteShadowRecorder + Backup-Base + TEST-Sandbox). Erst nach meiner Bestätigung
bauen. NOCH NICHTS schreiben, bevor wir die eine Wahrheit geklärt haben.

=====================================================================================================
```

---

*Erstellt von der 7.7.2-Session als finale Übergabe. Orchestrierung: `HANDOFF_MYKILOS8_ROLLING_PLAN.md`.
Brücke zum echten Code: `HANDOFF_MYKILOS8_KICKOFF.md`.*
