# HANDOFF — mykilOS 8 · Rollierender Orchestrierungs-Plan

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Start:  main = v7.7.2 (d36063c), 661 Tests grün, DMG signiert.
Ziel:   mykilOS 8 — in rollierenden Session-Blöcken, je bestem Modell, jeder Block endet mit
        DMG + striktem ZIEL-CHECK + nächstem orchestriertem Schritt. Automatisch rollierend.
Modus:  Read-first · live mit Johannes abstimmen · in der TEST-Sandbox bauen · alles gegen- und
        miteinander testen · keine Details übergehen · immer Quer-Wirkungen prüfen.
```

## 0. Die eiserne Invariante: EINE WAHRHEIT pro Datum

**In der gesamten App gibt es für jedes Datum genau EINE Quelle der Wahrheit (System-of-Record) und genau
EINEN Lesepfad dorthin.** Kein Fakt wird doppelt gespeichert; kein Read umgeht den Resolver.

- **Heutige Verletzung (MUSS in Block A aufgelöst werden):** Es gibt **zwei** `Kunden`- und **zwei**
  `Projekte`-Tabellen (Mastermind `appuVMh3KDfKw4OoQ` vs. Artikel `appdxTeT6bhSBmwx5`). Die App liest Projekte
  aus Mastermind, schreibt Intake-Kunde/Projekt aber in die Artikel-Base → **Split-Brain.**
- **SoR-Karte (in Block A verbindlich festschreiben + mit Johannes bestätigen):**

  | Datum | System-of-Record (einzige Wahrheit) | Einziger Lesepfad |
  |---|---|---|
  | Kunde (Stammdaten, Kdnr) | Artikel-Base `Kunden` (Sevdesk-Pipeline) | `ExternalMappingRegistry` |
  | Projekt (Geschäft: Status/Budget/Sevdesk) | Artikel-Base `Projekte` | `ExternalMappingRegistry` |
  | Projekt-Routing (Drive-Ordner-ID, ClickUp-Liste, Such-Strings) | Mastermind `Projekte` | `ExternalMappingRegistry` |
  | Verbindungs-Schlüssel | **Projektnummer** (`JJJJ-NR`) | — |
  | Kostenstellen | Airtable-Projektfeld | Registry |
  | Warenkorb | Airtable `Warenkörbe` (JSON-Snapshot, versioniert) | `WarenkorbListeStore` |
  | Timer-Segmente | lokal GRDB (pro Nutzer) | lokaler Store |
  | Clockodo-Buchung | Clockodo (User-Account) + Airtable-Spiegel | per-User-Store |
  | Backup aller Writes | Base `mykilOS-Backup` (**reiner Spiegel, KEINE konkurrierende Wahrheit**) | nur schreiben |

- **Durchsetzung:** alle Reads/Writes laufen über die Registry / die designierten Stores — **keine** verstreuten
  Direkt-Airtable-Calls in Views. Ein **Invarianten-Test** (Block A, danach in jedem ZIEL-Check) beweist: kein
  Datum doppelt, jeder Read über den Resolver.

## 1. Sicherheits-Sockel (gilt ab Block A für ALLE Writes, dauerhaft)
1. **Karte → Bestätigung → Audit** vor jedem Write (bestehendes Muster).
2. **WriteShadowRecorder → `mykilOS-Backup`** (append-only, KEIN DELETE/PATCH): jeder Write spiegelt mit
   vollständigem Payload-JSON (+ Vorwert bei Update). Auch Fehlversuche.
3. **TEST-Sandbox default** (`_TEST_PROVISIONING`, `TEST_`-Marker) + **TEST/PROD-Schalter** (PROD gesperrt bis
   Freigabe je Schritt). **DELETE nur für TEST-Eigenes**, nie Produktiv.
4. **Airtable nie DELETE/Overwrite** (außer TEST-scoped), **Sevdesk nie direkt** (nur via Airtable/Make),
   Tabu-Base/-Ordner nie. Secrets nur Keychain.
Details: `HANDOFF_TEST_SANDBOX.md`.

## 2. Die rollierenden Blöcke (je bestes Modell · auto-rollierend)

> Jeder Block = ein abgeschlossener Session-Strang auf eigenem Branch, endet mit **DMG + ZIEL-CHECK (§3) +
> orchestriertem Übergang** zum nächsten. Erst wenn der ZIEL-CHECK voll grün ist, rollt der nächste Block an.

| # | Block | Modell · Level | Inhalt (Quellen) |
|---|---|---|---|
| **A** | **Fundament: Eine Wahrheit + Sicherheit + Audit (S0)** | **Sonnet · high** (⤴ optional) | S0-Audit · **SoR-Karte auflösen** (Mastermind↔Artikel) · `ExternalMappingRegistry` als einziger Resolver (Grundgerüst) · `WriteShadowRecorder` + `mykilOS-Backup` · TEST-Sandbox + Schalter + `TestSandboxCleaner` · Rechte-Matrix scharf (sicher). |
| **B** | **Lokales Zeit-Subsystem (S1)** | **Sonnet · high** | Projekt-Timer (Start/Stopp/Pause, Single-Instance-Invariante), 3–5 Kostenstellen-Buttons, Sidebar-Pille, Puls-Erinnerung, doppelte Buchungs-Bestätigung, Zielkontingent. **Rein lokal.** Mockups `entwuerfe/`. |
| **C** | **Identität + Nomenklatur (S2)** | **Sonnet · high** (⤴ optional) | Registry voll (Kdnr/Projektnr/Token→Customer/Project, **Kdnr ≠ Projektnr**) · Kostenstellen aus Airtable · **NumberAuthority** (nächste `2026_030`, max+1, Archiv, Sevdesk-Seam) · STR-Nr-Regel + Varianten (aus Bestand) · **Anti-Duplikat-Checks** · konfigurierbares Ordnerschema + **Ordner-Konnektor-Tabelle** · Kdnr auf Detail-Übersicht. |
| **D** | **Provisioning in der Sandbox (S4)** | **Sonnet · high** | Drive-Ordnerbaum aus Schema (in `_TEST_PROVISIONING`) via Konnektoren · Mehrsystem-Geburt (Drive+Airtable, gated) · ClickUp-Routing-Tabelle (Gerüst) · **Intake-Drive-Upload-Trigger nachrüsten** (feuert heute nicht). Live fragen: wo/wie. |
| **E** | **Geld & Zeit-Upload (S3)** | **Sonnet · high** (⤴ optional) | Clockodo-Write-Gerüst + API-Schemata (per-User-Key, draft→confirm→POST, anonymisiert) · Soll/Ist-Loop (Sevdesk-OrderPos via Airtable → Soll · Ist aus Clockodo · Verkaufsbalken %). Kein realer POST bis Freigabe. |
| **F** | **Dokument-Widgets** | **Sonnet · high** | **Abnahme-Widget** (Protokoll→PDF-Briefpapier+Airtable+einsehbar) · **Warenkorb-Widget** (Einkaufswagen-Icon auf Übersicht, Tabelle, Versionen, **rote Diffs**) · **Export** (Warenkorb CSV/PDF) · **Feature A** „+"-Masken. |
| **G** | **Performance + Politur + Live-Schaltung** | **Sonnet · high** | Lokaler Artikel-Spiegel (Speed) · Linienzeichnungen in der Fragebogen-Maske · ClickUp-Baum **live mit Johannes** routen · **TEST→PROD-Flip je Schritt** · finaler Integrations- + Regressions-Durchlauf → mykilOS-8-Release-DMG. |

**Modell-Logik:** **Default = Sonnet 4.6, hohes Reasoning — für ALLE Blöcke ausreichend** (die Webshop-/Drive-/
Intake-Strecke dieser Übergabe wurde von Sonnet gebaut, solide). Das **⤴** bei A/C/E heißt nur: ein stärkeres
Modell ist bei Architektur/Identität/Geld **optional** sinnvoll, **kein Muss** — die Sicherheit liefert der
**ZIEL-CHECK (§3) + Johannes im Loop**, nicht die Modellstufe. Reine Mechanik/Cleanup → auch Haiku.

## 3. ⭐ ZIEL-CHECK je Block (das Herzstück — vor jedem DMG, NICHTS überspringen)

Ein Block ist erst „fertig", wenn ALLE sechs Punkte nachweislich grün sind:

1. **Vollständigkeit — wirklich gebaut, nicht behauptet.** Jedes einzelne Block-Ziel ist implementiert UND im
   **laufenden App-Bundle live verifiziert** (App starten, Funktion ausführen) — nicht nur „kompiliert" oder
   „Test grün". Jeden Punkt der Block-Liste einzeln abhaken. Stubs/TODOs offen → Block NICHT fertig.
2. **Quer-Wirkungs-Check (Regression) — die Kernfrage.** Für jede Änderung prüfen:
   - **Verschiebt das ein Layout woanders?** Betroffene + benachbarte Seiten/Widgets gegen **Screenshots**
     vorher/nachher prüfen (Sidebar breit/schmal, Übersicht, Detail-Tabs, Galerie).
   - **Schneide ich an anderer Stelle Daten ab?** Listen/Tabellen/Felder, die dieselben Stores/Felder nutzen,
     durchklicken (werden Records still verworfen? Spalten abgeschnitten? Mapping per Feld-NAME + `anyStringValue`?).
   - **Bricht eine andere Funktion?** Volle Testsuite (Regression) + die anderen Widgets/Tools real durchklicken.
3. **Eine-Wahrheit-Check.** Kein neues Datum doppelt gespeichert; alle Reads über die Registry/Stores; SoR-Karte
   eingehalten; Invarianten-Test grün.
4. **Sicherheits-Check.** Alle neuen Writes laufen durch WriteShadowRecorder→Backup-Base; gated; Sandbox default;
   kein Produktiv-DELETE; Sevdesk nicht direkt.
5. **Tests gegen- UND miteinander.** Neue Unit/Cold-Start-Tests grün **+ volle Suite grün + Cross-Funktions-
   Integrationstest** (neue Funktion zusammen mit bestehenden, z. B. Timer + Provisioning + Backup-Shadow).
6. **Abschluss-Ritual.** `swift build` + `swift test` grün → **DMG bauen** (Versionsbump, Name nach Zahlenkreis)
   → **Kurzbericht** (jedes Ziel: erreicht/offen + welche Quer-Wirkungen geprüft) → **nächster Block** anrollen.
   Push/Merge nach main: nur Johannes.

> **Regel:** Lieber ein Block länger offen, als ein Detail „durchgewunken". „Behauptet fertig" ≠ „live verifiziert".

## 3b. Hart gelernte Fallstricke (haben diese App mehrfach Zeit/Daten gekostet — lies sie ZUERST)

1. **Assistent wird stumm / „Archiv weg" / empfängt nichts = Codable-Rückwärtsinkompatibilität.** Ein
   **nicht-optionales** neues Feld an einem persistierten Typ (real: `EmailDraft.attachments`) killt das Decodieren
   ALLER alten Records → der ganze Verlauf wirkt gelöscht. **Regel:** persistierte Codable-Typen nie ohne
   `decodeIfPresent ?? default`; Decode resilient (ein kaputter Block ≠ Totalausfall); **Cold-Start-Test mit ALTEN Daten.**
2. **Layout-Drift / Sidebar = UI-Änderung verschiebt/beschneidet woanders.** Real: die „Übersicht" überlagerte die
   Sidebar (überbreite Hit-Test-Fläche, Klicks ins Leere); Mail-Fenster sprang; Spacing-Drift im Mini-Modus.
   `.clipped()` begrenzt nur die Ausgabe, NICHT Hit-Testing. **Regel:** nach jeder UI-Änderung Quer-Wirkung
   **gegen Screenshots** prüfen (Sidebar breit+mini, Übersicht, Detail-Tabs, Galerie). **Build-grün ≠ Layout-korrekt.**
3. **Airtable-Records verschwinden STILL = Mapping-Falle.** `fetchRecords` liefert Felder per **NAME, nicht ID**;
   und `stringValue` ist **nil bei Zahlenfeldern** (z. B. `Artikelnummer`) → `guard` verwirft alle 13.419 Records
   lautlos. **Regel:** per Feld-NAME mappen + `anyStringValue` für evtl. numerische Felder; gegen ECHTE Feldnamen+Typen testen.
4. **Agenten verlieren unkommittierte Arbeit (Prozess-Neustart) oder kollidieren (gemeinsamer Worktree).**
   **Regel:** **isolierte Worktrees**, „selbst bauen, keine Sub-Agenten", **früh committen**, und **jeden
   „fertig"-Bericht auf der Platte verifizieren** (eigener `swift build`/`swift test`, `git show --stat`) — nie blind glauben.
5. **Split-Brain / zwei Wahrheiten** (zwei Kunden-/Projekte-Tabellen Mastermind↔Artikel) → §0: eine SoR pro Datum,
   ein Resolver. Vor Provisioning auflösen.
6. **Tote Doku-Verweise** (Datei liegt im `_archiv/`) → Verweise vor Übergabe prüfen.

## 4. Rolling-Mechanik (automatisch)
- Reihenfolge **A → B → C → D → E → F → G**. Abhängigkeiten: B baut auf A (Sicherheit/Truth); C auf A; D auf C
  (Nomenklatur/Registry) + A (Sandbox); E auf C; F auf A (Widgets, gated); G auf allem.
- Nach grünem ZIEL-CHECK eines Blocks: nächsten Block **mit dessen Modell-Tag** öffnen, dessen Vertrag lesen,
  bauen, ZIEL-CHECK, DMG — fortlaufend. Bei Blocker oder Architektur-/Datenfrage: **nicht raten, Johannes live fragen.**
- Versionskette: je Block ein DMG (7.8 → 7.9 → … → **8.0 = mykilOS 8 vollständig**), BUNDLE_ID konstant.

## 5. Quellen-Index (alle Verträge dieser Übergabe)
- `HANDOFF_MYKILOS8_KICKOFF.md` — Brücke Briefing↔echter Code (Stolpersteine §2/§4, Schreib-Stand §8, Nomenklatur §9).
- `HANDOFF_TEST_SANDBOX.md` — Rechte-Matrix, Sandbox, **Write-Backup-Base §7**, TEST/PROD.
- `HANDOFF_PROVISIONING_NOMENKLATUR.md` — Nummern/Ordner/STR-Nr/Anti-Duplikat + Adapter-Seams (Sevdesk/ClickUp/Ordner).
- `HANDOFF_ABNAHME_WIDGET.md` — Abnahmeprotokoll-Widget.
- `HANDOFF_PLANNED_FEATURES.md` — Feature A („+"-Masken), C (Warenkorb-Widget + Diff), D (Export).
- `HANDOFF_PROJEKT_INTAKE.md` — Fragebogen-Vertrag (geshippt 7.7.2, Basis für Abnahme).
- `AIRTABLE_DATENFLUSS_AUDIT.md` — Zwei-Base-Landkarte (Grundlage der SoR-Auflösung).
- `mykilOS8_Orchestrierung/codesession_handoff/` — Original-Briefing (briefs S0–S4, Mockups, Modelle, Strategie).
- `CLAUDE.md` + `AGENTS.md` — eiserne Regeln.
