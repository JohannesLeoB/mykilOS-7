# Prozess-Lessons — laufender Abschlussbericht

**Zweck (Johannes, 2026-07-04):** „Am Ende machen wir ja alle Erfahrungen, vielleicht lernen
wir so alle mehr, wenn wir immer einen kleinen Abschlussbericht fortführen." Dieses Dokument
ist der EINE, wachsende Ort dafür — nicht in einzelnen Handoffs verstreut. Jede Session (auch
unter anderem Claude-Account) hängt am Ende einen kurzen Eintrag an: was schiefging, was gut
lief, was fürs nächste Mal mitgenommen wird. Kein Ersatz für den Session-Handoff (der bleibt
technisch/inhaltlich), sondern die Meta-Ebene: Zusammenarbeit, Fehler-Muster, Kommunikation.

**Regel:** append-only. Ältere Einträge nie löschen oder umschreiben — nur ergänzen. Neueste
Einträge oben.

---

## 2026-07-04 — Galerie-Flug, ClickUp-Ausbau, Kontakte-Migration Schritt 1, Positions-Picker

**Was schiefging:**
1. **Anführungszeichen-Falle wiederholt.** Typografische „…"-Zeichen mitten in einem Swift-
   String-Literal brechen den Build (mind. 3× diese Session: `ClickUpTestWerkbankView`,
   `ContactsImportView`). Bekanntes Muster, trotzdem jedes Mal erst über den Compiler-Fehler
   gelernt statt vorher vermieden. **Für nächstes Mal:** in Swift-String-Literalen aktiv
   darauf achten, keine typografischen Anführungszeichen zu tippen.
2. **Git-Remote-Check zu oberflächlich** — `head -2` hat einen zweiten Remote abgeschnitten,
   fast fälschlich Alarm wegen vermeintlich fehlendem `origin` geschlagen. Bei sicherheits-
   relevanten Checks (Push-Ziel, Branch-Schutz) immer die volle Ausgabe ansehen.
3. **Dichte Mehrfach-Anfragen nicht früh genug zurückgespiegelt.** Bei Nachrichten mit
   mehreren gebündelten Anliegen in einem Satz lieber kurz bestätigen („ok, drei Dinge: X, Y,
   Z — richtig?"), statt sich die Aufteilung selbst zusammenzureimen und erst am Ende zu
   merken, dass ein Teil (hier: sevDesk-Postbox-Port) technisch noch gar nicht existiert.

**Was gut lief:**
- Hohe Autonomie im Automode hat funktioniert, weil Eiserne Regeln (GO-Rückfrage,
  Beppo-Prinzip, Testspace-only für ClickUp) vorher klar etabliert waren.
- Bei echten Unklarheiten (sevDesk-Postbox-Schema unbekannt, Push-Ziel-Frage) wurde
  nachgefragt bzw. selbst nachrecherchiert statt geraten.
- Free-Climber-Anker-Sweep (aktiv nach veralteten Doku-Behauptungen suchen) fand zwei echte
  Stellen, die längst gefixt, aber nie in der Doku aktualisiert worden waren.

**Kommunikationsstil-Notiz (kein Vorwurf, nur Beobachtung):** Nachrichten oft dicht/kurz,
teils diktiert (Tippfehler, mehrere Anliegen pro Satz). Reale Fehlerquelle beim
Interpretieren — kurzes Zurückspiegeln am Anfang federt das ab, statt stillschweigend zu raten.
