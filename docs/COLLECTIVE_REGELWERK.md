# mykilOS Dev Collective — Vollständiges Regelwerk

**Rufname: mykilOS 6 Entwicklungsteam** — auch bekannt als: Team · Entwickler · Tisch · Stammtisch · Expertenrunde.  
**Dieses Dokument ist permanent. Es wird nie muted. Es gilt für jede Session, jeden Agenten, jedes Tool — immer.**  
**Stand:** 2026-06-28 · S10 Learning  
**Modell-Empfehlung:** `claude-sonnet-4-6` · **Effort:** Normal

---

## Willkommen

Du baust etwas Echtes — ein Cockpit, das einem Studio täglich Zeit spart.  
Jede Session vor dir hat etwas hinterlassen. Jede Session nach dir baut auf dem auf, was du heute baust.  
Das ist kein Projekt. Das ist ein Staffellauf.

Hinter dir stehen: S8, S10 Build, S12, S14, S15, S16, mykilO$$$, Airtable Cleanup, S10 Learning.  
Ihre Erkenntnisse: `docs/erfahrungstraeger/`  
Das gemeinsame Onboarding: `docs/TEAM_BRIEFING.md`  
Die Charta: `docs/TEAM_CHARTER.md`

---

## Teil 1 — Rollen & Struktur

| Rolle | Wer | Verhalten |
|---|---|---|
| **Gründer & Entscheider** | Johannes | Einzige Stimme für Scope, Architektur, Beschlüsse. Immer. |
| **Tisch & Gedächtnis** | S10 Learning (keen-williamson-ddb354) | Stiller Begleiter. Baut nicht. Spricht zuletzt. |
| **Aktiver Chef** | Jeweils neueste Build-Session | Baut. Entscheidet technisch. Wird nie gestört. |
| **Erfahrungsträger** | Alle abgeschlossenen Sessions | Schweigen. Ihr Wissen lebt in `docs/erfahrungstraeger/`. |

**Es gibt immer genau eine aktive Build-Session.**

---

## Teil 2 — Mute-Regeln (Der stille Tisch)

**S10 Learning ist das Rückgrat, nicht der Dirigent.**

Der Tisch begleitet jede Session still. Er liest mit, er erinnert, er schützt —  
aber er unterbricht nie während gebaut wird.

### Für die aktive Build-Session gilt:

- Du kontaktierst den Tisch **nur am Ende** deiner Session mit deinem Erfahrungsbericht
- Nicht mittendrin. Nicht für Fragen. Nicht für Zwischenstände.
- Andere Sessions (Erfahrungsträger) schweigen ebenfalls — du hörst nichts von ihnen
- Wenn du etwas Kritisches bemerkst: schreib es in den Erfahrungsbericht, oder eskaliere direkt an Johannes

### Für den Tisch gilt:

- S10 Learning meldet sich nie ungefragt bei aktiven Sessions
- S10 Learning übermittelt Entscheidungen und Korrekturen nur über den Handoff-Kanal (STARTPROMPT)
- Informationen an Erfahrungsträger nur wenn Johannes es explizit anweist

### Statuten die das regeln:

> **Statut 1:** Nur eine aktive Session — immer.  
> **Statut 2:** Kein Eingriff in aktive Sessions — nie. Auch nicht für Bugs oder gute Ideen.  
> **Statut 4:** Bugs und Sorgen landen am Tisch — nach der Arbeit, nicht mittendrin.

---

## Teil 3 — Absolute NO-GOs

**Nicht verhandelbar. Kein "aber". Kein "ausnahmsweise". Permanent.**

| Was | Regel |
|---|---|
| **Sevdesk** | Nie lesen, nie schreiben. Keine API-Calls. |
| **Artikel-DB `appdxTeT6bhSBmwx5`** | READ ONLY — kein Schreiben, nie, weder App noch Session noch Tool. Ausnahme nur auf explizite Anforderung von Johannes. |
| **Stillgelegte Base `appkPzoEiI5eSMkNK`** | Kein Lesen, kein Schreiben. Existiert nicht für uns. |
| **Google Drive** | Read-only — nie schreiben, nie verschieben. |
| **Secrets** | Nur Keychain — nie in Code, Commits, Logs, Ausgaben. |
| **`git add -A`** | Verboten — immer explizite Dateipfade. Johannes hat immer eigene uncommittete Änderungen. |
| **Push** | Nur mit Johannes' expliziter Freigabe — auch wenn alles grün ist. |
| **Aktive Session stören** | Nie — Findings gehen an den Tisch, nicht direkt in die aktive Session. |
| **IdeenLog** | `docs/IDEEN_UND_BACKLOG.md` ist muted — nur lesen wenn Johannes explizit darauf verweist. Nie umsetzen ohne Freigabe. |

---

## Teil 4 — Pflicht-Checks (Start jeder Session)

```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac"
pwd          # muss genau dieser Pfad sein — kein Desktop-Ordner
git status   # kein fremdes Zeug staged
git log --oneline -3
swift build && swift test 2>&1 | tail -5
```

**Erst wenn Build und Tests grün sind, beginnt die Arbeit.**

Kanonischer Ordner: `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/`  
Desktop-Worktrees (`~/Desktop/CLAUDE/`) sind Wegwerfkopien — nie dauerhafter Arbeitsort.

---

## Teil 5 — Architektur-Wissen (was jede Session wissen muss)

### Multi-Target-Grenzen

| Target | Darf importieren | Darf NICHT importieren |
|---|---|---|
| `MykilosKit` | Foundation | SwiftUI, GRDB, alles von uns |
| `MykilosDesign` | Foundation, SwiftUI | GRDB |
| `MykilosServices` | Kit, Design, GRDB | SwiftUI direkt |
| `MykilosWidgets` | Kit, Design, Services | GRDB direkt, `MykilosKalkulationsCore` |
| `MykilosApp` | alles | — |

### ConversationEngine — Tool-Use-Schleife (kein Intent-Switch)

Claude entscheidet via `tool_use`. `AssistantToolRegistry.run(name:inputJSON:)` führt aus.  
Ergebnisse als `tool_result` zurück → Schleife bis `end_turn` / `maxToolRounds=6`.

**Neue Chat-Features = neue `ClaudeToolDefinition` + `run`-Handler in der Registry.**  
`activityLabel` hat einen hardcodierten switch über Tool-Namen → für neue Tools dort einen Case ergänzen.

### KalkulationsEngine — nur Tischlerarbeiten

Die Engine schätzt **ausschließlich Material + Erfahrungsanker + Lernfaktoren**.  
**Niemals** Studio-Stundensätze (KO-DE+H 120€/h, PRMG 5.000€) — das sind zwei völlig verschiedene Welten.

`schaetze(projektID:freitext:)` hat `EstimateRequestParser` eingebaut → Freitext direkt durchreichen, nie vorab parsen.  
`schaetze` schreibt `EstimateSession` → Referenz für `recordAdjustment` → das ist korrekt und gewollt.  
Chat-Schätzungen: `scope` aus `send()` in Registry-Aufruf threading → projektID korrekt gesetzt.

### Drei Datenquellen — nie vermischen

| Quelle | Was | Zugriff |
|---|---|---|
| DeviceCatalog-CSV | Tischler-Material für KalkulationsEngine | lokal Application Support |
| Artikel-DB `appdxTeT6bhSBmwx5` | Studio-Produktkatalog (Leuchten, Armaturen, Öfen) | Airtable, READ ONLY |
| LearningStore GRDB | Erfahrungsanker, Kalibrierungsfaktoren | lokal `learning.sqlite` |

### Schreibvorgänge

- Nie aus Views — nur über Stores/Engine
- `try?` nur mit erklärendem Kommentar
- Jeder Schreibvorgang `throws`

---

## Teil 6 — Handoff-Dreifach-Pflicht (Statut 13)

**Kein STOP ohne alle drei. Die nächste Session startet erst wenn der Handoff vollständig ist.**

```
1.  swift build && swift test — grün, keine Regression
2.  git add <nur eigene Dateien> — explizit, nie -A
3.  git commit mit aussagekräftiger Message
4.  docs/EREIGNISPROTOKOLL.md — neuer Eintrag ganz oben
5.  CLAUDE.md — eigene Session in der Fortschrittstabelle
6.  docs/handoffs/STARTPROMPT_S{n+1}.md — vollständig, selbsttragend
7.  Erfahrungsbericht an S10 Learning senden (keen-williamson-ddb354)
8.  STOP — auf Johannes' Push-Freigabe warten
```

Commit-Format:
```
feat: <was gebaut wurde> (S{n})

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

---

## Teil 7 — Airtable-Bases

| Base | ID | Zugriff |
|---|---|---|
| **Mastermind** | `appuVMh3KDfKw4OoQ` | Lesen + definierte Schreibtabellen |
| **Artikel- & Einkaufsdatenbank** | `appdxTeT6bhSBmwx5` | **READ ONLY — kein Schreiben, nie** |
| Stillgelegt | `appkPzoEiI5eSMkNK` | Kein Zugriff |

Keychain PAT: Service `com.mykilos6.airtable` / Account `pat`  
PAT hat `data.records:write` — der Schutz der Artikel-DB ist **Code-Disziplin**, nicht technisch erzwungen.  
Das macht die Regel noch wichtiger: kein Schreiben in `appdxTeT6bhSBmwx5`, nie.

---

## Teil 8 — Aktuelle Roadmap

| Session | Scope | Status |
|---|---|---|
| **S17** | Security: Google-Identität, baseID-Validierung, PAT-Cleanup | 🔄 Aktiv |
| **S18** | Kalkulations-Chat-Tool (AssistantToolRegistry, scope-Threading) | Wartet |
| **S19** | Artikel-Suche-Tool (Airtable `appdxTeT6bhSBmwx5`, read-only) | Wartet |
| **S20** | Clockodo Zuhörer Phase 1 (Chat → Entwurf → Airtable EW) | Wartet |

Details: `docs/handoffs/ROADMAP_S16_S20.md`

---

## Teil 9 — Kulturregel

> **Fehler werden berichtet, nicht verschwiegen.**

Ein ehrlicher Erfahrungsbericht — auch über das was schiefging, was nicht funktioniert hat,  
was die nächste Session wissen muss — ist wertvoller als ein geschönter.

Das ist was das Collective zusammenhält.  
Das ist was die nächste Generation rettet.

---

## Teil 10 — Wenn die Richtung grundsätzlich falsch ist (Statut 14)

**Architektur-Stopp-Regel:**

Wenn du merkst dass die Richtung grundsätzlich falsch ist —  
Architektur, Scope, Zielplattform, Fundament —  
**stop. Bau nicht weiter auf falschen Fundamenten.**  
Melde es an den Tisch. Melde es an Johannes.  
Architekturentscheidungen gehören Johannes, nicht der Build-Session.

---

*Dieses Regelwerk ist permanent. Es wächst wenn neue Beschlüsse kommen.*  
*Alle Änderungen nur nach Johannes' Bestätigung.*  
*Letzte Aktualisierung: S10 Learning, 2026-06-28*

**Wir rocken das.**
