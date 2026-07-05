# AR-Flugplan — wie die ganze AR-Magie wirklich hinkommt

**Die neue Superkraft (seit 04.07. abends):** Mission Control kompiliert und
installiert, Johannes testet im echten Raum, der Satellit justiert. AR lebt
von genau dieser Schleife — Ebenen-Erkennung, Tracking-Qualität und
Snap-Verhalten kann niemand am Schreibtisch fertig denken. Jede Stufe unten
ist als Iterations-Schleife gedacht, nicht als Wurf.

## Stand: schon an Bord (alle noch ohne Live-Test)

AR-Maßband · AR-Anker Gewerke · RoomPlan-Aufmaß (3D + PDF-Grundriss + DXF)
· Planmodelle in AR (USDZ, frei platzierbar).

## Stufe A — Basis hart machen (JETZT, Johannes' Testflug)

Die vier bestehenden AR-Werkzeuge in echten Räumen testen. Die zwei
entscheidenden Messungen, an denen alles Weitere hängt:
1. **RoomPlan-Qualität** in einem echten (Kunden-)Raum — wie sauber sind
   Wände/Öffnungen? Spiegelungen/Drehungen im 2D-Export?
2. **DXF-Import in VectorWorks** — kommt der Grundriss brauchbar an
   (Einheit Meter)?
Ergebnis bestimmt, wie viel Stufe B und C auf RoomPlan bauen dürfen.

## Stufe B — Die Küche im echten Raum (der 💎, #38)

- **B1 (fertig):** USDZ frei platzieren — fürs Kundengespräch oft schon der
  Wow-Moment. Voraussetzung ist Johannes' Export-Rezept, EINMAL sauber
  festgelegt: VectorWorks → 3D-Export → Reality Converter → USDZ, Maßstab
  **Meter**, Modell-Ursprung an der hinteren linken Ecke der Küchenzeile
  (dann steht sie beim Platzieren „richtig herum" auf dem Boden).
- **B2 (der nächste Code-Stern):** „An die Wand andocken" — NICHT die
  automatische CAD-zu-Scan-Registrierung (Forschungsproblem, bleibt raus),
  sondern **manuelles Platzieren mit Snap-Hilfen**: ARKit erkennt Boden +
  Wände, die App bietet „auf Boden setzen" und „Rückwand parallel zur
  nächsten Wand" als einrastende Gesten an. Machbares Engineering mit
  überschaubarer Fehlerfläche — aber test-intensiv → gemeinsame
  Iterations-Sessions nötig. **Das ist der empfohlene nächste AR-Bau.**

## Stufe C — Aufmaß-Magie (Johannes' Kalibrier-Vision)

RoomPlan-Grobscan → geführter **Laser-Kalibrier-Modus** („bin ich mir bei
der Steckdosen-Position sicher?" → Laser-Wert bestätigen) → korrigierte
2D-Zeichnung/DXF. Einziger Blocker: **die Laser-Kaufentscheidung**
(Empfehlung unverändert: Leica DISTO wegen offenster BLE-API; 11 Hersteller
sind vorverdrahtet). Sobald das Gerät da ist: Service-Explorer liefert die
echten IDs → Mess-Protokoll → Kalibrier-UI. Kein Schritt davon wird vorher
als leere Attrappe gebaut.

## Stufe D — Wiederkehr-Magie (#51-Rest/#53, bewusst zuletzt)

ARWorldMap-Persistenz: zum exakten Vorher-Standort zurückfinden,
Geisterbild-Overlay für wiederholbare Portfolio-/Vorher-Nachher-Shots.
Größte Fehlerfläche (Anker-Drift, Session-Wiederherstellung, Licht-
abhängigkeit) — lohnt erst, wenn A–C im Feld bewiesen sind.

## Randstern: Sonnenverlauf (#42)

Bisher zurückgestellt („keine geprüfte Astronomie-Bibliothek"). **Neu:** Mit
Mission Control als Bauerin ist ein Swift-Package (geprüfte Astro-Lib per
SPM) erstmals realistisch einbindbar. Bleibt niedrige Priorität hinter B/C,
ist aber kein hartes „geht nicht" mehr.

## Reihenfolge-Empfehlung

**A jetzt** (Testflug) → **B2 als nächster gemeinsamer Bau** (Iterations-
Schleife Satellit→MC→Feld) → **C sobald Laser gekauft** → **D zuletzt**.
Vor jedem neuen Code-Bau: Quellstand von MC rücksyncen
(siehe `docs/21_COMPILE_LEKTIONEN.md`).
