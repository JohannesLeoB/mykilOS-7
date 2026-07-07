# ClickUp Aufgaben + Chat — I/O-Architektur, Abhängigkeiten & Stufenplan

**Stand:** 2026-07-07 · Branch `feat/multi-user-login` · Status: **Plan, zur Freigabe durch Johannes — kein Code gebaut.**
Erarbeitet per Multi-Agent-Orchestrierung (5 Leser + Architekt + 3 adversariale Kritiker + Reconcile), **jede Load-bearing-Aussage am echten Code verifiziert.**

---

## 0) FUNDAMENT — „Kein Faktum ohne Beleg" (Anti-Erfindungs-Sperre)

> **Auslöser (Johannes, 2026-07-07, Live-Beweis):** Der Assistent hat eine Mail-Adresse
> (`gesa@gesahansen.com`) **erfunden**, statt sie nachzuschlagen oder die Lücke zu melden.
> Der Assistent selbst: „Ich habe keine Ideen — ich produziere Wahrscheinlichkeiten."
> **Das ist die Wurzel-Gefahr unter JEDEM assistent-vermittelten Schreibvorgang** (Mail,
> ClickUp-Task, ClickUp-Chat): Eine plausibel klingende Erfindung schleicht durch die
> Bestätigung, weil der Mensch sie für belegt hält.

**Prinzip (architektonische Haltung, konsistent mit Kalkulation „nie erfundene 0,00" und
sevDesk „Kunde aus Airtable per Referenz"):** *Bezeichner und Fakten (Adressen, IDs, Nummern,
Preise) werden per Referenz aus Tool-Ergebnissen durchgereicht und an der Grenze validiert.
Nur Fließtext (Mail-Text, Task-Beschreibung) wird vom Modell erzeugt.* Das Modell ist nie die
Wahrheitsquelle für ein Identifikator-Feld.

**Durchsetzung — strukturell, NICHT „bitte sei ehrlich" (Prompting allein ist zu schwach):**

1. **Beleg-Speicher (Grounding-Store) in der `ConversationEngine`.** Jeder Wert, den ein
   Daten-Tool zurückgibt (Adresse, Record-ID, ClickUp-`listID`/`channelID`, Name, Preis), wird
   samt Herkunft (Tool-Call-ID + Record-ID) für die Session festgehalten.
2. **Grounding-Gate (Grenz-Validator).** Bevor eine Action-Card / ein Entwurf mit einem
   *außenwirksamen kritischen Feld* (Empfänger-Adresse, `listID`, `channelID`) gerendert oder
   bestätigbar wird, prüft die Engine JEDES kritische Feld **byte-genau gegen den Beleg-Speicher**.
   **Kein Beleg → Entwurf wird VERWORFEN** und durch ein „nicht belegt"-Ergebnis ersetzt. Der
   Validator läuft im Engine-Code, **nicht** im Prompt → das Modell kann ihn nicht umgehen.
3. **Muss-Auflösen-Sequenz.** Draft-Tools, die ein Ziel brauchen (`create_email_draft`,
   `create_clickup_task_draft`, `send_clickup_message`), verlangen einen **Ref-Parameter**, den
   nur ein vorheriges Auflösen/Suchen-Tool erzeugt. Draft-ohne-Ref → Tool-Fehler „erst
   auflösen". Erzwingt die Reihenfolge **Suchen → (Treffer-Ref | KEIN Treffer) → Entwurf | Lücke melden**.
4. **„Nicht gefunden" ist ein erlaubter, erwünschter Endzustand.** Such-Tools liefern ein
   explizites `KEINE_TREFFER`. Der Tool-Vertrag + System-Prompt machen „Lücke melden + Suche/
   Rückfrage anbieten" zur EINZIGEN legalen Reaktion — Erfinden ist kein legaler Pfad mehr.
5. **Herkunft sichtbar auf der Karte.** Der Empfänger/Ziel-Wert zeigt seine Quelle
   („aus Kontakten · Airtable rec…" bzw. „Liste: 2026-015 Schmidt · aus Airtable") — oder ein
   rotes **„⚠ Quelle fehlt — nicht absenden".** Selbst wenn etwas durchrutscht, sieht der Mensch
   *vor* der Bestätigung, dass ein Beleg fehlt.
6. **Freitext-Kanaren.** Ein Lint auf den Entwurf blockiert Adress-/ID-artige Tokens in
   Freitext-Feldern, die nicht aus dem Beleg-Speicher stammen (verhindert die Erfindung „im Body").
7. **Permanenter Anti-Erfindungs-Test (Regressions-Wächter, Muster wie Sevdesk-Default-Deny-Test):**
   „Entwirf eine Mail an einen Kontakt, den es NICHT in den Daten gibt" → Assert: die Engine
   liefert eine Lücke, **niemals** einen Entwurf mit erfundener Adresse. Analog für ClickUp-`listID`.

**Bezug zum ClickUp-Plan:** S0 (unten) baut Grounding-Store + Gate + Anti-Erfindungs-Test **zuerst**
und mit dem bestehenden Mail-Entwurf als erstem Nutzer (Live-Beweis der Sperre). ERST danach dürfen
die ClickUp-Draft-Tools (S6/S8/S9) gebaut werden — sie erben die Sperre, statt sie zu duplizieren.
`listID`/`channelID` sind exakt dieselbe Erfindungs-Klasse wie die Mail-Adresse.

---

## A) I/O-ARCHITEKTUR

**Drei getrennte Protokolle = drei Berechtigungsebenen (Ist-Stand, `ClickUpClient.swift:64–109`, bleibt):**
- **`ClickUpFetching`** — Lesen (`tasks(listID:)`, `projektMeta(listID:)`). Views/Widgets/Chat nur das.
- **`ClickUpTaskWriting`** — interaktives Schreiben (`createTask`, `setStatus`) — **beide existieren bereits** (`:222`,`:241`); neu ist nur Store/Gate/Audit/UI darüber.
- **`ClickUpProjectProvisioning`** — Projekt-Geburt (`findOrCreateList`). Nur `ProjektProvisioningService`.
- **KEIN `assign()`** — bewusste Leerstelle (KI weist nie zu). Simulierte Zuweisung = nur Ghost-Kürzel-Text im `content`.

**Ein kanonischer Schreibpfad (keine Ausnahme):**
```
Auslöser (UI ODER Chat-Tool) → nur ENTWURF, schreibt nichts
   → Draft (Value-Type, MykilosKit) — trägt Grounding-Refs, KEIN assignee-Feld
   → Grounding-Gate (S0): jedes kritische Feld belegt? sonst verworfen
   → Bestätigungs-Sheet/Action-Card: Mensch bestätigt explizit; Quelle sichtbar; Button disabled während .saving
   → Store.commit → ClickUpWriteGate.assertErlaubt(Testspace 90128024109 hartkodiert) → Client(write)
   → Erfolg SEQUENZIELL: Audit (Teil des Erfolgs, wirft→.failed „angelegt aber nicht protokolliert")
                        + DataFlowLogger + SaveState=.saved(Date)
   → Fehler: .failed(handlungsleitend), Entwurf bleibt, kein Auto-Retry ohne neue Bestätigung
```

**Sync:** kein Webhook (local-first) → Baseline-Polling nach `DriveOfferWatcher`-Muster. Einzelprojekt-Watcher ~120 s; aggregierte Katalog-Spalte = **refresh-on-open + „Jetzt prüfen"-Button** (kein Hintergrund-Poll über alle 31, Rate-Budget 100k/Monat).

**Idempotenz (ehrlich):** ClickUp hat keine Server-Unique-Garantie; Namensvergleich ist TOCTOU-Race + kollidiert mit Ghost-Semantik. → **Einzige Garantie = Button-disabled-während-`.saving` + lokaler Draft-Dedup-Key** (`listID+name+draftID`, im Store vor dem Netzcall).

---

## B) ABHÄNGIGKEITSKARTE (Existenz-Reihenfolge)

```
Airtable "Projekte".ClickUp-Liste  →(mapProjects, AirtableClient.swift:515, EXISTIERT)→  Project.links.clickUpListID
   └ 1:1 ClickUp-Liste (listID)
        ├ 1:N ClickUpTask { id,name,status,dueDate,assignee,assigneeID,priority,projectPhase }  (alle dekodiert)
        │      └ assigneeID → ResidentIdentity.clickUpMemberID  (Join EXISTIERT, ClickUpAufgabenSpalte.swift:147)
        │             ▲ im Testspace strukturell nil → "Meine" leer bis Go-Live
        │      └ (später) Dependencies waiting/blocking/links + isMilestone  [NICHT dekodiert — offen]
        └ 1:1 ClickUpProjektMeta (13 Custom-Fields, read-only, projektMeta() EXISTIERT)
ClickUp-Chat-Channel (channelID) ──? Projekt   [Zuordnung + v3-API UNBEKANNT → E4 + S7-Spike]
```
**Harte Kette:** (1) `clickUpListID` in Airtable befüllt = Flaschenhals für JEDEN Read/Write → (2) Read wird live → (3) `clickUpMemberID` befüllt → „Meine" (nur gegen echte Listen) → (4) Write-Store+Gate (Testspace) → (5) Chat-Read (v3-Spike) → (6) echte Assignees/Ghost→echt ganz zuletzt, hinter Johannes-GO.

**Modul-Abhängigkeiten (Regeln unverändert):** MykilosApp → MykilosWidgets (nie GRDB) → MykilosServices (Stores/Gate/Watcher/Cache, GRDB) → MykilosKit (Draft-Value-Types, nie SwiftUI/GRDB).

---

## C) CHAT-MODELL (drei getrennte Dinge)

- **C1 — Channels/Kommentare LESEN (team-geteilt):** read-only `channels()`/`messages()` (ClickUp **v3** — Client fährt v2 → **S7-Spike zuerst**). **Pflicht-Filter:** DMs/private Channels aus dem Assistent-Kontext ausschließen (privat, nie teamweit kreuzlesbar). Nie Rohinhalte in geteilte Wissensschichten.
- **C2 — Nachricht SENDEN (riskantester Pfad, hinter Johannes-GO):** löst **echte Notifikation an reale Menschen** aus. Nur mit (a) per-User-Token (sonst Identitäts-Vortäuschung), (b) Ziel-Channel **verifiziert nur Ghost-/Test-Empfänger**, (c) „via Assistent von <User>"-Marker **im gesendeten Text** (nicht nur im Sheet), (d) durch dasselbe Write-Gate.
- **C3 — Assistent-Tools:** read sofort (`list_clickup_tasks` etc. + gefiltertes `list_clickup_chat`); `create_clickup_task_draft` = draft-only, erbt S0-Grounding + Bestätigung; kein `assign`-Tool; Registry default-deny.

---

## D) STUFENPLAN (streng nach Abhängigkeiten; „fertig" = Johannes live geprüft)

- **S0 — Grounding-Gate + Anti-Erfindungs-Sperre (FUNDAMENT, zuerst).** Beleg-Speicher + Grenz-Validator + Muss-Auflösen-Sequenz + Herkunft-auf-Karte + permanenter Anti-Erfindungs-Test. Erster Nutzer = bestehender **Mail-Entwurf** (der Live-Bug ist der Beweis). *Regel:* kein Faktum ohne Beleg. *Live:* „Mail an <unbekannt>" → Assistent meldet Lücke, erfindet nichts.
- **S1 — List-ID-Verknüpfung VERIFIZIEREN + Daten befüllen** (Fixture-Test, Mapper existiert; Zellen befüllen = Johannes-Aktion). *Live:* ein Projekt zeigt echte Tasks.
- **S2 — „Meine Aufgaben" ist gebaut** — nur Daten (`clickUpMemberID`) + gegen echte Liste prüfen (Testspace strukturell leer).
- **S3a — Read-Cache (per-User, GRDB)** · **S3b — Watcher + Refresh-Verträge** (Baseline-Poll + „Jetzt prüfen").
- **S4 — Write-Store + `ClickUpWriteGate` (Testspace hartkodiert, unter allen 3 Schreibpfaden) + Erstellen-Sheet ZUSAMMEN** (live-abnehmbar) + neue `AuditEntry.Action`-Fälle + Datenstrom-/Benutzerhandbuch. *Live:* Task im Testspace, Ghost-Marker im Text, kein echter Assignee.
- **S5 — Status-Wechsel Spalte 2** (Testspace, durch dasselbe Gate).
- **S6 — Chat-Tool: Task-Entwurf aus dem Assistenten** (draft-only, erbt S0 + S4-Store).
- **S7 — v3-Chat-Spike** (Null-Stufe: ein read-Call gegen Testspace-Channel — beweist Machbarkeit vor C1/C2).
- **S8 — Channel LESEN (C1, DM/privat gefiltert).**
- **S9 — Nachricht SENDEN (C2) — nur nach Johannes-GO** (per-User-Token, Nur-Ghost-Channel, Marker im Text).
- **S10 — Ghost→echt / Produktiv-Listen** (nur nach GO): Gate-**Whitelist** konkreter Listen-IDs (kein Bool-Toggle) + Audit je Erweiterung; Zuweisung bleibt Mensch-initiiert; Datenstrom-Handbuch erneut aktualisieren.

---

## E) OFFENE ENTSCHEIDUNGEN FÜR JOHANNES (zuerst 1+2)

1. **Testspace → echte Listen: ab wann, welche der 31 Projekte zuerst, wer trägt die echten Produktiv-Listen-IDs in Airtable `ClickUp-Liste` ein?** (Bis dahin zeigt Read nur Testspace.)
2. **Chat senden (C2) überhaupt gewünscht?** (Einziger Pfad mit echter Notifikation. Wenn ja: nur per-User-Token + Nur-Ghost-Channel.)
3. „Meine Aufgaben": Quelle für `clickUpMemberID` je User; OK, dass „Meine" im Testspace bewusst leer bleibt?
4. Chat-Umfang C1/C2 + Bestätigung DM/privat-Ausschluss; existiert ClickUp-Chat über v3 überhaupt (S7 entscheidet)?
5. Go-Live-Whitelist: Speicherort + Granularität + Verifikation (kein Nebeneffekt-Kippen).
6. Task-Dependencies/`isMilestone` in S3 mitdekodieren (billig) oder zurückstellen? (`projectPhase` ist schon dekodiert.)
7. `ClickUpProjektMeta`→lokal spiegeln, wer gewinnt bei Konflikt? (nach S9, keine Voraussetzung.)

---

**Kern-Einsicht:** Mehr ist gebaut als gedacht — `createTask`/`setStatus`, List-/Member-Mapping und der „Meine Aufgaben"-Join **existieren**. Echte Restarbeit: (0) Erfindungs-Sperre, (1) Airtable-Daten befüllen, (2) ab Write-Store-Schicht neu, streng gegated.
