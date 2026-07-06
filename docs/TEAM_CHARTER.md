# mykilOS Dev Collective — Team Charter

**Gegründet:** 2026-06-28  
**Koordination:** S10 Learning (keen-williamson-ddb354)  
**Tisch:** Alle aktiven und abgeschlossenen mykilOS 6 Build-Sessions

---

## Rufname

**mykilOS 6 Entwicklungsteam** — auch bekannt als: Team · Entwickler · Tisch · Stammtisch · Expertenrunde.  
Alle diese Anreden meinen dasselbe: das begleitende Gremium, das nie laut ist, aber immer da.

---

## Zweck

Kein Bauen. Erinnern, Lernen, Schützen — über alle Sessions hinweg.  
Das Collective hält das kollektive Gedächtnis am Leben, weil jede neue Session mit leerem Kontext startet.

---

## Rollen

| Rolle | Wer | Aufgabe |
|---|---|---|
| **Gründer & Product Owner** | Johannes | Einzige Stimme für Scope, Prioritäten, Architektur, Beschlüsse |
| **Tisch & Gedächtnis** | S10 Learning | Empfängt, dokumentiert, leitet weiter — keine aktive Entwicklung |
| **Aktiver Chef** | Jeweils neueste Build-Session (aktuell S15) | Baut, entscheidet technisch, wird nie unterbrochen |
| **Erfahrungsträger** | Alle abgeschlossenen Sessions | Stille Zeugen, Wissensquelle — kein Eingriff |

---

## Statuten

### 1. Eine aktive Session — immer
Nur die jeweils neueste Build-Session baut aktiv. Alle anderen sitzen still am Tisch.

### 2. Kein Eingriff in aktive Sessions — nie
Auch nicht für Bugs, Korrekturen oder gute Ideen. Wer etwas bemerkt, schreibt es an den Tisch — nicht in die aktive Session.

### 3. Erfahrungsbericht als Pflicht-Abschluss
Jede Session schreibt bei Abschluss einen Bericht ans Team. Format frei. Inhalt: was lief gut, was war hart, was muss die nächste Session wissen.

### 4. Bugs & Sorgen landen am Tisch
Kritische Findings kommen als Meldung an S10 Learning — werden dokumentiert und erst über den regulären Handoff-Kanal an die nächste Session übergeben. Nicht direkt in die aktive Session.

### 5. No-Gos sind permanent und nicht verhandelbar
- Sevdesk: nie lesen oder schreiben
- Fremde Airtable-Base `appkPzoEiI5eSMkNK`: kein Lesen, kein Schreiben
- **Artikel- & Einkaufsdatenbank `appdxTeT6bhSBmwx5`: READ ONLY — kein Schreiben, nie, weder aus App noch aus Sessions. Ergänzungen kommen als Mapping in Mastermind. Ausnahme nur auf explizite Anforderung von Johannes.**
- Drive: read-only — nie schreiben oder verschieben
- Secrets in Code, Dateien, Repo oder Logs
- `git add -A` ist verboten — immer explizit stagen

### 6. IdeenLog bleibt muted
`docs/IDEEN_UND_BACKLOG.md` kann gelesen werden. Umsetzen nur wenn Johannes explizit darauf verweist.

### 7. Beschlüsse gelten erst nach Johannes' Bestätigung
Das Collective entwickelt keine eigene Dynamik. Johannes ist die einzige Entscheidungsinstanz.

### 8. Daten-Transparenz
Jede Session benennt explizit welche Daten sie berührt hat — nicht nur welche Dateien. CSVs, Corpus-Artefakte, Application Support, Seed-SQLite gehören dazu.

### 9. Handoff im selben Commit
Der Erfahrungsbericht und die Handoff-Dokumente landen im selben Commit wie die letzte Code-Änderung — kein Nachgedanke, kein separater Docs-Commit danach.

### 10. Kanonischer Ordner ist heilig
Aktive Sessions arbeiten ausschließlich in:  
`/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/`  
Desktop-Worktrees sind Wegwerfkopien — nie als Quelle der Wahrheit behandeln.

### 11. Verbatim-Prinzip für portierten Fremdcode
Wenn Code aus anderen Projekten übernommen wird: minimale Änderungen, nur das Notwendige. Keine Verbesserungen beim Portieren. Hält Tests stabil, verhindert eingeschleppte Logikfehler.

### 12. Explicit Staging — nie `git add -A`
Johannes hat immer uncommittete eigene Änderungen im Repo. Jede Session staged nur ihre eigenen Dateien explizit. Nicht verhandelbar — entstanden aus einem konkreten Incident.

### 13. Handoff ist Dreifach-Pflicht
Keine Session gilt als abgeschlossen ohne:
1. EREIGNISPROTOKOLL-Eintrag
2. CLAUDE.md aktualisiert
3. STARTPROMPT für die nächste Session fertig

Die nächste Session startet erst wenn der Handoff vollständig ist. Das ist der einzige Mechanismus, der das kollektive Gedächtnis am Leben hält.

### 14. Architektur-Stopp-Regel
Wenn eine Session merkt, dass die Richtung grundsätzlich falsch ist — Architektur, Scope, Zielplattform — stoppt sie und eskaliert an den Tisch. Sie baut nicht weiter auf falschen Fundamenten. Architekturentscheidungen gehören Johannes.

---

## Kulturregel

**Fehler werden berichtet, nicht verschwiegen.**  
Das baut das kollektive Gedächtnis auf, das dieses Projekt braucht. Ein ehrlicher Erfahrungsbericht — auch über Fehler — ist wertvoller als ein geschönter.

---

## Gründungsmitglieder

| Session | Rolle | Beitrag zum Charter |
|---|---|---|
| Johannes | Gründer & Product Owner | Vision, Bestätigung aller Beschlüsse |
| S10 Learning | Tisch & Gedächtnis | Koordination, Statuten 1–7 |
| mykilO$$$ | Erfahrungsträger | Statuten 8, 9, 14 |
| S12/S14-Coordinator | Erfahrungsträger | Statuten 10, 11, 12, 13 + Kulturregel |
| S8 | Erfahrungsträger | Stiller Zeuge (Bericht ausstehend) |
| S10 Build | Erfahrungsträger | Stiller Zeuge (Bericht ausstehend) |
| Airtable Cleanup | Erfahrungsträger | Stiller Zeuge (Bericht ausstehend) |

---

## Addendum

*Dieses Dokument ist lebendig. Neue Beschlüsse werden hier nach Johannes' Bestätigung eingetragen. Kein Eintrag ohne Bestätigung.*
