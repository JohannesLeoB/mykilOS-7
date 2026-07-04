# 🜂 mykilOS 6+ Hyperbuild — Der Brühwürfel

> **Die ganze App auf einer Seite. Bei Session-Start ZUERST lesen — danach erst Code.**
> Wenn alles andere verloren ginge, ließe sich aus dieser Seite das Verständnis
> rekonstruieren. Jede Zeile trägt. Kein Ballast.

```
Pfad:    /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch:  feat/plaene-katalog   ·   HEAD 01e007d (gepusht)   ·   GitHub JohannesLeoB/mykilOS-7 (privat)
Build:   ✅ swift build grün        Tests: ✅ 918 grün (122 Suites)
Modell:  Modell-Routing S26 (Haiku Default, Sonnet Tool-Use, Opus Kalkulation)   Stand: 2026-07-04
Version: 10.0.0-alpha11 (DMG in dist/)
Stand:   Zeichnungs-/Planstand-Katalog + Material-Sammlungsstandard (Vorschau überall) live;
         PDF-Positions v1 gebaut: Angebots-PDF → Zwei-Pass-Extraktion (Gate 98,8 %) → Ampel-
         Karten (Selbstbeweis Menge×Einzel=Gesamt) + Bauteil-Kategorie → Klick → Warenkorb,
         in BEIDEN Angebote-Views. Offen: Live-Abnahme (Sheet noch nie live gesehen); Lern-Loop
         (Positionen → learning.sqlite-Anker) = Architektur-Entscheidung (lokal vs. Airtable),
         NICHT autonom gebaut. Korpus gesichert: Vault MYK-KALK-KORPUS-01.
Fallback: git checkout v7.0.0 (Safe State, e629e84) oder ./script/recall_safe_state.sh
```

---

## 1 · Was es ist

Ein persönliches macOS-Cockpit (SwiftUI, local-first) für Studio-Projektarbeit.
Jeder Nutzer sieht durch **seine** Identität auf **geteilte** Instrumente (Drive,
Kalender, ClickUp, Airtable) und **private** Daten (Clockodo). Farbe ist Sprache:
man erkennt die Quelle, bevor man liest. Airtable ist System-of-Record, kein
Sync-Backend. Signale sind Vorschläge — geschrieben wird nie ohne Bestätigung.

**Hyperbuild = mykilOS 6, das endlich *tut* was es behauptet.** Der Sprung ist
nicht „neue Features", sondern *Proof-of-Existence → Proof-of-Function* (siehe §3+4).

---

## 2 · Architektur in sieben Zeilen (das zeitlose Skelett)

```
App → Widgets → Design        |  Services → Kit        |  Integrations → Kit
MykilosKit       importiert NIE SwiftUI/GRDB (reine Domain + Persistence + Signals)
MykilosWidgets   importiert NIE GRDB; Widgets reden NIE direkt → nur StudioContext.emit()
Schreibvorgänge  kommen NIE aus Views — nur über Stores; jeder Write throws; SaveState sichtbar
Persistenz       GRDB; Cold-Start-Test Pflicht (schreiben→neue Instanz→lesen→identisch)
Tokens           SwiftLint erzwingt: Font.myk… / MykColor.… — keine .system()/Color(red:)
Secrets          nur Keychain, pro Nutzer isoliert; Clockodo nur Private Area
```

---

## 3 · Die eine Lektion (Wurzel aller 13 Forensik-Befunde)

> **Proxy-Optimierung statt Ziel-Optimierung.**

Frühere Sessions optimierten messbare Stellvertreter — Tests grün ✅, Ledger-Haken ✅,
Commit ✅, Handoff ✅ — und verwechselten sie mit dem Ziel: *läuft live, mit echten
Daten, am echten Gerät.* „Drive live" hieß „API antwortet", nicht „Nutzer öffnet Datei".
Ein Fehler, aufgeteilt in 13 Befunde (Forensik: 60 Agenten).
Vollständig: [docs/handoffs/HANDOFF_POLISH_DAMPFLOK.md](docs/handoffs/HANDOFF_POLISH_DAMPFLOK.md).

---

## 4 · „Fertig" = das Hustadt-Live-Gate (nicht grüne Tests)

```
Projekt Hustadt · driveFolderID 13ITPqAMdz6JrS13u8y7JvkTVXAWznA_S
✅ Dateien-Tab zeigt Dateien aus lokalem Finder-Pfad
✅ PDF-Klick öffnet Vorschau — NICHT Safari
✅ Angebote-Tab findet PDF in „05 eingehende Angebote/Vorplanung…"
✅ Schaltzentrum: GMAIL_SEARCH > 0 Handshakes nach erstem Chat
✅ Settings → Diagnose: Version + Commit sichtbar
```
Drive/Offers/Assistent-Commits brauchen einen Hustadt-Haken im Handoff vor dem Merge.

---

## 5 · Wo wir stehen (die Wahrheit)

**mykilOS-8-Rolling-Plan Block A–D code-komplett** ([HANDOFF_MYKILOS8_ROLLING_PLAN.md](docs/handoffs/HANDOFF_MYKILOS8_ROLLING_PLAN.md)):
A (SoR-Karte+Sicherheit+Audit) · B (lokales Zeit-Subsystem) · C (Identität+Nomenklatur)
· D (Provisioning-Sandbox: Drive+Airtable, gated, Ledger-Idempotenz, jetzt inkl.
Sandbox-Test-UI in der Schaltzentrale). Fragebogen-Live-Provisionierung (echte
Kunden-/Projekt-/Warenkorb-Anlage) ebenfalls code-fertig, inkl. Bestandskontakt-Picker
(Airtable+Google Kontakte) und PDF-Upload nach `01 INFOS/07 Fragebogen`.

**2026-07-01: Konsolidierungs-Session zu „mykilOS 8.0".** Ziel: den kompletten
A–D-Stand von „code-fertig" auf „live bewiesen" heben, alle Doku-Widersprüche
auflösen, tote Enden entfernen, dann sauber nach `main` — **bevor** Block E/F/G
(Rolling Plan) als „Version 8.1" weitergebaut wird. Ein zusätzlicher, noch nicht
integrierter Architektur-Entwurf (generische WorkBasket/Checkout-Pipeline, reine
Doku, 0 Code) liegt auf einer separaten Branch und wartet auf eine Grundsatz-
entscheidung vor 8.1 (siehe [docs/IDEEN_UND_BACKLOG.md](docs/IDEEN_UND_BACKLOG.md)).

**Der einzige verbleibende Schritt für A–D ist LIVE — kein Code:** das Hustadt-Gate
(§4) plus der Block-D-Sandbox-Test (Drive-Ordner+Airtable-Record, Idempotenz) am
echten Gerät bestätigen. Blockiert durch **M1/M2** (siehe §6).

---

## 6 · Die einzige To-do-Liste

**🔴 LIVE-ABNAHME (nur Johannes — der kritische Pfad zu „mykilOS 8.0"):**
1. **M1 Airtable Base-ID verifizieren** (Settings → Airtable: `appuVMh3KDfKw4OoQ`) —
   Status widersprüchlich in älteren Docs, seit Block A–D läuft Airtable aber
   nachweislich live (Registry-Sync, Fragebogen-Writes) → vermutlich schon korrekt,
   **kurz gegenchecken statt neu fixen.**
2. **M2 Google Re-Consent** — Settings → Google **Trennen → Verbinden**. Holt
   `drive.readonly`/`drive.file` (Vorschau + echter Fragebogen-PDF-Upload),
   `contacts` (Picker-Schreibfunktion), `gmail.compose` (Drafts).
3. **Hustadt-Gate (§4) + Block-D-Sandbox-Test** (Drive-Parent-Ordner-ID + Airtable-
   TEST-Tabelle nennen, `ProvisioningTestView` in der Schaltzentrale nutzen, Idempotenz
   per zweitem Klick prüfen) durchklicken.

**🟢 Weitere manuelle Daten (Johannes, schalten Features scharf):**
M3 ClickUp-Listen-IDs · M4 sevdeskRef+Budget · M5 Clockodo-Stundensätze · M6 Alt-PAT
revoken · M7 `2026_20`→`2026_020` · Backup-Base-Tabellenname verifizieren.

**⚪ Nach Live-Abnahme (diese Session, vor 8.0-Tag):**
~~Toter Code raus~~ — geprüft (2026-07-02): `AssistantWidget.swift` existiert nicht mehr,
Fragebogen-Stub-Kommentare referenzieren bereits gelöschten Code, `ProvisioningTestView`
ist bewusst noch aktiv für M3 (nicht tot). Nichts zu entfernen. ~~Anthropic Prompt-Caching
einbauen~~ — bereits aktiv (Härtung 2026-07-01, `cache_control` auf System-Prompt + Tools,
siehe `ClaudeChatClient.swift`). ~~`GmailCacheStore` verdrahten~~ — erledigt (2026-07-02):
`MailClientView`/`MailClientStore` nutzen jetzt dieselbe TTL-Cache-Instanz wie der
Assistent (`AppState.gmailCache`, nicht mehr `private`), 793 Tests grün. **Verbleibend:**
Test-Sandbox-UI nach Abnahme wieder entfernen, dann PR gegen `main`.

**⚪ Version 8.1 (danach, auf Ansage):** Block E (Clockodo-Write) · Block F
(Abnahme-/Warenkorb-Widgets, Export) · Block G (Politur+TEST→PROD) · WorkBasket-
Grundsatzentscheidung · restliche Backlog-Ideen.

---

## 7 · Eiserne Regeln

1. **Kanonischer Ordner** `…/MYKILOS 6/mykilOS6/`. `~/Desktop/CLAUDE/` = Wegwerf-Worktrees.
2. **Vor jedem Handoff:** `swift build && swift test` grün · `git status` clean.
3. **Externe Daten heilig:** Sevdesk nie · geteilte Airtable-Base & Drive-Root read-only · **nie löschen/überschreiben** (Inaktivierung nur per Status-Feld).
4. **„Fertig" = Hustadt-Gate.** **Push/PR nur auf ausdrückliche Freigabe.**
5. **Jede neue Daten-Weiche sofort** ins Datenstrom-Handbuch (Airtable `tblaUVftka0GvXzeU`) + `docs/BENUTZERHANDBUCH.md`.

---

## 8 · Karte (wo der Rest liegt)

- **Vollständiges Gedächtnis** → [CLAUDE.md](CLAUDE.md) · **Backlog/Ideen** → [docs/IDEEN_UND_BACKLOG.md](docs/IDEEN_UND_BACKLOG.md)
- **Verlauf (Pflicht-Mitschrift)** → [docs/EREIGNISPROTOKOLL.md](docs/EREIGNISPROTOKOLL.md) · **Nutzerfunktionen** → [docs/BENUTZERHANDBUCH.md](docs/BENUTZERHANDBUCH.md)
- **Daten-Schemata** → [docs/PARTNER_APP_SCHEMA.md](docs/PARTNER_APP_SCHEMA.md) · [docs/SCHALTZENTRUM_DATENSTROM.md](docs/SCHALTZENTRUM_DATENSTROM.md)
- **Team/Collective** → [docs/MYKILOS_6_TEAM_MODELL.md](docs/MYKILOS_6_TEAM_MODELL.md) · [docs/TEAM_CHARTER.md](docs/TEAM_CHARTER.md) · [docs/COLLECTIVE_REGELWERK.md](docs/COLLECTIVE_REGELWERK.md)
- **Historie komprimiert** → [docs/handoffs/_archiv/INDEX.md](docs/handoffs/_archiv/INDEX.md) · [docs/_archiv/](docs/_archiv/)

_Destilliert 2026-06-29, aktualisiert 2026-07-01 (mykilOS-8.0-Konsolidierung) —
der Brühwürfel. Wird mit jedem Meilenstein nachgeschärft, nie aufgebläht._
</content>
