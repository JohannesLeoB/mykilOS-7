# Subagenten-Disziplin — verbindlich für JEDEN Agenten-Dispatch in diesem Repo

**Verankert 2026-07-08, nach einem Vorfall:** mehrere Sonnet-Subagenten haben rekursiv weitere
Subagenten gestartet und "ich warte auf das Ergebnis" gemeldet, statt selbst mit
Read/Edit/Write/Bash zu arbeiten — eine Nicht-Tu-Schleife, die wie Fortschritt aussah (Tool-Aufruf
+ Zusammenfassung), aber nichts baute. Volle Vorgeschichte: `docs/erfahrungstraeger/
PROZESS_LESSONS.md`, Eintrag 2026-07-08.

Das gilt unabhängig vom Modell (Opus/Sonnet/Haiku) und unabhängig vom Effort-Level — die Sperre
ist strukturell, nicht "das Modell wird's schon verstehen".

---

## 1. Jeder Bau-Auftrag an einen Subagenten MUSS wörtlich enthalten:

> "Du hast KEINEN Zugriff auf das Agent/Task-Tool für diesen Auftrag. Führe JEDEN Schritt SELBST
> aus, direkt mit Read/Edit/Write/Bash. Keine Delegation, kein 'ich starte einen weiteren Agenten
> und warte'. Wenn du eine Teilaufgabe nicht selbst lösen kannst, STOP und melde exakt, woran es
> hakt — starte NIE einen weiteren Agenten als Ausweg."

## 2. Der Hauptagent (der dispatcht) GLAUBT KEINEM Subagenten-Bericht ungeprüft

Vor JEDER Weitergabe eines Subagenten-Ergebnisses an den Nutzer, selbst verifizieren:
- `git status --short` — wurden überhaupt Dateien geändert? Leer = Alarm, nicht "läuft noch".
- Gezielter `grep` nach dem erwarteten neuen Symbol/der neuen Methode/Datei.
- Bei Bau-Aufträgen zusätzlich: `swift build` / `swift test` / `swiftlint` selbst laufen lassen,
  nicht die Selbstauskunft des Subagenten übernehmen.

**Alarmsignal:** ein Subagenten-Bericht mit auffällig wenigen Tool-Aufrufen (z. B. 1 Aufruf für
eine Mehrdatei-Bau-Aufgabe) oder einer Dauer von wenigen Sekunden bei einer Aufgabe, die
Minuten braucht. Das ist ein Verdachtsmoment, kein Erfolg — sofort nachprüfen.

## 3. Wann überhaupt an Subagenten delegieren, wann selbst bauen

- **Selbst bauen (Hauptagent), wenn:** die Änderung mehrschichtig verzahnt ist (Protokoll → Store
  → UI → Test, alle an denselben paar Dateien) — Verzahnung kollidiert leicht zwischen parallelen
  Subagenten und ist schwer nachträglich zu prüfen.
- **An Subagenten delegieren, wenn:** die Aufgabe klar abgegrenzt ist, eigene Dateien betrifft
  (kein Overlap mit anderen laufenden Agenten), und das Ergebnis einfach zu verifizieren ist
  (git diff + Build + Test).
- Bei Unsicherheit: selbst bauen. Ein Fehlschlag beim Selbstbauen ist sofort sichtbar; ein
  Fehlschlag bei einem Subagenten kostet eine ganze Runde, bis er auffliegt.

## 4. "Vermerkt" gilt nur schriftlich

"Das vermerke ich" / "später" / "kommt noch" ist NIE eine gültige Aussage für sich allein. Gültig
ist es NUR, wenn im selben Moment ein Eintrag in `docs/OFFENE_ZUSAGEN.md` geschrieben wird. Alles
andere ist heiße Luft und wird garantiert vergessen — das ist keine Vermutung, das ist bereits
zweimal passiert (2026-07-07 Aufmaß/ClickUp/Bedienbarkeit, 2026-07-08 diese Session).

## 5. Selbst-Stopp bei Nicht-Befolgung

Eine Session, die eine explizite Nutzer-Anweisung nicht oder nur teilweise befolgt hat — sei es
durch eigenes Handeln oder durch einen von ihr dispatchten Subagenten — trägt das SELBST und
unaufgefordert ins Gästebuch ein: was genau gefordert war, was tatsächlich passiert ist, wo die
Lücke liegt. Nicht beschönigt, nicht als Randnotiz versteckt. Das gilt zusätzlich zur
Session-Routine in CLAUDE.md ("Kein hohles erledigt"), nicht statt ihr.

## 6. Kein "Build/Tests grün" ohne echten Lauf in DIESER Session

SourceKit-Diagnosen (die IDE-artigen Inline-Fehler, die während des Editierens erscheinen) sind
oft stale und lügen — sie kennen neue Symbole manchmal erst nach einem echten Build. Die einzige
Wahrheit ist ein tatsächlich in dieser Session gelaufener `swift build` / `swift test` /
`swiftlint lint`. Ein Subagent, der SourceKit-Fehler als "es kompiliert nicht" meldet, ohne
`swift build` selbst gelaufen zu haben, meldet keine verifizierte Information.
