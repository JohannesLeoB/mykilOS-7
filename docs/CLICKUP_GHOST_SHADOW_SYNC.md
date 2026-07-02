# ClickUp Ghost-Shadow-Sync + GO-LIVE — Plan (geparkt)

**Status: Konzept v1 · 2026-07-02 · geparkt, nicht gebaut.** Vision Johannes, Architektur Claude.
Eigener späterer Strang — braucht ClickUp read-write + volle Session-Aufmerksamkeit, kollidiert
sonst mit der Wirbelsäule. Vertagt analog [[mykilos8-clickup-orchestration]] (Memory).

---

## 1. Ausgangslage

Johannes hat MYKILOS API TESTSPACE als **Ghost-Parallelaufbau** angelegt: echte Aufgaben +
Aufgaben-Historien, aber Team nur als **Ghost-Kürzel** (Jo/Da/Fra/Sen/Jil) im Text — keine echten
Assignees, keine echten Notifikationen (siehe [[clickup-ghost-persona-rule]], eiserne Regel).

**Erweiterter Wunsch (2026-07-02):** die **live geschalteten Projekte** aus den anderen (echten)
ClickUp-Spaces/Channels sollen **nach demselben Schema in den Testspace kopiert und
shadow-gesynct** werden — mit allen echten Tasks, aber weiterhin als Ghosts fürs Team. **Nur
Johannes selbst** ist bereits Live-User (echt aus ClickUp gespeist).

**Ziel:** irgendwann ein **GO-LIVE-Knopf**, der den (dann fertig angereicherten) Shadow-
Testspace live schaltet — Ghosts → echte Member gemappt, alles auf einmal „mit Saft versorgt".

---

## 2. Warum eigener Strang (nicht jetzt)

- Braucht **ClickUp read-write** auf die echten Live-Spaces — sensibler Rechte-Scope.
- **GO-LIVE ist kein Toggle**, sondern eine geführte Migration — verdient volle Aufmerksamkeit,
  nicht nebenbei neben der Wirbelsäule.
- Kollidiert sonst mit S10/Welle C (gleiche Ressource: Konzentration + ClickUp-Zugriff).

---

## 2b. ⚠️ Bekannte Überschneidung — VOR dem Sync zu klären (Johannes, 2026-07-02)

Der Testspace enthält bereits **zwei unabhängig gewachsene Kopien** desselben Projekts:
- **`PROJEKTE > AKTIV`** (Live-Struktur, z. B. `2025_014_BenjaminMartin_FUN16` mit 7 Tasks)
- **`88 Slack-Archiv (historisch)`** (Slack-Export-Import, dasselbe Projekt mit 26 Tasks)

Beide Zweige sind **nicht deckungsgleich** (unterschiedliche Task-Zahl = unterschiedliche
Detailtiefe/Zeitraum). Ein naiver Sync würde Dubletten erzeugen statt eine Wahrheit.

**Konsequenz fürs Sync-Design:** vor dem eigentlichen Live→Shadow-Sync braucht es einen
**Merge/Dedupe-Schritt** für bereits vorhandene Überschneidungen:
1. Projekt-Identität matchen (Projektnummer/Kdnr, nicht Freitext-Name).
2. Je Match: welche Kopie ist die vollständigere/aktuellere Quelle je Task (Slack-Historie hat
   oft mehr Kontext, Live-Struktur oft aktuelleren Status)?
3. Zusammenführen zu EINER Shadow-Wahrheit je Projekt — append-only, keine der beiden
   Ursprungskopien wird zerstört, bis der Merge bestätigt ist.
4. Erst danach greift die ID-Mapping-Registry (§3) für laufenden Sync.

**Das ist der erste Klärungspunkt, wenn der Strang drankommt** — nicht Detail, sondern
Voraussetzung: ohne sauberen Merge-Schritt entsteht beim Sync zusätzliches Chaos statt weniger.

---

## 3. Architektur-Skizze

```
Live-ClickUp-Spaces (echte Kanäle/Channels, oben im Screenshot)
        │  READ-ONLY (nie schreiben, keine Notifikationen von dort)
        ▼
   Sync-Engine  ──▶  ID-Mapping-Registry (Live-ID ↔ Shadow-ID, stabil, idempotent)
        │
        ▼
MYKILOS API TESTSPACE (Ghost-Shadow)
   - Tasks + Historie (als Kommentare/Description, ClickUp-History ist nicht direkt kopierbar)
   - Team weiterhin als Ghost-Kürzel im Text (Jo/Da/Fra/Sen/Jil)
   - Nur Johannes bereits echter Member (Live-User)
        │
        │  GO-LIVE-Knopf (geführt, dry-run-bar, reversibel)
        ▼
Ghost-Kürzel → echte Member gemappt · Notifikationen scharf · Testspace WIRD Produktion (Modell A)
```

### Bausteine
1. **Read-only Live-Quelle:** Sync liest die echten Spaces, schreibt NIE dorthin, löst KEINE
   Notifikationen dort aus.
2. **ID-Mapping-Registry** (Airtable oder lokal): `LiveTaskID ↔ ShadowTaskID`, `LiveListID ↔
   ShadowListID` — macht den Sync **idempotent** (wiederholbar ohne Dubletten). Append/Update,
   **nie Delete**. **Muss zusätzlich `SlackArchivTaskID` als dritten Schlüssel führen** (§2b) —
   sonst matcht der Sync nicht gegen die bereits vorhandene Slack-Archiv-Kopie.
3. **Ghost↔Member-Mapping-Tabelle:** Ghost-Kürzel → echte ClickUp-Member-ID. Aktuell nur
   `Johannes → echter User` gemappt; alle anderen bleiben Ghost bis GO-LIVE.
4. **Historie:** ClickUp erlaubt keinen direkten History-Write → Task-Historie wird als
   **Kommentar/Description mit Ghost-Kürzel + Original-Zeitstempel** mitkopiert (best-effort
   Chronik, kein 1:1-API-Replay).
5. **GO-LIVE-Migration:** geführter, **dry-run-barer**, reversibler Schritt: Ghost-Tokens im
   Testspace werden auf echte Member-IDs geremapped, Notifikationen erst DANACH scharf.

### Cutover-Modell: **A) Testspace WIRD Produktion** (empfohlen)
- Der angereicherte Shadow-Testspace ist nach GO-LIVE die neue Wahrheit.
- Team wird eingeladen (Ghost→Member-Mapping löst sich auf), alte Live-Spaces werden archiviert.
- **Warum A statt B (Zurücksync in bestehende Live-Spaces):** B bedeutet Merge-Schmerz zwischen
  zwei parallel gewachsenen Strukturen; A hat eine einzige Wahrheit (den Shadow), die bereits
  bewusst kuratiert wurde.

---

## 4. Rails (gelten unverändert, auch für diesen Strang)

- **Ghost-Persona-Regel bleibt bis GO-LIVE eisern:** nie echte Assignee-ID, nie echte
  Notifikationen, nur Testspace `90128024109` (siehe [[clickup-ghost-persona-rule]]).
- Live-Spaces werden beim Sync **nur gelesen**, nie beschrieben.
- GO-LIVE-Migration nur mit Johannes' expliziter Freigabe, nicht automatisiert im Auto-Mode.
- Dry-Run vor jedem echten Sync-Lauf; Mapping-Registry ist die Idempotenz-Garantie gegen Dubletten.

---

## 5. Offene Entscheidungen (vor Bau zu klären)

1. Mapping-Registry: Airtable-Tabelle oder lokal (GRDB)?
2. Wie weit zurück syncen (alle historischen Live-Projekte oder nur aktive)?
3. Sync-Rhythmus bis GO-LIVE: einmalig kopieren oder laufend spiegeln?
4. Exakter GO-LIVE-Trigger: manueller Knopf in mykilOS oder Skript/CLI?
5. Reihenfolge der Team-Mitglieder-Freischaltung (alle auf einmal vs. gestaffelt)?

---

## 6. Nächster Schritt (wenn der Strang drankommt)

Eigene Session mit vollem ClickUp-read-write-Scope. Erst Mapping-Registry + Dry-Run-Sync für
**ein** Test-Live-Projekt bauen und verifizieren, bevor breit auf alle live geschalteten Projekte
ausgerollt wird.
