# 00 · START HERE — Orchestrator-Brief (mykilOS 8)

*Du bist die orchestrierende Session für mykilOS 8 (Zeiterfassung + Provisioning). Du koordinierst und baust in sauberen, getesteten, sequentiellen Schritten. Baseline = aktueller **mykilOS 7.7** (Repo `JohannesLeoB/mykilOS-7`, privat, SwiftUI macOS, local-first GRDB, Design-Tokens als CI-Merge-Gate). Dieses Paket ist dein vollständiger Kontext.*

---

## Arbeitsweise — strikt, in dieser Reihenfolge
1. **Zuerst S0 (Audit, read-only).** Lies den Code, erstelle den State-Report nach `briefs/S0_Audit.md`. **Keine Code-Änderung, kein Commit.**
2. **STOPP und auf Johannes' ausdrückliche Bestätigung warten.** Lege den Report vor. Baue nicht weiter, bis Johannes „go" sagt. Weicht der echte Stand vom Plan ab: Plan anpassen, erneut vorlegen, erst dann weiter.
3. **Dann rollend S1 → S4, eine nach der anderen.** Pro Session: implementieren → **testen (grün)** → kurzer Report → **erst dann** die nächste. Nie zwei offene Baustellen gleichzeitig.
4. **Gates respektieren.** S3 und S4 brauchen Johannes' ausdrückliches Write-Gate-OK. Ohne das: nicht bauen.
5. **Bei jeder Unklarheit: direkt Johannes fragen, nicht raten.**

## Code-Respekt — hart
- Auf 7.7 **aufsetzen**, nichts Funktionierendes umschreiben. Keine Architektur-Pivots ohne OK.
- **Jeder Write wirft** (kein `try?`-Verschlucken). Echte Persistenz (GRDB + versionierte Migrationen). Kein `.inMemory`, kein UserDefaults-als-DB.
- Design-Tokens Pflicht, CI-Token-Gate grün halten.
- **Tests sind Teil von „fertig"**, nicht optional. Keine Session gilt als erledigt ohne grüne Tests.

## Invarianten & Modell
→ `02_Kanonisches_Modell.md` — Identität (Kdnr + Token + Projektnummer), Schreib-Disziplin (Karte → Bestätigung → Audit), Timer-Invariante (nie zwei gleichzeitig), Kostenstelle ↔ Clockodo-Service, Farbsprache.

## Reihenfolge, Gates & Modelle
→ `01_Bauplan_Zeiterfassung.md` — S0–S4 mit Abhängigkeiten, Gates und Modell-Empfehlung je Session.
**Modell-Hinweis:** Environment-Default am besten **Sonnet 4.6**; **Opus 4.8** gezielt nur für die Designpässe von S2 und S4; Haiku nur für triviale Mechanik. Das Modell wird im Environment gesetzt, nicht von dir.

## Was im Paket liegt
- `briefs/` — der Brief je Session (`S0_Audit` … `S4_Provisioning_Bundle`).
- `strategie/` — Gesamtstrategie, ClickUp-Master-Orchestrierung, Reply an die frühere Code-Session (Hintergrund & Begründung der Architektur).
- `daten_ports/` — die drei read-once JSON-Ports (Slack-Intelligenz, Projekt-Routinen, ClickUp-Build). Historischer Import, keine laufende Kopie.
- `entwuerfe/` — UI-Mockups (Timer, Erinnerung + doppelte Bestätigung, ClickUp-im-Projekt, ClickUp-Board).
- `clickup_referenz/` — ClickUp-Setup, Aufbau-Anleitung, Routinen, Slack-Report. **Nur relevant, falls der ClickUp-Weg gewählt wird.**

## Offene Entscheidungen (von Johannes, vor S3/S4)
1. **Write-Gate grundsätzlich** — darf die App als bestätigte Karten schreiben? (blockiert S3 + S4)
2. **ClickUp** — integrieren / über Slack Lists / vorerst weglassen? (bestimmt, ob S4 ClickUp einschließt)
3. **Detailfragen zu S1** — Timer-Wechsel (auto/nachfragen), Puls-Verhalten bei Ignorieren, zusätzliche feste Gemeinkosten-Stellen. Siehe Bauplan.

*Kurz: Audit zuerst, an Johannes' Bestätigung gebunden. Dann rollend, sauber, getestet, im Gesamtkonzept.*
