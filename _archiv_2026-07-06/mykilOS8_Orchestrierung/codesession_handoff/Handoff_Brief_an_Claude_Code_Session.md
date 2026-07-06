# Handoff-Brief — mykilOS 7 → 8 Entwicklung

**An:** Claude Code Session (auf MacBook, Projekt `/Users/johannesleoberger/Claude/Projects/mykilOS/`)  
**Von:** Strategy/Orchestration Session  
**Stand:** 30. Juni 2026  
**Modus:** Read-first, fragen bevor bauen, UI/UX/Daten sind Major.

---

## Dein Auftrag (3 Phasen)

### Phase 1: App verstehen (Audit)
Lese den Code. Nicht um ihn zu ändern — um ihn zu **verstehen**. Beantworte dir selbst:
1. **Architektur:** SwiftUI, GRDB, local-first — wie hängt es zusammen?
2. **Invarianten:** Welche Regeln darf niemand brechen?
3. **Schreib-Pattern:** Wie funktioniert das bestätigte Schreiben (Karte → Bestätigung → Audit)?
4. **Integrationen:** Was ist read-only, was darf schreiben?
5. **UI-System:** Wie sind Widgets, Token, Sidebar aufgebaut?
6. **Tests:** Was ist grün, was ist kritisch?

Schreib einen kurzen **Verständnis-Report** zurück an Johannes. Frag bei Unklarheit nach.

### Phase 2: Neue Ergänzungen diskutieren
Du kennst die App jetzt. Johannes brieft dich auf die sechs neuen Bausteine:
- Lokale Zeiterfassung (Timer, Kostenstellen, Erinnerung, doppelte Bestätigung).
- Soll/Ist-Stunden-Loop (Sevdesk + Clockodo).
- Persönlicher Upload zu Clockodo.
- Mehrsystem-Projekt-Geburt.

**Keine Anforderungen** — Kontext und Design. Ihr diskutiert: **wo passt das in die bestehende Architektur? Was muss neu, was kann bestehen bleiben?**

### Phase 3: Bauen im gemeinsamen Strang
S0 (Audit) → S1 (lokale Zeit) → S2 (Read-Wiring) → S3 (Upload) → S4 (Provisioning).  
**Pro Session:** implementieren → testen (grün) → UI/UX checken → Datenfluss absprechen → erst dann die nächste.

---

## Wo du startest (Dateien zum Lesen)

Navigiere zu: `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS\ 6/mykilOS6/`

**Zuerst (Überblick):**
- `CLAUDE.md` — die Projekt-Konfiguration, Skills, alles was die IDE wissen muss.
- `README.md` (falls vorhanden) — Projekt-Übersicht.

**Dann (Architektur verstehen):**
- `Sources/` — Schaue die Zielstruktur an. Welche Targets, welche Entität je Target?
- Das GRDB-Schema: Wo definiert? Migration-Story?
- SwiftUI-Ansichten: Projekt-Detailseite, Sidebar — wie hängen sie zusammen?
- Die Widgets: wie werden sie beschrieben (Design-Tokens, Farbsprache)?

**Dann (Schreib-Pattern):**
- Suche nach existierenden Schreib-Aktionen (`create_contact`, `create_draft`, Kalender-Vorschlag). Wie funktioniert die Karte → Bestätigung → Audit?
- ExternalMappingRegistry: Wo liegt sie, wie wird sie genutzt?
- `OfferDocumentClassifier`: Wie parst du `AN/AB/SR/TR` + Kdnr?

**Dann (Tests):**
- `Tests/` — welche Tests existieren, welche sind grün?
- Design-Token-CI-Gate: wo wird das durchgesetzt?

**Parallel (Kontext zur neuen Ergänzung):**
- Im selben Projekt findest du: `/mykilOS8_Orchestrierung.zip` (falls Johannes es dort ablegt)
  - Entpack das, lies `00_START_HERE_Orchestrator.md`, dann `02_Kanonisches_Modell.md`.
  - Das sind die Spielregeln, die deine neue Arbeit respektieren muss.

---

## Code-Respekt (Regeln, nicht Vorschläge)

1. **Nichts Funktionierendes umschreiben.** Aufsetzen, nicht umbauen. Wenn die aktuelle Lösung gut ist, erbleibt sie.
2. **Jeder Write wirft.** Keine `try?`-Verschluckungen. Fehler werden sichtbar.
3. **Design-Tokens sind Pflicht.** Kein Hardcoding von Farben/Fonts. Das CI-Gate muss grün bleiben.
4. **GRDB + versionierte Migrationen.** Keine `.inMemory`-Spielereien, keine UserDefaults-als-DB.
5. **Tests gehören zu „fertig".** Keine Session ist erledigt, ohne dass neue Tests grün sind.
6. **Invarianten einhalten.** Der Timer: genau ein aktiv gleichzeitig. Das ist eine DB-Constraint, nicht eine Konvention.

---

## Datenfluss & UI/UX (Major — hier sprechen wir ab)

**UI/UX-Entscheidungen** (du + Johannes):
- Timer auf der Projekt-Seite: großes Display, Start/Stopp. Kostenstellen-Buttons (3–5, aus Airtable-Feld). ✓ Mockup im ZIP.
- Sidebar: winzige Pille (Projekt + Zeit + Play/Pause), läuft nichts → nichts anzeigen. ✓ Mockup.
- Puls-Erinnerung: ganze Sidebar rot nach 60 Min (User-Setting), Klick → Check-in-Dialog. ✓ Mockup.
- Doppelte Bestätigung beim Buchen: Übersichts-Karte → expliziter zweiter „Ja, buchen". ✓ Mockup.
- Geld-Widget: Verkaufsbalken % (Indigo) mit Soll/Ist-Abgleich, > 100 % → Coral. ✓ Mockup.

Alle Mockups stehen im ZIP (`entwuerfe/`). Du liest sie, fragst nach, wir klären **vor** dem Code.

**Datenfluss** (kritisch — hier muss es passen):
- Kostenstellen kommen aus **Airtable-Projektfeld** (projektabhängig).
- Timer-Segmente landen **lokal in GRDB** (privat pro Nutzer).
- Upload zu Clockodo mit **nutzereigenem Key** (Keychain, nie app-weit).
- Clockodo-Aggregation zurück: **anonymisiert** je Kostenstelle/Projekt (kein Personenbezug).
- Soll-Stunden aus **Sevdesk-OrderPos** (strukturiert, kein PDF).
- Zielkontingent: aus Soll initialisiert, manuell editierbar, **gepinnt** (Flag), nicht stil­lschweigend überschrieben.

Diese Flows sind nicht verhandelbar — sie sind Teil des kanonischen Modells. Aber **wie** sie im Code aussehen (welche Views, welche GRDB-Entities, welche API-Calls), das diskutieren wir beim Bauen.

---

## Abstimmungs-Prozess (beim Bauen)

**Pro Session (S1–S4):**
1. Du liest den Brief (z. B. `briefs/S1_Lokales_Zeit_Subsystem.md`).
2. Du entwirfst die GRDB-Entities, die SwiftUI-Views, die API-Calls — **auf Papier oder als Draft-Kommentar**.
3. **Du fragst:** „Sieht die Struktur so aus wie gedacht? Fehlt was? Kriegen wir es hin?" (keine Antwort von mir, sondern ein Gespräch mit Johannes).
4. Erst wenn die Struktur klar ist: Code schreiben.
5. Tests grün.
6. Kurzer Report an Johannes: was ist fertig, was offen, was ist die nächste Session.

**Kommunikation:**
- Fragen direkt an Johannes im gleichen Projekt (er sieht die parallel laufende Code-Session).
- Bei Blockern oder Architektur-Entscheidungen: nicht raten, nachfragen.
- Bei Unklarheit im Brief: nach­lesen im ZIP, oder fragen.

---

## Was du vorfindest (Baseline mykilOS 7.7)

- **Version:** 7.7 (aktuell, SwiftUI macOS, GRDB/SQLite, local-first).
- **Integrationen:** Google Drive/Kalender/Contacts (OAuth read-only), Airtable (read-only für SoR), möglich Slack/ClickUp/Clockodo (noch nicht vollständig).
- **Schreib-Pattern:** Existiert (Karte → Bestätigung → Audit).
- **Registry:** `ExternalMappingRegistry` mappt externe Referenzen auf (Customer, Project).
- **OfferDocumentClassifier:** Parst AN/AB/SR/TR + Kdnr aus Dateien.
- **UI:** Projektseite, Sidebar, Widget-System mit Design-Tokens.
- **Tests:** 409 Tests (laut letztem Stand), CI-Gate für Design-Tokens.

Das ist solide. Du verstehst es, dann bauen wir drauf auf.

---

## Offene Entscheidungen (Johannes muss sie treffen, bevor du S3/S4 baust)

1. **Write-Gate:** Darf die App schreiben (Clockodo-Upload, Mehrsystem-Geburt) oder nur lesen?
2. **ClickUp:** Integrieren, via Slack Lists, oder vorerst weglassen?
3. **S1-Details:** Timer-Wechsel (auto-umschalten oder nachfragen)? Puls-Verhalten bei Ignorieren? Zusätzliche feste Gemeinkosten-Stellen?

Bis diese geklärt sind: S1 bauen (pure lokale Zeit, keine externe Abhängigkeit). S3/S4 können warten.

---

## Nächste Schritte

1. **Dein Part:** Audit lesen, Verständnis-Report schreiben, fragen.
2. **Johannes:** Report lesen, Audit-Fragen beantworten, dann die drei offenen Entscheidungen treffen.
3. **Dann gemeinsam:** S1 planen, diskutieren, bauen.

---

**Willkommen im Projekt. Lies zuerst. Frag früh. Baue dann sauber.**
