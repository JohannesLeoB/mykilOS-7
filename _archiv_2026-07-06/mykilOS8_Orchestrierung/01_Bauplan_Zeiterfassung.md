# mykilOS 8 — Schlanker Bauplan · Zeiterfassung + Provisioning

*Konsolidiert die sechs Bausteine aus der Strategie-Session in dependency-geordnete Code-Sessions. Baseline = aktueller 7.7-Stand (wird von S0 verifiziert). Strikt: jede Session hat Scope, Gate, Modell, Abhängigkeit. Kein Build ohne erfülltes Gate.*

## Invarianten (gelten in jeder Session)
- **Identität:** `Kdnr` (Kunde) + `kunde`-Token (Slug) + Projektnummer (Projekt).
- **Schreiben** nur über Karte → Bestätigung → Audit; **jeder Write wirft** (kein `try?`).
- **Externe Quellen read-only**, außer bewusst freigegebene Writes (Gate).
- **Ein** globaler Timer-Zustand in der lokalen DB — nie zwei gleichzeitig. **Kostenstelle ↔ Clockodo-Service.**
- **Farbsprache:** Sage = Zeit, Indigo = Geld, Ochre = Aufgaben, Terrakotta = Dateien, Coral = Risiko.

## Sessions (in dieser Reihenfolge)

**S0 · Audit (read-only)** — Sonnet 4.6, extended thinking — *kein Gate* — **jetzt beauftragt**
Liest 7.7, berichtet Stand: Version, Integrationen (read/write), Write-Pattern, ExternalMappingRegistry + Schlüssel, OfferDocumentClassifier, GRDB-Schema/Migrationen, Tests + Token-Gate, Aufbau Projektseite/Sidebar/Widget-System. Gleicht gegen diesen Plan ab. **Keine Code-Änderung.**

**S1 · Lokales Zeit-Subsystem** — Sonnet 4.6, high thinking — *kein Gate* — nach S0
Bausteine 4–6 + lokaler Teil von 2 & 3. Timer (Start/Stopp, **Single-Instance-Invariante**, Pause hält / Stopp beendet), 3–5 Kostenstellen-Buttons, Sidebar-Pille, **Puls-Erinnerung** (Intervall in User-Settings, lokal), **doppelte Buchungs-Bestätigung**, lokaler GRDB-Store pro Nutzer, lokal editierbares Zielkontingent mit Herkunfts-Flag (`auto`/`manuell`). Rein lokal, kein externer Write.

**S2 · Read-Wiring + Registry-Kdnr** — Opus 4.8 (Design Kdnr + Sevdesk-Kontrakt) → Sonnet 4.6 (Impl) — *kein Gate* — nach S1
Registry um `Kdnr` als zweiten kanonischen Schlüssel erweitern. Soll-Stunden aus Sevdesk `Order/OrderPos` lesen. Kostenstellen aus dem Airtable-Projektfeld. Ist-Stunden aus Clockodo **aggregiert/anonymisiert** je Kostenstelle/Projekt. Verkaufsbalken % im Geld-Widget (Indigo), rollend, > 100 % → Coral.

**S3 · Persönlicher Clockodo-Upload** — Sonnet 4.6, high thinking — **GATE: dein OK** (erster externer Write, aber mit nutzereigenem Key in eigener Keychain) — nach S1/S2
Upload-Knopf schreibt Segmente mit dem **eigenen** Clockodo-Zugang des Mitarbeiters, werfend, lokal auditiert. Kein app-weiter Schlüssel.

**S4 · Provisioning-Bundle (Projekt-Geburt)** — Opus 4.8 (Design) → Sonnet 4.6 (Impl) — **GATE: dein Write-Gate-OK** — nach S2/S3
Eine bestätigte Karte → Airtable-Record + Drive-Ordner + Clockodo-Projekt + Clockodo-Services (aus Airtable-Kostenstellen) [+ ClickUp-Task, falls ClickUp-Weg gewählt]. Idempotent (Schlüssel Kdnr+Projektnr), Teilfehler-fest, jeder Schritt wirft.

## Modell-Hinweis (ehrlich)
Der Trigger setzt **kein** Modell — die gestartete Session nutzt die Modell-Konfiguration deines Environments. Obige Empfehlungen sind also Empfehlungen: Environment-Default am besten **Sonnet 4.6**, **Opus 4.8** gezielt nur für die Designpässe von S2 und S4. Haiku nur für triviale Mechanik.

## Gates / Entscheidungen (bei dir)
1. **Write-Gate grundsätzlich** — dürfen App-Schreibpfade (als bestätigte Karten) existieren? Blockiert S3 + S4.
2. **ClickUp** — integrieren / via Slack Lists / vorerst weglassen? Bestimmt, ob S4 ClickUp einschließt.
3. *(Mehrbenutzer-Backend bleibt separat — die Zeiterfassung braucht es nicht.)*

## Offene Detailfragen (fließen in die Briefs S1/S4)
- Timer-Wechsel zwischen Projekten bei laufendem Timer: **auto-umschalten oder nachfragen?** (Entwurf: nachfragen)
- Puls-Erinnerung bei Ignorieren: **dauerhaft pulsen** oder nach ~5 Min beruhigen bis zur nächsten Marke?
- Zusätzlich zu den projektabhängigen Tätigkeits-Buttons noch **feste Gemeinkosten-Stellen** (Verwaltung, Akquise, Urlaub/Krankheit)?
