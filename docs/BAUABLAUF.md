# BAUABLAUF — der feste, verifizierte Bauablauf für mykilOS 11

**Verankert 2026-07-08.** Dies ist die **einzige Wahrheit über die Bau-Reihenfolge**. Jede Session
nimmt den NÄCHSTEN offenen Schritt, baut NUR diesen, verifiziert ihn hart, stoppt. Kein Vorgreifen,
keine Bündelung mehrerer Schritte, keine Abkürzung. Detail-Ideen liegen in
[IDEEN_UND_BACKLOG.md](IDEEN_UND_BACKLOG.md); der verifizierte Bau-Stand in
[OFFENE_ZUSAGEN.md](OFFENE_ZUSAGEN.md). Bei Widerspruch gilt: dieses Dokument (Reihenfolge) +
OFFENE_ZUSAGEN.md (Stand).

---

## 0. Das eiserne Arbeitsgesetz — gilt für JEDE Session, JEDES Modell (Sonnet 5 niedrig als Standard)

1. **Ein Schritt pro Session-Einheit.** Nicht zwei, nicht „während ich dabei bin". Ein Schritt aus
   der Liste unten, zu Ende gebracht und verifiziert, DANN Stop.
2. **Selbst arbeiten, kein Schwarm.** Keine Multi-Agenten-Workflows, keine parallelen Coding-
   Subagenten für verzahnte Änderungen. Wenn überhaupt ein Subagent, dann nur nach
   [SUBAGENT_DISZIPLIN.md](SUBAGENT_DISZIPLIN.md) (Anti-Delegations-Klausel + selbst per `git status`
   verifizieren). Standard: der Haupt-Agent baut direkt mit Read/Edit/Write/Bash. Brot und Wasser.
3. **„Fertig" heißt: Johannes hat es LIVE in der App geprüft.** Niemals „Build grün / Tests grün"
   als Fertigmeldung. Grün beweist nur, dass der Code nicht kaputt ist.
4. **Nie „erledigt/toll/schon fast fertig" melden, wenn keine Zeile Code steht** (Lehre Aufmaß-
   Widget: wochenlang als geplant/„kommt" geführt, real 0 %). Kein Code = Status 🔴, Punkt.
5. **Keine Abkürzung möglich machen.** Verifizieren, dann weiter. Nie das nächste anfangen, bevor
   das laufende real grün UND ehrlich gemeldet ist.
6. **Wird ein Schritt nicht umgesetzt, wird das aktiv gemeldet** — nie stillschweigend fallenlassen.

## 1. Der Verifikations-Zyklus pro Schritt (der Fang-Mechanismus — jede Stufe ist ein harter Stop)

```
PREFLIGHT (vor jeder Aktion):
  pwd  → endet auf ".../mykilOS Mac"        sonst STOP
  git remote get-url origin  → mykilOS-macOS  sonst STOP
  git branch --show-current  → feat/multi-user-login (oder von Johannes genannter)
  swift build && swift test  → grün           sonst ist DAS der Auftrag, nicht der geplante Schritt
  gh run list --branch <branch> --limit 3  → echte CI grün (nicht nur lokal)

BAUEN: genau EIN Schritt aus der Liste. Klein.

DEFINITION OF DONE — alle fünf, in dieser Reihenfolge, jede ein Stop bei Rot:
  (a) swift build  → grün
  (b) swift test   → grün, UND ein NEUER Test, der genau dieses Feature beweist
  (c) swiftlint lint --quiet | grep -c ': error:'  → 0
  (d) commit + push, dann gh run watch <run> --exit-status → echte CI grün (SELBST gesehen)
  (e) an Johannes gemeldet MIT Beleg (Commit-SHA + CI-Run-URL) + klarer Bitte um LIVE-Prüfung

STATUS nach (a)–(d):  🟡 gebaut, CI-grün, ABER NICHT live-abgenommen — NICHT „fertig".
STATUS nach (e)+Johannes-Live-OK:  ✅ fertig.

FANG-MECHANISMUS: Würdest du irgendetwas als „läuft/fertig/grün" melden, das du nicht real gesehen
hast (git status leer? Test wirklich gelaufen? CI wirklich grün?) → STOP, nicht melden, erst prüfen.
Ein Subagenten-Bericht mit auffällig wenig Tool-Aufrufen = Alarm, selbst nachprüfen.

SESSION-GRENZE: nach (e) STOP. Nicht den nächsten Schritt anfangen. Johannes gibt GO für den nächsten.
```

## 2. Statusmodell (in OFFENE_ZUSAGEN.md gepflegt, hier gespiegelt)

- 🔴 **nicht begonnen** — keine Zeile Code.
- 🟡 **gebaut, CI-grün, NICHT live-abgenommen** — existiert, kompiliert, getestet, aber Johannes hat
  es nicht selbst live geprüft. Zählt NICHT als fertig.
- ✅ **fertig** — von Johannes live in der App bestätigt.

---

## 3. WELLE 1 — PRIO 1: ClickUp voll ausgebaut

> **Maxime (Johannes 2026-07-08):** „Ich will nie wieder aus mykilOS in eine andere App wechseln
> müssen." ClickUp muss in der App **voll und tief** bedienbar sein: Multiuser, Abhängigkeiten,
> alles. Ghost-Persona-/Testspace-Regel bleibt hart, bis Johannes eine Liste per Go-Live-Whitelist
> ausdrücklich freigibt.

**Fundament, das schon steht (verifiziert 2026-07-08, nicht anfassen):** `ClickUpWriteGate`
(fail-closed), `ClickUpGoLiveWhitelistStore` (admin-gated), `ClickUpTaskActionStore`
(create/setStatus/**updateTask** durch Gate+Audit), Lesen (tasks/projektMeta/spaceID/currentUser).

| Schritt | Ziel (genau EINS) | Kern-Dateien | Live-Abnahme durch Johannes |
|---|---|---|---|
| **CU-1** | Bearbeiten-UI-Sheet für das schon gebaute `updateTask` (Titel/Fälligkeit/Priorität) — in TasksWidget UND ClickUpAufgabenSpalte erreichbar | neu `ClickUpTaskEditSheet.swift`, `TasksWidget.swift`, `Kataloge/ClickUpAufgabenSpalte.swift` | Aufgabe im Testspace bearbeiten, Änderung erscheint in ClickUp |
| **CU-2** | Kanban-Spalten (nach Status gruppiert) im Aufgaben-Tab (Kataloge) | `ClickUpAufgabenSpalte.swift` | Aufgaben in Status-Spalten statt Liste sichtbar |
| **CU-3** | Kanban-Aufgaben-Widget auf der Übersicht (Heute/Today) | Today-View + Widget | auf Übersicht sichtbar |
| **CU-4** | „Meine Aufgaben" echt: `clickUpMemberID` je User im Onboarding erfassen + filtern (Multiuser-Basis) | Onboarding, `ResidentIdentity`, `ClickUpAufgabenSpalte` | eigener Account sieht nur eigene Aufgaben |
| **CU-5** | Zuweisen (Mensch-bestätigt, NUR durch Go-Live-Gate, Member-Picker) — KI weist nie zu | neu `assignTask` im Client + Store + Picker-UI | im freigeschalteten Testkanal einer Ghost-ID zuweisen |
| **CU-6** | Abhängigkeiten LESEN + anzeigen (waiting/blocking; nutzt geerntetes Phasen-Template) | Client (`dependencies` dekodieren), UI | Abhängigkeiten einer Testaufgabe sichtbar |
| **CU-7** | Abhängigkeiten SETZEN (durchs Gate) | Client + Store + UI | Abhängigkeit im Testspace setzen |
| **CU-8** | Chat/Kommentare LESEN — ZUERST v3-API-Spike (Client fährt v2), dann Team-Channels, DM/privat raus | neu `ClickUpChatClient.swift`, UI | Kommentare einer Testaufgabe sichtbar |
| **CU-9** | Kommentar SCHREIBEN (gated, Mensch-bestätigt) | Chat-Client + Store | Kommentar im Testspace posten |
| **CU-10** | Tiefe Bedienung, je EIN kleiner Schritt: Custom Fields schreiben · Subtasks · zwischen Listen verschieben · löschen | Client + Store + UI, pro Teilschritt getrennt | jede Teilaktion einzeln live geprüft |
| **CU-11** | Architektur-Bereinigung: `ClickUpTestWerkbankView` auf `ClickUpTaskActionStore` umstellen (Gate+Audit statt Direktaufruf) | `Settings/ClickUpTestWerkbankView.swift` | Werkbank funktioniert weiter, jetzt gegated |

**Datengrundlage für „echt live" (getrennt, Johannes-Aktion, kein Code):** die 11 echten Produktiv-
Listen-IDs aus [CLICKUP_GRUNDWAHRHEIT_GEERNTET.md](handoffs/CLICKUP_GRUNDWAHRHEIT_GEERNTET.md) in
Airtable `ClickUp-Liste` eintragen; Go-Live einer Liste bleibt ein ausdrücklicher Admin-Akt.

## 4. WELLE 2 — Performance & Google Drive

> **Johannes 2026-07-08:** „App muss schneller werden. Daten brauchen zu lange zu laden. Google Drive
> besser anbinden, integrieren oder cachen."

| Schritt | Ziel | Prinzip |
|---|---|---|
| **PERF-1** | MESSEN, wo die Langsamkeit sitzt (Startup, Registry-Load, Drive-Fetch, ClickUp-`withTaskGroup` über alle Projekte) — Zahlen, kein Raten | erst diagnostizieren, dann fixen |
| **PERF-2** | Google-Drive-Cache-Schicht (lokaler Cache pro Ordner/Datei mit Zeitstempel + Hintergrund-Refresh, Live gewinnt) — spürbar schnellere Ladezeiten | GRDB-Cache, per-User; kein Backend |
| **PERF-3** | Ladezustände/Nebenläufigkeit glätten (kein Blockieren des MainActor, sichtbare Skeleton-States) | messbar an PERF-1-Zahlen |

## 5. WELLE 3 — Sicherheit: S0 Grounding-Gate (KRITISCH — Einschub-Kandidat, Johannes entscheidet)

> Der Assistent erfindet Fakten (Mail-Adressen), wenn er sie nicht in den Daten findet — ein reales,
> laufendes Risiko im ausgelieferten Produkt. Voller Plan:
> [CLICKUP_IO_ARCHITEKTUR_PLAN.md](handoffs/CLICKUP_IO_ARCHITEKTUR_PLAN.md) §0.

| Schritt | Ziel |
|---|---|
| **S0-1** | Beleg-Speicher: jeder von einem Tool gelieferte Wert (Adresse/ID/Fakt) wird mit Herkunft festgehalten |
| **S0-2** | Grenz-Validator im Engine-Code: jedes außenwirksame kritische Feld (Empfänger/listID/channelID) muss belegt sein, sonst wird der Entwurf verworfen → „nicht gefunden" statt Erfindung. KEIN Prompt, ein Code-Validator. |
| **S0-3** | Herkunft auf der Karte sichtbar + permanenter Anti-Erfindungs-Test (Mail an nicht existierenden Kontakt → muss Lücke liefern, nie erfundene Adresse) |

**Empfehlung:** S0 sollte NICHT lange hinter Welle 1 warten — es ist die Reparatur genau der
Krankheit, die das Vertrauen gekostet hat. Reihenfolge Welle 1 vs. S0 ist Johannes' Entscheidung.

## 6. WELLE 4+ — Feature-Backlog, triagiert (Volldetail in IDEEN_UND_BACKLOG.md)

Nach Welle 1–3, je in kleine verifizierte Schritte zerlegt, wenn drankommt. Reihenfolge innerhalb
der Wellen von Johannes bestimmbar. **Nichts hiervon als „geplant=fast fertig" behandeln — alles 🔴,
bis Code steht.**

- **W4 · Aufmaß-Widget (laser-agnostisch):** Geräte-Profil-Registry über die ~100 gängigsten
  Lasermessgeräte (Leica Disto / Bosch GLM / Stanley …) statt Ein-Modell-Bindung + BLE-Aufnahme +
  Canvas + Persistenz. (Johannes 2026-07-08: NICHT von einem Modell abhängig machen.)
- **W5 · Assistent-Katalog-/Lagerbestand-Suche (gecached, günstig):** „welche Armaturen auf Lager?"
  ohne teuren Live-API-Call pro Frage.
- **W6 · Universeller Checkout / globales Drag & Drop:** alles aus allen Katalogen (Kontakte/Artikel/
  Positionen/Dateien) pickbar → Warenkorb → CheckoutPort; sevDesk-Postbox-Port bauen.
- **W7 · Kontakte-Ausbau:** Galerie/Kachel + Kontaktbilder, Visitenkarten-Scan, Mail-Signatur→Kontakt,
  Kontakt↔Projekt-Verknüpfung, Kontakt-Picker aus PDFs.
- **W8 · Dokumenten-Template-Katalog (HTML→PDF):** Abnahme-/Übergabeprotokoll, Fragebogen-Migration,
  Pflege/Geräteliste — alles was sevDesk NICHT macht.
- **W9 · Mini-Mode V1.1 + „Boss Button":** schwebende Icon-Sidebar-Presence, Klick-zur-brennenden-Stelle.
- **W10 · Config-driven:** Ordner-Schema-Editor, Look-only Theme-System (CI/Editorial als erstes Theme).
- **W11 · Barcode/QR-Scan, Timeline-Meilenstein-Marker, Mail-Metadaten→Drive-Ablage-Vorschlag.**
- **W12 · Datenschutz/DSGVO:** Onboarding-Datenschutz-Screen (Wording von Johannes), KI-Master-Switch-
  Scope, Export-Recht.
- **W13 · Multi-User auf EINEM Gerät (Nutzer-Wechsel), Settings im macOS-System-Settings-Stil.**
- **W14 · Kosten-Governance:** API-Call-Budgets (Airtable 100k/Monat, aiText-Fallen), Systemkosten-
  Transparenz.
- **W15 (großer eigener Strang, später):** iPad-Version.

## 7. Wie eine Session konkret abläuft (Kurzform zum Anheften)

1. Lies: PROZESS_LESSONS.md (oberster Eintrag) · OFFENE_ZUSAGEN.md · dieses BAUABLAUF.md · bei
   Subagenten SUBAGENT_DISZIPLIN.md.
2. Preflight (Abschnitt 1). Ist CI/Build/Test rot → das ist dein Auftrag, nicht der geplante Schritt.
3. Nimm den **nächsten offenen Schritt** (kleinste Nummer mit 🔴/🟡 in Welle 1, sonst wie Johannes sagt).
4. Baue NUR diesen. Verifiziere alle 5 DoD-Gates. Aktualisiere den Status in OFFENE_ZUSAGEN.md SOFORT.
5. Melde mit Beleg (Commit-SHA + CI-Run-URL), bitte um Live-Prüfung. **STOP.** Warte auf GO.

**Ende jeder Session:** 3 ehrliche Zeilen an PROZESS_LESSONS.md. Kein hohles „erledigt".
